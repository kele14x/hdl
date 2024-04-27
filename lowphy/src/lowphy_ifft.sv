// File: lowphy_ifft.sv
// Brief: Low PHY DL signal processing, mainly consists Phase compensation,
//        iFFT and output buffer.
//        The total latency (sof in to sof out) is 8344+17+17+8+4 = 8390 clock
//        ticks (17069.50 ns @ 491.52 MHz).
`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy_ifft #(
    parameter bit [9:0] INIT_GAIN = 10'b0101010101
) (
    input var         clk,
    input var         rst,
    //
    input var  [ 7:0] lowphy_dl_frame,
    input var         lowphy_dl_sof,
    input var         lowphy_dl_sos,
    input var  [32:0] lowphy_dl_frac,
    input var  [31:0] lowphy_dl_data,
    input var         lowphy_dl_valid,
    //
    output var [ 7:0] dl_frame,
    output var        dl_sof,
    output var        dl_sos,
    output var [31:0] dl_data,
    output var        dl_valid,
    //
    input var         ctrl_clk,
    input var         ctrl_rst,
    //
    input var  [ 3:0] dl_phase_comp_addr,
    input var         dl_phase_comp_en,
    input var         dl_phase_comp_we,
    input var  [31:0] dl_phase_comp_din,
    output var [31:0] dl_phase_comp_dout
);

  logic [ 7:0] current_frame;

  logic        fft_din_sof;
  logic        fft_din_sos;
  logic [31:0] fft_din_data;
  logic        fft_din_valid;

  logic        fft_dout_sof;
  logic        fft_dout_sos;
  logic [31:0] fft_dout_data;
  logic        fft_dout_valid;

  logic        conv_dout_sof;
  logic        conv_dout_sos;
  logic [31:0] conv_dout_data;
  logic        conv_dout_valid;

  logic        phase_comp_dout_sof;
  logic        phase_comp_dout_sos;
  logic [31:0] phase_comp_dout_data;
  logic        phase_comp_dout_valid;

  logic        dl_sof_s;
  logic        dl_sos_s;
  logic [31:0] dl_data_s;
  logic        dl_valid_s;

  // Convolution in frequency domain is equivalent to time shift in time domain.
  // In time domain we need to shift the waveform to the right (later) by
  // 88 or 72 samples. This is:
  //
  //   $$y = x .* exp(2j*pi*-88*k/N)$$
  //
  // Where k is the sample index, N is the FFT size (1024) and x is the input
  // waveform.
  //
  // PINC = dec2hex(mod(2^32*(-88)/1024, 2^32), 8)
  // POFF = 0
  //
  lowphy_conv #(
    .POFF_INIT_PARAM("00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000"),
    .PINC_INIT_PARAM("EA000000,EE000000,EE000000,EE000000,EE000000,EE000000,EE000000,EE000000,EE000000,EE000000,EE000000,EE000000,EE000000,EE000000")
  ) u_in_conv (
      .clk               (clk),
      .rst               (rst),
      //
      .din_sof           (lowphy_dl_sof),
      .din_sos           (lowphy_dl_sos),
      .din_data          (lowphy_dl_data),
      .din_valid         (lowphy_dl_valid),
      //
      .dout_sof          (fft_din_sof),
      .dout_sos          (fft_din_sos),
      .dout_data         (fft_din_data),
      .dout_valid        (fft_din_valid),
      //
      .ctrl_clk          (ctrl_clk),
      .ctrl_rst          (ctrl_rst),
      //
      .ctrl_poff_mem_en  (  /* not used */),
      .ctrl_poff_mem_we  (  /* not used */),
      .ctrl_poff_mem_addr(  /* not used */),
      .ctrl_poff_mem_din (  /* not used */),
      .ctrl_poff_mem_dout(  /* not used */),
      //
      .ctrl_pinc_mem_en  (  /* not used */),
      .ctrl_pinc_mem_we  (  /* not used */),
      .ctrl_pinc_mem_addr(  /* not used */),
      .ctrl_pinc_mem_din (  /* not used */),
      .ctrl_pinc_mem_dout(  /* not used */)
  );

  lowphy_transform #(
      .INIT_GAIN(INIT_GAIN),
      .MODE     (0)
  ) u_transform (
      .clk       (clk),
      .rst       (rst),
      //
      .din_sof   (fft_din_sof),
      .din_sos   (fft_din_sos),
      .din_data  (fft_din_data),
      .din_valid (fft_din_valid),
      //
      .dout_sof  (fft_dout_sof),
      .dout_sos  (fft_dout_sos),
      .dout_data (fft_dout_data),
      .dout_valid(fft_dout_valid)
  );

  // Convolution in time domain is equivalent to frequency shift. This input
  // waveform includes 88 or 72 points CP and left are symbol data.
  // To ensure the first sample of the symbol data has 0 phase shift, we need to
  // set the POFF base on the CP length.
  //
  // PINC = dec2hex(mod(2^32*(-612/2)/1024, 2^32), 8)
  // POFF = dec2hex(mod(2^32*(-612/2)*(-88)/1024, 2^32), 8)
  //
  lowphy_conv #(
    .POFF_INIT_PARAM("4C000000,84000000,84000000,84000000,84000000,84000000,84000000,84000000,84000000,84000000,84000000,84000000,84000000,84000000"),
    .PINC_INIT_PARAM("B3800000,B3800000,B3800000,B3800000,B3800000,B3800000,B3800000,B3800000,B3800000,B3800000,B3800000,B3800000,B3800000,B3800000")
  ) u_out_conv (
      .clk               (clk),
      .rst               (rst),
      //
      .din_sof           (fft_dout_sof),
      .din_sos           (fft_dout_sos),
      .din_data          (fft_dout_data),
      .din_valid         (fft_dout_valid),
      //
      .dout_sof          (conv_dout_sof),
      .dout_sos          (conv_dout_sos),
      .dout_data         (conv_dout_data),
      .dout_valid        (conv_dout_valid),
      //
      .ctrl_clk          (ctrl_clk),
      .ctrl_rst          (ctrl_rst),
      //
      .ctrl_poff_mem_en  (  /* not used */),
      .ctrl_poff_mem_we  (  /* not used */),
      .ctrl_poff_mem_addr(  /* not used */),
      .ctrl_poff_mem_din (  /* not used */),
      .ctrl_poff_mem_dout(  /* not used */),
      //
      .ctrl_pinc_mem_en  (  /* not used */),
      .ctrl_pinc_mem_we  (  /* not used */),
      .ctrl_pinc_mem_addr(  /* not used */),
      .ctrl_pinc_mem_din (  /* not used */),
      .ctrl_pinc_mem_dout(  /* not used */)
  );

  lowphy_phase_comp u_phase_comp (
      .clk                 (clk),
      .rst                 (rst),
      //
      .din_sof             (conv_dout_sof),
      .din_sos             (conv_dout_sos),
      .din_data            (conv_dout_data),
      .din_valid           (conv_dout_valid),
      //
      .dout_sof            (phase_comp_dout_sof),
      .dout_sos            (phase_comp_dout_sos),
      .dout_data           (phase_comp_dout_data),
      .dout_valid          (phase_comp_dout_valid),
      //
      .ctrl_clk            (ctrl_clk),
      .ctrl_rst            (ctrl_rst),
      //
      .ctrl_phase_comp_addr(dl_phase_comp_addr),
      .ctrl_phase_comp_en  (dl_phase_comp_en),
      .ctrl_phase_comp_we  (dl_phase_comp_we),
      .ctrl_phase_comp_din (dl_phase_comp_din),
      .ctrl_phase_comp_dout(dl_phase_comp_dout)
  );

  lowphy_ifft_out_buf u_out_buf (
      .clk       (clk),
      .rst       (rst),
      //
      .din_sof   (phase_comp_dout_sof),
      .din_sos   (phase_comp_dout_sos),
      .din_data  (phase_comp_dout_data),
      .din_valid (phase_comp_dout_valid),
      //
      .dout_sof  (dl_sof_s),
      .dout_sos  (dl_sos_s),
      .dout_data (dl_data_s),
      .dout_valid(dl_valid_s)
  );

  always_ff @(posedge clk) begin
    if (lowphy_dl_sof) begin
      current_frame <= lowphy_dl_frame;
    end
  end

  // Output registers

  always_ff @(posedge clk) begin
    if (dl_sof_s) begin
      dl_frame <= current_frame;
    end
  end

  always_ff @(posedge clk) begin
    dl_sof   <= dl_sof_s;
    dl_sos   <= dl_sos_s;
    dl_data  <= dl_data_s;
    dl_valid <= dl_valid_s;
  end

endmodule

`default_nettype wire

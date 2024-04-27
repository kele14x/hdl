// File: lowphy_fft.sv
// Brief: Low PHY processing. Generally consists input buffer, FFT, and
//        phase compensation. The total latency (from sof in to sof out)
//        is (12291+8344+17+17+8 = 20677 clock ticks (4206.75 ns @ 491.52 Mhz).
`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy_fft #(
    parameter bit [9:0] INIT_GAIN = 10'b0101010101
) (
    input var         clk,
    input var         rst,
    //
    output var [ 7:0] lowphy_ul_frame,
    output var        lowphy_ul_sof,
    output var        lowphy_ul_sos,
    output var [31:0] lowphy_ul_data,
    output var        lowphy_ul_valid,
    //
    input var  [ 7:0] ul_frame,
    input var         ul_sof,
    input var         ul_sos,
    input var  [32:0] ul_frac,
    input var  [31:0] ul_data,
    input var         ul_valid,
    //
    input var         ctrl_clk,
    input var         ctrl_rst,
    //
    input var  [ 3:0] ul_phase_comp_addr,
    input var         ul_phase_comp_en,
    input var         ul_phase_comp_we,
    input var  [31:0] ul_phase_comp_din,
    output var [31:0] ul_phase_comp_dout
);

  logic [ 7:0] current_frame;

  logic        buf_dout_sof;
  logic        buf_dout_sos;
  logic [31:0] buf_dout_data;
  logic        buf_dout_valid;

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

  logic        lowphy_ul_sof_s;
  logic        lowphy_ul_sos_s;
  logic [31:0] lowphy_ul_data_s;
  logic        lowphy_ul_valid_s;

  lowphy_fft_in_buf u_in_buf (
      .clk       (clk),
      .rst       (rst),
      //
      .din_sof   (ul_sof),
      .din_sos   (ul_sos),
      .din_data  (ul_data),
      .din_valid (ul_valid),
      //
      .dout_sof  (buf_dout_sof),
      .dout_sos  (buf_dout_sos),
      .dout_data (buf_dout_data),
      .dout_valid(buf_dout_valid)
  );

  // Frequnecy shift 1638 SCS, so first sample output from FFT is first RE data
  lowphy_conv #(
    .POFF_INIT_PARAM("00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000"),
    .PINC_INIT_PARAM("4C800000,4C800000,4C800000,4C800000,4C800000,4C800000,4C800000,4C800000,4C800000,4C800000,4C800000,4C800000,4C800000,4C800000")
  ) u_in_conv (
      .clk               (clk),
      .rst               (rst),
      //
      .din_sof           (buf_dout_sof),
      .din_sos           (buf_dout_sos),
      .din_data          (buf_dout_data),
      .din_valid         (buf_dout_valid),
      //
      .dout_sof          (fft_din_sof),
      .dout_sos          (fft_din_sos),
      .dout_data         (fft_din_data),
      .dout_valid        (fft_din_valid),
      // Control & Status
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
      .MODE     (1)
  ) u_fft_core (
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

  // Frequecy conv for time domain shift
  lowphy_conv #(
    .POFF_INIT_PARAM("00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000"),
    .PINC_INIT_PARAM("00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000")
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
      // Control & Status
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
      .dout_sof            (lowphy_ul_sof_s),
      .dout_sos            (lowphy_ul_sos_s),
      .dout_data           (lowphy_ul_data_s),
      .dout_valid          (lowphy_ul_valid_s),
      // Control & Status
      .ctrl_clk            (ctrl_clk),
      .ctrl_rst            (ctrl_rst),
      //
      .ctrl_phase_comp_addr(ul_phase_comp_addr),
      .ctrl_phase_comp_en  (ul_phase_comp_en),
      .ctrl_phase_comp_we  (ul_phase_comp_we),
      .ctrl_phase_comp_din (ul_phase_comp_din),
      .ctrl_phase_comp_dout(ul_phase_comp_dout)
  );

  always_ff @(posedge clk) begin
    if (ul_sof) begin
      current_frame <= ul_frame;
    end
  end

  // Output registers

  always_ff @(posedge clk) begin
    if (lowphy_ul_sof_s) begin
      lowphy_ul_frame <= current_frame;
    end
  end

  always_ff @(posedge clk) begin
    lowphy_ul_sof   <= lowphy_ul_sof_s;
    lowphy_ul_sos   <= lowphy_ul_sos_s;
    lowphy_ul_data  <= lowphy_ul_data_s;
    lowphy_ul_valid <= lowphy_ul_valid_s;
  end

endmodule

`default_nettype wire

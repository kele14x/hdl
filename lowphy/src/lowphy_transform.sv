// File: lowphy_transform.sv
// Brief: Latency 3202 clock ticks
`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy_transform #(
    parameter bit [9:0] INIT_GAIN = 10'b0101010101,  // shift by 1 at each radix-4 stage
    parameter int       MODE      = 0                // 0 for DL (iFFT), 1 for UL (FFT)
) (
    input var         clk,
    input var         rst,
    //
    input var         din_sof,
    input var         din_sos,
    input var  [31:0] din_data,
    input var         din_valid,
    //
    output var        dout_sof,
    output var        dout_sos,
    output var [31:0] dout_data,
    output var        dout_valid
);

  // First sample to first sample latency of FFT core
  // Xilinx FFT IP reports latency from first sample of input to last sample
  // of output. So the latency reported at GUI should be subtracted by 1024
  localparam int FftCoreLatency = 3202;

  logic        fft_config_done;
  logic [ 9:0] fft_scale_sch;
  logic        fft_fwd_inv;

  logic [15:0] s_axis_config_tdata;
  logic        s_axis_config_tready;
  logic        s_axis_config_tvalid;

  logic        din_last;

  logic [31:0] s_axis_data_tdata;
  logic        s_axis_data_tlast;
  logic        s_axis_data_tvalid;
  logic        s_axis_data_tready;

  logic [31:0] m_axis_data_tdata;
  logic        m_axis_data_tlast;
  logic        m_axis_data_tvalid;

  logic [14:0] current_sample;
  logic [ 8:0] current_symbol;  // 0 ~ 279


  // Generate FFT config
  // FFT is configured at every reset

  always_ff @(posedge clk) begin
    if (rst) begin
      fft_config_done <= 1'b0;
    end else if (s_axis_config_tvalid && s_axis_config_tready) begin
      fft_config_done <= 1'b1;
    end
  end

  assign fft_scale_sch = INIT_GAIN;  // shift by 1 at each radix-4 stage
  assign fft_fwd_inv = MODE;  // 0 for iFFT, 1 for FFT
  assign s_axis_config_tdata = {5'b0, fft_scale_sch, fft_fwd_inv};

  always_ff @(posedge clk) begin
    if (rst) begin
      s_axis_config_tvalid <= 1'b0;
    end else if (s_axis_config_tvalid && s_axis_config_tready) begin
      s_axis_config_tvalid <= 1'b0;
    end else if (!fft_config_done) begin
      s_axis_config_tvalid <= 1'b1;
    end else begin
      s_axis_config_tvalid <= 1'b0;
    end
  end


  // FFT input

  // Reset to all 1s ensures we does not got SOF/SOS until we receive first SOF
  // after reset.
  always_ff @(posedge clk) begin
    if (rst) begin
      current_sample <= '1;
    end else if(din_sos) begin
      current_sample <= '0;
    end else if (~&current_sample) begin
      current_sample <= current_sample + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      current_symbol <= '1;
    end else if (din_sof) begin
      current_symbol <= '0;
    end else if (din_sos) begin
      current_symbol <= current_symbol + 1;
    end
  end

  always_ff @(posedge clk) begin
    din_last <= (current_sample == 1021);
  end


  // The FFT Core

  // The FFT core is not always ready, it may de-assert for 1 clock at some
  // point at beginning of frame. To be lazy, we add a FIFO here to handle the
  // backward pressure. This is FIFO is will not be full. And a very small FIFO
  // is enough.
  xpm_fifo_axis #(
      .CASCADE_HEIGHT     (0),
      .CDC_SYNC_STAGES    (2),
      .CLOCKING_MODE      ("common_clock"),
      .ECC_MODE           ("no_ecc"),
      .FIFO_DEPTH         (16),
      .FIFO_MEMORY_TYPE   ("distributed"),
      .PACKET_FIFO        ("false"),
      .PROG_EMPTY_THRESH  (10),
      .PROG_FULL_THRESH   (10),
      .RD_DATA_COUNT_WIDTH(5),
      .RELATED_CLOCKS     (0),
      .SIM_ASSERT_CHK     (0),
      .TDATA_WIDTH        (32),
      .TDEST_WIDTH        (1),
      .TID_WIDTH          (1),
      .TUSER_WIDTH        (1),
      .USE_ADV_FEATURES   ("0000"),
      .WR_DATA_COUNT_WIDTH(5)
  ) xpm_fifo_axis_inst (
      .s_aclk            (clk),
      .s_aresetn         (~rst),
      //
      .s_axis_tdata      (din_data),
      .s_axis_tdest      ('0),
      .s_axis_tid        ('0),
      .s_axis_tkeep      ('0),
      .s_axis_tlast      (din_last),
      .s_axis_tstrb      ('0),
      .s_axis_tuser      ('0),
      .s_axis_tvalid     (din_valid),
      .s_axis_tready     (),
      //
      .wr_data_count_axis(),
      .prog_full_axis    (),
      .almost_full_axis  (),
      //
      .injectsbiterr_axis('0),
      .injectdbiterr_axis('0),
      //
      .m_aclk            (clk),
      //
      .m_axis_tdata      (s_axis_data_tdata),
      .m_axis_tdest      (),
      .m_axis_tid        (),
      .m_axis_tkeep      (),
      .m_axis_tlast      (s_axis_data_tlast),
      .m_axis_tstrb      (),
      .m_axis_tuser      (),
      .m_axis_tvalid     (s_axis_data_tvalid),
      .m_axis_tready     (s_axis_data_tready),
      //
      .rd_data_count_axis(),
      .prog_empty_axis   (),
      .almost_empty_axis (),
      //
      .sbiterr_axis      (),
      .dbiterr_axis      ()
  );

  // FFT core latency `FftCoreLatency`
  ifft_1ch_4k_p u_ifft_1ch_4k_p (
      .aclk                      (clk),
      .aresetn                   (~rst),
      //
      .s_axis_config_tdata       (s_axis_config_tdata),
      .s_axis_config_tvalid      (s_axis_config_tvalid),
      .s_axis_config_tready      (s_axis_config_tready),
      //
      .s_axis_data_tdata         (s_axis_data_tdata),
      .s_axis_data_tvalid        (s_axis_data_tvalid),
      .s_axis_data_tready        (s_axis_data_tready),
      .s_axis_data_tlast         (s_axis_data_tlast),
      //
      .m_axis_data_tdata         (m_axis_data_tdata),
      .m_axis_data_tvalid        (m_axis_data_tvalid),
      .m_axis_data_tlast         (m_axis_data_tlast),
      //
      .event_frame_started       (),
      .event_tlast_unexpected    (),
      .event_tlast_missing       (),
      .event_data_in_channel_halt()
  );

  assign dout_data  = m_axis_data_tdata;

  assign dout_valid = m_axis_data_tvalid;

  always_ff @(posedge clk) begin
    dout_sof <= ((current_symbol == 0) && (current_sample == FftCoreLatency - 1024 + 1));
  end

  always_ff @(posedge clk) begin
    dout_sos <= (current_sample == FftCoreLatency - 1024 + 1);
  end

endmodule

`default_nettype wire

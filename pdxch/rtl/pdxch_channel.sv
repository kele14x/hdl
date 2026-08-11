`timescale 1 ns / 1 ps
//
`default_nettype none

module pdxch_channel #(
    parameter int HAS_CDC    = 1,
    parameter int NUM_ANT    = 4,
    parameter int HALF_BLOCK = 0,
    parameter int HALF_FFT   = 0
) (
    // Clock & Reset
    //--------------
    input  wire        clk,
    input  wire        rst,
    // 4 ant sequential
    input  wire [15:0] din_dr,
    input  wire [15:0] din_di,
    input  wire        din_sf,
    input  wire        din_sl,
    input  wire        din_sy,
    input  wire [ 3:0] din_chn,
    input  wire        din_dv,
    input  wire        din_last,
    //
    output wire [31:0] m_axis_tdata        [NUM_ANT],
    output wire [ 7:0] m_axis_tuser        [NUM_ANT],
    output wire        m_axis_tlast        [NUM_ANT],
    output wire        m_axis_tvalid       [NUM_ANT],
    input  wire        m_axis_tready       [NUM_ANT],
    // CSR
    //----
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    input  wire [ 1:0] ctrl_rat,
    input  wire [ 3:0] ctrl_bw,
    input  wire [16:0] ctrl_gain           [NUM_ANT],
    //
    input  wire [ 3:0] ctrl_phase_comp_addr,
    input  wire        ctrl_phase_comp_we,
    input  wire [31:0] ctrl_phase_comp_din
);

  localparam int LogFftSize = (HALF_FFT != 0) ? 11 : 12;

  // HALF_BLOCK is retained for compatibility with existing instantiations.
  wire unused_half_block = &{1'b0, HALF_BLOCK};

  // Signals

  logic [15:0] gain_dout_dr;
  logic [15:0] gain_dout_di;
  logic        gain_dout_sf;
  logic        gain_dout_sl;
  logic        gain_dout_sy;
  logic [ 3:0] gain_dout_chn;
  logic        gain_dout_dv;
  logic        gain_dout_last;

  logic [15:0] pre_conv_dout_dr;
  logic [15:0] pre_conv_dout_di;
  logic        pre_conv_dout_sf;
  logic        pre_conv_dout_sl;
  logic        pre_conv_dout_sy;
  logic [ 3:0] pre_conv_dout_chn;
  logic        pre_conv_dout_dv;
  logic        pre_conv_dout_last;

  logic [15:0] fft_dout_dr;
  logic [15:0] fft_dout_di;
  logic        fft_dout_sf;
  logic        fft_dout_sl;
  logic        fft_dout_sy;
  logic [ 3:0] fft_dout_chn;
  logic        fft_dout_dv;
  logic        fft_dout_last;

  logic [15:0] phase_comp_dout_dr;
  logic [15:0] phase_comp_dout_di;
  logic        phase_comp_dout_sf;
  logic        phase_comp_dout_sl;
  logic        phase_comp_dout_sy;
  logic [ 3:0] phase_comp_dout_chn;
  logic        phase_comp_dout_dv;
  logic        phase_comp_dout_last;

  logic [ 1:0] ctrl_size;
  logic [ 1:0] ctrl_itlv;
  logic        unused_fft_stat_ovf;

  // Main

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_rat == 2'b00) begin  // LTE
      ctrl_size <= 2'b01;  // 2k
    end else if (ctrl_rat == 2'b01) begin  // NR 15 kHz SCS
      case (ctrl_bw)
        4'd0:    ctrl_size <= 2'b01; // 2k
        4'd1:    ctrl_size <= 2'b01; // 2k
        4'd2:    ctrl_size <= 2'b01; // 2k
        default: ctrl_size <= 2'b10; // 4k
      endcase
    end else begin  // NR 30kHz SCS
      case (ctrl_bw)
        4'd0:    ctrl_size <= 2'b00; // 1k
        4'd1:    ctrl_size <= 2'b00; // 1k
        4'd2:    ctrl_size <= 2'b00; // 1k
        4'd3:    ctrl_size <= 2'b01; // 2k
        default: ctrl_size <= 2'b10; // 4k
      endcase
    end
  end

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_rat == 2'b00) begin  // LTE
      ctrl_itlv <= 2'b00;  // 16
    end else if (ctrl_rat == 2'b01) begin  // NR 15 kHz SCS
      case (ctrl_bw)
        4'd0:    ctrl_itlv <= 2'b00; // 16
        4'd1:    ctrl_itlv <= 2'b00; // 16
        4'd2:    ctrl_itlv <= 2'b00; // 16
        default: ctrl_itlv <= 2'b01; // 8
      endcase
    end else begin  // NR 30kHz SCS
      case (ctrl_bw)
        4'd0:    ctrl_itlv <= 2'b00; // 16
        4'd1:    ctrl_itlv <= 2'b00; // 16
        4'd2:    ctrl_itlv <= 2'b00; // 16
        4'd3:    ctrl_itlv <= 2'b01; // 8
        default: ctrl_itlv <= 2'b10; // 4
      endcase
    end
  end

  gain #(
      .HAS_CDC   (HAS_CDC),
      .NUM_ANT   (NUM_ANT),
      .COMPLEX   (0),
      .GAIN_WIDTH(17)
  ) u_gain (
      .clk         (clk),
      .rst         (rst),
      //
      .din_dr      (din_dr),
      .din_di      (din_di),
      .din_sf      (din_sf),
      .din_sl      (din_sl),
      .din_sy      (din_sy),
      .din_chn     (din_chn),
      .din_dv      (din_dv),
      .din_last    (din_last),
      //
      .dout_dr     (gain_dout_dr),
      .dout_di     (gain_dout_di),
      .dout_sf     (gain_dout_sf),
      .dout_sl     (gain_dout_sl),
      .dout_sy     (gain_dout_sy),
      .dout_chn    (gain_dout_chn),
      .dout_dv     (gain_dout_dv),
      .dout_last   (gain_dout_last),
      //
      .ctrl_gain_dr(ctrl_gain),
      .ctrl_gain_di('{NUM_ANT{'0}})
  );

  pdxch_conv #(
      .HAS_CDC(HAS_CDC),
      .NUM_ANT(NUM_ANT)
  ) u_pre_conv (
      .clk      (clk),
      .rst      (rst),
      //
      .din_dr   (gain_dout_dr),
      .din_di   (gain_dout_di),
      .din_sf   (gain_dout_sf),
      .din_sl   (gain_dout_sl),
      .din_sy   (gain_dout_sy),
      .din_chn  (gain_dout_chn),
      .din_dv   (gain_dout_dv),
      .din_last (gain_dout_last),
      //
      .dout_dr  (pre_conv_dout_dr),
      .dout_di  (pre_conv_dout_di),
      .dout_sf  (pre_conv_dout_sf),
      .dout_sl  (pre_conv_dout_sl),
      .dout_sy  (pre_conv_dout_sy),
      .dout_chn (pre_conv_dout_chn),
      .dout_dv  (pre_conv_dout_dv),
      .dout_last(pre_conv_dout_last),
      //
      .ctrl_rat (ctrl_rat),
      .ctrl_bw  (ctrl_bw)
  );

  fft #(
      .NUM_ANT           (NUM_ANT),
      .INV_FFT           (1'b1),
      .LOG_FFT_SIZE      (LogFftSize),
      .DATA_WIDTH        (16),
      .BIT_REVERSED_INPUT(1'b1)
  ) u_fft (
      .clk      (clk),
      .rst      (rst),
      //
      .din_dr   (pre_conv_dout_dr),
      .din_di   (pre_conv_dout_di),
      .din_sf   (pre_conv_dout_sf),
      .din_sl   (pre_conv_dout_sl),
      .din_sy   (pre_conv_dout_sy),
      .din_chn  (pre_conv_dout_chn),
      .din_dv   (pre_conv_dout_dv),
      .din_last (pre_conv_dout_last),
      //
      .dout_dr  (fft_dout_dr),
      .dout_di  (fft_dout_di),
      .dout_sf  (fft_dout_sf),
      .dout_sl  (fft_dout_sl),
      .dout_sy  (fft_dout_sy),
      .dout_chn (fft_dout_chn),
      .dout_dv  (fft_dout_dv),
      .dout_last(fft_dout_last),
      //
      .ctrl_size(ctrl_size),
      .ctrl_itlv(ctrl_itlv),
      //
      .stat_ovf (unused_fft_stat_ovf)
  );

  phase_comp #(
      .HAS_CDC(HAS_CDC),
      .NUM_ANT(NUM_ANT)
  ) u_phase_comp (
      .clk                 (clk),
      .rst                 (rst),
      //
      .din_dr              (fft_dout_dr),
      .din_di              (fft_dout_di),
      .din_sf              (fft_dout_sf),
      .din_sl              (fft_dout_sl),
      .din_sy              (fft_dout_sy),
      .din_chn             (fft_dout_chn),
      .din_dv              (fft_dout_dv),
      .din_last            (fft_dout_last),
      //
      .dout_dr             (phase_comp_dout_dr),
      .dout_di             (phase_comp_dout_di),
      .dout_sf             (phase_comp_dout_sf),
      .dout_sl             (phase_comp_dout_sl),
      .dout_sy             (phase_comp_dout_sy),
      .dout_chn            (phase_comp_dout_chn),
      .dout_dv             (phase_comp_dout_dv),
      .dout_last           (phase_comp_dout_last),
      //----
      .ctrl_clk            (ctrl_clk),
      .ctrl_rst            (ctrl_rst),
      //
      .ctrl_rat            (ctrl_rat),
      //
      .ctrl_phase_comp_addr(ctrl_phase_comp_addr),
      .ctrl_phase_comp_we  (ctrl_phase_comp_we),
      .ctrl_phase_comp_din (ctrl_phase_comp_din)
  );

  pdxch_block2stream #(
      .NUM_ANT(NUM_ANT)
  ) u_block2stream (
      .clk          (clk),
      .rst          (rst),
      //
      .din_dr       (phase_comp_dout_dr),
      .din_di       (phase_comp_dout_di),
      .din_sf       (phase_comp_dout_sf),
      .din_sl       (phase_comp_dout_sl),
      .din_sy       (phase_comp_dout_sy),
      .din_chn      (phase_comp_dout_chn),
      .din_dv       (phase_comp_dout_dv),
      .din_last     (phase_comp_dout_last),
      //
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tuser (m_axis_tuser),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tready(m_axis_tready)
  );

endmodule

`default_nettype wire

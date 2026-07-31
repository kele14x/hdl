`timescale 1 ns / 1 ps
//
`default_nettype none

module pdxch_conv #(
    parameter bit HAS_CDC = 1'b0,
    parameter int NUM_ANT = 4
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [15:0] din_dr,
    input  wire [15:0] din_di,
    input  wire        din_sf,
    input  wire        din_sl,
    input  wire        din_sy,
    input  wire [ 3:0] din_chn,
    input  wire        din_dv,
    input  wire        din_last,
    //
    output wire [15:0] dout_dr,
    output wire [15:0] dout_di,
    output wire        dout_sf,
    output wire        dout_sl,
    output wire        dout_sy,
    output wire [ 3:0] dout_chn,
    output wire        dout_dv,
    output wire        dout_last,
    // CSR
    //----
    input  wire [ 1:0] ctrl_rat,
    input  wire [ 3:0] ctrl_bw
);

  // FFT Size table:
  //-------+---------+---------+
  // Mu:   |    0    |    1    |
  //-------+---------+---------+
  // BW: 0 |    2048 |    1024 |
  //     1 |    2048 |    1024 |
  //     2 |    2048 |    1024 |
  //     3 |    4096 |    2048 |
  //-------+---------+---------+

  // CP Length table:
  //-------+---------+---------+
  // Mu:   |    0    |    1    |
  //-------+---------+---------+
  // BW: 0 | 160/144 |  88/ 72 |
  //     1 | 160/144 |  88/ 72 |
  //     2 | 160/144 |  88/ 72 |
  //     3 | 320/288 | 176/144 |
  //-------+---------+---------+

  localparam int Latency = 15;
  localparam int AntAddrWidth = $clog2(NUM_ANT);

  // Signals

  logic        [ 1:0] ctrl_rat_s;
  logic        [ 3:0] ctrl_bw_s;

  logic        [11:0] index            [NUM_ANT];
  logic        [11:0] index_next;
  logic        [11:0] index_r;

  logic        [ 2:0] fft_size;

  logic        [11:0] index_rev;

  logic        [ 6:0] pinc             [NUM_ANT];
  logic        [ 6:0] pinc_next;
  logic        [ 6:0] pinc_r;

  logic        [ 6:0] phase;

  logic signed [15:0] cos;
  logic signed [15:0] sin;

  logic signed [15:0] din_dr_d;
  logic signed [15:0] din_di_d;
  logic               unused_mult_ovf;
  logic               unused_cmult_ovf;

  // Main

  generate
    if (HAS_CDC) begin : g_cdc

      cdc_array_single #(
          .DEST_SYNC_FF (2),
          .INIT_SYNC_FF (0),
          .SRC_INPUT_REG(0),
          .WIDTH        (2)
      ) i_cdc_ctrl_rat (
          .src_clk (1'b1),
          .src_in  (ctrl_rat),
          //
          .dest_clk(clk),
          .dest_out(ctrl_rat_s)
      );

      cdc_array_single #(
          .DEST_SYNC_FF (2),
          .INIT_SYNC_FF (0),
          .SRC_INPUT_REG(0),
          .WIDTH        (4)
      ) i_cdc_ctrl_bw (
          .src_clk (1'b1),
          .src_in  (ctrl_bw),
          //
          .dest_clk(clk),
          .dest_out(ctrl_bw_s)
      );

    end else begin : g_no_cdc

      assign ctrl_rat_s = ctrl_rat;
      assign ctrl_bw_s  = ctrl_bw;

    end
  endgenerate

  always_comb begin
    if (~ctrl_rat_s[1]) begin  // 15 kHz SCS
      case (ctrl_bw_s)
        4'b0000: fft_size = 3'd2;  // 7.68 (30.72), 2k
        4'b0001: fft_size = 3'd2;  // 15.36 (30.72), 2k
        4'b0010: fft_size = 3'd2;  // 30.72, 2k
        default: fft_size = 3'd1;  // 61.44, 4k
      endcase
    end else begin
      case (ctrl_bw_s)
        4'b0000: fft_size = 3'd4;  // 7.68 (30.72), 1k
        4'b0001: fft_size = 3'd4;  // 15.36 (30.72), 1k
        4'b0010: fft_size = 3'd4;  // 30.72, 1k
        4'b0011: fft_size = 3'd2;  // 61.44, 2k
        default: fft_size = 3'd1;  // 122.88, 4k
      endcase
    end
  end

  always_comb begin
    if (din_sy) begin
      index_next = '0;
    end else if (din_dv && (din_chn < 4'(NUM_ANT))) begin
      index_next = index[din_chn[AntAddrWidth-1:0]] + {9'd0, fft_size};
    end else begin
      index_next = '0;
    end
  end

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_index

      always_ff @(posedge clk) begin
        if (rst) begin
          index[i] <= '0;
        end else if (din_chn == i) begin
          index[i] <= index_next;
        end
      end

    end
  endgenerate

  always_comb begin
    for (int i = 0; i < 12; i++) begin
      index_rev[i] = index_next[11-i];
    end
  end

  always_ff @(posedge clk) begin
    index_r <= index_rev;
  end

  always_comb begin
    if (din_sl) begin
      pinc_next = (ctrl_rat_s == 0) ? -7'sd10 : -7'sd11;
    end else if (din_sy) begin
      pinc_next = -7'sd9;
    end else if (din_dv && (din_chn < 4'(NUM_ANT))) begin
      pinc_next = pinc[din_chn[AntAddrWidth-1:0]];
    end else begin
      pinc_next = '0;
    end
  end

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_pinc
      always_ff @(posedge clk) begin
        if (rst) begin
          pinc[i] <= '0;
        end else if (din_chn == i) begin
          pinc[i] <= pinc_next;
        end
      end
    end
  endgenerate

  always_ff @(posedge clk) begin
    pinc_r <= pinc_next;
  end

  mult #(
      .A_WIDTH(12),
      .B_WIDTH(7),
      .P_WIDTH(7),
      .SHIFT  (0)
  ) u_mult (
      .clk(clk),
      .rst(rst),
      //
      .a  (index_r),
      .b  (pinc_r),
      .p  (phase),
      //
      .ovf(unused_mult_ovf)
  );

  pdxch_conv_nco u_nco (
      .clk  (clk),
      .phase(phase),
      .cos  (cos),
      .sin  (sin)
  );

  // Match NCO latency: 1 + 4 + 3
  delay #(
      .WIDTH(32),
      .DEPTH(8),
      .INIT (1'b0)
  ) u_dq_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({din_di, din_dr}),
      .dout({din_di_d, din_dr_d})
  );

  cmult #(
      .USE_3_MULT(1'b0),
      .A_WIDTH(16),
      .B_WIDTH(16),
      .P_WIDTH(16),
      .SHIFT(14)
  ) u_cmult (
      .clk(clk),
      .rst(rst),
      //
      .ar (din_dr_d),
      .ai (din_di_d),
      //
      .br (cos),
      .bi (sin),
      //
      .pr (dout_dr),
      .pi (dout_di),
      //
      .ovf(unused_cmult_ovf)
  );

  delay #(
      .WIDTH(9),
      .DEPTH(Latency),
      .INIT (1'b0)
  ) u_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({din_last, din_dv, din_chn, din_sy, din_sl, din_sf}),
      .dout({dout_last, dout_dv, dout_chn, dout_sy, dout_sl, dout_sf})
  );

endmodule

`default_nettype wire

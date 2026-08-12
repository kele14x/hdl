`timescale 1 ns / 1 ps
//
`default_nettype none

module puxch_conv #(
    parameter int NUM_ANT = 4
) (
    input var         clk,
    input var         rst,
    //
    input var  [15:0] din_dr,
    input var  [15:0] din_di,
    input var         din_sf,
    input var         din_sl,
    input var         din_sy,
    input var  [ 3:0] din_chn,
    input var         din_dv,
    input var         din_last,
    //
    output var [15:0] dout_dr,
    output var [15:0] dout_di,
    output var        dout_sf,
    output var        dout_sl,
    output var        dout_sy,
    output var [ 3:0] dout_chn,
    output var        dout_dv,
    output var        dout_last,
    // CSR
    //----
    input var  [ 1:0] ctrl_rat,
    input var  [ 3:0] ctrl_bw,
    input var  [ 8:0] ctrl_nprb
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

  // index/NCO (9 cycles) followed by the four-multiplier cmult pipeline
  // produces data 14 cycles after the input sample.  Keep metadata aligned
  // with that observed interface latency.
  localparam int Latency = 14;

  // Signals

  logic [ 1:0] ctrl_rat_s;
  logic [ 3:0] ctrl_bw_s;
  logic [ 8:0] ctrl_nprb_s;

  logic [ 3:0] fft_size;

  logic [11:0] index       [NUM_ANT];
  logic [11:0] index_next;
  logic [11:0] index_r;
  logic [11:0] index_mask;

  logic        valid       [NUM_ANT];
  logic        valid_next;
  logic        valid_r;

  logic        last;

  localparam int AntIndexWidth = (NUM_ANT <= 1) ? 1 : $clog2(NUM_ANT);

  wire [AntIndexWidth-1:0] din_chn_idx;

  assign din_chn_idx = din_chn[AntIndexWidth-1:0];

  logic        [11:0] pinc_r;

  logic        [11:0] phase;

  logic signed [15:0] cos;
  logic signed [15:0] sin;

  logic signed [15:0] din_dr_d;
  logic signed [15:0] din_di_d;
  logic               mult_ovf;
  logic               cmult_ovf;


  // CDC for control signals

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (2 + 4 + 9)
  ) u_ctrl_cdc (
      .src_clk (1'b1),
      .src_in  ({ctrl_nprb, ctrl_bw, ctrl_rat}),
      //
      .dest_clk(clk),
      .dest_out({ctrl_nprb_s, ctrl_bw_s, ctrl_rat_s})
  );

  // Main

  always_comb begin
    if (ctrl_rat_s == 0) begin  // LTE
      fft_size = 4'd2;  // 2k
    end else if (ctrl_rat_s == 1) begin  // 15 kHz SCS NR
      case (ctrl_bw_s)
        4'b0000: fft_size = 4'd2;  // 7.68 (30.72), 2k
        4'b0001: fft_size = 4'd2;  // 15.36 (30.72), 2k
        4'b0010: fft_size = 4'd2;  // 30.72, 2k
        default: fft_size = 4'd1;  // 61.44, 4k
      endcase
    end else begin
      case (ctrl_bw_s)
        4'b0000: fft_size = 4'd4;  // 7.68 (30.72), 1k
        4'b0001: fft_size = 4'd4;  // 15.36 (30.72), 1k
        4'b0010: fft_size = 4'd4;  // 30.72, 1k
        4'b0011: fft_size = 4'd2;  // 61.44, 2k
        default: fft_size = 4'd1;  // 122.88, 4k
      endcase
    end
  end

  // Index counter

  always_comb begin
    if (ctrl_rat_s == 0) begin  // LTE
      index_mask = 12'hFFE;  // 2k
    end else if (ctrl_rat_s == 1) begin  // 15 kHz SCS NR
      case (ctrl_bw_s)
        4'b0000: index_mask = 12'hFFE;  // 7.68 (30.72), 2k
        4'b0001: index_mask = 12'hFFE;  // 15.36 (30.72), 2k
        4'b0010: index_mask = 12'hFFE;  // 30.72, 2k
        default: index_mask = 12'hFFF;  // 61.44, 4k
      endcase
    end else begin
      case (ctrl_bw_s)
        4'b0000: index_mask = 12'hFFC;  // 7.68 (30.72), 1k
        4'b0001: index_mask = 12'hFFC;  // 15.36 (30.72), 1k
        4'b0010: index_mask = 12'hFFC;  // 30.72, 1k
        4'b0011: index_mask = 12'hFFE;  // 61.44, 2k
        default: index_mask = 12'hFFF;  // 122.88, 4k
      endcase
    end
  end

  always_comb begin
    if (din_sy) begin
      index_next = '0;
    end else if (din_dv && (din_chn < 4'(NUM_ANT))) begin
      index_next = (index[din_chn_idx] + 12'(fft_size));
    end else begin
      index_next = '0;
    end
  end

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_ch

      always_ff @(posedge clk) begin
        if (rst) begin
          index[i] <= '0;
        end else if (din_chn == i) begin
          index[i] <= index_next;
        end
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    index_r <= index_next;
  end

  // Valid & Last marker

  always_comb begin
    if (din_sy) begin
      valid_next = din_dv;
    end else if (din_dv && (din_chn < 4'(NUM_ANT))) begin
      valid_next = ((index[din_chn_idx] == index_mask) ? 1'b0 : valid[din_chn_idx]);
    end else begin
      valid_next = 1'b0;
    end
  end

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_ch_v

      always_ff @(posedge clk) begin
        if (rst) begin
          valid[i] <= 1'b0;
        end else if (din_chn == i) begin
          valid[i] <= valid_next;
        end
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    valid_r <= valid_next;
  end

  always_ff @(posedge clk) begin
    last <= valid_next && (index_next == index_mask) && din_dv;
  end

  // PINC
  // PINC is the FCW for NCW, unit one half SC

  always_ff @(posedge clk) begin
    if (ctrl_rat_s == 0) begin  // LTE, half SCS shift
      pinc_r <= (ctrl_nprb_s * 12) - 1;
    end else begin
      pinc_r <= (ctrl_nprb_s * 12);
    end
  end

  // phase = $unsigned(index_r) * $unsigned(pinc_r) / 2, then truncate to 12-bit

  mult #(
      .A_WIDTH (13),
      .B_WIDTH (13),
      .P_WIDTH (12),
      .SHIFT   (1),
      //
      .ROUND   (0),
      .SATURATE(0)
  ) u_mult (
      .clk(clk),
      .rst(rst),
      //
      .a  ({1'b0, index_r}),
      .b  ({1'b0, pinc_r}),
      .p  (phase),
      .ovf(mult_ovf)
      //
  );

  dds_lut #(
      .STRUCTURE   ("AUTO"),
      .RASTERIZED  (0),
      .DATA_WIDTH  (16),
      .PHASE_WIDTH (12),
      .NEGATIVE_COS(0),
      .NEGATIVE_SIN(0)
  ) u_dds_lut (
      .clk    (clk),
      .rst    (rst),
      //
      .phase  (phase),
      //
      .cos_out(cos),
      .sin_out(sin)
  );

  // Match NCO latency: 1 + 4 + 4
  delay #(
      .WIDTH(32),
      .DEPTH(9)
  ) u_data_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({din_di, din_dr}),
      .dout({din_di_d, din_dr_d})
  );

  cmult #(
      .USE_3_MULT(0),
      .A_WIDTH (16),
      .B_WIDTH (16),
      .P_WIDTH (16),
      .SHIFT   (15),
      //
      .ROUND   (1),
      .SATURATE(0)
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
      .ovf(cmult_ovf)
      //
  );

  delay #(
      .WIDTH(7),
      .DEPTH(Latency)
  ) u_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({din_chn, din_sy, din_sl, din_sf}),
      .dout({dout_chn, dout_sy, dout_sl, dout_sf})
  );

  delay #(
      .WIDTH(2),
      .DEPTH(Latency - 1)
  ) u_delay_last (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({last, valid_r}),
      .dout({dout_last, dout_dv})
  );

  wire unused_conv = &{1'b0, din_last, mult_ovf, cmult_ovf};

endmodule

`default_nettype wire

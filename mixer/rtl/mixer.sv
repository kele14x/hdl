`timescale 1 ns / 1 ps
//
`default_nettype none

module mixer #(
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
    // Control signals
    input  wire [19:0] ctrl_pinc[NUM_ANT],
    input  wire [19:0] ctrl_poff[NUM_ANT]
);

  // Local parameters

  localparam int Latency = 13;

  // Helper functions

  function automatic logic [19:0] phase_add;
    input logic [19:0] phase;
    input logic [19:0] inc;
    begin
      logic [20:0] temp;
      temp = phase + inc;
      if (temp[20:18] >= 3'b011) begin
        temp[20:18] = temp[20:18] - 3'b011;
      end
      phase_add = temp[19:0];
    end
  endfunction

  function automatic logic [19:0] phase_correct;
    input logic [19:0] phase;
    input logic [19:0] lfsr;
    begin
      logic [32:0] temp;
      temp = {phase, 12'b0} + lfsr;
      if (temp[32:30] >= 3'b011) begin
        temp[32:30] = temp[32:30] - 3'b011;
      end
      phase_correct = temp[31:12];
    end
  endfunction

  // Signals

  logic [19:0] ctrl_pinc_s[NUM_ANT];
  logic [19:0] ctrl_poff_s[NUM_ANT];

  logic [15:0] din_dr_d;
  logic [15:0] din_di_d;

  logic [15:0] nco_dr;
  logic [15:0] nco_di;

  logic [19:0] phase      [NUM_ANT];
  logic [19:0] phase_next;
  logic [19:0] phase_r;
  logic [19:0] phase_lfsr;

  logic [19:0] lfsr;

  logic [11:0] phase_lut;

  // Main

  generate
    if (HAS_CDC) begin : g_cdc
      for (genvar i = 0; i < NUM_ANT; i = i + 1) begin : g_ch

        cdc_array_single #(
            .DEST_SYNC_FF (2),
            .INIT_SYNC_FF (0),
            .SRC_INPUT_REG(0),
            .WIDTH        (20)
        ) i_cdc_pinc (
            .src_clk (1'b1),
            .src_in  (ctrl_pinc[i]),
            //
            .dest_clk(clk),
            .dest_out(ctrl_pinc_s[i])
        );

        cdc_array_single #(
            .DEST_SYNC_FF (2),
            .INIT_SYNC_FF (0),
            .SRC_INPUT_REG(0),
            .WIDTH        (20)
        ) i_cdc_poff (
            .src_clk (1'b1),
            .src_in  (ctrl_poff[i]),
            //
            .dest_clk(clk),
            .dest_out(ctrl_poff_s[i])
        );

      end
    end else begin : g_no_cdc

      assign ctrl_pinc_s = ctrl_pinc;
      assign ctrl_poff_s = ctrl_poff;

    end
  endgenerate

  // Phase accumulator

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_ant

      always_ff @(posedge clk) begin
        if (rst) begin
          phase[i] <= '0;
        end else if (din_chn == i) begin
          phase[i] <= phase_next;
        end
      end

    end
  endgenerate

  // The phase accumulator is controlled by din_chn, but not din_dv
  always_comb begin
    if (din_chn < NUM_ANT) begin
      if (din_sf) begin
        phase_next = ctrl_poff_s[din_chn];
      end else begin
        phase_next = phase_add(phase[din_chn], ctrl_pinc_s[din_chn]);
      end
    end else begin
      phase_next = '0;
    end
  end

  always_ff @(posedge clk) begin
    phase_r <= phase_next;
  end

  always_ff @(posedge clk) begin
    phase_lfsr <= phase_correct(phase_r, lfsr);
  end

  assign phase_lut = phase_lfsr[19:8];

  lfsr #(
      .BIT_WIDTH      (20),
      .INITIAL        (20'hFFFFF),
      .POLYNOMIAL     (21'h100005),
      .STRUCTURE      ("FIBONACCI"),
      .GATE_TYPE      ("XOR"),
      .PARALLEL_OUTPUT(1'b1)
  ) i_lfsr (
      .clk (clk),
      .rst (rst),
      .en  (1'b1),
      .load(1'b0),
      .din ({20{1'b1}}),
      .dout(lfsr)
  );

  dds_lut #(
      .STRUCTURE   ("AUTO"),
      .RASTERIZED  (1),
      .PHASE_WIDTH (12),
      .NEGATIVE_COS(0),
      .NEGATIVE_SIN(0)
  ) i_lut (
      .clk    (clk),
      .rst    (rst),
      //
      .phase  (phase_lut),
      //
      .cos_out(nco_dr),
      .sin_out(nco_di)
  );

  // Delay

  delay #(
      .WIDTH(16),
      .DEPTH(6),
      .INIT (1'b0)
  ) i_delay_dr (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      //
      .din (din_dr),
      .dout(din_dr_d)
  );

  delay #(
      .WIDTH(16),
      .DEPTH(6),
      .INIT (1'b0)
  ) i_delay_di (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      //
      .din (din_di),
      .dout(din_di_d)
  );

  // Complex multiplier

  cmult3 #(
      .A_WIDTH (16),
      .B_WIDTH (16),
      .P_WIDTH (16),
      .SHIFT   (15),
      //
      .ROUND   (1'b1),
      .SATURATE(1'b0)
  ) i_cmult (
      .clk(clk),
      .rst(rst),
      //
      .ar (din_dr_d),
      .ai (din_di_d),
      //
      .br (nco_dr),
      .bi (nco_di),
      //
      .pr (dout_dr),
      .pi (dout_di),
      //
      .ovf(  /* not used */)
  );

  delay #(
      .WIDTH(5),
      .DEPTH(Latency),
      .INIT (1'b0)
  ) i_delay_dv (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      //
      .din ({din_last, din_dv, din_sy, din_sl, din_sf}),
      .dout({dout_last, dout_dv, dout_sy, dout_sl, dout_sf})
  );

  delay #(
      .WIDTH(4),
      .DEPTH(Latency),
      .INIT (1'b0)
  ) i_delay_chn (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      //
      .din (din_chn),
      .dout(dout_chn)
  );

endmodule

`default_nettype wire

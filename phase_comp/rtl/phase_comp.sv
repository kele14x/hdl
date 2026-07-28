`timescale 1 ns / 1 ps
//
`default_nettype none

module phase_comp #(
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
    //----
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    input  wire [ 1:0] ctrl_rat,
    //
    input  wire [ 3:0] ctrl_phase_comp_addr,
    input  wire        ctrl_phase_comp_we,
    input  wire [31:0] ctrl_phase_comp_din
);

  // Parameters

  localparam int Latency = 10;
  localparam int AddrWidth = 4;

  // Signals

  logic        [          1:0] ctrl_rat_s;

  logic        [AddrWidth-1:0] din_sym       [NUM_ANT];
  logic        [AddrWidth-1:0] din_sym_next;
  logic        [AddrWidth-1:0] din_sym_r;

  logic        [AddrWidth-1:0] addrb;
  logic        [         31:0] doutb;

  logic signed [         15:0] phase_comp_dr;
  logic signed [         15:0] phase_comp_di;

  logic signed [         15:0] din_dr_d;
  logic signed [         15:0] din_di_d;

  // Main

  generate
    if (HAS_CDC) begin : g_cdc

      cdc_array_single #(
          .DEST_SYNC_FF (2),
          .INIT_SYNC_FF (0),
          .SRC_INPUT_REG(0),
          .WIDTH        (2)
      ) i_cdc_rat (
          .src_clk (1'b1),
          .src_in  (ctrl_rat),
          //
          .dest_clk(clk),
          .dest_out(ctrl_rat_s)
      );

    end else begin : g_no_cdc

      assign ctrl_rat_s = ctrl_rat;

    end
  endgenerate

  // Symbol Counter

  always_comb begin
    if (din_dv && din_sl) begin
      din_sym_next = '0;
    end else if (din_dv && din_sy) begin
      din_sym_next = din_sym[din_chn] + 1'b1;
    end else if (din_dv) begin
      din_sym_next = din_sym[din_chn];
    end else begin
      din_sym_next = '0;
    end
  end

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_din_sym

      always_ff @(posedge clk) begin
        if (rst) begin
          din_sym[i] <= '0;
        end else if (din_chn == i) begin
          din_sym[i] <= din_sym_next;
        end
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    din_sym_r <= din_sym_next;
  end

  assign addrb = din_sym_r;

  // Read latency = 1
  ram_sdp #(
      .ADDR_WIDTH  (4),
      .DATA_WIDTH  (32),
      .READ_LATENCY(1),
      .INIT_WORD   (32'h00004000),
      .INIT_FILE   ("")
  ) i_ram (
      .clka (ctrl_clk),
      .ena  (1'b1),
      .wea  (ctrl_phase_comp_we),
      .addra(ctrl_phase_comp_addr),
      .dina (ctrl_phase_comp_din),
      //
      .clkb (clk),
      .rstb (1'b0),
      .enb  (1'b1),
      .addrb(addrb),
      .doutb(doutb)
  );

  // Disable Phase Comp for LTE
  always_ff @(posedge clk) begin
    if (ctrl_rat_s == 0) begin  // LTE
      {phase_comp_di, phase_comp_dr} <= {16'h0000, 16'h4000};
    end else begin
      {phase_comp_di, phase_comp_dr} <= doutb;
    end
  end

  delay #(
      .WIDTH(32),
      .DEPTH(3)
  ) i_dq_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({din_di, din_dr}),
      .dout({din_di_d, din_dr_d})
  );

  cmult4 #(
      .A_WIDTH (16),
      .B_WIDTH (16),
      .P_WIDTH (16),
      .SHIFT   (14),
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
      .br (phase_comp_dr),
      .bi (phase_comp_di),
      //
      .pr (dout_dr),
      .pi (dout_di),
      //
      .ovf()
  );

  delay #(
      .WIDTH(9),
      .DEPTH(Latency)
  ) i_ctrl_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({din_last, din_dv, din_chn, din_sy, din_sl, din_sf}),
      .dout({dout_last, dout_dv, dout_chn, dout_sy, dout_sl, dout_sf})
  );

endmodule

`default_nettype wire

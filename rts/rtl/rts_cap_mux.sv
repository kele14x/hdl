`timescale 1 ns / 1 ps
//
`default_nettype none

module rts_cap_mux #(
    parameter int NUM_CC = 12
) (
    input var                       clk,
    input var                       rst,
    // monitor interface
    input var  [     NUM_CC*32-1:0] s0_axis_tdata,
    input var  [               7:0] s0_axis_tuser,
    input var                       s0_axis_tlast,
    input var                       s0_axis_tvalid,
    input var                       s0_axis_tready,
    //
    input var  [     NUM_CC*32-1:0] s1_axis_tdata,
    input var  [               7:0] s1_axis_tuser,
    input var                       s1_axis_tlast,
    input var                       s1_axis_tvalid,
    input var                       s1_axis_tready,
    //
    output var [              31:0] m_axis_tdata,
    output var [               7:0] m_axis_tuser,
    output var                      m_axis_tlast,
    output var                      m_axis_tvalid,
    //
    input var                       ctrl_pos_sel,
    input var  [$clog2(NUM_CC)-1:0] ctrl_cc_sel
);

  // Signals

  logic [     NUM_CC*32-1:0] tdata_d;
  logic [               7:0] tuser_d;
  logic                      tlast_d;
  logic                      tvalid_d;
  wire                       unused_rst = rst;

  wire                       ctrl_pos_sel_s;
  wire  [$clog2(NUM_CC)-1:0] ctrl_cc_sel_s;

  // Control signals CDC

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (1)
  ) i_cdc_ctrl_pos_sel (
      .src_clk (1'b1),
      .src_in  (ctrl_pos_sel),
      .dest_clk(clk),
      .dest_out(ctrl_pos_sel_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        ($clog2(NUM_CC))
  ) i_cdc_ctrl_cc_sel (
      .src_clk (1'b1),
      .src_in  (ctrl_cc_sel),
      .dest_clk(clk),
      .dest_out(ctrl_cc_sel_s)
  );

  // Main

  // 2:1 sel

  always_ff @(posedge clk) begin
    if (ctrl_pos_sel_s == 1'b0) begin
      tdata_d <= s0_axis_tdata;
    end else begin
      tdata_d <= s1_axis_tdata;
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_pos_sel_s == 1'b0) begin
      tuser_d <= s0_axis_tuser;
    end else begin
      tuser_d <= s1_axis_tuser;
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_pos_sel_s == 1'b0) begin
      tlast_d <= s0_axis_tlast;
    end else begin
      tlast_d <= s1_axis_tlast;
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_pos_sel_s == 1'b0) begin
      tvalid_d <= s0_axis_tvalid && s0_axis_tready;
    end else begin
      tvalid_d <= s1_axis_tvalid && s1_axis_tready;
    end
  end

  // 12:1 sel

  always_ff @(posedge clk) begin
    m_axis_tdata <= tdata_d[32*ctrl_cc_sel_s+31-:32];
  end

  always_ff @(posedge clk) begin
    m_axis_tuser <= tuser_d;
  end

  always_ff @(posedge clk) begin
    m_axis_tlast <= tlast_d;
  end

  always_ff @(posedge clk) begin
    m_axis_tvalid <= tvalid_d;
  end

endmodule

`default_nettype wire

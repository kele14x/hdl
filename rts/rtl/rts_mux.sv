`timescale 1 ns / 1 ps
//
`default_nettype none

module rts_mux #(
    parameter NUM_CC = 12
) (
    input  wire                 clk,
    input  wire                 rst,
    //
    input  wire                 sync,
    //
    input  wire [         31:0] cw_data,
    input  wire [         31:0] ram0_data,
    input  wire [         31:0] ram1_data,
    input  wire [         31:0] ram2_data,
    //
    output logic  [NUM_CC*32-1:0] m_axis_tdata,
    output logic  [          7:0] m_axis_tuser,
    output wire                 m_axis_tlast,
    output logic                  m_axis_tvalid,
    input  wire                 m_axis_tready,
    //
    input  wire [ NUM_CC*6-1:0] ctrl_src_sel
);

  // Parameters

  // Signals

  wire [NUM_CC*6-1:0] ctrl_src_sel_s;
  wire                 unused_m_axis_tready = m_axis_tready;
  wire [         5:0] ctrl_src_sel_ch[0:NUM_CC-1];

  logic                 sync_d;
  wire                sync_posedge;

  // Control signals CDC

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (NUM_CC * 6)
  ) i_cdc_ctrl_src_sel (
      .src_clk (1'b1),
      .src_in  (ctrl_src_sel),
      .dest_clk(clk),
      .dest_out(ctrl_src_sel_s)
  );

  generate
    genvar i;
    for (i = 0; i < NUM_CC; i = i + 1) begin : g_ctrl_ch

      assign ctrl_src_sel_ch[i] = ctrl_src_sel_s[i*6+5-:6];

      always_ff @(posedge clk) begin
        case (ctrl_src_sel_ch[i])
          6'b000001: m_axis_tdata[32*i+31-:32] <= cw_data;
          6'b000010: m_axis_tdata[32*i+31-:32] <= ram0_data;
          6'b000011: m_axis_tdata[32*i+31-:32] <= ram1_data;
          6'b000100: m_axis_tdata[32*i+31-:32] <= ram2_data;
          default:   m_axis_tdata[32*i+31-:32] <= 32'd0;
        endcase
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    sync_d <= sync;
  end

  assign sync_posedge = sync && !sync_d;

  always_ff @(posedge clk) begin
    if (sync_posedge) begin
      m_axis_tuser <= 8'd1;
    end else begin
      m_axis_tuser <= 8'd0;
    end
  end

  assign m_axis_tlast = 1'b0;

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tvalid <= 1'b0;
    end else begin
      m_axis_tvalid <= 1'b1;
    end
  end

  // ignore m_axis_tready

endmodule

`default_nettype wire

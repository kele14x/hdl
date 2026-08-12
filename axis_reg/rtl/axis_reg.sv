`timescale 1 ns / 1 ps
//
`default_nettype none

module axis_reg #(
    parameter int DATA_WIDTH = 32,
    parameter int USER_WIDTH = 1
) (
    input var                                          aclk,
    input var                                          aresetn,
    //
    input var  [                       DATA_WIDTH-1:0] s_axis_tdata,
    input var  [                     DATA_WIDTH/8-1:0] s_axis_tkeep,
    input var                                          s_axis_tlast,
    input var  [(USER_WIDTH > 0 ? USER_WIDTH : 1)-1:0] s_axis_tuser,
    input var                                          s_axis_tvalid,
    output var                                         s_axis_tready,
    //
    output var [                       DATA_WIDTH-1:0] m_axis_tdata,
    output var [                     DATA_WIDTH/8-1:0] m_axis_tkeep,
    output var                                         m_axis_tlast,
    output var [(USER_WIDTH > 0 ? USER_WIDTH : 1)-1:0] m_axis_tuser,
    output var                                         m_axis_tvalid,
    input var                                          m_axis_tready
);

  // AXI-Stream register slice built on the generic skid_buffer.  The sideband
  // (tuser, tlast, tkeep) is packed alongside tdata into a single word so the
  // whole beat passes through one skid_buffer instance.

  localparam int USER_KEEP_WIDTH = USER_WIDTH > 0 ? USER_WIDTH : 1;
  localparam int PAYLOAD_WIDTH = DATA_WIDTH + DATA_WIDTH/8 + 1 + USER_KEEP_WIDTH;

  logic [PAYLOAD_WIDTH-1:0] s_payload;
  logic [PAYLOAD_WIDTH-1:0] m_payload;

  assign s_payload = {s_axis_tuser, s_axis_tlast, s_axis_tkeep, s_axis_tdata};

  skid_buffer #(
      .DATA_WIDTH(PAYLOAD_WIDTH)
  ) u_skid_buffer (
      .clk     (aclk),
      .rst_n   (aresetn),
      //
      .s_data_i(s_payload),
      .s_vld_i (s_axis_tvalid),
      .s_rdy_o (s_axis_tready),
      //
      .m_data_o(m_payload),
      .m_vld_o (m_axis_tvalid),
      .m_rdy_i (m_axis_tready)
  );

  assign {m_axis_tuser, m_axis_tlast, m_axis_tkeep, m_axis_tdata} = m_payload;

endmodule

`default_nettype wire

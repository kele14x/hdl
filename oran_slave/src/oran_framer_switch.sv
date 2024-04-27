// File: oran_framer_switch.sv
// Brief: N-to-M AXIS switch for framer.
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_framer_switch #(
    parameter int NUM_ETHERNET_PORT = 1,
    parameter int NUM_ANTENNA_PORT  = 2,
    parameter int NUM_CC            = 1
) (
    input var                          clk,
    input var                          rst,
    //
    output var [                 63:0] m_axis_tdata [NUM_ETHERNET_PORT],
    output var [                  7:0] m_axis_tkeep [NUM_ETHERNET_PORT],
    output var                         m_axis_tvalid[NUM_ETHERNET_PORT],
    output var                         m_axis_tlast [NUM_ETHERNET_PORT],
    input var                          m_axis_tready[NUM_ETHERNET_PORT],
    //
    input var  [                 63:0] s_axis_tdata [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [                  7:0] s_axis_tkeep [ NUM_ANTENNA_PORT][NUM_CC],
    input var                          s_axis_tvalid[ NUM_ANTENNA_PORT][NUM_CC],
    input var                          s_axis_tlast [ NUM_ANTENNA_PORT][NUM_CC],
    output var                         s_axis_tready[ NUM_ANTENNA_PORT][NUM_CC],
    input var  [NUM_ETHERNET_PORT-1:0] s_axis_tuser [ NUM_ANTENNA_PORT][NUM_CC]
);

  // Number of source points, N
  localparam int NumSrc = NUM_ANTENNA_PORT * NUM_CC;
  // Number of destination points, M
  localparam int NumDest = NUM_ETHERNET_PORT;

  logic [                 63:0] s_axis_tdata_s [NumSrc];
  logic [                  7:0] s_axis_tkeep_s [NumSrc];
  logic                         s_axis_tvalid_s[NumSrc];
  logic                         s_axis_tlast_s [NumSrc];
  logic                         s_axis_tready_s[NumSrc];
  logic [NUM_ETHERNET_PORT-1:0] s_axis_tuser_s [NumSrc];

  generate
    for (genvar i = 0; i < NUM_ANTENNA_PORT; i++) begin : g_ant
      for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cc
        assign s_axis_tdata_s[i*NUM_CC+cc] = s_axis_tdata[i][cc];
        assign s_axis_tkeep_s[i*NUM_CC+cc] = s_axis_tkeep[i][cc];
        assign s_axis_tvalid_s[i*NUM_CC+cc] = s_axis_tvalid[i][cc];
        assign s_axis_tlast_s[i*NUM_CC+cc] = s_axis_tlast[i][cc];
        assign s_axis_tuser_s[i*NUM_CC+cc] = s_axis_tuser[i][cc];
        //
        assign s_axis_tready[i][cc] = s_axis_tready_s[i*NUM_CC+cc];
      end
    end
  endgenerate


  oran_switch #(
      .NUM_SRC (NumSrc),
      .NUM_DEST(NumDest)
  ) i_switch (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (s_axis_tdata_s),
      .s_axis_tkeep (s_axis_tkeep_s),
      .s_axis_tvalid(s_axis_tvalid_s),
      .s_axis_tlast (s_axis_tlast_s),
      .s_axis_tready(s_axis_tready_s),
      .s_axis_tuser (s_axis_tuser_s),
      //
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tkeep (m_axis_tkeep),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tready(m_axis_tready)
  );

endmodule

`default_nettype wire

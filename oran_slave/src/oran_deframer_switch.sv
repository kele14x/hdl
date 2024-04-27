// File: oran_deframer_switch.sv
// Brief: N-to-M AXIS switch for deframer.
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_deframer_switch #(
    parameter int NUM_ETHERNET_PORT = 1,
    parameter int NUM_ANTENNA_PORT  = 2,
    parameter int NUM_CC            = 1
) (
    input var                                clk,
    input var                                rst,
    //
    input var  [                       63:0] s_axis_tdata [NUM_ETHERNET_PORT],
    input var  [                        7:0] s_axis_tkeep [NUM_ETHERNET_PORT],
    input var                                s_axis_tvalid[NUM_ETHERNET_PORT],
    input var                                s_axis_tlast [NUM_ETHERNET_PORT],
    output var                               s_axis_tready[NUM_ETHERNET_PORT],
    input var  [NUM_ANTENNA_PORT*NUM_CC-1:0] s_axis_tuser [NUM_ETHERNET_PORT],
    //
    output var [                       63:0] m_axis_tdata [ NUM_ANTENNA_PORT][NUM_CC],
    output var [                        7:0] m_axis_tkeep [ NUM_ANTENNA_PORT][NUM_CC],
    output var                               m_axis_tvalid[ NUM_ANTENNA_PORT][NUM_CC],
    output var                               m_axis_tlast [ NUM_ANTENNA_PORT][NUM_CC]
);

  // Number of destination points, M
  localparam int NumDest = NUM_ANTENNA_PORT * NUM_CC;


  // An N-times-M state matrix for packet routing
  // For example an 2 to 4 case, the table will look like this:
  //
  //     | A0  | A1  | A2  | A3  |  R  |
  // E0  |  x  |     |     |     |  x  |
  // E1  |     |  x  |     |     |  x  |
  // F   |  x  |  x  |     |     |  -  |
  //
  // The x marks the packet is routing from En to Am
  // X-axis ORed the table, we get the per Ethernet channel busy state
  // Y-axis ORed the table, we get the per end point busy state
  //
  logic [          NumDest-1:0] is_busy           [NUM_ETHERNET_PORT];
  logic [          NumDest-1:0] is_busy_f;

  logic [NUM_ETHERNET_PORT-1:0] req;
  logic [NUM_ETHERNET_PORT-1:0] req_ack;

  logic [                 63:0] m_axis_tdata_next [ NUM_ANTENNA_PORT] [NUM_CC];
  logic [                  7:0] m_axis_tkeep_next [ NUM_ANTENNA_PORT] [NUM_CC];
  logic                         m_axis_tvalid_next[ NUM_ANTENNA_PORT] [NUM_CC];
  logic                         m_axis_tlast_next [ NUM_ANTENNA_PORT] [NUM_CC];

  // Per end point is busy flag
  always_comb begin
    is_busy_f = '0;
    for (int i = 0; i < NUM_ETHERNET_PORT; i++) begin
      is_busy_f = is_busy_f | is_busy[i];
    end
  end

  // All ethernet channel arbitration
  // Since we check from channel 0, fist Ethernet channel has highest propriety.
  // If there is conflict between requested end point, we only acknowledge to
  // first Ethernet channel
  always_comb begin
    logic [NumDest-1:0] occupy;
    occupy  = '0;
    req_ack = '0;
    for (int i = 0; i < NUM_ETHERNET_PORT; i++) begin
      if (req[i] && !s_axis_tready[i] && !(|(s_axis_tuser[i] & occupy))) begin
        req_ack[i] = 1'b1;
        occupy = occupy | s_axis_tuser[i];
      end
    end
  end

  generate
    for (genvar i = 0; i < NUM_ETHERNET_PORT; i++) begin : g_busy

      // The 1-to-which information is carried by TUSER, each bit corresponds to
      // an end point. This allows 1-to-many broadcast.
      // If all request end points are not busy, this request is valid. Else the
      // request will be blocked until all request end points are free.
      always_comb begin
        req[i] = (&(s_axis_tuser[i] & ~is_busy_f | ~s_axis_tuser[i]) && s_axis_tvalid[i]);
      end

      // Set the busy flag for that Ethernet channel and corresponding end points
      // if it wins arbitration (req_ack)
      always_ff @(posedge clk) begin
        if (rst) begin
          is_busy[i]       <= '0;
          s_axis_tready[i] <= 1'b0;
        end else if (req[i] && req_ack[i]) begin
          is_busy[i]       <= is_busy[i] | s_axis_tuser[i];
          s_axis_tready[i] <= 1'b1;
        end else if (s_axis_tvalid[i] && s_axis_tready[i] && s_axis_tlast[i]) begin
          is_busy[i]       <= '0;
          s_axis_tready[i] <= 1'b0;
        end
      end

    end
  endgenerate

  generate
    for (genvar i = 0; i < NUM_ANTENNA_PORT; i++) begin : g_ant
      for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cc

        always_comb begin
          m_axis_tdata_next[i][cc] = '0;
          m_axis_tkeep_next[i][cc] = '0;
          m_axis_tlast_next[i][cc] = '0;
          for (int e = 0; e < NUM_ETHERNET_PORT; e++) begin
            if (is_busy[e][i*NUM_CC+cc]) begin
              m_axis_tdata_next[i][cc] = m_axis_tdata_next[i][cc] | s_axis_tdata[e];
              m_axis_tkeep_next[i][cc] = m_axis_tkeep_next[i][cc] | s_axis_tkeep[e];
              m_axis_tlast_next[i][cc] = m_axis_tlast_next[i][cc] | s_axis_tlast[e];
            end
          end
        end

        always_ff @(posedge clk) begin
          m_axis_tdata[i][cc] <= m_axis_tdata_next[i][cc];
          m_axis_tkeep[i][cc] <= m_axis_tkeep_next[i][cc];
          m_axis_tlast[i][cc] <= m_axis_tlast_next[i][cc];
        end

        always_comb begin
          m_axis_tvalid_next[i][cc] = 1'b0;
          for (int e = 0; e < NUM_ETHERNET_PORT; e++) begin
            m_axis_tvalid_next[i][cc] = m_axis_tvalid_next[i][cc] | (s_axis_tvalid[e] & is_busy[e][i*NUM_CC+cc]);
          end
        end

        always_ff @(posedge clk) begin
          m_axis_tvalid[i][cc] <= m_axis_tvalid_next[i][cc];
        end

      end
    end
  endgenerate

endmodule

`default_nettype wire

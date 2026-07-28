// File: oran_switch.sv
// Brief: N-to-M AXIS switch
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_switch #(
    // Number of source points, N
    parameter int NUM_SRC  = 2,
    // Number of destination points, M
    parameter int NUM_DEST = 4
) (
    input var                 clk,
    input var                 rst,
    //
    input var  [        63:0] s_axis_tdata [ NUM_SRC],
    input var  [         7:0] s_axis_tkeep [ NUM_SRC],
    input var                 s_axis_tvalid[ NUM_SRC],
    input var                 s_axis_tlast [ NUM_SRC],
    output var                s_axis_tready[ NUM_SRC],
    input var  [NUM_DEST-1:0] s_axis_tuser [ NUM_SRC],
    //
    output var [        63:0] m_axis_tdata [NUM_DEST],
    output var [         7:0] m_axis_tkeep [NUM_DEST],
    output var                m_axis_tvalid[NUM_DEST],
    output var                m_axis_tlast [NUM_DEST],
    input var                 m_axis_tready[NUM_DEST]
);

  // An N-times-M state matrix for packet routing
  // For example an 2 to 4 case, the table will look like this:
  //
  //     | D0  | D1  | D2  | D3  |  R  |
  // S0  |  x  |  x  |     |     |  x  |
  // S1  |     |  x  |     |     |  x  |
  // F   |  x  |  x  |     |     |  -  |
  //
  // The x marks the packet is routing from Sn to Dm
  // X-axis ORed the table, we get the per source channel busy state
  // Y-axis ORed the table, we get the per end point busy state
  //
  logic [NUM_DEST-1:0] is_busy           [NUM_SRC];
  logic [NUM_DEST-1:0] is_busy_dest;
  logic [ NUM_SRC-1:0] is_busy_src;

  logic [ NUM_SRC-1:0] req;
  logic [ NUM_SRC-1:0] req_ack;

  logic [        63:0] m_axis_tdata_next [NUM_SRC];
  logic [         7:0] m_axis_tkeep_next [NUM_SRC];
  logic                m_axis_tvalid_next[NUM_SRC];
  logic                m_axis_tlast_next [NUM_SRC];

  // Per end point is busy flag
  always_comb begin
    is_busy_dest = '0;
    for (int s = 0; s < NUM_SRC; s++) begin
      is_busy_dest = is_busy_dest | is_busy[s];
    end
  end

  // Per source is busy flag
  always_comb begin
    is_busy_src = '0;
    for (int d = 0; d < NUM_DEST; d++) begin
      for (int s = 0; s < NUM_SRC; s++) begin
        is_busy_src[s] = is_busy_src[s] | is_busy[s][d];
      end
    end
  end

  // All source channel arbitration
  // Since we check from channel 0, fist source channel has highest propriety.
  // If there is conflict between requested end point, we only acknowledge to
  // first source channel
  always_comb begin
    logic [NUM_DEST-1:0] occupy;
    occupy  = '0;
    req_ack = '0;
    for (int s = 0; s < NUM_SRC; s++) begin
      if (req[s] && !is_busy_src[s] && !(|(s_axis_tuser[s] & occupy))) begin
        req_ack[s] = 1'b1;
        occupy = occupy | s_axis_tuser[s];
      end
    end
  end

  generate
    for (genvar s = 0; s < NUM_SRC; s++) begin : g_busy

      // The 1-to-which information is carried by TUSER, each bit corresponds to
      // an end point. This allows 1-to-many broadcast.
      // If all request end points are not busy, this request is valid. Else the
      // request will be blocked until all request end points are free.
      always_comb begin
        req[s] = (&(s_axis_tuser[s] & ~is_busy_dest | ~s_axis_tuser[s]) && s_axis_tvalid[s]);
      end

      // Since we only have 1 depth register, the TREADY signal depends on
      // whether there is valid data at master AXIS i/f, whether the slave module
      // is ready (TREADY), and if current source point could accept data.
      // TODO: multi end point?
      always_comb begin
        s_axis_tready[s] = is_busy_src[s];
        for (int d = 0; d < NUM_DEST; d++) begin
          s_axis_tready[s] = s_axis_tready[s] && (!m_axis_tvalid[d] || m_axis_tready[d]);
        end
      end

      // Set the busy flag for that source channel and corresponding end points
      // if it wins arbitration (req_ack)
      always_ff @(posedge clk) begin
        if (rst) begin
          is_busy[s] <= '0;
        end else if (req[s] && req_ack[s]) begin
          is_busy[s] <= is_busy[s] | s_axis_tuser[s];
        end else if (s_axis_tvalid[s] && s_axis_tready[s] && s_axis_tlast[s]) begin
          is_busy[s] <= '0;
        end
      end

    end
  endgenerate

  generate
    for (genvar d = 0; d < NUM_DEST; d++) begin : g_ant

      always_comb begin
        m_axis_tdata_next[d] = '0;
        m_axis_tkeep_next[d] = '0;
        m_axis_tlast_next[d] = '0;
        for (int s = 0; s < NUM_SRC; s++) begin
          if (is_busy_src[s]) begin
            m_axis_tdata_next[d] = m_axis_tdata_next[d] | s_axis_tdata[s];
            m_axis_tkeep_next[d] = m_axis_tkeep_next[d] | s_axis_tkeep[s];
            m_axis_tlast_next[d] = m_axis_tlast_next[d] | s_axis_tlast[s];
          end
        end
      end

      always_ff @(posedge clk) begin
        for (int s = 0; s < NUM_SRC; s++) begin
          if (s_axis_tvalid[s] && s_axis_tready[s]) begin
            m_axis_tdata[d] <= m_axis_tdata_next[d];
            m_axis_tkeep[d] <= m_axis_tkeep_next[d];
            m_axis_tlast[d] <= m_axis_tlast_next[d];
          end
        end
      end

      // TVALID assert means there is valid data at master AXIS i/f.
      // If it is accpeted by slave, we need to deassert TVALID. But if there
      // is new data from any source, we need to assert TVALID. The arbiter
      // ensures there is only one source at same time.
      always_comb begin
        m_axis_tvalid_next[d] = m_axis_tvalid[d];
        if (m_axis_tready[d]) begin
          m_axis_tvalid_next[d] = 1'b0;
        end
        for (int s = 0; s < NUM_SRC; s++) begin
          if (s_axis_tvalid[s] && s_axis_tready[s]) begin
            m_axis_tvalid_next[d] = 1'b1;
          end
        end
      end

      always_ff @(posedge clk) begin
        if (rst) begin
          m_axis_tvalid[d] <= 1'b0;
        end else begin
          m_axis_tvalid[d] <= m_axis_tvalid_next[d];
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire

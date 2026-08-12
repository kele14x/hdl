// N-to-M AXIS switch
`timescale 1 ns / 1 ps
//
`default_nettype none

module axis_switch #(
    parameter int NUM_SRC    = 2,
    parameter int NUM_DEST   = 4,
    parameter int DATA_WIDTH = 32,
    parameter int USER_WIDTH = 1
) (
    input var                                          clk,
    input var                                          rst,
    //
    input var  [                       DATA_WIDTH-1:0] s_axis_tdata [ NUM_SRC],
    input var  [                     DATA_WIDTH/8-1:0] s_axis_tkeep [ NUM_SRC],
    input var                                          s_axis_tlast [ NUM_SRC],
    input var  [                         NUM_DEST-1:0] s_axis_tdest [ NUM_SRC],
    input var  [(USER_WIDTH > 0 ? USER_WIDTH : 1)-1:0] s_axis_tuser [ NUM_SRC],
    input var                                          s_axis_tvalid[ NUM_SRC],
    output var                                         s_axis_tready[ NUM_SRC],
    //
    output var [                       DATA_WIDTH-1:0] m_axis_tdata [NUM_DEST],
    output var [                     DATA_WIDTH/8-1:0] m_axis_tkeep [NUM_DEST],
    output var                                         m_axis_tlast [NUM_DEST],
    output var [(USER_WIDTH > 0 ? USER_WIDTH : 1)-1:0] m_axis_tuser [NUM_DEST],
    output var                                         m_axis_tvalid[NUM_DEST],
    input var                                          m_axis_tready[NUM_DEST]
);

  // Parameters

  localparam int UserWidthInt = (USER_WIDTH > 0 ? USER_WIDTH : 1);

  // DRC

  initial begin : drc_check
    assert (NUM_SRC >= 1)
    else begin
      $error("[%m]: NUM_SRC must be at least 1, got %0d", NUM_SRC);
    end

    assert (NUM_DEST >= 1)
    else begin
      $error("[%m]: NUM_DEST must be at least 1, got %0d", NUM_DEST);
    end

    assert (DATA_WIDTH % 8 == 0)
    else begin
      $error("[%m]: DATA_WIDTH must be a multiple of 8, got %0d", DATA_WIDTH);
    end
  end

  // Note

  // An N-times-M state matrix for packet routing. For the 2-to-4 case the
  // table looks like this:
  //
  //     | D0  | D1  | D2  | D3  |  R  |
  // S0  |  x  |  x  |     |     |  x  |
  // S1  |     |     |  x  |     |  x  |
  // F   |  x  |  x  |  x  |     |  -  |
  //
  // An x marks that a packet is routing from Sn to Dm. ORing the table
  // along the columns gives the per destination busy state, ORing along
  // the rows gives the per source busy state.
  //
  // Rules: a source may route one packet to several destinations at once
  // (TDEST is a bitmask), but a destination is fed by at most one source
  // at any given time, so there is no routing conflict. The destinations
  // of a packet stay reserved until its TLAST transfer. A packet with
  // TDEST == 0 is silently discarded until TLAST.

  // Signals

  logic [    NUM_DEST-1:0] is_busy           [ NUM_SRC];
  logic                    is_discard        [ NUM_SRC];
  logic [    NUM_DEST-1:0] is_busy_dest;
  logic [     NUM_SRC-1:0] is_busy_src;
  //
  logic [     NUM_SRC-1:0] req;
  logic [     NUM_SRC-1:0] req_ack;
  logic [     NUM_SRC-1:0] transfer;
  //
  logic [  DATA_WIDTH-1:0] m_axis_tdata_s    [NUM_DEST];
  logic [DATA_WIDTH/8-1:0] m_axis_tkeep_s    [NUM_DEST];
  logic                    m_axis_tlast_s    [NUM_DEST];
  logic [UserWidthInt-1:0] m_axis_tuser_s    [NUM_DEST];
  logic                    m_axis_tvalid_s   [NUM_DEST];
  logic                    m_axis_tvalid_next[NUM_DEST];
  //
  logic [     NUM_SRC-1:0] busy_src_of_dest  [NUM_DEST];

  // Main

  // Per destination busy flag
  always_comb begin : p_is_busy_dest
    is_busy_dest = 0;
    for (int ss = 0; ss < NUM_SRC; ss = ss + 1) begin
      is_busy_dest = is_busy_dest | is_busy[ss];
    end
  end

  // Per source busy flag
  always_comb begin : p_is_busy_src
    for (int ss = 0; ss < NUM_SRC; ss = ss + 1) begin
      is_busy_src[ss] = |is_busy[ss];
    end
  end

  // All source channel arbitration. Since we check from channel 0, the
  // lowest source index has the highest priority: on a destination
  // conflict only the first requester is acknowledged and the others
  // retry on the next cycle.
  always_comb begin : p_req_ack
    logic [NUM_DEST-1:0] occupy;
    occupy  = 0;
    req_ack = 0;

    for (int ss = 0; ss < NUM_SRC; ss = ss + 1) begin
      if (req[ss] && !(|(s_axis_tdest[ss] & occupy))) begin
        req_ack[ss] = 1'b1;
        occupy      = occupy | s_axis_tdest[ss];
      end
    end
  end

  generate
    for (genvar s = 0; s < NUM_SRC; s = s + 1) begin : g_src

      // A packet requests all destinations of its TDEST bitmask at once;
      // the request is granted only when every one of them is free.
      always_comb begin : p_req
        req[s] = s_axis_tvalid[s] && !is_busy_src[s] && !is_discard[s] &&
                 (s_axis_tdest[s] != 0) &&
                 (&(s_axis_tdest[s] & ~is_busy_dest | ~s_axis_tdest[s]));
      end

      assign transfer[s] = s_axis_tvalid[s] && s_axis_tready[s];

      // Reserve the destinations of a packet when it wins arbitration, or
      // enter the discard path for TDEST == 0; both are released by the
      // TLAST transfer.
      always_ff @(posedge clk) begin
        if (rst) begin
          is_busy[s]    <= 0;
          is_discard[s] <= 1'b0;
        end else if (transfer[s] && s_axis_tlast[s]) begin
          is_busy[s]    <= 0;
          is_discard[s] <= 1'b0;
        end else if (s_axis_tvalid[s] && !is_busy_src[s] && !is_discard[s]) begin
          if (s_axis_tdest[s] == 0) begin
            is_discard[s] <= 1'b1;
          end else if (req_ack[s]) begin
            is_busy[s] <= s_axis_tdest[s];
          end
        end
      end

      // Discarded packets are always accepted. A routed packet advances
      // only when every destination it targets can take the beat, so a
      // broadcast never tears between its destinations.
      always_comb begin : p_s_axis_tready
        s_axis_tready[s] = 1'b0;
        if (is_discard[s]) begin
          s_axis_tready[s] = 1'b1;
        end else if (is_busy_src[s]) begin
          s_axis_tready[s] = 1'b1;
          for (int dd = 0; dd < NUM_DEST; dd = dd + 1) begin
            if (is_busy[s][dd] && m_axis_tvalid_s[dd] && !m_axis_tready[dd]) begin
              s_axis_tready[s] = 1'b0;
            end
          end
        end
      end

    end
  endgenerate

  generate
    genvar d;
    for (d = 0; d < NUM_DEST; d = d + 1) begin : g_dest

      assign m_axis_tdata[d]  = m_axis_tdata_s[d];
      assign m_axis_tkeep[d]  = m_axis_tkeep_s[d];
      assign m_axis_tlast[d]  = m_axis_tlast_s[d];
      assign m_axis_tuser[d]  = m_axis_tuser_s[d];
      assign m_axis_tvalid[d] = m_axis_tvalid_s[d];

      // Output register; at most one source routes to this destination at
      // any time, so the source select cannot conflict.
      always_ff @(posedge clk) begin
        for (int ss = 0; ss < NUM_SRC; ss = ss + 1) begin
          if (is_busy[ss][d] && transfer[ss]) begin
            m_axis_tdata_s[d] <= s_axis_tdata[ss];
            m_axis_tkeep_s[d] <= s_axis_tkeep[ss];
            m_axis_tlast_s[d] <= s_axis_tlast[ss];
            m_axis_tuser_s[d] <= s_axis_tuser[ss];
          end
        end
      end

      // TVALID drops when the beat is accepted and rises when a source
      // transfers into this destination.
      always_comb begin : p_m_axis_tvalid_next
        m_axis_tvalid_next[d] = m_axis_tvalid_s[d] && !m_axis_tready[d];
        for (int ss = 0; ss < NUM_SRC; ss = ss + 1) begin
          if (is_busy[ss][d] && transfer[ss]) begin
            m_axis_tvalid_next[d] = 1'b1;
          end
        end
      end

      always_ff @(posedge clk) begin
        if (rst) begin
          m_axis_tvalid_s[d] <= 1'b0;
        end else begin
          m_axis_tvalid_s[d] <= m_axis_tvalid_next[d];
        end
      end

      // A destination must never be routed from more than one source
      assert property (@(posedge clk) disable iff (rst) $onehot0(busy_src_of_dest[d]))
      else $error("[%m]: destination %0d is routed from more than one source", d);

    end
  endgenerate

  // Busy columns of the routing table, one per destination
  generate
    for (genvar cd = 0; cd < NUM_DEST; cd = cd + 1) begin : g_busy_col
      for (genvar cs = 0; cs < NUM_SRC; cs = cs + 1) begin : g_busy_src
        assign busy_src_of_dest[cd][cs] = is_busy[cs][cd];
      end
    end
  endgenerate

endmodule

`default_nettype wire

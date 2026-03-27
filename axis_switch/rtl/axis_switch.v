// N-to-M AXIS switch
`timescale 1 ns / 1 ps
//
`default_nettype none

module axis_switch #(
    parameter integer NUM_SRC    = 2,
    parameter integer NUM_DEST   = 4,
    parameter integer DATA_WIDTH = 32,
    parameter integer USER_WIDTH = 1
) (
    input  wire                                                  clk,
    input  wire                                                  rst,
    //
    input  wire [                        DATA_WIDTH*NUM_SRC-1:0] s_axis_tdata,
    input  wire [                      DATA_WIDTH*NUM_SRC/8-1:0] s_axis_tkeep,
    input  wire [                                   NUM_SRC-1:0] s_axis_tlast,
    input  wire [                          NUM_DEST*NUM_SRC-1:0] s_axis_tdest,
    input  wire [ (USER_WIDTH > 0 ? USER_WIDTH : 1)*NUM_SRC-1:0] s_axis_tuser,
    input  wire [                                   NUM_SRC-1:0] s_axis_tvalid,
    output wire [                                   NUM_SRC-1:0] s_axis_tready,
    //
    output wire [                       DATA_WIDTH*NUM_DEST-1:0] m_axis_tdata,
    output wire [                     DATA_WIDTH*NUM_DEST/8-1:0] m_axis_tkeep,
    output wire [                                  NUM_DEST-1:0] m_axis_tlast,
    output wire [(USER_WIDTH > 0 ? USER_WIDTH : 1)*NUM_DEST-1:0] m_axis_tuser,
    output wire [                                  NUM_DEST-1:0] m_axis_tvalid,
    input  wire [                                  NUM_DEST-1:0] m_axis_tready
);

  // Parameters

  localparam integer UserWidthInt = (USER_WIDTH > 0 ? USER_WIDTH : 1);

  // Signals

  wire [  DATA_WIDTH-1:0] s_axis_tdata_s    [ 0:NUM_SRC-1];
  wire [DATA_WIDTH/8-1:0] s_axis_tkeep_s    [ 0:NUM_SRC-1];
  wire                    s_axis_tlast_s    [ 0:NUM_SRC-1];
  wire [    NUM_DEST-1:0] s_axis_tdest_s    [ 0:NUM_SRC-1];
  wire [UserWidthInt-1:0] s_axis_tuser_s    [ 0:NUM_SRC-1];
  wire                    s_axis_tvalid_s   [ 0:NUM_SRC-1];
  reg                     s_axis_tready_s   [ 0:NUM_SRC-1];
  //
  reg  [  DATA_WIDTH-1:0] m_axis_tdata_s    [0:NUM_DEST-1];
  reg  [DATA_WIDTH/8-1:0] m_axis_tkeep_s    [0:NUM_DEST-1];
  reg                     m_axis_tlast_s    [0:NUM_DEST-1];
  reg  [UserWidthInt-1:0] m_axis_tuser_s    [0:NUM_DEST-1];
  reg                     m_axis_tvalid_s   [0:NUM_DEST-1];
  wire                    m_axis_tready_s   [0:NUM_DEST-1];
  //
  reg  [  DATA_WIDTH-1:0] m_axis_tdata_next [0:NUM_DEST-1];
  reg  [DATA_WIDTH/8-1:0] m_axis_tkeep_next [0:NUM_DEST-1];
  reg                     m_axis_tlast_next [0:NUM_DEST-1];
  reg  [UserWidthInt-1:0] m_axis_tuser_next [0:NUM_DEST-1];
  reg                     m_axis_tvalid_next[0:NUM_DEST-1];

  reg  [    NUM_DEST-1:0] is_busy           [ 0:NUM_SRC-1];
  reg  [    NUM_DEST-1:0] is_busy_dest;
  reg  [     NUM_SRC-1:0] is_busy_src;

  reg  [     NUM_SRC-1:0] req;
  reg  [     NUM_SRC-1:0] req_ack;

  // Note

  // An N-times-M state matrix for packet routing
  // For example an 2 to 4 case, the table will look like this:
  //
  //     | D0  | D1  | D2  | D3  |  R  |
  // S0  |  x  |  x  |     |     |  x  |
  // S1  |     |     |  x  |     |  x  |
  // F   |  x  |  x  |  x  |     |  -  |
  //
  // The x marks the packet is routing from Sn to Dm
  // X-axis ORed the table, we get the per source channel busy state
  // Y-axis ORed the table, we get the per end point busy state
  //
  // Rules: There could be one source channel routing to multiple destination
  // channels, but a destination channel could only be routed from one source
  // channel at any given time, so there is no routing conflict. Thus here
  // could be multiple x in one row, but there will be only one x in one column.

  // Main

  // Per end point is busy flag
  always @(*) begin : s_is_busy_dest
    integer ss;
    is_busy_dest = 0;
    for (ss = 0; ss < NUM_SRC; ss = ss + 1) begin
      is_busy_dest = is_busy_dest | is_busy[ss];
    end
  end

  // Per source is busy flag
  always @(*) begin : s_in_busy_src
    integer ss, dd;
    is_busy_src = 0;
    for (dd = 0; dd < NUM_DEST; dd = dd + 1) begin
      for (ss = 0; ss < NUM_SRC; ss = ss + 1) begin
        is_busy_src[ss] = is_busy_src[ss] || is_busy[ss][dd];
      end
    end
  end

  // All source channel arbitration
  // Since we check from channel 0, fist source channel has highest propriety.
  // If there is conflict between requested end point, we only acknowledge to
  // first source channel
  always @(*) begin : p_req_ack
    integer ss;
    reg [NUM_DEST-1:0] occupy;
    occupy  = 0;
    req_ack = 0;

    for (ss = 0; ss < NUM_SRC; ss = ss + 1) begin
      if (req[ss] && !is_busy_src[ss] && !(|(s_axis_tdest_s[ss] & occupy))) begin
        req_ack[ss] = 1'b1;
        occupy = occupy | s_axis_tdest_s[ss];
      end
    end
  end

  generate
    genvar s;
    for (s = 0; s < NUM_SRC; s = s + 1) begin : g_src

      assign s_axis_tdata_s[s]  = s_axis_tdata[DATA_WIDTH*(s+1)-1-:DATA_WIDTH];
      assign s_axis_tkeep_s[s]  = s_axis_tkeep[DATA_WIDTH/8*(s+1)-1-:DATA_WIDTH/8];
      assign s_axis_tlast_s[s]  = s_axis_tlast[s];
      assign s_axis_tdest_s[s]  = s_axis_tdest[NUM_DEST*(s+1)-1-:NUM_DEST];
      assign s_axis_tuser_s[s]  = s_axis_tuser[UserWidthInt*(s+1)-1-:UserWidthInt];
      assign s_axis_tvalid_s[s] = s_axis_tvalid[s];
      //
      assign s_axis_tready[s]   = s_axis_tready_s[s];

      // The 1-to-which information is carried by TDEST, each bit corresponds to
      // an end point. This allows 1-to-many broadcast.
      // If all request end points are not busy, this request is valid. Else the
      // request will be blocked until all request end points are free.
      always @(*) begin
        req[s] = (&(s_axis_tdest_s[s] & ~is_busy_dest | ~s_axis_tdest_s[s]) && s_axis_tvalid_s[s]);
      end

      // Since we only have 1 depth register, the TREADY signal depends on
      // whether there is valid data at master AXIS i/f, whether the slave module
      // is ready (TREADY), and if current source point could accept data.
      // TODO: multi end point?
      always @(*) begin : p_s_axis_tready
        integer dd;
        s_axis_tready_s[s] = is_busy_src[s];
        for (dd = 0; dd < NUM_DEST; dd = dd + 1) begin
          s_axis_tready_s[s] = s_axis_tready_s[s] && (!m_axis_tvalid_s[dd] || m_axis_tready_s[dd]);
        end
      end

      // Set the busy flag for that source channel and corresponding end points
      // if it wins arbitration (req_ack)
      always @(posedge clk) begin
        if (rst) begin
          is_busy[s] <= 0;
        end else if (req[s] && req_ack[s]) begin
          is_busy[s] <= is_busy[s] | s_axis_tdest_s[s];
        end else if (s_axis_tvalid_s[s] && s_axis_tready_s[s] && s_axis_tlast_s[s]) begin
          is_busy[s] <= 0;
        end
      end

    end
  endgenerate

  generate
    genvar d;
    for (d = 0; d < NUM_DEST; d = d + 1) begin : g_dest

      assign m_axis_tdata[DATA_WIDTH*(d+1)-1-:DATA_WIDTH]     = m_axis_tdata_s[d];
      assign m_axis_tkeep[DATA_WIDTH/8*(d+1)-1-:DATA_WIDTH/8] = m_axis_tkeep_s[d];
      assign m_axis_tlast[d]                                  = m_axis_tlast_s[d];
      assign m_axis_tuser[UserWidthInt*(d+1)-1-:UserWidthInt] = m_axis_tuser_s[d];
      assign m_axis_tvalid[d]                                 = m_axis_tvalid_s[d];
      //
      assign m_axis_tready_s[d]                               = m_axis_tready[d];

      always @(*) begin : p_m_axis_next
        integer ss;
        m_axis_tdata_next[d] = 0;
        m_axis_tkeep_next[d] = 0;
        m_axis_tlast_next[d] = 0;
        m_axis_tuser_next[d] = 0;
        for (ss = 0; ss < NUM_SRC; ss = ss + 1) begin
          if (is_busy_src[ss]) begin
            m_axis_tdata_next[d] = m_axis_tdata_next[d] | s_axis_tdata_s[ss];
            m_axis_tkeep_next[d] = m_axis_tkeep_next[d] | s_axis_tkeep_s[ss];
            m_axis_tlast_next[d] = m_axis_tlast_next[d] | s_axis_tlast_s[ss];
            m_axis_tuser_next[d] = m_axis_tuser_next[d] | s_axis_tuser_s[ss];
          end
        end
      end

      always @(posedge clk) begin : p_m_axis
        integer ss;
        for (ss = 0; ss < NUM_SRC; ss = ss + 1) begin
          if (s_axis_tvalid_s[ss] && s_axis_tready_s[ss]) begin
            m_axis_tdata_s[d] <= m_axis_tdata_next[d];
            m_axis_tkeep_s[d] <= m_axis_tkeep_next[d];
            m_axis_tlast_s[d] <= m_axis_tlast_next[d];
            m_axis_tuser_s[d] <= m_axis_tuser_next[d];
          end
        end
      end

      // TVALID assert means there is valid data at master AXIS i/f.
      // If it is accepted by slave, we need to de-assert TVALID. But if there
      // is new data from any source, we need to assert TVALID. The arbiter
      // ensures there is only one source at same time.
      always @(*) begin : p_m_axis_tvalid_next
        integer ss;
        m_axis_tvalid_next[d] = m_axis_tvalid_s[d];
        if (m_axis_tready_s[d]) begin
          m_axis_tvalid_next[d] = 1'b0;
        end
        for (ss = 0; ss < NUM_SRC; ss = ss + 1) begin
          if (s_axis_tvalid_s[ss] && s_axis_tready_s[ss]) begin
            m_axis_tvalid_next[d] = 1'b1;
          end
        end
      end

      always @(posedge clk) begin
        if (rst) begin
          m_axis_tvalid_s[d] <= 1'b0;
        end else begin
          m_axis_tvalid_s[d] <= m_axis_tvalid_next[d];
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire

`timescale 1 ns / 1 ps
//
`default_nettype none

module axis_reg #(
    parameter integer DATA_WIDTH = 32,
    parameter integer USER_WIDTH = 1
) (
    input  wire                                          aclk,
    input  wire                                          aresetn,
    //
    input  wire  [                       DATA_WIDTH-1:0] s_axis_tdata,
    input  wire  [                     DATA_WIDTH/8-1:0] s_axis_tkeep,
    input  wire                                          s_axis_tlast,
    input  wire  [(USER_WIDTH > 0 ? USER_WIDTH : 1)-1:0] s_axis_tuser,
    input  wire                                          s_axis_tvalid,
    output logic                                         s_axis_tready,
    //
    output logic [                       DATA_WIDTH-1:0] m_axis_tdata,
    output logic [                     DATA_WIDTH/8-1:0] m_axis_tkeep,
    output logic                                         m_axis_tlast,
    output logic [(USER_WIDTH > 0 ? USER_WIDTH : 1)-1:0] m_axis_tuser,
    output logic                                         m_axis_tvalid,
    input  wire                                          m_axis_tready
);

  // Notes

  // s_axis_tvalid | tvalid_d | m_axis_tvalid | m_axis_tready | *s_axis_tready || tvalid_d_next | m_axis_tvalid_next |      |      |
  //             0 |        0 |             0 |             0 |              1 ||             0 |                  0 |      |      |
  //             0 |        0 |             0 |             1 |              1 ||             0 |                  0 |      |      |
  //             0 |        0 |             1 |             0 |              1 ||             0 |                  1 |      |      |
  //             0 |        0 |             1 |             1 |              1 ||             0 |                  0 |      |      |
  //             0 |        1 |             0 |             0 |              1 ||             0 |                  1 |      | B->M |
  //             0 |        1 |             0 |             1 |              1 ||             0 |                  1 |      | B->M |
  //             0 |        1 |             1 |             0 |              0 ||             1 |                  1 |      |      |
  //             0 |        1 |             1 |             1 |              0 ||             0 |                  1 |      | B->M |
  //             1 |        0 |             0 |             0 |              1 ||             0 |                  1 |      | S->M |
  //             1 |        0 |             0 |             1 |              1 ||             0 |                  1 |      | S->M |
  //             1 |        0 |             1 |             0 |              1 ||             1 |                  1 | S->B |      |
  //             1 |        0 |             1 |             1 |              1 ||             0 |                  1 |      | S->M |
  //             1 |        1 |             0 |             0 |              1 ||             1 |                  1 | S->B | B->M |
  //             1 |        1 |             0 |             1 |              1 ||             1 |                  1 | S->B | B->M |
  //             1 |        1 |             1 |             0 |              0 ||             1 |                  1 |      |      |
  //             1 |        1 |             1 |             1 |              0 ||             0 |                  1 |      | B->M |
  // s_axis_tready == !m_axis_tvalid || !tvalid_d

  // Signals

  localparam integer USER_KEEP_WIDTH = USER_WIDTH > 0 ? USER_WIDTH : 1;

  logic [     DATA_WIDTH-1:0] tdata_d;
  logic [   DATA_WIDTH/8-1:0] tkeep_d;
  logic [USER_KEEP_WIDTH-1:0] tuser_d;
  logic                       tlast_d;

  logic                       tvalid_d;

  logic [     DATA_WIDTH-1:0] tdata_s;
  logic [   DATA_WIDTH/8-1:0] tkeep_s;
  logic [USER_KEEP_WIDTH-1:0] tuser_s;
  logic                       tlast_s;

  logic                       tvalid_d_next;

  logic                       m_axis_tvalid_next;

  // Main

  // S_AXIS

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      s_axis_tready <= 1'b0;
    end else begin
      s_axis_tready <= !tvalid_d_next || !m_axis_tvalid_next;
    end
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      tvalid_d <= 1'b0;
    end else begin
      tvalid_d <= tvalid_d_next;
    end
  end

  // Buffer

  always_comb begin
    case (tvalid_d)
      1'b0: begin
        // There is no data in the buffer, we know at this state `s_axis_tready` is 1.
        // based on the `s_axis_tvalid`, `m_axis_tvalid` and `m_axis_tready`
        // the buffer valid flag may stay 0 or become 1.
        if (s_axis_tvalid && m_axis_tvalid && !m_axis_tready) begin
          tvalid_d_next = 1'b1;
        end else begin
          tvalid_d_next = 1'b0;
        end
      end

      1'b1: begin
        // There is 1 word of data in the buffer, at this state `s_axis_tready` could be 0 or 1,
        // but we does not need to check it since the `s_axis_tready` could be get from `m_axis_tvalid`.
        if (m_axis_tvalid && m_axis_tready) begin
          tvalid_d_next = 1'b0;
        end else if (!s_axis_tvalid && !m_axis_tvalid) begin
          tvalid_d_next = 1'b0;
        end else begin
          tvalid_d_next = 1'b1;
        end
      end

      default: begin
        tvalid_d_next = 1'b0;
      end
    endcase
  end

  always_ff @(posedge aclk) begin
    if ((s_axis_tvalid && !tvalid_d && m_axis_tvalid && !m_axis_tready) ||
        (s_axis_tvalid && tvalid_d && !m_axis_tvalid)) begin
      tdata_d <= s_axis_tdata;
      tkeep_d <= s_axis_tkeep;
      tlast_d <= s_axis_tlast;
      tuser_d <= s_axis_tuser;
    end
  end

  // Output

  always_comb begin
    if (tvalid_d) begin
      tdata_s = tdata_d;
      tkeep_s = tkeep_d;
      tuser_s = tuser_d;
      tlast_s = tlast_d;
    end else begin
      tdata_s = s_axis_tdata;
      tkeep_s = s_axis_tkeep;
      tuser_s = s_axis_tuser;
      tlast_s = s_axis_tlast;
    end
  end

  always_ff @(posedge aclk) begin
    if ((s_axis_tvalid || tvalid_d) && (!m_axis_tvalid || m_axis_tready)) begin
      m_axis_tdata <= tdata_s;
      m_axis_tkeep <= tkeep_s;
      m_axis_tlast <= tlast_s;
      m_axis_tuser <= tuser_s;
    end
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      m_axis_tvalid <= 1'b0;
    end else begin
      m_axis_tvalid <= m_axis_tvalid_next;
    end
  end

  always_comb begin
    case (m_axis_tvalid)
      1'b0: begin
        if (s_axis_tvalid || tvalid_d) begin
          m_axis_tvalid_next = 1'b1;
        end else begin
          m_axis_tvalid_next = 1'b0;
        end
      end

      1'b1: begin
        if (!s_axis_tvalid && !tvalid_d && m_axis_tready) begin
          m_axis_tvalid_next = 1'b0;
        end else begin
          m_axis_tvalid_next = 1'b1;
        end
      end

      default: begin
        m_axis_tvalid_next = 1'b0;
      end
    endcase
  end

endmodule

`default_nettype wire

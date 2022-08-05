// File: axis_reg.sv
// Brief: Register for the AXI4-Stream interface
`timescale 1 ns / 100 ps
//
`default_nettype none

module axis_reg #(
    parameter int HAS_TKEEP   = 0,
    parameter int HAS_TLAST   = 0,
    parameter int HAS_TREADY  = 1,
    parameter int HAS_TSTRB   = 0,
    parameter int TDATA_WIDTH = 8,
    parameter int TDEST_WIDTH = 0,
    parameter int TID_WIDTH   = 0,
    parameter int TUSER_WIDTH = 0
) (
    input var                                                                   aclk,
    input var                                                                   aclken,
    input var                                                                   aresetn,
    // Slave Side Interface
    //---------------------
    input var  [                    (TDATA_WIDTH == 0 ? 0 : (TDATA_WIDTH-1)):0] s_axis_tdata,
    input var  [                    (TDEST_WIDTH == 0 ? 0 : (TDEST_WIDTH-1)):0] s_axis_tdest,
    input var  [                        (TID_WIDTH == 0 ? 0 : (TID_WIDTH-1)):0] s_axis_tid,
    input var  [(TDATA_WIDTH == 0 || HAS_TKEEP == 0 ? 0 : (TDATA_WIDTH/8-1)):0] s_axis_tkeep,
    input var                                                                   s_axis_tlast,
    input var                                                                   s_axis_tvalid,
    input var  [(TDATA_WIDTH == 0 || HAS_TSTRB == 0 ? 0 : (TDATA_WIDTH/8-1)):0] s_axis_tstrb,
    input var  [                    (TUSER_WIDTH == 0 ? 0 : (TUSER_WIDTH-1)):0] s_axis_tuser,
    output var                                                                  s_axis_tready,
    // Master Side Interface
    //----------------------
    output var [                    (TDATA_WIDTH == 0 ? 0 : (TDATA_WIDTH-1)):0] m_axis_tdata,
    output var [                    (TDEST_WIDTH == 0 ? 0 : (TDEST_WIDTH-1)):0] m_axis_tdest,
    output var [                        (TID_WIDTH == 0 ? 0 : (TID_WIDTH-1)):0] m_axis_tid,
    output var [(TDATA_WIDTH == 0 || HAS_TKEEP == 0 ? 0 : (TDATA_WIDTH/8-1)):0] m_axis_tkeep,
    output var                                                                  m_axis_tlast,
    output var                                                                  m_axis_tvalid,
    output var [(TDATA_WIDTH == 0 || HAS_TSTRB == 0 ? 0 : (TDATA_WIDTH/8-1)):0] m_axis_tstrb,
    output var [                    (TUSER_WIDTH == 0 ? 0 : (TUSER_WIDTH-1)):0] m_axis_tuser,
    input var                                                                   m_axis_tready
);

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      m_axis_tdata  <= '0;
      m_axis_tdest  <= '0;
      m_axis_tid    <= '0;
      m_axis_tkeep  <= '0;
      m_axis_tlast  <= '0;
      m_axis_tstrb  <= '0;
      m_axis_tuser  <= '0;
    end else if (aclken) begin
      if (s_axis_tvalid && s_axis_tready) begin
        m_axis_tdata  <= s_axis_tdata;
        m_axis_tdest  <= s_axis_tdest;
        m_axis_tid    <= s_axis_tid;
        m_axis_tkeep  <= s_axis_tkeep;
        m_axis_tlast  <= s_axis_tlast;
        m_axis_tstrb  <= s_axis_tstrb;
        m_axis_tuser  <= s_axis_tuser;
      end
    end
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      s_axis_tready <= 1'b0;
    end else if (aclken) begin
      if (s_axis_tvalid && s_axis_tready) begin
        s_axis_tready <= 1'b0;
      end else if (!m_axis_tvalid || m_axis_tready) begin
        s_axis_tready <= 1'b1;
      end
    end
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      m_axis_tvalid <= 1'b0;
    end else if (aclken) begin
      if (s_axis_tvalid && s_axis_tready) begin
        m_axis_tvalid <= 1'b1;
      end else if (m_axis_tready) begin
        m_axis_tvalid <= 1'b0;
      end
    end
  end

endmodule

`default_nettype wire

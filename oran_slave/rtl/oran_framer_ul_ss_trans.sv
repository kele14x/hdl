// File: oran_framer_ul_ss_trans.sv
// Brief: Insert transport (eCPRI) header at the beginning of Ethernet Packet
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_framer_ul_ss_trans #(
    parameter bit [15:0] PC_ID = 16'h0000
) (
    input var         clk,
    input var         rst,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tlast,
    output var        m_axis_tvalid,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tlast,
    input var         s_axis_tvalid,
    input var  [15:0] s_axis_tuser    // packet size
);

  import oran_pkg::*;

  logic        insert_trans_hdr_n;

  // Sequence counter for each PCID
  logic [ 7:0] seq_cnt;

  // Transport Header (64-bit)
  logic [ 3:0] ecpri_version = 4'b0001;
  logic [ 2:0] ecpri_reserved = 3'b000;
  logic        ecpri_concat = 1'b0;
  logic [ 7:0] ecpri_messagetype = 8'h00;  // 0 for IQ, 2 for C-Plane
  logic [15:0] ecpri_payloadsize;
  logic [15:0] ecpri_pcid = PC_ID;
  logic [ 7:0] ecpri_seqid;
  logic        ecpri_ebit = 1'b1;
  logic [ 6:0] ecpri_subseqid = 7'h0000;

  logic [63:0] ecpri_header;

  logic [63:0] s_axis_tdata_d;
  logic [ 7:0] s_axis_tkeep_d;
  logic        s_axis_tvalid_d;
  logic        s_axis_tlast_d;


  // eCPRI Transport Header

  assign ecpri_header = {
    ecpri_version,
    ecpri_reserved,
    ecpri_concat,
    ecpri_messagetype,
    ecpri_payloadsize,
    ecpri_pcid,
    ecpri_seqid,
    ecpri_ebit,
    ecpri_subseqid
  };

  assign ecpri_seqid = seq_cnt;

  always_ff @(posedge clk) begin
    if (rst) begin
      seq_cnt <= '0;
    end else if (m_axis_tvalid && m_axis_tlast) begin
      seq_cnt <= seq_cnt + 1;
    end
  end

  assign ecpri_payloadsize = s_axis_tuser + 4;


  // Delay the input AXIS for one clock

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      s_axis_tdata_d <= s_axis_tdata;
      s_axis_tkeep_d <= s_axis_tkeep;
      s_axis_tlast_d <= s_axis_tlast;
    end
    s_axis_tvalid_d <= s_axis_tvalid;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      insert_trans_hdr_n <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      insert_trans_hdr_n <= 1'b0;
    end else if (s_axis_tvalid) begin
      insert_trans_hdr_n <= 1'b1;
    end
  end

  // Master AXIS

  always_ff @(posedge clk) begin
    if (!insert_trans_hdr_n && s_axis_tvalid) begin
      m_axis_tdata <= byte_reverse(ecpri_header);
    end else begin
      m_axis_tdata <= s_axis_tdata_d;
    end
  end

  always_ff @(posedge clk) begin
    if (!insert_trans_hdr_n && s_axis_tvalid) begin
      m_axis_tkeep <= '1;
    end else begin
      m_axis_tkeep <= s_axis_tkeep_d;
    end
  end

  always_ff @(posedge clk) begin
    m_axis_tvalid <= (!insert_trans_hdr_n && s_axis_tvalid) || s_axis_tvalid_d;
  end

  always_ff @(posedge clk) begin
    if (!insert_trans_hdr_n && s_axis_tvalid) begin
      m_axis_tlast <= 1'b0;
    end else begin
      m_axis_tlast <= s_axis_tlast_d;
    end
  end

endmodule

`default_nettype wire

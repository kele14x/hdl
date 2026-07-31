// File: oran_framer_ul_ss_app.sv
// Breif: Prefix the packet with O-RAN application common header (timing 
//        header).
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_framer_ul_ss_app (
    input var         clk,
    input var         rst,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    output var [15:0] m_axis_tuser,   // Payload size
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    input var  [47:0] s_axis_tuser    // {payload size, Application header}
);

  import oran_pkg::*;

  logic insert_app_hdr_n;
  logic extra_last;

  // Application Header (32-bit)
  logic app_datadirection;  // 0 for UL, 1 for DL
  logic [2:0] app_payloadversion;
  logic [3:0] app_filterindex;
  logic [7:0] app_frameid;
  logic [3:0] app_subframeid;
  logic [5:0] app_slotid;
  logic [5:0] app_symbolid;

  logic [31:0] app_header;

  logic [63:0] s_axis_tdata_rev;
  logic [63:0] s_axis_tdata_d;
  logic [7:0] s_axis_tkeep_d;

  wire unused_app_header_fields = &{
    1'b0,
    app_datadirection,
    app_payloadversion,
    app_filterindex,
    app_frameid,
    app_subframeid,
    app_slotid,
    app_symbolid,
    s_axis_tdata_d[63:32],
    s_axis_tkeep_d[3:0]
  };


  // Main
  //-----

  assign {
    app_datadirection,
    app_payloadversion,
    app_filterindex,
    app_frameid,
    app_subframeid,
    app_slotid,
    app_symbolid
  } = app_header;

  assign app_header = s_axis_tuser[31:0];


  // Insert application at first tick

  always_ff @(posedge clk) begin
    if (rst) begin
      insert_app_hdr_n <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      insert_app_hdr_n <= 1'b0;
    end else if (s_axis_tvalid) begin
      insert_app_hdr_n <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      extra_last <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast && s_axis_tkeep[4]) begin
      extra_last <= 1'b1;
    end else begin
      extra_last <= 1'b0;
    end
  end


  // Delay the input for 1 clock

  assign s_axis_tdata_rev = byte_reverse(s_axis_tdata);

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      s_axis_tdata_d <= s_axis_tdata_rev;
      s_axis_tkeep_d <= s_axis_tkeep;
    end
  end


  // Output

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tdata <= byte_reverse({s_axis_tdata_d[31:0], 32'b0});
    end else if (!insert_app_hdr_n && s_axis_tvalid) begin
      m_axis_tdata <= byte_reverse({app_header, s_axis_tdata_rev[63:32]});
    end else if (s_axis_tvalid) begin
      m_axis_tdata <= byte_reverse({s_axis_tdata_d[31:0], s_axis_tdata_rev[63:32]});
    end
  end

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tkeep <= {4'b0, s_axis_tkeep_d[7:4]};
    end else if (!insert_app_hdr_n && s_axis_tvalid) begin
      m_axis_tkeep <= {s_axis_tkeep[3:0], 4'b1111};
    end else if (s_axis_tvalid) begin
      m_axis_tkeep <= {s_axis_tkeep[3:0], s_axis_tkeep_d[7:4]};
    end
  end

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tlast <= 1'b1;
    end else if (s_axis_tvalid && s_axis_tlast && !s_axis_tkeep[4]) begin
      m_axis_tlast <= 1'b1;
    end else if (s_axis_tvalid) begin
      m_axis_tlast <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tvalid <= 1'b1;
    end else if (s_axis_tvalid) begin
      m_axis_tvalid <= 1'b1;
    end else begin
      m_axis_tvalid <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (!insert_app_hdr_n && s_axis_tvalid) begin
      m_axis_tuser <= {s_axis_tuser[47:32]};
    end
  end

endmodule

`default_nettype wire

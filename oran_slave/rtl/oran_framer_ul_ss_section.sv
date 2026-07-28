// File: oran_framer_ul_ss_section.sv
// Brief: Prefix the packet with O-RAN application application section header.
//        The section header could be 32-bit or 48-bit (udCompHdr included).
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_framer_ul_ss_section (
    input var         clk,
    input var         rst,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    output var [47:0] m_axis_tuser,      // {Payload size, Application Header}
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    input var  [63:0] s_axis_tuser,      // Application header
    //
    input var         ctrl_has_udcomphdr,
    input var  [ 3:0] ctrl_ud_comp_meth,
    input var  [ 3:0] ctrl_ud_iq_width
);

  import oran_pkg::*;

  logic        insert_sec_hdr_n;
  logic        extra_last;

  // Section Header (32-bit)
  logic [11:0] section_sectionid = 12'b0;
  logic        section_rb = 1'b0;
  logic        section_syminc = 1'b0;
  logic [ 9:0] section_startprbu = 10'b0;
  logic [ 7:0] section_numprbu = 8'b0;

  logic [31:0] section_header;

  logic [63:0] s_axis_tdata_rev;
  logic [63:0] s_axis_tdata_d;
  logic [ 7:0] s_axis_tkeep_d;


  // Main
  //-----

  assign {
    section_sectionid,
    section_rb,
    section_syminc,
    section_startprbu,
    section_numprbu
  } = section_header;

  assign section_header = s_axis_tuser[31:0];


  // Insert application at first tick

  always_ff @(posedge clk) begin
    if (rst) begin
      insert_sec_hdr_n <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      insert_sec_hdr_n <= 1'b0;
    end else if (s_axis_tvalid) begin
      insert_sec_hdr_n <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      extra_last <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      if (ctrl_has_udcomphdr && s_axis_tkeep[2]) begin
        extra_last <= 1'b1;
      end else if (s_axis_tkeep[4]) begin
        extra_last <= 1'b1;
      end else begin
        extra_last <= 1'b0;
      end
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
      if (ctrl_has_udcomphdr) begin
        m_axis_tdata <= byte_reverse({s_axis_tdata_d[47:0], 16'b0});
      end else begin
        m_axis_tdata <= byte_reverse({s_axis_tdata_d[31:0], 16'b0});
      end
    end else if (!insert_sec_hdr_n && s_axis_tvalid) begin
      if (ctrl_has_udcomphdr) begin
        m_axis_tdata <= byte_reverse({section_header, 16'h1900, s_axis_tdata_rev[63:48]});
      end else begin
        m_axis_tdata <= byte_reverse({section_header, s_axis_tdata_rev[63:32]});
      end
    end else if (s_axis_tvalid) begin
      if (ctrl_has_udcomphdr) begin
        m_axis_tdata <= byte_reverse({s_axis_tdata_d[47:0], s_axis_tdata_rev[63:48]});
      end else begin
        m_axis_tdata <= byte_reverse({s_axis_tdata_d[31:0], s_axis_tdata_rev[63:32]});
      end
    end
  end

  always_ff @(posedge clk) begin
    if (extra_last) begin
      if (ctrl_has_udcomphdr) begin
        m_axis_tkeep <= {2'b00, s_axis_tkeep_d[7:2]};
      end else begin
        m_axis_tkeep <= {4'b00, s_axis_tkeep_d[7:4]};
      end
    end else if (!insert_sec_hdr_n && s_axis_tvalid) begin
      if (ctrl_has_udcomphdr) begin
        m_axis_tkeep <= {s_axis_tkeep[1:0], 6'b111111};
      end else begin
        m_axis_tkeep <= {s_axis_tkeep[3:0], 4'b1111};
      end
    end else if (s_axis_tvalid) begin
      if (ctrl_has_udcomphdr) begin
        m_axis_tkeep <= {s_axis_tkeep[1:0], s_axis_tkeep_d[7:2]};
      end else begin
        m_axis_tkeep <= {s_axis_tkeep[3:0], s_axis_tkeep_d[7:4]};
      end
    end
  end

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tlast <= 1'b1;
    end else if (s_axis_tvalid && s_axis_tlast && !s_axis_tkeep[2]) begin
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
    if (!insert_sec_hdr_n && s_axis_tvalid) begin
      if (ctrl_ud_comp_meth == 0) begin
        m_axis_tuser <= {section_numprbu * 48 + 8 + ctrl_has_udcomphdr * 2, s_axis_tuser[63:32]};
      end else begin
        m_axis_tuser <= {section_numprbu * 28 + 8 + ctrl_has_udcomphdr * 2, s_axis_tuser[63:32]};
      end
    end
  end

endmodule

`default_nettype wire

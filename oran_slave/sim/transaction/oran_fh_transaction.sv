`ifndef __ORAN_FH_TRANSACTION__
`define __ORAN_FH_TRANSACTION__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4s_transaction.sv"
`include "eth_transaction.sv"
`include "ecpri_transaction.sv"


//
// ORAN Application Common Header
//
class oran_application_header extends uvm_object;

  // Declaration of fields

  bit            data_direction;
  bit      [2:0] payload_version = 3'b001;
  bit      [3:0] filter_index;
  rand bit [7:0] frame_id;
  rand bit [3:0] subframe_id;
  rand bit [5:0] slot_id;
  rand bit [5:0] symbol_id;

  // Declaration of utility and field macros

  `uvm_object_utils_begin(oran_application_header)
    `uvm_field_int(data_direction, UVM_DEFAULT)
    `uvm_field_int(payload_version, UVM_DEFAULT)
    `uvm_field_int(filter_index, UVM_DEFAULT)
    `uvm_field_int(frame_id, UVM_DEFAULT)
    `uvm_field_int(subframe_id, UVM_DEFAULT)
    `uvm_field_int(slot_id, UVM_DEFAULT)
    `uvm_field_int(symbol_id, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_oran_application_header");
    super.new(.name(name));
  endfunction : new

  // Helper functions

  virtual function int get_size();
    return 4;
  endfunction : get_size

  virtual function bit [7:0] get_byte(input int idx);
    bit [7:0] temp[];
    this.get_bytes(temp);
    return temp[idx];
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    bit [7:0] temp[];
    temp = {>>{this.data_direction, this.payload_version, this.filter_index,
      this.frame_id, this.subframe_id, this.slot_id, this.symbol_id}};
    bytes = {bytes, temp};
  endfunction : get_bytes

endclass : oran_application_header


//
// ORAN Application Section Header
//
class oran_section_header extends uvm_object;

  // Declaration of fields

  rand bit [11:0] section_id;
  bit             rb;
  bit             sym_inc;
  rand bit [ 9:0] start_prbu;
  rand bit [ 7:0] num_prbu;

  rand bit        has_ud_comp_hdr;
  // ud_comp_hdr = {ud_iq_width, ud_comp_meth}
  rand bit [ 3:0] ud_iq_width;
  rand bit [ 3:0] ud_comp_meth;
  bit      [ 7:0] reserved;

  // Declaration of utility and field macros

  `uvm_object_utils_begin(oran_section_header)
    `uvm_field_int(section_id, UVM_DEFAULT)
    `uvm_field_int(rb, UVM_DEFAULT)
    `uvm_field_int(sym_inc, UVM_DEFAULT)
    `uvm_field_int(start_prbu, UVM_DEFAULT)
    `uvm_field_int(num_prbu, UVM_DEFAULT)
    `uvm_field_int(has_ud_comp_hdr, UVM_DEFAULT)
    `uvm_field_int(ud_iq_width, UVM_DEFAULT)
    `uvm_field_int(ud_comp_meth, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_oran_section_header");
    super.new(.name(name));
  endfunction : new

  // Helper functions

  virtual function int get_size();
    return 4 + this.has_ud_comp_hdr * 2;
  endfunction : get_size

  virtual function bit [7:0] get_byte(input int idx);
    bit [7:0] temp[];
    this.get_bytes(temp);
    return temp[idx];
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    bit [7:0] temp[];
    if (this.has_ud_comp_hdr) begin
      temp = {>>{this.section_id, this.rb, this.sym_inc, this.start_prbu, this.num_prbu,
        this.ud_iq_width, this.ud_comp_meth, this.reserved}};
    end else begin
      temp = {>>{this.section_id, this.rb, this.sym_inc, this.start_prbu, this.num_prbu}};
    end
    bytes = {bytes, temp};
  endfunction : get_bytes

endclass : oran_section_header


//
// ORAN Application Section Field
//
class oran_section extends uvm_object;

  // Fields

  rand oran_section_header        section_hdr;
  // raw IQ samples
  rand bit                 [15:0] iqdata      [];
  bit                      [ 7:0] payload     [];

  // Constraints

  constraint sample_c {iqdata.size() == this.section_hdr.num_prbu * 24;}

  // Macros

  `uvm_object_utils_begin(oran_section)
    `uvm_field_object(section_hdr, UVM_DEFAULT)
    `uvm_field_array_int(iqdata, UVM_DEFAULT)
    `uvm_field_array_int(payload, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_oran_section");
    super.new(.name(name));
    this.section_hdr = oran_section_header::type_id::create("section_hdr");
  endfunction : new

  function void post_randomize();
    this.payload = new[0];
    if (this.section_hdr.ud_comp_meth == 0) begin
      this.uncompressed_payload();
    end else if (this.section_hdr.ud_comp_meth == 1) begin
      this.bfp_compressed_payload();
    end else begin
      `uvm_fatal("", "Unsupported udCompMeth");
    end
  endfunction : post_randomize

  // Helper functions

  function void uncompressed_payload();
    this.payload = {>>{this.iqdata}};
  endfunction : uncompressed_payload

  function void bfp_compressed_payload();
    bit signed [15:0] max;
    int msb;
    bit [7:0] exp;
    bit [7:0] temp[];

    this.payload = new[0];

    for (int rb = 0; rb < this.iqdata.size() / 24; rb++) begin
      // Find max
      max = 0;
      for (int i = 0; i < 24; i++) begin
        if ($signed(iqdata[rb*24+i]) > max) max = iqdata[rb*24+i];
        if ($signed(~iqdata[rb*24+i]) > max) max = ~iqdata[rb*24+i];
      end

      // Find MSB
      for (msb = 15; msb >= this.section_hdr.ud_iq_width; msb--) begin
        if (max[msb] ^ max[msb-1]) break;
      end

      // Exponent
      exp = msb - this.section_hdr.ud_iq_width + 1;

      // Compress and pack
      if (this.section_hdr.ud_iq_width == 6) begin
        bit [5:0] buffer[24];
        for (int i = 0; i < 24; i++) begin
          buffer[i] = iqdata[rb * 24 + i] >> exp;
        end
        temp = {>>{buffer}};
      end else if (this.section_hdr.ud_iq_width == 7) begin
        bit [6:0] buffer[24];
        for (int i = 0; i < 24; i++) begin
          buffer[i] = iqdata[rb * 24 + i] >> exp;
        end
        temp = {>>{buffer}};
      end else if (this.section_hdr.ud_iq_width == 8) begin
        bit [7:0] buffer[24];
        for (int i = 0; i < 24; i++) begin
          buffer[i] = iqdata[rb * 24 + i] >> exp;
        end
        temp = {>>{buffer}};
      end else if (this.section_hdr.ud_iq_width == 9) begin
        bit [8:0] buffer[24];
        for (int i = 0; i < 24; i++) begin
          buffer[i] = iqdata[rb * 24 + i] >> exp;
        end
        temp = {>>{buffer}};
      end else begin
        `uvm_fatal("", "Not implemented BFP compress bit width");
      end
      this.payload = {this.payload, exp, temp};
    end
  endfunction

  // Interface functions

  virtual function int get_size();
    int c = 0;
    c = c + this.section_hdr.get_size();
    c = c + this.payload.size();
    return c;
  endfunction : get_size

  virtual function bit [7:0] get_byte(input int c);
    if (c < section_hdr.get_size()) begin
      return section_hdr.get_byte(c);
    end

    c = c - this.section_hdr.get_size();
    return this.payload[c];
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    this.section_hdr.get_bytes(bytes);
    bytes = {bytes, this.payload};
  endfunction : get_bytes

endclass : oran_section


//
// ORAN FH U-Plane Message
//
class oran_fh_u_message extends ecpri_iq_message;

  // Declaration of transaction fields

  rand oran_application_header app_hdr;
  rand oran_section            sections[];

  // Declaration of utility and field macros

  `uvm_object_utils_begin(oran_fh_u_message)
    `uvm_field_object(app_hdr, UVM_DEFAULT)
    `uvm_field_array_object(sections, UVM_DEFAULT)
  `uvm_object_utils_end

  // Declaration of constraints

  constraint payload_size_c {this.payload.size() == 0;}

  // Constructor

  function new(input string name = "unnamed_oran_fh_u_message");
    super.new(.name(name));
    this.app_hdr = oran_application_header::type_id::create("app_hdr");
  endfunction : new

  function void post_randomize();
    for (int i = 0; i < sections.size(); i++) begin
      sections[i] = oran_section::type_id::create($sformatf("sections%0d", i));
      assert (this.sections[i].randomize())
      else begin
        `uvm_error("", $sformatf("Sections[%0d] randomize fail", i))
      end
    end
  endfunction : post_randomize

  // Helper functions

  virtual function void normalize();
    int c = 0;
    c = c + this.iq_hdr.get_size();
    c = c + this.app_hdr.get_size();
    for (int i = 0; i < this.sections.size(); i++) begin
      c = c + this.sections[i].get_size();
    end
    this.common_hdr.payload_size = c;
  endfunction : normalize

  virtual function int get_size();
    int c = 0;
    c = c + this.common_hdr.get_size();
    c = c + this.iq_hdr.get_size();
    c = c + this.app_hdr.get_size();
    for (int i = 0; i < this.sections.size(); i++) begin
      c = c + this.sections[i].get_size();
    end
    return c;
  endfunction : get_size

  virtual function bit [7:0] get_byte(input int idx);
    if (idx < this.common_hdr.get_size()) begin
      return this.common_hdr.get_byte(idx);
    end

    idx = idx - this.common_hdr.get_size();
    if (idx < this.iq_hdr.get_size()) begin
      return this.iq_hdr.get_byte(idx);
    end

    idx = idx - this.iq_hdr.get_size();
    if (idx < this.app_hdr.get_size()) begin
      return this.app_hdr.get_byte(idx);
    end

    idx = idx - this.app_hdr.get_size();
    for (int i = 0; i < this.sections.size(); i++) begin
      if (idx < this.sections[i].get_size()) begin
        return this.sections[i].get_byte(idx);
      end
      idx = idx - this.sections[i].get_size();
    end

    return this.payload[idx];
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    this.common_hdr.get_bytes(bytes);
    this.iq_hdr.get_bytes(bytes);
    this.app_hdr.get_bytes(bytes);
    for (int i = 0; i < this.sections.size(); i++) begin
      this.sections[i].get_bytes(bytes);
    end
  endfunction : get_bytes

  // Mannual create

  virtual function oran_section create_section();
    oran_section sec;
    sec = oran_section::type_id::create("sec");
    this.sections = {this.sections, sec};
    return sec;
  endfunction

endclass : oran_fh_u_message


//
// ORAN FH C-Plance Message
//
class oran_fh_c_message extends ecpri_iqc_message;

  // Declaration of transaction fields

  oran_application_header app_hdr;
  oran_section            sections[];

  // Declaration of utility and field macros

  `uvm_object_utils_begin(oran_fh_c_message)
    `uvm_field_object(app_hdr, UVM_DEFAULT)
    `uvm_field_array_object(sections, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_oran_fh_c_message");
    super.new(.name(name));
    this.app_hdr = oran_application_header::type_id::create("app_hdr");
    for (int i = 0; i < sections.size(); i++) begin
      sections[i] = oran_section::type_id::create($sformatf("sections%0d", i));
    end
  endfunction : new

  function void post_randomize();
    for (int i = 0; i < sections.size(); i++) begin
      assert (this.sections[i].randomize())
      else begin
        `uvm_error("", "section randomize fail")
      end
    end
  endfunction

  // Helper functions

  // Get packet total size (including header) in bytes
  virtual function int get_size();
    int c = 0;
    c = c + this.app_hdr.get_size();
    for (int i = 0; i < this.sections.size(); i++) begin
      c = c + this.sections[i].get_size();
    end
    return c;
  endfunction

  // Get the byte in packet at index n
  virtual function bit [7:0] get_byte(input int idx);
    if (idx < this.app_hdr.get_size()) begin
      return this.app_hdr.get_byte(idx);
    end
    idx = idx - this.app_hdr.get_size();

    for (int i = 0; i < this.sections.size(); i++) begin
      if (idx < this.sections[i].get_size()) begin
        return this.sections[i].get_byte(idx);
      end
      idx = idx - this.sections[i].get_size();
    end

    if (idx < this.payload.size()) begin
      return this.payload[idx];
    end

    `uvm_error("", "Index out of range!");
    return 8'd0;
  endfunction

endclass : oran_fh_c_message


//
// ORAN FH Packet Transaction
//
class oran_fh_transaction extends ecpri_transaction;

  // Declaration of utility and field macros,

  `uvm_object_utils(oran_fh_transaction)

  // Constructor

  function new(input string name = "unnamed_oran_fh_transaction");
    super.new(.name(name));
  endfunction : new

  // Helper functions

  // Create O-RAN FH U-Plane message and add it to packet, the newly created
  // message is returned to user.
  virtual function oran_fh_u_message create_u_message();
    oran_fh_u_message msg;
    msg = oran_fh_u_message::type_id::create("msg");
    this.messages = {this.messages, msg};
    return msg;
  endfunction : create_u_message

  // Create O-RAN FH C-Plane message and add it to packet, the newly created
  // message is returned to user.
  virtual function oran_fh_c_message create_c_message();
    oran_fh_c_message msg;
    msg = oran_fh_c_message::type_id::create("msg");
    this.messages = {this.messages, msg};
    return msg;
  endfunction : create_c_message

endclass : oran_fh_transaction

`default_nettype wire

`endif

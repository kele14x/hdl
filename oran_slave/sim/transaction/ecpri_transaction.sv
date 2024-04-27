`ifndef __ECPRI_TRANSACTION__
`define __ECPRI_TRANSACTION__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4s_transaction.sv"
`include "eth_transaction.sv"


//
// eCPRI Common Header
//
class ecpri_common_header extends uvm_object;

  // Fields

  bit      [ 3:0] version        = 4'b0001;
  bit      [ 2:0] reserved;
  rand bit        concatenation;
  rand bit [ 7:0] message_type;
  rand bit [15:0] payload_size;

  // Macros

  `uvm_object_utils_begin(ecpri_common_header)
    `uvm_field_int(version, UVM_DEFAULT)
    `uvm_field_int(concatenation, UVM_DEFAULT)
    `uvm_field_int(message_type, UVM_DEFAULT)
    `uvm_field_int(payload_size, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constraints

  // As eCPRI specification v2.0, type 0 ~ 11 is defined, 12 ~ 64 are reversed
  // 64 ~ 255 is vendor specific
  constraint message_type_c {this.message_type inside {[0 : 11]};}

  // Constructor

  function new(input string name = "unnamed_ecpri_common_header");
    super.new(.name(name));
  endfunction : new

  // Helper functions

  virtual function int get_size();
    return 4;
  endfunction : get_size

  virtual function bit [7:0] get_byte(input int idx);
    bit [7:0] bytes[];
    this.get_bytes(bytes);
    return bytes[idx];
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    bit [7:0] temp[];
    temp = {>>{this.version, this.reserved, this.concatenation, this.message_type,
      this.payload_size}};
    bytes = {bytes, temp};
  endfunction : get_bytes

endclass : ecpri_common_header


//
// eCPRI IQ Header (Type #0)
//
class ecpri_iq_header extends uvm_object;

  // Fields

  bit [15:0] pcid  = 16'h0000;
  bit [15:0] seqid = 16'h0000;

  // Macros

  `uvm_object_utils_begin(ecpri_iq_header)
    `uvm_field_int(pcid, UVM_DEFAULT)
    `uvm_field_int(seqid, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_ecpri_iq_header");
    super.new(.name(name));
  endfunction : new

  // Helper functions

  virtual function int get_size();
    return 4;
  endfunction

  virtual function bit [7:0] get_byte(input int idx);
    bit [7:0] bytes[];
    this.get_bytes(bytes);
    return bytes[idx];
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    bit [7:0] temp[];
    temp  = {>>{this.pcid, this.seqid}};
    bytes = {bytes, temp};
  endfunction : get_bytes

endclass : ecpri_iq_header


//
// eCPRI IQC Header (Type #2)
//
class ecpri_iqc_header extends ecpri_iq_header;

  // Macros

  `uvm_object_utils(ecpri_iqc_header)

  // Constructor

  function new(input string name = "unnamed_ecpri_iqc_header");
    super.new(.name(name));
  endfunction : new

endclass : ecpri_iqc_header


//
// General eCPRI Message
//
class ecpri_message extends axi4s_transaction_base;

  // Declaration of transaction fields

  rand ecpri_common_header       common_hdr;
  rand bit                 [7:0] payload    [];


  // Declaration of utility and field macros

  `uvm_object_utils_begin(ecpri_message)
    `uvm_field_object(common_hdr, UVM_DEFAULT)
    `uvm_field_array_int(payload, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constraints

  constraint payload_size_c {this.payload.size() inside {[1 : 50]};}

  // Constructor

  function new(input string name = "unnamed_ecpri_message");
    super.new(.name(name));
    common_hdr = ecpri_common_header::type_id::create("common_hdr");
  endfunction : new

  // Helper functions

  virtual function void normalize();
    this.common_hdr.payload_size = this.payload.size();
  endfunction : normalize

  virtual function int get_size();
    int c = 0;
    c = c + this.common_hdr.get_size();
    c = c + this.payload.size();
    // For concat message, padding to 4-byte boundary
    if (this.common_hdr.concatenation) begin
      c = ((c + 3) / 4) * 4;
    end
    return c;
  endfunction : get_size

  virtual function bit [7:0] get_byte(input int idx);
    if (idx < this.common_hdr.get_size()) begin
      return this.common_hdr.get_byte(idx);
    end

    idx = idx - this.common_hdr.get_size();
    if (idx < this.payload.size()) begin
      return this.payload[idx];
    end

    return 8'b0;
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    int pad;
    bit [7:0] padding[];

    this.common_hdr.get_bytes(bytes);
    bytes = {bytes, this.payload};

    // Padding to 4-byte boundary if concatenation
    if (this.common_hdr.concatenation) begin
      pad = this.payload.size() % 4;
      pad = ((pad == 0) ? 0 : 4 - pad);
      padding = new[pad];
      bytes = {bytes, padding};
    end
  endfunction : get_bytes

  virtual function bit [`MAX_TUSER_WIDTH-1:0] get_tuser();
    return '0;
  endfunction : get_tuser

  virtual function bit [`MAX_TID_WIDTH-1:0] get_tid();
    return '0;
  endfunction : get_tid

  virtual function bit [`MAX_TDEST_WIDTH-1:0] get_tdest();
    return '0;
  endfunction : get_tdest

endclass : ecpri_message


//
// eCPRI Type #0 IQ Message
//
class ecpri_iq_message extends ecpri_message;

  // Fields

  rand ecpri_iq_header iq_hdr;

  // Macros

  `uvm_object_utils_begin(ecpri_iq_message)
    `uvm_field_object(iq_hdr, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_ecpri_iq_message");
    super.new(.name(name));
    this.iq_hdr = ecpri_iq_header::type_id::create("iq_hdr");
  endfunction : new

  // Helper functions

  virtual function int get_size();
    int c = 0;
    c = c + super.get_size();
    c = c + this.iq_hdr.get_size();
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
    if (idx < this.payload.size()) begin
      return this.payload[idx];
    end

    return 8'd0;
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    int pad;
    bit [7:0] padding[];

    this.common_hdr.get_bytes(bytes);
    this.iq_hdr.get_bytes(bytes);
    bytes = {bytes, this.payload};

    // Padding to 4-byte boundary if concatenation
    if (this.common_hdr.concatenation) begin
      pad = this.payload.size() % 4;
      pad = ((pad == 0) ? 0 : 4 - pad);
      padding = new[pad];
      bytes = {bytes, padding};
    end
  endfunction : get_bytes

endclass : ecpri_iq_message


//
// eCPRI Type #2 IQC Message
//
class ecpri_iqc_message extends ecpri_message;

  // Fields

  ecpri_iqc_header iqc_hdr;

  // Macros

  `uvm_object_utils_begin(ecpri_iqc_message)
    `uvm_field_object(iqc_hdr, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_ecpri_iqc_message");
    super.new(.name(name));
    this.common_hdr = ecpri_common_header::type_id::create("common_hdr");
    this.iqc_hdr    = ecpri_iqc_header::type_id::create("iqc_hdr");
  endfunction : new

  virtual function int get_size();
    int c = 0;
    c = c + this.common_hdr.get_size();
    c = c + this.iqc_hdr.get_size();
    c = c + this.payload.size();
    // For concat message, padding to 4-byte boundary
    if (this.common_hdr.concatenation) begin
      c = ((c + 3) / 4) * 4;
    end
    return c;
  endfunction : get_size

  virtual function bit [7:0] get_byte(input int idx);
    if (idx < this.common_hdr.get_size()) begin
      return this.common_hdr.get_byte(idx);
    end

    idx = idx - this.common_hdr.get_size();
    if (idx < this.iqc_hdr.get_size()) begin
      return this.iqc_hdr.get_byte(idx);
    end

    idx = idx - this.iqc_hdr.get_size();
    if (idx < this.payload.size()) begin
      return this.payload[idx];
    end

    return 8'd0;
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    int pad;
    bit [7:0] padding[];

    this.common_hdr.get_bytes(bytes);
    this.iqc_hdr.get_bytes(bytes);
    bytes = {bytes, this.payload};

    // Padding to 4-byte boundary if concatenation
    if (this.common_hdr.concatenation) begin
      pad = this.payload.size() % 4;
      pad = ((pad == 0) ? 0 : 4 - pad);
      padding = new[pad];
      bytes = {bytes, padding};
    end
  endfunction : get_bytes

endclass : ecpri_iqc_message


//
// eCPRI Type #5 One-Way Delay Measurement Message
//
class ecpri_delay_measure_message extends ecpri_message;

  // Fields

  bit [ 7:0] measurement_id;
  bit [ 7:0] action_type;
  bit [79:0] timestamp;
  bit [63:0] compensation_value;

  // Macros

  `uvm_object_utils_begin(ecpri_delay_measure_message)
    `uvm_field_int(measurement_id, UVM_DEFAULT)
    `uvm_field_int(action_type, UVM_DEFAULT)
    `uvm_field_int(timestamp, UVM_DEFAULT)
    `uvm_field_int(compensation_value, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_ecpri_delay_measure_message");
    super.new(.name(name));
  endfunction : new

  virtual function void normalize();
    this.common_hdr.message_type = 5;
    this.common_hdr.payload_size = 20;
  endfunction : normalize

  // Helper functions

  virtual function int get_size();
    int c = 0;
    c = c + this.common_hdr.get_size();
    c = c + 20;
    return c;
  endfunction : get_size

  virtual function bit [7:0] get_byte(input int idx);
    bit [7:0] temp[];
    if (idx < this.common_hdr.get_size()) begin
      return this.common_hdr.get_byte(idx);
    end

    idx = idx - this.common_hdr.get_size();
    if (idx < 20) begin
      temp = {>>{this.measurement_id, this.action_type, this.timestamp, this.compensation_value}};
      return temp[idx];
    end

    return 8'd0;
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    bit [7:0] temp[];
    this.common_hdr.get_bytes(bytes);
    temp  = {>>{this.measurement_id, this.action_type, this.timestamp, this.compensation_value}};
    bytes = {bytes, temp};
  endfunction : get_bytes

endclass : ecpri_delay_measure_message



//
// Multiple eCPRI Messages concat in one
//
class ecpri_concat_message extends axi4s_transaction_base;

  // Fields

  ecpri_message messages     [];
  rand int      num_messages;

  // Macros

  `uvm_object_utils_begin(ecpri_concat_message)
    `uvm_field_array_object(messages, UVM_DEFAULT)
    `uvm_field_int(num_messages, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constraints

  // Do not generate too much messages
  constraint num_messages_c {1 <= this.num_messages && this.num_messages <= 5;}

  // Constructor

  function new(input string name = "unnamed_ecpri_raw_transaction");
    super.new(.name(name));
  endfunction : new

  function void post_randomize();
    // Vivado seems has a bug directly randomize the messages array, so
    // use a rand int here to control the messages size
    this.messages = new[this.num_messages];
    for (int i = 0; i < this.messages.size(); i++) begin
      messages[i] = ecpri_message::type_id::create($sformatf("Messages[%0d]", i));
      assert (this.messages[i].randomize())
      else begin
        `uvm_error("", $sformatf("Messages[%0d] randomize fail", i))
      end
      if (i < this.messages.size() - 1) begin
        messages[i].common_hdr.concatenation = 1;
      end
    end
  endfunction : post_randomize

  // Help functions

  // Get packet total size (including header) in bytes
  virtual function int get_size();
    int c = 0;
    for (int i = 0; i < this.messages.size(); i++) begin
      c = c + this.messages[i].get_size();
    end
    return c;
  endfunction : get_size

  virtual function bit [7:0] get_byte(input int idx);
    for (int i = 0; i < this.messages.size(); i++) begin
      if (idx < this.messages[i].get_size()) begin
        return this.messages[i].get_byte(idx);
      end
      idx = idx - this.messages[i].get_size();
    end

    return 8'd0;
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    for (int i = 0; i < this.messages.size(); i++) begin
      this.messages[i].get_bytes(bytes);
    end
  endfunction

  virtual function bit [`MAX_TUSER_WIDTH-1:0] get_tuser();
    return '0;
  endfunction : get_tuser

  virtual function bit [`MAX_TID_WIDTH-1:0] get_tid();
    return '0;
  endfunction : get_tid

  virtual function bit [`MAX_TDEST_WIDTH-1:0] get_tdest();
    return '0;
  endfunction : get_tdest

  // Help functions

  // Create a eCPRI message and add it to messages array
  virtual function ecpri_message create_message(input int msg_type);
    ecpri_message msg;
    if (msg_type == 0) begin
      msg = ecpri_iq_message::type_id::create("msg");
      this.messages = {this.messages, msg};
    end else if (msg_type == 2) begin
      msg = ecpri_iqc_message::type_id::create("msg");
      this.messages = {this.messages, msg};
    end else if (msg_type == 5) begin
      msg = ecpri_delay_measure_message::type_id::create("msg");
      this.messages = {this.messages, msg};
    end else begin
      `uvm_error("", "Unsupported message type")
    end
    return msg;
  endfunction

endclass : ecpri_concat_message


//
// eCPRI Packet
//
class ecpri_transaction extends eth_transaction;

  // Fields

  rand ecpri_message messages[];

  // Macros

  `uvm_object_utils_begin(ecpri_transaction)
    `uvm_field_array_object(messages, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constraints

  constraint payload_size_c {
    this.payload.size() == 0;
  }

  // Constructor

  function new(input string name = "unnamed_ecpri_transaction");
    super.new(.name(name));
    this.mac_hdr.ethertype = 16'hAEFE;
  endfunction : new

  function void post_randomize();
    for (int i = 0; i < messages.size(); i++) begin
      messages[i] = ecpri_message::type_id::create($sformatf("Messages[%0d]", i));
      assert (this.messages[i].randomize())
      else begin
        `uvm_error("", $sformatf("Messages[%0d] randomize fail", i))
      end
    end
    this.normalize();
  endfunction : post_randomize

  // Helper functions

  virtual function void normalize();
    for (int i = 0; i < messages.size(); i++) begin
      messages[i].common_hdr.concatenation = ((i < (this.messages.size() - 1)) ? 1 : 0);
      messages[i].normalize();
    end
  endfunction : normalize

  virtual function int get_size();
    int c = 0;
    c = c + this.mac_hdr.get_size();
    for (int i = 0; i < this.messages.size(); i++) begin
      c = c + this.messages[i].get_size();
    end
    c = c + this.payload.size();
    return c;
  endfunction : get_size

  virtual function bit [7:0] get_byte(input int idx);
    if (idx < this.mac_hdr.get_size()) begin
      return this.mac_hdr.get_byte(idx);
    end

    idx = idx - this.mac_hdr.get_size();
    for (int i = 0; i < this.messages.size(); i++) begin
      if (idx < this.messages[i].get_size()) begin
        return this.messages[i].get_byte(idx);
      end
      idx = idx - this.messages[i].get_size();
    end

    return this.payload[idx];
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes []);
    this.mac_hdr.get_bytes(bytes);
    for (int i = 0; i < this.messages.size(); i++) begin
      this.messages[i].get_bytes(bytes);
    end
    bytes = {bytes, this.payload};
  endfunction : get_bytes

  // Manual create

  // Create a eCPRI message and add it to messages array
  virtual function ecpri_message create_message(input int msg_type);
    ecpri_message msg;
    if (msg_type == 0) begin
      msg = ecpri_iq_message::type_id::create("msg");
      this.messages = {this.messages, msg};
    end else if (msg_type == 2) begin
      msg = ecpri_iqc_message::type_id::create("msg");
      this.messages = {this.messages, msg};
    end else if (msg_type == 5) begin
      msg = ecpri_delay_measure_message::type_id::create("msg");
      this.messages = {this.messages, msg};
    end else begin
      `uvm_error("", "Unsupported message type")
    end
    return msg;
  endfunction

endclass

`default_nettype wire

`endif

`ifndef __ORAN_FH_SEQUENCE__
`define __ORAN_FH_SEQUENCE__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "oran_fh_transaction.sv"


class oran_fh_sequence extends uvm_sequence #(oran_fh_transaction);

  oran_fh_transaction req;

  // Macro

  `uvm_object_utils_begin(oran_fh_sequence)
    `uvm_field_object(req, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_oran_fh_sequence");
    super.new(.name(name));
  endfunction : new

  // UVM

  virtual task body();
    repeat (10) begin
      `uvm_do_with(req,
                   {
        req.mac_hdr.dest_mac == 48'h001122334466;
        req.mac_hdr.src_mac == 48'h001122334455;
        req.mac_hdr.has_vlan == 1'b1;
        //
//        req.sections[0].section_hdr.start_prbu == 0;
//        req.sections[0].section_hdr.num_prbu == 30;
      })
      `uvm_do_with(req,
                   {
        req.mac_hdr.dest_mac == 48'h001122334466;
        req.mac_hdr.src_mac == 48'h001122334455;
        req.mac_hdr.has_vlan == 1'b1;
        //
//        req.sections[0].section_hdr.start_prbu == 30;
//        req.sections[0].section_hdr.num_prbu == 21;
      })
      #(35.7 * 1000);
    end
  endtask

endclass

`default_nettype wire

`endif

`ifndef __ORAN_FH_20_2_BFP_SEQUENCE__
`define __ORAN_FH_20_2_BFP_SEQUENCE__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "oran_fh_transaction.sv"


//
// 20MHz 1 Ant
//
class oran_fh_20_2_bfp_sequence extends uvm_sequence #(oran_fh_transaction);

  // Macro

  `uvm_object_utils(oran_fh_20_2_bfp_sequence)

  // Constructor

  function new(input string name = "unnamed_oran_fh_20_2_bfp_sequence");
    super.new(.name(name));
  endfunction : new

  // UVM

  virtual task body();
    for (int sym = 4; sym < 280; sym++) begin
      oran_section sec;
      oran_fh_u_message msg;
      ecpri_delay_measure_message odm_msg;

      // Create a packet
      `uvm_create(req)
      req.mac_hdr.dest_mac = 48'h001122334466;
      req.mac_hdr.src_mac = 48'h001122334455;
      req.mac_hdr.has_vlan = 1'b1;
      req.mac_hdr.vlan_tci = 16'h7001;

      // Add U-Plane Message
      msg = req.create_u_message();
      msg.app_hdr.symbol_id = sym;

      // Add a U-Plane Section
      sec = msg.create_section();
      assert (sec.randomize() with {
        sec.section_hdr.start_prbu == 0;
        sec.section_hdr.num_prbu == 30;
        sec.section_hdr.has_ud_comp_hdr == 1;
        sec.section_hdr.ud_comp_meth == 1;
        sec.section_hdr.ud_iq_width == 9;
      });

      // Add a ODM Message
      odm_msg = ecpri_delay_measure_message'(req.create_message(5));
      odm_msg.measurement_id = 8'hFF;
      odm_msg.timestamp = 80'h112233445566778899AA;

      // Send message
      req.normalize();
      `uvm_info("", $sformatf("size = %d", req.get_size()), UVM_LOW)
      req.print();
      `uvm_send(req)

      // Create a packet
      `uvm_create(req)
      req.mac_hdr.dest_mac = 48'h001122334466;
      req.mac_hdr.src_mac = 48'h001122334455;
      req.mac_hdr.has_vlan = 1'b1;
      req.mac_hdr.vlan_tci = 16'h7001;

      // Add U-Plane Message
      msg = req.create_u_message();
      msg.app_hdr.symbol_id = sym;

      // Add a U-Plane Section
      sec = msg.create_section();
      assert (sec.randomize() with {
        sec.section_hdr.start_prbu == 30;
        sec.section_hdr.num_prbu == 21;
        sec.section_hdr.has_ud_comp_hdr == 1;
        sec.section_hdr.ud_comp_meth == 1;
        sec.section_hdr.ud_iq_width == 9;
      });

      // Add a ODM Message
      odm_msg = ecpri_delay_measure_message'(req.create_message(5));
      odm_msg.measurement_id = 8'hFF;
      odm_msg.timestamp = 80'h112233445566778899AA;

      // Send message
      req.normalize();
      `uvm_info("", $sformatf("size = %d", req.get_size()), UVM_LOW)
      req.print();
      `uvm_send(req)

      #(35.7 * 1000);
    end
  endtask

endclass : oran_fh_20_2_bfp_sequence

`default_nettype wire

`endif

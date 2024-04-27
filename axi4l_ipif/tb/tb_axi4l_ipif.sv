// File: tb_axi4l_ipif.sv
// Brief: Testbench for module axi4l_ipif
`timescale 1 ns / 100 ps
//
`default_nettype none
`include "uvm_macros.svh"

import uvm_pkg::*;
  
module tb_axi4l_ipif ();

  `include "axi4l_ipif_test.sv"


  parameter int ADDR_WIDTH = 12;
  parameter int DATA_WIDTH = 32;

  bit aclk;
  bit aresetn;

  // Virtual interface
  axi4l_ipif_if #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) vif (
      .aclk   (aclk),
      .aresetn(aresetn)
  );

  // Connects the interface to DUT
  axi4l_ipif #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) DUT (
      .aclk          (aclk),
      .aresetn       (aresetn),
      //
      .s_axi_awaddr  (vif.s_axi_awaddr),
      .s_axi_awprot  (vif.s_axi_awprot),
      .s_axi_awvalid (vif.s_axi_awvalid),
      .s_axi_awready (vif.s_axi_awready),
      //
      .s_axi_wdata   (vif.s_axi_wdata),
      .s_axi_wstrb   (vif.s_axi_wstrb),
      .s_axi_wvalid  (vif.s_axi_wvalid),
      .s_axi_wready  (vif.s_axi_wready),
      //
      .s_axi_bresp   (vif.s_axi_bresp),
      .s_axi_bvalid  (vif.s_axi_bvalid),
      .s_axi_bready  (vif.s_axi_bready),
      //
      .s_axi_araddr  (vif.s_axi_araddr),
      .s_axi_arprot  (vif.s_axi_arprot),
      .s_axi_arvalid (vif.s_axi_arvalid),
      .s_axi_arready (vif.s_axi_arready),
      //
      .s_axi_rdata   (vif.s_axi_rdata),
      .s_axi_rresp   (vif.s_axi_rresp),
      .s_axi_rvalid  (vif.s_axi_rvalid),
      .s_axi_rready  (vif.s_axi_rready),
      // IP i/f
      //=======
      .ipif_addr     (vif.ipif_addr),
      .ipif_req      (vif.ipif_req),
      .ipif_req_is_wr(vif.ipif_req_is_wr),
      //
      .ipif_wr_be    (vif.ipif_wr_be),
      .ipif_wr_data  (vif.ipif_wr_data),
      .ipif_wr_ack   (vif.ipif_wr_ack),
      .ipif_wr_err   (vif.ipif_wr_err),
      //
      .ipif_rd_data  (vif.ipif_rd_data),
      .ipif_rd_ack   (vif.ipif_rd_ack),
      .ipif_rd_err   (vif.ipif_rd_err)
  );

  // Stimulation
  initial begin
    aclk = 0;
    forever begin
      #5 aclk = ~aclk;
    end
  end

  initial begin
    aresetn = 0;
    #100;
    aresetn = 1;
  end

  // //-------------------------------------------------------------------------
  // // Task: reset_slave_and_interface
  // // Brief: Reset the DUT and all input signal to DUT
  // //-------------------------------------------------------------------------

  // task automatic reset_slave_and_interface();
  //   @(posedge aclk);
  //   // AXI
  //   aresetn <= 0;
  //   s_axi_awaddr <= 0;
  //   s_axi_awprot <= 0;
  //   s_axi_awvalid <= 0;
  //   s_axi_wdata <= 0;
  //   s_axi_wstrb <= 0;
  //   s_axi_wvalid <= 0;
  //   s_axi_bready <= 0;
  //   s_axi_araddr <= 0;
  //   s_axi_arprot <= 0;
  //   s_axi_arvalid <= 0;
  //   s_axi_rready <= 0;
  //   // WR
  //   ipif_wr_ack <= 0;
  //   ipif_wr_err <= 0;
  //   // RD
  //   ipif_rd_data <= 0;
  //   ipif_rd_ack <= 0;
  //   ipif_rd_err <= 0;
  //   repeat (16) @(posedge aclk);
  //   @(posedge aclk) aresetn <= 1;
  //   repeat (16) @(posedge aclk);
  // endtask

  // // Test cases

  // //-------------------------------------------------------------------------
  // // Task: test_single_write_same_time
  // // Brief: Test if DUT can accept signal AXI write. Only write response is
  // //        checked. No write effect is checked.
  // //-------------------------------------------------------------------------

  // task automatic test_single_write_same_time();
  //   logic awok, wok, bok, wreqok;
  //   awok = 0;
  //   wok = 0;
  //   bok = 0;
  //   wreqok = 0;
  //   reset_slave_and_interface();

  //   fork
  //     // Set write address
  //     begin
  //       @(posedge aclk);
  //       s_axi_awaddr  <= $urandom();
  //       s_axi_awvalid <= 1'b1;
  //       repeat (16) begin
  //         @(posedge aclk);
  //         if (s_axi_awready) begin
  //           awok = 1;
  //           s_axi_awvalid <= 1'b0;
  //           break;
  //         end
  //       end
  //     end

  //     // Set write data
  //     begin
  //       @(posedge aclk);
  //       s_axi_wdata  <= $urandom();
  //       s_axi_wstrb  <= $urandom();
  //       s_axi_wvalid <= 1'b1;
  //       repeat (16) begin
  //         @(posedge aclk);
  //         if (s_axi_wready) begin
  //           wok = 1;
  //           s_axi_wvalid <= 1'b0;
  //           break;
  //         end
  //       end
  //     end

  //     // Response to write
  //     begin
  //       @(posedge aclk);
  //       s_axi_bready <= 1'b1;
  //       repeat (16) begin
  //         @(posedge aclk);
  //         if (s_axi_bvalid) begin
  //           bok = 1;
  //           s_axi_bready <= 1'b0;
  //           break;
  //         end
  //       end
  //     end

  //     // Response to wr_ack
  //     begin
  //       repeat (16) begin
  //         @(posedge aclk);
  //         if (ipif_req && ipif_req_is_wr) begin
  //           ipif_wr_ack <= 1'b1;
  //           ipif_wr_err <= 1'b0;
  //           wreqok = 1;
  //           break;
  //         end
  //       end
  //       @(posedge aclk);
  //       ipif_wr_ack <= 1'b0;
  //       ipif_wr_err <= 1'b0;
  //     end

  //   join

  //   if (awok && wok && bok && wreqok) begin
  //     $info("%t, Test \"test_single_write_same_time\" success.", $time);
  //   end else begin
  //     $warning("%t, Test \"test_single_write_same_time\" fail.", $time());
  //   end
  // endtask


  initial begin
    $display("********************");
    $display("Simulation started");

    // Register the interface in the UVM configuration block
    uvm_resource_db#(virtual axi4l_ipif_if)::set(.scope("ifs"), .name("axi4l_ipif_if"), .val(vif));

    // Execute the test
    run_test();
  end

  final begin
    $display("********************");
    $display("%t, simulation ended.", $time());
  end


endmodule

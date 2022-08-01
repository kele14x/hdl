// File: tb_axi4l_ipif.sv
// Brief: Testbench for module axi4l_ipif
`timescale 1 ns / 100 ps
//
`default_nettype none

module tb_axi4l_ipif ();

  parameter int ADDR_WIDTH = 12;
  parameter int DATA_WIDTH = 32;

  // AXI i/f
  //---------
  logic                    aclk = 0;
  logic                    aresetn = 0;
  //
  logic [  ADDR_WIDTH-1:0] s_axi_awaddr = 0;
  logic [             2:0] s_axi_awprot = 0;
  logic                    s_axi_awvalid = 0;
  logic                    s_axi_awready = 0;
  //
  logic [  DATA_WIDTH-1:0] s_axi_wdata = 0;
  logic [             3:0] s_axi_wstrb = 0;
  logic                    s_axi_wvalid = 0;
  logic                    s_axi_wready = 0;
  //
  logic [             1:0] s_axi_bresp = 0;
  logic                    s_axi_bvalid = 0;
  logic                    s_axi_bready = 0;
  //
  logic [  ADDR_WIDTH-1:0] s_axi_araddr = 0;
  logic [             2:0] s_axi_arprot = 0;
  logic                    s_axi_arvalid = 0;
  logic                    s_axi_arready = 0;
  //
  logic [  DATA_WIDTH-1:0] s_axi_rdata = 0;
  logic [             1:0] s_axi_rresp = 0;
  logic                    s_axi_rvalid = 0;
  logic                    s_axi_rready = 0;

  // Write i/f
  //-----------
  logic                    ipif_req;
  logic                    ipif_req_is_wr;
  logic [  ADDR_WIDTH-3:0] ipif_addr;
  //
  logic [DATA_WIDTH/8-1:0] ipif_wr_be;
  logic [  DATA_WIDTH-1:0] ipif_wr_data;
  logic                    ipif_wr_ack;
  logic                    ipif_wr_err;

  logic [  DATA_WIDTH-1:0] ipif_rd_data;
  logic                    ipif_rd_ack;
  logic                    ipif_rd_err;


  // Stimulation
  //============

  always #5 aclk = ~aclk;

  //-------------------------------------------------------------------------
  // Task: reset_slave_and_interface
  // Brief: Reset the DUT and all input signal to DUT
  //-------------------------------------------------------------------------

  task automatic reset_slave_and_interface();
    @(posedge aclk);
    // AXI
    aresetn <= 0;
    s_axi_awaddr <= 0;
    s_axi_awprot <= 0;
    s_axi_awvalid <= 0;
    s_axi_wdata <= 0;
    s_axi_wstrb <= 0;
    s_axi_wvalid <= 0;
    s_axi_bready <= 0;
    s_axi_araddr <= 0;
    s_axi_arprot <= 0;
    s_axi_arvalid <= 0;
    s_axi_rready <= 0;
    // WR
    ipif_wr_ack <= 0;
    ipif_wr_err <= 0;
    // RD
    ipif_rd_data <= 0;
    ipif_rd_ack <= 0;
    ipif_rd_err <= 0;
    repeat (16) @(posedge aclk);
    @(posedge aclk) aresetn <= 1;
    repeat (16) @(posedge aclk);
  endtask

  // Test cases

  //-------------------------------------------------------------------------
  // Task: test_single_write_same_time
  // Brief: Test if DUT can accept signal AXI write. Only write response is
  //        checked. No write effect is checked.
  //-------------------------------------------------------------------------

  task automatic test_single_write_same_time();
    logic awok, wok, bok, wreqok;
    awok = 0;
    wok = 0;
    bok = 0;
    wreqok = 0;
    reset_slave_and_interface();

    fork
      // Set write address
      begin
        @(posedge aclk);
        s_axi_awaddr  <= $urandom();
        s_axi_awvalid <= 1'b1;
        repeat (16) begin
          @(posedge aclk);
          if (s_axi_awready) begin
            awok = 1;
            s_axi_awvalid <= 1'b0;
            break;
          end
        end
      end

      // Set write data
      begin
        @(posedge aclk);
        s_axi_wdata  <= $urandom();
        s_axi_wstrb  <= $urandom();
        s_axi_wvalid <= 1'b1;
        repeat (16) begin
          @(posedge aclk);
          if (s_axi_wready) begin
            wok = 1;
            s_axi_wvalid <= 1'b0;
            break;
          end
        end
      end

      // Response to write
      begin
        @(posedge aclk);
        s_axi_bready <= 1'b1;
        repeat (16) begin
          @(posedge aclk);
          if (s_axi_bvalid) begin
            bok = 1;
            s_axi_bready <= 1'b0;
            break;
          end
        end
      end

      // Response to wr_ack
      begin
        repeat (16) begin
          @(posedge aclk);
          if (ipif_req && ipif_req_is_wr) begin
            ipif_wr_ack <= 1'b1;
            ipif_wr_err <= 1'b0;
            wreqok = 1;
            break;
          end
        end
        @(posedge aclk);
        ipif_wr_ack <= 1'b0;
        ipif_wr_err <= 1'b0;
      end

    join

    if (awok && wok && bok && wreqok) begin
      $info("%t, Test \"test_single_write_same_time\" success.", $time);
    end else begin
      $warning("%t, Test \"test_single_write_same_time\" fail.", $time());
    end
  endtask


  initial begin
    $display("%t, simulation ends.", $time());
    #1000;
    test_single_write_same_time();
    #1000;
    $finish();
  end

  final begin
    $display("%t, simulation ends.", $time());
  end

  axi4l_ipif #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) UUT (
      .*
  );

endmodule

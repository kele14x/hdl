`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_rts2;

  // Parameters
  localparam integer ADDR_WIDTH = 40;

  // AXI4-Lite
  logic          s_axi_aclk;
  logic          s_axi_aresetn;
  //
  logic   [15:0] s_axi_awaddr;
  logic   [ 2:0] s_axi_awprot;
  logic          s_axi_awvalid;
  logic          s_axi_awready;
  //
  logic   [31:0] s_axi_wdata;
  logic   [ 3:0] s_axi_wstrb;
  logic          s_axi_wvalid;
  logic          s_axi_wready;
  //
  logic   [ 1:0] s_axi_bresp;
  logic          s_axi_bvalid;
  logic          s_axi_bready;
  //
  logic   [15:0] s_axi_araddr;
  logic   [ 2:0] s_axi_arprot;
  logic          s_axi_arvalid;
  logic          s_axi_arready;
  //
  logic   [31:0] s_axi_rdata;
  logic   [ 1:0] s_axi_rresp;
  logic          s_axi_rvalid;
  logic          s_axi_rready;

  // Timer Interface
  logic          clk;
  logic          rstn;
  //
  logic          rfs_in;

  // DDR DataMover Interface
  logic          ddr4_clk;
  logic          ddr4_rstn;
  //
  logic   [79:0] m_axis_s2mm_cmd_tdata;
  logic          m_axis_s2mm_cmd_tvalid;
  logic          m_axis_s2mm_cmd_tready;
  //
  logic   [79:0] m_axis_mm2s_cmd_tdata;
  logic          m_axis_mm2s_cmd_tvalid;
  logic          m_axis_mm2s_cmd_tready;
  //
  logic   [31:0] s_axis_s2mm_sts_tdata;
  logic   [ 3:0] s_axis_s2mm_sts_tkeep;
  logic          s_axis_s2mm_sts_tlast;
  logic          s_axis_s2mm_sts_tvalid;
  logic          s_axis_s2mm_sts_tready;
  //
  logic   [ 7:0] s_axis_mm2s_sts_tdata;
  logic   [ 0:0] s_axis_mm2s_sts_tkeep;
  logic          s_axis_mm2s_sts_tlast;
  logic          s_axis_mm2s_sts_tvalid;
  logic          s_axis_mm2s_sts_tready;
  //
  logic          mm2s_err;
  logic          s2mm_err;

  // S2MM AXIS
  logic   [63:0] m_axis_s2mm_tdata;
  logic   [ 7:0] m_axis_s2mm_tkeep;
  logic          m_axis_s2mm_tlast;
  logic          m_axis_s2mm_tvalid;
  logic          m_axis_s2mm_tready;

  // MM2S AXIS
  logic   [63:0] s_axis_mm2s_tdata;
  logic   [ 7:0] s_axis_mm2s_tkeep;
  logic          s_axis_mm2s_tlast;
  logic          s_axis_mm2s_tvalid;
  logic          s_axis_mm2s_tready;

  // Ethernet Interface
  logic   [63:0] m_tx_axis_tdata;
  logic   [ 7:0] m_tx_axis_tkeep;
  logic          m_tx_axis_tlast;
  logic          m_tx_axis_tvalid;
  //
  logic   [63:0] s_rx_axis_tdata;
  logic   [ 7:0] s_rx_axis_tkeep;
  logic          s_rx_axis_tlast;
  logic          s_rx_axis_tvalid;

  integer        fin;

  `include "tb_axi4l.svh"

  // Clock & Reset

  initial begin
    s_axi_aclk = 1'b0;
    forever begin
      #5 s_axi_aclk = ~s_axi_aclk;
    end
  end

  initial begin
    s_axi_aresetn = 1'b0;
    repeat (10) @(posedge s_axi_aclk);
    s_axi_aresetn <= 1'b1;
  end

  initial begin
    clk = 1'b0;
    forever begin
      #(1.25) clk = ~clk;
    end
  end

  initial begin
    rstn = 1'b0;
    repeat (10) @(posedge clk);
    rstn <= 1'b1;
  end

  initial begin
    ddr4_clk = 1'b0;
    forever begin
      #(1.667) ddr4_clk = ~ddr4_clk;
    end
  end

  initial begin
    ddr4_rstn = 1'b0;
    repeat (10) @(posedge ddr4_clk);
    ddr4_rstn <= 1'b1;
  end

  // Stimulus

  initial begin
    rfs_in = 1'b0;
    #1000;
    @(posedge clk) rfs_in <= 1'b1;
    @(posedge clk) rfs_in <= 1'b0;
  end

  // DataMover command / response
  initial begin
    automatic logic [63:0] data;
    automatic logic [ 7:0] keep;

    automatic logic [22:0] size;
    automatic logic        eof;
    automatic logic [39:0] offset;
    automatic logic [ 3:0] tag;

    // Reset interface signals

    s_axis_mm2s_tdata = '0;
    s_axis_mm2s_tkeep = '0;
    s_axis_mm2s_tlast = 1'b0;
    s_axis_mm2s_tvalid = 1'b0;

    s_axis_mm2s_sts_tdata = '0;
    s_axis_mm2s_sts_tkeep = '0;
    s_axis_mm2s_sts_tlast = 1'b0;
    s_axis_mm2s_sts_tvalid = 1'b0;

    m_axis_mm2s_cmd_tready = 1'b1;

    mm2s_err = 1'b0;

    // Try to open file
    fin = $fopen("nr_fdd_4ant_20m_2cc_4ant_10m_1cc_15k_2.pcap", "rb");
    if (fin == 0) begin
      $error("Failed to open file");
      $finish;
    end

    forever begin
      data = 0;
      keep = 0;

      // Wait CMD
      forever begin
        @(posedge ddr4_clk);
        if (m_axis_mm2s_cmd_tvalid) begin
          size   = m_axis_mm2s_cmd_tdata[22:0];
          eof    = m_axis_mm2s_cmd_tdata[30];
          offset = m_axis_mm2s_cmd_tdata[ADDR_WIDTH+31:32];
          tag    = m_axis_mm2s_cmd_tdata[ADDR_WIDTH+35:ADDR_WIDTH+32];
          $display("Get CMD: offset: %x, size: %d, tag: %d, eof: %d", offset, size, tag, eof);
          break;
        end
      end

      // Seek to offset
      $fseek(fin, offset, 0);

      // Read data from file
      while (size > 0) begin
        // Try to get 8-byte data from file, if reach EOF, set done to 1
        data = '0;
        keep = '0;
        for (int i = 0; i < 8 && size > 0; i++) begin
          if (!$feof(fin)) begin
            data[i*8+7-:8] = $fgetc(fin);
            keep[i] = 1'b1;
            size--;
          end else begin
            size = 0;
            break;
          end
        end

        // Send data to DUT
        s_axis_mm2s_tdata  <= data;
        s_axis_mm2s_tkeep  <= keep;
        s_axis_mm2s_tlast  <= eof && (size == 0);
        s_axis_mm2s_tvalid <= 1'b1;

        // Wait for DUT to process data
        forever begin
          @(posedge ddr4_clk);
          if (s_axis_mm2s_tready) begin
            break;
          end
        end
        s_axis_mm2s_tvalid <= 1'b0;
      end

      // Set sts
      @(posedge ddr4_clk);
      s_axis_mm2s_sts_tdata  = {4'h8, tag};
      s_axis_mm2s_sts_tkeep  = 1'b1;
      s_axis_mm2s_sts_tlast  = eof;
      s_axis_mm2s_sts_tvalid = 1'b1;
      forever begin
        @(posedge ddr4_clk);
        if (s_axis_mm2s_sts_tready) begin
          break;
        end
      end
      s_axis_mm2s_sts_tvalid <= 1'b0;

      // Done for one packet
      $display("Done for one packet: offset: %x, size: %d, tag: %d, eof: %d", offset, size, tag, eof);
    end
  end

  // Test

  initial begin
    automatic logic [31:0] data;
    $display("*** Test started ***");
    axi_reset();

    wait (s_axi_aresetn);
    axi_read('h0, data);
    assert (data == 32'h20250513)
    else $error("Check version register failed");

    axi_write('h4, 32'h12345678);
    axi_read('h4, data);
    assert (data == 32'h12345678)
    else $error("Check scratchpad register 0 failed");

    axi_write('h8, 32'h5A5A5A5A);
    axi_read('h8, data);
    assert (data == 32'h5A5A5A5A)
    else $error("Check scratchpad register 1 failed");

    $display("AXI register test passed");

    // addr_offset
    axi_write('h104, 32'd0);
    // addr_size
    axi_write('h114, 32'd4_248_504);
    // enable
    axi_write('h100, 32'b1);

    #30000000;
    $finish;
  end

  final begin
    $fclose(fin);
    $display("*** Test finished ***");
  end

  // DUT

  rts2_wrapper DUT (.*);

endmodule

`default_nettype wire

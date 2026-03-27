`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_lowphy ();

  // Signals

  // Clocks

  logic         internal_bus_clk;

  logic         defm_reset;
  logic         fram_reset;

  // interrupt pin

  logic         interrupt;

  logic         tx0_eth_port_clk;

  logic [ 63:0] m0_message_axis_tdata;
  logic [  7:0] m0_message_axis_tkeep;
  logic         m0_message_axis_tlast;
  logic         m0_message_axis_tvalid;
  logic         m0_message_axis_tready;

  logic [ 79:0] m0_message_ts_tdata;
  logic         m0_message_ts_tvalid;

  logic [ 63:0] m0_eth_axis_tdata;
  logic [  7:0] m0_eth_axis_tkeep;
  logic         m0_eth_axis_tlast;
  logic         m0_eth_axis_tvalid;
  logic         m0_eth_axis_tready;

  logic [ 63:0] s0_eth_axis_tdata;
  logic [  7:0] s0_eth_axis_tkeep;
  logic         s0_eth_axis_tlast;
  logic         s0_eth_axis_tvalid;
  logic         s0_eth_axis_tuser;

  logic         s0_eth_mac_bad_fcs;
  logic [ 79:0] s0_eth_mac_tstamp_out;
  logic         s0_eth_mac_tstamp_valid;

  // AXI-Lite Control/Status

  logic         s_axi_aclk;
  logic         s_axi_aresetn;

  logic [ 15:0] S00_AXI_awaddr;
  logic         S00_AXI_awvalid;
  logic         S00_AXI_awready;
  //
  logic [ 31:0] S00_AXI_wdata;
  logic [  3:0] S00_AXI_wstrb;
  logic         S00_AXI_wvalid;
  logic         S00_AXI_wready;
  //
  logic [  1:0] S00_AXI_bresp;
  logic         S00_AXI_bvalid;
  logic         S00_AXI_bready;
  //
  logic [ 15:0] S00_AXI_araddr;
  logic         S00_AXI_arvalid;
  logic         S00_AXI_arready;
  //
  logic [ 31:0] S00_AXI_rdata;
  logic [  1:0] S00_AXI_rresp;
  logic         S00_AXI_rvalid;
  logic         S00_AXI_rready;

  logic         clk;
  logic         rst;
  //
  logic [383:0] M_DL_AXIS_tdata;
  logic         M_DL_AXIS_tuser;
  logic         M_DL_AXIS_tlast;
  logic         M_DL_AXIS_tvalid;
  logic         M_DL_AXIS_tready;
  //
  logic [383:0] S_UL_AXIS_tdata;
  logic         S_UL_AXIS_tuser;
  logic         S_UL_AXIS_tlast;
  logic         S_UL_AXIS_tvalid;
  logic         S_UL_AXIS_tready;

  // Helers

  // Register check macro
  `define CHECK_REG(ADDR, EXP_VAL, MSG) \
    begin \
      logic [31:0] read_data; \
      axi_read(ADDR, read_data); \
      assert (read_data == EXP_VAL) else begin \
        $error("Failed to check %s: got %0h, expected %0h", MSG, read_data, EXP_VAL); \
        #1 $finish; \
      end \
    end

  function static void axi_reset();
    S00_AXI_awaddr  <= 0;
    S00_AXI_awvalid <= 0;
    S00_AXI_wdata   <= 0;
    S00_AXI_wstrb   <= 0;
    S00_AXI_wvalid  <= 0;
    S00_AXI_bready  <= 0;
    S00_AXI_araddr  <= 0;
    S00_AXI_arvalid <= 0;
    S00_AXI_rready  <= 0;
  endfunction

  // AXI read/write helper tasks
  task static axi_write(input logic [31:0] addr, input logic [31:0] data);
    @(posedge s_axi_aclk);
    fork
      begin
        // Write address
        S00_AXI_awaddr  <= addr;
        S00_AXI_awvalid <= 1'b1;
        forever begin
          @(posedge s_axi_aclk);
          if (S00_AXI_awready) break;
        end
        S00_AXI_awvalid <= 1'b0;
      end

      begin
        // Write data
        S00_AXI_wdata  <= data;
        S00_AXI_wstrb  <= 4'hF;
        S00_AXI_wvalid <= 1'b1;
        forever begin
          @(posedge s_axi_aclk);
          if (S00_AXI_wready) break;
        end
        S00_AXI_wvalid <= 1'b0;
      end

      begin
        // Write response
        S00_AXI_bready <= 1'b1;
        forever begin
          @(posedge s_axi_aclk);
          if (S00_AXI_bvalid) break;
        end
        S00_AXI_bready <= 1'b0;
      end
    join
    $display("INFO: ORAN AXI write: %08x -> %08x", addr, data);
  endtask

  task static axi_read(input logic [31:0] addr, output logic [31:0] data);
    @(posedge s_axi_aclk);
    fork
      begin
        // Read address
        S00_AXI_araddr  <= addr;
        S00_AXI_arvalid <= 1'b1;
        forever begin
          @(posedge s_axi_aclk);
          if (S00_AXI_arready) break;
        end
        S00_AXI_arvalid <= 1'b0;
      end

      begin
        // Read data
        S00_AXI_rready <= 1'b1;
        forever begin
          @(posedge s_axi_aclk);
          if (S00_AXI_rvalid) break;
        end
        data = S00_AXI_rdata;
        S00_AXI_rready <= 1'b0;
      end
    join
    $display("INFO: ORAN AXI read: %08x -> %08x", addr, data);
  endtask

  // Clock and reset generation

  // s_axi_aclk @ 100 MHz
  initial begin
    s_axi_aclk = 0;
    forever #5 s_axi_aclk = ~s_axi_aclk;
  end

  initial begin
    s_axi_aresetn = 0;
    #100 s_axi_aresetn = 1;
  end

  // internal_bus_clk @ 400 MHz
  initial begin
    internal_bus_clk = 0;
    forever #1.25 internal_bus_clk = ~internal_bus_clk;
  end

  initial begin
    defm_reset = 1;
    #100 defm_reset = 0;
  end

  initial begin
    fram_reset = 1;
    #100 fram_reset = 0;
  end

  // tx0_eth_port_clk @ 312.5 MHz
  initial begin
    tx0_eth_port_clk = 0;
    forever #1.6 tx0_eth_port_clk = ~tx0_eth_port_clk;
  end

  // clk @ 491.52 MHz
  initial begin
    clk = 0;
    forever #1.017 clk = ~clk;
  end

  initial begin
    rst = 1;
    #100 rst = 0;
  end

  // Stimulus

  // Conenct framer/deframer reset to ORAN IP user I/O

  assign m0_eth_axis_tready = 1'b1;

  assign m0_message_axis_tready = 1'b1;

  // Ethernet driver
  initial begin
    s0_eth_axis_tdata = 0;
    s0_eth_axis_tkeep = 0;
    s0_eth_axis_tvalid = 0;
    s0_eth_axis_tlast = 0;
    s0_eth_axis_tuser = 0;
    s0_eth_mac_bad_fcs = 0;
    s0_eth_mac_tstamp_out = 0;
    s0_eth_mac_tstamp_valid = 0;
  end

  // Configuration
  initial begin
    logic [31:0] data;
    $display("*** Simulation start");
    // Reset
    axi_reset();
    wait (s_axi_aresetn);

    // Perform register checks using the macro
    `CHECK_REG('h0000, 'h03010000, "ORAN IP cfg_version")
    `CHECK_REG('h0004, 'h23100607, "ORAN IP internal_revision")

    // Reset framer and deframer
    axi_write('h0200, 'h00000001);  // fram_reset
    axi_write('h0600, 'h00000001);  // defm_reset

    // Per CC config
    for (int cc = 0; cc < 3; cc++) begin
      axi_write('hE100 + cc * 'h70, 'h00000111);  // oran_cc_config
    end
    axi_write('hE004, 'h00000007);  // cc_enable
    axi_write('hE000, 'h00000007);  // cc_reload

    // Deassert reset
    axi_write('h0200, 'h00000000);  // fram_reset
    axi_write('h0600, 'h00000000);  // defm_reset

    // Poll for ready
    data = 0;
    forever begin
      axi_read('h000C, data);
      if (data[16]) break;
      #1000;
    end
    $display("INFO: ORAN IP fram_reset is ready");
    forever begin
      axi_read('h000C, data);
      if (data[20]) break;
      #1000;
    end
    $display("INFO: ORAN IP defm_reset is ready");

    #10000;
    $finish;
  end

  final begin
    $display("*** Simulation ends");
  end

  // Main

  design_1 DUT (
      .tx0_eth_port_clk       (tx0_eth_port_clk),
      //
      .m0_eth_axis_tdata      (m0_eth_axis_tdata),
      .m0_eth_axis_tkeep      (m0_eth_axis_tkeep),
      .m0_eth_axis_tvalid     (m0_eth_axis_tvalid),
      .m0_eth_axis_tlast      (m0_eth_axis_tlast),
      .m0_eth_axis_tready     (m0_eth_axis_tready),
      //
      .s0_eth_axis_tdata      (s0_eth_axis_tdata),
      .s0_eth_axis_tkeep      (s0_eth_axis_tkeep),
      .s0_eth_axis_tvalid     (s0_eth_axis_tvalid),
      .s0_eth_axis_tlast      (s0_eth_axis_tlast),
      .s0_eth_axis_tuser      (s0_eth_axis_tuser),
      .s0_eth_mac_bad_fcs     (s0_eth_mac_bad_fcs),
      .s0_eth_mac_tstamp_out  (s0_eth_mac_tstamp_out),
      .s0_eth_mac_tstamp_valid(s0_eth_mac_tstamp_valid),
      //
      .m0_message_axis_tdata  (m0_message_axis_tdata),
      .m0_message_axis_tkeep  (m0_message_axis_tkeep),
      .m0_message_axis_tvalid (m0_message_axis_tvalid),
      .m0_message_axis_tlast  (m0_message_axis_tlast),
      .m0_message_axis_tready (m0_message_axis_tready),
      .m0_message_ts_tdata    (m0_message_ts_tdata),
      .m0_message_ts_tvalid   (m0_message_ts_tvalid),
      //   Clocks
      .defm_reset             (defm_reset),
      .fram_reset             (fram_reset),
      //
      .internal_bus_clk       (internal_bus_clk),
      // interrupt pin
      .interrupt              (interrupt),
      // AXI-Lite Control/Status
      .s_axi_aclk             (s_axi_aclk),
      .s_axi_aresetn          (s_axi_aresetn),
      //
      .S00_AXI_awaddr         (S00_AXI_awaddr),
      .S00_AXI_awvalid        (S00_AXI_awvalid),
      .S00_AXI_awready        (S00_AXI_awready),
      //
      .S00_AXI_wdata          (S00_AXI_wdata),
      .S00_AXI_wstrb          (S00_AXI_wstrb),
      .S00_AXI_wvalid         (S00_AXI_wvalid),
      .S00_AXI_wready         (S00_AXI_wready),
      //
      .S00_AXI_bresp          (S00_AXI_bresp),
      .S00_AXI_bvalid         (S00_AXI_bvalid),
      .S00_AXI_bready         (S00_AXI_bready),
      //
      .S00_AXI_araddr         (S00_AXI_araddr),
      .S00_AXI_arvalid        (S00_AXI_arvalid),
      .S00_AXI_arready        (S00_AXI_arready),
      //
      .S00_AXI_rdata          (S00_AXI_rdata),
      .S00_AXI_rresp          (S00_AXI_rresp),
      .S00_AXI_rvalid         (S00_AXI_rvalid),
      .S00_AXI_rready         (S00_AXI_rready),
      // Radio I/F
      //----------
      .clk                    (clk),
      .rst                    (rst),
      //
      .M_DL_AXIS_tdata        (M_DL_AXIS_tdata),
      .M_DL_AXIS_tuser        (M_DL_AXIS_tuser),
      .M_DL_AXIS_tlast        (M_DL_AXIS_tlast),
      .M_DL_AXIS_tvalid       (M_DL_AXIS_tvalid),
      .M_DL_AXIS_tready       (M_DL_AXIS_tready),
      //
      .S_UL_AXIS_tdata        (S_UL_AXIS_tdata),
      .S_UL_AXIS_tuser        (S_UL_AXIS_tuser),
      .S_UL_AXIS_tlast        (S_UL_AXIS_tlast),
      .S_UL_AXIS_tvalid       (S_UL_AXIS_tvalid),
      .S_UL_AXIS_tready       (S_UL_AXIS_tready)
  );

endmodule

`default_nettype wire

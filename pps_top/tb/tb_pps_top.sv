`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_pps_top;

  parameter int FREQUENCY = 1;

  // AXI

  logic        s_axi_aclk;
  logic        s_axi_aresetn;

  logic [31:0] s_axi_awaddr;
  logic [ 2:0] s_axi_awprot;
  logic        s_axi_awvalid;
  logic        s_axi_awready;

  logic [31:0] s_axi_wdata;
  logic [ 3:0] s_axi_wstrb;
  logic        s_axi_wvalid;
  logic        s_axi_wready;

  logic [ 1:0] s_axi_bresp;
  logic        s_axi_bvalid;
  logic        s_axi_bready;

  logic [31:0] s_axi_araddr;
  logic [ 2:0] s_axi_arprot;
  logic        s_axi_arvalid;
  logic        s_axi_arready;

  logic [31:0] s_axi_rdata;
  logic [ 1:0] s_axi_rresp;
  logic        s_axi_rvalid;
  logic        s_axi_rready;

  // PAD

  logic        pps_in;
  logic        pps_out_pad;

  // Timer

  logic        clk;
  logic        rst;

  logic [47:0] sys_timer_s;
  logic [31:0] sys_timer_ns;

  logic        pps_out;

  logic        raw_10ms_strobe;
  logic        dl_10ms_strobe;
  logic        ul_10ms_strobe;
  logic        air_intface_10ms;

  logic        start_of_frame;
  logic        start_of_symbol;
  logic [31:0] start_of_symbol_frac;

  // Ethernet

  logic        eth_clk;
  logic        eth_clk2x;
  logic        eth_rst;

  logic [47:0] timer_s;
  logic [31:0] timer_ns;

  logic [31:0] ts_t1;
  logic [31:0] ts_t2;
  logic        ts_valid;

  // Helper functions and tasks

  // Reset AXI interface
  task static axi_reset();
    s_axi_awaddr  <= '0;
    s_axi_awprot  <= '0;
    s_axi_awvalid <= '0;
    //
    s_axi_wdata   <= '0;
    s_axi_wstrb   <= '0;
    s_axi_wvalid  <= '0;
    //
    s_axi_bready  <= '0;
    //
    s_axi_araddr  <= '0;
    s_axi_arprot  <= '0;
    s_axi_arvalid <= '0;
    //
    s_axi_rready  <= '0;
  endtask

  // Write AXI register
  task static axi_write(input bit [31:0] addr, input bit [31:0] data);
    fork
      begin : p_aw
        s_axi_awaddr  <= addr;
        s_axi_awprot  <= '0;
        s_axi_awvalid <= 1'b1;
        forever begin
          @(posedge s_axi_aclk);
          if (s_axi_awready) break;
        end
        s_axi_awvalid <= 1'b0;
      end

      begin : p_w
        s_axi_wdata  <= data;
        s_axi_wstrb  <= '1;
        s_axi_wvalid <= 1'b1;
        forever begin
          @(posedge s_axi_aclk);
          if (s_axi_wready) break;
        end
        s_axi_wvalid <= 1'b0;
      end

      begin : p_b
        s_axi_bready <= 1'b1;
        forever begin
          @(posedge s_axi_aclk);
          if (s_axi_bvalid) begin
            if (s_axi_bresp != '0)
              $warning("AXI write error (addr = %x, data = %x, resp = %x)", addr, data, s_axi_bresp);
            break;
          end
        end
        s_axi_bready <= 1'b0;
      end
    join
    // $display("axi write: addr = %x, data = %x", addr, data);
  endtask

  // Read AXI register
  task static axi_read(input bit [31:0] addr, output bit [31:0] data);
    fork
      begin : p_ar
        s_axi_araddr  <= addr;
        s_axi_arprot  <= '0;
        s_axi_arvalid <= 1'b1;
        forever begin
          @(posedge s_axi_aclk);
          if (s_axi_arready) break;
        end
        s_axi_arvalid <= 1'b0;
      end

      begin : p_r
        s_axi_rready <= 1'b1;
        forever begin
          @(posedge s_axi_aclk);
          if (s_axi_rvalid) begin
            data = s_axi_rdata;
            if (s_axi_rresp != '0)
              $warning("AXI read error (addr = %x, data = %x, resp = %x)", addr, data, s_axi_rresp);
            break;
          end
        end
        s_axi_rready <= 1'b0;
      end
    join
    // $display("axi read: addr = %x, data = %x", addr, data);
  endtask

  // Get time
  task static get_time(output bit[47:0] sec, output bit[31:0] nsec);
    logic [31:0] data;
    // Take a snap
    axi_write(32'h2C, 32'd1);
    axi_write(32'h2C, 32'd0);
    @(posedge s_axi_aclk);
    @(posedge s_axi_aclk);
    // Second
    axi_read(32'h20, data);
    sec[47:32] = data[15:0];
    axi_read(32'h24, data);
    sec[31:0] = data;
    // Nanosecond
    axi_read(32'h28, nsec);
  endtask

  // Set time
  task static set_time(input bit [47:0] sec, input bit [31:0] nsec);
    // Second
    axi_write(32'h30, sec[47:32]);
    axi_write(32'h34, sec[31:0]);
    // Nanosecond
    axi_write(32'h38, nsec);
    // Commit
    axi_write(32'h3C, 32'd1);
    axi_write(32'h3C, 32'd0);
  endtask

  // Clock & Reset
  //--------------

  initial begin
    s_axi_aclk = 0;
    forever begin
      #5 s_axi_aclk = ~s_axi_aclk;
    end
  end

  initial begin
    s_axi_aresetn = 0;
    #100;
    s_axi_aresetn = 1;
  end

  initial begin
    clk = 0;
    forever begin
      #(4.069) clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    #1000;
    rst = 0;
  end


  // Stimulation
  //------------

  initial begin
    logic [47:0] sec;
    logic [31:0] nsec;

    $display("*** Simulation start");
    axi_reset();
    wait(s_axi_aresetn);
    @(posedge s_axi_aclk);

    // Configuration

    // Set frequency control word
    // dec2hex(round(2^32*100e-6), 8)
    axi_write(32'h18, 32'h0000C000);
    // axi_write(32'h18, 32'h00000000);
    // axi_write(32'h18, 32'hFFF97247);

    // Soft reset
    axi_write(32'h04, 32'd1);
    axi_write(32'h04, 32'd0);

    #1000;
    @(posedge s_axi_aclk);

    // Get time
    get_time(sec, nsec);
    $display("Get time: sec = %d, nsec = %d\n", sec, nsec);

    sec = 100;
    nsec = 009999000;
    set_time(sec, nsec);
    get_time(sec, nsec);
    $display("Get time: sec = %d, nsec = %d\n", sec, nsec);

    #(11*1000*1000);

    $finish();
  end

  initial begin
    forever begin
      @(posedge clk);
      if (start_of_symbol) begin
        $display("%09x", start_of_symbol_frac);
      end
    end
  end

  final begin
    $display("** Simulation end");
  end

  pps_top #(.FREQUENCY(FREQUENCY)) DUT (.*);

endmodule

`default_nettype wire

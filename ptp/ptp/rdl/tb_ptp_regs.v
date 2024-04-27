// File: tb_ptp_regs.v
// Breif: Testbench for module ptp.
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_ptp_regs;

    reg        s_axi_aclk;
    reg        s_axi_aresetn;
    //
    reg  [ 5:0] s_axi_awaddr;
    reg  [ 2:0] s_axi_awprot;
    reg         s_axi_awvalid;
    wire        s_axi_awready;
    //
    reg  [31:0] s_axi_wdata;
    reg  [ 3:0] s_axi_wstrb;
    reg         s_axi_wvalid;
    wire        s_axi_wready;
    //
    wire [ 1:0] s_axi_bresp;
    wire        s_axi_bvalid;
    reg         s_axi_bready;
    //
    reg  [ 5:0] s_axi_araddr;
    reg  [ 2:0] s_axi_arprot;
    reg         s_axi_arvalid;
    wire        s_axi_arready;
    //
    wire [31:0] s_axi_rdata;
    wire [ 1:0] s_axi_rresp;
    wire        s_axi_rvalid;
    reg         s_axi_rready;
    // ctrl.rst
    wire [     0:0] ctrl_rst_out;
    // ctrl.enable
    wire [     0:0] ctrl_enable_out;
    // mode.slave
    wire [     0:0] mode_slave_out;
    // rtc_offset_set.set
    wire [     0:0] rtc_offset_set_set_out;
    // rtc_offset_ns.val
    wire [    31:0] rtc_offset_ns_val_out;
    // rtc_offset_s_l.val
    wire [    31:0] rtc_offset_s_l_val_out;
    // rtc_offset_s_h.val
    wire [    15:0] rtc_offset_s_h_val_out;
    // rtc_offset_get.get
    wire [     0:0] rtc_offset_get_get_out;
    // rtc_ns.val
    reg  [    31:0] rtc_ns_val_in;
    // rtc_s_l.val
    reg  [    31:0] rtc_s_l_val_in;
    // rtc_s_h.val
    reg  [    15:0] rtc_s_h_val_in;

    task axi_reset();
        begin
            @(posedge s_axi_aclk);
            s_axi_awaddr  <= 0;
            s_axi_awprot  <= 0;
            s_axi_awvalid <= 0;

            s_axi_wdata   <= 0;
            s_axi_wstrb   <= 0;
            s_axi_wvalid  <= 0;

            s_axi_bready  <= 0;

            s_axi_araddr  <= 0;
            s_axi_arprot  <= 0;
            s_axi_arvalid <= 0;

            s_axi_rready  <= 0;
        end
    endtask

    task axi_write(input  reg [ 5:0] addr,
                   input  reg [31:0] data,
                   output reg [ 1:0] resp);
        begin
            fork
                begin
                  s_axi_awaddr  <= addr;
                  s_axi_awprot  <= 0;
                  s_axi_awvalid <= 1;
                  @(posedge s_axi_aclk);
                  while (s_axi_awready == 0) begin
                      @(posedge s_axi_aclk);
                  end
                  s_axi_awvalid <= 0;
                end

                begin
                    s_axi_wdata  <= data;
                    s_axi_wstrb  <= 4'b1111;
                    s_axi_wvalid <= 1;
                    @(posedge s_axi_aclk);
                    while (s_axi_wready == 0) begin
                        @(posedge s_axi_aclk);
                    end
                    s_axi_wvalid <= 0;
                end

                begin
                    s_axi_bready <= 1;
                    @(posedge s_axi_aclk);
                    while (s_axi_bvalid == 0) begin
                        @(posedge s_axi_aclk);
                    end
                    resp = s_axi_bresp;
                    s_axi_bready <= 0;
                end
            join
            $display("Write: addr = %x, data = %x, resp = %x\n", addr, data, resp);
        end
    endtask

    task axi_read(input  reg [ 5:0] addr,
                  output reg [31:0] data,
                  output reg [ 1:0] resp);
        begin
            fork
                begin
                    s_axi_araddr  <= addr;
                    s_axi_arprot  <= 0;
                    s_axi_arvalid <= 1;
                    @(posedge s_axi_aclk);
                    while (s_axi_arready == 0) begin
                        @(posedge s_axi_aclk);
                    end
                    s_axi_arvalid <= 0;
                end

                begin
                    s_axi_rready <= 1;
                    @(posedge s_axi_aclk);
                    while (s_axi_rvalid == 0) begin
                        @(posedge s_axi_aclk);
                    end
                    data = s_axi_rdata;
                    resp = s_axi_rresp;
                    s_axi_rready <= 0;
                end
            join
            $display("Read: addr = %x, data = %x, resp = %x\n", addr, data, resp);
        end
    endtask

    ptp_regs DUT (
        .s_axi_aclk                              (s_axi_aclk),
        .s_axi_aresetn                           (s_axi_aresetn),
        //
        .s_axi_awaddr                            (s_axi_awaddr),
        .s_axi_awprot                            (s_axi_awprot),
        .s_axi_awvalid                           (s_axi_awvalid),
        .s_axi_awready                           (s_axi_awready),
        //
        .s_axi_wdata                             (s_axi_wdata),
        .s_axi_wstrb                             (s_axi_wstrb),
        .s_axi_wvalid                            (s_axi_wvalid),
        .s_axi_wready                            (s_axi_wready),
        //
        .s_axi_bresp                             (s_axi_bresp),
        .s_axi_bvalid                            (s_axi_bvalid),
        .s_axi_bready                            (s_axi_bready),
        //
        .s_axi_araddr                            (s_axi_araddr),
        .s_axi_arprot                            (s_axi_arprot),
        .s_axi_arvalid                           (s_axi_arvalid),
        .s_axi_arready                           (s_axi_arready),
        //
        .s_axi_rdata                             (s_axi_rdata),
        .s_axi_rresp                             (s_axi_rresp),
        .s_axi_rvalid                            (s_axi_rvalid),
        .s_axi_rready                            (s_axi_rready),
        // ctrl.rst,
        .ctrl_rst_out                            (ctrl_rst_out),
        // ctrl.enable,
        .ctrl_enable_out                         (ctrl_enable_out),
        // mode.slave,
        .mode_slave_out                          (mode_slave_out),
        // rtc_offset_set.set,
        .rtc_offset_set_set_out                  (rtc_offset_set_set_out),
        // rtc_offset_ns.val,
        .rtc_offset_ns_val_out                   (rtc_offset_ns_val_out),
        // rtc_offset_s_l.val,
        .rtc_offset_s_l_val_out                  (rtc_offset_s_l_val_out),
        // rtc_offset_s_h.val,
        .rtc_offset_s_h_val_out                  (rtc_offset_s_h_val_out),
        // rtc_offset_get.get,
        .rtc_offset_get_get_out                  (rtc_offset_get_get_out),
        // rtc_ns.val,
        .rtc_ns_val_in                           (rtc_ns_val_in),
        // rtc_s_l.val,
        .rtc_s_l_val_in                          (rtc_s_l_val_in),
        // rtc_s_h.val,
        .rtc_s_h_val_in                          (rtc_s_h_val_in)
    );


    // Stimulation
    //------------

    initial begin
        s_axi_aclk = 0;
        forever begin
            #5 s_axi_aclk = ~s_axi_aclk;
        end
    end

    initial begin
        s_axi_aresetn = 0;
        #100 s_axi_aresetn = 1;
    end

    initial begin : p_stimu
        reg [ 5:0] addr;
        reg [31:0] data;
        reg [ 1:0] resp;
        integer i;

        // Wait reset done
        axi_reset();
        wait(s_axi_aresetn);

        // Write / read test
        @(posedge s_axi_aclk);
        // ctrl.rst
        addr = 'h0;
        axi_read(addr, data, resp);
        data = data ^ ({ 1 { 1'b1 } } << 0);
        axi_write(addr, data, resp);
        // ctrl.enable
        addr = 'h0;
        axi_read(addr, data, resp);
        data = data ^ ({ 1 { 1'b1 } } << 8);
        axi_write(addr, data, resp);
        // mode.slave
        addr = 'h4;
        axi_read(addr, data, resp);
        data = data ^ ({ 1 { 1'b1 } } << 0);
        axi_write(addr, data, resp);
        // rtc_offset_set.set
        addr = 'h20;
        axi_read(addr, data, resp);
        data = data ^ ({ 1 { 1'b1 } } << 0);
        axi_write(addr, data, resp);
        // rtc_offset_ns.val
        addr = 'h24;
        axi_read(addr, data, resp);
        data = data ^ ({ 32 { 1'b1 } } << 0);
        axi_write(addr, data, resp);
        // rtc_offset_s_l.val
        addr = 'h28;
        axi_read(addr, data, resp);
        data = data ^ ({ 32 { 1'b1 } } << 0);
        axi_write(addr, data, resp);
        // rtc_offset_s_h.val
        addr = 'h2c;
        axi_read(addr, data, resp);
        data = data ^ ({ 16 { 1'b1 } } << 0);
        axi_write(addr, data, resp);
        // rtc_offset_get.get
        addr = 'h30;
        axi_read(addr, data, resp);
        data = data ^ ({ 1 { 1'b1 } } << 0);
        axi_write(addr, data, resp);
        // rtc_ns.val
        addr = 'h34;
        axi_read(addr, data, resp);
        data = data ^ ({ 32 { 1'b1 } } << 0);
        axi_write(addr, data, resp);
        // rtc_s_l.val
        addr = 'h38;
        axi_read(addr, data, resp);
        data = data ^ ({ 32 { 1'b1 } } << 0);
        axi_write(addr, data, resp);
        // rtc_s_h.val
        addr = 'h3c;
        axi_read(addr, data, resp);
        data = data ^ ({ 16 { 1'b1 } } << 0);
        axi_write(addr, data, resp);
        #1000;
        $finish;
    end

endmodule

`default_nettype wire

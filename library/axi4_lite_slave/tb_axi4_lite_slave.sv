`timescale 1 ns / 1 ps

// Ignore the "not declared" error here, it should be fine when running simulation
import axi_vip_pkg::*;
import axi_vip_0_pkg::*;

module tb_axi4_lite_slave ();

    reg ACLK   ;
    reg ARESETn;
    //
    wire [31:0] AWADDR ;
    wire [ 2:0] AWPROT ;
    wire        AWVALID;
    wire        AWREADY;
    //
    wire [31:0] WDATA ;
    wire [ 3:0] WSTRB ;
    wire        WVALID;
    wire        WREADY;
    //
    wire [1:0] BRESP ;
    wire       BVALID;
    wire       BREADY;
    //
    wire [31:0] ARADDR ;
    wire [ 2:0] ARPROT ;
    wire        ARVALID;
    wire        ARREADY;
    //
    wire [31:0] RDATA ;
    wire [ 1:0] RRESP ;
    wire        RVALID;
    wire        RREADY;

    // Found path: tb_axi4_lite_slave.i_axi_vip_0.inst

    axi_vip_0_mst_t mst_agent;
    axi_transaction rd_trans;
    axi_transaction wr_trans;

    //
    task test_single_write();
        wr_trans = mst_agent.wr_driver.create_transaction("Write transaction");

        wr_trans.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
        assert(wr_trans.randomize());
        wr_trans.set_data_insertion_delay(0);
        wr_trans.set_addr_delay(0);

        mst_agent.wr_driver.send(wr_trans);
        mst_agent.wr_driver.wait_rsp(wr_trans);
        $display("%t, 1 write transaction done.", $time);
    endtask

    //
    task test_single_read();
        rd_trans = mst_agent.rd_driver.create_transaction("Read transaction");
        rd_trans.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
        assert(rd_trans.randomize());
        mst_agent.rd_driver.send(rd_trans);
        mst_agent.rd_driver.wait_rsp(rd_trans);
        $display("%t, 1 read transaction done.", $time);
    endtask


    initial begin
        $display("Simulation starts.");
        mst_agent = new("Maseter agent", tb_axi4_lite_slave.DUT.design_1_i.axi_vip_0.inst.IF);
        mst_agent.start_master();

        wait(ARESETn);
        #100;
        test_single_write();

        #1000;
        $finish();
    end

    final begin
        $display("Simulation ends.");
    end


    always begin
        ACLK = 0;
        #5 ACLK <= 1;
        #5;
    end

    initial begin
        ARESETn = 0;
        #200;
        ARESETn = 1;
    end

    design_1_wrapper DUT(ARESETn, ACLK);

//    axi_vip_0 i_axi_vip_0 (
//        .aclk         (ACLK   ),
//        .aresetn      (ARESETn),
//        //
//        .m_axi_awaddr (AWADDR ),
//        .m_axi_awprot (AWPROT ),
//        .m_axi_awvalid(AWVALID),
//        .m_axi_awready(AWREADY),
//        //
//        .m_axi_wdata  (WDATA  ),
//        .m_axi_wstrb  (WSTRB  ),
//        .m_axi_wvalid (WVALID ),
//        .m_axi_wready (WREADY ),
//        //
//        .m_axi_bresp  (BRESP  ),
//        .m_axi_bvalid (BVALID ),
//        .m_axi_bready (BREADY ),
//        //
//        .m_axi_araddr (ARADDR ),
//        .m_axi_arprot (ARPROT ),
//        .m_axi_arvalid(ARVALID),
//        .m_axi_arready(ARREADY),
//        //
//        .m_axi_rdata  (RDATA  ),
//        .m_axi_rresp  (RRESP  ),
//        .m_axi_rvalid (RVALID ),
//        .m_axi_rready (RREADY )
//    );

//    axi4_lite_slave i_axi4_lite_slave (
//        .ACLK   (ACLK   ),
//        .ARESETn(ARESETn),
//        //
//        .AWADDR (AWADDR ),
//        .AWPROT (AWPROT ),
//        .AWVALID(AWVALID),
//        .AWREADY(AWREADY),
//        //
//        .WDATA  (WDATA  ),
//        .WSTRB  (WSTRB  ),
//        .WVALID (WVALID ),
//        .WREADY (WREADY ),
//        //
//        .BRESP  (BRESP  ),
//        .BVALID (BVALID ),
//        .BREADY (BREADY ),
//        //
//        .ARADDR (ARADDR ),
//        .ARPROT (ARPROT ),
//        .ARVALID(ARVALID),
//        .ARREADY(ARREADY),
//        //
//        .RDATA  (RDATA  ),
//        .RRESP  (RRESP  ),
//        .RVALID (RVALID ),
//        .RREADY (RREADY )
//    );

endmodule

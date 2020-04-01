/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_axis_axi_master ();

    // Clock & Reset
    //=================
    logic aclk    = 0;
    logic aresetn = 0;

    // AXI4-Stream
    //------------
    logic [7:0] s_axis_tdata  = 0;
    logic       s_axis_tvalid = 0;
    logic       s_axis_tready    ;
    //
    logic [7:0] m_axis_tdata     ;
    logic       m_axis_tvalid    ;
    logic       m_axis_tready = 1;

    // AXI4-Lite
    //----------
    logic [31:0] m_axi_awaddr     ;
    logic [ 2:0] m_axi_awprot     ;
    logic        m_axi_awvalid    ;
    logic        m_axi_awready = 1;
    //
    logic [31:0] m_axi_wdata     ;
    logic [ 3:0] m_axi_wstrb     ;
    logic        m_axi_wvalid    ;
    logic        m_axi_wready = 1;
    //
    logic [1:0]  m_axi_bresp  = 0;
    logic        m_axi_bvalid = 0;
    logic        m_axi_bready    ;
    //
    logic [31:0] m_axi_araddr     ;
    logic [ 2:0] m_axi_arprot     ;
    logic        m_axi_arvalid    ;
    logic        m_axi_arready = 1;
    //
    logic [31:0] m_axi_rdata  = 0;
    logic [ 1:0] m_axi_rresp  = 0;
    logic        m_axi_rvalid = 0;
    logic        m_axi_rready    ;

    // tasks

    task axi_read(input [14:0] addr);
        reg [7:0] txd [0:6];
        begin
            txd[0] = {1'b0, addr[14:8]};
            txd[1] = addr[7:0];
            txd[2] = 8'h00;
            txd[3] = 8'h00;
            txd[4] = 8'h00;
            txd[5] = 8'h00;
            txd[6] = 8'h00;

            @(posedge aclk);
            for(int i = 0; i < 7; i++) begin
                s_axis_tdata  <= txd[i];
                s_axis_tvalid <= 1'b1;
                while(1) begin
                    @(posedge aclk);
                    if (s_axis_tready) break;
                end
                s_axis_tdata  <= 8'd0;
                s_axis_tvalid <= 1'b0;
                #80;
                @(posedge aclk);
            end
        end
    endtask

    task axi_write(input [14:0] addr, input [31:0] data);
        reg [7:0] txd [0:6];
        begin
            txd[0] = {1'b1, addr[14:8]};
            txd[1] = addr[7:0];
            txd[2] = 8'h00;
            txd[3] = data[31:24];
            txd[4] = data[23:16];
            txd[5] = data[15:8];
            txd[6] = data[7:0];

            @(posedge aclk);
            for(int i = 0; i < 7; i++) begin
                s_axis_tdata  <= txd[i];
                s_axis_tvalid <= 1'b1;
                while(1) begin
                    @(posedge aclk);
                    if (s_axis_tready) break;
                end
                s_axis_tdata  <= 8'd0;
                s_axis_tvalid <= 1'b0;
                #80;
                @(posedge aclk);
            end
        end
    endtask

    always #5 aclk = ~aclk;

    initial begin
        $display("Simulation starts");
        aresetn = 1'b0;
        #100;
        aresetn = 1'b1;
        #100;

        axi_write(15'h55, 32'hABCD0123);
        #100;
        axi_read(15'h55);

        #1000;
        $display("Simulation ends");
        $finish();
    end

    axis_axi_master DUT ( .* );


    blk_mem_gen_0 i_blk_mem_gen_0 (
        .s_aclk       (aclk         ),
        .s_aresetn    (aresetn      ),
        //
        .s_axi_awaddr (m_axi_awaddr ),
        .s_axi_awvalid(m_axi_awvalid),
        .s_axi_awready(m_axi_awready),
        //
        .s_axi_wdata  (m_axi_wdata  ),
        .s_axi_wstrb  (m_axi_wstrb  ),
        .s_axi_wvalid (m_axi_wvalid ),
        .s_axi_wready (m_axi_wready ),
        //
        .s_axi_bresp  (m_axi_bresp  ),
        .s_axi_bvalid (m_axi_bvalid ),
        .s_axi_bready (m_axi_bready ),
        //
        .s_axi_araddr (m_axi_araddr ),
        .s_axi_arvalid(m_axi_arvalid),
        .s_axi_arready(m_axi_arready),
        //
        .s_axi_rdata  (m_axi_rdata  ),
        .s_axi_rresp  (m_axi_rresp  ),
        .s_axi_rvalid (m_axi_rvalid ),
        .s_axi_rready (m_axi_rready ),
        //
        .rsta_busy    (             ),
        .rstb_busy    (             )
    );

endmodule

`default_nettype wire

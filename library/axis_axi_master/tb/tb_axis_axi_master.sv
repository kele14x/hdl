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
        reg [7:0] txd [0:5];
        begin
            txd[0] = {1'b0, addr[14:8]};
            txd[1] = addr[7:0];
            txd[2] = 8'h00;
            txd[3] = 8'h00;
            txd[4] = 8'h00;
            txd[5] = 8'h00;

            @(posedge aclk);
            for(int i = 0; i < 6; i++) begin
                s_axis_tdata  <= txd[i];
                s_axis_tvalid <= 1'b1;
                while(1) begin
                    @(posedge aclk);
                    if (s_axis_tready) break;
                end
            end
            s_axis_tdata  <= 8'd0;
            s_axis_tvalid <= 1'b0;

        end
    endtask

    task axi_write(input [14:0] addr, input [31:0] data);

    endtask

    always #5 aclk = ~aclk;

    initial begin
        $display("Simulation starts");
        aresetn = 1'b0;
        #100;
        aresetn = 1'b1;
        #100;

        axi_read(15'h55);
        #1000;
        $display("Simulation ends");
        $finish();
    end

    axis_axi_master DUT ( .* );

endmodule

`default_nettype wire

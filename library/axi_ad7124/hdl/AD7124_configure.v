`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2020/05/13 15:29:27
// Design Name:
// Module Name: AD7124_configure
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module AD7124_configure (
    input            PL_clk          , // osc 50M
    input            rst             ,
    output reg       TC_cs_n         , //Serial Control Port Chip Select
    output     [6:0] TC_cs           ,
    output reg       TC_sclk         , //max 25M
    input            TC_sdo          , //Serial Control Port Unid irectional Serial Data Out
    output reg       TC_sdi          , //Serial Control Port Bidirectional Serial Data In/Out
    input      [3:0] configure_select,
    input            start           ,
    output reg       F_stop_address    = 1'b0
    // output            wr_en_0   ,
    // output reg [15:0] adc_data_0
);

    localparam WIDTH1  = 24     ;
    localparam WIDTH2  = 32     ;
    localparam DLYTIME = 30'd800; // total 1ms

    reg [29:0] cnt              ;
    reg [ 7:0] txcnt_address = 0;

    wire [23:0] rdata;
    wire        rst  ;

    //add logical program
    // reg               start        = 1'b1;
    wire              stop_address;
    reg  [WIDTH1-1:0] tx_data_24  ;
    reg  [WIDTH2-1:0] tx_data_32  ;

    wire TC_sdi1 ;
    wire TC_sclk1;
    wire TC_cs_n1;

    wire TC_sdi2 ;
    wire TC_sclk2;
    wire TC_cs_n2;

    reg [4:0] TC_status = 5'b00000;

    reg [29:0] cnt_data      ;
    reg [ 7:0] txcnt_data = 0;

    wire data_ie_address;

    always@(posedge PL_clk,negedge rst)//启动时发送配置信息的计时信息
        if(~rst)
            cnt <= 20'b0    ;
        else begin
            if(~start || (cnt==DLYTIME) || F_stop_address)
                cnt <= 20'b0    ;
            else
                cnt <= cnt+1'b1;
        end

    always@(posedge PL_clk,negedge rst)//配置地址的循环计数信息
        if(~rst)
            txcnt_address <= 0  ;
        else if(~start || stop_address)   //return
            txcnt_address <= 0  ;
        else if( start && (cnt== DLYTIME) )
            txcnt_address <= txcnt_address + 1'b1;

    always@(posedge PL_clk,negedge rst)//配置地址停止的标志信号,受到start支配，当start为0时，F_stop_address也为0
        if(~rst)
            F_stop_address <= 1'b0;
        else if(start) begin
            if(stop_address)
                F_stop_address <= 1'b1;
        end
        else
            F_stop_address <= 1'b0;

    //使能和停止配置地址发送的信号
    assign data_ie_address = (start && (~F_stop_address) && (cnt == DLYTIME) && ((txcnt_address==8'd0)||(txcnt_address==8'd1)||(txcnt_address==8'd2)||(txcnt_address==8'd3)||(txcnt_address==8'd4)||(txcnt_address==8'd5)))  ? 1'b1 : 1'b0  ;
    assign stop_address    = (cnt == DLYTIME) && ( txcnt_address==8'd5 )  ? 1'b1 : 1'b0  ;


    always@(posedge PL_clk,negedge rst)
        if(~rst) begin
            tx_data_24 <= 0    ;
            tx_data_32 <= 0    ;
        end
        else if(start) begin
            case(txcnt_address)
                8'd0 : tx_data_24 <=    {8'h01,16'h0083  };
                8'd1 : begin if(configure_select==4'b0001)
                    tx_data_32 <= {8'h03,24'h1F0000}; //外部放大器增益为0.25
                    else if(configure_select==4'b0010)
                        tx_data_32 <= {8'h03,24'h4F0000}; //外部放大器增益为2
                    else if(configure_select==4'b0100)
                        tx_data_32 <= {8'h03,24'h7F0000}; //外部放大器增益为16
                    else if(configure_select==4'b1000)
                        tx_data_32 <= {8'h03,24'h2F0000}; //外部放大器增益为128
                end
                8'd2 : tx_data_24 <=    {8'h09,16'h80C7  };
                8'd3 : tx_data_24 <=    {8'h19,16'h09E0  };
                8'd4 : tx_data_32 <=    {8'h21,24'h060010};
            endcase
        end

    //建立一个状态机来选择配置寄存器还是读取数据寄存器的数据
    always@(posedge PL_clk,negedge rst)
        if(~rst)
            begin
                TC_sclk   <= TC_sclk1   ;
                TC_cs_n   <= TC_cs_n1   ;
                TC_sdi    <= TC_sdi1    ;
                TC_status <= 5'b00000    ;
            end
        else begin
            case(TC_status)
                5'b00000 : begin
                    if((txcnt_address == 8'd1) && (cnt == 30'd700))begin
                        TC_sclk   <= TC_sclk2   ;
                        TC_cs_n   <= TC_cs_n2   ;
                        TC_sdi    <= TC_sdi2    ;
                        TC_status <= 5'b00001 ;end
                    else begin
                        TC_sclk   <= TC_sclk1   ;
                        TC_cs_n   <= TC_cs_n1   ;
                        TC_sdi    <= TC_sdi1    ;
                        TC_status <= 5'b00000;end
                end
                5'b00001 : begin
                    if((txcnt_address == 8'd2) && (cnt == 30'd700))begin
                        TC_sclk   <= TC_sclk1   ;
                        TC_cs_n   <= TC_cs_n1   ;
                        TC_sdi    <= TC_sdi1    ;
                        TC_status <= 5'b00010 ;end
                    else begin
                        TC_sclk   <= TC_sclk2   ;
                        TC_cs_n   <= TC_cs_n2   ;
                        TC_sdi    <= TC_sdi2    ;
                        TC_status <= 5'b00001;end
                end
                5'b00010 : begin
                    if((txcnt_address == 8'd3) && (cnt == 30'd700))begin
                        TC_sclk   <= TC_sclk1   ;
                        TC_cs_n   <= TC_cs_n1   ;
                        TC_sdi    <= TC_sdi1    ;
                        TC_status <= 5'b00100 ;end
                    else begin
                        TC_sclk   <= TC_sclk1   ;
                        TC_cs_n   <= TC_cs_n1   ;
                        TC_sdi    <= TC_sdi1    ;
                        TC_status <= 5'b00010;end
                end
                5'b00100 : begin
                    if((txcnt_address == 8'd4) && (cnt == 30'd700))begin
                        TC_sclk   <= TC_sclk2   ;
                        TC_cs_n   <= TC_cs_n2   ;
                        TC_sdi    <= TC_sdi2    ;
                        TC_status <= 5'b01000 ;end
                    else begin
                        TC_sclk   <= TC_sclk1   ;
                        TC_cs_n   <= TC_cs_n1   ;
                        TC_sdi    <= TC_sdi1    ;
                        TC_status <= 5'b00100;end
                end
                5'b01000 : begin
                    if((txcnt_address == 8'd5) && (cnt == 30'd700))begin
                        TC_status <= 5'b00000   ;
                        TC_sclk   <= TC_sclk1   ;
                        TC_cs_n   <= TC_cs_n1   ;
                        TC_sdi    <= TC_sdi1    ;end
                    else begin
                        TC_sclk   <= TC_sclk2   ;
                        TC_cs_n   <= TC_cs_n2   ;
                        TC_sdi    <= TC_sdi2    ;
                        TC_status <= 5'b01000   ;end
                end
            endcase;
        end



// vio_0 vio(
// .clk(PL_clk),
// .probe_out0(TC_SYNC)
// );

    // ila_0 ila (
    //     .clk    (PL_clk         ),
    //     .probe0 (TC_sclk        ),
    //     .probe1 (TC_cs_n        ),
    //     .probe2 (TC_sdi         ),
    //     .probe3 (TC_status      ),
    //     .probe4 (txcnt_address  ),
    //     .probe5 (start          ),
    //     .probe6 (stop_address   ),
    //     .probe7 (data_ie_address),
    //     .probe8 (tx_data_24     ),
    //     .probe9 (tx_data_32     ),
    //     .probe10(cnt            ),
    //     .probe11(TC_sclk3       ),
    //     .probe12(TC_sdi3        ),
    //     .probe13(TC_cs_n3       ),
    //     .probe14(TC_sclk1       ),
    //     .probe15(TC_sclk2       ),
    //     .probe16(tx_data        ),
    //     .probe17(data_ie_rd     ),
    //     .probe18(TC_data        ),
    //     .probe19(F_stop_address ),
    //     .probe20(data_ie_data   ),
    //     .probe21(cnt_data       ),
    //     .probe22(txcnt_data     ),
    //     .probe23(rdata_0        ),
    //     .probe24(rdata_1        ),
    //     .probe25(cnt_rd_count   )
    // );


    spi_master #(
        .CPOL   (1'b1  ),
        .CPHA   (1'b1  ),
        .DIVF   (3     ), //2^DIVF*2=3.125M,32ns
        .WIDTH  (WIDTH1),
        .DATA_WD(32    )
    ) spi_m_24 (
        .clk    (PL_clk         ),
        .rst    (rst            ),
        .data_i (tx_data_24     ),
        .data_ie(data_ie_address),
        // .data_o (rdata  ),
        // .wr_en  (wr_en_0),
        .sclk   (TC_sclk1       ),
        .cs     (TC_cs_n1       ),
        // .miso   (TC_sdo1    ),
        .mosi   (TC_sdi1        )
    );

    spi_master #(
        .CPOL   (1'b1  ),
        .CPHA   (1'b1  ),
        .DIVF   (3     ), //2^DIVF*2=3.125M,32ns
        .WIDTH  (WIDTH2),
        .DATA_WD(32    )
    ) spi_m_32 (
        .clk    (PL_clk         ),
        .rst    (rst            ),
        .data_i (tx_data_32     ),
        .data_ie(data_ie_address),
        // .data_o (rdata  ),
        // .wr_en  (wr_en_0),
        .sclk   (TC_sclk2       ),
        .cs     (TC_cs_n2       ),
        // .miso   (TC_sdo1    ),
        .mosi   (TC_sdi2        )
    );



endmodule

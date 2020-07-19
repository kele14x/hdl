`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:58suo
// Engineer:shaoyuxin
//
// Create Date: 2020/04/29 21:49:39
// Design Name:
// Module Name: AD7124_8
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


module AD7124_8_1 (
    input             PL_clk       , // osc 50M
    input             PL_USER_RST_N,
    output reg        TC_cs_n      , //Serial Control Port Chip Select
    output reg        TC_sclk      , //max 25M
    input             TC_sdo       , //Serial Control Port Unid irectional Serial Data Out
    output reg        TC_sdi       , //Serial Control Port Bidirectional Serial Data In/Out
    input             start        ,
    output reg        stop_all       = 0,//单次采样的停止信号，保证每次start有效时，只采样一�?,并且引出模块用来指示�?始下�?个�?�道的RTD采样
    output     [23:0] rdata_0      ,
    output     [23:0] rdata_1 ,
     output            wr_en_1   
    // output reg [15:0] adc_data_0
);

    localparam WIDTH1  = 24     ;
    localparam WIDTH2  = 32     ;
    localparam WIDTH3  = 8      ;
    localparam DLYTIME = 30'd800; // total 1ms


    reg [WIDTH3-1:0] tx_data          ;
    reg [      29:0] cnt              ;
    reg [       7:0] txcnt_address = 0;


    wire [23:0] rdata;
    wire        rst  ;

    //add logical program
    wire              stop_address;
    reg  [WIDTH1-1:0] tx_data_24  ;
    reg  [WIDTH2-1:0] tx_data_32  ;
    reg  [WIDTH3-1:0] tx_data     ;

    wire       TC_sdi1             ;
    wire       TC_sclk1            ;
    wire       TC_cs_n1            ;
    wire       TC_sdi2             ;
    wire       TC_sclk2            ;
    wire       TC_cs_n2            ;
    reg  [4:0] TC_status = 5'b00000;

    wire TC_sdi3 ;
    wire TC_sclk3;
    wire TC_cs_n3;

    wire TC_sdi4 ;
    wire TC_sclk4;
    wire TC_cs_n4;
    
    reg F_stop_cnt_rd;

    // reg stop_single;//单次采样的停止信号，保证每次start有效时，只采样一�?

    reg        F_stop_address    ;
    reg [29:0] cnt_data          ;
    reg [ 7:0] txcnt_data     = 0;

    wire        data_ie_address             ;
    wire        data_ie_data                ;
    wire        stop_data                   ;
    reg  [23:0] TC_data         = 24'h000000;
    // reg  [23:0] TC_data_1                   ;



    wire wr_en_0;
//    wire wr_en_1;
    // wire [23:0] rdata_0       ;
    // wire [23:0] rdata_1       ;
    reg        F_stop = 1'b0; //高有�? 停止cnt_data 计数
    reg [19:0] cnt_rd       ;
    // reg         F_stop_1 = 1'b0;// 高有�? 停止cnt_rd 计数
    reg stop_single = 0;

    assign rst = PL_USER_RST_N;

    always@(posedge PL_clk,negedge rst)//启动时发送配置信息的计时信息
        if(~rst)
            cnt <= 20'b0    ;
        else begin
            if((cnt==DLYTIME) || (~start) || F_stop_address)
                cnt <= 20'b0    ;
            else
                cnt <= cnt+1'b1;
        end

    always@(posedge PL_clk,negedge rst)//使能状�?�寄存器读取的计数信�?
        if(~rst)
            cnt_data <= 20'b0    ;
        else begin
            if((~F_stop_address) || (cnt_data==DLYTIME) || F_stop || stop_single)
                cnt_data <= 20'b0    ;
            else
                cnt_data <= cnt_data+1'b1;
        end

    always@(posedge PL_clk,negedge rst)//read AD 数据寄存器的计数信息
        if(~rst)
            cnt_rd <= 20'b0    ;
        else begin
            if((~F_stop_address) || (cnt_rd==DLYTIME) || rdata_0[23] || stop_all || F_stop_cnt_rd)//为了使cnt_data�?800
                cnt_rd <= 20'b0    ;
            else
                cnt_rd <= cnt_rd + 1'b1;
        end


    always@(posedge PL_clk,negedge rst)//配置地址的循环计数信�?
        if(~rst)
            txcnt_address <= 0  ;
        else if(stop_address || stop_single)   //return
            txcnt_address <= 0  ;
        else if( start && (cnt== DLYTIME) )
            txcnt_address <= txcnt_address + 1'b1;

    always@(posedge PL_clk,negedge rst)//配置地址停止的标志信�?
        if(~rst)
            F_stop_address <= 1'b0;
        else if(stop_address)
            F_stop_address <= 1'b1;
            else if(~start)
            F_stop_address <= 1'b0;
            
    always@(posedge PL_clk,negedge rst)//循环读取数据的计数信�?
        if(~rst)
            txcnt_data <= 0  ;
        else if(stop_data || stop_single)   //return
            txcnt_data <= 0  ;
        else if( F_stop_address && (cnt_data== DLYTIME) )
            txcnt_data <= txcnt_data + 1'b1;

    //使能和停止配置地�?发�?�的信号
    assign data_ie_address = (start && (cnt == DLYTIME)) && (( txcnt_address==8'd4 ) || ( txcnt_address==8'd3 ) || ( txcnt_address==8'd2 ) || ( txcnt_address==8'd1) || ( txcnt_address==8'd0 )) ? 1'b1 : 1'b0  ;
    assign stop_address    = (cnt == DLYTIME) && ( txcnt_address==8'd5 )  ? 1'b1 : 1'b0  ;

    //使能和复位循环读取数据的信号
    assign data_ie_data = (F_stop_address && (cnt_data == 20'd50) && ( txcnt_data==8'd0 ))  ? 1'b1 : 1'b0  ;
    assign stop_data    = (cnt_data == DLYTIME) && ( txcnt_data==8'd0 )  ? 1'b1 : 1'b0  ;

    assign data_ie_rd = (F_stop_address && (cnt_rd == 20'd50))  ? 1'b1 : 1'b0  ;

    always@(posedge PL_clk,negedge rst)
        if(~rst) begin
            tx_data_24 <= 0    ;
            tx_data_32 <= 0    ;
        end
        else if(start) begin
            case(txcnt_address)
                8'd0 : tx_data_24 <=    {8'h01,16'h0080  };
                8'd1 : tx_data_32 <=    {8'h03,24'h0018C0}; //dev_addr:3
                8'd2 : tx_data_24 <=    {8'h09,16'h81CF  };
                8'd3 : tx_data_24 <=    {8'h19,16'h09E1  };
                8'd4 : tx_data_32 <=    {8'h21,24'h0603C0};
            endcase
        end

    //循环读取AD的状态寄存器并且判断是否可以读取ad数据寄存器的数据
    always@(posedge PL_clk,negedge rst)
        if(~rst)
            tx_data <= 0    ;
        else if(F_stop_address) begin
            case(txcnt_data)
                8'd0 : begin
                    tx_data <= {8'h40};
                end
            endcase
        end

    //建立�?个状态机来�?�择配置寄存器还是读取数据寄存器的数�?
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
                    if((txcnt_address == 8'd1) && (cnt == 30'd700))begin//发�?? 8'd0 : tx_data_24 <= {8'h01,16'h0083  };
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
                    if((txcnt_address == 8'd2) && (cnt == 30'd700))begin//发�??  8'd1 : tx_data_32 <= {8'h03,24'h1F0000};
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
                    if((txcnt_address == 8'd3) && (cnt == 30'd700))begin//发�??  8'd2 : tx_data_24 <= {8'h09,16'h80C7  };
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
                    if((txcnt_address == 8'd4) && (cnt == 30'd700))begin//发�??  8'd3 : tx_data_24 <= {8'h19,16'h09E0  };
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
                    if(cnt_data == 30'd10 )begin//发�??  8'd4 : tx_data_32 <= {8'h21,24'h060010};，当cnt_data = 800，发送读状�?�寄存器信号
                        TC_status <= 5'b10000;
                        TC_sclk   <= TC_sclk3   ;
                        TC_cs_n   <= TC_cs_n3   ;
                        TC_sdi    <= TC_sdi3    ;end
                    else begin
                        F_stop_cnt_rd    <= 1'b1;
                        TC_sclk   <= TC_sclk2   ;
                        TC_cs_n   <= TC_cs_n2   ;
                        TC_sdi    <= TC_sdi2    ;
                        TC_status <= 5'b01000 ;end
                end
                5'b10000 : begin//这里判断读回来的状�?�寄存器的最高位是否�?0，如果为0则停止访问状态寄存器，转为发送请求数据寄存器数据的tx_data�?42，如果为1，不断访问AD的状态寄存器，直到最高位�?0.
                if(~rdata_0[23] && (cnt_data>=20'd700))begin
                TC_status <= 5'b10001;
//                F_stop    <= 1'b1;
                end
//                    if(~rdata_0[23] && (cnt_data>=700))begin//这里是保证当~rdata_0[23]�?0时，�?后一个cnt_data计数周期达到800且让sclk3完全给到sclk上�??
//                        if(cnt_rd == 20'd800) begin//在cnt_rd == 20'd50的时候发送data_ie_rd，当�?个cnt_rd周期结束后，默认结束完了�?次读Ad采集数据的操作，跳到10001状�??
//                            F_stop    <= 1'b0       ;//cnt_data�?始计�?
//                            F_stop_cnt_rd <= 1'b1;
//                            // TC_sclk   <= TC_sclk3   ;
//                            // TC_cs_n   <= TC_cs_n3   ;
//                            // TC_sdi    <= TC_sdi3    ;
//                            TC_status <= 5'b10001 ;end
//                        else begin//发�?�读取AD的数据寄存器请求
//                            F_stop_cnt_rd <= 1'b0;
//                            F_stop    <= 1'b1;//stop cnt_data
//                            TC_status <= 5'b10000;
//                            TC_sclk   <= TC_sclk4   ;
//                            TC_cs_n   <= TC_cs_n4   ;
//                            TC_sdi    <= TC_sdi4    ;end
//                    end
                    else begin
                        F_stop    <= 1'b0;                    
                        TC_sclk   <= TC_sclk3   ;
                        TC_cs_n   <= TC_cs_n3   ;
                        TC_sdi    <= TC_sdi3    ;
                        TC_status <= 5'b10000 ;end
                end
                // 5'b10001 : begin if(~rdata_0[23]) begin//判断读取AD数据寄存器结束后回归到查询状态寄存器的状态，并且�?始下�?次的读取状�?�寄存器，等到又�?次rdata_0[23]�?0时，又重新开始读取AD的数据寄存器
                //         F_stop_1  <= 1'b1;//停止cnt_rd计数，继续访问AD的状态寄存器，等待下�?次读取数据寄存器�?
                //         TC_sclk   <= TC_sclk3   ;
                //         TC_cs_n   <= TC_cs_n3   ;
                //         TC_sdi    <= TC_sdi3    ;
                //         TC_status <= 5'b10001 ;end
                //     else begin//可以循环读取AD的状态寄存器的最高位，然后去读AD的数据寄存器
                //         TC_status <= 5'b10000 ;
                //         F_stop_1  <= 1'b0;
                //     end
                // end
                5'b10001 : begin
                       if(cnt_rd == 20'd800) begin//在cnt_rd == 20'd50的时候发送data_ie_rd，当�?个cnt_rd周期结束后，默认结束完了�?次读Ad采集数据的操作，跳到10001状�??
                            F_stop    <= 1'b0       ;//cnt_data�?始计�?
                            F_stop_cnt_rd <= 1'b1;
                            // TC_sclk   <= TC_sclk3   ;
                            // TC_cs_n   <= TC_cs_n3   ;
                            // TC_sdi    <= TC_sdi3    ;
                            TC_status <= 5'b10010 ;end
                        else begin//发�?�读取AD的数据寄存器请求
                            F_stop_cnt_rd <= 1'b0;
                            F_stop    <= 1'b1;//stop cnt_data
                            TC_status <= 5'b10001;
                            TC_sclk   <= TC_sclk4   ;
                            TC_cs_n   <= TC_cs_n4   ;
                            TC_sdi    <= TC_sdi4    ;end
                end
                5'b10010 : begin if(stop_all) //表示只有效读取了�?次RTD数据就结束了，没有进行循环读取，又回到了初始态，等待�?下一次的start信号
                    TC_status <= 5'b00000;
                    else
                        TC_status <= 5'b10010;
                end

            endcase;
        end

    always@(posedge PL_clk,negedge rst)//表示此�?�道RTD采样�?次结束，并且引出模块用来指示�?始下�?个�?�道的RTD采样
        if(~rst)
            stop_single <= 1'b0;
        else if(wr_en_1 && start)
            stop_single <= 1'b1;
        else if(~start)
            stop_single <= 1'b0;

    always@(posedge PL_clk,negedge rst)//如果用stop_single的信号当停止信号的话，cnt_rd的计数不会跑�?800就停了，因为wr_en_1有效时，此时计数就停止了，sclk就不会是sclk4了，因此为了让sclk4充分的给到sclk，所以是�?要另设另�?个停止信号作为后续模块的�?始信�?
        if(~rst)
            stop_all <= 1'b0;
        else if(stop_single && (cnt_rd == 20'd800))
            stop_all <= 1'b1;
        else if (~start)
            stop_all <= 1'b0;


    always@(posedge PL_clk,negedge rst)//wr_en_1代表了一次读取数据的结束，也代表了rdata_1的更新，
        if(~rst)
            TC_data <= 24'h000000;
        else if(wr_en_1)
            TC_data <= rdata_1;

    reg [29:0] cnt_rd_count;
    always@(posedge PL_clk,negedge rst)//计数，看看到底读了AD数据寄存器多少次
        if(~rst)
            cnt_rd_count <= 0;
        else if(wr_en_1)
            cnt_rd_count <= cnt_rd_count + 1'b1;

// vio_0 vio(
// .clk(PL_clk),
// .probe_out0(TC_SYNC)
// );

//        ila_0 ila (
//            .clk    (PL_clk         ),
//            .probe0 (TC_sclk        ),
//            .probe1 (TC_cs_n        ),
//            .probe2 (TC_sdi         ),
//            .probe3 (TC_status      ),
//            .probe4 (txcnt_address  ),
//            .probe5 (TC_sdo          ),
//            .probe6 (stop_address   ),
//            .probe7 (data_ie_address),
//            .probe8 (tx_data_24     ),
//            .probe9 (tx_data_32     ),
//            .probe10(cnt            ),
//            .probe11(TC_sclk4       ),
//            .probe12(TC_sdi4        ),
//            .probe13(TC_cs_n4       ),
//            .probe14(TC_sclk1       ),
//            .probe15(TC_sclk2       ),
//            .probe16(tx_data        ),
//            .probe17(data_ie_rd     ),
//            .probe18(TC_data        ),
//            .probe19(F_stop_address ),
//            .probe20(data_ie_data   ),
//            .probe21(cnt_data       ),
//            .probe22(txcnt_data     ),
//            .probe23(rdata_0        ),
//            .probe24(rdata_1        ),
//            .probe25(cnt_rd_count   )
//        );


    (* KEEP="TRUE" *)spi_master #(
        .CPOL   (1'b1 ),
        .CPHA   (1'b1 ),
        .DIVF   (3    ), //2^DIVF*2=3.125M,32ns
        .WIDTH  (WIDTH1),
        .DATA_WD(32   )
    ) spi_m_24 (
        .clk    (PL_clk ),
        .rst    (rst    ),
        .data_i (tx_data_24),
        .data_ie(data_ie_address),
        // .data_o (rdata  ),
        // .wr_en  (wr_en_0),
        .sclk   (TC_sclk1   ),
        .cs     (TC_cs_n1   ),
        // .miso   (TC_sdo1    ),
        .mosi   (TC_sdi1    )
);

    (* KEEP="TRUE" *)spi_master #(
        .CPOL   (1'b1 ),
        .CPHA   (1'b1 ),
        .DIVF   (3    ), //2^DIVF*2=3.125M,32ns
        .WIDTH  (WIDTH2),
        .DATA_WD(32   )
    ) spi_m_32 (
        .clk    (PL_clk ),
        .rst    (rst    ),
        .data_i (tx_data_32),
        .data_ie(data_ie_address),
        // .data_o (rdata  ),
        // .wr_en  (wr_en_0),
        .sclk   (TC_sclk2   ),
        .cs     (TC_cs_n2   ),
        // .miso   (TC_sdo1    ),
        .mosi   (TC_sdi2    )
    );

    (* KEEP="TRUE" *)spi_master_transmit_RTD #(
        .CPOL   (1'b1  ),
        .CPHA   (1'b1  ),
        .DIVF   (3     ), //2^DIVF*2=3.125M,32ns
        .WIDTH  (WIDTH3),
        .DATA_WD(24    )
    ) spi_m_transmit (
        .clk    (PL_clk ),
        .rst    (rst    ),
        .data_i (tx_data),
        .data_ie(data_ie_data),
        .data_o (rdata_0  ),
        .wr_en  (wr_en_0),
        .sclk   (TC_sclk3   ),
        .cs     (TC_cs_n3   ),
        .miso   (TC_sdo     ),
        .mosi   (TC_sdi3    )
    );

    (* KEEP="TRUE" *)spi_master_transmit_RTD #(
        .CPOL   (1'b1  ),
        .CPHA   (1'b1  ),
        .DIVF   (3     ), //2^DIVF*2=3.125M,32ns
        .WIDTH  (WIDTH3),
        .DATA_WD(24    )
    ) spi_m_rdata (
        .clk    (PL_clk ),
        .rst    (rst    ),
        .data_i (8'h42),
        .data_ie(data_ie_rd),
        .data_o (rdata_1       ),
        .wr_en  (wr_en_1     ),
        .sclk   (TC_sclk4   ),
        .cs     (TC_cs_n4   ),
        .miso   (TC_sdo     ),
        .mosi   (TC_sdi4    )
    );

endmodule

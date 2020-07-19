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


module AD7124_8_TC_read (
    input            PL_clk         , // osc 50M
    input            PL_USER_RST_N  ,
    output reg       TC_cs_n        , //Serial Control Port Chip Select
    output reg       TC_sclk        , //max 25M
    input            TC_sdo         , //Serial Control Port Unid irectional Serial Data Out
    output reg       TC_sdi         , //Serial Control Port Bidirectional Serial Data In/Out
    input            start          ,
    output reg [7:0] txcnt_loop = 0 ,
    output           data_ie_rd_1   ,
    output           data_ie_rd_2   ,
    output           data_ie_rd_3   ,
    output           data_ie_rd_4   ,
    output           data_ie_rd_5   ,
    output           data_ie_rd_6   ,
    output           data_ie_rd_7   ,
    output      [23:0]  rdata_1    ,
    output reg          stop_all   ,
    output reg wr_en_1_dy2        ,
    output wr_en_1
);

    localparam WIDTH3       = 8      ;
    localparam DLYTIME      = 30'd900; // total 1ms
    localparam DLYTIME_loop = 30'd900; // total 1ms

    wire rst;

    reg [       2:0] TC_status = 3'b000;
    reg [WIDTH3-1:0] tx_data           ;

    wire [23:0] rdata_0;
//    wire [23:0] rdata_1;
     reg  [23:0] TC_data;

    wire wr_en_0;
    wire wr_en_1;

    //读取状�?�寄存器�?�?计数信息
    reg  [29:0] cnt      = 0   ;
    reg  [ 7:0] txcnt    = 0   ;
    wire        data_ie        ;
    wire        stop           ;
    reg         stop_cnt = 1'b1;

    //读取数据寄存器所�?计数信息
    reg  [29:0] cnt_rd      = 0   ;
    reg  [ 7:0] txcnt_rd    = 0   ;
    reg         stop_cnt_rd = 1'b1;
    wire        data_ie_rd        ;
    wire        stop_rd           ;


    //循环读取AD_0-AD_7�?�?的计数信�?
    reg [29:0] cnt_loop = 0;
    // reg [ 7:0] txcnt_loop    = 0   ;
    reg stop_cnt_loop = 1'b1;


    wire TC_sclk1;
    wire TC_sdi1 ;
    wire TC_cs_n1;

    wire TC_sclk2;
    wire TC_sdi2 ;
    wire TC_cs_n2;
    
   reg wr_en_1_dy1;
//   reg wr_en_1_dy2;
//    reg stop_all;

    //add logical program


    assign rst = PL_USER_RST_N;


    always@(posedge PL_clk,negedge rst)//当配置结束后，start会一直为1，cnt正常计数，后期stop_cnt控制cnt是否计数，默认�?�应该为1
        if(~rst)
            cnt <= 20'b0    ;
        else begin
            if((~start) || (cnt==DLYTIME) || stop_cnt)
                cnt <= 20'b0    ;
            else
                cnt <= cnt+1'b1;
        end

    always@(posedge PL_clk,negedge rst)//配合产生data_ie，也可以去掉
        if(~rst)
            txcnt <= 0  ;
        else if(stop)   //return
            txcnt <= 0  ;
        else if( start && (cnt== DLYTIME) )
            txcnt <= txcnt + 1'b1;


    //循环产生使能和复位来读取状�?�寄存器的信�?
    assign data_ie = (start && (cnt == 20'd50) && ( txcnt==8'd0 ))  ? 1'b1 : 1'b0  ;
    assign stop    = (cnt == DLYTIME) && ( txcnt==8'd0 )  ? 1'b1 : 1'b0  ;


    //循环读取AD的状态寄存器并且判断是否可以读取ad数据寄存器的数据，当start�?1，txcnt�?0，发送tx_data，这个模块也可以去掉
    always@(posedge PL_clk,negedge rst)
        if(~rst)
            tx_data <= 0    ;
        else if(start) begin
            case(txcnt)
                8'd0 : begin
                    tx_data <= {8'h40};
                end
            endcase
        end



    //读取数据寄存器的相关计时信息


    always@(posedge PL_clk,negedge rst)//读取数据寄存器所�?的计时信息，由stop_cnt_rd来控制是否计数，stop_cnt_rd默认态应该为1�?
        if(~rst)
            cnt_rd <= 20'b0    ;
        else begin
            if((stop_cnt_rd) || (cnt_rd==DLYTIME))
                cnt_rd <= 20'b0    ;
            else
                cnt_rd <= cnt_rd+1'b1;
        end

    always@(posedge PL_clk,negedge rst)//读取数据计数
        if(~rst)
            txcnt_rd <= 0  ;
        else if(stop_rd)   //return
            txcnt_rd <= 0  ;
        else if(cnt_rd== DLYTIME)
            txcnt_rd <= txcnt_rd + 1'b1;

    //循环产生AD_0-AD7的使能和复位来读取数据寄存器的信�?
    assign data_ie_rd = (start && (cnt_rd   == 20'd50) && ( txcnt_rd==8'd0 ))  ? 1'b1 : 1'b0  ;
    assign stop_rd    = (cnt_rd == DLYTIME) && ( txcnt_rd==8'd0 )  ? 1'b1 : 1'b0  ;

    //建立�?个状态机来�?�择配置寄存器还是读取数据寄存器的数�?
    always@(posedge PL_clk,negedge rst)
        if(~rst)
            begin
                TC_sclk   <= TC_sclk1   ;
                TC_cs_n   <= TC_cs_n1   ;
                TC_sdi    <= TC_sdi1    ;
                TC_status <= 3'b000     ;
            end
        else begin if(start) begin
                case(TC_status)
                    3'b000 : begin
//                        if(txcnt_loop == 8'd0) begin
                            if(~rdata_0[23] && (cnt >= 20'd800)) begin //保证第二次循环读取数据的正确性，不加cnt >= 20'd800的话，第二次读取数据就会直接进入数据寄存器，不会查询状�?�寄存器
                                stop_cnt      <= 1'b1     ;           //停止查询状�?�寄存器的cnt计数计时信息，只要进入到读取数据寄存器的循环中，就把cnt计数停掉，初始�?�为1
                                stop_cnt_loop <= 1'b0     ;           //当确定了数据寄存器准备好了后，开始cnt_loop计数，此时AD_0已经准备好了，同时默认AD_1-AD_7中的数据都已经准备完成了，可以直接进行读取数据寄存器操作，初始�?�为1，即停止计数
                                stop_cnt_rd   <= 1'b0     ;           //start cnt_data�?始计数，初始态为1
                                TC_sclk       <= TC_sclk2 ;
                                TC_cs_n       <= TC_cs_n2 ;
                                TC_sdi        <= TC_sdi2  ;
                                TC_status     <= 3'b001   ; end
                            else begin                                 //这里判断读回来的状�?�寄存器的最高位是否�?0，如果为0则停止访问状态寄存器，转为发送请求数据寄存器数据的tx_data�?42，如果为1，不断访问AD的状态寄存器，直到最高位�?0.
                                stop_cnt      <= 1'b0     ;           //当配置结束后，首先开始cnt计数，目的是来访问状态寄存器，确定AD采集的数据是否可以进行读�?
                                stop_cnt_loop <= 1'b1     ;
                                stop_cnt_rd   <= 1'b1     ;
                                TC_sclk       <= TC_sclk1 ;
                                TC_cs_n       <= TC_cs_n1 ;
                                TC_sdi        <= TC_sdi1  ;
                                TC_status     <= 3'b000   ; end
                        end
//                    end
                    3'b001 : begin
                        if(cnt_rd == 20'd850) begin                    //在cnt_rd == 20'd50的时候发送data_ie_rd，当�?个cnt_rd周期结束后，默认结束完了�?次读Ad采集数据的操作�??
                            stop_cnt_rd <= 1'b1        ;               //stop cnt_data停止计数，继续访问AD的状态寄存器，等待下�?次读取数据寄存器
                            TC_status   <= 3'b000      ; end
                        else begin                                     //�?始发送读取AD的数据寄存器请求
                            TC_status <= 3'b001        ;
                            TC_sclk   <= TC_sclk2      ;
                            TC_cs_n   <= TC_cs_n2      ;
                            TC_sdi    <= TC_sdi2       ; end
                    end
//                    3'b010 : begin
//                        if(txcnt_loop == 8'd1) begin                   //判断读取AD数据寄存器结束后回归到查询状态寄存器的状态，并且�?始下�?次的读取状�?�寄存器，等到又�?次rdata_0[23]�?0时，又重新开始读取AD的数据寄存器
//                            TC_sclk   <= TC_sclk1      ;
//                            TC_cs_n   <= TC_cs_n1      ;
//                            TC_sdi    <= TC_sdi1       ;
//                            TC_status <= 3'b000        ; end
//                        else begin
//                            TC_status <= 5'b010        ;
//                        end
//                    end
                endcase
            end
        end
        
always@(posedge PL_clk,negedge rst)
if(~rst)
stop_all <= 1'b0;
else if(cnt_rd == 20'd850)
stop_all <= 1'b1;
else if(~start)
stop_all <= 1'b0;
 


    always@(posedge PL_clk,negedge rst)//当AD_0读取完成数据，默认其�?8个AD同样转换完成，所以无�?向AD_0�?样访问状态寄存器，可以直接读取数据寄存器，这就是其它AD读取数据的计数信�?
        if(~rst)
            cnt_loop <= 20'b0    ;
        else begin
            if(stop_cnt_loop || (cnt_loop==DLYTIME))
                cnt_loop <= 20'b0    ;
            else
                cnt_loop <= cnt_loop+1'b1;
        end

    always@(posedge PL_clk,negedge rst)//其它AD的循环计数信息，�?1�?7代表�?7个AD
        if(~rst)
            txcnt_loop <= 0  ;
        else if(stop_loop)   //return
            txcnt_loop <= 0  ;
        else if((~stop_cnt_loop) && (cnt_loop==DLYTIME) )
            txcnt_loop <= txcnt_loop + 1'b1;


    assign data_ie_rd_1 = (start && (cnt_loop == 20'd50) && ( txcnt_loop==8'd1 ))  ? 1'b1 : 1'b0  ;
    assign data_ie_rd_2 = (start && (cnt_loop == 20'd50) && ( txcnt_loop==8'd2 ))  ? 1'b1 : 1'b0  ;
    assign data_ie_rd_3 = (start && (cnt_loop == 20'd50) && ( txcnt_loop==8'd3 ))  ? 1'b1 : 1'b0  ;
    assign data_ie_rd_4 = (start && (cnt_loop == 20'd50) && ( txcnt_loop==8'd4 ))  ? 1'b1 : 1'b0  ;
    assign data_ie_rd_5 = (start && (cnt_loop == 20'd50) && ( txcnt_loop==8'd5 ))  ? 1'b1 : 1'b0  ;
    assign data_ie_rd_6 = (start && (cnt_loop == 20'd50) && ( txcnt_loop==8'd6 ))  ? 1'b1 : 1'b0  ;
    assign data_ie_rd_7 = (start && (cnt_loop == 20'd50) && ( txcnt_loop==8'd7 ))  ? 1'b1 : 1'b0  ;

    assign stop_loop = (cnt_loop == DLYTIME) && ( txcnt_loop==8'd7 )  ? 1'b1 : 1'b0  ;



    always@(posedge PL_clk,negedge rst)//wr_en_1代表了一次读取数据的结束，也代表了rdata_1的更新，
        if(~rst)
            TC_data <= 24'h000000;
        else if(wr_en_1)
            TC_data <= rdata_1;
            
      always@(posedge PL_clk)
      begin
             wr_en_1_dy1  <= wr_en_1;
             wr_en_1_dy2  <= wr_en_1_dy1;
             end
             
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

        // ila_0 ila (
        //     .clk    (PL_clk         ),
        //     .probe0 (TC_sclk        ),
        //     .probe1 (TC_cs_n        ),
        //     .probe2 (TC_sdi         ),
        //     .probe3 (TC_status      ),
        //     .probe4 ( ),
        //     .probe5 ( ),
        //     .probe6 ( ),
        //     .probe7 (),
        //     .probe8 ( ),
        //     .probe9 ( ),
        //     .probe10( ),
        //     .probe11( ),
        //     .probe12( ),
        //     .probe13( ),
        //     .probe14( ),
        //     .probe15( ),
        //     .probe16( ),
        //     .probe17( ),
        //     .probe18( ),
        //     .probe19( ),
        //     .probe20( ),
        //     .probe21( ),
        //     .probe22( ),
        //     .probe23( ),
        //     .probe24( ),
        //     .probe25( )
        // );



    (* KEEP="TRUE" *)spi_master_transmit_TC_status #(
        .CPOL   (1'b1  ),
        .CPHA   (1'b1  ),
        .DIVF   (3     ), //2^DIVF*2=3.125M,32ns
        .WIDTH  (WIDTH3),
        .DATA_WD(24    )
    ) spi_m_transmit (
        .clk    (PL_clk ),
        .rst    (rst    ),
        .data_i (tx_data),
        .data_ie(data_ie),
        .data_o (rdata_0),
        .wr_en  (wr_en_0),
        .sclk   (TC_sclk1   ),
        .cs     (TC_cs_n1   ),
        .miso   (TC_sdo     ),
        .mosi   (TC_sdi1    )
);


        (* KEEP="TRUE" *)spi_master_transmit_TC_data #(
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
            .sclk   (TC_sclk2   ),
            .cs     (TC_cs_n2   ),
            .miso   (TC_sdo     ),
            .mosi   (TC_sdi2    )
        );

        endmodule

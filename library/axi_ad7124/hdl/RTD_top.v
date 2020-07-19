`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2020/05/21 19:46:01
// Design Name:
// Module Name: RTD_top
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


module RTD_top (
    input             PL_clk     ,
    input             rst        ,
    // output G1_ANA_POW_EN,
    input             start      ,
    output     [ 9:0] stop_single,
    input             RTD_sdo    ,
    output reg        RTD_cs_n   ,
    output reg        RTD_sclk   ,
    output reg        RTD_sdi    ,
    output     [23:0] rdata_0    ,
    output     [23:0] rdata_1    ,
    output     [23:0] rdata_2    ,
    output     [23:0] rdata_3    ,
    output     [23:0] rdata_4    ,
    output     [23:0] rdata_5    ,
    output     [23:0] rdata_6    ,
    output     [23:0] rdata_7    ,
    output     [23:0] rdata_8    ,
    output     [23:0] rdata_9    ,
    output            wr_en_RTD  ,
    output reg [31:0] RTD_data
);

    // wire       start      ;
    // wire [9:0] stop_single;

    reg  [9:0] RTD_status = 10'b0000000000;
    reg  [9:0] start_10   = 10'b1000000000;
    
    wire       TC_sclk_0                  ;
    wire       TC_sdi_0                   ;
    wire       TC_cs_n_0                  ;

    wire TC_sclk_1;
    wire TC_sdi_1 ;
    wire TC_cs_n_1;

    wire TC_sclk_2;
    wire TC_sdi_2 ;
    wire TC_cs_n_2;

    wire TC_sclk_3;
    wire TC_sdi_3 ;
    wire TC_cs_n_3;

    wire TC_sclk_4;
    wire TC_sdi_4 ;
    wire TC_cs_n_4;

    wire TC_sclk_5;
    wire TC_sdi_5 ;
    wire TC_cs_n_5;

    wire TC_sclk_6;
    wire TC_sdi_6 ;
    wire TC_cs_n_6;

    wire TC_sclk_7;
    wire TC_sdi_7 ;
    wire TC_cs_n_7;

    wire TC_sclk_8;
    wire TC_sdi_8 ;
    wire TC_cs_n_8;

    wire TC_sclk_9;
    wire TC_sdi_9 ;
    wire TC_cs_n_9;

    wire stop_single_0;
    wire stop_single_1;
    wire stop_single_2;
    wire stop_single_3;
    wire stop_single_4;
    wire stop_single_5;
    wire stop_single_6;
    wire stop_single_7;
    wire stop_single_8;
    wire stop_single_9;

    wire [23:0] data_status_0;
    // wire [23:0] rdata_0      ;

    wire [23:0] data_status_1;
    // wire [23:0] rdata_1      ;

    wire [23:0] data_status_2;
    // wire [23:0] rdata_2      ;

    wire [23:0] data_status_3;
    // wire [23:0] rdata_3      ;

    wire [23:0] data_status_4;
    // wire [23:0] rdata_4      ;

    wire [23:0] data_status_5;
    // wire [23:0] rdata_5      ;

    wire [23:0] data_status_6;
    // wire [23:0] rdata_6      ;

    wire [23:0] data_status_7;
    // wire [23:0] rdata_7      ;

    wire [23:0] data_status_8;
    // wire [23:0] rdata_8      ;

    wire [23:0] data_status_9;
    // wire [23:0] rdata_9      ;
    
    wire wr_en_0;
    wire wr_en_1;
    wire wr_en_2;
    wire wr_en_3;
    wire wr_en_4;
    wire wr_en_5;
    wire wr_en_6;
    wire wr_en_7;
    wire wr_en_8;
    wire wr_en_9;
    
    reg wr_en_0_dy;
    reg wr_en_1_dy;
    reg wr_en_2_dy;
    reg wr_en_3_dy;
    reg wr_en_4_dy;
    reg wr_en_5_dy;
    reg wr_en_6_dy;
    reg wr_en_7_dy;
    reg wr_en_8_dy;
    reg wr_en_9_dy;

    reg wr_en_0_dy1;
    reg wr_en_1_dy1;
    reg wr_en_2_dy1;
    reg wr_en_3_dy1;
    reg wr_en_4_dy1;
    reg wr_en_5_dy1;
    reg wr_en_6_dy1;
    reg wr_en_7_dy1;
    reg wr_en_8_dy1;
    reg wr_en_9_dy1;

    reg wr_en_0_dy2;
    reg wr_en_1_dy2;
    reg wr_en_2_dy2;
    reg wr_en_3_dy2;
    reg wr_en_4_dy2;
    reg wr_en_5_dy2;
    reg wr_en_6_dy2;
    reg wr_en_7_dy2;
    reg wr_en_8_dy2;
    reg wr_en_9_dy2;
    
    assign wr_en_RTD = wr_en_0_dy2 || wr_en_1_dy2 || wr_en_2_dy2 || wr_en_3_dy2 || wr_en_4_dy2 || wr_en_5_dy2 || wr_en_6_dy2 || wr_en_7_dy2 || wr_en_8_dy2 || wr_en_9_dy2;
    
    // assign G1_ANA_POW_EN = 1'b1;
    // assign start = 1'b1;

    assign stop_single = {stop_single_9,stop_single_8,stop_single_7,stop_single_6,stop_single_5,stop_single_4,stop_single_3,stop_single_2,stop_single_1,stop_single_0};

    always@(posedge PL_clk,negedge rst)
        if(~rst) begin
            RTD_sclk <= TC_sclk_0;
            RTD_sdi  <= TC_sdi_0 ;
            RTD_cs_n <= TC_cs_n_0;
        end
        else if(start) begin
            case(RTD_status)
                10'b0000000000 : begin if(stop_single_9) begin
                    RTD_status <= 10'b0000000001;
                    start_10      <= 10'b0000000001;
                    RTD_sclk   <= TC_sclk_0;
                    RTD_sdi    <= TC_sdi_0 ;
                    RTD_cs_n   <= TC_cs_n_0;end
                else begin
                    RTD_sclk <= TC_sclk_9;
                    RTD_sdi  <= TC_sdi_9 ;
                    RTD_cs_n <= TC_cs_n_9;
                    start_10      <= 10'b1000000000;
                    RTD_status <= 10'b0000000000;end
            end
                10'b0000000001 : begin if(stop_single_0) begin
                    RTD_status <= 10'b0000000010;
                    start_10      <= 10'b0000000010;
                    RTD_sclk   <= TC_sclk_1;
                    RTD_sdi    <= TC_sdi_1 ;
                    RTD_cs_n   <= TC_cs_n_1;end
                else begin
                    RTD_sclk <= TC_sclk_0;
                    RTD_sdi  <= TC_sdi_0 ;
                    RTD_cs_n <= TC_cs_n_0;
                    start_10      <= 10'b0000000001;
                    RTD_status <= 10'b0000000001;end
            end
                10'b0000000010 : begin if(stop_single_1) begin
                    RTD_status <= 10'b0000000100;
                    start_10      <= 10'b0000000100;
                    RTD_sclk   <= TC_sclk_2;
                    RTD_sdi    <= TC_sdi_2 ;
                    RTD_cs_n   <= TC_cs_n_2;end
                else begin
                    RTD_sclk <= TC_sclk_1;
                    RTD_sdi  <= TC_sdi_1 ;
                    RTD_cs_n <= TC_cs_n_1;
                    start_10      <= 10'b0000000010;
                    RTD_status <= 10'b0000000010;end
            end
                10'b0000000100 : begin if(stop_single_2) begin
                    RTD_status <= 10'b0000001000;
                    start_10      <= 10'b0000001000;
                    RTD_sclk   <= TC_sclk_3;
                    RTD_sdi    <= TC_sdi_3 ;
                    RTD_cs_n   <= TC_cs_n_3;end
                else begin
                    RTD_sclk <= TC_sclk_2;
                    RTD_sdi  <= TC_sdi_2 ;
                    RTD_cs_n <= TC_cs_n_2;
                    start_10     <= 10'b0000000100;
                    RTD_status <= 10'b0000000100;end
            end
                10'b0000001000 : begin if(stop_single_3) begin
                    RTD_status <= 10'b0000010000;
                    start_10      <= 10'b0000010000;
                    RTD_sclk   <= TC_sclk_4;
                    RTD_sdi    <= TC_sdi_4 ;
                    RTD_cs_n   <= TC_cs_n_4;end
                else begin
                    RTD_sclk <= TC_sclk_3;
                    RTD_sdi  <= TC_sdi_3 ;
                    RTD_cs_n <= TC_cs_n_3;
                    start_10      <= 10'b0000001000;
                    RTD_status <= 10'b0000001000;end
            end
                10'b0000010000 : begin if(stop_single_4) begin
                    RTD_status <= 10'b0000100000;
                    start_10      <= 10'b0000100000;
                    RTD_sclk   <= TC_sclk_5;
                    RTD_sdi    <= TC_sdi_5 ;
                    RTD_cs_n   <= TC_cs_n_5;end
                else begin
                    RTD_sclk <= TC_sclk_4;
                    RTD_sdi  <= TC_sdi_4 ;
                    RTD_cs_n <= TC_cs_n_4;
                    start_10      <= 10'b0000010000;
                    RTD_status <= 10'b0000010000;end
            end
                10'b0000100000 : begin if(stop_single_5) begin
                    RTD_status <= 10'b0001000000;
                    start_10      <= 10'b0001000000;
                    RTD_sclk   <= TC_sclk_6;
                    RTD_sdi    <= TC_sdi_6 ;
                    RTD_cs_n   <= TC_cs_n_6;end
                else begin
                    RTD_sclk <= TC_sclk_5;
                    RTD_sdi  <= TC_sdi_5 ;
                    RTD_cs_n <= TC_cs_n_5;
                    start_10      <= 10'b0000100000;
                    RTD_status <= 10'b0000100000;end
            end
                10'b0001000000 : begin if(stop_single_6) begin
                    RTD_status <= 10'b0010000000;
                    start_10      <= 10'b0010000000;
                    RTD_sclk   <= TC_sclk_7;
                    RTD_sdi    <= TC_sdi_7 ;
                    RTD_cs_n   <= TC_cs_n_7;end
                else begin
                    RTD_sclk <= TC_sclk_6;
                    RTD_sdi  <= TC_sdi_6 ;
                    RTD_cs_n <= TC_cs_n_6;
                    start_10      <= 10'b0001000000;
                    RTD_status <= 10'b0001000000;end
            end
                10'b0010000000 : begin if(stop_single_7) begin
                    RTD_status <= 10'b0100000000;
                    start_10      <= 10'b0100000000;
                    RTD_sclk   <= TC_sclk_8;
                    RTD_sdi    <= TC_sdi_8 ;
                    RTD_cs_n   <= TC_cs_n_8;end
                else begin
                    RTD_sclk <= TC_sclk_7;
                    RTD_sdi  <= TC_sdi_7 ;
                    RTD_cs_n <= TC_cs_n_7;
                    start_10      <= 10'b0010000000;
                    RTD_status <= 10'b0010000000;end
                end
                10'b0100000000 : begin if(stop_single_8) begin
                    RTD_status <= 10'b0000000000;
                    start_10      <= 10'b1000000000;
                    RTD_sclk   <= TC_sclk_9;
                    RTD_sdi    <= TC_sdi_9 ;
                    RTD_cs_n   <= TC_cs_n_9;end
                else begin
                    RTD_sclk <= TC_sclk_8;
                    RTD_sdi  <= TC_sdi_8 ;
                    RTD_cs_n <= TC_cs_n_8;
                    start_10      <= 10'b0100000000;
                    RTD_status <= 10'b0100000000;end
                end
            endcase
        end 
        
  always@(posedge PL_clk)
  begin
  //delay 1
  wr_en_0_dy <= wr_en_0;
  wr_en_1_dy <= wr_en_1;
  wr_en_2_dy <= wr_en_2;
  wr_en_3_dy <= wr_en_3;
  wr_en_4_dy <= wr_en_4;
  wr_en_5_dy <= wr_en_5;
  wr_en_6_dy <= wr_en_6;
  wr_en_7_dy <= wr_en_7;
  wr_en_8_dy <= wr_en_8;
  wr_en_9_dy <= wr_en_9;
  //delay 2
  wr_en_0_dy1 <= wr_en_0_dy;
  wr_en_1_dy1 <= wr_en_1_dy;
  wr_en_2_dy1 <= wr_en_2_dy;
  wr_en_3_dy1 <= wr_en_3_dy;
  wr_en_4_dy1 <= wr_en_4_dy;
  wr_en_5_dy1 <= wr_en_5_dy;
  wr_en_6_dy1 <= wr_en_6_dy;
  wr_en_7_dy1 <= wr_en_7_dy;
  wr_en_8_dy1 <= wr_en_8_dy;
  wr_en_9_dy1 <= wr_en_9_dy;  
  //delay 3
  wr_en_0_dy2 <= wr_en_0_dy1;
  wr_en_1_dy2 <= wr_en_1_dy1;
  wr_en_2_dy2 <= wr_en_2_dy1;
  wr_en_3_dy2 <= wr_en_3_dy1;
  wr_en_4_dy2 <= wr_en_4_dy1;
  wr_en_5_dy2 <= wr_en_5_dy1;
  wr_en_6_dy2 <= wr_en_6_dy1;
  wr_en_7_dy2 <= wr_en_7_dy1;
  wr_en_8_dy2 <= wr_en_8_dy1;
  wr_en_9_dy2 <= wr_en_9_dy1;  
  end
  
  always @(posedge PL_clk)
  begin
  if(wr_en_0)
  RTD_data <= {8'd1,rdata_0};
  else if(wr_en_1)
  RTD_data <= {8'd2,rdata_1};
  else if(wr_en_2)
  RTD_data <= {8'd3,rdata_2};
  else if(wr_en_3)
  RTD_data <= {8'd4,rdata_3};
  else if(wr_en_4)
  RTD_data <= {8'd5,rdata_4};
  else if(wr_en_5)
  RTD_data <= {8'd6,rdata_5};
  else if(wr_en_6)
  RTD_data <= {8'd7,rdata_6};  
  else if(wr_en_7)
  RTD_data <= {8'd8,rdata_7};  
  else if(wr_en_8)
  RTD_data <= {8'd9,rdata_8};
  else if(wr_en_9)
  RTD_data <= {8'd10,rdata_9};  
  end

    
   AD7124_8_0 AD7124_8_0 (
        .PL_clk       (PL_clk       ),
        .PL_USER_RST_N(rst          ),
        .TC_cs_n      (TC_cs_n_0    ),
        .TC_sclk      (TC_sclk_0    ),
        .TC_sdo       (RTD_sdo      ),
        .TC_sdi       (TC_sdi_0     ),
        .start        (start_10[0]        ),
        .stop_all     (stop_single_0),
        .rdata_0      (data_status_0),
        .rdata_1      (rdata_0      ),
        .wr_en_1      (wr_en_0      )
    );

    AD7124_8_1 AD7124_8_1 (
        .PL_clk       (PL_clk       ),
        .PL_USER_RST_N(rst          ),
        .TC_cs_n      (TC_cs_n_1    ),
        .TC_sclk      (TC_sclk_1    ),
        .TC_sdo       (RTD_sdo      ),
        .TC_sdi       (TC_sdi_1     ),
        .start        (start_10[1] ),
        .stop_all     (stop_single_1),
        .rdata_0      (data_status_1),
        .rdata_1      (rdata_1      ),
        .wr_en_1      (wr_en_1      )
    );

    AD7124_8_2 AD7124_8_2 (
        .PL_clk       (PL_clk       ),
        .PL_USER_RST_N(rst          ),
        .TC_cs_n      (TC_cs_n_2    ),
        .TC_sclk      (TC_sclk_2    ),
        .TC_sdo       (RTD_sdo      ),
        .TC_sdi       (TC_sdi_2     ),
        .start        (start_10[2] ),
        .stop_all     (stop_single_2),
        .rdata_0      (data_status_2),
        .rdata_1      (rdata_2      ),
        .wr_en_1      (wr_en_2      )
    );

    AD7124_8_3 AD7124_8_3 (
        .PL_clk       (PL_clk       ),
        .PL_USER_RST_N(rst          ),
        .TC_cs_n      (TC_cs_n_3    ),
        .TC_sclk      (TC_sclk_3    ),
        .TC_sdo       (RTD_sdo      ),
        .TC_sdi       (TC_sdi_3     ),
        .start        (start_10[3] ),
        .stop_all     (stop_single_3),
        .rdata_0      (data_status_3),
        .rdata_1      (rdata_3      ),
        .wr_en_1      (wr_en_3      )
    );

    AD7124_8_4 AD7124_8_4 (
        .PL_clk       (PL_clk       ),
        .PL_USER_RST_N(rst          ),
        .TC_cs_n      (TC_cs_n_4    ),
        .TC_sclk      (TC_sclk_4    ),
        .TC_sdo       (RTD_sdo      ),
        .TC_sdi       (TC_sdi_4     ),
        .start        (start_10[4] ),
        .stop_all     (stop_single_4),
        .rdata_0      (data_status_4),
        .rdata_1      (rdata_4      ),
        .wr_en_1      (wr_en_4     )
    );

    AD7124_8_5 AD7124_8_5 (
        .PL_clk       (PL_clk       ),
        .PL_USER_RST_N(rst          ),
        .TC_cs_n      (TC_cs_n_5    ),
        .TC_sclk      (TC_sclk_5    ),
        .TC_sdo       (RTD_sdo      ),
        .TC_sdi       (TC_sdi_5     ),
        .start        (start_10[5] ),
        .stop_all     (stop_single_5),
        .rdata_0      (data_status_5),
        .rdata_1      (rdata_5      ),
        .wr_en_1      (wr_en_5      )
    );

    AD7124_8_6 AD7124_8_6 (
        .PL_clk       (PL_clk       ),
        .PL_USER_RST_N(rst          ),
        .TC_cs_n      (TC_cs_n_6    ),
        .TC_sclk      (TC_sclk_6    ),
        .TC_sdo       (RTD_sdo      ),
        .TC_sdi       (TC_sdi_6     ),
        .start        (start_10[6] ),
        .stop_all     (stop_single_6),
        .rdata_0      (data_status_6),
        .rdata_1      (rdata_6      ),
        .wr_en_1      (wr_en_6      )
    );
    AD7124_8_7 AD7124_8_7 (
        .PL_clk       (PL_clk       ),
        .PL_USER_RST_N(rst          ),
        .TC_cs_n      (TC_cs_n_7    ),
        .TC_sclk      (TC_sclk_7    ),
        .TC_sdo       (RTD_sdo      ),
        .TC_sdi       (TC_sdi_7     ),
        .start        (start_10[7] ),
        .stop_all     (stop_single_7),
        .rdata_0      (data_status_7),
        .rdata_1      (rdata_7      ),
        .wr_en_1      (wr_en_7      )
    );
    AD7124_8_8 AD7124_8_8 (
        .PL_clk       (PL_clk       ),
        .PL_USER_RST_N(rst          ),
        .TC_cs_n      (TC_cs_n_8    ),
        .TC_sclk      (TC_sclk_8    ),
        .TC_sdo       (RTD_sdo      ),
        .TC_sdi       (TC_sdi_8     ),
        .start        (start_10[8] ),
        .stop_all     (stop_single_8),
        .rdata_0      (data_status_8),
        .rdata_1      (rdata_8      ),
        .wr_en_1      (wr_en_8      )
    );
    AD7124_8_9 AD7124_8_9 (
        .PL_clk       (PL_clk       ),
        .PL_USER_RST_N(rst          ),
        .TC_cs_n      (TC_cs_n_9    ),
        .TC_sclk      (TC_sclk_9    ),
        .TC_sdo       (RTD_sdo      ),
        .TC_sdi       (TC_sdi_9     ),
        .start        (start_10[9] ),
        .stop_all     (stop_single_9),
        .rdata_0      (data_status_9),
        .rdata_1      (rdata_9      ),
        .wr_en_1      (wr_en_9      )
    );
    
    // ila_2 ila_2 (
    //     .clk    (PL_clk       ),
    //     .probe0 (rst          ),
    //     .probe1 (start        ),
    //     .probe2 (RTD_sdo      ),
    //     .probe3 (RTD_cs_n     ),
    //     .probe4 (RTD_sclk     ),
    //     .probe5 (RTD_sdi     ),
    //     .probe6 (TC_sclk_0    ),
    //     .probe7 (TC_sdi_0     ),
    //     .probe8 (TC_cs_n_0    ),
    //     .probe9 (TC_sclk_1    ),
    //     .probe10(TC_sdi_1     ),
    //     .probe11(TC_cs_n_1    ),
    //     .probe12(TC_sclk_2    ),
    //     .probe13(TC_sdi_2     ),
    //     .probe14(TC_cs_n_2    ),
    //     .probe15(TC_sclk_3    ),
    //     .probe16(TC_sdi_3     ),
    //     .probe17(TC_cs_n_3    ),
    //     .probe18(TC_sclk_4    ),
    //     .probe19(TC_sdi_4     ),
    //     .probe20(TC_cs_n_4    ),
    //     .probe21(TC_sclk_5    ),
    //     .probe22(TC_sdi_5     ),
    //     .probe23(TC_cs_n_5    ),
    //     .probe24(TC_sclk_6    ),
    //     .probe25(TC_sdi_6     ),
    //     .probe26(TC_cs_n_6    ),
    //     .probe27(TC_sclk_7    ),
    //     .probe28(TC_sdi_7     ),
    //     .probe29(TC_cs_n_7    ),
    //     .probe30(stop_single_0),
    //     .probe31(stop_single_1),
    //     .probe32(stop_single_2),
    //     .probe33(stop_single_3),
    //     .probe34(stop_single_4),
    //     .probe35(stop_single_5),
    //     .probe36(stop_single_6),
    //     .probe37(stop_single_7),
    //     .probe38(stop_single  ),
    //     .probe39(data_status_0),
    //     .probe40(rdata_0      ),
    //     .probe41(data_status_1),
    //     .probe42(rdata_1      ),
    //     .probe43(data_status_2),
    //     .probe44(rdata_2      ),
    //     .probe45(data_status_3),
    //     .probe46(rdata_3      ),
    //     .probe47(data_status_4),
    //     .probe48(rdata_4      ),
    //     .probe49(data_status_5),
    //     .probe50(rdata_5      ),
    //     .probe51(data_status_6),
    //     .probe52(rdata_6      ),
    //     .probe53(data_status_7),
    //     .probe54(rdata_7        ),
    //     .probe55(TC_sclk_8      ),
    //     .probe56(TC_sdi_8       ),
    //     .probe57(TC_cs_n_8      ),
    //     .probe58(TC_sclk_9      ),
    //     .probe59(TC_cs_n_9      ),
    //     .probe60(data_status_8),
    //     .probe61(rdata_8      ),
    //     .probe62(data_status_9),
    //     .probe63(rdata_9      )
    // );
    
endmodule

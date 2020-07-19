`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2020/05/25 18:40:51
// Design Name:
// Module Name: TC_top
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


module ADread_top (
    input            PL_clk ,
    input            rst    ,
    // output           SYNC   ,
    input            start  ,
    input            TC_sdo ,
    output reg [7:0] TC_cs_n,
    output reg       TC_sclk,
    output reg       TC_sdi ,
    output [23:0] TC_data_0,
    output [23:0] TC_data_1,
    output [23:0] TC_data_2,
    output [23:0] TC_data_3,
    output [23:0] TC_data_4,
    output [23:0] TC_data_5,
    output [23:0] TC_data_6,
    output [23:0] TC_data_7,
    output reg [7:0] start_8,
    output stop_all  ,
    output stop_all_1,
    output stop_all_2,
    output stop_all_3,
    output stop_all_4,
    output stop_all_5,
    output stop_all_6,
    output stop_all_7,
    output reg [7:0] TC_status,
    output reg [31:0] TC_data,
    output wr_en
);




    wire       TC_cs_n0    ;
    wire       TC_sclk0    ;
    wire       TC_sdi0     ;
    // wire [7:0] txcnt_loop  ;
    // wire       data_ie_rd_1;
    // wire       data_ie_rd_2;
    // wire       data_ie_rd_3;
    // wire       data_ie_rd_4;
    // wire       data_ie_rd_5;
    // wire       data_ie_rd_6;
    // wire       data_ie_rd_7;

    wire TC_cs_n1;
    wire TC_sclk1;
    wire TC_sdi1 ;

    wire TC_cs_n2;
    wire TC_sclk2;
    wire TC_sdi2 ;

    wire TC_cs_n3;
    wire TC_sclk3;
    wire TC_sdi3 ;

    wire TC_cs_n4;
    wire TC_sclk4;
    wire TC_sdi4 ;

    wire TC_cs_n5;
    wire TC_sclk5;
    wire TC_sdi5 ;

    wire TC_cs_n6;
    wire TC_sclk6;
    wire TC_sdi6 ;

    wire TC_cs_n7;
    wire TC_sclk7;
    wire TC_sdi7 ;
    
//    wire stop_all  ;
//    wire stop_all_1;
//    wire stop_all_2;
//    wire stop_all_3;
//    wire stop_all_4;
//    wire stop_all_5;
//    wire stop_all_6;
//    wire stop_all_7;

    reg [7:0] TC_status = 8'd0;
    
    wire wr_en_0;
    wire wr_en_1;
    wire wr_en_2;
    wire wr_en_3;
    wire wr_en_4;
    wire wr_en_5;
    wire wr_en_6;
    wire wr_en_7;
    
    reg wr_en_0_dy ;
    reg wr_en_1_dy ;
    reg wr_en_2_dy ;
    reg wr_en_3_dy ;
    reg wr_en_4_dy ;
    reg wr_en_5_dy ;
    reg wr_en_6_dy ;
    reg wr_en_7_dy ;
   
    
    assign wr_en = wr_en_0_dy || wr_en_1_dy || wr_en_2_dy || wr_en_3_dy || wr_en_4_dy || wr_en_5_dy || wr_en_6_dy || wr_en_7_dy;
    
    wire wr_en_1_0;
    wire wr_en_1_1;
    wire wr_en_1_2;
    wire wr_en_1_3;
    wire wr_en_1_4;
    wire wr_en_1_5;
    wire wr_en_1_6;
    wire wr_en_1_7;
    
    always@(posedge PL_clk) 
    begin
    wr_en_0_dy <= wr_en_0;
    wr_en_1_dy <= wr_en_1;
    wr_en_2_dy <= wr_en_2;
    wr_en_3_dy <= wr_en_3;
    wr_en_4_dy <= wr_en_4;
    wr_en_5_dy <= wr_en_5;
    wr_en_6_dy <= wr_en_6;
    wr_en_7_dy <= wr_en_7;
    end
    
   always@(posedge PL_clk) 
   begin
   if(wr_en_1_0)
   TC_data <= {8'd1,TC_data_0};
   else if(wr_en_1_1)
    TC_data <= {8'd2,TC_data_1};  
   else if(wr_en_1_2)
    TC_data <= {8'd3,TC_data_2};  
   else if(wr_en_1_3)
    TC_data <= {8'd4,TC_data_3};        
    else if(wr_en_1_4)
    TC_data <= {8'd5,TC_data_4};   
    else if(wr_en_1_5)
    TC_data <= {8'd6,TC_data_5};  
    else if(wr_en_1_6)
    TC_data <= {8'd7,TC_data_6}; 
    else if(wr_en_1_7)
    TC_data <= {8'd8,TC_data_7};  
    end        
//    reg [7:0] start_8;

    // assign SYNC = 1'b1;

    always@(posedge PL_clk,negedge rst)
        if(~rst) begin
            TC_cs_n <= {7'b1111111,TC_cs_n0};
            TC_sclk <= TC_sclk0;
            TC_sdi  <= TC_sdi0;
            TC_status <= 8'b00000000;
            start_8   <= 8'b00000000;
        end
        else if(start) begin
            case(TC_status)
                8'b00000000 : begin if(stop_all) begin
                    TC_cs_n <= {6'b111111,TC_cs_n1,1'b1};
                    TC_sclk <= TC_sclk1;
                    TC_sdi  <= TC_sdi1;
                    start_8   <= 8'b00000010;
                    TC_status <= 8'b00000001;
                    end
                    else begin
                    TC_cs_n <= {7'b1111111,TC_cs_n0};
                    TC_sclk <= TC_sclk0;
                    TC_sdi  <= TC_sdi0;
                    start_8   <= 8'b00000001;
                    TC_status <= 8'b00000000;
                    end
                end
                8'b00000001 : begin if(stop_all_1) begin
                    TC_cs_n <= {5'b11111,TC_cs_n2,2'b11};
                    TC_sclk <= TC_sclk2;
                    TC_sdi  <= TC_sdi2;   
                    start_8   <= 8'b00000100;
                    TC_status <= 8'b00000010;             
                end  
                else begin
                    TC_cs_n <= {6'b111111,TC_cs_n1,1'b1};
                    TC_sclk <= TC_sclk1;
                    TC_sdi  <= TC_sdi1;
                    start_8   <= 8'b00000010;
                    TC_status <= 8'b00000001;                    
                    end
                end
                8'b00000010 : begin if(stop_all_2) begin
                    TC_cs_n <= {4'b1111,TC_cs_n3,3'b111};
                    TC_sclk <= TC_sclk3;
                    TC_sdi  <= TC_sdi3;  
                     start_8   <= 8'b00001000;
                    TC_status  <= 8'b00000100;                                 
                end
                   else begin
                    TC_cs_n <= {5'b11111,TC_cs_n2,2'b11};
                    TC_sclk <= TC_sclk2;
                    TC_sdi  <= TC_sdi2;   
                    start_8   <= 8'b00000100;
                    TC_status <= 8'b00000010;   
                end
                end
                8'b00000100 : begin if(stop_all_3) begin       
                    TC_cs_n <= {3'b111,TC_cs_n4,4'b1111};
                    TC_sclk <= TC_sclk4;
                    TC_sdi  <= TC_sdi4;
                     start_8   <= 8'b00010000;
                    TC_status  <= 8'b00001000;                    
                end
                else begin
                     TC_cs_n <= {4'b1111,TC_cs_n3,3'b111};
                    TC_sclk <= TC_sclk3;
                    TC_sdi  <= TC_sdi3;  
                     start_8   <= 8'b00001000;
                    TC_status  <= 8'b00000100;                    
                end
                end
                8'b00001000 : begin if(stop_all_4) begin
                    TC_cs_n <= {2'b11,TC_cs_n5,5'b11111};
                    TC_sclk <= TC_sclk5;
                    TC_sdi  <= TC_sdi5;
                     start_8   <= 8'b00100000;
                    TC_status  <= 8'b00010000;                       
                    end
                    else begin
                    TC_cs_n <= {3'b111,TC_cs_n4,4'b1111};
                    TC_sclk <= TC_sclk4;
                    TC_sdi  <= TC_sdi4;
                     start_8   <= 8'b00010000;
                    TC_status  <= 8'b00001000;
                end                       
                end
                8'b00010000 : begin if(stop_all_5) begin
                    TC_cs_n <= {1'b1,TC_cs_n6,6'b111111};
                    TC_sclk <= TC_sclk6;
                    TC_sdi  <= TC_sdi6;
                    start_8    <= 8'b01000000;
                    TC_status  <= 8'b00100000;  
                    end
                    else begin
                    TC_cs_n <= {2'b11,TC_cs_n5,5'b11111};
                    TC_sclk <= TC_sclk5;
                    TC_sdi  <= TC_sdi5;
                     start_8   <= 8'b00100000;
                    TC_status  <= 8'b00010000;    
                    end
                end
                8'b00100000 : begin if(stop_all_6) begin
                    TC_cs_n <= {TC_cs_n7,7'b1111111};
                    TC_sclk <= TC_sclk7;
                    TC_sdi  <= TC_sdi7;
                    start_8    <= 8'b10000000;
                    TC_status  <= 8'b01000000;                     
                end
                else begin
                    TC_cs_n <= {1'b1,TC_cs_n6,6'b111111};
                    TC_sclk <= TC_sclk6;
                    TC_sdi  <= TC_sdi6;
                    start_8    <= 8'b01000000;
                    TC_status  <= 8'b00100000;  
                end
                end
                8'b01000000 : begin if(stop_all_7) begin
                    TC_status  <= 8'b00000000;
                end else begin
                    TC_cs_n <= {TC_cs_n7,7'b1111111};
                    TC_sclk <= TC_sclk7;
                    TC_sdi  <= TC_sdi7;
                    start_8    <= 8'b10000000;
                    TC_status  <= 8'b01000000;
                end
                end
            endcase
        end




    AD7124_8_TC_read AD7124_8_0 (
        .PL_clk       (PL_clk      ),
        .PL_USER_RST_N(rst         ),
        .TC_cs_n      (TC_cs_n0    ),
        .TC_sclk      (TC_sclk0    ),
        .TC_sdo       (TC_sdo      ),
        .TC_sdi       (TC_sdi0     ),
        .start        (start_8[0]      ),
//        .txcnt_loop   (txcnt_loop  ),
//        .data_ie_rd_1 (data_ie_rd_1),
//        .data_ie_rd_2 (data_ie_rd_2),
//        .data_ie_rd_3 (data_ie_rd_3),
//        .data_ie_rd_4 (data_ie_rd_4),
//        .data_ie_rd_5 (data_ie_rd_5),
//        .data_ie_rd_6 (data_ie_rd_6),
//        .data_ie_rd_7 (data_ie_rd_7),
        .rdata_1(TC_data_0),
        .stop_all(stop_all),
        .wr_en_1_dy2(wr_en_0),
        .wr_en_1(wr_en_1_0)
        
    );

    AD7124_8_TC_read AD7124_8_1 (
        .PL_clk       (PL_clk      ),
        .PL_USER_RST_N(rst         ),
        .TC_cs_n      (TC_cs_n1    ),
        .TC_sclk      (TC_sclk1    ),
        .TC_sdo       (TC_sdo      ),
        .TC_sdi       (TC_sdi1     ),
        .start        (start_8[1]       ),
        .rdata_1(TC_data_1),
        .stop_all(stop_all_1),
        .wr_en_1_dy2(wr_en_1),
        .wr_en_1(wr_en_1_1) 
    );

    AD7124_8_TC_read AD7124_8_2 (
        .PL_clk       (PL_clk      ),
        .PL_USER_RST_N(rst         ),
        .TC_cs_n      (TC_cs_n2    ),
        .TC_sclk      (TC_sclk2    ),
        .TC_sdo       (TC_sdo      ),
        .TC_sdi       (TC_sdi2     ),
        .start        (start_8[2]       ),
        .rdata_1(TC_data_2),
        .stop_all(stop_all_2),
        .wr_en_1_dy2(wr_en_2),
        .wr_en_1(wr_en_1_2) 
    );

    AD7124_8_TC_read AD7124_8_3 (
        .PL_clk       (PL_clk      ),
        .PL_USER_RST_N(rst         ),
        .TC_cs_n      (TC_cs_n3    ),
        .TC_sclk      (TC_sclk3    ),
        .TC_sdo       (TC_sdo      ),
        .TC_sdi       (TC_sdi3     ),
        .start        (start_8[3]       ),
        .rdata_1(TC_data_3),
        .stop_all(stop_all_3),
        .wr_en_1_dy2(wr_en_3),
        .wr_en_1(wr_en_1_3) 
    );

    AD7124_8_TC_read AD7124_8_4 (
        .PL_clk       (PL_clk      ),
        .PL_USER_RST_N(rst         ),
        .TC_cs_n      (TC_cs_n4    ),
        .TC_sclk      (TC_sclk4    ),
        .TC_sdo       (TC_sdo      ),
        .TC_sdi       (TC_sdi4     ),
        .start        (start_8[4]       ),
        .rdata_1(TC_data_4),
        .stop_all(stop_all_4),
        .wr_en_1_dy2(wr_en_4),
        .wr_en_1(wr_en_1_4) 
    );

    AD7124_8_TC_read AD7124_8_5 (
        .PL_clk       (PL_clk      ),
        .PL_USER_RST_N(rst         ),
        .TC_cs_n      (TC_cs_n5    ),
        .TC_sclk      (TC_sclk5    ),
        .TC_sdo       (TC_sdo      ),
        .TC_sdi       (TC_sdi5     ),
        .start        (start_8[5]       ),
        .rdata_1(TC_data_5),
        .stop_all(stop_all_5),
        .wr_en_1_dy2(wr_en_5),
        .wr_en_1(wr_en_1_5) 
    );

    AD7124_8_TC_read AD7124_8_6 (
        .PL_clk       (PL_clk      ),
        .PL_USER_RST_N(rst         ),
        .TC_cs_n      (TC_cs_n6    ),
        .TC_sclk      (TC_sclk6    ),
        .TC_sdo       (TC_sdo      ),
        .TC_sdi       (TC_sdi6     ),
        .start        (start_8[6]       ),
        .rdata_1(TC_data_6),
        .stop_all(stop_all_6),
        .wr_en_1_dy2(wr_en_6),
        .wr_en_1(wr_en_1_6) 
    );

    AD7124_8_TC_read AD7124_8_7 (
        .PL_clk       (PL_clk      ),
        .PL_USER_RST_N(rst         ),
        .TC_cs_n      (TC_cs_n7    ),
        .TC_sclk      (TC_sclk7    ),
        .TC_sdo       (TC_sdo      ),
        .TC_sdi       (TC_sdi7     ),
        .start        (start_8[7]       ),
        .txcnt_loop   (txcnt_loop  ),
        .rdata_1(TC_data_7),
        .stop_all(stop_all_7),
        .wr_en_1_dy2(wr_en_7),
        .wr_en_1(wr_en_1_7) 
    );
endmodule

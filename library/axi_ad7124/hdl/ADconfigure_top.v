`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2020/05/13 15:42:56
// Design Name:
// Module Name: ADconfigure_top
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


module ADconfigure_top (
    input            PL_clk          ,
    input            rst             ,
    output reg [7:0] TC_cs_n         ,
    output reg       TC_sclk         ,
    output reg       TC_sdi          ,
    input      [3:0] configure_select,
    input      [7:0] start           , //启动AD配置信号，只能有1位为1，且配置结束后要变为全0，PS端对其初始值应该设为全0
    output     [7:0] F_configure_stop  //反馈给PS端的信号，表示已经配置结束，PS端读到此状态后开启之后AD的启动配置信号，也只有1位能为1,由start控制，当start为0时对应F_stop为0
);//查询F_configure_stop状态的时间应该大于80us小于120us，就说超过120us即算是配置失败，需要重新配置，重新配置也需要start从0到1

    wire F_stop_0;
    wire F_stop_1;
    wire F_stop_2;
    wire F_stop_3;
    wire F_stop_4;
    wire F_stop_5;
    wire F_stop_6;
    wire F_stop_7;

    wire TC_cs_n0;
    wire TC_sclk0;
    wire TC_sdi0 ;

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


    assign F_configure_stop = {F_stop_7,F_stop_6,F_stop_5,F_stop_4,F_stop_3,F_stop_2,F_stop_1,F_stop_0};

    always@(posedge PL_clk,negedge rst) begin
        if(~rst) begin
            TC_cs_n <= {8'b11111111};
            TC_sclk <= TC_sclk0;
            TC_sdi  <= TC_sdi0;
        end
        else begin
            case(start)
                8'b00000000 : begin
                    TC_cs_n <= {8'b11111111};
                    TC_sclk <= TC_sclk0;
                    TC_sdi  <= TC_sdi0;
                end
                8'b00000001 : begin
                    TC_cs_n <= {7'b1111111,TC_cs_n0};
                    TC_sclk <= TC_sclk0;
                    TC_sdi  <= TC_sdi0;
                end
                8'b00000010 : begin
                    TC_cs_n <= {6'b111111,TC_cs_n1,1'b1};
                    TC_sclk <= TC_sclk1;
                    TC_sdi  <= TC_sdi1;
                end
                8'b00000100 : begin
                    TC_cs_n <= {5'b11111,TC_cs_n2,2'b11};
                    TC_sclk <= TC_sclk2;
                    TC_sdi  <= TC_sdi2;
                end
                8'b00001000 : begin
                    TC_cs_n <= {4'b1111,TC_cs_n3,3'b111};
                    TC_sclk <= TC_sclk3;
                    TC_sdi  <= TC_sdi3;
                end
                8'b00010000 : begin
                    TC_cs_n <= {3'b111,TC_cs_n4,4'b1111};
                    TC_sclk <= TC_sclk4;
                    TC_sdi  <= TC_sdi4;
                end
                8'b00100000 : begin
                    TC_cs_n <= {2'b11,TC_cs_n5,5'b11111};
                    TC_sclk <= TC_sclk5;
                    TC_sdi  <= TC_sdi5;
                end
                8'b01000000 : begin
                    TC_cs_n <= {1'b1,TC_cs_n6,6'b111111};
                    TC_sclk <= TC_sclk6;
                    TC_sdi  <= TC_sdi6;
                end
                8'b10000000 : begin
                    TC_cs_n <= {TC_cs_n7,7'b111111};
                    TC_sclk <= TC_sclk7;
                    TC_sdi  <= TC_sdi7;
                end
            endcase;
        end
    end


    AD7124_configure AD7124_configure_0 (
        .PL_clk          (PL_clk          ),
        .rst             (rst             ),
        .TC_cs_n         (TC_cs_n0        ),
        .TC_sclk         (TC_sclk0        ),
        .TC_sdi          (TC_sdi0         ),
        .configure_select(configure_select),
        .start           (start[0]        ),
        .F_stop_address  (F_stop_0        )
    );

    AD7124_configure AD7124_configure_1 (
        .PL_clk          (PL_clk          ),
        .rst             (rst             ),
        .TC_cs_n         (TC_cs_n1        ),
        .TC_sclk         (TC_sclk1        ),
        .TC_sdi          (TC_sdi1         ),
        .configure_select(configure_select),
        .start           (start[1]        ),
        .F_stop_address  (F_stop_1        )
    );

    AD7124_configure AD7124_configure_2 (
        .PL_clk          (PL_clk          ),
        .rst             (rst             ),
        .TC_cs_n         (TC_cs_n2        ),
        .TC_sclk         (TC_sclk2        ),
        .TC_sdi          (TC_sdi2         ),
        .configure_select(configure_select),
        .start           (start[2]        ),
        .F_stop_address  (F_stop_2        )
    );

    AD7124_configure AD7124_configure_3 (
        .PL_clk          (PL_clk          ),
        .rst             (rst             ),
        .TC_cs_n         (TC_cs_n3        ),
        .TC_sclk         (TC_sclk3        ),
        .TC_sdi          (TC_sdi3         ),
        .configure_select(configure_select),
        .start           (start[3]        ),
        .F_stop_address  (F_stop_3        )
    );

    AD7124_configure AD7124_configure_4 (
        .PL_clk          (PL_clk          ),
        .rst             (rst             ),
        .TC_cs_n         (TC_cs_n4        ),
        .TC_sclk         (TC_sclk4        ),
        .TC_sdi          (TC_sdi4         ),
        .configure_select(configure_select),
        .start           (start[4]        ),
        .F_stop_address  (F_stop_4        )
    );

    AD7124_configure AD7124_configure_5 (
        .PL_clk          (PL_clk          ),
        .rst             (rst             ),
        .TC_cs_n         (TC_cs_n5        ),
        .TC_sclk         (TC_sclk5        ),
        .TC_sdi          (TC_sdi5         ),
        .configure_select(configure_select),
        .start           (start[5]        ),
        .F_stop_address  (F_stop_5        )
    );

    AD7124_configure AD7124_configure_6 (
        .PL_clk          (PL_clk          ),
        .rst             (rst             ),
        .TC_cs_n         (TC_cs_n6        ),
        .TC_sclk         (TC_sclk6        ),
        .TC_sdi          (TC_sdi6         ),
        .configure_select(configure_select),
        .start           (start[6]        ),
        .F_stop_address  (F_stop_6        )
    );

    AD7124_configure AD7124_configure_7 (
        .PL_clk          (PL_clk          ),
        .rst             (rst             ),
        .TC_cs_n         (TC_cs_n7        ),
        .TC_sclk         (TC_sclk7        ),
        .TC_sdi          (TC_sdi7         ),
        .configure_select(configure_select),
        .start           (start[7]        ),
        .F_stop_address  (F_stop_7        )
    );


endmodule

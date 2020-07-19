`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2020/05/27 22:30:42
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


module TC_top (
    input             PL_clk           ,
    input             rst              ,
    input             TC_sdo           ,
    output reg [7:0]  TC_cs_n         ,
    output reg       TC_sclk          ,
    output reg       TC_sdi           ,
    output            wr_en           ,
    output    [31:0]  TC_data         ,
    input             start_rd        ,
   input  [3:0]       configure_select,
   input  [7:0]       start_configure ,
   output [7:0]       F_configure_stop
);


    wire [7:0] TC_cs_n_rd;
    wire       TC_sclk_rd;
    wire       TC_sdi_rd ;

    wire [7:0] TC_cs_n_fig;
    wire       TC_sclk_fig;
    wire       TC_sdi_fig ;


//    wire [3:0] configure_select;
//    wire [7:0] start_configure ;
//    wire [7:0] F_configure_stop;

//    wire start_rd;

    wire [ 7:0] start_8  ;
wire stop_all  ;
wire stop_all_1;
wire stop_all_2;
wire stop_all_3;
wire stop_all_4;
wire stop_all_5;
wire stop_all_6;
wire stop_all_7;
wire [7:0] TC_status;

    wire [23:0] TC_data_0   ;
    wire [23:0] TC_data_1   ;
    wire [23:0] TC_data_2   ;
    wire [23:0] TC_data_3   ;
    wire [23:0] TC_data_4   ;
    wire [23:0] TC_data_5   ;
    wire [23:0] TC_data_6   ;
    wire [23:0] TC_data_7   ;
    

    always @(posedge PL_clk or negedge rst)
        if(~rst) begin
            TC_sclk <= TC_sclk_rd;
            TC_cs_n <= TC_cs_n_rd;
            TC_sdi  <= TC_sdi_rd;
        end
        else if(|start_configure) begin
            TC_sclk <= TC_sclk_fig;
            TC_cs_n <= TC_cs_n_fig;
            TC_sdi  <= TC_sdi_fig ;
        end
        else if(start_rd) begin
            TC_sclk <= TC_sclk_rd;
            TC_cs_n <= TC_cs_n_rd;
            TC_sdi  <= TC_sdi_rd ;
        end



//    vio_0 vio_0 (
//        .clk       (PL_clk          ),
//        .probe_out0(configure_select),
//        .probe_out1(start_configure ),
//        .probe_out2(SYNC            ),
//        .probe_out3(start_rd        ),
//        .probe_out4(G1_Relay_Ctrl   )
//    );

//    ila_2 ila_2 (
//        .clk    (PL_clk          ),
//        .probe0 (configure_select),
//        .probe1 (start_configure ),
//        .probe2 (SYNC            ),
//        .probe3 (start_rd        ),
//        .probe4 (TC_cs_n_rd      ),
//        .probe5 (TC_sclk_rd      ),
//        .probe6 (TC_sdi_rd       ),
//        .probe7 (TC_cs_n_fig     ),
//        .probe8 (TC_sclk_fig     ),
//        .probe9 (TC_sdi_fig      ),
//        .probe10(TC_sdo          ),
//        .probe11(stop_all      ),
//        .probe12(stop_all      ),
//        .probe13(stop_all_1    ),
//        .probe14(stop_all_2    ),
//        .probe15(stop_all_3    ),
//        .probe16(stop_all_4    ),
//        .probe17(stop_all_5    ),
//        .probe18(stop_all_6    ),
//        .probe19(TC_data_0       ),
//        .probe20(TC_data_1       ),
//        .probe21(TC_data_2       ),
//        .probe22(TC_data_3       ),
//        .probe23(TC_data_4       ),
//        .probe24(TC_data_5       ),
//        .probe25(TC_data_6       ),
//        .probe26(TC_data_7       ),
//        .probe27(stop_all_7),
//        .probe28(TC_status)
//    );

    ADread_top ADread_top (
        .PL_clk      (PL_clk      ),
        .rst         (rst         ),
        .start       (start_rd    ),
        .TC_sdo      (TC_sdo      ),
        .TC_cs_n     (TC_cs_n_rd  ),
        .TC_sclk     (TC_sclk_rd  ),
        .TC_sdi      (TC_sdi_rd   ),
        .start_8  (start_8  ),
        .stop_all  (stop_all  ),
        .stop_all_1(stop_all_1),
        .stop_all_2(stop_all_2),
        .stop_all_3(stop_all_3),
        .stop_all_4(stop_all_4),
        .stop_all_5(stop_all_5),
        .stop_all_6(stop_all_6),
        .stop_all_7(stop_all_7),  
        .TC_status (TC_status),      
        .TC_data_0   (TC_data_0   ),
        .TC_data_1   (TC_data_1   ),
        .TC_data_2   (TC_data_2   ),
        .TC_data_3   (TC_data_3   ),
        .TC_data_4   (TC_data_4   ),
        .TC_data_5   (TC_data_5   ),
        .TC_data_6   (TC_data_6   ),
        .TC_data_7   (TC_data_7   ),
        .TC_data     (TC_data     ),
        .wr_en       (wr_en       )
    );



    ADconfigure_top ADconfigure_top (
        .PL_clk          (PL_clk          ),
        .rst             (rst             ),
        .TC_cs_n         (TC_cs_n_fig     ),
        .TC_sclk         (TC_sclk_fig     ),
        .TC_sdi          (TC_sdi_fig      ),
        .configure_select(configure_select),
        .start           (start_configure ),
        .F_configure_stop(F_configure_stop)
    );



endmodule

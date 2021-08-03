// File: cfr_branch.sv
// Brief: CFR for one branch (two antenna)

`timescale 1ns / 1ps `default_nettype none

module cfr_branch #(
    parameter int ID              = 0 ,
    parameter int DATA_WIDTH      = 16,
    parameter int CPW_ADDR_WIDTH  = 8 ,
    parameter int CPW_DATA_WIDTH  = 16
) (
    // Data Interface
    //---------------
    input  var                      clk                           ,
    input  var                      rst                           ,
    // Data input
    input  var [    DATA_WIDTH-1:0] data_i_in                     ,
    input  var [    DATA_WIDTH-1:0] data_q_in                     ,
    // Data output
    output var [    DATA_WIDTH-1:0] data_i_out                    ,
    output var [    DATA_WIDTH-1:0] data_q_out                    ,
    // Control Interface
    //------------------
    input  var                      ctrl_clk                      ,
    input  var                      ctrl_rst                      ,
    //
    input  var                      ctrl_pc_cfr_enable            ,
    input  var [      DATA_WIDTH:0] ctrl_pc_cfr_clipping_threshold,
    input  var [      DATA_WIDTH:0] ctrl_pc_cfr_detect_threshold  ,
    //
    input  var [CPW_ADDR_WIDTH-1:0] ctrl_pc_cfr_cpw_addr          ,
    input  var                      ctrl_pc_cfr_cpw_en            ,
    input  var                      ctrl_pc_cfr_cpw_we            ,
    output var [CPW_DATA_WIDTH-1:0] ctrl_pc_cfr_cpw_rd_data_i     ,
    output var [CPW_DATA_WIDTH-1:0] ctrl_pc_cfr_cpw_rd_data_q     ,
    input  var [CPW_DATA_WIDTH-1:0] ctrl_pc_cfr_cpw_wr_data_i     ,
    input  var [CPW_DATA_WIDTH-1:0] ctrl_pc_cfr_cpw_wr_data_q     ,
    //
    input  var                      ctrl_hc_enable                ,
    input  var [      DATA_WIDTH:0] ctrl_hc_threshold
);


    logic [DATA_WIDTH-1:0] data_i_s;
    logic [DATA_WIDTH-1:0] data_q_s;


    pc_cfr #(
        .DATA_WIDTH    (DATA_WIDTH    ),
        .CPW_ADDR_WIDTH(CPW_ADDR_WIDTH),
        .CPW_DATA_WIDTH(CPW_DATA_WIDTH)
    ) i_pc_cfr (
        // Data Interface
        //---------------
        .clk                    (clk                           ),
        .rst                    (rst                           ),
        // Data input
        .data_i_in              (data_i_in                     ),
        .data_q_in              (data_q_in                     ),
        // Data output
        .data_i_out             (data_i_s                      ),
        .data_q_out             (data_q_s                      ),
        // Control Interface
        //------------------
        .ctrl_clk               (ctrl_clk                      ),
        .ctrl_rst               (ctrl_rst                      ),
        //
        .ctrl_enable            (ctrl_pc_cfr_enable            ),
        .ctrl_clipping_threshold(ctrl_pc_cfr_clipping_threshold),
        .ctrl_pd_threshold      (ctrl_pc_cfr_detect_threshold  ),
        //
        .ctrl_cpw_addr          (ctrl_pc_cfr_cpw_addr          ),
        .ctrl_cpw_en            (ctrl_pc_cfr_cpw_en            ),
        .ctrl_cpw_we            (ctrl_pc_cfr_cpw_we            ),
        .ctrl_cpw_rd_data_i     (ctrl_pc_cfr_cpw_rd_data_i     ),
        .ctrl_cpw_rd_data_q     (ctrl_pc_cfr_cpw_rd_data_q     ),
        .ctrl_cpw_wr_data_i     (ctrl_pc_cfr_cpw_wr_data_i     ),
        .ctrl_cpw_wr_data_q     (ctrl_pc_cfr_cpw_wr_data_q     )
    );


    cfr_hardclipping #(.DATA_WIDTH(DATA_WIDTH)) i_cfr_hardclipping (
        .clk           (clk              ),
        .rst           (rst              ),
        //
        .data_i_in     (data_i_s         ),
        .data_q_in     (data_q_s         ),
        //
        .data_i_out    (data_i_out       ),
        .data_q_out    (data_q_out       ),
        //
        .ctrl_enable   (ctrl_hc_enable   ),
        .ctrl_threshold(ctrl_hc_threshold)
    );

endmodule

`default_nettype wire

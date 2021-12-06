// File: cfr.sv
// Brief: CFR Top module

`timescale 1 ns / 1 ps `default_nettype none

module cfr #(
    parameter int CSR            = 2,
    parameter int UP_FACTOR      = 2,
    parameter int DATA_WIDTH     = 16,
    parameter int NUM_CPG        = 6,
    parameter int CPW_ADDR_WIDTH = 8,
    parameter int CPW_DATA_WIDTH = 16,
    parameter int NUM_BRANCH     = 2
) (
    // Data Interface
    //---------------
    input var                       clk,
    input var                       rst,
    // Data input
    input var  [    DATA_WIDTH-1:0] data_i_in                     [NUM_BRANCH],
    input var  [    DATA_WIDTH-1:0] data_q_in                     [NUM_BRANCH],
    input var                       data_valid_in,
    input var                       data_sof_in,
    input var                       data_sop_in,
    // Data output
    output var [    DATA_WIDTH-1:0] data_i_out                    [NUM_BRANCH],
    output var [    DATA_WIDTH-1:0] data_q_out                    [NUM_BRANCH],
    output var                      data_valid_out,
    output var                      data_sof_out,
    output var                      data_sop_out,
    // Control Interface
    //------------------
    input var                       ctrl_clk,
    input var                       ctrl_rst,
    //
    input var                       ctrl_pc_cfr_enable            [NUM_BRANCH],
    input var  [               3:0] ctrl_pc_cfr_spacing           [NUM_BRANCH],
    input var  [      DATA_WIDTH:0] ctrl_pc_cfr_clipping_threshold[NUM_BRANCH],
    input var  [      DATA_WIDTH:0] ctrl_pc_cfr_detect_threshold  [NUM_BRANCH],
    //
    input var  [CPW_ADDR_WIDTH-1:0] ctrl_pc_cfr_cpw_addr          [NUM_BRANCH],
    input var                       ctrl_pc_cfr_cpw_en            [NUM_BRANCH],
    input var                       ctrl_pc_cfr_cpw_we            [NUM_BRANCH],
    output var [CPW_DATA_WIDTH-1:0] ctrl_pc_cfr_cpw_rd_data_i     [NUM_BRANCH],
    output var [CPW_DATA_WIDTH-1:0] ctrl_pc_cfr_cpw_rd_data_q     [NUM_BRANCH],
    input var  [CPW_DATA_WIDTH-1:0] ctrl_pc_cfr_cpw_wr_data_i     [NUM_BRANCH],
    input var  [CPW_DATA_WIDTH-1:0] ctrl_pc_cfr_cpw_wr_data_q     [NUM_BRANCH],
    //
    input var                       ctrl_hc_enable                [NUM_BRANCH],
    input var  [      DATA_WIDTH:0] ctrl_hc_threshold             [NUM_BRANCH]
);


  generate
    for (genvar i = 0; i < NUM_BRANCH; i++) begin : g_branch

      cfr_branch #(
          .ID            (i),
          .CSR           (CSR),
          .UP_FACTOR     (UP_FACTOR),
          .DATA_WIDTH    (DATA_WIDTH),
          .NUM_CPG       (NUM_CPG),
          .CPW_ADDR_WIDTH(CPW_ADDR_WIDTH),
          .CPW_DATA_WIDTH(CPW_DATA_WIDTH)
      ) i_cfr_branch (
          .clk                           (clk),
          .rst                           (rst),
          //
          .data_i_in                     (data_i_in[i]),
          .data_q_in                     (data_q_in[i]),
          //
          .data_i_out                    (data_i_out[i]),
          .data_q_out                    (data_q_out[i]),
          //
          .ctrl_clk                      (ctrl_clk),
          .ctrl_rst                      (ctrl_rst),
          //
          .ctrl_pc_cfr_enable            (ctrl_pc_cfr_enable[i]),
          .ctrl_pc_cfr_spacing           (ctrl_pc_cfr_spacing[i]),
          .ctrl_pc_cfr_clipping_threshold(ctrl_pc_cfr_clipping_threshold[i]),
          .ctrl_pc_cfr_detect_threshold  (ctrl_pc_cfr_detect_threshold[i]),
          //
          .ctrl_pc_cfr_cpw_addr          (ctrl_pc_cfr_cpw_addr[i]),
          .ctrl_pc_cfr_cpw_en            (ctrl_pc_cfr_cpw_en[i]),
          .ctrl_pc_cfr_cpw_we            (ctrl_pc_cfr_cpw_we[i]),
          .ctrl_pc_cfr_cpw_rd_data_i     (ctrl_pc_cfr_cpw_rd_data_i[i]),
          .ctrl_pc_cfr_cpw_rd_data_q     (ctrl_pc_cfr_cpw_rd_data_q[i]),
          .ctrl_pc_cfr_cpw_wr_data_i     (ctrl_pc_cfr_cpw_wr_data_i[i]),
          .ctrl_pc_cfr_cpw_wr_data_q     (ctrl_pc_cfr_cpw_wr_data_q[i]),
          //
          .ctrl_hc_enable                (ctrl_hc_enable[i]),
          .ctrl_hc_threshold             (ctrl_hc_threshold[i])
      );

    end
  endgenerate

  reg_pipeline #(
      .DATA_WIDTH     (3),
      .PIPELINE_STAGES(211 + 23)
  ) i_reg_pipeline (
      .clk (clk),
      .din ({data_sof_in, data_sop_in, data_valid_in}),
      .dout({data_sof_out, data_sop_out, data_valid_out})
  );

endmodule

`default_nettype wire

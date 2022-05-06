`timescale 1 ns / 1 ps `default_nettype none
module ul_adaptor_gearbox_bfp9 #(
    parameter int NUM_CC = 2
) (
    input var         clk,
    input var         rst,
    //
    input var         ul_radio_start_10ms,
    input var         ul_update            [NUM_CC],
    // AXIS
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    input var         m_axis_tready,
    // FIFO
    input var  [23:0] fram_req_data,
    input var         fram_req_empty,
    output var        fram_req_rden,
    // URAM
    output var [11:0] uram_addr            [NUM_CC],
    output var        uram_rden            [NUM_CC],
    input var  [71:0] uram_data            [NUM_CC]
);


  logic [71:0] re_data;
  logic [ 2:0] re_cnt;
  logic        re_valid;
  logic        re_done;

  logic [ 3:0] comp_exp;
  logic [35:0] comp_mantissa;
  logic [ 3:0] comp_cnt;
  logic        comp_valid;
  logic        comp_done;

  // URAM Reader
  //------------

  (* keep_hierarchy="yes" *)
  ul_adaptor_gearbox_bfp9_reader #(
      .NUM_CC(NUM_CC)
  ) i_reader (
      .clk                  (clk),
      .rst                  (rst),
      //
      .ul_radio_start_10ms  (ul_radio_start_10ms),
      .ul_update            (ul_update),
      // FIFO
      .fram_req_data        (fram_req_data),
      .fram_req_empty       (fram_req_empty),
      .fram_req_rden        (fram_req_rden),
      // URAM
      .uram_addr            (uram_addr),
      .uram_rden            (uram_rden),
      .uram_data            (uram_data),
      //
      .re_data              (re_data),
      .re_cnt               (re_cnt),
      .re_valid             (re_valid),
      .re_done              (re_done)
  );

  // BFP9 Compression
  //-----------------

  (* keep_hierarchy="yes" *)
  ul_adaptor_gearbox_bfp9_comp i_comp (
      .clk          (clk),
      .rst          (rst),
      //
      .re_data      (re_data),
      .re_cnt       (re_cnt),
      .re_valid     (re_valid),
      .re_done      (re_done),
      //
      .comp_exp     (comp_exp),
      .comp_mantissa(comp_mantissa),
      .comp_cnt     (comp_cnt),
      .comp_valid   (comp_valid),
      .comp_done    (comp_done)
  );

  // AXIS FSM
  //---------
  // Write 7-word (24 REs) or 3.5-word (12 REs) to AXI-Stream interface

  (* keep_hierarchy="yes" *)
  ul_adaptor_gearbox_bfp9_axis i_axis (
      .clk          (clk),
      .rst          (rst),
      //
      .comp_exp     (comp_exp),
      .comp_mantissa(comp_mantissa),
      .comp_cnt     (comp_cnt),
      .comp_valid   (comp_valid),
      .comp_done    (comp_done),
      // AXIS
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tkeep (m_axis_tkeep),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tready(m_axis_tready)
  );

endmodule

`default_nettype wire

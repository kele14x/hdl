// file: srs_adaptor_controller_req.sv
// brief: Forward necessary SRS C-Plane message to next module as SRS
//        configuration.
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_controller_run (
    // 400M
    //======
    input var                   clk_400m,
    input var                   rst_400m,
    // SRS Request
    input var  [          15:0] srs_req_rtc_pc_id,
    input var  [           3:0] srs_req_cc,
    input var  [          11:0] srs_req_symbol,
    input var  [           7:0] srs_req_numprbc,
    input var  [           9:0] srs_req_startprbc,
    input var  [          11:0] srs_req_sectionid,
    input var  [           3:0] srs_req_ethport,
    input var                   srs_req_valid,
    output var                  srs_req_ready,
    // Frame Request
    output var [ 2:0] fram_req_eth_port,
    output var [63:0] fram_req_header,
    output var [ 8:0] fram_req_start_rb,
    output var [ 7:0] fram_req_num_rb,
    output var        fram_req_valid,
    input var         fram_req_ready,
    // DFE
    //====
    input var         clk_491m52,
    input var         rst_491m52,
    //
    input var  [21:0] srs_data,  // {4E, 9Q, 9I}
    input var         srs_valid,
    input var         srs_sop,
    input var         srs_eop,
    // SRS Request
    output var [ 3:0] dfe_req_cc,
    output var [ 5:0] dfe_req_layer,
    output var [11:0] dfe_req_symbol,
    output var        dfe_req_valid
);


  typedef enum int { S_IDLE, S_REQ, S_DATA, S_FRAM } state_t;

  state_t state, state_next;


  always_ff @ (posedge clk_400m) begin
    if (rst_400m) begin
      state <= S_IDLE;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    case(state) begin
      S_IDLE: state_next = srs_req_valid ? S_REQ : S_IDLE;
      S_REQ:  state_next = S_DATA;
      S_DATA: state_next = srs_eop : S_FRAM : S_DATA;
      S_FRAM: state_next = fram_req_ready ?
    end
  end

endmodule

`default_nettype wire

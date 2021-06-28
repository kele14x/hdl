// file: srs_adaptor_controller_req.sv
// brief: Forward necessary SRS C-Plane message to next module as SRS
//        configuration.
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_controller_scheduler #(
    parameter int ADDR_WIDTH = 10,
    parameter int DATA_WIDTH = 71,
    parameter int NUM_CC = 2
) (
    // 400M
    //======
    input var                   clk,
    input var                   rst,
    // UL Timing
    input var  [          11:0] s_ul_sym_num     [NUM_CC],
    input var                   s_ul_update      [NUM_CC],
    // SRS Message Buffer
    output var [ADDR_WIDTH-1:0] rd_addr,
    output var                  rd_en,
    output var                  rd_clr,
    input var  [DATA_WIDTH-1:0] rd_data,
    // SRS Runner
    output var [          15:0] srs_run_rtc_pc_id,
    output var [           3:0] srs_run_cc,
    output var [          11:0] srs_run_symbol,
    output var [           7:0] srs_run_numprbc,
    output var [           9:0] srs_run_startprbc,
    output var [          11:0] srs_run_sectionid,
    output var [           3:0] srs_run_ethport,
    output var                  srs_run_valid,
    input var                   srs_run_ready
);

  logic s_ul_update_ored;

  logic process_it, do_another_round;

  logic [15:0] srs_rtc_pc_id;
  logic [ 3:0] srs_cc;
  logic [11:0] srs_symbol;
  logic [ 3:0] srs_numsymbol;
  logic [ 7:0] srs_numprbc;
  logic [ 9:0] srs_startprbc;
  logic [11:0] srs_sectionid;
  logic [ 3:0] srs_ethport;
  logic        srs_valid;

  assign {
    srs_valid,
    srs_rtc_pc_id,
    srs_cc,
    srs_symbol,
    srs_numsymbol,
    srs_numprbc,
    srs_startprbc,
    srs_sectionid,
    srs_ethport
  } = rd_data;

  typedef enum int {
    S_IDLE,
    S_ADDR,
    S_DATA,
    S_CLR,
    S_VALID,
    S_NEXT
  } state_t;

  state_t state, next_state;

  logic [ 3:0] current_cc;
  logic [ 5:0] current_layer;
  logic [11:0] current_symbol[NUM_CC];

  // FSM
  //====

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_IDLE;
    end else begin
      state <= next_state;
    end
  end


  always_comb begin
    case (state)
      S_IDLE: next_state = s_ul_update_ored ? S_ADDR : S_IDLE;
      S_ADDR: next_state = S_DATA;
      S_DATA: next_state = process_it ? S_VALID : S_NEXT;
      S_VALID: next_state = srs_run_ready ? S_CLR : S_VALID;
      S_CLR: next_state = S_NEXT;
      S_NEXT:
      next_state = ~(rd_addr == {ADDR_WIDTH{1'b1}}) ? S_ADDR : do_another_round ? S_ADDR : S_IDLE;
      default: next_state = S_IDLE;
    endcase
  end



  // Read Interface
  //===============

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_en <= 1'b0;
    end else begin
      rd_en <= (next_state == S_ADDR || next_state == S_CLR);
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_addr <= '1;
    end else if (next_state == S_ADDR) begin
      rd_addr <= rd_addr + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_clr <= 1'b0;
    end else begin
      rd_clr <= (next_state == S_CLR);
    end
  end

  // Which Symbol to Process
  //========================

  always_comb begin
    s_ul_update_ored = 1'b0;
    for (int i = 0; i < NUM_CC; i++) begin
      if (s_ul_update[i]) begin
        s_ul_update_ored = 1'b1;
        break;
      end
    end
  end

  assign process_it = srs_valid && (current_cc == srs_cc) &&
    (current_layer == srs_rtc_pc_id[5:0]) &&
    (current_symbol[current_cc] >= srs_symbol) &&
    (current_symbol[current_cc] <= srs_symbol + srs_numsymbol - 1);

  always_comb begin
    do_another_round = 1'b0;
    if (current_cc < NUM_CC || current_layer < 64) begin
      do_another_round = 1'b1;
    end
    for (int i = 0; i < NUM_CC; i++) begin
      if (current_symbol[i] < s_ul_sym_num[i]) begin
        do_another_round = 1'b1;
        break;
      end
    end
  end

  // We need to loop every CC, every layer and every symbol and compare it with
  // SRS C-Plane message to decide whether we need to reply a packet. The loop
  // sequence is firstly layer, then CC, then symbol.

  // Current layer
  always_ff @(posedge clk) begin
    if (s_ul_update_ored && state == S_IDLE) begin
      current_layer <= '0;
    end else if (state == S_NEXT && &rd_addr) begin
      current_layer <= current_layer + 1;
    end
  end

  // Current CC
  always_ff @(posedge clk) begin
    if (s_ul_update_ored && state == S_IDLE) begin
      current_cc <= '0;
    end else if (state == S_NEXT && (&rd_addr) && (&current_layer)) begin
      current_cc <= (current_cc == (NUM_CC - 1)) ? 0 : current_cc + 1;
    end
  end

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin
      // Current symbol
      always_ff @(posedge clk) begin
        if (s_ul_update_ored && state == S_IDLE) begin
          current_symbol[i] <= s_ul_sym_num[i];
        end else if (state == S_NEXT && (&rd_addr) && (&current_layer) && current_cc == i) begin
          current_symbol[i] <= current_symbol[i] + 1;
        end
      end
    end
  endgenerate



  // Output
  //=======

  always_ff @(posedge clk) begin
    if (state == S_DATA && process_it) begin
      srs_run_rtc_pc_id <= srs_rtc_pc_id;
      srs_run_cc        <= srs_cc;
      srs_run_symbol    <= srs_symbol;
      srs_run_numprbc   <= srs_numprbc;
      srs_run_startprbc <= srs_startprbc;
      srs_run_sectionid <= srs_sectionid;
      srs_run_ethport   <= srs_ethport;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      srs_run_valid <= 1'b0;
    end else begin
      srs_run_valid <= (next_state == S_VALID);
    end
  end

endmodule

`default_nettype wire

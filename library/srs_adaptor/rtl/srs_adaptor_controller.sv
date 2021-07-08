`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_controller #(
    parameter int NUM_CC = 2
) (
    // XORIF
    //======
    input var         clk,
    input var         rst,
    // UL Timing
    input var  [11:0] s_ul_sym_num      [NUM_CC],
    input var         s_ul_update       [NUM_CC],
    // SRS Mux
    input var  [15:0] srs_mux_rtc_pc_id,
    input var  [ 2:0] srs_mux_cc,
    //
    input var  [ 7:0] srs_mux_frameid,
    input var  [ 3:0] srs_mux_subframeid,
    input var  [ 5:0] srs_mux_slotid,
    input var  [ 5:0] srs_mux_symbolid,
    input var  [11:0] srs_mux_symbol,              // 0 ~ 559
    //
    input var  [ 3:0] srs_mux_numsymbol,           // 1 ~ 3 
    input var  [ 7:0] srs_mux_numprbc,             // 0 ~ 275
    input var  [ 9:0] srs_mux_startprbc,           // 0 ~ 275
    input var  [11:0] srs_mux_sectionid,
    //
    input var  [ 2:0] srs_mux_ethport,             // 0 ~ 3
    //
    input var         srs_mux_valid,
    // Runner
    //=======
    output var [15:0] srs_run_rtc_pc_id,
    output var [ 2:0] srs_run_cc,
    //
    output var [ 7:0] srs_run_frameid,
    output var [ 3:0] srs_run_subframeid,
    output var [ 5:0] srs_run_slotid,
    output var [ 5:0] srs_run_symbolid,
    output var [11:0] srs_run_symbol,
    //
    output var [ 7:0] srs_run_numprbc,
    output var [ 9:0] srs_run_startprbc,
    output var [11:0] srs_run_sectionid,
    //
    output var [ 3:0] srs_run_ethport,
    //
    output var        srs_run_valid,
    output var        srs_run_ready
);


  // Signals
  //========

  // SRS messages are buffered in registers
  // Each CC have one buffer, which means one section

  logic [15:0] srs_buf_rtc_pc_id [NUM_CC];
  //
  logic [ 7:0] srs_buf_frameid   [NUM_CC];
  logic [ 3:0] srs_buf_subframeid[NUM_CC];
  logic [ 5:0] srs_buf_slotid    [NUM_CC];
  logic [ 5:0] srs_buf_symbolid  [NUM_CC];
  logic [11:0] srs_buf_symbol    [NUM_CC];  // 0 ~ 559
  //
  logic [ 3:0] srs_buf_numsymbol [NUM_CC];  // 1 ~ 3
  logic [ 7:0] srs_buf_numprbc   [NUM_CC];  // 0 ~ 275
  logic [ 9:0] srs_buf_startprbc [NUM_CC];  // 0 ~ 275
  logic [11:0] srs_buf_sectionid [NUM_CC];
  //
  logic [ 2:0] srs_buf_ethport   [NUM_CC];  // 0 ~ 3
  //
  logic        srs_buf_valid     [NUM_CC];


  logic        s_ul_update_ored;

  logic process_it, do_another_round;

  typedef enum int {
    S_IDLE,
    S_CHK,
    S_VALID,
    S_NEXT
  } state_t;

  state_t state, next_state;

  logic [ 2:0] current_cc;
  logic [ 5:0] current_layer;
  logic [11:0] current_symbol[NUM_CC];




  // Buffer
  //=======

  always_ff @(posedge clk) begin
    if (rst) begin
      srs_buf_valid <= '{NUM_CC{1'b0}};
    end else if (srs_mux_valid) begin
      srs_buf_valid[srs_mux_cc] <= 1'b1;
      // TODO: unvalid switch
    end
  end

  always_ff @(posedge clk) begin
    if (srs_mux_valid) begin
      srs_buf_rtc_pc_id[srs_mux_cc]  <= srs_mux_rtc_pc_id;
      //
      srs_buf_frameid[srs_mux_cc]    <= srs_mux_frameid;
      srs_buf_subframeid[srs_mux_cc] <= srs_mux_subframeid;
      srs_buf_slotid[srs_mux_cc]     <= srs_mux_slotid;
      srs_buf_symbolid[srs_mux_cc]   <= srs_mux_symbolid;
      srs_buf_symbol[srs_mux_cc]     <= srs_mux_symbol;
      //
      srs_buf_numsymbol[srs_mux_cc]  <= srs_mux_numsymbol;
      srs_buf_numprbc[srs_mux_cc]    <= srs_mux_numprbc;
      srs_buf_startprbc[srs_mux_cc]  <= srs_mux_startprbc;
      srs_buf_sectionid[srs_mux_cc]  <= srs_mux_sectionid;
      //
      srs_buf_ethport[srs_mux_cc]    <= srs_mux_ethport;
    end
  end


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
      S_IDLE:  next_state = s_ul_update_ored ? S_CHK : S_IDLE;
      S_CHK:   next_state = process_it ? S_VALID : S_NEXT;
      S_VALID: next_state = srs_run_ready ? S_NEXT : S_VALID;
      S_NEXT:  next_state = do_another_round ? S_VALID : S_IDLE;
      default: next_state = S_IDLE;
    endcase
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

  assign process_it = srs_buf_valid[current_cc] && 
    (current_symbol[current_cc] >= srs_buf_symbol[current_cc]) &&
    (current_symbol[current_cc] <= srs_buf_symbol[current_cc] + srs_buf_numsymbol[current_cc] - 1);

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
    end else if (state == S_NEXT) begin
      current_layer <= current_layer + 1;
    end
  end

  // Current CC
  always_ff @(posedge clk) begin
    if (s_ul_update_ored && state == S_IDLE) begin
      current_cc <= '0;
    end else if (state == S_NEXT && (&current_layer)) begin
      current_cc <= (current_cc == (NUM_CC - 1)) ? 0 : current_cc + 1;
    end
  end

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin
      // Current symbol
      always_ff @(posedge clk) begin
        if (s_ul_update_ored && state == S_IDLE) begin
          current_symbol[i] <= s_ul_sym_num[i];
        end else if (state == S_NEXT && (&current_layer) && current_cc == i) begin
          current_symbol[i] <= current_symbol[i] + 1;
        end
      end
    end
  endgenerate


  // Output
  //=======

  always_ff @(posedge clk) begin
    if ((state == S_CHK && process_it) || (state == S_NEXT && do_another_round)) begin
      srs_run_rtc_pc_id  <= {srs_buf_rtc_pc_id[current_cc][15:6], current_layer};
      srs_run_cc         <= current_cc;
      //
      srs_run_frameid    <= srs_buf_frameid[current_cc];
      srs_run_subframeid <= srs_buf_subframeid[current_cc];
      srs_run_slotid     <= srs_buf_slotid[current_cc];
      srs_run_symbolid   <= srs_buf_symbolid[current_cc];
      srs_run_symbol     <= current_symbol[current_cc];
      //
      srs_run_numprbc    <= srs_buf_numprbc[current_cc];
      srs_run_startprbc  <= srs_buf_startprbc[current_cc];
      srs_run_sectionid  <= srs_buf_sectionid[current_cc];
      //
      srs_run_ethport    <= srs_buf_ethport[current_cc];
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

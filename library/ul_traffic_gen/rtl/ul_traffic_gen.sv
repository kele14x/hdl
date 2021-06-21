// file: ul_traffic_gen.sv
// brief: UL Traffic generator for test
`timescale 1 ns / 1 ps `default_nettype none

module ul_traffic_gen (
    input var         clk,
    input var         rst,
    //
    input var         ul_radio_start_10ms,
    //
    output var        ul_sof_ahead_3,
    output var        ul_sop_ahead_3,
    output var [15:0] ul_data_i,
    output var [15:0] ul_data_q,
    // Control
    input var  [ 1:0] ctrl_numerology
);


  logic ul_radio_start_10ms_d, ul_radio_start_10ms_dd;

  // Count 1 radio frame (10 ms)
  // 10 * 1 * (12 * (4096 * 8 + 288 * 8) + 2 * (4096 * 8 + 320 * 8))
  // 10 * 2 * (12 * (4096 * 4 + 288 * 4) + 2 * (4096 * 4 + 352 * 4))
  // 10 * 4 * (13.5 * (4096 * 2 + 288 * 2) + 0.5 * (4096 * 2 + 416 * 2))
  logic [ 2:0] csr_cnt;  // 0 ~ 7, 0 ~ 3, 0 ~ 1
  logic [11:0] symbol_tick_cnt;  // 0 ~ 4095
  logic [ 8:0] cp_tick_cnt;  // 0 ~ 287, 0 ~ 319, 0 ~ 351, 0 ~ 415
  logic [ 3:0] symbol_cnt;  // 0 ~ 13
  logic [ 1:0] slot_cnt;  // 0, 0 ~ 1, 0 ~ 3
  logic [ 3:0] subframe_cnt;  // 0 ~ 9

  logic [ 2:0] csr_max;
  logic [ 8:0] cp_tick_max;
  logic [ 1:0] slot_max;
  logic        last_tick;

  logic [ 7:0] frame_cnt;  // 0 ~ 255

  logic [11:0] addr;

  typedef enum int {
    S_SYMBOL,
    S_CP
  } state_t;

  state_t state, state_next;


  // Maximum value for some counters
  //================================

  always_comb begin
    if (ctrl_numerology == 1) begin  // Mu = 0, 15 kHz SCS
      csr_max = 7;
    end else if (ctrl_numerology == 0) begin  // Mu = 1, 30 kHz SCS
      csr_max = 3;
    end else begin  // Mu = 2, 60 kHz SCS
      csr_max = 1;
    end
  end

  always_comb begin
    if (ctrl_numerology == 1) begin  // Mu = 0, 15 kHz SCS
      cp_tick_max = (symbol_cnt == 0 || symbol_cnt == 7) ? 319 : 287;
    end else if (ctrl_numerology == 0) begin  // Mu = 1, 30 kHz SCS
      cp_tick_max = (symbol_cnt == 0) ? 351 : 287;
    end else begin  // Mu = 2, 60 kHz SCS
      cp_tick_max = (symbol_cnt == 0 || slot_cnt[0] == 0) ? 415 : 287;
    end
  end

  always_comb begin
    if (ctrl_numerology == 1) begin  // Mu = 0, 15 kHz SCS
      slot_max = 0;
    end else if (ctrl_numerology == 0) begin  // Mu = 1, 30 kHz SCS
      slot_max = 1;
    end else begin  // Mu = 2, 60 kHz SCS
      slot_max = 3;
    end
  end


  // Counters
  //=========

  always_ff @(posedge clk) begin
    ul_radio_start_10ms_d  <= ul_radio_start_10ms;
    ul_radio_start_10ms_dd <= ul_radio_start_10ms_d;
  end

  assign last_tick = (csr_cnt == csr_max && cp_tick_cnt == cp_tick_max &&
    symbol_cnt == 13 && slot_cnt == slot_max && subframe_cnt == 9);

  always_ff @(posedge clk) begin
    if (rst || ul_radio_start_10ms_d) begin
      csr_cnt <= 0;
    end else if (last_tick) begin
      csr_cnt <= csr_cnt;
    end else begin
      csr_cnt <= csr_cnt == csr_max ? 0 : csr_cnt + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst || ul_radio_start_10ms_d) begin
      state <= S_SYMBOL;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    case (state)
      S_SYMBOL: state_next = (symbol_tick_cnt == 4095 && csr_cnt == csr_max) ? S_CP : S_SYMBOL;
      S_CP:
      state_next = (cp_tick_cnt == cp_tick_max && csr_cnt == csr_max && ~last_tick) ? S_SYMBOL : S_CP;
      default: state_next = S_SYMBOL;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst || ul_radio_start_10ms_d) begin
      symbol_tick_cnt <= 0;
    end else if (last_tick) begin
      symbol_tick_cnt <= symbol_tick_cnt;
    end else if (state == S_SYMBOL && csr_cnt == csr_max) begin
      symbol_tick_cnt <= symbol_tick_cnt + 1;
    end else if (state == S_SYMBOL) begin
      symbol_tick_cnt <= symbol_tick_cnt;
    end else begin
      symbol_tick_cnt <= 0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst || ul_radio_start_10ms_d) begin
      cp_tick_cnt <= 0;
    end else if (last_tick) begin
      cp_tick_cnt <= cp_tick_cnt;
    end else if (state == S_CP && csr_cnt == csr_max) begin
      cp_tick_cnt <= cp_tick_cnt == cp_tick_max ? 0 : cp_tick_cnt + 1;
    end else if (state == S_CP) begin
      cp_tick_cnt <= cp_tick_cnt;
    end else begin
      cp_tick_cnt <= 0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst || ul_radio_start_10ms_d) begin
      symbol_cnt <= 0;
    end else if (last_tick) begin
      symbol_cnt <= symbol_cnt;
    end else if (csr_cnt == csr_max && cp_tick_cnt == cp_tick_max) begin
      symbol_cnt <= symbol_cnt == 13 ? 0 : symbol_cnt + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst || ul_radio_start_10ms_d) begin
      slot_cnt <= 0;
    end else if (last_tick) begin
      slot_cnt <= slot_cnt;
    end else if (csr_cnt == csr_max && cp_tick_cnt == cp_tick_max && symbol_cnt == 13) begin
      slot_cnt <= slot_cnt == slot_max ? 0 : slot_cnt + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst || ul_radio_start_10ms_d) begin
      subframe_cnt <= 0;
    end else if (last_tick) begin
      subframe_cnt <= subframe_cnt;
    end else if (csr_cnt == csr_max && cp_tick_cnt == cp_tick_max && symbol_cnt == 13 && slot_cnt == slot_max) begin
      subframe_cnt <= subframe_cnt + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      frame_cnt <= 0;
    end else if (ul_radio_start_10ms_d) begin
      frame_cnt <= frame_cnt + 1;
    end
  end


  // Output
  //=======

  always_ff @(posedge clk) begin
    if (rst) begin
      ul_sof_ahead_3 <= 1'b0;
    end else begin
      ul_sof_ahead_3 <= ul_radio_start_10ms_dd;
    end
  end

  (* keep_hierarchy="yes" *)
  ul_traffic_gen_bram #(
      .ADDR_WIDTH(12),
      .DATA_WIDTH(12),
      .INIT_FILE ("index.mem")
  ) i_tick2addr (
      .clk    (clk),
      .rst    (rst),
      //
      .rd_addr(symbol_tick_cnt),
      .rd_en  (1'b1),
      .rd_data(addr)
  );

  (* keep_hierarchy="yes" *)
  ul_traffic_gen_bram #(
      .ADDR_WIDTH(12),
      .DATA_WIDTH(32),
      .INIT_FILE ("data.mem")
  ) i_data (
      .clk    (clk),
      .rst    (rst),
      //
      .rd_addr(addr),
      .rd_en  (1'b1),
      .rd_data({ul_data_q, ul_data_i})
  );

  always_ff @(posedge clk) begin
    if (rst) begin
      ul_sop_ahead_3 <= 1'b0;
    end else begin
      ul_sop_ahead_3 <= (csr_cnt == 0 && symbol_tick_cnt == 0);
    end
  end

endmodule

`default_nettype none

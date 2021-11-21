// file: srs_adaptor_controller.sv
// brief: This module controls when to run the processing of SRS symbol.
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
    input var  [15:0] srs_gen_rtc_pc_id,
    input var  [ 2:0] srs_gen_cc,
    //
    input var  [ 7:0] srs_gen_frameid,
    input var  [ 3:0] srs_gen_subframeid,
    input var  [ 5:0] srs_gen_slotid,
    input var  [ 5:0] srs_gen_symbolid,
    input var  [11:0] srs_gen_symbol,              // 0 ~ 559
    //
    input var  [ 3:0] srs_gen_numsymbol,           // 1 ~ 3
    input var  [ 7:0] srs_gen_numprbc,             // 0 ~ 275
    input var  [ 9:0] srs_gen_startprbc,           // 0 ~ 275
    input var  [11:0] srs_gen_sectionid,
    //
    input var  [ 2:0] srs_gen_ethport,             // 0 ~ 3
    //
    input var         srs_gen_valid,
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
    output var [ 2:0] srs_run_ethport,
    //
    output var        srs_run_valid,
    input var         srs_run_ready
);


  // Local Parameters
  //=================

  localparam int BufferWidth = 92;


  // Signals
  //========

  // SRS messages are buffered in a distrubution RAM, this enables more
  // flexiable for multi sections.

  logic [            6:0] buffer_wr_addr;
  logic                   buffer_wr_en;
  logic [BufferWidth-1:0] buffer_wr_data;

  logic [            6:0] buffer_rd_addr;
  logic [            2:0] buffer_rd_en;
  logic [BufferWidth-1:0] buffer_rd_data;

  logic [           15:0] srs_buf_rtc_pc_id;
  logic [            2:0] srs_buf_cc;
  //
  logic [            7:0] srs_buf_frameid;
  logic [            3:0] srs_buf_subframeid;
  logic [            5:0] srs_buf_slotid;
  logic [            5:0] srs_buf_symbolid;
  logic [           11:0] srs_buf_symbol;  // 0 ~ 559
  //
  logic [            3:0] srs_buf_numsymbol;  // 1 ~ 3
  logic [            7:0] srs_buf_numprbc;  // 0 ~ 275
  logic [            9:0] srs_buf_startprbc;  // 0 ~ 275
  logic [           11:0] srs_buf_sectionid;
  //
  logic [            2:0] srs_buf_ethport;  // 0 ~ 3
  //
  logic                   srs_buf_valid;

  logic                   srs_buf_valid_mem             [128] = '{128{1'b0}};

  // State Machine

  typedef enum int {
    S_IDLE,
    S_RD,
    S_D1,
    S_D2,
    S_DATA,
    S_CHK,
    S_VALID,
    S_NEXT
  } state_t;

  logic init_cc[NUM_CC];

  logic init_fsm, process_it;

  state_t state, next_state;

  logic [ 2:0] current_cc;
  logic [11:0] current_symbol[NUM_CC];


  // Buffer Writer
  //==============

  assign buffer_wr_data = {
    srs_gen_rtc_pc_id,
    srs_gen_cc,
    srs_gen_frameid,
    srs_gen_subframeid,
    srs_gen_slotid,
    srs_gen_symbolid,
    srs_gen_symbol,
    srs_gen_numsymbol,
    srs_gen_numprbc,
    srs_gen_startprbc,
    srs_gen_sectionid,
    srs_gen_ethport
  };

  assign {
    srs_buf_rtc_pc_id,
    srs_buf_cc,
    srs_buf_frameid,
    srs_buf_subframeid,
    srs_buf_slotid,
    srs_buf_symbolid,
    srs_buf_symbol,
    srs_buf_numsymbol,
    srs_buf_numprbc,
    srs_buf_startprbc,
    srs_buf_sectionid,
    srs_buf_ethport
  } = buffer_rd_data;

  assign buffer_wr_en = srs_gen_valid;

  always_ff @(posedge clk) begin
    if (rst) begin
      buffer_wr_addr <= '0;
    end else if (buffer_wr_en) begin
      buffer_wr_addr <= buffer_wr_addr + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (buffer_wr_en) begin
      srs_buf_valid_mem[buffer_wr_addr] <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      srs_buf_valid <= 1'b0;
    end else if (buffer_rd_en[2]) begin
      srs_buf_valid <= srs_buf_valid_mem[buffer_rd_addr];
    end
  end


  (* keep_hierarchy="yes" *)
  bram_sdp #(
      .ADDR_WIDTH  (7),
      .DATA_WIDTH  (BufferWidth),
      .READ_LATENCY(3)
  ) i_buffer (
      .clka (clk),
      .ena  (buffer_wr_en),
      .wea  (buffer_wr_en),
      .addra(buffer_wr_addr),
      .dina (buffer_wr_data),
      //
      .clkb (clk),
      .enb  (buffer_rd_en),
      .rstb ({3{1'b0}}),
      .addrb(buffer_rd_addr),
      .doutb(buffer_rd_data)
  );


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
      S_IDLE:  next_state = init_fsm ? S_RD : S_IDLE;
      S_RD:    next_state = S_D1;
      S_D1:    next_state = S_D2;
      S_D2:    next_state = S_DATA;
      S_DATA:  next_state = S_CHK;
      S_CHK:   next_state = process_it ? S_VALID : S_NEXT;
      S_VALID: next_state = srs_run_ready ? S_NEXT : S_VALID;
      S_NEXT:  next_state = ~(&buffer_rd_addr) ? S_RD : S_IDLE;
      default: next_state = S_IDLE;
    endcase
  end


  // Which Symbol to Process
  //========================

  // Two CC may required to process at save time
  generate
    for (genvar i = 0; i < NUM_CC; i++) begin
      always_comb begin
        init_cc[i] = (state == S_IDLE) && s_ul_update[i] && (s_ul_sym_num[i] != current_symbol[i]);
      end
    end
  endgenerate

  // We will start of FSM at any CC is required
  always_comb begin
    init_fsm = 1'b0;
    for (int i = 0; i < NUM_CC; i++) begin
      if (init_cc[i]) begin
        init_fsm = 1'b1;
        break;
      end
    end
  end

  // Which CC to process
  always_ff @(posedge clk) begin
    if (rst) begin
      current_cc <= '0;
    end else begin
      for (int i = 0; i < NUM_CC; i++) begin
        if (init_cc[i]) begin
          current_cc <= i;
          break;
        end
      end
    end
  end

  // Which symbol to process
  always_ff @(posedge clk) begin
    if (rst) begin
      current_symbol <= '{NUM_CC{'b0}};
    end else begin
      for (int i = 0; i < NUM_CC; i++) begin
        if (init_cc[i]) begin
          current_symbol[i] <= s_ul_sym_num[i];
          break;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    process_it <= srs_buf_valid && (current_cc == srs_buf_cc) &&
      (current_symbol[current_cc] >= srs_buf_symbol) &&
      (current_symbol[current_cc] <= srs_buf_symbol + srs_buf_numsymbol - 1);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      buffer_rd_addr <= 0;
    end else if (state == S_RD) begin
      buffer_rd_addr <= buffer_rd_addr + 1;
    end
  end

  always_ff @(posedge clk) begin
    buffer_rd_en[0] <= (next_state == S_RD);
    buffer_rd_en[1] <= (next_state == S_D1);
    buffer_rd_en[2] <= (next_state == S_D2);
  end


  // Output
  //=======

  always_ff @(posedge clk) begin
    if (state == S_CHK && process_it) begin
      srs_run_rtc_pc_id  <= srs_buf_rtc_pc_id;
      srs_run_cc         <= srs_buf_cc;
      //
      srs_run_frameid    <= srs_buf_frameid;
      srs_run_subframeid <= srs_buf_subframeid;
      srs_run_slotid     <= srs_buf_slotid;
      srs_run_symbolid   <= srs_buf_symbolid;
      srs_run_symbol     <= srs_buf_symbol;
      //
      srs_run_numprbc    <= srs_buf_numprbc;
      srs_run_startprbc  <= srs_buf_startprbc;
      srs_run_sectionid  <= srs_buf_sectionid;
      //
      srs_run_ethport    <= srs_buf_ethport;
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

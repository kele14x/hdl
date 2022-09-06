// File: fir2_stage.sv
// Brief: Multiplier at each stage for ch_fir module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module fir2_stage #(
    parameter int CSR_SUPPORT    = 16,
    parameter int ADDR_WIDTH     = 4,
    parameter int DATA_WIDTH     = 16,
    parameter int COE_DATA_WIDTH = 16,
    parameter int MAC_DATA_WIDTH = 33
) (
    input var                              clk,
    input var                              rst,
    // State machine sync
    input var                              sync_in,
    output var                             sync_out,
    //
    input var  signed [    DATA_WIDTH-1:0] forward_data_in,
    output var signed [    DATA_WIDTH-1:0] forward_data_out,
    //
    input var  signed [    DATA_WIDTH-1:0] backward_data_in,
    output var signed [    DATA_WIDTH-1:0] backward_data_out,
    //
    input var  signed [MAC_DATA_WIDTH-1:0] mac_data_in,
    output var signed [MAC_DATA_WIDTH-1:0] mac_data_out,
    // Control interface
    //==================
    input var                              ctrl_clk,
    input var                              ctrl_rst,
    //
    input var                              ctrl_loop_back,
    input var                              ctrl_odd_tap,
    //
    input var                              ctrl_coe_en,
    input var                              ctrl_coe_we,
    input var         [    ADDR_WIDTH-1:0] ctrl_coe_addr,
    input var         [COE_DATA_WIDTH-1:0] ctrl_coe_din,
    output var        [COE_DATA_WIDTH-1:0] ctrl_coe_dout
);


  initial begin
    assert ($clog2(CSR_SUPPORT) == ADDR_WIDTH);
  end


  // Signals
  //========

  logic        [    ADDR_WIDTH-1:0] state;

  logic        [    ADDR_WIDTH-1:0] coe_addr;
  logic signed [COE_DATA_WIDTH-1:0] coe_data;

  logic                             fds_we;
  logic        [    ADDR_WIDTH-1:0] fds_addr;
  logic        [    ADDR_WIDTH-1:0] fds_addr_next;
  logic        [    DATA_WIDTH-1:0] fds_din;
  logic signed [    DATA_WIDTH-1:0] fds_dout;
  logic signed [    DATA_WIDTH-1:0] fds_dout_r;

  logic signed [    DATA_WIDTH-1:0] backward_data_s;

  logic                             bds_rst;
  logic                             bds_we;
  logic        [    ADDR_WIDTH-1:0] bds_addr;
  logic        [    ADDR_WIDTH-1:0] bds_addr_next;
  logic        [    DATA_WIDTH-1:0] bds_din;
  logic signed [    DATA_WIDTH-1:0] bds_dout;

  logic                             op;


  // Main
  //=====

  // To utilize the clock frequency to sample rate ratio to save resource, each
  // DSP computes a component of result during serval ticks and accumulate them
  // together. Assume CSR = N, during N clock ticks, one DSP could accumulate
  // N samples. The first DSP calculates x[n-N+1] to x[n], and second DSP
  // calculates x[n-2*N+1] to x[n-N], etc.
  //
  // The samples are provides to MAC in reversed order, this is reduce the
  // input to output latency, since when x[n] is provide in input port, old
  // samples ware already accumulated and ready in DSP.
  //
  // `state` is the counter to manage the internal state and provide control
  // control signals. The state counter counts from (CSR_SUPPORT - 1) to 0.
  //
  // `state == 1` is a special state, at this state it requires new sample from
  // input. At `state == 0`, this new sample will appear on MAC input.
  //
  // Current implementation requires input samples are provide at input
  // at exactly every N ticks (1 sample per N ticks), no early and no late.

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= 1;
    end else if (sync_in) begin
      state <= 0;
    end else if (state == 0) begin
      state <= CSR_SUPPORT - 1;
    end else begin
      state <= state - 1;
    end
  end

  // In fact all DSP share the same the same state. But to reduce the fan out
  // of sync signal, we delay the sync signal for N ticks and pass it to next
  // stage.
  shift_regs #(
      .DATA_WIDTH(1),
      .DEPTH     (CSR_SUPPORT)
  ) i_sync_delay (
      .clk (clk),
      .cen (1'b1),
      //
      .din (sync_in),
      .dout(sync_out)
  );


  // Coefficients store

  // Since forward data was read from memory in a reversed order, coefficients
  // also need to be read out in reversed order. The state counter could be
  // directly used as address. The RAM latency should be 1. This match MAC's
  // B input port latency.
  assign coe_addr = state;

  ram_sdp #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (COE_DATA_WIDTH),
      .READ_LATENCY(1),
      .INIT_WORD   ('0)
  ) i_coe_store (
      .clka (ctrl_clk),
      .ena  (ctrl_coe_en),
      .wea  (ctrl_coe_we),
      .addra(ctrl_coe_addr),
      .dina (ctrl_coe_din),
      //
      .clkb (clk),
      .rstb (1'b0),
      .enb  (1'b1),
      .addrb(coe_addr),
      .doutb(coe_data)
  );


  // Forward data store

  // Forward data (data A of MAC) is buffered in a cyclic buffer (implemented
  // as single port RAM). After one cyclic, one sample will be passed to next
  // stage. This ensures all stages only holds the data it needs and reduce
  // buffer size requirement.

  assign fds_we  = (state == 1);
  assign fds_din = forward_data_in;

  always_ff @(posedge clk) begin
    if (rst) begin
      fds_addr <= '0;
    end else begin
      fds_addr <= fds_addr_next;
    end
  end

  always_comb begin
   if (fds_addr >= CSR_SUPPORT - 2) begin
      fds_addr_next = '0;
    end else begin
      fds_addr_next = fds_addr + 1;
    end
  end

  ram_sp #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .WRITE_MODE  ("WRITE_FIRST"),
      .READ_LATENCY(1),
      .INIT_WORD   ('0)
  ) i_forward_data_store (
      .clk (clk),
      .rst (1'b0),
      .en  (1'b1),
      .we  (fds_we),
      .addr(fds_addr),
      .din (fds_din),
      .dout(fds_dout)
  );

  // For N = 2, RAM output should be directly connect to next stage. For N > 2,
  // we need to buffer the RAM output at `state = N - 1`.

  always_ff @(posedge clk) begin
    if (state == CSR_SUPPORT - 1) begin
      fds_dout_r <= fds_dout;
    end
  end

  always_comb begin
    if (state == CSR_SUPPORT - 1) begin
      forward_data_out = fds_dout;
    end else begin
      forward_data_out = fds_dout_r;
    end
  end


  // Backward data store

  always_comb begin
    if (ctrl_loop_back) begin
      backward_data_s = forward_data_out;
    end else begin
      backward_data_s = backward_data_in;
    end
  end

  assign bds_we  = (state == 0);
  assign bds_din = backward_data_s;

  always_ff @(posedge clk) begin
    if (rst) begin
      bds_addr <= '0;
    end else begin
      bds_addr <= bds_addr_next;
    end
  end

  always_comb begin
    if (state == 1) begin
      bds_addr_next = bds_addr;
    end else if (state == 0 && ctrl_odd_tap) begin
      bds_addr_next = bds_addr;
    end else if (bds_addr == CSR_SUPPORT - 1) begin
      bds_addr_next = 0;
    end else begin
      bds_addr_next = bds_addr + 1;
    end
  end

  always_comb begin
    if (ctrl_odd_tap == 0 || ctrl_loop_back == 0) begin
      bds_rst = 1'b0;
    end else begin
      bds_rst = (state == CSR_SUPPORT - 1);
    end
  end

  ram_sp #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .WRITE_MODE  ("WRITE_FIRST"),
      .READ_LATENCY(1),
      .INIT_WORD   ('0)
  ) i_backward_data_store (
      .clk (clk),
      .rst (bds_rst),
      .en  (1'b1),
      .we  (bds_we),
      .addr(bds_addr),
      .din (bds_din),
      .dout(bds_dout)
  );

  always_ff @(posedge clk) begin
    if (state == 0) begin
      backward_data_out <= bds_dout;
    end
  end


  // MAC

  always_ff @(posedge clk) begin
    op <= (state == 0);
  end

  fir2_mac #(
      .A_WIDTH(DATA_WIDTH),
      .B_WIDTH(COE_DATA_WIDTH),
      .D_WIDTH(DATA_WIDTH),
      .P_WIDTH(MAC_DATA_WIDTH)
  ) i_mac (
      .clk (clk),
      .a   (fds_dout),
      .b   (coe_data),
      .d   (bds_dout),
      .op  (op),
      .pin (mac_data_in),
      .pout(mac_data_out)
  );

endmodule

`default_nettype wire

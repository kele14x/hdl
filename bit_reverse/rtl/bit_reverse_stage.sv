// File: bit_reverse_stage.sv
// Brief: Bit reverse stage for bit_reverse module.
`default_nettype none
//
`timescale 1 ns / 1 ps

module bit_reverse_stage #(
    parameter int IDX_STAGE  = 0,
    parameter int FFT_SIZE   = 4096,
    parameter int DATA_WIDTH = 32
) (
    input var                   clk,
    input var                   rst,
    // Data input
    input var  [DATA_WIDTH-1:0] data_in,
    input var                   data_valid_in,
    input var                   data_last_in,
    // Data output
    output var [DATA_WIDTH-1:0] data_out,
    output var                  data_valid_out,
    output var                  data_last_out
);

  // Swap x_j and x_k, where:
  //   j = N - 1 - i
  //   k = i
  localparam int LogFftSize = $clog2(FFT_SIZE);
  localparam int NumStage = LogFftSize / 2;
  localparam int DelayTaps = 2 ** (LogFftSize - 1 - IDX_STAGE) - 2 ** IDX_STAGE;
  localparam int Latency = DelayTaps + 1;

  logic                  switch;
  logic                  shift_en;

  logic [DATA_WIDTH+1:0] data_m0;
  logic [DATA_WIDTH+1:0] data_m1;
  logic [DATA_WIDTH+1:0] data_delayed;

  logic [DATA_WIDTH-1:0] data_s;
  logic                  data_valid_s;
  logic                  data_last_s;

  // Each stage has a local counter, which counts from 0 to FFT_SIZE-1. Counter
  // synchronize with `data_in`.
  logic [LogFftSize-1:0] counter;
  // State indicate counter >= 1
  logic                  state;

  // Main
  //=====

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= 'd0;
    end else if (data_valid_in && data_last_in) begin
      counter <= 'd0;
    end else if (data_valid_in) begin
      counter <= counter + 1;
    end else begin
      counter <= counter;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= 1'b0;
    end else if (data_valid_in && data_last_in) begin
      state <= 1'b0;
    end else if (data_valid_in) begin
      state <= 1'b1;
    end else begin
      state <= state;
    end
  end

  // s = x_j and /x_k (2'b10)
  assign switch   = counter[LogFftSize-1-IDX_STAGE] && ~counter[IDX_STAGE];

  assign shift_en = data_valid_in && ~state;

  always_comb begin
    if (switch) begin
      data_m0 = data_delayed;
    end else begin
      data_m0 = {data_last_in, data_valid_in, data_in};
    end
  end

  // D = 2^j - 2^k
  shift_ram #(
      .DEPTH     (DelayTaps),
      .DATA_WIDTH(DATA_WIDTH + 2)
  ) i_delay (
      .clk (clk),
      .rst (rst),
      .cen (shift_en),
      .din (data_m0),
      .dout(data_delayed)
  );

  always_comb begin
    if (switch) begin
      data_m1 = {data_last_in, data_valid_in, data_in};
    end else begin
      data_m1 = data_delayed;
    end
  end

  assign {data_last_s, data_valid_s, data_s} = data_m1;

  // Data output

  always_ff @(posedge clk) begin
    if (data_valid_s && shift_en) begin
      data_out <= data_s;
    end
  end

  always_ff @(posedge clk) begin
    data_valid_out <= data_valid_s && shift_en;
  end

  always_ff @(posedge clk) begin
    data_last_out <= data_last_s;
  end

endmodule

`default_nettype wire

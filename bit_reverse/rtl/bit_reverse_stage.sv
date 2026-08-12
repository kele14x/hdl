`default_nettype none
//
`timescale 1 ns / 1 ps

module bit_reverse_stage #(
    parameter NUM_INLV     = 4,
    parameter IDX_STAGE    = 0,
    parameter LOG_FFT_SIZE = 12,
    parameter DATA_WIDTH   = 16
) (
    input var                                               clk,
    input var                                               rst,
    // Data input
    input var  [                            DATA_WIDTH-1:0] din_dr,
    input var  [                            DATA_WIDTH-1:0] din_di,
    input var  [(NUM_INLV <= 1 ? 1 : $clog2(NUM_INLV))-1:0] din_id,
    input var                                               din_valid,
    input var                                               din_last,
    // Data output
    output var [                            DATA_WIDTH-1:0] dout_dr,
    output var [                            DATA_WIDTH-1:0] dout_di,
    output var [(NUM_INLV <= 1 ? 1 : $clog2(NUM_INLV))-1:0] dout_id,
    output var                                              dout_valid,
    output var                                              dout_last
);

  // Swap x_j and x_k, where:
  //   j = N - 1 - i
  //   k = i
  localparam int DelayTaps = NUM_INLV * (2 ** (LOG_FFT_SIZE - 1 - IDX_STAGE) - 2 ** IDX_STAGE);

  localparam int IdWidth = NUM_INLV <= 1 ? 1 : $clog2(NUM_INLV);
  localparam [31:0] LastIdFull = NUM_INLV - 1;
  localparam [IdWidth-1:0] LastId = LastIdFull[IdWidth-1:0];

  // Each stage has a local counter, which counts from 0 to FFT_SIZE-1. Counter
  // synchronize with `din_dr`.
  logic [        LOG_FFT_SIZE-1:0] counter;

  wire                             switch;

  wire  [2*DATA_WIDTH+IdWidth+1:0] data_m0;
  wire  [2*DATA_WIDTH+IdWidth+1:0] data_m1;
  wire  [2*DATA_WIDTH+IdWidth+1:0] data_delayed;

  wire  [          DATA_WIDTH-1:0] data_dr_s;
  wire  [          DATA_WIDTH-1:0] data_di_s;
  wire  [             IdWidth-1:0] data_id_s;
  wire                             data_valid_s;
  wire                             data_last_s;

  // Main

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= 'd0;
    end else if (din_valid && din_last && din_id == LastId) begin
      counter <= 'd0;
    end else if (din_valid && din_id == LastId) begin
      counter <= counter + 1'd1;
    end else begin
      counter <= counter;
    end
  end

  // s = x_j and /x_k ({x_j, x_k} == 2'b10)
  assign switch  = counter[LOG_FFT_SIZE-1-IDX_STAGE] && ~counter[IDX_STAGE];

  assign data_m0 = switch ? data_delayed : {din_last, din_valid, din_id, din_di, din_dr};

  // D = 2^j - 2^k
  shift_ram #(
      .DEPTH(DelayTaps),
      .WIDTH(2 * DATA_WIDTH + IdWidth + 2)
  ) i_delay (
      .clk (clk),
      .rst (rst),
      .cen (1'b1),
      .din (data_m0),
      .dout(data_delayed)
  );

  assign data_m1 = switch ? {din_last, din_valid, din_id, din_di, din_dr} : data_delayed;

  assign {data_last_s, data_valid_s, data_id_s, data_di_s, data_dr_s} = data_m1;

  // Data output

  always_ff @(posedge clk) begin
    if (data_valid_s) begin
      dout_dr   <= data_dr_s;
      dout_di   <= data_di_s;
      dout_last <= data_last_s;
    end
  end

  always_ff @(posedge clk) begin
    dout_id    <= data_id_s;
    dout_valid <= data_valid_s;
  end

endmodule

`default_nettype wire

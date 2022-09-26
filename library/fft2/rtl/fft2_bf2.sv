// File: fft_bf2.sv
// Brief: Radix-2 Butterfly operator for FFT.
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft2_bf2 #(
    parameter int LOG_SIZE   = 4,
    parameter int DATA_WIDTH = 16
) (
    input var                          clk,
    input var                          rst,
    //
    input var  signed [DATA_WIDTH-1:0] data_i_in,
    input var  signed [DATA_WIDTH-1:0] data_q_in,
    input var                          data_valid_in,
    input var                          data_last_in,
    //
    output var signed [DATA_WIDTH-1:0] data_i_out,
    output var signed [DATA_WIDTH-1:0] data_q_out,
    output var                         data_valid_out,
    output var                         data_last_out
);


  // Signals
  //========

  // Counter count from 0 to LOG_FFT_SIZE - 1
  logic        [  LOG_SIZE-1:0] counter;

  logic                         sel;

  logic                         wr_en;
  logic                         rd_en;
  logic                         empty;


  logic signed [DATA_WIDTH-1:0] data_i_s;
  logic signed [DATA_WIDTH-1:0] data_q_s;
  //
  logic signed [DATA_WIDTH-1:0] delay_i_in;
  logic signed [DATA_WIDTH-1:0] delay_q_in;
  logic                         delay_sel_in;
  logic        [DATA_WIDTH*2:0] delay_in;
  //
  logic signed [DATA_WIDTH-1:0] delay_i_out;
  logic signed [DATA_WIDTH-1:0] delay_q_out;
  logic                         delay_sel_out;
  logic        [DATA_WIDTH*2:0] delay_out;


  // State Counter
  //==============

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= 'd0;
    end else if (data_valid_in && data_last_in) begin
      counter <= 'd0;
    end else if (data_valid_in) begin
      counter <= counter + 1;
    end
  end

  assign sel   = counter[LOG_SIZE-1];

  assign wr_en = data_valid_in;

  always_comb begin
    if (sel == 1'b0) begin
      rd_en = delay_sel_out && !empty;
    end else begin
      rd_en = data_valid_in;
    end
  end


  // Butterfly Operation
  //====================

  // Output to delay path
  always_comb begin
    if (sel) begin
      delay_i_in = delay_i_out - data_i_in;
      delay_q_in = delay_q_out - data_q_in;
    end else begin
      delay_i_in = data_i_in;
      delay_q_in = data_q_in;
    end
  end

  // To (next) BF or output
  always_comb begin
    if (sel) begin
      data_i_s = delay_i_out + data_i_in;
      data_q_s = delay_q_out + data_q_in;
    end else begin
      data_i_s = delay_i_out;
      data_q_s = delay_q_out;
    end
  end

  // Delay

  assign delay_sel_in = sel;

  assign delay_in = {delay_sel_in, delay_q_in, delay_i_in};
  assign {delay_sel_out, delay_q_out, delay_i_out} = delay_out;

  fifo_generator_0 i_fifo (
      .clk        (clk),
      .srst       (rst),
      // Write side
      .din        (delay_in),
      .wr_en      (wr_en),
      .full       (  /* not used */),
      // Read side
      .dout       (delay_out),
      .rd_en      (rd_en),
      .empty      (empty),
      //
      .wr_rst_busy(  /* not used */),
      .rd_rst_busy(  /* not used */)
  );

  // Output register

  always_ff @(posedge clk) begin
    data_i_out     <= data_i_s;
    data_q_out     <= data_q_s;
    data_valid_out <= rd_en;
    data_last_out  <= rd_en && (counter == '1);
  end

endmodule

`default_nettype wire

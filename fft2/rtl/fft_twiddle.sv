
// File: fft_twiddle.v
// Brief: FFT process stage. Each stage includes:
//          - 1 Twiddler (twidder factor ROM and complex multiplier)
//          - 1 Butterfly operator
`timescale 1 ns / 1 ps
//
`default_nettype none

module fft_twiddle #(
    parameter int LOG_SIZE    = 4,
    parameter int DATA_WIDTH  = 16,
    parameter int PHASE_WIDTH = 16
) (
    input var                          clk,
    input var                          rst,
    // Input
    input var  signed [DATA_WIDTH-1:0] data_i_in,
    input var  signed [DATA_WIDTH-1:0] data_q_in,
    input var                          data_valid_in,
    input var                          data_last_in,
    // Output
    output var signed [DATA_WIDTH-1:0] data_i_out,
    output var signed [DATA_WIDTH-1:0] data_q_out,
    output var                         data_valid_out,
    output var                         data_last_out,
    // Status
    output var                         ovf
);


  // Signals
  //========

  // Counter count from 0 to FFT_SIZE - 1
  logic [LOG_SIZE-1:0] counter;

  logic [LOG_SIZE-1:0] twiddle;

  logic signed [DATA_WIDTH-1:0] data_i_s;
  logic signed [DATA_WIDTH-1:0] data_q_s;


  // Main
  //=====

  // Control signal for each stage

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= '0;
    end else if (data_valid_in && data_last_in) begin
      counter <= 'd0;
    end else if (data_valid_in) begin
      counter <= counter + 1;
    end
  end

  wire signed [15:0] twiddle_i_s;
  wire signed [15:0] twiddle_q_s;


  // Twiddle is twiddle factor index
  generate
    if (LOG_SIZE % 2 == 0) begin : g_even_size
      always_comb begin
        twiddle = {counter[LOG_SIZE-2], counter[LOG_SIZE-1]} * counter[LOG_SIZE-3:0];
      end
    end else begin : g_odd_size
      always_comb begin
        twiddle = counter[LOG_SIZE-1] * counter[LOG_SIZE-2:0];
      end
    end
  endgenerate

  delay #(
      .DATA_WIDTH(DATA_WIDTH * 2),
      .DEPTH     (2)
  ) i_data_delay (
      .clk (clk),
      .cen (1'b1),
      //
      .din ({data_q_in, data_i_in}),
      .dout({data_q_s, data_i_s})
  );

  delay #(
      .DATA_WIDTH(2),
      .DEPTH     (10)
  ) i_valid_delay (
      .clk (clk),
      .cen (1'b1),
      //
      .din ({data_last_in, data_valid_in}),
      .dout({data_last_out, data_valid_out})
  );

  fft_twiddle_rom #(
      .TWIDDLE_WIDTH(LOG_SIZE),
      .DATA_WIDTH   (PHASE_WIDTH)
  ) i_twiddle_rom (
      .clk          (clk),
      .rst          (1'b0),
      //
      .en           (1'b1),
      .twiddle      (twiddle),
      //
      .twiddle_i_out(twiddle_i_s),
      .twiddle_q_out(twiddle_q_s)
  );

  cmult #(
      .A_WIDTH (DATA_WIDTH),
      .B_WIDTH (PHASE_WIDTH),
      .P_WIDTH (DATA_WIDTH),
      .SRA_BITS(PHASE_WIDTH - 2)
  ) i_cmult (
      .clk(clk),
      .rst(rst),
      //
      .ar (data_i_s),
      .ai (data_q_s),
      //
      .br (twiddle_i_s),
      .bi (twiddle_q_s),
      //
      .pr (data_i_out),
      .pi (data_q_out),
      //
      .ovf(ovf)
  );

endmodule

`default_nettype wire

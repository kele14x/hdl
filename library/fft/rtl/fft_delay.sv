// File: fft_delay.sv
// Brief: Delay line for FFT.
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft_delay #(
    parameter bit SIM_INIT   = 0,
    parameter int DELAY_TAPS = 8,
    parameter int DATA_WIDTH = 16
) (
    input var                   clk,
    input var                   rst,
    //
    input var  [DATA_WIDTH-1:0] data_i_in,
    input var  [DATA_WIDTH-1:0] data_q_in,
    //
    output var [DATA_WIDTH-1:0] data_i_out,
    output var [DATA_WIDTH-1:0] data_q_out
);

  initial begin
    assert (DELAY_TAPS > 0)
    else begin
      $error("[%m]: Number of delay taps (DELAY_TAPS) must be greater than 0.");
      #1 $finish();
    end
  end

  // Put delay taps on packet domain to infer SRL
  logic [DELAY_TAPS-1:0] data_i_srl[DATA_WIDTH];
  logic [DELAY_TAPS-1:0] data_q_srl[DATA_WIDTH];

  generate
    if (SIM_INIT) begin : g_init
      initial begin
        for (int d = 0; d < DATA_WIDTH; d++) begin
          data_i_srl[d] = {DELAY_TAPS{1'b0}};
          data_q_srl[d] = {DELAY_TAPS{1'b0}};
        end
      end
    end
  endgenerate

  generate
    for (genvar d = 0; d < DATA_WIDTH; d++) begin : g_srl

      always_ff @(posedge clk) begin
        data_i_srl[d][0] <= data_i_in[d];
        data_q_srl[d][0] <= data_q_in[d];
        for (int i = 1; i < DELAY_TAPS; i++) begin
          data_i_srl[d][i] <= data_i_srl[d][i-1];
          data_q_srl[d][i] <= data_q_srl[d][i-1];
        end
      end

      assign data_i_out[d] = data_i_srl[d][DELAY_TAPS-1];
      assign data_q_out[d] = data_q_srl[d][DELAY_TAPS-1];

    end
  endgenerate

endmodule

`default_nettype wire

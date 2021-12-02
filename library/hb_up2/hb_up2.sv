// File: hb_up2.sv
// Brief: Half band up-sample by 2.
`timescale 1 ns / 1 ps `default_nettype none

module hb_up2 #(
    parameter int XIN_WIDTH = 16,
    parameter int COE_WIDTH = 16,
    parameter int NUM_UNIQUE_COE = 5,
    parameter signed [COE_WIDTH-1:0] COE_NUMS[NUM_UNIQUE_COE] = {952, -1609, 3090, -6260, 20622},
    parameter int YOUT_WIDTH = 16,
    parameter int SRA_BITS = 15
) (
    input var  logic                  clk,
    input var  logic                  rst,
    input var  logic [ XIN_WIDTH-1:0] xin,
    output var logic [YOUT_WIDTH-1:0] yout0,
    output var logic [YOUT_WIDTH-1:0] yout1,
    output var logic                  ovf
);

  localparam int RND = (1 <<< (SRA_BITS - 1));
  localparam int Latency = NUM_UNIQUE_COE + 6;

  logic signed [        XIN_WIDTH-1:0] xin_d[NUM_UNIQUE_COE*4];

  logic signed [          XIN_WIDTH:0] adreg[  NUM_UNIQUE_COE];
  logic signed [XIN_WIDTH+COE_WIDTH:0] mreg [  NUM_UNIQUE_COE];
  logic signed [XIN_WIDTH+COE_WIDTH:0] preg [  NUM_UNIQUE_COE];

  // Delay taps, tools can automatically absorb registers into DSP and duplicate
  // registers if needed

  always_ff @(posedge clk) begin
    xin_d[0] <= xin;
    for (int i = 1; i < NUM_UNIQUE_COE * 4; i++) begin
      xin_d[i] <= xin_d[i-1];
    end
  end

  generate
    for (genvar i = 0; i < NUM_UNIQUE_COE; i++) begin : g_dsp

      always_ff @(posedge clk) begin
        adreg[i] <= xin_d[1] + xin_d[NUM_UNIQUE_COE*2-2*i];
        mreg[i]  <= adreg[i] * COE_NUMS[i];
        preg[i]  <= mreg[i] + ((i < NUM_UNIQUE_COE - 1) ? preg[i+1] : RND);
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    yout0 <= xin_d[NUM_UNIQUE_COE+4];
    yout1 <= preg[0][YOUT_WIDTH+SRA_BITS-1:SRA_BITS];
  end

  generate
    if (YOUT_WIDTH + SRA_BITS >= XIN_WIDTH + COE_WIDTH + 1) begin : g_no_ovf

      // Output is full width, no overflow will happen
      assign ovf = 'b0;

    end else begin : g_ovf

      always_ff @(posedge clk) begin
        ovf <= ~(&preg[0][XIN_WIDTH+COE_WIDTH:YOUT_WIDTH+SRA_BITS-1] ||
                 &(~preg[0][XIN_WIDTH+COE_WIDTH:YOUT_WIDTH+SRA_BITS-1]));
      end

    end
  endgenerate

endmodule

`default_nettype wire

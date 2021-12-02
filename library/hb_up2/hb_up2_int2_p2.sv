// File: hb_up2.sv
// Brief: Half band up-sample by 2. Interleaved 2 channels.

`timescale 1 ns / 1 ps `default_nettype none

module hb_up2_int2_p2 #(
    parameter int XIN_WIDTH = 16,
    parameter int COE_WIDTH = 16,
    parameter int NUM_UNIQUE_COE = 5,
    parameter signed [COE_WIDTH-1:0] COE_NUMS[NUM_UNIQUE_COE] = {952, -1609, 3090, -6260, 20622},
    parameter int YOUT_WIDTH = 16,
    parameter int SRA_BITS = 15
) (
    input var  logic                  clk,
    input var  logic                  rst,
    input var  logic [ XIN_WIDTH-1:0] xin0,
    input var  logic [ XIN_WIDTH-1:0] xin1,
    output var logic [YOUT_WIDTH-1:0] yout0,
    output var logic [YOUT_WIDTH-1:0] yout1,
    output var logic [YOUT_WIDTH-1:0] yout2,
    output var logic [YOUT_WIDTH-1:0] yout3,
    output var logic                  ovf
);


  localparam int RND = (1 <<< (SRA_BITS - 1));
  localparam int BASE = ((NUM_UNIQUE_COE) / 2) +
    (((NUM_UNIQUE_COE) % 2) != 0) + 1; // ceil(N/2) + 1
  localparam int TAPS = BASE*4+NUM_UNIQUE_COE*2 > BASE*4+6 ?
    BASE*4+NUM_UNIQUE_COE*2 : BASE*4+6;

  localparam int Latency = (BASE * 4 + 5) / 2 + 2;

  logic signed [        XIN_WIDTH-1:0] xin_d [          TAPS];

  logic signed [          XIN_WIDTH:0] adreg0[NUM_UNIQUE_COE];
  logic signed [XIN_WIDTH+COE_WIDTH:0] mreg0 [NUM_UNIQUE_COE];
  logic signed [XIN_WIDTH+COE_WIDTH:0] preg0 [NUM_UNIQUE_COE];

  logic signed [          XIN_WIDTH:0] adreg1[NUM_UNIQUE_COE];
  logic signed [XIN_WIDTH+COE_WIDTH:0] mreg1 [NUM_UNIQUE_COE];
  logic signed [XIN_WIDTH+COE_WIDTH:0] preg1 [NUM_UNIQUE_COE];

  // Delay taps, tools can automatically absorb registers into DSP and duplicate
  // registers if needed
  always_ff @(posedge clk) begin
    xin_d[0] <= xin1;
    xin_d[1] <= xin0;
    for (int i = 2; i < TAPS; i++) begin
      xin_d[i] <= xin_d[i-2];
    end
  end

  function automatic int x_idx(input int ith, input int stage);
    begin
      int ret;
      ret = BASE * 2 - ith - 1;  // time index
      ret = (ret / 2) * 4 + (ret % 2) + 2;
      ret = ret - stage * 2;  // data index
      return ret;
    end
  endfunction

  generate
    for (genvar s = 0; s < NUM_UNIQUE_COE; s++) begin : g_dsp

      always_ff @(posedge clk) begin
        adreg0[s] <= xin_d[x_idx(s-NUM_UNIQUE_COE+1, s)] + xin_d[x_idx(-s+NUM_UNIQUE_COE, s)];
        mreg0[s]  <= adreg0[s] * COE_NUMS[s];
        preg0[s]  <= mreg0[s] + ((s < NUM_UNIQUE_COE - 1) ? preg0[s+1] : RND);
      end

      always_ff @(posedge clk) begin
        adreg1[s] <= xin_d[x_idx(s-NUM_UNIQUE_COE+2, s)] + xin_d[x_idx(-s+NUM_UNIQUE_COE+1, s)];
        mreg1[s]  <= adreg1[s] * COE_NUMS[s];
        preg1[s]  <= mreg1[s] + ((s < NUM_UNIQUE_COE - 1) ? preg1[s+1] : RND);
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    yout0 <= xin_d[BASE*4+5];
    yout1 <= preg0[0][YOUT_WIDTH+SRA_BITS-1:SRA_BITS];
    yout2 <= xin_d[BASE*4+4];
    yout3 <= preg1[0][YOUT_WIDTH+SRA_BITS-1:SRA_BITS];
  end

  generate
    if (YOUT_WIDTH + SRA_BITS >= XIN_WIDTH + COE_WIDTH + 1) begin : g_no_ovf

      // Output is full width, no overflow will happen
      assign ovf = 'b0;

    end else begin : g_ovf

      always_ff @(posedge clk) begin
        ovf <= ~(&preg0[0][XIN_WIDTH+COE_WIDTH:YOUT_WIDTH+SRA_BITS-1] ||
                 &(~preg0[0][XIN_WIDTH+COE_WIDTH:YOUT_WIDTH+SRA_BITS-1])) ||
               ~(&preg1[0][XIN_WIDTH+COE_WIDTH:YOUT_WIDTH+SRA_BITS-1] ||
                 &(~preg1[0][XIN_WIDTH+COE_WIDTH:YOUT_WIDTH+SRA_BITS-1]));
      end

    end
  endgenerate


endmodule

`default_nettype wire

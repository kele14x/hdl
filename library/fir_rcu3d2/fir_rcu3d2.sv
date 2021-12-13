// File: hb_up2.sv
// Brief: Half band up-sample by 2.

`timescale 1 ns / 1 ps `default_nettype none

module fir_rcu3d2 #(
    parameter int XIN_WIDTH = 16,
    parameter int COE_WIDTH = 16,
    parameter int NUM_UNIQUE_COE = 10,
    parameter signed [COE_WIDTH-1:0] COE_NUMS[NUM_UNIQUE_COE] = {22, 59, -244,
      -427, 1101, 1665, -3566, -5196, 12690, 26660},
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
    output var logic                  ovf
);


  localparam int Latency = NUM_UNIQUE_COE + 2;
  localparam int Base = NUM_UNIQUE_COE + 1;
  localparam int RND = (1 <<< (SRA_BITS - 1));

  logic signed [        XIN_WIDTH-1:0] xin_d[Base*2];

  logic signed [          XIN_WIDTH:0] adreg1[  NUM_UNIQUE_COE];
  logic signed [XIN_WIDTH+COE_WIDTH:0] mreg1 [  NUM_UNIQUE_COE];
  logic signed [XIN_WIDTH+COE_WIDTH:0] preg1 [  NUM_UNIQUE_COE];

  logic signed [          XIN_WIDTH:0] adreg2[  NUM_UNIQUE_COE];
  logic signed [XIN_WIDTH+COE_WIDTH:0] mreg2 [  NUM_UNIQUE_COE];
  logic signed [XIN_WIDTH+COE_WIDTH:0] preg2 [  NUM_UNIQUE_COE];

  // Delay taps, tools can automatically absorb registers into DSP and duplicate
  // registers if needed

  initial begin
    assert(NUM_UNIQUE_COE % 2 == 0)
    else begin
      $error("NUM_UNIQUE_COE should be an even number");
      $finish;
    end
  end

  always_ff @(posedge clk) begin
    xin_d[1] <= xin0;
    xin_d[0] <= xin1;
    for (int i = 1; i < Base; i++) begin
      xin_d[2*i+1] <= xin_d[2*i-1];
      xin_d[2*i]   <= xin_d[2*i-2];
    end
  end

  generate
    for (genvar ii = 0; ii < NUM_UNIQUE_COE; ii++) begin : g_dsp1

      int idx1 = (2*ii < NUM_UNIQUE_COE) ? 2*ii : (2*NUM_UNIQUE_COE - 2*ii - 1);

      always_ff @(posedge clk) begin
        adreg1[ii] <= xin_d[ii+1];
        mreg1[ii]  <= adreg1[ii] * COE_NUMS[idx1];
        preg1[ii]  <= mreg1[ii] + (ii == 0 ? RND : preg1[ii-1]);
      end

    end
  endgenerate

  generate
    for (genvar ii = 0; ii < NUM_UNIQUE_COE; ii++) begin : g_dsp2

      int idx2 = (2*ii < NUM_UNIQUE_COE) ? 2*ii + 1 : (2*NUM_UNIQUE_COE - 2*ii - 2);

      always_ff @(posedge clk) begin
        adreg2[ii] <= xin_d[ii];
        mreg2[ii]  <= adreg2[ii] * COE_NUMS[idx2];
        preg2[ii]  <= mreg2[ii] + (ii == 0 ? RND : preg2[ii-1]);
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    yout0 <= xin_d[2*NUM_UNIQUE_COE+1];
    yout1 <= preg1[NUM_UNIQUE_COE-1][YOUT_WIDTH+SRA_BITS-1:SRA_BITS];
    yout2 <= preg2[NUM_UNIQUE_COE-1][YOUT_WIDTH+SRA_BITS-1:SRA_BITS];
  end

  generate
    if (YOUT_WIDTH + SRA_BITS >= XIN_WIDTH + COE_WIDTH + 1) begin : g_no_ovf

      // Output is full width, no overflow will happen
      assign ovf = 'b0;

    end else begin : g_ovf

      always_ff @(posedge clk) begin
        ovf <= ~(&preg1[0][XIN_WIDTH+COE_WIDTH:YOUT_WIDTH+SRA_BITS-1] ||
                 &(~preg1[0][XIN_WIDTH+COE_WIDTH:YOUT_WIDTH+SRA_BITS-1])) ||
               ~(&preg2[0][XIN_WIDTH+COE_WIDTH:YOUT_WIDTH+SRA_BITS-1] ||
                 &(~preg2[0][XIN_WIDTH+COE_WIDTH:YOUT_WIDTH+SRA_BITS-1]));
      end

    end
  endgenerate

endmodule

`default_nettype wire

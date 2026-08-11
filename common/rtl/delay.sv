`timescale 1 ns / 1 ps
//
`default_nettype none

module delay #(
    parameter int DATA_WIDTH = 8,
    parameter int WIDTH      = DATA_WIDTH,
    parameter int DEPTH      = 8,
    parameter int INIT       = 0
) (
    input  wire             clk,
    input  wire             rst,
    input  wire             cen,
    //
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

  // Check parameters

  // verilog_format: off
  initial begin
    if (DEPTH < 0 || 16384 < DEPTH) begin
      $fatal(1, "Delay depth (DEPTH) must be within the range 0 to 16384, got %d. [%m]", DEPTH);
    end

    if (WIDTH < 1 || 1024 < WIDTH) begin
      $fatal(1, "Data width (WIDTH) must be within the range 1 to 1024, got %d. [%m]", WIDTH);
    end
  end
  // verilog_format: on

  generate
    if (DEPTH == 0) begin : g_no_reg

      wire unused = &{1'b0, clk, rst, cen};

      assign dout = din;

    end else begin : g_regs

      logic [WIDTH-1:0] dregs[0:DEPTH-1];

      initial begin : p_init
        integer i;
        if (INIT != 0) begin
          for (i = 0; i < DEPTH; i = i + 1) begin
            dregs[i] = 'b0;
          end
        end
      end

      always @(posedge clk) begin : p_shift
        integer i;
        if (rst) begin
          for (i = 0; i < DEPTH; i = i + 1) begin
            dregs[i] <= 'b0;
          end
        end else if (cen) begin
          dregs[0] <= din;
          for (i = 1; i < DEPTH; i = i + 1) begin
            dregs[i] <= dregs[i-1];
          end
        end
      end

      assign dout = dregs[DEPTH-1];

    end
  endgenerate

endmodule

`default_nettype wire

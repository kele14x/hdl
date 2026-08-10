`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY="yes" *)
module dds_lut_rom #(
    parameter int STRUCTURE  = 1,
    parameter int RASTERIZED = 0,
    parameter int ADDR_WIDTH = 12,
    parameter int DATA_WIDTH = 16,
    parameter int OUTPUT_REG = 1
) (
    input  wire                  clk,
    //
    input  wire                  rsta,
    input  wire                  ena,
    input  wire [ADDR_WIDTH-1:0] addra,
    output wire [DATA_WIDTH-1:0] douta,
    //
    input  wire                  rstb,
    input  wire                  enb,
    input  wire [ADDR_WIDTH-1:0] addrb,
    output wire [DATA_WIDTH-1:0] doutb
);

  // Local parameters

  localparam int StructureFull = 1;
  localparam int StructureHalf = 2;

  localparam int Factor = STRUCTURE == StructureFull ? 1 : (STRUCTURE == StructureHalf ? 2 : 4);
  localparam int K = (RASTERIZED > 0 ? 3 : 4) * (2 ** ADDR_WIDTH) / 4;

  // Signals

  // The Memory
  logic signed [DATA_WIDTH-1:0] mem     [0:K-1];

  logic signed [DATA_WIDTH-1:0] douta_s;
  logic signed [DATA_WIDTH-1:0] doutb_s;

  initial begin : p_init
    integer i;
    for (i = 0; i < K; i = i + 1) begin
      // The sized real-to-integer cast rounds to the nearest integer. Do not
      // use $rtoi here: it truncates toward zero and biases the LUT values.
      /* verilator lint_off REALCVT */
      mem[i] = (2 ** (DATA_WIDTH - 1) - 2) * $cos(3.141592653589793 * 2 * i / Factor / K);
      /* verilator lint_on REALCVT */
    end
  end

  // Memory port A

  always_ff @(posedge clk) begin
    if (rsta) begin
      douta_s <= '0;
    end else if (ena) begin
      douta_s <= mem[addra];
    end
  end

  // Memory port B

  always_ff @(posedge clk) begin
    if (rstb) begin
      doutb_s <= '0;
    end else if (enb) begin
      doutb_s <= mem[addrb];
    end
  end

  generate
    if (OUTPUT_REG == 0) begin : g_no_reg

      assign douta = douta_s;
      assign doutb = doutb_s;

    end else begin : g_reg

      logic ena_d;
      logic enb_d;

      logic signed [DATA_WIDTH-1:0] douta_r;
      logic signed [DATA_WIDTH-1:0] doutb_r;

      always_ff @(posedge clk) begin
        ena_d <= ena;
        enb_d <= enb;
      end

      always_ff @(posedge clk) begin
        if (rsta) begin
          douta_r <= '0;
        end else if (ena_d) begin
          douta_r <= douta_s;
        end
      end

      always_ff @(posedge clk) begin
        if (rstb) begin
          doutb_r <= '0;
        end else if (enb_d) begin
          doutb_r <= doutb_s;
        end
      end

      assign douta = douta_r;
      assign doutb = doutb_r;

    end
  endgenerate

endmodule

`default_nettype wire

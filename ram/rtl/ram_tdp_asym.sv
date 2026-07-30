/*
 * True Dual Port Asymmetric Memory
 *
 * This module implements a true dual port memory with configurable address and data widths.
 * It supports different write modes and optional output registers for both ports.
 *
 * Read Latency: 1 or 2 (with OUTPUT_REG_A/B) clock cycles
 *
 * Note: rst[0] does not work here
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_tdp_asym #(
    parameter integer ADDR_WIDTH_A = 11,
    parameter integer DATA_WIDTH_A = 16,
    parameter bit     OUTPUT_REG_A = 1'b1,
    parameter string  WRITE_MODE_A = "READ_FIRST",
    //
    parameter integer ADDR_WIDTH_B = 10,
    parameter integer DATA_WIDTH_B = 32,
    parameter bit     OUTPUT_REG_B = 1'b1,
    parameter string  WRITE_MODE_B = "READ_FIRST",
    //
    parameter string  INIT_FILE    = "",
    parameter string  RAM_STYLE    = "AUTO"
) (
    input  wire                    clka,
    input  wire [  OUTPUT_REG_A:0] rsta,
    input  wire [  OUTPUT_REG_A:0] ena,
    input  wire                    wea,
    input  wire [ADDR_WIDTH_A-1:0] addra,
    input  wire [DATA_WIDTH_A-1:0] dina,
    output logic  [DATA_WIDTH_A-1:0] douta,
    //
    input  wire                    clkb,
    input  wire [  OUTPUT_REG_B:0] rstb,
    input  wire [  OUTPUT_REG_B:0] enb,
    input  wire                    web,
    input  wire [ADDR_WIDTH_B-1:0] addrb,
    input  wire [DATA_WIDTH_B-1:0] dinb,
    output logic  [DATA_WIDTH_B-1:0] doutb
);

  // Check parameters

  // verilog_format: off
  initial begin
    if  (WRITE_MODE_A != "WRITE_FIRST" && WRITE_MODE_A != "READ_FIRST" && WRITE_MODE_A != "NO_CHANGE") begin
      $display("Port A write mode (WRITE_MODE_A) should be one of \"WRITE_FIRST\", \"READ_FIRST\", or \"NO_CHANGE\", got \"%s\". [%m]", WRITE_MODE_A);
      $finish();
    end
    if  (WRITE_MODE_B != "WRITE_FIRST" && WRITE_MODE_B != "READ_FIRST" && WRITE_MODE_B != "NO_CHANGE") begin
      $display("Port B write mode (WRITE_MODE_B) should be one of \"WRITE_FIRST\", \"READ_FIRST\", or \"NO_CHANGE\", got \"%s\". [%m]", WRITE_MODE_B);
      $finish();
    end
    if  (RAM_STYLE != "AUTO" && RAM_STYLE != "BLOCK" && RAM_STYLE != "DISTRIBUTED" && RAM_STYLE != "REGISTER" && RAM_STYLE != "ULTRA") begin
      $display("RAM_STYLE should be one of \"AUTO\", \"BLOCK\", \"DISTRIBUTED\", \"REGISTER\", or \"ULTRA\", got \"%s\". [%m]", RAM_STYLE);
      $finish();
    end
  end
  // verilog_format: on

  // Parameters

  localparam integer SizeA = 2 ** ADDR_WIDTH_A;
  localparam integer SizeB = 2 ** ADDR_WIDTH_B;
  localparam integer MaxSize = (SizeA > SizeB) ? SizeA : SizeB;

  localparam integer MaxWidth = (DATA_WIDTH_A > DATA_WIDTH_B) ? DATA_WIDTH_A : DATA_WIDTH_B;
  localparam integer MinWidth = (DATA_WIDTH_A < DATA_WIDTH_B) ? DATA_WIDTH_A : DATA_WIDTH_B;

  localparam integer Ratio = MaxWidth / MinWidth;
  localparam integer Log2Ratio = $clog2(Ratio);

  // Signals

  // The Memory
  /* verilator lint_off MULTIDRIVEN */
  (* RAM_STYLE=RAM_STYLE *)
  logic     [    MinWidth-1:0] mem   [0:MaxSize-1];

  wire                       ena_s;
  wire                       enb_s;
  wire                       unused_inputs;

  logic     [DATA_WIDTH_A-1:0] rega;
  logic     [DATA_WIDTH_B-1:0] regb;

  integer                    init_idx;

  // This makes Vivado recognize correct EN pin
  assign ena_s = ena[0];
  assign enb_s = enb[0];
  assign unused_inputs = ^{rsta[0], ena[OUTPUT_REG_A], rstb[0], enb[OUTPUT_REG_B]};

  // Initialize memory

  initial begin
    for (init_idx = 0; init_idx < MaxSize; init_idx = init_idx + 1) begin
      mem[init_idx] = 'b0;
    end
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end
  end

  // Memory port A

  generate
    if (DATA_WIDTH_A <= DATA_WIDTH_B) begin : g_a_aletb

      // Port A read
      always_ff @(posedge clka) begin
        // TODO: rsta[0] does not work here
        if (ena_s) begin
          if (wea && (WRITE_MODE_A == "WRITE_FIRST")) begin
            rega <= dina;
          end else if (wea && (WRITE_MODE_A == "NO_CHANGE")) begin
            rega <= rega;
          end else begin  // no wea, or write mode is "READ_FIRST"
            rega <= mem[addra];
          end
        end
      end

      // Port A write
      always_ff @(posedge clka) begin
        if (ena_s) begin
          if (wea) begin
            mem[addra] <= dina;
          end
        end
      end

    end else begin : g_a_agtb

      // Port A read
      always @(posedge clka) begin : p_rd
        integer a_rd_idx;
        logic [Log2Ratio-1:0] lsbaddr;
        for (a_rd_idx = 0; a_rd_idx < Ratio; a_rd_idx = a_rd_idx + 1) begin
          lsbaddr = a_rd_idx[Log2Ratio-1:0];
          // TODO: rsta[0] does not work here
          if (ena_s) begin
            if (wea && (WRITE_MODE_A == "WRITE_FIRST")) begin
              rega[(a_rd_idx+1)*MinWidth-1-:MinWidth] <= dina[(a_rd_idx+1)*MinWidth-1-:MinWidth];
            end else if (wea && (WRITE_MODE_A == "NO_CHANGE")) begin
              rega[(a_rd_idx+1)*MinWidth-1-:MinWidth] <= rega[(a_rd_idx+1)*MinWidth-1-:MinWidth];
            end else begin  // no wea, or write mode is "READ_FIRST"
              rega[(a_rd_idx+1)*MinWidth-1-:MinWidth] <= mem[{addra, lsbaddr}];
            end
          end
        end
      end

      // Port A write
      always @(posedge clka) begin : p_wr
        integer a_wr_idx;
        logic [Log2Ratio-1:0] lsbaddr;
        for (a_wr_idx = 0; a_wr_idx < Ratio; a_wr_idx = a_wr_idx + 1) begin
          lsbaddr = a_wr_idx[Log2Ratio-1:0];
          if (ena_s) begin
            if (wea) begin
              mem[{addra, lsbaddr}] <= dina[(a_wr_idx+1)*MinWidth-1-:MinWidth];
            end
          end
        end
      end

    end
  endgenerate

  // Memory port B

  generate
    if (DATA_WIDTH_A < DATA_WIDTH_B) begin : g_b_altb

      // Port B read
      always @(posedge clkb) begin : p_rd
        integer b_rd_idx;
        logic [Log2Ratio-1:0] lsbaddr;
        for (b_rd_idx = 0; b_rd_idx < Ratio; b_rd_idx = b_rd_idx + 1) begin
          lsbaddr = b_rd_idx[Log2Ratio-1:0];
          // TODO: rstb[0] does not work here
          if (enb_s) begin
            if (web && (WRITE_MODE_B == "WRITE_FIRST")) begin
              regb[(b_rd_idx+1)*MinWidth-1-:MinWidth] <= dinb[(b_rd_idx+1)*MinWidth-1-:MinWidth];
            end else if (web && (WRITE_MODE_B == "NO_CHANGE")) begin
              regb[(b_rd_idx+1)*MinWidth-1-:MinWidth] <= regb[(b_rd_idx+1)*MinWidth-1-:MinWidth];
            end else begin  // no web, or write mode is "READ_FIRST"
              regb[(b_rd_idx+1)*MinWidth-1-:MinWidth] <= mem[{addrb, lsbaddr}];
            end
          end
        end
      end

      // Port B write
      always @(posedge clkb) begin : p_wr
        integer b_wr_idx;
        logic [Log2Ratio-1:0] lsbaddr;
        for (b_wr_idx = 0; b_wr_idx < Ratio; b_wr_idx = b_wr_idx + 1) begin
          lsbaddr = b_wr_idx[Log2Ratio-1:0];
          if (enb_s) begin
            if (web) begin
              mem[{addrb, lsbaddr}] <= dinb[(b_wr_idx+1)*MinWidth-1-:MinWidth];
            end
          end
        end
      end

    end else begin : g_b_agetb

      // Port B read
      always_ff @(posedge clkb) begin
        // TODO: rstb[0] does not work here
        if (enb_s) begin
          if (web && (WRITE_MODE_B == "WRITE_FIRST")) begin
            regb <= dinb;
          end else if (web && (WRITE_MODE_B == "NO_CHANGE")) begin
            regb <= regb;
          end else begin  // no web, or write mode is "READ_FIRST"
            regb <= mem[addrb];
          end
        end
      end

      // Port B write
      always_ff @(posedge clkb) begin
        if (enb_s) begin
          if (web) begin
            mem[addrb] <= dinb;
          end
        end
      end

    end
  endgenerate
  /* verilator lint_on MULTIDRIVEN */

  // Optional output pipeline registers

  generate
    if (OUTPUT_REG_A == 0) begin : g_no_reg_a

      always_comb begin
        douta = rega;
      end

    end else begin : g_reg_a

      always_ff @(posedge clka) begin
        if (rsta[1]) begin
          douta <= 'd0;
        end else if (ena[1]) begin
          douta <= rega;
        end
      end

    end
  endgenerate

  generate
    if (OUTPUT_REG_B == 0) begin : g_no_reg_b

      always_comb begin
        doutb = regb;
      end

    end else begin : g_reg_b

      always_ff @(posedge clkb) begin
        if (rstb[1]) begin
          doutb <= 'd0;
        end else if (enb[1]) begin
          doutb <= regb;
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire

/*
 * True Dual Port Asymmetric Memory
 *
 * This module implements a true dual port memory with configurable address and data widths.
 * It supports different write modes and independent read latency for both ports.
 *
 * Read Latency: 1 to 3 clock cycles
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_tdp_asym #(
    parameter int ADDR_WIDTH_A   = 11,
    parameter int DATA_WIDTH_A   = 16,
    parameter int READ_LATENCY_A = 2,
    parameter     WRITE_MODE_A   = "READ_FIRST",
    //
    parameter int ADDR_WIDTH_B   = 10,
    parameter int DATA_WIDTH_B   = 32,
    parameter int READ_LATENCY_B = 2,
    parameter     WRITE_MODE_B   = "READ_FIRST",
    //
    parameter     INIT_FILE      = "NONE",
    parameter     RAM_STYLE      = "AUTO"
) (
    input  wire                       clka,
    input  wire  [READ_LATENCY_A-1:0] rsta,
    input  wire  [READ_LATENCY_A-1:0] ena,
    input  wire                       wea,
    input  wire  [  ADDR_WIDTH_A-1:0] addra,
    input  wire  [  DATA_WIDTH_A-1:0] dina,
    output logic [  DATA_WIDTH_A-1:0] douta,
    //
    input  wire                       clkb,
    input  wire  [READ_LATENCY_B-1:0] rstb,
    input  wire  [READ_LATENCY_B-1:0] enb,
    input  wire                       web,
    input  wire  [  ADDR_WIDTH_B-1:0] addrb,
    input  wire  [  DATA_WIDTH_B-1:0] dinb,
    output logic [  DATA_WIDTH_B-1:0] doutb
);

  // Check parameters

  initial begin : drc_check
    assert (1 <= READ_LATENCY_A && READ_LATENCY_A <= 3)
    else begin
      $fatal(1, "[%m]: READ_LATENCY_A should be within range 1 to 3, got %d", READ_LATENCY_A);
    end

    assert (1 <= READ_LATENCY_B && READ_LATENCY_B <= 3)
    else begin
      $fatal(1, "[%m]: READ_LATENCY_B should be within range 1 to 3, got %d", READ_LATENCY_B);
    end

    /* verilator lint_off WIDTHEXPAND */
    assert (WRITE_MODE_A == "WRITE_FIRST" || WRITE_MODE_A == "READ_FIRST" || WRITE_MODE_A == "NO_CHANGE")
    /* verilator lint_on WIDTHEXPAND */
    else begin
      $fatal(1, "[%m]: invalid WRITE_MODE_A %s (use WRITE_FIRST, READ_FIRST, or NO_CHANGE)",
             WRITE_MODE_A);
    end

    /* verilator lint_off WIDTHEXPAND */
    assert (WRITE_MODE_B == "WRITE_FIRST" || WRITE_MODE_B == "READ_FIRST" || WRITE_MODE_B == "NO_CHANGE")
    /* verilator lint_on WIDTHEXPAND */
    else begin
      $fatal(1, "[%m]: invalid WRITE_MODE_B %s (use WRITE_FIRST, READ_FIRST, or NO_CHANGE)",
             WRITE_MODE_B);
    end

    assert (INIT_FILE != "")
    else begin
      $fatal(1, "[%m]: INIT_FILE must be NONE or a legal initialization file name");
    end

    /* verilator lint_off WIDTHEXPAND */
    assert (RAM_STYLE == "AUTO" || RAM_STYLE == "BLOCK" || RAM_STYLE == "DISTRIBUTED" ||
            RAM_STYLE == "REGISTER" || RAM_STYLE == "ULTRA")
    /* verilator lint_on WIDTHEXPAND */
    else begin
      $fatal(1, "[%m]: invalid RAM_STYLE %s (use AUTO, BLOCK, DISTRIBUTED, REGISTER, or ULTRA)",
             RAM_STYLE);
    end

`ifdef RAM_USE_XPM
    /* verilator lint_off WIDTHEXPAND */
    assert (RAM_STYLE != "REGISTER")
    /* verilator lint_on WIDTHEXPAND */
    else begin
      $fatal(1, "[%m]: RAM_STYLE REGISTER is not supported by xpm_memory_tdpram");
    end

    /* verilator lint_off WIDTHEXPAND */
    assert (RAM_STYLE != "DISTRIBUTED")
    /* verilator lint_on WIDTHEXPAND */
    else begin
      $fatal(1,
             "[%m]: RAM_STYLE DISTRIBUTED does not preserve both write ports in xpm_memory_tdpram");
    end

`endif
  end

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
`ifndef RAM_USE_XPM
  (* RAM_STYLE=RAM_STYLE *)
  logic [MinWidth-1:0] mem[0:MaxSize-1];
`endif

  wire                     ena_s;
  wire                     enb_s;

  logic [DATA_WIDTH_A-1:0] rega  [READ_LATENCY_A];
  logic [DATA_WIDTH_B-1:0] regb  [READ_LATENCY_B];

`ifndef RAM_USE_XPM
  integer init_idx;
`endif

  // This makes Vivado recognize correct EN pin
  assign ena_s = ena[0];
  assign enb_s = enb[0];

`ifdef RAM_USE_XPM

  localparam integer XpmMemorySize = MaxSize * MinWidth;

  // UltraRAM requires a common clock; the two clock ports may be tied
  // together by the caller even though the interface exposes both ports.
  localparam XpmClockingMode = RAM_STYLE == "ULTRA" ? "common_clock" : "independent_clock";

  localparam integer XpmReadLatencyA = READ_LATENCY_A < 3 ? READ_LATENCY_A : 2;
  localparam integer XpmReadLatencyB = READ_LATENCY_B < 3 ? READ_LATENCY_B : 2;

  localparam integer RtlPipelineStartA = XpmReadLatencyA;
  localparam integer RtlPipelineStartB = XpmReadLatencyB;

  localparam XpmInitParam = INIT_FILE == "NONE" ? "0" : "";

  logic xpm_sbiterra;
  logic xpm_dbiterra;
  logic xpm_sbiterrb;
  logic xpm_dbiterrb;

  xpm_memory_tdpram #(
      // Common module parameters
      .MEMORY_SIZE            (XpmMemorySize),
      .MEMORY_PRIMITIVE       (RAM_STYLE),
      .CLOCKING_MODE          (XpmClockingMode),
      .ECC_MODE               ("no_ecc"),
      .ECC_TYPE               ("none"),
      .ECC_BIT_RANGE          ("[7:0]"),
      .MEMORY_INIT_FILE       (INIT_FILE),
      .MEMORY_INIT_PARAM      (XpmInitParam),
      .USE_MEM_INIT           (1),
      .USE_MEM_INIT_MMI       (0),
      .WAKEUP_TIME            ("disable_sleep"),
      .AUTO_SLEEP_TIME        (0),
      .MESSAGE_CONTROL        (0),
      .USE_EMBEDDED_CONSTRAINT(0),
      .MEMORY_OPTIMIZATION    ("true"),
      .CASCADE_HEIGHT         (0),
      .RAM_DECOMP             ("auto"),
      .SIM_ASSERT_CHK         (0),
      .WRITE_PROTECT          (1),
      .IGNORE_INIT_SYNTH      (0),
      // Port A module parameters
      .WRITE_DATA_WIDTH_A     (DATA_WIDTH_A),
      .READ_DATA_WIDTH_A      (DATA_WIDTH_A),
      .BYTE_WRITE_WIDTH_A     (DATA_WIDTH_A),
      .ADDR_WIDTH_A           (ADDR_WIDTH_A),
      .READ_RESET_VALUE_A     ("0"),
      .READ_LATENCY_A         (XpmReadLatencyA),
      .WRITE_MODE_A           (WRITE_MODE_A),
      .RST_MODE_A             ("sync"),
      // Port B module parameters
      .WRITE_DATA_WIDTH_B     (DATA_WIDTH_B),
      .READ_DATA_WIDTH_B      (DATA_WIDTH_B),
      .BYTE_WRITE_WIDTH_B     (DATA_WIDTH_B),
      .ADDR_WIDTH_B           (ADDR_WIDTH_B),
      .READ_RESET_VALUE_B     ("0"),
      .READ_LATENCY_B         (XpmReadLatencyB),
      .WRITE_MODE_B           (WRITE_MODE_B),
      .RST_MODE_B             ("sync")
  ) xpm_memory_tdpram_i (
      // Common module ports
      .sleep         (1'b0),
      // Port A module ports
      .clka          (clka),
      .rsta          (rsta[XpmReadLatencyA-1]),
      .ena           (ena_s),
      .regcea        (ena[XpmReadLatencyA-1]),
      .wea           (wea),
      .addra         (addra),
      .dina          (dina),
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      .douta         (rega[XpmReadLatencyA-1]),
      .sbiterra      (xpm_sbiterra),
      .dbiterra      (xpm_dbiterra),
      // Port B module ports
      .clkb          (clkb),
      .rstb          (rstb[XpmReadLatencyB-1]),
      .enb           (enb_s),
      .regceb        (enb[XpmReadLatencyB-1]),
      .web           (web),
      .addrb         (addrb),
      .dinb          (dinb),
      .injectsbiterrb(1'b0),
      .injectdbiterrb(1'b0),
      .doutb         (regb[XpmReadLatencyB-1]),
      .sbiterrb      (xpm_sbiterrb),
      .dbiterrb      (xpm_dbiterrb)
  );

`else

  localparam integer RtlPipelineStartA = 1;
  localparam integer RtlPipelineStartB = 1;

  // Initialize memory

  initial begin
    for (init_idx = 0; init_idx < MaxSize; init_idx = init_idx + 1) begin
      mem[init_idx] = 'b0;
    end
    if (INIT_FILE != "NONE") begin
      $readmemh(INIT_FILE, mem);
    end
  end

  // Memory port A

  generate
    if (DATA_WIDTH_A <= DATA_WIDTH_B) begin : g_a_aletb

      // Port A read
      always_ff @(posedge clka) begin
        if (rsta[0]) begin
          rega[0] <= '0;
        end else if (ena_s) begin
          /* verilator lint_off WIDTHEXPAND */
          if (wea && (WRITE_MODE_A == "WRITE_FIRST")) begin
            /* verilator lint_on WIDTHEXPAND */
            rega[0] <= dina;
            /* verilator lint_off WIDTHEXPAND */
          end else if (wea && (WRITE_MODE_A == "NO_CHANGE")) begin
            /* verilator lint_on WIDTHEXPAND */
            rega[0] <= rega[0];
          end else begin  // no wea, or write mode is "READ_FIRST"
            rega[0] <= mem[addra];
          end
        end
      end

      // Port A write
      always @(posedge clka) begin
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
          if (rsta[0]) begin
            rega[0] <= '0;
          end else if (ena_s) begin
            /* verilator lint_off WIDTHEXPAND */
            if (wea && (WRITE_MODE_A == "WRITE_FIRST")) begin
              /* verilator lint_on WIDTHEXPAND */
              rega[0][(a_rd_idx+1)*MinWidth-1-:MinWidth] <= dina[(a_rd_idx+1)*MinWidth-1-:MinWidth];
              /* verilator lint_off WIDTHEXPAND */
            end else if (wea && (WRITE_MODE_A == "NO_CHANGE")) begin
              /* verilator lint_on WIDTHEXPAND */
              rega[0][(a_rd_idx+1)*MinWidth-1-:MinWidth] <= rega[0][(a_rd_idx+1)*MinWidth-1-:MinWidth];
            end else begin  // no wea, or write mode is "READ_FIRST"
              rega[0][(a_rd_idx+1)*MinWidth-1-:MinWidth] <= mem[{addra, lsbaddr}];
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
          if (rstb[0]) begin
            regb[0] <= '0;
          end else if (enb_s) begin
            /* verilator lint_off WIDTHEXPAND */
            if (web && (WRITE_MODE_B == "WRITE_FIRST")) begin
              /* verilator lint_on WIDTHEXPAND */
              regb[0][(b_rd_idx+1)*MinWidth-1-:MinWidth] <= dinb[(b_rd_idx+1)*MinWidth-1-:MinWidth];
              /* verilator lint_off WIDTHEXPAND */
            end else if (web && (WRITE_MODE_B == "NO_CHANGE")) begin
              /* verilator lint_on WIDTHEXPAND */
              regb[0][(b_rd_idx+1)*MinWidth-1-:MinWidth] <= regb[0][(b_rd_idx+1)*MinWidth-1-:MinWidth];
            end else begin  // no web, or write mode is "READ_FIRST"
              regb[0][(b_rd_idx+1)*MinWidth-1-:MinWidth] <= mem[{addrb, lsbaddr}];
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
        if (rstb[0]) begin
          regb[0] <= '0;
        end else if (enb_s) begin
          /* verilator lint_off WIDTHEXPAND */
          if (web && (WRITE_MODE_B == "WRITE_FIRST")) begin
            /* verilator lint_on WIDTHEXPAND */
            regb[0] <= dinb;
            /* verilator lint_off WIDTHEXPAND */
          end else if (web && (WRITE_MODE_B == "NO_CHANGE")) begin
            /* verilator lint_on WIDTHEXPAND */
            regb[0] <= regb[0];
          end else begin  // no web, or write mode is "READ_FIRST"
            regb[0] <= mem[addrb];
          end
        end
      end

      // Port B write
      always @(posedge clkb) begin
        if (enb_s) begin
          if (web) begin
            mem[addrb] <= dinb;
          end
        end
      end

    end
  endgenerate
  /* verilator lint_on MULTIDRIVEN */

`endif

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    for (genvar i = RtlPipelineStartA; i < READ_LATENCY_A; i++) begin : g_pipeline_a
      always_ff @(posedge clka) begin
        if (rsta[i]) begin
          rega[i] <= '0;
        end else if (ena[i]) begin
          rega[i] <= rega[i-1];
        end
      end
    end

    for (genvar i = RtlPipelineStartB; i < READ_LATENCY_B; i++) begin : g_pipeline_b
      always_ff @(posedge clkb) begin
        if (rstb[i]) begin
          regb[i] <= '0;
        end else if (enb[i]) begin
          regb[i] <= regb[i-1];
        end
      end
    end
  endgenerate

  assign douta = rega[READ_LATENCY_A-1];
  assign doutb = regb[READ_LATENCY_B-1];

endmodule

`default_nettype wire

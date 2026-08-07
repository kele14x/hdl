// File: ram_tdp.sv
// Brief: Simplified True Dual Port Memory. Which means RAM with two ports, and
//        both ports can be used to write and read. However, each port only has
//        one address port, it's used for both read and write. Which means you
//        can't simultaneously do write and read on different address using only
//        one port.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_tdp #(
    parameter int ADDR_WIDTH     = 10,
    parameter int DATA_WIDTH     = 32,
    parameter     WRITE_MODE_A   = "READ_FIRST",  // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
    parameter     WRITE_MODE_B   = "READ_FIRST",  // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
    parameter int READ_LATENCY_A = 2,
    parameter int READ_LATENCY_B = 2,
    //
    parameter int DEPTH          = 1 << ADDR_WIDTH,
    parameter     INIT_FILE      = "NONE",
    parameter     RAM_STYLE      = "AUTO"
) (
    // Port A
    input var                       clka,
    input var                       rsta,
    input var  [READ_LATENCY_A-1:0] ena,
    input var                       wea,
    input var  [    ADDR_WIDTH-1:0] addra,
    input var  [    DATA_WIDTH-1:0] dina,
    output var [    DATA_WIDTH-1:0] douta,
    // Port B
    input var                       clkb,
    input var                       rstb,
    input var  [READ_LATENCY_B-1:0] enb,
    input var                       web,
    input var  [    ADDR_WIDTH-1:0] addrb,
    input var  [    DATA_WIDTH-1:0] dinb,
    output var [    DATA_WIDTH-1:0] doutb
);


  initial begin : drc_check
    assert (1 <= READ_LATENCY_A && READ_LATENCY_A <= 3)
    else begin
      $fatal(1, "[%m]: READ_LATENCY_A should be within range 1 to 3.");
    end

    assert (1 <= READ_LATENCY_B && READ_LATENCY_B <= 3)
    else begin
      $fatal(1, "[%m]: READ_LATENCY_B should be within range 1 to 3.");
    end

    assert (INIT_FILE != "")
    else begin
      $fatal(1, "[%m]: INIT_FILE must be NONE or a legal initialization file name");
    end

    assert (ADDR_WIDTH > 0)
    else begin
      $fatal(1, "[%m]: ADDR_WIDTH must be positive, got %d", ADDR_WIDTH);
    end

    assert (DEPTH > 0)
    else begin
      $fatal(1, "[%m]: DEPTH must be positive, got %d", DEPTH);
    end

    assert (ADDR_WIDTH >= $clog2(DEPTH))
    else begin
      $fatal(1, "[%m]: ADDR_WIDTH %d is too small for DEPTH %d", ADDR_WIDTH, DEPTH);
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

`ifdef RAM_USE_XPM

  localparam int XpmMemorySize = DATA_WIDTH * DEPTH;

  // UltraRAM requires a common clock; the two clock ports may be tied
  // together by the caller even though the interface exposes both ports.
  localparam XpmClockingMode = RAM_STYLE == "ULTRA" ? "common_clock" : "independent_clock";

  // XPM exposes independent enables for its first read stage and its final
  // output stage. Keep the third stage in RTL so each port's final enable
  // remains independent.
  localparam int XpmReadLatencyA = READ_LATENCY_A < 3 ? READ_LATENCY_A : 2;
  localparam int XpmReadLatencyB = READ_LATENCY_B < 3 ? READ_LATENCY_B : 2;

  localparam XpmInitParam = INIT_FILE == "NONE" ? "0" : "";

  logic [DATA_WIDTH-1:0] xpm_douta;
  logic [DATA_WIDTH-1:0] xpm_doutb;
  logic [DATA_WIDTH-1:0] output_reg_a;
  logic [DATA_WIDTH-1:0] output_reg_b;

  logic                  xpm_rsta;
  logic                  xpm_rstb;

  logic                  xpm_sbiterra;
  logic                  xpm_dbiterra;
  logic                  xpm_sbiterrb;
  logic                  xpm_dbiterrb;

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
      .WRITE_DATA_WIDTH_A     (DATA_WIDTH),
      .READ_DATA_WIDTH_A      (DATA_WIDTH),
      .BYTE_WRITE_WIDTH_A     (DATA_WIDTH),
      .ADDR_WIDTH_A           (ADDR_WIDTH),
      .READ_RESET_VALUE_A     ("0"),
      .READ_LATENCY_A         (XpmReadLatencyA),
      .WRITE_MODE_A           (WRITE_MODE_A),
      .RST_MODE_A             ("sync"),
      // Port B module parameters
      .WRITE_DATA_WIDTH_B     (DATA_WIDTH),
      .READ_DATA_WIDTH_B      (DATA_WIDTH),
      .BYTE_WRITE_WIDTH_B     (DATA_WIDTH),
      .ADDR_WIDTH_B           (ADDR_WIDTH),
      .READ_RESET_VALUE_B     ("0"),
      .READ_LATENCY_B         (XpmReadLatencyB),
      .WRITE_MODE_B           (WRITE_MODE_B),
      .RST_MODE_B             ("sync")
  ) xpm_memory_tdpram_i (
      .sleep         (1'b0),
      //
      .clka          (clka),
      .rsta          (xpm_rsta),
      .ena           (ena[0]),
      .regcea        (ena[XpmReadLatencyA-1]),
      .wea           (wea),
      .addra         (addra),
      .dina          (dina),
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      .douta         (xpm_douta),
      .sbiterra      (xpm_sbiterra),
      .dbiterra      (xpm_dbiterra),
      //
      .clkb          (clkb),
      .rstb          (xpm_rstb),
      .enb           (enb[0]),
      .regceb        (enb[XpmReadLatencyB-1]),
      .web           (web),
      .addrb         (addrb),
      .dinb          (dinb),
      .injectsbiterrb(1'b0),
      .injectdbiterrb(1'b0),
      .doutb         (xpm_doutb),
      .sbiterrb      (xpm_sbiterrb),
      .dbiterrb      (xpm_dbiterrb)
  );

  // XPM's reset is connected only when its output is also the core output.
  assign xpm_rsta = rsta && (READ_LATENCY_A == XpmReadLatencyA);
  assign xpm_rstb = rstb && (READ_LATENCY_B == XpmReadLatencyB);

  generate
    if (READ_LATENCY_A > XpmReadLatencyA) begin : g_output_reg_a
      always_ff @(posedge clka) begin
        if (rsta) begin
          output_reg_a <= {DATA_WIDTH{1'b0}};
        end else if (ena[READ_LATENCY_A-1]) begin
          output_reg_a <= xpm_douta;
        end
      end

      assign douta = output_reg_a;
    end else begin : g_xpm_output_a
      assign douta = xpm_douta;
    end

    if (READ_LATENCY_B > XpmReadLatencyB) begin : g_output_reg_b
      always_ff @(posedge clkb) begin
        if (rstb) begin
          output_reg_b <= {DATA_WIDTH{1'b0}};
        end else if (enb[READ_LATENCY_B-1]) begin
          output_reg_b <= xpm_doutb;
        end
      end

      assign doutb = output_reg_b;
    end else begin : g_xpm_output_b
      assign doutb = xpm_doutb;
    end
  endgenerate

`else

  // The portable behavioral memory.
  /* verilator lint_off MULTIDRIVEN */
  (* RAM_STYLE = RAM_STYLE *)
  logic [DATA_WIDTH-1:0] MEM[DEPTH];

  // Port A output pipeline
  logic [DATA_WIDTH-1:0] rega[READ_LATENCY_A];
  // Port B output pipeline
  logic [DATA_WIDTH-1:0] regb[READ_LATENCY_B];

  // Initializes the memory values to a specified file or to all zeros to match
  // hardware
  initial begin : memory_init
    if (INIT_FILE != "NONE") begin : file_init
      $readmemh(INIT_FILE, MEM, 0, DEPTH - 1);
    end else begin : zero_init
      for (int i = 0; i < DEPTH; i++) begin
        MEM[i] = {DATA_WIDTH{1'b0}};
      end
    end
  end

  // Port A write
  always @(posedge clka) begin
    if (ena[0] && wea) begin
      MEM[addra] <= dina;
    end
  end

  // Port B write
  always @(posedge clkb) begin
    if (enb[0] && web) begin
      MEM[addrb] <= dinb;
    end
  end

  // Port A read
  always_ff @(posedge clka) begin
    if (rsta && (READ_LATENCY_A == 1)) begin
      rega[0] <= {DATA_WIDTH{1'b0}};
    end else if (ena[0]) begin
      /* verilator lint_off WIDTHEXPAND */
      if ((wea == 1'b1) && (WRITE_MODE_A == "WRITE_FIRST")) begin
        /* verilator lint_on WIDTHEXPAND */
        rega[0] <= dina;
        /* verilator lint_off WIDTHEXPAND */
      end else if ((wea == 1'b1) && (WRITE_MODE_A == "NO_CHANGE")) begin
        /* verilator lint_on WIDTHEXPAND */
        rega[0] <= rega[0];
      end else begin  // no wea, or write mode is "READ_FIRST"
        rega[0] <= MEM[addra];
      end
    end
  end

  // Port B read
  always_ff @(posedge clkb) begin
    if (rstb && (READ_LATENCY_B == 1)) begin
      regb[0] <= {DATA_WIDTH{1'b0}};
    end else if (enb[0]) begin
      /* verilator lint_off WIDTHEXPAND */
      if ((web == 1'b1) && (WRITE_MODE_B == "WRITE_FIRST")) begin
        /* verilator lint_on WIDTHEXPAND */
        regb[0] <= dinb;
        /* verilator lint_off WIDTHEXPAND */
      end else if ((web == 1'b1) && (WRITE_MODE_B == "NO_CHANGE")) begin
        /* verilator lint_on WIDTHEXPAND */
        regb[0] <= regb[0];
      end else begin  // no web, or write mode is "READ_FIRST"
        regb[0] <= MEM[addrb];
      end
    end
  end

  /* verilator lint_on MULTIDRIVEN */

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    for (genvar i = 1; i < READ_LATENCY_A; i++) begin : g_output_reg_a
      always_ff @(posedge clka) begin
        if (rsta && (i == READ_LATENCY_A - 1)) begin
          rega[i] <= {DATA_WIDTH{1'b0}};
        end else if (ena[i]) begin
          rega[i] <= rega[i-1];
        end
      end
    end

    for (genvar i = 1; i < READ_LATENCY_B; i++) begin : g_output_reg_b
      always_ff @(posedge clkb) begin
        if (rstb && (i == READ_LATENCY_B - 1)) begin
          regb[i] <= {DATA_WIDTH{1'b0}};
        end else if (enb[i]) begin
          regb[i] <= regb[i-1];
        end
      end
    end
  endgenerate

  assign douta = rega[READ_LATENCY_A-1];
  assign doutb = regb[READ_LATENCY_B-1];

`endif

endmodule

`default_nettype wire

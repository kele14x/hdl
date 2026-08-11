// File: ram_sdp.sv
// Brief: Simplified Simple Dual Port (SDP) memory. Port A is the
//        write port, port B is the read port. Each port has dedicated address
//        port.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sdp #(
    parameter int ADDR_WIDTH   = 10,
    parameter int DATA_WIDTH   = 32,
    parameter int READ_LATENCY = 2,                // 1 ~ 3
    //
    parameter int DEPTH        = 1 << ADDR_WIDTH,
    parameter     INIT_FILE    = "NONE",
    parameter     RAM_STYLE    = "AUTO"
) (
    // Port A, write port
    input var                     clka,
    input var                     wea,
    input var  [  ADDR_WIDTH-1:0] addra,
    input var  [  DATA_WIDTH-1:0] dina,
    // Port B, read port
    input var                     clkb,
    input var                     rstb,
    input var  [READ_LATENCY-1:0] enb,
    input var  [  ADDR_WIDTH-1:0] addrb,
    output var [  DATA_WIDTH-1:0] doutb
);


  initial begin : drc_check
    assert (1 <= READ_LATENCY && READ_LATENCY <= 3)
    else begin
      $fatal(1, "[%m]: Read latency (READ_LATENCY) should be within range 1 to 3, got %d",
             READ_LATENCY);
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
      $fatal(1, "[%m]: RAM_STYLE REGISTER is not supported by xpm_memory_sdpram");
    end
`endif
  end

`ifdef RAM_USE_XPM

  localparam integer XpmMemorySize = DATA_WIDTH * DEPTH;

  // UltraRAM requires a common clock; the two clock ports may be tied
  // together by the caller even though the interface exposes both ports.
  localparam XpmClockingMode = RAM_STYLE == "ULTRA" ? "common_clock" : "independent_clock";

  // XPM exposes independent enables for its first read stage and its final
  // output stage. Keep the third stage in RTL so enb[2] remains independent.
  localparam int XpmReadLatency = READ_LATENCY < 3 ? READ_LATENCY : 2;

  localparam XpmInitParam = INIT_FILE == "NONE" ? "0" : "";

  logic [DATA_WIDTH-1:0] xpm_dout;
  logic [DATA_WIDTH-1:0] output_reg;

  logic                  xpm_rstb;

  logic                  xpm_sbiterrb;
  logic                  xpm_dbiterrb;

  xpm_memory_sdpram #(
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
      .BYTE_WRITE_WIDTH_A     (DATA_WIDTH),
      .ADDR_WIDTH_A           (ADDR_WIDTH),
      .RST_MODE_A             ("sync"),
      // Port B module parameters
      .READ_DATA_WIDTH_B      (DATA_WIDTH),
      .ADDR_WIDTH_B           (ADDR_WIDTH),
      .READ_RESET_VALUE_B     ("0"),
      .READ_LATENCY_B         (XpmReadLatency),
      .WRITE_MODE_B           ("read_first"),
      .RST_MODE_B             ("sync")
  ) xpm_memory_sdpram_i (
      .sleep         (1'b0),
      //
      .clka          (clka),
      .ena           (wea),
      .wea           (wea),
      .addra         (addra),
      .dina          (dina),
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      //
      .clkb          (clkb),
      .rstb          (xpm_rstb),
      .enb           (enb[0]),
      .regceb        (enb[XpmReadLatency-1]),
      .addrb         (addrb),
      .doutb         (xpm_dout),
      .sbiterrb      (xpm_sbiterrb),
      .dbiterrb      (xpm_dbiterrb)
  );

  // XPM's reset is connected only when its output is also the core output.
  assign xpm_rstb = rstb && (READ_LATENCY == XpmReadLatency);

  generate
    if (READ_LATENCY > XpmReadLatency) begin : g_output_reg
      always_ff @(posedge clkb) begin
        if (rstb) begin
          output_reg <= {DATA_WIDTH{1'b0}};
        end else if (enb[READ_LATENCY-1]) begin
          output_reg <= xpm_dout;
        end
      end

      assign doutb = output_reg;
    end else begin : g_xpm_output
      assign doutb = xpm_dout;
    end
  endgenerate

`else

  // The portable behavioral memory.
  (* RAM_STYLE = RAM_STYLE *)
  logic [DATA_WIDTH-1:0] MEM[DEPTH];

  // Port B output pipeline
  logic [DATA_WIDTH-1:0] regb[READ_LATENCY];

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

  // Memory write
  always @(posedge clka) begin
    if (wea) begin
      /* verilator lint_off WIDTHTRUNC */
      MEM[addra] <= dina;
      /* verilator lint_on WIDTHTRUNC */
    end
  end

  // Memory read
  always_ff @(posedge clkb) begin
    if (rstb && (READ_LATENCY == 1)) begin
      regb[0] <= {DATA_WIDTH{1'b0}};
    end else if (enb[0]) begin
      /* verilator lint_off WIDTHTRUNC */
      regb[0] <= MEM[addrb];
      /* verilator lint_on WIDTHTRUNC */
    end
  end

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    for (genvar i = 1; i < READ_LATENCY; i++) begin : g_output_reg
      always_ff @(posedge clkb) begin
        if (rstb && (i == READ_LATENCY - 1)) begin
          regb[i] <= {DATA_WIDTH{1'b0}};
        end else if (enb[i]) begin
          regb[i] <= regb[i-1];
        end
      end
    end
  endgenerate

  assign doutb = regb[READ_LATENCY-1];

`endif

endmodule

`default_nettype wire

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
    parameter int READ_LATENCY = 3,       // 1 ~ 3
    parameter     INIT_FILE    = "NONE",
    parameter     RAM_STYLE    = "AUTO"
) (
    // Port A, write port
    input var                     clka,
    input var                     ena,
    input var                     wea,
    input var  [  ADDR_WIDTH-1:0] addra,
    input var  [  DATA_WIDTH-1:0] dina,
    // Port B, read port
    input var                     clkb,
    input var  [READ_LATENCY-1:0] rstb,
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

  // Port B output pipeline
  logic [DATA_WIDTH-1:0] regb[READ_LATENCY];

`ifdef RAM_USE_XPM

  localparam integer XpmMemorySize = DATA_WIDTH * (1 << ADDR_WIDTH);

  // XPM exposes independent enables for its first read stage and its final
  // output stage. Keep the third stage in RTL so enb[2] remains independent.
  localparam integer XpmReadLatency = READ_LATENCY < 3 ? READ_LATENCY : 2;

  localparam integer RtlPipelineStart = XpmReadLatency;

  localparam XpmInitParam = INIT_FILE == "NONE" ? "0" : "";

  logic xpm_sbiterrb;
  logic xpm_dbiterrb;

  xpm_memory_sdpram #(
      // Common module parameters
      .MEMORY_SIZE            (XpmMemorySize),
      .MEMORY_PRIMITIVE       (RAM_STYLE),
      .CLOCKING_MODE          ("independent_clock"),
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
      .clka          (clka),
      .ena           (ena),
      .wea           (wea),
      .addra         (addra),
      .dina          (dina),
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      .clkb          (clkb),
      .rstb          (rstb[XpmReadLatency-1]),
      .enb           (enb[0]),
      .regceb        (enb[XpmReadLatency-1]),
      .addrb         (addrb),
      .doutb         (regb[XpmReadLatency-1]),
      .sbiterrb      (xpm_sbiterrb),
      .dbiterrb      (xpm_dbiterrb)
  );

`else

  localparam integer RtlPipelineStart = 1;

  // The portable behavioral memory.
  (* RAM_STYLE = RAM_STYLE *)
  logic [DATA_WIDTH-1:0] MEM[2**ADDR_WIDTH];

  // Initializes the memory values to a specified file or to all zeros to match
  // hardware
  initial begin : memory_init
    if (INIT_FILE != "NONE") begin : file_init
      $readmemh(INIT_FILE, MEM, 0, 2 ** ADDR_WIDTH - 1);
    end else begin : zero_init
      for (int i = 0; i < 2 ** ADDR_WIDTH; i++) begin
        MEM[i] = {DATA_WIDTH{1'b0}};
      end
    end
  end

  // Memory write

  always_ff @(posedge clka) begin
    if (ena && wea) begin
      MEM[addra] <= dina;
    end
  end

  // Memory read

  always_ff @(posedge clkb) begin
    if (rstb[0]) begin
      regb[0] <= '0;
    end else if (enb[0]) begin
      regb[0] <= MEM[addrb];
    end
  end

`endif

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    for (genvar i = RtlPipelineStart; i < READ_LATENCY; i++) begin : g_output_reg
      always_ff @(posedge clkb) begin
        if (rstb[i]) begin
          regb[i] <= '0;
        end else if (enb[i]) begin
          regb[i] <= regb[i-1];
        end
      end
    end
  endgenerate

  assign doutb = regb[READ_LATENCY-1];

endmodule

`default_nettype wire

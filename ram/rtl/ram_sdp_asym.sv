// File: ram_sdp_asym.sv
// Brief: Simple Dual Port (SDP) memory with asymmetric port width.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sdp_asym #(
    parameter int ADDR_WIDTH_A   = 11,
    parameter int DATA_WIDTH_A   = 16,
    parameter int ADDR_WIDTH_B   = 9,
    parameter int DATA_WIDTH_B   = 64,
    parameter int READ_LATENCY_B = 2,
    parameter     INIT_FILE      = "NONE",
    parameter     RAM_STYLE      = "AUTO"
) (
    // Port A, write port
    input var                       clka,
    input var                       wea,
    input var  [  ADDR_WIDTH_A-1:0] addra,
    input var  [  DATA_WIDTH_A-1:0] dina,
    // Port B, read port
    input var                       clkb,
    input var  [READ_LATENCY_B-1:0] rstb,
    input var  [READ_LATENCY_B-1:0] enb,
    input var  [  ADDR_WIDTH_B-1:0] addrb,
    output var [  DATA_WIDTH_B-1:0] doutb
);

  localparam int SizeA = 2 ** ADDR_WIDTH_A;
  localparam int SizeB = 2 ** ADDR_WIDTH_B;

  localparam int MaxSize = (SizeA > SizeB) ? SizeA : SizeB;

  localparam int MaxWidth = (DATA_WIDTH_A > DATA_WIDTH_B) ? DATA_WIDTH_A : DATA_WIDTH_B;
  localparam int MinWidth = (DATA_WIDTH_A < DATA_WIDTH_B) ? DATA_WIDTH_A : DATA_WIDTH_B;

  localparam int Ratio = MaxWidth / MinWidth;
  localparam int Log2Ratio = $clog2(Ratio);

  initial begin : drc_check
    assert (1 <= READ_LATENCY_B && READ_LATENCY_B <= 3)
    else begin
      $fatal(1, "[%m]: Read latency (READ_LATENCY_B) should be within range 1 to 3, got %d",
             READ_LATENCY_B);
    end

    assert (INIT_FILE != "")
    else begin
      $fatal(1, "[%m]: INIT_FILE must be NONE or a legal initialization file name");
    end

    assert (DATA_WIDTH_A > 0 && DATA_WIDTH_B > 0)
    else begin
      $fatal(1, "[%m]: DATA_WIDTH_A and DATA_WIDTH_B should be greater than zero");
    end

    assert (MaxWidth % MinWidth == 0)
    else begin
      $fatal(1,
             "The wider RAM port width should be an integer multiple of the narrower port width.");
    end

    assert ((Ratio & (Ratio - 1)) == 0)
    else begin
      $fatal(
          1,
          "[%m]: The ratio of the wider RAM port width to the narrower port width should be a power of two, got %d",
          Ratio);
    end

    assert (SizeA * DATA_WIDTH_A == SizeB * DATA_WIDTH_B)
    else begin
      $fatal(1, "[%m]: The two RAM ports should address the same total memory size");
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

    assert (RAM_STYLE != "DISTRIBUTED" || DATA_WIDTH_A == DATA_WIDTH_B)
    else begin
      $fatal(1, "[%m]: RAM_STYLE DISTRIBUTED is not supported for asymmetric xpm_memory_sdpram");
    end
`endif
  end

  logic [DATA_WIDTH_B-1:0] regb[READ_LATENCY_B];

`ifdef RAM_USE_XPM

  localparam integer XpmMemorySize = MaxSize * MinWidth;

  // UltraRAM requires a common clock; the two clock ports may be tied
  // together by the caller even though the interface exposes both ports.
  localparam XpmClockingMode = RAM_STYLE == "ULTRA" ? "common_clock" : "independent_clock";

  // XPM exposes independent enables for its first read stage and its final
  // output stage. Keep the third stage in RTL so enb[2] remains independent.
  localparam integer XpmReadLatency = READ_LATENCY_B < 3 ? READ_LATENCY_B : 2;

  localparam integer RtlPipelineStart = XpmReadLatency;

  localparam XpmInitParam = INIT_FILE == "NONE" ? "0" : "";

  logic xpm_sbiterrb;
  logic xpm_dbiterrb;

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
      .WRITE_DATA_WIDTH_A     (DATA_WIDTH_A),
      .BYTE_WRITE_WIDTH_A     (DATA_WIDTH_A),
      .ADDR_WIDTH_A           (ADDR_WIDTH_A),
      .RST_MODE_A             ("sync"),
      // Port B module parameters
      .READ_DATA_WIDTH_B      (DATA_WIDTH_B),
      .ADDR_WIDTH_B           (ADDR_WIDTH_B),
      .READ_RESET_VALUE_B     ("0"),
      .READ_LATENCY_B         (XpmReadLatency),
      .WRITE_MODE_B           ("read_first"),
      .RST_MODE_B             ("sync")
  ) xpm_memory_sdpram_i (
      .sleep         (1'b0),
      .clka          (clka),
      .ena           (1'b1),
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
  logic [MinWidth-1:0] MEM[MaxSize];

  initial begin : memory_init
    if (INIT_FILE != "NONE") begin : file_init
      $readmemh(INIT_FILE, MEM, 0, MaxSize - 1);
    end else begin : zero_init
      for (int i = 0; i < MaxSize; i++) begin
        MEM[i] = '0;
      end
    end
  end

  generate
    if (DATA_WIDTH_A <= DATA_WIDTH_B) begin : g_n_wr
      always_ff @(posedge clka) begin
        if (wea) begin
          MEM[addra] <= dina;
        end
      end
    end else begin : g_s_wr
      always_ff @(posedge clka) begin
        if (wea) begin
          for (int i = 0; i < Ratio; i++) begin
            MEM[{addra, Log2Ratio'(i)}] <= dina[(i+1)*MinWidth-1-:MinWidth];
          end
        end
      end
    end
  endgenerate

  generate
    if (DATA_WIDTH_B <= DATA_WIDTH_A) begin : g_n_rd
      always_ff @(posedge clkb) begin
        if (rstb[0]) begin
          regb[0] <= '0;
        end else if (enb[0]) begin
          regb[0] <= MEM[addrb];
        end
      end
    end else begin : g_s_rd
      always_ff @(posedge clkb) begin
        if (rstb[0]) begin
          regb[0] <= '0;
        end else if (enb[0]) begin
          for (int i = 0; i < Ratio; i++) begin
            regb[0][(i+1)*MinWidth-1-:MinWidth] <= MEM[{addrb, Log2Ratio'(i)}];
          end
        end
      end
    end

  endgenerate

`endif

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    for (genvar i = RtlPipelineStart; i < READ_LATENCY_B; i++) begin : g_output_reg
      always_ff @(posedge clkb) begin
        if (rstb[i]) begin
          regb[i] <= '0;
        end else if (enb[i]) begin
          regb[i] <= regb[i-1];
        end
      end
    end
  endgenerate

  assign doutb = regb[READ_LATENCY_B-1];

endmodule

`default_nettype wire

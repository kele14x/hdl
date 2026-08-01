// File: ram_sp.sv
// Brief: Simplified Single Port (SP) Memory.
`timescale 1ns / 1ps
//
`default_nettype none

module ram_sp #(
    parameter int ADDR_WIDTH   = 10,
    parameter int DATA_WIDTH   = 32,
    parameter     WRITE_MODE   = "READ_FIRST",  // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
    parameter int READ_LATENCY = 2,             // 1 ~ 3
    parameter     INIT_FILE    = "NONE",
    parameter     RAM_STYLE    = "AUTO"
) (
    input var                     clk,
    input var  [READ_LATENCY-1:0] rst,
    input var  [READ_LATENCY-1:0] en,
    input var                     we,
    input var  [  ADDR_WIDTH-1:0] addr,
    input var  [  DATA_WIDTH-1:0] din,
    output var [  DATA_WIDTH-1:0] dout
);


  initial begin : drc_check
    assert (1 <= READ_LATENCY && READ_LATENCY <= 3)
    else begin
      $fatal(1, "[%m]: Read layency (READ_LATENCY) should be within range 1 to 3, got %d",
             READ_LATENCY);
    end

    assert (INIT_FILE != "")
    else begin
      $fatal(1, "[%m]: INIT_FILE must be NONE or a legal initialization file name");
    end

    /* verilator lint_off WIDTHEXPAND */
    assert (WRITE_MODE == "WRITE_FIRST" || WRITE_MODE == "READ_FIRST" || WRITE_MODE == "NO_CHANGE")
    /* verilator lint_on WIDTHEXPAND */
    else begin
      $fatal(1, "[%m]: invalid WRITE_MODE %s (use WRITE_FIRST, READ_FIRST, or NO_CHANGE)",
             WRITE_MODE);
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
      $fatal(1, "[%m]: RAM_STYLE REGISTER is not supported by xpm_memory_spram");
    end
`endif
  end

  // Port B output pipeline
  logic [DATA_WIDTH-1:0] rega[READ_LATENCY];

`ifdef RAM_USE_XPM

  localparam integer XpmMemorySize = DATA_WIDTH * (1 << ADDR_WIDTH);

  // XPM exposes independent enables for its first read stage and its final
  // output stage. Keep the third stage in RTL so en[2] remains independent.
  localparam integer XpmReadLatency = READ_LATENCY < 3 ? READ_LATENCY : 2;

  localparam integer RtlPipelineStart = XpmReadLatency;

  localparam XpmInitParam = INIT_FILE == "NONE" ? "0" : "";

  logic xpm_sbiterra;
  logic xpm_dbiterra;

  xpm_memory_spram #(
      // Common module parameters
      .MEMORY_SIZE        (XpmMemorySize),
      .MEMORY_PRIMITIVE   (RAM_STYLE),
      .ECC_MODE           ("no_ecc"),
      .ECC_TYPE           ("none"),
      .ECC_BIT_RANGE      ("[7:0]"),
      .MEMORY_INIT_FILE   (INIT_FILE),
      .MEMORY_INIT_PARAM  (XpmInitParam),
      .USE_MEM_INIT       (1),
      .USE_MEM_INIT_MMI   (0),
      .WAKEUP_TIME        ("disable_sleep"),
      .AUTO_SLEEP_TIME    (0),
      .MESSAGE_CONTROL    (0),
      .MEMORY_OPTIMIZATION("true"),
      .CASCADE_HEIGHT     (0),
      .RAM_DECOMP         ("auto"),
      .SIM_ASSERT_CHK     (0),
      .WRITE_PROTECT      (1),
      .IGNORE_INIT_SYNTH  (0),
      // Port A module parameters
      .WRITE_DATA_WIDTH_A (DATA_WIDTH),
      .READ_DATA_WIDTH_A  (DATA_WIDTH),
      .BYTE_WRITE_WIDTH_A (DATA_WIDTH),
      .ADDR_WIDTH_A       (ADDR_WIDTH),
      .READ_RESET_VALUE_A ("0"),
      .READ_LATENCY_A     (XpmReadLatency),
      .WRITE_MODE_A       (WRITE_MODE),
      .RST_MODE_A         ("sync")
  ) xpm_memory_spram_i (
      .sleep         (1'b0),
      .clka          (clk),
      .rsta          (rst[XpmReadLatency-1]),
      .ena           (en[0]),
      .regcea        (en[XpmReadLatency-1]),
      .wea           (we),
      .addra         (addr),
      .dina          (din),
      .douta         (rega[XpmReadLatency-1]),
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      .sbiterra      (xpm_sbiterra),
      .dbiterra      (xpm_dbiterra)
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

  always_ff @(posedge clk) begin : memory_write
    if (en[0] && we) begin
      MEM[addr] <= din;
    end
  end

  // Memory read

  always_ff @(posedge clk) begin : memory_read
    if (rst[0]) begin
      rega[0] <= '0;
    end else if (en[0]) begin
      /* verilator lint_off WIDTHEXPAND */
      if ((we == 1'b1) && (WRITE_MODE == "WRITE_FIRST")) begin
        /* verilator lint_on WIDTHEXPAND */
        rega[0] <= din;
        /* verilator lint_off WIDTHEXPAND */
      end else if ((we == 1'b1) && (WRITE_MODE == "NO_CHANGE")) begin
        /* verilator lint_on WIDTHEXPAND */
        rega[0] <= rega[0];
      end else begin  // no we, or write mode is "READ_FIRST"
        rega[0] <= MEM[addr];
      end
    end
  end

`endif

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    for (genvar i = RtlPipelineStart; i < READ_LATENCY; i++) begin : g_output_reg
      always_ff @(posedge clk) begin
        if (rst[i]) begin
          rega[i] <= '0;
        end else if (en[i]) begin
          rega[i] <= rega[i-1];
        end
      end
    end
  endgenerate

  assign dout = rega[READ_LATENCY-1];

endmodule

`default_nettype wire

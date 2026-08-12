// File: ram_sp.sv
// Brief: Simplified Single Port (SP) Memory.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sp #(
    parameter int ADDR_WIDTH   = 10,
    parameter int DATA_WIDTH   = 32,
    parameter     WRITE_MODE   = "READ_FIRST",     // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
    parameter int READ_LATENCY = 2,                // 1 ~ 3
    //
    parameter int DEPTH        = 1 << ADDR_WIDTH,
    parameter     INIT_FILE    = "NONE",
    parameter     RAM_STYLE    = "AUTO"
) (
    input var                     clk,
    input var                     rst,
    input var  [READ_LATENCY-1:0] en,
    input var                     we,
    input var  [  ADDR_WIDTH-1:0] addr,
    input var  [  DATA_WIDTH-1:0] din,
    output var [  DATA_WIDTH-1:0] dout
);


  initial begin : drc_check
    assert (ADDR_WIDTH > 0)
    else begin
      $error("[%m]: ADDR_WIDTH must be positive, got %d", ADDR_WIDTH);
    end

    assert (DEPTH > 0)
    else begin
      $error("[%m]: DEPTH must be positive, got %d", DEPTH);
    end

    assert (ADDR_WIDTH >= $clog2(DEPTH))
    else begin
      $error("[%m]: ADDR_WIDTH %d is too small for DEPTH %d", ADDR_WIDTH, DEPTH);
    end

    assert (1 <= READ_LATENCY && READ_LATENCY <= 3)
    else begin
      $error("[%m]: Read latency (READ_LATENCY) should be within range 1 to 3, got %d",
             READ_LATENCY);
    end

    assert (INIT_FILE != "")
    else begin
      $error("[%m]: INIT_FILE must be NONE or a legal initialization file name");
    end

    /* verilator lint_off WIDTHEXPAND */
    assert (WRITE_MODE == "WRITE_FIRST" || WRITE_MODE == "READ_FIRST" || WRITE_MODE == "NO_CHANGE")
    /* verilator lint_on WIDTHEXPAND */
    else begin
      $error("[%m]: invalid WRITE_MODE %s (use WRITE_FIRST, READ_FIRST, or NO_CHANGE)",
             WRITE_MODE);
    end

    /* verilator lint_off WIDTHEXPAND */
    assert (RAM_STYLE == "AUTO" || RAM_STYLE == "BLOCK" || RAM_STYLE == "DISTRIBUTED" ||
            RAM_STYLE == "REGISTER" || RAM_STYLE == "ULTRA")
    /* verilator lint_on WIDTHEXPAND */
    else begin
      $error("[%m]: invalid RAM_STYLE %s (use AUTO, BLOCK, DISTRIBUTED, REGISTER, or ULTRA)",
             RAM_STYLE);
    end

`ifdef RAM_USE_XPM
    /* verilator lint_off WIDTHEXPAND */
    assert (RAM_STYLE != "REGISTER")
    /* verilator lint_on WIDTHEXPAND */
    else begin
      $error("[%m]: RAM_STYLE REGISTER is not supported by xpm_memory_spram");
    end
`endif
  end

`ifdef RAM_USE_XPM

  localparam int XpmMemorySize = DATA_WIDTH * DEPTH;

  // XPM exposes independent enables for its first read stage and its final
  // output stage. Keep the third stage in RTL so en[2] remains independent.
  localparam int XpmReadLatency = READ_LATENCY < 3 ? READ_LATENCY : 2;

  localparam XpmInitParam = INIT_FILE == "NONE" ? "0" : "";

  logic [DATA_WIDTH-1:0] xpm_dout;
  logic [DATA_WIDTH-1:0] output_reg;

  logic                  xpm_rsta;

  logic                  xpm_sbiterra;
  logic                  xpm_dbiterra;

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
      //
      .clka          (clk),
      .rsta          (xpm_rsta),
      .ena           (en[0]),
      .regcea        (en[XpmReadLatency-1]),
      .wea           (we),
      .addra         (addr),
      .dina          (din),
      .douta         (xpm_dout),
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      .sbiterra      (xpm_sbiterra),
      .dbiterra      (xpm_dbiterra)
  );

  // XPM's reset is connected only when its output is also the core output.
  assign xpm_rsta = rst && (READ_LATENCY == XpmReadLatency);

  generate
    if (READ_LATENCY > XpmReadLatency) begin : g_output_reg
      always_ff @(posedge clk) begin
        if (rst) begin
          output_reg <= {DATA_WIDTH{1'b0}};
        end else if (en[READ_LATENCY-1]) begin
          output_reg <= xpm_dout;
        end
      end

      assign dout = output_reg;
    end else begin : g_xpm_output
      assign dout = xpm_dout;
    end
  endgenerate

`else

  // The portable behavioral memory.
  (* RAM_STYLE = RAM_STYLE *)
  logic [DATA_WIDTH-1:0] MEM[DEPTH];

  // Port A output pipeline
  logic [DATA_WIDTH-1:0] rega[READ_LATENCY];

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
  always @(posedge clk) begin : memory_write
    if (en[0] && we) begin
      MEM[addr] <= din;
    end
  end

  // Memory read
  always_ff @(posedge clk) begin : memory_read
    if (rst && (READ_LATENCY == 1)) begin
      rega[0] <= {DATA_WIDTH{1'b0}};
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

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    for (genvar i = 1; i < READ_LATENCY; i++) begin : g_output_reg
      always_ff @(posedge clk) begin
        if (rst && (i == READ_LATENCY - 1)) begin
          rega[i] <= {DATA_WIDTH{1'b0}};
        end else if (en[i]) begin
          rega[i] <= rega[i-1];
        end
      end
    end
  endgenerate

  assign dout = rega[READ_LATENCY-1];

`endif

endmodule

`default_nettype wire

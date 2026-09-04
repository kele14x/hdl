// File: ram_sp_uram_8k36.sv
// Brief: 8192 x 36 single-port RAM packed into one 4096 x 72 UltraRAM.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sp_uram_8k36 (
    input var         clk,
    input var  [ 1:0] en,
    input var         we,
    input var  [12:0] addr,
    input var  [35:0] din,
    output var [35:0] dout
);

  // UltraScale+ UltraRAM has a fixed 4096 x 72 organization. Logical address
  // bit 0 selects one of the two 36-bit samples packed into each physical word.
  wire  [11:0] physical_addr;
  wire  [71:0] physical_din;
  wire  [ 7:0] physical_we;
  wire  [71:0] physical_dout;

  logic [ 1:0] read_half;

  assign physical_addr = addr[12:1];
  assign physical_din  = {din, din};
  assign physical_we   = addr[0] ? {4'b1111, {4{1'b0}}} : {{4{1'b0}}, 4'b1111};

  // Keep the logical half select aligned with the two-cycle RAM read pipeline.
  // The caller registers the mux output as the third read-side pipeline stage.
  always_ff @(posedge clk) begin
    if (en[0]) begin
      read_half[0] <= addr[0];
    end
    if (en[1]) begin
      read_half[1] <= read_half[0];
    end
  end

  assign dout = read_half[1] ? physical_dout[71:36] : physical_dout[35:0];

`ifdef RAM_USE_XPM

  logic xpm_sbiterra;
  logic xpm_dbiterra;

  xpm_memory_spram #(
      // One physical URAM288: 4096 words x 72 bits.
      .MEMORY_SIZE        (72 * 4096),
      .MEMORY_PRIMITIVE   ("ultra"),
      .ECC_MODE           ("no_ecc"),
      .ECC_TYPE           ("none"),
      .ECC_BIT_RANGE      ("[7:0]"),
      .MEMORY_INIT_FILE   ("none"),
      .MEMORY_INIT_PARAM  ("0"),
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
      // Four 9-bit byte lanes select either 36-bit logical half.
      .WRITE_DATA_WIDTH_A (72),
      .BYTE_WRITE_WIDTH_A (9),
      .ADDR_WIDTH_A       (12),
      .RST_MODE_A         ("sync"),
      // Read the complete physical word before the external half mux.
      .READ_DATA_WIDTH_A  (72),
      .READ_RESET_VALUE_A ("0"),
      .READ_LATENCY_A     (2),
      .WRITE_MODE_A       ("read_first")
  ) xpm_memory_spram_i (
      .sleep         (1'b0),
      .clka          (clk),
      .rsta          (1'b0),
      .ena           (en[0]),
      .regcea        (en[1]),
      .wea           (physical_we & {8{we}}),
      .addra         (physical_addr),
      .dina          (physical_din),
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      .douta         (physical_dout),
      .sbiterra      (xpm_sbiterra),
      .dbiterra      (xpm_dbiterra)
  );

`else

  // Portable behavioral model used by non-Xilinx simulators.
  logic [71:0] mem[4096];
  logic [71:0] read_data[2];

  initial begin : memory_init
    for (int i = 0; i < 4096; i++) begin
      mem[i] = 72'b0;
    end
  end

  // Memory write. Kept out of the always_ff read block below because `mem` is
  // also driven by the initial block, which Questa rejects for always_ff
  // (vopt-7061).
  always @(posedge clk) begin : memory_write
    if (en[0] && we) begin
      // Mirror the XPM byte-lane write: physical_we[3:0] enables the low
      // 36-bit half, physical_we[7:4] the high half.
      if (|physical_we[3:0]) begin
        mem[physical_addr][35:0] <= physical_din[35:0];
      end
      if (|physical_we[7:4]) begin
        mem[physical_addr][71:36] <= physical_din[71:36];
      end
    end
  end

  // Memory read. The nonblocking assignment captures the pre-write contents,
  // so a same-cycle write to the same address still reads old data.
  always_ff @(posedge clk) begin : memory_read
    if (en[0]) begin
      read_data[0] <= mem[physical_addr];
    end
    if (en[1]) begin
      read_data[1] <= read_data[0];
    end
  end

  assign physical_dout = read_data[1];

`endif

endmodule

`default_nettype wire

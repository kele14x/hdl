// File: ram_sdp_uram_8k36.sv
// Brief: 8192 x 36 simple dual-port RAM packed into one 4096 x 72 UltraRAM.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sdp_uram_8k36 (
    // Port A, write port
    input var         clka,
    input var         wea,
    input var  [12:0] addra,
    input var  [35:0] dina,
    // Port B, read port
    input var         clkb,
    input var         rstb,
    input var  [ 2:0] enb,
    input var  [12:0] addrb,
    output var [35:0] doutb
);

  // UltraScale+ UltraRAM has a fixed 4096 x 72 organization. Logical address
  // bit 0 selects one of the two 36-bit samples packed into each physical word.
  wire  [11:0] physical_addra;
  wire  [11:0] physical_addrb;
  wire  [71:0] physical_dina;
  wire  [ 7:0] physical_wea;
  wire  [71:0] physical_doutb;

  logic [ 2:0] read_half;

  assign physical_addra = addra[12:1];
  assign physical_addrb = addrb[12:1];
  assign physical_dina  = {dina, dina};
  assign physical_wea   = addra[0] ? {4'b1111, {4{1'b0}}} : {{4{1'b0}}, 4'b1111};

  // Keep the logical half select aligned with the three-cycle RAM read pipeline.
  // READ_LATENCY_B=3 lets Vivado absorb the UltraRAM output register.
  always_ff @(posedge clkb) begin
    if (rstb) begin
      read_half <= 3'b000;
    end else begin
      if (enb[0]) begin
        read_half[0] <= addrb[0];
      end
      if (enb[1]) begin
        read_half[1] <= read_half[0];
      end
      if (enb[2]) begin
        read_half[2] <= read_half[1];
      end
    end
  end

  assign doutb = read_half[2] ? physical_doutb[71:36] : physical_doutb[35:0];

`ifdef RAM_USE_XPM

  logic xpm_sbiterrb;
  logic xpm_dbiterrb;

  xpm_memory_sdpram #(
      // One physical URAM288: 4096 words x 72 bits.
      .MEMORY_SIZE            (72 * 4096),
      .MEMORY_PRIMITIVE       ("ultra"),
      .CLOCKING_MODE          ("common_clock"),
      .ECC_MODE               ("no_ecc"),
      .ECC_TYPE               ("none"),
      .ECC_BIT_RANGE          ("[7:0]"),
      .MEMORY_INIT_FILE       ("none"),
      .MEMORY_INIT_PARAM      ("0"),
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
      // Four 9-bit byte lanes select either 36-bit logical half.
      .WRITE_DATA_WIDTH_A     (72),
      .BYTE_WRITE_WIDTH_A     (9),
      .ADDR_WIDTH_A           (12),
      .RST_MODE_A             ("sync"),
      // Port B reads the complete physical word before the external half mux.
      .READ_DATA_WIDTH_B      (72),
      .ADDR_WIDTH_B           (12),
      .READ_RESET_VALUE_B     ("0"),
      .READ_LATENCY_B         (3),
      .WRITE_MODE_B           ("read_first"),
      .RST_MODE_B             ("sync")
  ) xpm_memory_sdpram_i (
      .sleep         (1'b0),
      //
      .clka          (clka),
      .ena           (wea),
      .wea           (physical_wea & {8{wea}}),
      .addra         (physical_addra),
      .dina          (physical_dina),
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      //
      .clkb          (clkb),
      .rstb          (rstb),
      .enb           (enb[0]),
      .regceb        (enb[2]),
      .addrb         (physical_addrb),
      .doutb         (physical_doutb),
      .sbiterrb      (xpm_sbiterrb),
      .dbiterrb      (xpm_dbiterrb)
  );

`else

  // Portable behavioral model used by non-Xilinx simulators.
  logic [71:0] mem[4096];
  logic [71:0] read_data[3];

  initial begin : memory_init
    for (int i = 0; i < 4096; i++) begin
      mem[i] = 72'b0;
    end
  end

  always @(posedge clka) begin
    if (wea) begin
      if (addra[0]) begin
        mem[physical_addra][71:36] <= dina;
      end else begin
        mem[physical_addra][35:0] <= dina;
      end
    end
  end

  always_ff @(posedge clkb) begin
    if (enb[0]) begin
      read_data[0] <= mem[physical_addrb];
    end
    if (enb[1]) begin
      read_data[1] <= read_data[0];
    end
    if (rstb) begin
      read_data[2] <= 72'b0;
    end else if (enb[2]) begin
      read_data[2] <= read_data[1];
    end
  end

  assign physical_doutb = read_data[2];

`endif

endmodule

`default_nettype wire

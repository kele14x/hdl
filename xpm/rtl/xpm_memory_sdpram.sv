`timescale 1 ns / 1 ps
//
`default_nettype none

module xpm_memory_sdpram #(
    parameter int    ADDR_WIDTH_A            = 10,
    parameter int    ADDR_WIDTH_B            = 10,
    parameter int    AUTO_SLEEP_TIME         = 0,
    parameter int    BYTE_WRITE_WIDTH_A      = 32,
    parameter int    CASCADE_HEIGHT          = 0,
    parameter string CLOCKING_MODE           = "common_clock",
    parameter string ECC_BIT_RANGE           = "7:0",
    parameter string ECC_MODE                = "no_ecc",
    parameter string ECC_TYPE                = "none",
    parameter int    IGNORE_INIT_SYNTH       = 0,
    parameter string MEMORY_INIT_FILE        = "none",
    parameter string MEMORY_INIT_PARAM       = "0",
    parameter string MEMORY_OPTIMIZATION     = "true",
    parameter string MEMORY_PRIMITIVE        = "auto",
    parameter int    MEMORY_SIZE             = 32768,
    parameter int    MESSAGE_CONTROL         = 0,
    parameter string RAM_DECOMP              = "auto",
    parameter int    READ_DATA_WIDTH_B       = 32,
    parameter int    READ_LATENCY_B          = 1,
    parameter string READ_RESET_VALUE_B      = "0",
    parameter string RST_MODE_A              = "SYNC",
    parameter string RST_MODE_B              = "SYNC",
    parameter int    SIM_ASSERT_CHK          = 0,
    parameter int    USE_EMBEDDED_CONSTRAINT = 0,
    parameter int    USE_MEM_INIT            = 1,
    parameter int    USE_MEM_INIT_MMI        = 0,
    parameter string WAKEUP_TIME             = "disable_sleep",
    parameter int    WRITE_DATA_WIDTH_A      = 32,
    parameter string WRITE_MODE_B            = "no_change",
    parameter int    WRITE_PROTECT           = 1
) (
    input  wire                                                       clka,
    input  wire                                                       ena,
    input  wire [(WRITE_DATA_WIDTH_A+BYTE_WRITE_WIDTH_A-1)/BYTE_WRITE_WIDTH_A-1:0] wea,
    input  wire [ADDR_WIDTH_A-1:0]                                    addra,
    input  wire [WRITE_DATA_WIDTH_A-1:0]                              dina,
    input  wire                                                       injectdbiterra,
    input  wire                                                       injectsbiterra,
    input  wire                                                       clkb,
    input  wire                                                       rstb,
    input  wire                                                       enb,
    input  wire                                                       regceb,
    input  wire [ADDR_WIDTH_B-1:0]                                    addrb,
    output logic [READ_DATA_WIDTH_B-1:0]                              doutb,
    output wire                                                       dbiterrb,
    output wire                                                       sbiterrb,
    input  wire                                                       sleep
);

  localparam int DataWidth = (WRITE_DATA_WIDTH_A > READ_DATA_WIDTH_B) ? WRITE_DATA_WIDTH_A : READ_DATA_WIDTH_B;
  localparam int AddrWidth = (ADDR_WIDTH_A > ADDR_WIDTH_B) ? ADDR_WIDTH_A : ADDR_WIDTH_B;

  logic [DataWidth-1:0] mem[2**AddrWidth];
  logic [DataWidth-1:0] rd_pipe[READ_LATENCY_B];

  always_ff @(posedge clka) begin
    if (ena && (|wea)) begin
      mem[addra] <= {{(DataWidth-WRITE_DATA_WIDTH_A){1'b0}}, dina};
    end
  end

  always_ff @(posedge clkb) begin
    if (rstb) begin
      rd_pipe[0] <= '0;
    end else if (enb) begin
      rd_pipe[0] <= mem[addrb];
    end
  end

  generate
    for (genvar i = 1; i < READ_LATENCY_B; i++) begin : g_rd_pipe
      always_ff @(posedge clkb) begin
        if (rstb) begin
          rd_pipe[i] <= '0;
        end else if (regceb) begin
          rd_pipe[i] <= rd_pipe[i-1];
        end
      end
    end
  endgenerate

  always_comb begin
    doutb = rd_pipe[READ_LATENCY_B-1][READ_DATA_WIDTH_B-1:0];
  end

  assign dbiterrb = 1'b0;
  assign sbiterrb = 1'b0;

  wire unused_xpm_memory_sdpram = &{
    1'b0,
    32'(AUTO_SLEEP_TIME),
    32'(CASCADE_HEIGHT),
    (CLOCKING_MODE == "common_clock"),
    (ECC_BIT_RANGE == "7:0"),
    (ECC_MODE == "no_ecc"),
    (ECC_TYPE == "none"),
    32'(IGNORE_INIT_SYNTH),
    (MEMORY_INIT_FILE == "none"),
    (MEMORY_INIT_PARAM == "0"),
    (MEMORY_OPTIMIZATION == "true"),
    (MEMORY_PRIMITIVE == "auto"),
    32'(MEMORY_SIZE),
    32'(MESSAGE_CONTROL),
    (RAM_DECOMP == "auto"),
    (READ_RESET_VALUE_B == "0"),
    (RST_MODE_A == "SYNC"),
    (RST_MODE_B == "SYNC"),
    32'(SIM_ASSERT_CHK),
    32'(USE_EMBEDDED_CONSTRAINT),
    32'(USE_MEM_INIT),
    32'(USE_MEM_INIT_MMI),
    (WAKEUP_TIME == "disable_sleep"),
    (WRITE_MODE_B == "no_change"),
    32'(WRITE_PROTECT),
    regceb,
    injectdbiterra,
    injectsbiterra,
    sleep
  };

endmodule

`default_nettype wire

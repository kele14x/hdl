`timescale 1 ns / 1 ps
//
`default_nettype none

module xpm_memory_tdpram #(
    parameter int    ADDR_WIDTH_A            = 10,
    parameter int    ADDR_WIDTH_B            = 10,
    parameter int    AUTO_SLEEP_TIME         = 0,
    parameter int    BYTE_WRITE_WIDTH_A      = 32,
    parameter int    BYTE_WRITE_WIDTH_B      = 32,
    parameter int    CASCADE_HEIGHT          = 0,
    parameter string CLOCKING_MODE           = "common_clock",
    parameter string ECC_MODE                = "no_ecc",
    parameter string MEMORY_INIT_FILE        = "none",
    parameter string MEMORY_INIT_PARAM       = "0",
    parameter string MEMORY_OPTIMIZATION     = "true",
    parameter string MEMORY_PRIMITIVE        = "auto",
    parameter int    MEMORY_SIZE             = 32768,
    parameter int    MESSAGE_CONTROL         = 0,
    parameter int    READ_DATA_WIDTH_A       = 32,
    parameter int    READ_DATA_WIDTH_B       = 32,
    parameter int    READ_LATENCY_A          = 1,
    parameter int    READ_LATENCY_B          = 1,
    parameter string READ_RESET_VALUE_A      = "0",
    parameter string READ_RESET_VALUE_B      = "0",
    parameter string RST_MODE_A              = "SYNC",
    parameter string RST_MODE_B              = "SYNC",
    parameter int    SIM_ASSERT_CHK          = 0,
    parameter int    USE_EMBEDDED_CONSTRAINT = 0,
    parameter int    USE_MEM_INIT            = 1,
    parameter int    USE_MEM_INIT_MMI        = 0,
    parameter string WAKEUP_TIME             = "disable_sleep",
    parameter int    WRITE_DATA_WIDTH_A      = 32,
    parameter int    WRITE_DATA_WIDTH_B      = 32,
    parameter string WRITE_MODE_A            = "no_change",
    parameter string WRITE_MODE_B            = "no_change",
    parameter int    WRITE_PROTECT           = 1
) (
    input  wire                                                       clka,
    input  wire                                                       rsta,
    input  wire                                                       ena,
    input  wire [(WRITE_DATA_WIDTH_A+BYTE_WRITE_WIDTH_A-1)/BYTE_WRITE_WIDTH_A-1:0] wea,
    input  wire [ADDR_WIDTH_A-1:0]                                    addra,
    input  wire                                                       regcea,
    input  wire [WRITE_DATA_WIDTH_A-1:0]                              dina,
    output logic [READ_DATA_WIDTH_A-1:0]                              douta,
    input  wire                                                       injectdbiterra,
    input  wire                                                       injectsbiterra,
    output wire                                                       dbiterra,
    output wire                                                       sbiterra,
    input  wire                                                       clkb,
    input  wire                                                       rstb,
    input  wire                                                       enb,
    input  wire [(WRITE_DATA_WIDTH_B+BYTE_WRITE_WIDTH_B-1)/BYTE_WRITE_WIDTH_B-1:0] web,
    input  wire [ADDR_WIDTH_B-1:0]                                    addrb,
    input  wire                                                       regceb,
    input  wire [WRITE_DATA_WIDTH_B-1:0]                              dinb,
    output logic [READ_DATA_WIDTH_B-1:0]                              doutb,
    input  wire                                                       injectdbiterrb,
    input  wire                                                       injectsbiterrb,
    output wire                                                       dbiterrb,
    output wire                                                       sbiterrb,
    input  wire                                                       sleep
);

  localparam int DataWidthAB = (WRITE_DATA_WIDTH_A > WRITE_DATA_WIDTH_B) ? WRITE_DATA_WIDTH_A : WRITE_DATA_WIDTH_B;
  localparam int DataWidth = (DataWidthAB > READ_DATA_WIDTH_A) ? ((DataWidthAB > READ_DATA_WIDTH_B) ? DataWidthAB : READ_DATA_WIDTH_B) : ((READ_DATA_WIDTH_A > READ_DATA_WIDTH_B) ? READ_DATA_WIDTH_A : READ_DATA_WIDTH_B);
  localparam int AddrWidth = (ADDR_WIDTH_A > ADDR_WIDTH_B) ? ADDR_WIDTH_A : ADDR_WIDTH_B;

  logic [DataWidth-1:0] mem[2**AddrWidth];
  logic [DataWidth-1:0] rd_pipe_a[READ_LATENCY_A];
  logic [DataWidth-1:0] rd_pipe_b[READ_LATENCY_B];

  always_ff @(posedge clka) begin
    if (ena && (|wea)) begin
      mem[AddrWidth'(addra)] <= {{(DataWidth-WRITE_DATA_WIDTH_A){1'b0}}, dina};
    end
    if (rsta) begin
      rd_pipe_a[0] <= '0;
    end else if (ena) begin
      rd_pipe_a[0] <= mem[AddrWidth'(addra)];
    end
  end

  always_ff @(posedge clkb) begin
    if (enb && (|web)) begin
      mem[AddrWidth'(addrb)] <= {{(DataWidth-WRITE_DATA_WIDTH_B){1'b0}}, dinb};
    end
    if (rstb) begin
      rd_pipe_b[0] <= '0;
    end else if (enb) begin
      rd_pipe_b[0] <= mem[AddrWidth'(addrb)];
    end
  end

  generate
    for (genvar i = 1; i < READ_LATENCY_A; i++) begin : g_rd_pipe_a
      always_ff @(posedge clka) begin
        if (rsta) begin
          rd_pipe_a[i] <= '0;
        end else if (regcea) begin
          rd_pipe_a[i] <= rd_pipe_a[i-1];
        end
      end
    end

    for (genvar i = 1; i < READ_LATENCY_B; i++) begin : g_rd_pipe_b
      always_ff @(posedge clkb) begin
        if (rstb) begin
          rd_pipe_b[i] <= '0;
        end else if (regceb) begin
          rd_pipe_b[i] <= rd_pipe_b[i-1];
        end
      end
    end
  endgenerate

  always_comb begin
    douta = rd_pipe_a[READ_LATENCY_A-1][READ_DATA_WIDTH_A-1:0];
    doutb = rd_pipe_b[READ_LATENCY_B-1][READ_DATA_WIDTH_B-1:0];
  end

  assign dbiterra = 1'b0;
  assign sbiterra = 1'b0;
  assign dbiterrb = 1'b0;
  assign sbiterrb = 1'b0;

  wire unused_xpm_memory_tdpram = &{
    1'b0,
    32'(AUTO_SLEEP_TIME),
    32'(CASCADE_HEIGHT),
    (CLOCKING_MODE == "common_clock"),
    (ECC_MODE == "no_ecc"),
    (MEMORY_INIT_FILE == "none"),
    (MEMORY_INIT_PARAM == "0"),
    (MEMORY_OPTIMIZATION == "true"),
    (MEMORY_PRIMITIVE == "auto"),
    32'(MEMORY_SIZE),
    32'(MESSAGE_CONTROL),
    (READ_RESET_VALUE_A == "0"),
    (READ_RESET_VALUE_B == "0"),
    (RST_MODE_A == "SYNC"),
    (RST_MODE_B == "SYNC"),
    32'(SIM_ASSERT_CHK),
    32'(USE_EMBEDDED_CONSTRAINT),
    32'(USE_MEM_INIT),
    32'(USE_MEM_INIT_MMI),
    (WAKEUP_TIME == "disable_sleep"),
    (WRITE_MODE_A == "no_change"),
    (WRITE_MODE_B == "no_change"),
    32'(WRITE_PROTECT),
    regcea,
    injectdbiterra,
    injectsbiterra,
    injectdbiterrb,
    injectsbiterrb,
    sleep
  };

endmodule

`default_nettype wire

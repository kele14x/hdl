// File: oran_deframer_dl_ss_hdr_buffer
// Brief: Section header buffer for O-RAM deframer DL
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_deframer_dl_ss_hdr_buffer #(
    parameter int BUFFER_SYMBOL = 10
) (
    input var                              clk,
    input var                              rst,
    //
    input var                              timer_sos,
    //
    input var  [                     39:0] s_axis_header_tdata,
    input var                              s_axis_header_tvalid,
    input var  [$clog2(BUFFER_SYMBOL)-1:0] s_axis_header_tuser,
    //
    input var  [$clog2(BUFFER_SYMBOL)-1:0] buffer_rd_bank,
    input var  [                      3:0] buffer_rd_addr,
    input var                              buffer_rd_en,
    output var [                     40:0] buffer_rd_dout
);

  // Each symbol is stored in dedicate bank
  // Each bank has 16 depth, which should be enough
  localparam int AddrWidth = 4;
  // Stores only data
  localparam int DataWidth = 40;

  // Buffer write signal

  logic [AddrWidth-1:0] wr_addr     [BUFFER_SYMBOL];
  logic                 wr_en       [BUFFER_SYMBOL];
  logic [DataWidth-1:0] wr_din      [BUFFER_SYMBOL];

  // Buffer read signal

  logic [AddrWidth-1:0] rd_addr     [BUFFER_SYMBOL];
  logic                 rd_en       [BUFFER_SYMBOL];
  logic [DataWidth-1:0] rd_dout     [BUFFER_SYMBOL];

  logic                 rd_dv       [BUFFER_SYMBOL];

  logic                 ram_dbiterrb[BUFFER_SYMBOL];
  logic                 ram_sbiterrb[BUFFER_SYMBOL];

  logic                 valid_flag  [BUFFER_SYMBOL] [2**AddrWidth];


  // Write side
  //-----------

  generate
    for (genvar i = 0; i < BUFFER_SYMBOL; i++) begin : g_write

      assign wr_en[i]  = s_axis_header_tvalid && (s_axis_header_tuser == i);

      assign wr_din[i] = s_axis_header_tdata;

      always_ff @(posedge clk) begin
        if (rst) begin
          wr_addr[i] <= '0;
        end else if (buffer_rd_bank == i && timer_sos) begin
          wr_addr[i] <= '0;
        end else if (wr_en[i]) begin
          wr_addr[i] <= wr_addr[i] + 1;
        end
      end

    end
  endgenerate


  // Read side
  //----------

  generate
    for (genvar i = 0; i < BUFFER_SYMBOL; i++) begin : g_read

      // Make sure we readout write bank (symbol), so pointer is managed by buffer
      // itself
      assign rd_addr[i] = buffer_rd_addr;

      assign rd_en[i]   = buffer_rd_en && (buffer_rd_bank == i);

    end
  endgenerate

  // Data output demux
  assign buffer_rd_dout = {rd_dv[buffer_rd_bank], rd_dout[buffer_rd_bank]};


  // The buffer
  //-----------

  generate
    for (genvar i = 0; i < BUFFER_SYMBOL; i++) begin : g_sym

`ifdef XILINX
      xpm_memory_sdpram #(
          .ADDR_WIDTH_A           (AddrWidth),
          .ADDR_WIDTH_B           (AddrWidth),
          .AUTO_SLEEP_TIME        (0),
          .BYTE_WRITE_WIDTH_A     (DataWidth),
          .CASCADE_HEIGHT         (0),
          .CLOCKING_MODE          ("common_clock"),
          .ECC_MODE               ("no_ecc"),
          .MEMORY_INIT_FILE       ("none"),
          .MEMORY_INIT_PARAM      ("0"),
          .MEMORY_OPTIMIZATION    ("true"),
          .MEMORY_PRIMITIVE       ("distributed"),
          .MEMORY_SIZE            (DataWidth * (2 ** AddrWidth)),
          .MESSAGE_CONTROL        (0),
          .READ_DATA_WIDTH_B      (DataWidth),
          .READ_LATENCY_B         (1),
          .READ_RESET_VALUE_B     ("0"),
          .RST_MODE_A             ("SYNC"),
          .RST_MODE_B             ("SYNC"),
          .SIM_ASSERT_CHK         (0),
          .USE_EMBEDDED_CONSTRAINT(0),
          .USE_MEM_INIT           (1),
          .USE_MEM_INIT_MMI       (0),
          .WAKEUP_TIME            ("disable_sleep"),
          .WRITE_DATA_WIDTH_A     (DataWidth),
          .WRITE_MODE_B           ("read_first"),
          .WRITE_PROTECT          (1)
      ) i_valid_ram (
          //
          .clka          (clk),
          .ena           (wr_en[i]),
          .wea           (wr_en[i]),
          .addra         (wr_addr[i]),
          .dina          (wr_din[i]),
          //
          .injectsbiterra(1'b0),
          .injectdbiterra(1'b0),
          //
          .clkb          (clk),
          .rstb          (1'b0),
          .enb           (rd_en[i]),
          .regceb        (1'b1),
          .addrb         (rd_addr[i]),
          .doutb         (rd_dout[i]),
          .dbiterrb      (ram_dbiterrb[i]),
          .sbiterrb      (ram_sbiterrb[i]),
          //
          //
          .sleep         (1'b0)
      );
`else
      ram_sdp #(
          .ADDR_WIDTH  (AddrWidth),
          .DATA_WIDTH  (DataWidth),
          .READ_LATENCY(1),
          .INIT_WORD   ('0),
          .INIT_FILE   ("")
      ) i_valid_ram (
          .clka (clk),
          .ena  (wr_en[i]),
          .wea  (wr_en[i]),
          .addra(wr_addr[i]),
          .dina (wr_din[i]),
          .clkb (clk),
          .rstb (1'b0),
          .enb  (rd_en[i]),
          .addrb(rd_addr[i]),
          .doutb(rd_dout[i])
      );

      assign ram_dbiterrb[i] = 1'b0;
      assign ram_sbiterrb[i] = 1'b0;
`endif

      wire unused_ram_status = &{1'b0, ram_dbiterrb[i], ram_sbiterrb[i]};

      // Valid flag
      always_ff @(posedge clk) begin
        if (rst) begin
          valid_flag[i] <= '{2 ** AddrWidth{'0}};
        end else if (wr_en[i]) begin
          valid_flag[i][wr_addr[i]] <= 1'b1;
        end else if (rd_en[i]) begin
          valid_flag[i][rd_addr[i]] <= 1'b0;
        end
      end

      always_ff @(posedge clk) begin
        if (rst) begin
          rd_dv[i] <= '0;
        end else if (rd_en[i]) begin
          rd_dv[i] <= valid_flag[i][rd_addr[i]];
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire

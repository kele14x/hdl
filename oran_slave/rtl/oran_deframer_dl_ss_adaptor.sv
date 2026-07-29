// File: oran_deframer_dl_ss_adaptor.sv
// Brief: This module receives DL IQ data, and write to next module.
//        The input data should be split into sections and each packet holds
//        a section. Section header is provided at TUSER port.
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_deframer_dl_ss_adaptor #(
    parameter int ADAPTOR_SIZE = 1024
) (
    input var         clk,
    input var         rst,
    // Timer
    input var  [ 7:0] timer_frame,
    input var         timer_sof,
    input var         timer_sos,
    input var  [32:0] timer_frac,
    // Defm data
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    input var  [31:0] s_axis_tuser,       // section header
    // Lowphy
    output var [ 7:0] dl_syml_frame,
    output var        dl_syml_sof,
    output var        dl_syml_sos,
    output var [32:0] dl_syml_frac,
    output var [31:0] dl_syml_data,
    output var        dl_syml_valid,
    // Control & Status
    input var  [11:0] ctrl_syml_rd_shift
);

  // Address width of adaptor, 32-bit width
  localparam int AddrWidth = $clog2(ADAPTOR_SIZE);

  // Signals
  //--------

  logic [         11:0] section_sectionid;
  logic                 section_rb;
  logic                 section_syminc;
  logic [          9:0] section_startprbu;
  logic [          7:0] section_numprbu;

  logic [          7:0] current_frame;
  logic [         32:0] current_frac;
  logic [         14:0] current_sample;
  logic                 current_is_sof;

  // Write 2 REs at each clock tick
  logic [AddrWidth-2:0] syml_wr_addr;
  logic                 syml_wr_en;
  logic [         63:0] syml_wr_data;

  // Read 1 REs at each clock tick
  logic [AddrWidth-1:0] syml_rd_cnt;
  logic                 syml_rd_run;

  logic [AddrWidth-1:0] syml_rd_addr;
  logic                 syml_rd_en;
  logic                 syml_rd_en_d;
  logic [         31:0] syml_rd_data;

  logic [         63:0] ram_douta;
  logic                 ram_dbiterra;
  logic                 ram_sbiterra;
  logic                 ram_dbiterrb;
  logic                 ram_sbiterrb;

  wire unused_ram_outputs = &{
    1'b0,
    ram_douta,
    ram_dbiterra,
    ram_sbiterra,
    ram_dbiterrb,
    ram_sbiterrb
  };

  logic                 synced;

  wire unused_section_fields = &{
    1'b0,
    s_axis_tkeep,
    section_sectionid,
    section_rb,
    section_syminc,
    section_numprbu
  };


  // Main
  //-----

  // TUSER signal mapping

  assign {
    section_sectionid,
    section_rb,
    section_syminc,
    section_startprbu,
    section_numprbu
  } = s_axis_tuser;


  // An state flag to sync with AXIS packet

  always_ff @(posedge clk) begin
    if (rst) begin
      synced <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      synced <= 1'b0;
    end else if (s_axis_tvalid) begin
      synced <= 1'b1;
    end
  end

  // Symbol write address increases at each data tick. Write address is RE
  // number divided by 2;
  always_ff @(posedge clk) begin
    if (s_axis_tvalid && !synced) begin
      syml_wr_addr <= (AddrWidth - 1)'({1'b0, section_startprbu} * 6);
    end else if (s_axis_tvalid) begin
      syml_wr_addr <= syml_wr_addr + {{(AddrWidth - 2){1'b0}}, 1'b1};
    end
  end

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      syml_wr_en <= 1'b1;
    end else begin
      syml_wr_en <= 1'b0;
    end
  end

  // AXI4-Stream data to RAM data mapping
  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      syml_wr_data <= {
        s_axis_tdata[55:48],  // Q1[15:8]
        s_axis_tdata[63:56],  // Q1[7:0]
        s_axis_tdata[39:32],  // I1[15:8]
        s_axis_tdata[47:40],  // I1[7:0]
        s_axis_tdata[23:16],  // Q0[15:8]
        s_axis_tdata[31:24],  // Q0[7:0]
        s_axis_tdata[7:0],  // I0[15:8]
        s_axis_tdata[15:8]  // I0[7:0]
      };
    end
  end

  // Sample counter

  always_ff @(posedge clk) begin
    if (rst) begin
      current_frame <= '0;
    end else if (timer_sof) begin
      current_frame <= timer_frame;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      current_frac <= '0;
    end else if (timer_sof) begin
      current_frac <= timer_frac;
    end
  end

  always_ff @(posedge clk) begin
    if (rst | timer_sos) begin
      current_sample <= '0;
    end else begin
      current_sample <= current_sample + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      current_is_sof <= 1'b0;
    end else if (timer_sos && timer_sof) begin
      current_is_sof <= 1'b1;
    end else if (timer_sos) begin
      current_is_sof <= 1'b0;
    end
  end


  // Generate symbol buffer reader signal
  // TODO: This assumes all section data is write into adaptor buffer at 1000th
  //       clock tick, this may not valid

  always_ff @(posedge clk) begin
    if (current_sample == 1000) begin
      syml_rd_cnt <= '0;
    end else if (syml_rd_run) begin
      syml_rd_cnt <= syml_rd_cnt + {{(AddrWidth - 1){1'b0}}, 1'b1};
    end
  end

  always_ff @(posedge clk) begin
    if (current_sample == 1000) begin
      syml_rd_run <= 1'b1;
    end else if (&syml_rd_cnt) begin
      syml_rd_run <= 1'b0;
    end
  end

  // The RD shift value controls which RE we starts to read. For example, for
  // 4096 FFT size, read RE at 1638 gives a proper sequence for iFFT transform.
  always_ff @(posedge clk) begin
    syml_rd_addr <= AddrWidth'(syml_rd_cnt + ctrl_syml_rd_shift);
    syml_rd_en   <= syml_rd_run;
  end

  always_ff @(posedge clk) begin
    syml_rd_en_d <= syml_rd_en;
  end


  // Output

  always_ff @(posedge clk) begin
    if ((current_sample == 1003) && current_is_sof) begin
      dl_syml_frame <= current_frame;
    end
  end

  always_ff @(posedge clk) begin
    if ((current_sample == 1003) && current_is_sof) begin
      dl_syml_sof <= 1'b1;
    end else begin
      dl_syml_sof <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (current_sample == 1003) begin
      dl_syml_sos <= 1'b1;
    end else begin
      dl_syml_sos <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if ((current_sample == 1003) && current_is_sof) begin
      dl_syml_frac <= current_frac;
    end
  end

  assign dl_syml_data = syml_rd_data;

  always_ff @(posedge clk) begin
    dl_syml_valid <= syml_rd_en_d;
  end

  // Instance the RAM
  // The RAM is 64-bit write and 32-bit read RAM

`ifdef XILINX
  xpm_memory_tdpram #(
      .ADDR_WIDTH_A           (AddrWidth - 1),
      .ADDR_WIDTH_B           (AddrWidth),
      .AUTO_SLEEP_TIME        (0),
      .BYTE_WRITE_WIDTH_A     (64),
      .BYTE_WRITE_WIDTH_B     (32),
      .CASCADE_HEIGHT         (0),
      .CLOCKING_MODE          ("common_clock"),
      .ECC_MODE               ("no_ecc"),
      .MEMORY_INIT_FILE       ("none"),
      .MEMORY_INIT_PARAM      ("0"),
      .MEMORY_OPTIMIZATION    ("true"),
      .MEMORY_PRIMITIVE       ("block"),
      .MEMORY_SIZE            (2 ** AddrWidth * 32),
      .MESSAGE_CONTROL        (0),
      .READ_DATA_WIDTH_A      (64),
      .READ_DATA_WIDTH_B      (32),
      .READ_LATENCY_A         (1),
      .READ_LATENCY_B         (2),
      .READ_RESET_VALUE_A     ("0"),
      .READ_RESET_VALUE_B     ("0"),
      .RST_MODE_A             ("SYNC"),
      .RST_MODE_B             ("SYNC"),
      .SIM_ASSERT_CHK         (0),
      .USE_EMBEDDED_CONSTRAINT(0),
      .USE_MEM_INIT           (1),
      .USE_MEM_INIT_MMI       (0),
      .WAKEUP_TIME            ("disable_sleep"),
      .WRITE_DATA_WIDTH_A     (64),
      .WRITE_DATA_WIDTH_B     (32),
      .WRITE_MODE_A           ("no_change"),
      .WRITE_MODE_B           ("read_first"),
      .WRITE_PROTECT          (1)
  ) xpm_memory_sdpram_inst (
      // Write side
      .clka          (clk),
      .rsta          (1'b0),
      .ena           (syml_wr_en),
      .wea           (syml_wr_en),
      .addra         (syml_wr_addr),
      .regcea        (1'b1),
      .dina          (syml_wr_data),
      .douta         (ram_douta),
      //
      .injectdbiterra('0),
      .injectsbiterra('0),
      .dbiterra      (ram_dbiterra),
      .sbiterra      (ram_sbiterra),
      //
      // Read side
      .clkb          (clk),
      .rstb          (1'b0),
      .enb           (syml_rd_en),
      .web           (syml_rd_en),
      .addrb         (syml_rd_addr),
      .regceb        (syml_rd_en_d),
      .dinb          ('0),
      .doutb         (syml_rd_data),
      //
      .injectdbiterrb('0),
      .injectsbiterrb('0),
      .dbiterrb      (ram_dbiterrb),
      .sbiterrb      (ram_sbiterrb),
      //
      //
      .sleep         ('0)
  );
`else
  ram_tdp_asym #(
      .ADDR_WIDTH_A(AddrWidth - 1),
      .DATA_WIDTH_A(64),
      .OUTPUT_REG_A(1'b0),
      .WRITE_MODE_A("NO_CHANGE"),
      .ADDR_WIDTH_B(AddrWidth),
      .DATA_WIDTH_B(32),
      .OUTPUT_REG_B(1'b1),
      .WRITE_MODE_B("READ_FIRST"),
      .INIT_FILE   (""),
      .RAM_STYLE   ("BLOCK")
  ) i_syml_ram (
      .clka (clk),
      .rsta (1'b0),
      .ena  (syml_wr_en),
      .wea  (syml_wr_en),
      .addra(syml_wr_addr),
      .dina (syml_wr_data),
      .douta(ram_douta),
      .clkb (clk),
      .rstb (2'b00),
      .enb  ({syml_rd_en_d, syml_rd_en}),
      .web  (syml_rd_en),
      .addrb(syml_rd_addr),
      .dinb ('0),
      .doutb(syml_rd_data)
  );

  assign ram_dbiterra = 1'b0;
  assign ram_sbiterra = 1'b0;
  assign ram_dbiterrb = 1'b0;
  assign ram_sbiterrb = 1'b0;
`endif

endmodule

`default_nettype wire

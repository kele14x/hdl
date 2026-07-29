// File: oran_framer_ul_ss_adaptor.sv
// Brief: Buffer UL symbol data, the working flow is like:
//          1. UL DFE send one symbol data to adaptor
//          2. Adaptor buffer this symbol into RAM
//          3. After first 4k sample of symbol is buffered, adaptor raise SOF/SOS
//             flag to controller. Then switch to next buffer for next symbol
//          4. Controller send req* to adaptor
//          5. Adaptor output required PRBs to master AXIS i/f
//        Due to the reading/writing conflict, ping-pong buffer is needed
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_framer_ul_ss_adaptor #(
    parameter int ADAPTOR_SIZE = 1024
) (
    input var         clk,
    input var         rst,
    //
    input var  [ 7:0] req_frameid,
    input var  [ 3:0] req_subframeid,
    input var  [ 5:0] req_slotid,
    input var  [ 5:0] req_symbolid,
    input var  [ 9:0] req_startprb,
    input var  [ 7:0] req_numprb,
    input var         req_valid,
    output var        req_ready,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    output var [63:0] m_axis_tuser,
    //
    input var  [ 7:0] ul_syml_frame,
    input var         ul_syml_sof,
    input var         ul_syml_sos,
    input var  [31:0] ul_syml_data,
    input var         ul_syml_valid,
    //
    output var [ 7:0] ul_ctrl_frame,
    output var        ul_ctrl_sof,
    output var        ul_ctrl_sos,
    // Control I/F
    //------------
    input var  [11:0] ctrl_syml_rd_shift
);

  // Buffer address width per bank, so 2x for ping-pong buffer
  localparam int AddrWidth = $clog2(ADAPTOR_SIZE);

  // Signals
  //--------

  // Application Header (32-bit)
  logic        app_datadirection = 1'b0;  // 0 for UL, 1 for DL
  logic [ 2:0] app_payloadversion = 3'b001;
  logic [ 3:0] app_filterindex = 4'b0;
  logic [ 7:0] app_frameid;
  logic [ 3:0] app_subframeid;
  logic [ 5:0] app_slotid;
  logic [ 5:0] app_symbolid;

  logic [31:0] app_header;

  // Section Header (32-bit)
  logic [11:0] section_sectionid = 12'b0;
  logic        section_rb = 1'b0;
  logic        section_syminc = 1'b0;
  logic [ 9:0] section_startprbu;
  logic [ 7:0] section_numprbu;

  logic [31:0] section_header;

  // FSM
  typedef enum int {
    S_RST,
    S_IDLE,
    S_WAIT0,
    S_WAIT1,
    S_WAIT2,
    S_WR
  } state_t;

  state_t state, state_next;

  // Write 1 REs at each clock tick

  logic                 syml_wr_run;
  logic                 syml_wr_is_sof;

  logic                 syml_wr_bank;
  logic [AddrWidth-1:0] syml_wr_addr;
  logic [  AddrWidth:0] syml_wr_addr_f;
  logic                 syml_wr_en;
  logic [         31:0] syml_wr_data;

  // Read 2 REs at each clock tick
  logic                 syml_rd_bank;
  logic [AddrWidth-2:0] syml_rd_addr;
  logic [AddrWidth-1:0] syml_rd_addr_f;
  logic                 syml_rd_en;
  logic                 syml_rd_en_d;
  logic [         63:0] syml_rd_data;

  logic [AddrWidth-2:0] syml_rd_addr_max;

  logic [         31:0] ram_douta;
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

  logic                 m_axis_tlast_pre;


  // Main
  //-----

  always_ff @(posedge clk) begin
    if (req_valid && req_ready) begin
      app_frameid <= req_frameid;
      app_subframeid <= req_subframeid;
      app_slotid <= req_slotid;
      app_symbolid <= req_symbolid;
    end
  end

  assign app_header = {
    app_datadirection,
    app_payloadversion,
    app_filterindex,
    app_frameid,
    app_subframeid,
    app_slotid,
    app_symbolid
  };

  always_ff @(posedge clk) begin
    if (req_valid && req_ready) begin
      section_startprbu <= req_startprb;
      section_numprbu   <= req_numprb;
    end
  end

  assign section_header = {
    section_sectionid, section_rb, section_syminc, section_startprbu, section_numprbu
  };


  // FSM
  //----

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    // Stay at current state by default
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_IDLE;
      end

      S_IDLE: begin
        if (req_valid) begin
          state_next = S_WAIT0;
        end
      end

      S_WAIT0: begin
        state_next = S_WAIT1;
      end

      S_WAIT1: begin
        state_next = S_WR;
      end

      S_WR: begin
        if (syml_rd_addr == syml_rd_addr_max) begin
          state_next = S_IDLE;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (state == S_IDLE && req_valid) begin
      syml_rd_addr_max <= (AddrWidth - 1)'((32'({1'b0, req_startprb}) + 32'({3'b0, req_numprb})) * 32'd6 - 32'd1 + 32'(ctrl_syml_rd_shift));
    end
  end

  assign req_ready = (state == S_IDLE);


  // Write symbol data to buffer
  // write bank is ping-pong (0/1) switched

  always_ff @(posedge clk) begin
    if (rst) begin
      syml_wr_run <= 1'b0;
    end else if (ul_syml_sos) begin
      syml_wr_run <= 1'b1;
    end else if (&syml_wr_addr) begin
      syml_wr_run <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (ul_syml_sof) begin
      syml_wr_is_sof <= 1'b1;
    end else if (ul_syml_sos) begin
      syml_wr_is_sof <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (ul_syml_sof) begin
      syml_wr_bank <= 1'b0;
    end else if (ul_syml_sos) begin
      syml_wr_bank <= ~syml_wr_bank;
    end
  end

  always_ff @(posedge clk) begin
    if (ul_syml_sos) begin
      syml_wr_addr <= '0;
    end else if (&syml_wr_addr) begin
      syml_wr_addr <= '0;
    end else if (ul_syml_valid && syml_wr_run) begin
      syml_wr_addr <= syml_wr_addr + 1;
    end
  end

  assign syml_wr_addr_f = {syml_wr_bank, syml_wr_addr};

  always_ff @(posedge clk) begin
    syml_wr_en <= ul_syml_sos || (ul_syml_valid && syml_wr_run);
  end

  always_ff @(posedge clk) begin
    syml_wr_data <= ul_syml_data;
  end


  // Control

  always_ff @(posedge clk) begin
    if (syml_wr_is_sof && &syml_wr_addr) begin
      ul_ctrl_frame <= ul_syml_frame;
    end
  end

  always_ff @(posedge clk) begin
    ul_ctrl_sof <= syml_wr_is_sof && &syml_wr_addr;
  end

  always_ff @(posedge clk) begin
    ul_ctrl_sos <= &syml_wr_addr;
  end


  // Read symbol data from buffer
  // read bank is pong-ping switched

  always_ff @(posedge clk) begin
    if (ul_ctrl_sof) begin
      syml_rd_bank <= 1'b0;
    end else if (ul_ctrl_sos) begin
      syml_rd_bank <= ~syml_rd_bank;
    end
  end

  assign syml_rd_addr_f = {syml_rd_bank, syml_rd_addr};

  always_ff @(posedge clk) begin
    syml_rd_en_d <= syml_rd_en;
  end

  always_ff @(posedge clk) begin
    if (state == S_IDLE && req_valid) begin
      syml_rd_addr <= (AddrWidth - 1)'({1'b0, req_startprb} * 6 + ctrl_syml_rd_shift);
    end else if (state == S_WR) begin
      syml_rd_addr <= syml_rd_addr + {{(AddrWidth - 2){1'b0}}, 1'b1};
    end
  end

  assign syml_rd_en = (state == S_WR);


  // Master AXIS

  // AXI IQ byte mapping
  // The latency from req_valid && req_ready handshake to TDATA is 5 clock
  // ticks, including 3 FSM delay and 2 RAM latency.
  always_comb begin
    m_axis_tdata[7:0]   = syml_rd_data[15:8];  // I0 [15:8]
    m_axis_tdata[15:8]  = syml_rd_data[7:0];  // I0 [ 7:0]
    m_axis_tdata[23:16] = syml_rd_data[31:24];  // Q0 [15:8]
    m_axis_tdata[31:24] = syml_rd_data[23:16];  // Q0 [ 7:0]
    m_axis_tdata[39:32] = syml_rd_data[47:40];  // I1 [15:8]
    m_axis_tdata[47:40] = syml_rd_data[39:32];  // I1 [ 7:0]
    m_axis_tdata[55:48] = syml_rd_data[63:56];  // Q1 [15:8]
    m_axis_tdata[63:56] = syml_rd_data[55:48];  // Q1 [ 7:0]
  end

  always_ff @(posedge clk) begin
    m_axis_tvalid <= syml_rd_en_d;
  end

  assign m_axis_tkeep = '1;

  always_ff @(posedge clk) begin
    m_axis_tlast_pre <= (syml_rd_addr == syml_rd_addr_max);
    m_axis_tlast     <= m_axis_tlast_pre;
  end

  // The latency from req_valid & req_ready handshake to TUSER is 2 clock ticks,
  // which should be aligned with TDATA
  always_ff @(posedge clk) begin
    m_axis_tuser <= {app_header, section_header};
  end

  // Instance the RAM
  // The RAM is 64-bit write and 32-bit read RAM. Depth is 8192 (32-bit) for
  // ping-pong switch.

`ifdef XILINX
  xpm_memory_tdpram #(
      .ADDR_WIDTH_A           (AddrWidth + 1),
      .ADDR_WIDTH_B           (AddrWidth),
      .AUTO_SLEEP_TIME        (0),
      .BYTE_WRITE_WIDTH_A     (32),
      .BYTE_WRITE_WIDTH_B     (64),
      .CASCADE_HEIGHT         (0),
      .CLOCKING_MODE          ("common_clock"),
      .ECC_MODE               ("no_ecc"),
      .MEMORY_INIT_FILE       ("none"),
      .MEMORY_INIT_PARAM      ("0"),
      .MEMORY_OPTIMIZATION    ("true"),
      .MEMORY_PRIMITIVE       ("block"),
      .MEMORY_SIZE            (2 ** AddrWidth * 2 * 32),
      .MESSAGE_CONTROL        (0),
      .READ_DATA_WIDTH_A      (32),
      .READ_DATA_WIDTH_B      (64),
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
      .WRITE_DATA_WIDTH_A     (32),
      .WRITE_DATA_WIDTH_B     (64),
      .WRITE_MODE_A           ("no_change"),
      .WRITE_MODE_B           ("read_first"),
      .WRITE_PROTECT          (1)
  ) xpm_memory_sdpram_inst (
      // Write side
      .clka          (clk),
      .rsta          (1'b0),
      .ena           (syml_wr_en),
      .wea           (syml_wr_en),
      .addra         (syml_wr_addr_f),
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
      .rstb          (~syml_rd_en_d),
      .enb           (syml_rd_en),
      .web           (syml_rd_en),
      .addrb         (syml_rd_addr_f),
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
      .ADDR_WIDTH_A(AddrWidth + 1),
      .DATA_WIDTH_A(32),
      .OUTPUT_REG_A(1'b0),
      .WRITE_MODE_A("NO_CHANGE"),
      .ADDR_WIDTH_B(AddrWidth),
      .DATA_WIDTH_B(64),
      .OUTPUT_REG_B(1'b1),
      .WRITE_MODE_B("READ_FIRST"),
      .INIT_FILE   (""),
      .RAM_STYLE   ("BLOCK")
  ) i_syml_ram (
      .clka (clk),
      .rsta (1'b0),
      .ena  (syml_wr_en),
      .wea  (syml_wr_en),
      .addra(syml_wr_addr_f),
      .dina (syml_wr_data),
      .douta(ram_douta),
      .clkb (clk),
      .rstb ({~syml_rd_en_d, 1'b0}),
      .enb  ({ syml_rd_en_d, syml_rd_en}),
      .web  (syml_rd_en),
      .addrb(syml_rd_addr_f),
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

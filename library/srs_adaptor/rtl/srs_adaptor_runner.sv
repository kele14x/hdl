// file: srs_adaptor_controller_req.sv
// brief: Forward necessary SRS C-Plane message to next module as SRS
//        configuration.
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_runner (
    // 400M
    //======
    input var         clk_400m,
    input var         rst_400m,
    // SRS Request
    input var  [15:0] srs_run_rtc_pc_id,
    input var  [ 2:0] srs_run_cc,
    //
    input var  [ 7:0] srs_run_frameid,
    input var  [ 3:0] srs_run_subframeid,
    input var  [ 5:0] srs_run_slotid,
    input var  [ 5:0] srs_run_symbolid,
    input var  [11:0] srs_run_symbol,
    //
    input var  [ 7:0] srs_run_numprbc,
    input var  [ 9:0] srs_run_startprbc,
    input var  [11:0] srs_run_sectionid,
    //
    input var  [ 2:0] srs_run_ethport,
    //
    input var         srs_run_valid,
    output var        srs_run_ready,
    // Frame Request
    //==============
    output var [ 2:0] fram_req_eth_port,
    output var [15:0] fram_req_rtc_pc_id,
    output var [63:0] fram_req_header,
    output var [ 9:0] fram_req_start_rb,
    output var [ 7:0] fram_req_num_rb,
    output var        fram_req_bank,
    output var        fram_req_valid,
    input var         fram_req_ready,
    //
    input var  [10:0] bram_rd_addr,        // 0 ~ 1024
    input var         bram_rd_rden,        // !connect to all registers in output pipe
    output var [95:0] bram_rd_data,        // 4 RE
    // DFE
    //====
    input var         clk_491m52,
    input var         rst_491m52,
    //
    input var  [23:0] srs_data_tdata,
    input var         srs_data_tlast,
    input var         srs_data_tvalid,
    output var        srs_data_tready,
    // SRS Request
    output var [ 2:0] srs_req_cc,
    output var [ 5:0] srs_req_layer,
    output var [11:0] srs_req_symbol,
    output var        srs_req_valid
);


  // Signals
  //========

  logic srs_run_bank;
  logic srs_req_bank;
  
  logic srs_data_ready;
  logic srs_data_done;

  // Application Header (8-byte)

  localparam [0:0] oran_data_direction = 1'b0;  // 0: UL; 1: DL;
  localparam [2:0] oran_payload_version = 3'd1;
  localparam [3:0] oran_filter_index = 4'd0;

  logic [31:0] oran_application_header;

  // Section Header

  localparam [0:0] oran_rb = 1'b0;
  localparam [0:0] oran_symbol_inc = 1'b0;

  logic [31:0] oran_section_header;

  logic [12:0] bram_wr_addr;
  logic        bram_wr_en;
  logic [23:0] bram_wr_data;

  // Let do a single thread state machine first
  typedef enum int {
    S_IDLE,  // Nothing doing
    S_REQ,   // Send request to DFE, wait CDC done
    S_DATA,  // Wait data transfer done
    S_FRAM   // Send frame request to framer, wait framer done
  } state_t;

  state_t state, state_next;

  logic [20:0] srs_req_in;
  logic        srs_req_send;
  logic        srs_req_rcv;


  // FSM
  //====

  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      state <= S_IDLE;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    case (state)
      S_IDLE:  state_next = srs_run_valid ? S_REQ : S_IDLE;
      S_REQ:   state_next = srs_req_rcv ? S_DATA : S_REQ;
      S_DATA:  state_next = srs_data_done ? S_FRAM : S_DATA;
      S_FRAM:  state_next = fram_req_ready ? S_IDLE : S_FRAM;
      default: state_next = S_IDLE;
    endcase
  end

  always_ff @(posedge clk_400m) begin
    srs_run_ready <= state_next == S_IDLE;
  end

  always_ff @(posedge clk_400m) begin
    srs_data_ready <= state_next == S_DATA;
  end

  // Requst data from DFE
  //=====================

  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      srs_run_bank <= 1'b0;
    end else if (state == S_IDLE && srs_run_valid) begin
      srs_run_bank <= ~srs_run_bank;
    end
  end

  always_ff @(posedge clk_400m) begin
    if (state == S_IDLE && srs_run_valid) begin
      srs_req_in <= {srs_run_bank, srs_run_cc, srs_run_rtc_pc_id[5:0], srs_run_symbol};
    end
  end

  always_ff @(posedge clk_400m) begin
    srs_req_send <= (state_next == S_REQ);
  end

  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (22)
  ) xpm_cdc_handshake_inst (
      .src_clk (clk_400m),
      .src_in  (srs_req_in),
      .src_send(srs_req_send),
      .src_rcv (srs_req_rcv),
      //
      .dest_clk(clk_491m52),
      .dest_out({srs_req_bank, srs_req_cc, srs_req_layer, srs_req_symbol}),
      .dest_req(srs_req_valid),
      .dest_ack(  /* Not used */)
  );

  xpm_cdc_array_single #(
      .DEST_SYNC_FF  (4),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_INPUT_REG (0),
      .WIDTH         (1)
  ) xpm_cdc_array_single_inst (
      .src_clk (  /* Not used */),
      .src_in  (srs_data_ready),
      .dest_clk(clk_491m52),
      .dest_out(srs_data_tready)
  );

  xpm_cdc_pulse #(
      .DEST_SYNC_FF  (4),
      .INIT_SYNC_FF  (0),
      .REG_OUTPUT    (1),
      .RST_USED      (1),
      .SIM_ASSERT_CHK(0)
  ) xpm_cdc_pulse_inst (
      .src_clk   (clk_491m52),
      .src_rst   (rst_491m52),
      .src_pulse (srs_data_tvalid && srs_data_tlast),
      //
      .dest_clk  (clk_400m),
      .dest_rst  (rst_400m),
      .dest_pulse(srs_data_done)
  );

  // Wait framer done
  //=================

  assign oran_application_header = {
    oran_data_direction,
    oran_payload_version,
    oran_filter_index,
    srs_run_frameid,
    srs_run_subframeid,
    srs_run_slotid,
    srs_run_symbolid
  };

  assign oran_section_header = {
    srs_run_sectionid, oran_rb, oran_symbol_inc, srs_run_startprbc, srs_run_numprbc
  };

  always_ff @(posedge clk_400m) begin
    if (state == S_IDLE && srs_run_valid) begin
      fram_req_eth_port  <= srs_run_ethport;
      fram_req_rtc_pc_id <= srs_run_rtc_pc_id;
      fram_req_header    <= {oran_application_header, oran_section_header};
      fram_req_start_rb  <= srs_run_startprbc;
      fram_req_num_rb    <= srs_run_numprbc;
      fram_req_bank      <= srs_run_bank;
    end
  end

  always_ff @(posedge clk_400m) begin
    fram_req_valid <= (state_next == S_FRAM);
  end

  srs_adaptor_writer i_srs_adaptor_writer (
      // DFE
      //====
      .clk            (clk_491m52),
      .rst            (rst_491m52),
      //
      .srs_data_tdata (srs_data_tdata),  // {4'b exponent, 9'b mantissa Q, 9'b mantissa I}
      .srs_data_tvalid(srs_data_tvalid),
      .srs_data_tlast (srs_data_tlast),
      //
      .wr_addr        (bram_wr_addr[11:0]),
      .wr_en          (bram_wr_en),
      .wr_data        (bram_wr_data)
  );

  always_ff @(posedge clk_491m52) begin
    if (srs_req_valid) begin
      bram_wr_addr[12] <= srs_req_bank;
    end
  end

  srs_adaptor_bram i_srs_adaptor_bram (
      // Write port
      .clka (clk_491m52),
      .addra(bram_wr_addr),  // 0 ~ 4096
      .ena  (bram_wr_en),
      .wea  (bram_wr_en),  // 1 RE
      .dina (bram_wr_data),
      // Read port
      .clkb (clk_400m),
      .rstb (rst_400m),
      .addrb(bram_rd_addr),  // 0 ~ 1024
      .enb  (bram_rd_rden),  // !connect to all registers in output pipe
      .doutb(bram_rd_data)
  );

endmodule

`default_nettype wire

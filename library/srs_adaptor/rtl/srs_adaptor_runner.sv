// file: srs_adaptor_runner.sv
// brief: This module is SRS request executor, when it received SRS request
//        information from `srs_run_*` ports, it do:
//          1. Forward the request to DFE at `srs_req_*` ports
//          2. Wait DFE module send back one symbol data from `srs_data_*`
//             ports
//          3. While DFE send data, write them to a BRAM buffer. It will also
//             handles the PING-PONG buffer switch
//          4. After one symbol data is done, tell framer to pack it into a
//             packet
//        During the framer packing the packet, this runner could try to request
//        next symbol data from DFE.
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_runner (
    // 400M
    //======
    input var         clk_400m,
    input var         rst_400m,
    // SRS Request
    input var  [ 2:0] srs_run_cc,
    input var  [ 5:0] srs_run_layer,
    input var  [11:0] srs_run_symbol,
    //
    input var  [15:0] srs_run_rtc_pc_id,
    //
    input var  [ 7:0] srs_run_frameid,
    input var  [ 3:0] srs_run_subframeid,
    input var  [ 5:0] srs_run_slotid,
    input var  [ 5:0] srs_run_symbolid,
    //
    input var  [ 3:0] srs_run_numsymbol,
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
    output var [15:0] fram_req_rtc_pc_id,
    //
    output var [ 7:0] fram_req_frameid,
    output var [ 3:0] fram_req_subframeid,
    output var [ 5:0] fram_req_slotid,
    output var [ 5:0] fram_req_symbolid,
    //
    output var [ 3:0] fram_req_numsymbol,
    output var [ 7:0] fram_req_numprbc,
    output var [ 9:0] fram_req_startprbc,
    output var [11:0] fram_req_sectionid,
    //
    output var [ 2:0] fram_req_ethport,
    //
    output var        fram_req_valid,
    input var         fram_req_ready,
    // DFE
    //====
    input var         clk_491m52,
    input var         rst_491m52,
    // SRS Request
    output var [ 2:0] srs_req_cc,
    output var [ 5:0] srs_req_layer,
    output var [11:0] srs_req_symbol,
    output var        srs_req_valid,
    //
    input var  [23:0] srs_data_tdata,
    input var         srs_data_tlast,
    input var         srs_data_tvalid,
    output var        srs_data_tready,
    // BRAM Writer
    output var        bram_bank,            // !@clk_400m
    //
    output var [11:0] bram_wr_addr,         // 4096
    output var        bram_wr_en,           //
    output var [23:0] bram_wr_data          // 1 RE
);


  // Signals
  //========

  // Data wait CDC
  // During the state machine, we need to checking the `srs_req_*` AXIS
  // interface. However, the AXIS interface is on `clk_491m` clock doamin, so
  // CDC is need here. These signals are CDCed signals at `clk_400m` doamin.
  logic srs_data_ready;
  logic srs_data_valid;
  logic srs_data_done;  // last & valid


  // Runner state machine
  typedef enum int {
    S_RST,   // Under reset
    S_IDLE,  // Nothing doing
    S_WAIT,  // Wait data transfer start
    S_DATA,  // Wait data transfer done
    S_FRAM   // Send frame request to framer, wait framer done
  } state_t;

  state_t state, state_next;

  // Request CDC
  logic [20:0] srs_req_in, srs_req_prev, srs_req_out;  // width = 3 + 6 + 12
  logic       srs_req_send;
  logic       srs_req_rcv;

  logic       srs_req_new;

  logic [7:0] srs_wait_cnt;


  // FSM
  //====
  // It will try to accept SRS run request (`srs_run_valid`) when IDLE

  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    case (state)
      S_RST:   state_next = S_IDLE;
      S_IDLE:  state_next = ~srs_run_valid ? S_IDLE : srs_req_new ? S_WAIT : S_FRAM;
      S_WAIT:  state_next = srs_data_valid ? S_DATA : (&srs_wait_cnt ? S_IDLE : S_WAIT);
      S_DATA:  state_next = srs_data_done ? S_FRAM : S_DATA;
      S_FRAM:  state_next = fram_req_ready ? S_IDLE : S_FRAM;
      default: state_next = S_RST;
    endcase
  end

  always_ff @(posedge clk_400m) begin
    srs_run_ready <= (state_next == S_IDLE);
  end


  // Send Requst to DFE
  //===================
  // This also covers CDC

  assign srs_req_new = {srs_run_cc, srs_run_layer, srs_run_symbol} != srs_req_prev;

  // When one SRS run request is accepted, register them at srs_req_in register
  // since the data will not change.
  always_ff @(posedge clk_400m) begin
    if (state == S_IDLE && srs_run_valid) begin
      if (srs_req_new) begin
        srs_req_in <= {srs_run_cc, srs_run_layer, srs_run_symbol};
      end
    end
  end

  // We do not want request same symbol again and again. If controller request
  // differenct section of same symbol, we pass the request.
  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      srs_req_prev <= '1;
    end else if (state == S_IDLE && srs_run_valid) begin
      if (srs_req_new) begin
        srs_req_prev <= {srs_run_cc, srs_run_layer, srs_run_symbol};
      end
    end
  end

  // Set CDC HS send flag. It takes few clock ticks to complate the CDC HS.
  // We assume the request will not come too offten so the previous CDC HS is
  // always done. Thus we does not check `srs_req_send` and `srs_req_rcv`.
  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      srs_req_send <= '0;
    end else if (state == S_IDLE && srs_run_valid) begin
      if (srs_req_new) begin
        srs_req_send <= 1'b1;
      end
    end else if (srs_req_rcv) begin
      srs_req_send <= 1'b0;
    end
  end


  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (21)
  ) xpm_cdc_srs_req (
      .src_clk (clk_400m),
      .src_in  (srs_req_in),
      .src_send(srs_req_send),
      .src_rcv (srs_req_rcv),
      //
      .dest_clk(clk_491m52),
      .dest_out(srs_req_out),
      .dest_req(srs_req_valid),
      .dest_ack(  /* Not used */)
  );

  assign {srs_req_cc, srs_req_layer, srs_req_symbol} = srs_req_out;


  // Get Data from DFE
  //==================

  always_ff @(posedge clk_400m) begin
    srs_data_ready <= (state_next == S_DATA || state_next == S_WAIT);
  end

  // When one symbol data is received, switch PING-PONG bank, then this
  // information will send to framer, it will read right bank.
  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      bram_bank <= 1'b0;
    end else if (state == S_DATA && srs_data_done) begin
      bram_bank <= ~bram_bank;
    end
  end

  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      srs_wait_cnt <= '0;
    end else if (state_next == S_WAIT) begin
      srs_wait_cnt <= srs_wait_cnt + 1;
    end else begin
      srs_wait_cnt <= '0;
    end
  end


  xpm_cdc_single #(
      .DEST_SYNC_FF  (4),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_INPUT_REG (0)
  ) xpm_cdc_srs_data_tready (
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
  ) xpm_cdc_srs_data_valid (
      .src_clk   (clk_491m52),
      .src_rst   (rst_491m52),
      .src_pulse (srs_data_tvalid),
      //
      .dest_clk  (clk_400m),
      .dest_rst  (rst_400m),
      .dest_pulse(srs_data_valid)
  );

  xpm_cdc_pulse #(
      .DEST_SYNC_FF  (4),
      .INIT_SYNC_FF  (0),
      .REG_OUTPUT    (1),
      .RST_USED      (1),
      .SIM_ASSERT_CHK(0)
  ) xpm_cdc_srs_data_done (
      .src_clk   (clk_491m52),
      .src_rst   (rst_491m52),
      .src_pulse (srs_data_tvalid && srs_data_tlast),
      //
      .dest_clk  (clk_400m),
      .dest_rst  (rst_400m),
      .dest_pulse(srs_data_done)
  );


  always_ff @(posedge clk_491m52) begin
    if (rst_491m52) begin
      bram_wr_en <= 0;
    end else begin
      bram_wr_en <= srs_data_tvalid && srs_data_tready;
    end
  end

  always_ff @(posedge clk_491m52) begin
    if (~srs_data_tready) begin
      bram_wr_addr <= '0;
    end else if (bram_wr_en) begin
      bram_wr_addr <= bram_wr_addr + 1;
    end
  end

  always_ff @(posedge clk_491m52) begin
    bram_wr_data <= srs_data_tdata;
  end


  // Wait framer done
  //=================

  always_ff @(posedge clk_400m) begin
    if (state == S_IDLE && srs_run_valid) begin
      fram_req_rtc_pc_id  <= srs_run_rtc_pc_id;
      //
      fram_req_frameid    <= srs_run_frameid;
      fram_req_subframeid <= srs_run_subframeid;
      fram_req_slotid     <= srs_run_slotid;
      fram_req_symbolid   <= srs_run_symbolid;
      //
      fram_req_numsymbol  <= srs_run_numsymbol;
      fram_req_numprbc    <= srs_run_numprbc;
      fram_req_startprbc  <= srs_run_startprbc;
      fram_req_sectionid  <= srs_run_sectionid;
      //
      fram_req_ethport    <= srs_run_ethport;
    end
  end

  always_ff @(posedge clk_400m) begin
    fram_req_valid <= (state_next == S_FRAM);
  end

endmodule

`default_nettype wire

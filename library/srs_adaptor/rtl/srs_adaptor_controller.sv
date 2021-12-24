// file: srs_adaptor_controller.sv
// brief: This module controls when to run the processing of SRS symbol.
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_controller #(
    parameter int NUM_CC      = 2,
    parameter int NUM_LAYER   = 64,
    parameter int NUM_SECTION = 8
) (
    // XORIF
    //======
    input var         clk,
    input var         rst,
    // UL Timing
    input var  [11:0] s_ul_sym_num      [NUM_CC],
    input var         s_ul_update       [NUM_CC],
    // SRS Mux
    input var  [ 2:0] srs_mux_cc,
    input var  [ 5:0] srs_mux_layer,
    input var  [11:0] srs_mux_symbol,
    //
    input var  [15:0] srs_mux_rtc_pc_id,
    //
    input var  [ 7:0] srs_mux_frameid,
    input var  [ 3:0] srs_mux_subframeid,
    input var  [ 5:0] srs_mux_slotid,
    input var  [ 5:0] srs_mux_symbolid,
    //
    input var  [ 3:0] srs_mux_numsymbol,           // 1 ~ 3
    input var  [ 7:0] srs_mux_numprbc,             // 0 ~ 275
    input var  [ 9:0] srs_mux_startprbc,           // 0 ~ 275
    input var  [11:0] srs_mux_sectionid,
    //
    input var  [ 2:0] srs_mux_ethport,             // 0 ~ 3
    //
    input var         srs_mux_valid,
    // Runner
    //=======
    output var [ 2:0] srs_run_cc,
    output var [ 5:0] srs_run_layer,
    output var [11:0] srs_run_symbol,
    //
    output var [15:0] srs_run_rtc_pc_id,
    //
    output var [ 7:0] srs_run_frameid,
    output var [ 3:0] srs_run_subframeid,
    output var [ 5:0] srs_run_slotid,
    output var [ 5:0] srs_run_symbolid,
    //
    output var [ 3:0] srs_run_numsymbol,
    output var [ 7:0] srs_run_numprbc,
    output var [ 9:0] srs_run_startprbc,
    output var [11:0] srs_run_sectionid,
    //
    output var [ 2:0] srs_run_ethport,
    //
    output var        srs_run_valid,
    input var         srs_run_ready,
    // Control
    //========
    input var         ctrl_srs_en,
    output var        error_fifo_full
);


  // Local Parameters
  //=================

  localparam int CcWidth = $clog2(NUM_CC) == 0 ? 1 : $clog2(NUM_CC);  // 1
  localparam int LayerWidth = $clog2(NUM_LAYER);  // 6
  localparam int SectionWidth = $clog2(NUM_SECTION);  // 3

  localparam int BufferAddrWidth = CcWidth + LayerWidth + SectionWidth;
  localparam int BufferDataWidth = 99;


  // SRS Control Message Buffer
  //===========================

  logic [BufferAddrWidth-1:0] buffer_wr_addr;
  logic                       buffer_wr_en;
  logic [BufferDataWidth-1:0] buffer_wr_data;

  logic [BufferAddrWidth-1:0] buffer_rd_addr;
  logic                       buffer_rd_en;
  logic                       buffer_clr_en;
  logic [BufferDataWidth-1:0] buffer_rd_data;


  // SRS message write to this buffer
  // It will be cleared once readout in C-Plane mode, but not be cleared in
  // M-Plane mode.
  srs_adaptor_controller_tdp i_srs_adaptor_controller_tdp (
      .clka (clk),
      .ena  (buffer_wr_en),
      .wea  (buffer_wr_en),
      .addra(buffer_wr_addr),
      .dina (buffer_wr_data),
      .douta(  /* not used */),
      //
      .clkb (clk),
      .enb  (buffer_rd_en),
      .web  (buffer_clr_en),
      .addrb(buffer_rd_addr),
      .dinb (99'b0),
      .doutb(buffer_rd_data)
  );


  // Buffer Write Address
  // ====================
  // Since at every symbol time, we need to loop the buffer and pick up the
  // valid control message to process. To reduce the buffer traverse time, the
  // control message must be stored based on CC and Layer.
  //
  // Every CC x Layer has few dedicate memory space (defined be NUM_SECTION).
  // The write address is constructed by {CC, Layer, SectionIndex}. To avoid
  // write address conflict, each CC x Layer should has it's own section index,
  // which is a counter that increase by 1 every time a new control message is
  // stored. Those section index may not be reset to 0, since in any case the
  // whole buffer is looped.

  logic [BufferAddrWidth-1:0] buffer_wr_addr_s;

  logic [        CcWidth-1:0] buffer_wr_addr_cc;
  logic [     LayerWidth-1:0] buffer_wr_addr_layer;
  logic [   SectionWidth-1:0] buffer_wr_addr_section;

  (* ram_style="distributed" *)
  logic [   SectionWidth-1:0] section_index          [NUM_CC * NUM_LAYER];  // 128 depth


  initial begin
    for (int i = 0; i < NUM_CC * NUM_LAYER; i++) begin
      section_index[i] <= '0;
    end
  end

  assign buffer_wr_addr_cc      = srs_mux_cc[CcWidth-1:0];
  assign buffer_wr_addr_layer   = srs_mux_layer[LayerWidth-1:0];
  assign buffer_wr_addr_section = section_index[{buffer_wr_addr_cc, buffer_wr_addr_layer}];

  assign buffer_wr_addr_s       = {buffer_wr_addr_cc, buffer_wr_addr_layer, buffer_wr_addr_section};

  // section_index ram's asynchronous output (latency 0) has dirctly feedback
  // to it's input, this enables write operation at every clock tick. The
  // timing seems be fine.
  always @(posedge clk) begin
    if (srs_mux_valid) begin
      section_index[{
        buffer_wr_addr_cc, buffer_wr_addr_layer
      }] <= section_index[{buffer_wr_addr_cc, buffer_wr_addr_layer}] + 1;
    end
  end


  // Buffer Writer
  //==============

  typedef enum int {
    S_WR_RST,
    S_WR_INIT,
    S_WR_CLR,
    S_WR_WAIT,
    S_WR_OP
  } wr_state_t;

  wr_state_t wr_state, wr_state_next;


  always_ff @(posedge clk) begin
    if (rst) begin
      wr_state <= S_WR_RST;
    end else begin
      wr_state <= wr_state_next;
    end
  end

  always_comb begin
    case (wr_state)
      S_WR_RST:  wr_state_next = S_WR_INIT;
      S_WR_INIT: wr_state_next = S_WR_CLR;
      S_WR_CLR:  wr_state_next = &buffer_wr_addr ? S_WR_WAIT : S_WR_CLR;
      S_WR_WAIT: wr_state_next = ctrl_srs_en ? S_WR_OP : S_WR_WAIT;
      S_WR_OP:   wr_state_next = ctrl_srs_en ? S_WR_OP : S_WR_RST;
      default:   wr_state_next = S_WR_RST;
    endcase
  end


  always_ff @(posedge clk) begin
    if (wr_state_next == S_WR_OP) begin
      buffer_wr_data <= {
        srs_mux_valid,
        //
        srs_mux_cc,
        srs_mux_layer,
        srs_mux_symbol,
        //
        srs_mux_rtc_pc_id,
        //
        srs_mux_frameid,
        srs_mux_subframeid,
        srs_mux_slotid,
        srs_mux_symbolid,
        //
        srs_mux_numsymbol,
        srs_mux_numprbc,
        srs_mux_startprbc,
        srs_mux_sectionid,
        //
        srs_mux_ethport
      };
    end else begin
      buffer_wr_data <= '0;
    end
  end

  always_ff @(posedge clk) begin
    if (wr_state_next == S_WR_OP) begin
      buffer_wr_en <= srs_mux_valid;
    end else if (wr_state_next == S_WR_CLR) begin
      buffer_wr_en <= 1'b1;
    end else begin
      buffer_wr_en <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (wr_state_next == S_WR_OP) begin
      buffer_wr_addr <= buffer_wr_addr_s;
    end else if (wr_state_next == S_WR_CLR) begin
      buffer_wr_addr <= buffer_wr_addr + 1;
    end else begin
      buffer_wr_addr <= '1;
    end
  end


  // Symbol to Process
  //==================

  logic                init_cc    [NUM_CC];

  logic [CcWidth+11:0] fifo_din;
  logic                fifo_full;
  logic                fifo_wr_en;

  logic                fifo_rd_en;
  logic                fifo_empty;
  logic [CcWidth+11:0] fifo_dout;


  // FWFT FIFO with width (CcWidth + 12). We need this fifo since we may spend
  // more than 1 symbol time to process all layer x all section control
  // message for one SRS symbol. In this case, we need to pick up the symbols
  // just missed. For none-SRS symbols, the FIFO should be just pushed and then
  // pop empty. So any FIFO depth should be OK.
  srs_adaptor_controller_fifo i_srs_adaptor_controller_fifo (
      .clk        (clk),
      .srst       (rst),
      //
      .din        (fifo_din),
      .full       (fifo_full),
      .wr_en      (fifo_wr_en),
      //
      .rd_en      (fifo_rd_en),
      .empty      (fifo_empty),
      .dout       (fifo_dout),
      //
      .wr_rst_busy(  /* not used */),
      .rd_rst_busy(  /* not used */)
  );


  // Two CC may required to be processed at same time (in the case of same SC
  // spacing). So request/ack handshake mechanism is used here.
  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_init_cc

      always_ff @(posedge clk) begin
        if (s_ul_update[cc]) begin
          init_cc[cc] <= 1'b1;
        end else if (init_cc[cc]) begin
          // First CC first
          for (int i = 0; i <= cc; i++) begin
            if (init_cc[i] && i < cc) begin
              break;
            end else begin
              init_cc[cc] <= 1'b0;
            end
          end
        end
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    for (int cc = 0; cc < NUM_CC; cc++) begin
      if (init_cc[cc]) begin
        fifo_din <= {cc[NUM_CC-1:0], s_ul_sym_num[cc]};
        break;
      end
    end
  end

  always_ff @(posedge clk) begin
    for (int cc = 0; cc < NUM_CC; cc++) begin
      fifo_wr_en <= 1'b0;
      if (init_cc[cc]) begin
        fifo_wr_en <= 1'b1;
        break;
      end
    end
  end

  // assume the FIFO will never full
  assign error_fifo_full = fifo_full;


  // Buffer Reader
  //==============

  typedef enum int {
    S_RD_RST,
    S_RD_IDLE,
    S_RD_ADDR,
    S_RD_D1,
    S_RD_D2,
    S_RD_DATA,
    S_RD_CHK,
    S_RD_VALID
  } rd_state_t;

  rd_state_t rd_state, rd_state_next;


  logic process_it;

  logic [2:0] current_cc;
  logic [11:0] current_symbol;

  logic [LayerWidth+SectionWidth-1:0] layer_section_cnt;

  logic srs_run_valid_s;


  always_ff @(posedge clk) begin
    if (rst) begin
      rd_state <= S_RD_RST;
    end else begin
      rd_state <= rd_state_next;
    end
  end

  always_comb begin
    case (rd_state)
      S_RD_RST: rd_state_next = S_RD_IDLE;
      S_RD_IDLE: rd_state_next = ~fifo_empty ? S_RD_ADDR : S_RD_IDLE;
      S_RD_ADDR: rd_state_next = S_RD_D1;
      S_RD_D1: rd_state_next = S_RD_D2;
      S_RD_D2: rd_state_next = S_RD_DATA;
      S_RD_DATA: rd_state_next = S_RD_CHK;
      S_RD_CHK:
      rd_state_next = process_it ? S_RD_VALID : (&layer_section_cnt) ? S_RD_IDLE : S_RD_ADDR;
      S_RD_VALID:
      rd_state_next = ~srs_run_ready ? S_RD_VALID : (&layer_section_cnt) ? S_RD_IDLE : S_RD_ADDR;
      default: rd_state_next = S_RD_RST;
    endcase
  end

  always_ff @(posedge clk) begin
    fifo_rd_en <= (rd_state_next == S_RD_IDLE);
  end

  always_ff @(posedge clk) begin
    if (rd_state == S_RD_IDLE && ~fifo_empty) begin
      {current_cc, current_symbol} <= fifo_dout;
    end
  end

  // Flag the section that needs to process
  // Remember we need to process all sections belong to same symbol, same cc, and
  // same layer together. Then could we move to next layer, next cc.
  // Thanks to the buffer is arranged in order, we could go pass the buffer for
  // just one time.
  always_ff @(posedge clk) begin
    process_it <= srs_run_valid_s &&
      (current_cc == srs_run_cc) &&
      (current_symbol >= srs_run_symbol) &&
      (current_symbol <= srs_run_symbol + srs_run_numsymbol - 1);
  end

  // Read address
  always_ff @(posedge clk) begin
    if (rd_state_next == S_RD_ADDR) begin
      layer_section_cnt <= layer_section_cnt + 1;
    end else if (rd_state_next == S_RD_IDLE) begin
      layer_section_cnt <= '1;
    end else begin
      layer_section_cnt <= layer_section_cnt;
    end
  end

  assign buffer_rd_addr = {current_cc, layer_section_cnt};

  // Read enable
  always_ff @(posedge clk) begin
    buffer_rd_en <= (rd_state_next == S_RD_ADDR) ||
        (rd_state_next == S_RD_D1) ||
        (rd_state_next == S_RD_D2) ||
        (rd_state_next == S_RD_DATA) ||
        (rd_state_next == S_RD_CHK);
  end

  // Clear the buffer memory
  always_ff @(posedge clk) begin
    buffer_clr_en <= (rd_state_next == S_RD_CHK) && process_it;
  end


  // Output
  //=======

  assign {srs_run_valid_s,
      //
      srs_run_cc, srs_run_layer, srs_run_symbol,
      //
      srs_run_rtc_pc_id,
      //
      srs_run_frameid, srs_run_subframeid, srs_run_slotid, srs_run_symbolid,
      //
      srs_run_numsymbol, srs_run_numprbc, srs_run_startprbc, srs_run_sectionid,
      //
      srs_run_ethport} = buffer_rd_data;

  always_ff @(posedge clk) begin
    if (rst) begin
      srs_run_valid <= 1'b0;
    end else begin
      srs_run_valid <= (rd_state_next == S_RD_VALID);
    end
  end

endmodule

`default_nettype wire

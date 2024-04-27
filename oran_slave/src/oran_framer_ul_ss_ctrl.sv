`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_framer_ul_ss_ctrl (
    input var         clk,
    input var         rst,
    //
    input var  [ 7:0] ul_frame,
    input var         ul_sof,
    input var         ul_sos,
    //
    output var [ 7:0] req_app_frameid,
    output var [ 3:0] req_app_subframeid,
    output var [ 5:0] req_app_slotid,
    output var [ 5:0] req_app_symbolid,
    output var [ 9:0] req_section_startprbu,
    output var [ 7:0] req_section_numprbu,
    output var        req_valid,
    input var         req_ready,
    // Control & Status
    //-----------------
    input var         ctrl_clk,
    input var         ctrl_rst,
    //
    input var  [ 3:0] ctrl_buf_wr_addr,
    input var         ctrl_buf_wr_en,
    input var         ctrl_buf_wr_we,
    input var  [31:0] ctrl_buf_wr_din,
    output var [31:0] ctrl_buf_wr_dout,
    //
    input var  [ 4:0] ctrl_mask_wr_addr,
    input var         ctrl_mask_wr_en,
    input var         ctrl_mask_wr_we,
    input var  [31:0] ctrl_mask_wr_din,
    output var [31:0] ctrl_mask_wr_dout
);

  localparam int BufferDepth = 16;
  localparam int BufferWidth = 33;  // 32-bit section data + 1-bit valid flag

  logic                           section_header_valid;
  logic [                   11:0] section_sectionid;
  logic                           section_rb;
  logic                           section_syminc;
  logic [                    9:0] section_startprbu;
  logic [                    7:0] section_numprbu;

  // {pcid, start_prbu, number_prbu, valid}
  logic [        BufferWidth-1:0] ctrl_buffer                      [BufferDepth];

  logic [                   13:0] mask_buffer                      [         20];

  logic                           symbol_mask;

  logic [                    7:0] current_frame;  // 0 ~ 255
  logic [                    4:0] current_subframe_slot;  // 0 ~ 19
  logic [                    3:0] current_symbol;  // 0 ~ 13

  logic [$clog2(BufferDepth)-1:0] buffer_rd_addr;
  logic                           buffer_rd_en;
  logic [        BufferWidth-1:0] buffer_rd_data;

  typedef enum int {
    S_RST,
    S_IDLE,
    S_MASK,
    S_RD,
    S_REQ
  } state_t;

  state_t state, state_next;

  //
  // This function helps you build a line of section control message in
  // buffer, using start PRB and number PRB
  //
  function static logic [32:0] build_ctrl_buffer(input logic [9:0] startprb,
                                                 input logic [7:0] numprb);
    return {1'b1, 12'd0, 1'b0, 1'b0, startprb, numprb};
  endfunction


  // Main
  //-----

  // Initialize the control buffer. Currently use a static configuration, which
  // is 10 sections per antenna
  initial begin
    for (int i = 0; i < BufferDepth; i++) begin
      ctrl_buffer[i] = '0;
    end
    // ctrl_buffer[0] = build_ctrl_buffer(0, 30);
    // ctrl_buffer[1] = build_ctrl_buffer(30, 30);
    // ctrl_buffer[2] = build_ctrl_buffer(60, 30);
    // ctrl_buffer[3] = build_ctrl_buffer(90, 30);
    // ctrl_buffer[4] = build_ctrl_buffer(120, 30);
    // ctrl_buffer[5] = build_ctrl_buffer(150, 30);
    // ctrl_buffer[6] = build_ctrl_buffer(180, 30);
    // ctrl_buffer[7] = build_ctrl_buffer(210, 30);
    // ctrl_buffer[8] = build_ctrl_buffer(240, 30);
    // ctrl_buffer[9] = build_ctrl_buffer(270, 3);
  end

  // Control buffer write

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_buf_wr_en) begin
      ctrl_buf_wr_dout <= ctrl_buffer[ctrl_buf_wr_addr][31:0];
    end
  end

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_buf_wr_en && ctrl_buf_wr_we) begin
      if (ctrl_buf_wr_din[7:0] == '0) begin
        // if numprb is 0, deassert the valid flag
        ctrl_buffer[ctrl_buf_wr_addr] <= {1'b0, ctrl_buf_wr_din};
      end else begin
        ctrl_buffer[ctrl_buf_wr_addr] <= {1'b1, ctrl_buf_wr_din};
      end
    end
  end

  // Master buffer write

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_mask_wr_en) begin
      ctrl_mask_wr_dout <= {18'b0, mask_buffer[ctrl_mask_wr_addr]};
    end
  end

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_mask_wr_en && ctrl_mask_wr_we) begin
      mask_buffer[ctrl_mask_wr_addr] <= ctrl_mask_wr_din[13:0];
    end
  end

  // Frame/Subframe/Slot/Symbol counter

  always_ff @(posedge clk) begin
    if (ul_sof) begin
      current_frame <= ul_frame;
    end
  end

  always_ff @(posedge clk) begin
    if (rst | ul_sof) begin
      current_subframe_slot <= '0;
    end else if (ul_sos && current_symbol == 13) begin
      current_subframe_slot <= current_subframe_slot + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst | ul_sof) begin
      current_symbol <= '0;
    end else if (ul_sos && current_symbol == 13) begin
      current_symbol <= '0;
    end else if (ul_sos) begin
      current_symbol <= current_symbol + 1;
    end
  end


  // FSM
  //----
  // This FSM loops the control buffer when Start of Symbol (SOS) signal
  // arrives. Each line in control buffer repsent a section message we need to
  // send to DU. The control information is end to req_* ports with `req_valid`
  // assert. The adpator module in UL will do the packaging, and replies with
  // `req_ready`. Then we can go to next line. After loop all lines, the FSM
  // goes to idle. We assume all lines will be done befoer next SOS.

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
        if (ul_sos) begin
          state_next = S_MASK;
        end
      end

      S_MASK: begin
        if (symbol_mask) begin
          state_next = S_RD;
        end else begin
          state_next = S_IDLE;
        end
      end

      S_RD: begin
        state_next = S_REQ;
      end

      S_REQ: begin
        if (~req_valid || req_ready) begin
          // This line of buffer is not valid or (is valid and) request is
          // accepted by next module
          if (&buffer_rd_addr) begin
            state_next = S_IDLE;
          end else begin
            state_next = S_RD;
          end
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end


  // Buffer read

  // buffer_rd_addr
  always_ff @(posedge clk) begin
    if (state_next == S_RST || state_next == S_IDLE) begin
      buffer_rd_addr <= '0;
    end else if (state == S_REQ && req_ready) begin
      buffer_rd_addr <= buffer_rd_addr + 1;
    end
  end

  // buffer_rd_en
  always_ff @(posedge clk) begin
    if (state_next == S_RD) begin
      buffer_rd_en <= 1'b1;
    end else begin
      buffer_rd_en <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (buffer_rd_en) begin
      buffer_rd_data <= ctrl_buffer[buffer_rd_addr];
    end
  end

  // Mask read

  always_comb begin
    symbol_mask = mask_buffer[current_subframe_slot][current_symbol];
  end

  assign {
    section_header_valid,
    section_sectionid,
    section_rb,
    section_syminc,
    section_startprbu,
    section_numprbu
  } = buffer_rd_data;

  assign req_app_frameid = current_frame;
  assign req_app_subframeid = current_subframe_slot[4:1];
  assign req_app_slotid = {5'b0, current_subframe_slot[0]};
  assign req_app_symbolid = {2'b0, current_symbol};

  assign req_section_startprbu = section_startprbu;
  assign req_section_numprbu = section_numprbu;

  assign req_valid = section_header_valid && (state == S_REQ);

endmodule

`default_nettype wire

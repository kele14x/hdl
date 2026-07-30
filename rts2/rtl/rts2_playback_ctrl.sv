`timescale 1ns / 1ps
//
`default_nettype none

module rts2_playback_ctrl #(
    parameter integer ADDR_WIDTH = 40
) (
    // DataMover I/F
    //--------------
    input  wire        ddr4_clk,
    input  wire        ddr4_rst,
    //
    output reg  [79:0] m_axis_mm2s_cmd_tdata,
    output wire        m_axis_mm2s_cmd_tvalid,
    input  wire        m_axis_mm2s_cmd_tready,
    //
    input  wire [ 7:0] s_axis_mm2s_sts_tdata,
    input  wire [ 0:0] s_axis_mm2s_sts_tkeep,
    input  wire        s_axis_mm2s_sts_tlast,
    input  wire        s_axis_mm2s_sts_tvalid,
    output wire        s_axis_mm2s_sts_tready,
    //
    input  wire        mm2s_err,
    //
    input  wire        ctrl_en,
    input  wire [31:0] ctrl_addr_offset,
    input  wire [31:0] ctrl_addr_size
);

  // Parameters

  localparam [ADDR_WIDTH-1:0] AddrBase = 40'h04_0000_0000;
  localparam [          31:0] PageSize = 32'd4096;

  localparam integer S_RST = 0;
  localparam integer S_IDLE = 1;
  localparam integer S_PRE = 2;
  localparam integer S_CMD = 3;
  localparam integer S_STS = 4;

  // Signals

  wire                  ctrl_en_s;
  wire [          31:0] ctrl_addr_offset_s;
  wire [          31:0] ctrl_addr_size_s;

  reg  [          31:0] offset_reg;
  reg  [          31:0] size_reg;
  reg  [           3:0] tag_reg;

  wire [           3:0] mm2s_rsvd;
  wire [           3:0] mm2s_tag;
  wire [ADDR_WIDTH-1:0] mm2s_saddr;
  wire                  mm2s_drr;
  wire                  mm2s_eof;
  wire [           5:0] mm2s_dsa;
  wire                  mm2s_type;
  wire [          22:0] mm2s_btt;

  integer state, state_next;

  wire unused_status_inputs = &{1'b0, s_axis_mm2s_sts_tdata, s_axis_mm2s_sts_tkeep, s_axis_mm2s_sts_tlast, mm2s_err, 1'b0};

  // CDC for control signals

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (1)
  ) u_ctrl_en_cdc (
      .src_clk (1'b1),
      .src_in  (ctrl_en),
      //
      .dest_clk(ddr4_clk),
      .dest_out(ctrl_en_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (32)
  ) u_ctrl_addr_offset_cdc (
      .src_clk (1'b1),
      .src_in  (ctrl_addr_offset),
      //
      .dest_clk(ddr4_clk),
      .dest_out(ctrl_addr_offset_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (32)
  ) u_ctrl_addr_size_cdc (
      .src_clk (1'b1),
      .src_in  (ctrl_addr_size),
      //
      .dest_clk(ddr4_clk),
      .dest_out(ctrl_addr_size_s)
  );

  // Main

  assign s_axis_mm2s_sts_tready = 1'b1;

  // FSM

  always @(posedge ddr4_clk) begin
    if (ddr4_rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always @(*) begin
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_IDLE;
      end

      S_IDLE: begin
        if (ctrl_en_s && (ctrl_addr_size_s != 0)) begin
          state_next = S_PRE;
        end
      end

      S_PRE: begin
        // We check the remaining size of bytes here
        if (size_reg != 0) begin
          state_next = S_CMD;
        end else begin
          state_next = S_IDLE;
        end
      end

      S_CMD: begin
        if (m_axis_mm2s_cmd_tready) begin
          state_next = S_STS;
        end
      end

      S_STS: begin
        if (s_axis_mm2s_sts_tvalid) begin
          state_next = S_PRE;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  // Offset & Size register

  always @(posedge ddr4_clk) begin
    if (ddr4_rst) begin
      offset_reg <= 'b0;
      size_reg   <= 'b0;
    end else if ((state == S_IDLE) && ctrl_en_s && (ctrl_addr_size_s != 0)) begin
      // Load offset & size from CSR at this condition
      offset_reg <= ctrl_addr_offset_s;
      size_reg   <= ctrl_addr_size_s;
    end else if (state == S_PRE) begin
      // Fetch one `PageSize` at a time
      if (size_reg > PageSize) begin
        offset_reg <= offset_reg + PageSize;
        size_reg   <= size_reg - PageSize;
      end else begin
        offset_reg <= offset_reg + PageSize;
        size_reg   <= 'b0;
      end
    end
  end

  always @(posedge ddr4_clk) begin
    if (ddr4_rst) begin
      tag_reg <= 'b0;
    end else if (state == S_PRE && size_reg > PageSize) begin
      tag_reg <= tag_reg + 1'b1;
    end
  end

  // MM2S Command

  assign m_axis_mm2s_cmd_tvalid = (state == S_CMD);

  always @(posedge ddr4_clk) begin
    if ((state == S_PRE) && (size_reg != 0)) begin
      m_axis_mm2s_cmd_tdata <= {
        mm2s_rsvd, mm2s_tag, mm2s_saddr, mm2s_drr, mm2s_eof, mm2s_dsa, mm2s_type, mm2s_btt
      };
    end
  end

  assign mm2s_rsvd  = 4'h0;
  assign mm2s_tag   = tag_reg;
  assign mm2s_saddr = AddrBase + {{(ADDR_WIDTH-32){1'b0}}, offset_reg};
  assign mm2s_drr   = 1'b0;
  assign mm2s_eof   = size_reg > PageSize ? 1'b0 : 1'b1;
  assign mm2s_dsa   = 6'h0;
  assign mm2s_type  = 1'b1;
  assign mm2s_btt   = size_reg > PageSize ? PageSize[22:0] : size_reg[22:0];

endmodule

`default_nettype wire

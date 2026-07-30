`timescale 1 ns / 1 ps
//
`default_nettype none

module rts_cap_ram (
    input  wire        clk,
    input  wire        clk_l,
    input  wire        rst,
    //
    input  wire        sync,
    //
    input  wire [31:0] s_axis_tdata,
    input  wire [ 7:0] s_axis_tuser,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tvalid,
    //
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    input  wire        ctrl_cap_trigger,
    input  wire        ctrl_cap_force,
    input  wire [ 1:0] ctrl_cap_mode,
    input  wire [18:0] ctrl_cap_offset,
    input  wire [ 4:0] ctrl_cap_len,
    //
    output reg         stat_cap_status,
    //
    input  wire [ 3:0] ctrl_ram_addr_msb,
    //
    input  wire [12:0] ctrl_ram_addr,
    input  wire        ctrl_ram_en,
    input  wire        ctrl_ram_we,
    input  wire [31:0] ctrl_ram_din,
    output wire [31:0] ctrl_ram_dout,
    output reg         ctrl_ram_valid
);

  // Parameters

  localparam integer AddrWidth = 17;
  localparam integer DataWidth = 32;

  localparam integer S_RST = 0;
  localparam integer S_IDLE = 1;
  localparam integer S_WAIT = 2;
  localparam integer S_CAPTURE = 3;

  // Signals

  integer state, state_next;

  wire                 ctrl_cap_trigger_s;
  wire                 ctrl_cap_force_s;
  wire [          1:0] ctrl_cap_mode_s;
  wire [         18:0] ctrl_cap_offset_s;
  wire [          4:0] ctrl_cap_len_s;

  reg                  state_is_idle;
  wire                 state_is_idle_s;

  reg                  sync_d;
  wire                 sync_posedge;
  reg                  sync_req;

  reg  [          3:0] seq_counter;
  reg  [          3:0] seq_counter_d;
  reg  [         18:0] offset_counter;
  reg  [         18:0] offset_counter_next;
  reg                  offset_start;

  reg  [         31:0] s_axis_tdata_d;

  reg                  ram_wea;
  reg  [AddrWidth-1:0] ram_addra;
  reg  [DataWidth-1:0] ram_dina;

  reg                  ram_addr_done;

  reg                  ctrl_ram_en_d;

  wire                 unused_s_axis_meta = |{s_axis_tuser[7:1], s_axis_tlast};
  wire                 unused_ctrl_ram_write = |{ctrl_ram_we, ctrl_ram_din};

  // Control signals CDC

  cdc_pulse #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .REG_OUTPUT  (0),
      .RST_USED    (1)
  ) i_cdc_ctrl_cap_trigger (
      .src_clk   (ctrl_clk),
      .src_rst   (ctrl_rst),
      .src_pulse (ctrl_cap_trigger),
      //
      .dest_clk  (clk),
      .dest_rst  (rst),
      .dest_pulse(ctrl_cap_trigger_s)
  );

  cdc_pulse #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .REG_OUTPUT  (0),
      .RST_USED    (1)
  ) i_cdc_ctrl_cap_force (
      .src_clk   (ctrl_clk),
      .src_rst   (ctrl_rst),
      .src_pulse (ctrl_cap_force),
      //
      .dest_clk  (clk),
      .dest_rst  (rst),
      .dest_pulse(ctrl_cap_force_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (19)
  ) i_cdc_ctrl_cap_offset (
      .src_clk (1'b1),
      .src_in  (ctrl_cap_offset),
      .dest_clk(clk),
      .dest_out(ctrl_cap_offset_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (2)
  ) i_cdc_ctrl_cap_mode (
      .src_clk (1'b1),
      .src_in  (ctrl_cap_mode),
      .dest_clk(clk),
      .dest_out(ctrl_cap_mode_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (5)
  ) i_cdc_ctrl_cap_len (
      .src_clk (1'b1),
      .src_in  (ctrl_cap_len),
      .dest_clk(clk),
      .dest_out(ctrl_cap_len_s)
  );

  // Status signal CDC

  always @(posedge clk) begin
    state_is_idle <= (state == S_IDLE);
  end

  cdc_pulse #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .REG_OUTPUT  (0),
      .RST_USED    (1)
  ) i_cdc_state_is_idle (
      .src_clk   (clk),
      .src_rst   (rst),
      .src_pulse (state_is_idle),
      //
      .dest_clk  (ctrl_clk),
      .dest_rst  (ctrl_rst),
      .dest_pulse(state_is_idle_s)
  );

  initial begin
    stat_cap_status = 1'b0;
  end

  always @(posedge ctrl_clk) begin
    if (ctrl_cap_trigger || ctrl_cap_force) begin
      stat_cap_status <= 1'b1;
    end else if (state_is_idle_s) begin
      stat_cap_status <= 1'b0;
    end
  end

  // Main

  always @(posedge clk) begin
    sync_d <= sync;
  end

  assign sync_posedge = sync && !sync_d;

  // s_axis_tuser[0] marks the next tick is the start of a new sequence,
  // `seq_counter` counter from 0 to 15 and loops
  always @(posedge clk) begin
    if (rst) begin
      seq_counter <= 'd0;
    end else if (s_axis_tuser[0]) begin
      seq_counter <= 'd0;
    end else begin
      seq_counter <= seq_counter + 1'd1;
    end
  end

  // Sync with the posedge of the `sync` signal
  always @(posedge clk) begin
    if (rst) begin
      sync_req <= 1'b0;
    end else if (sync_posedge && &seq_counter) begin
      sync_req <= 1'b0;
    end else if (sync_posedge) begin
      sync_req <= 1'b1;
    end else if (&seq_counter) begin
      sync_req <= 1'b0;
    end
  end

  // `offset_counter` is the MSB of the counter
  always @(posedge clk) begin
    if (rst) begin
      offset_counter <= 'd0;
    end else begin
      offset_counter <= offset_counter_next;
    end
  end

  always @(*) begin
    offset_counter_next = offset_counter;
    if ((sync_posedge || sync_req) && &seq_counter) begin
      offset_counter_next = 'd0;
    end else if (&seq_counter) begin
      offset_counter_next = offset_counter + 1'd1;
    end
  end

  always @(posedge clk) begin
    offset_start <= offset_counter_next == ctrl_cap_offset_s;
  end

  // Capture FSM

  always @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always @(*) begin
    // Default state
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_IDLE;
      end

      S_IDLE: begin
        if (ctrl_cap_force_s) begin
          state_next = S_CAPTURE;
        end else if (ctrl_cap_trigger_s) begin
          state_next = S_WAIT;
        end
      end

      S_WAIT: begin
        if (offset_start) begin
          state_next = S_CAPTURE;
        end
      end

      S_CAPTURE: begin
        if (ram_addr_done && ram_wea) begin
          state_next = S_IDLE;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  // Port A

  // s_axis_tdata   => s_axis_tdata_d => ram_dina
  // s_axis_tuser   => state          => ram_wea
  // seq_count
  // offset_counter
  // offset_start

  always @(posedge clk) begin
    s_axis_tdata_d <= s_axis_tdata;
  end

  always @(posedge clk) begin
    ram_dina <= s_axis_tdata_d;
  end

  always @(posedge clk) begin
    seq_counter_d <= seq_counter;
  end

  always @(posedge clk) begin
    case (ctrl_cap_mode_s)
      2'b00: begin
        // 30.72 Msps, 1/16 tick
        ram_wea <= (state == S_CAPTURE) && s_axis_tvalid && seq_counter_d == 4'd0;
      end
      2'b01: begin
        // 61.44 Msps, 1/8 tick
        ram_wea <= (state == S_CAPTURE) && s_axis_tvalid && seq_counter_d[2:0] == 3'd0;
      end
      2'b10: begin
        // 122.88 Msps, 1/4 tick
        ram_wea <= (state == S_CAPTURE) && s_axis_tvalid && seq_counter_d[1:0] == 2'd0;
      end
      default: begin
        ram_wea <= 1'b0;
      end
    endcase
  end

  always @(posedge clk) begin
    if (((state == S_WAIT) && offset_start) || ((state == S_IDLE) && ctrl_cap_force_s)) begin
      ram_addra <= 'd0;
    end else if (ram_wea) begin
      ram_addra <= ram_addra + 1'd1;
    end
  end

  always @(*) begin
    case (ctrl_cap_len_s)
      5'd0:    ram_addr_done = (ram_addra == 'h00000);
      5'd1:    ram_addr_done = (ram_addra == 'h00001);
      5'd2:    ram_addr_done = (ram_addra == 'h00003);
      5'd3:    ram_addr_done = (ram_addra == 'h00007);
      5'd4:    ram_addr_done = (ram_addra == 'h0000F);
      5'd5:    ram_addr_done = (ram_addra == 'h0001F);
      5'd6:    ram_addr_done = (ram_addra == 'h0003F);
      5'd7:    ram_addr_done = (ram_addra == 'h0007F);
      5'd8:    ram_addr_done = (ram_addra == 'h000FF);
      5'd9:    ram_addr_done = (ram_addra == 'h001FF);
      5'd10:   ram_addr_done = (ram_addra == 'h003FF);
      5'd11:   ram_addr_done = (ram_addra == 'h007FF);
      5'd12:   ram_addr_done = (ram_addra == 'h00FFF);
      5'd13:   ram_addr_done = (ram_addra == 'h01FFF);
      5'd14:   ram_addr_done = (ram_addra == 'h03FFF);
      5'd15:   ram_addr_done = (ram_addra == 'h07FFF);
      5'd16:   ram_addr_done = (ram_addra == 'h0FFFF);
      default: ram_addr_done = (ram_addra == 'h1FFFF);
    endcase
  end

  // The RAM

  rts_cap_buffer #(
      .ADDR_WIDTH(AddrWidth),
      .DATA_WIDTH(DataWidth)
  ) i_cap_buffer (
      // Port A
      .clka  (clk),
      .clka_l(clk_l),
      .rsta  (rst),
      .wea   (ram_wea),
      .addra (ram_addra),
      .dina  (ram_dina),
      // Port B
      .clkb  (ctrl_clk),
      .rstb  (ctrl_rst),
      .enb   (ctrl_ram_en),
      .addrb ({ctrl_ram_addr_msb, ctrl_ram_addr}),
      .doutb (ctrl_ram_dout)
  );

  // Port B

  always @(posedge ctrl_clk) begin
    ctrl_ram_en_d  <= ctrl_ram_en;
    ctrl_ram_valid <= ctrl_ram_en_d;
  end

endmodule

`default_nettype wire

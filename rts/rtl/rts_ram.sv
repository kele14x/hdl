`timescale 1 ns / 1 ps
//
`default_nettype none

module rts_ram (
    input  wire        clk,
    input  wire        clk_l,
    input  wire        rst,
    //
    input  wire        sync,
    //
    output logic  [31:0] dout0,
    output logic  [31:0] dout1,
    output logic  [31:0] dout2,
    //
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    input  wire [ 2:0] ctrl_ram_mode,
    //
    input  wire [19:0] ctrl_ram0_offset,
    input  wire [19:0] ctrl_ram1_offset,
    input  wire [19:0] ctrl_ram2_offset,
    //
    input  wire [ 6:0] ctrl_ram_addr_msb,
    //
    input  wire [12:0] ctrl_ram_addr,
    input  wire        ctrl_ram_en,
    input  wire        ctrl_ram_we,
    input  wire [31:0] ctrl_ram_din,
    output wire [31:0] ctrl_ram_dout,
    output wire        ctrl_ram_valid
);

  // Parameters

  localparam integer AddrWdith = 20;
  localparam integer DataWidth = 32;

  localparam integer NumChannel = 3;

  // Signals

  wire [         19:0] ctrl_ram_offset_s   [0:NumChannel-1];
  wire                 unused_ctrl_ram_mode = |ctrl_ram_mode;
  wire                 unused_ctrl2ram_full;
  wire                 unused_ram2ctrl_full;

  wire [          6:0] ctrl_ram_addr_msb_s;
  wire [         12:0] ctrl_ram_addr_s;
  wire                 ctrl_ram_en_s;
  wire                 ctrl_ram_en_s_n;
  wire                 ctrl_ram_en_d;
  wire                 ctrl_ram_we_s;
  wire [         31:0] ctrl_ram_din_s;

  wire                 ctrl_ram_valid_n;

  logic                  init_n;
  wire                 init_n_d;
  logic                  sync_d;
  logic                  sync_posedge;

  logic  [          2:0] count;
  wire [          2:0] count_d;
  logic  [         19:0] count_ch            [0:NumChannel-1];

  logic  [         31:0] dout_reg            [0:NumChannel-1];

  wire [AddrWdith-1:0] addra;
  wire                 ena;
  wire                 wea;
  wire [DataWidth-1:0] dina;
  wire [DataWidth-1:0] douta;

  logic  [AddrWdith-1:0] addrb;
  logic                  enb;
  wire                 web;
  wire [DataWidth-1:0] dinb;
  wire [DataWidth-1:0] doutb;

  logic                  sync_f;
  logic  [          3:0] seq;

  // Main

  // Control CDC

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (20)
  ) i_cdc_ram0_offset (
      .src_clk (ctrl_clk),
      .src_in  (ctrl_ram0_offset),
      //
      .dest_clk(clk_l),
      .dest_out(ctrl_ram_offset_s[0])
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (20)
  ) i_cdc_ram1_offset (
      .src_clk (ctrl_clk),
      .src_in  (ctrl_ram1_offset),
      //
      .dest_clk(clk_l),
      .dest_out(ctrl_ram_offset_s[1])
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (20)
  ) i_cdc_ram2_offset (
      .src_clk (ctrl_clk),
      .src_in  (ctrl_ram2_offset),
      //
      .dest_clk(clk_l),
      .dest_out(ctrl_ram_offset_s[2])
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (7)
  ) i_cdc_ram_addr_msb (
      .src_clk (ctrl_clk),
      .src_in  (ctrl_ram_addr_msb),
      //
      .dest_clk(clk_l),
      .dest_out(ctrl_ram_addr_msb_s)
  );

  // Port A CDC

  fifo_async #(
      .FIFO_DEPTH  (256),
      .FIFO_LATENCY(2),
      .DATA_WIDTH  (46)
  ) i_ctrl2ram_cdc (
      .rst     (ctrl_rst),
      //
      .wr_clk  (ctrl_clk),
      .wr_en   (ctrl_ram_en),
      .wr_din  ({ctrl_ram_din, ctrl_ram_we, ctrl_ram_addr}),
      .wr_full (unused_ctrl2ram_full),
      //
      .rd_clk  (clk_l),
      .rd_dout ({ctrl_ram_din_s, ctrl_ram_we_s, ctrl_ram_addr_s}),
      .rd_en   (1'b1),
      .rd_empty(ctrl_ram_en_s_n)
  );

  assign ctrl_ram_en_s = ~ctrl_ram_en_s_n;

  assign addra = {ctrl_ram_addr_msb_s, ctrl_ram_addr_s};
  assign ena = ctrl_ram_en_s;
  assign wea = ctrl_ram_we_s;
  assign dina = ctrl_ram_din_s;

  delay #(
      .WIDTH(1),
      .DEPTH(5),
      .INIT (1)
  ) i_delay_ram_en (
      .clk (clk_l),
      .rst (rst),
      .cen (1'b1),
      .din (ctrl_ram_en_s),
      .dout(ctrl_ram_en_d)
  );

  fifo_async #(
      .FIFO_DEPTH  (256),
      .FIFO_LATENCY(2),
      .DATA_WIDTH  (32)
  ) i_ram2ctrl_cdc (
      .rst     (ctrl_rst),
      //
      .wr_clk  (clk_l),
      .wr_din  (douta),
      .wr_en   (ctrl_ram_en_d),
      .wr_full (unused_ram2ctrl_full),
      //
      .rd_clk  (ctrl_clk),
      .rd_dout (ctrl_ram_dout),
      .rd_en   (1'b1),
      .rd_empty(ctrl_ram_valid_n)
  );

  assign ctrl_ram_valid = ~ctrl_ram_valid_n;

  // Sample counter

  always_ff @(posedge clk_l) begin
    sync_d <= sync;
  end

  always_ff @(posedge clk_l) begin
    sync_posedge <= sync && ~sync_d;
  end

  // keep at reset (init_n == 0) state until reset is released
  always_ff @(posedge clk_l) begin
    if (rst) begin
      init_n <= 1'b0;
    end else begin
      init_n <= 1'b1;
    end
  end

  // `counter` is 10 ms counter, assume the clock is 245.76 MHz
  // Read one data every 8 clock cycles

  // 8:1 clock cycle counter
  always_ff @(posedge clk_l) begin
    if (rst) begin
      count <= 'd0;
    end else if (sync_posedge || ~init_n) begin
      count <= 'd0;
    end else begin
      count <= count + 1'b1;
    end
  end

  generate
    genvar i;

    for (i = 0; i < NumChannel; i = i + 1) begin : g_ch

      always_ff @(posedge clk_l) begin
        if (rst) begin
          count_ch[i] <= 'd0;
        end else if (sync_posedge || ~init_n) begin
          count_ch[i] <= ctrl_ram_offset_s[i];
        end else if (&count) begin
          count_ch[i] <= count_ch[i] + 1'b1;
        end
      end

      always_ff @(posedge clk_l) begin
        if (init_n_d && (count_d == i)) begin
          dout_reg[i] <= doutb;
        end
      end

    end
  endgenerate

  // Port B

  always_ff @(posedge clk_l) begin
    if (count == 0) begin
      addrb <= count_ch[0];
    end else if (count == 1) begin
      addrb <= count_ch[1];
    end else if (count == 2) begin
      addrb <= count_ch[2];
    end
  end

  always_ff @(posedge clk_l) begin
    enb <= (count == 0 || count == 1 || count == 2) && init_n;
  end

  assign web  = 1'b0;
  assign dinb = 32'd0;

  rts_ram_buffer i_buffer (
      .clk  (clk_l),
      // Port A
      .addra(addra),
      .ena  (ena),
      .wea  (wea),
      .dina (dina),
      .douta(douta),
      // Port B
      .addrb(addrb),
      .enb  (enb),
      .web  (web),
      .dinb (dinb),
      .doutb(doutb)
  );

  delay #(
      .WIDTH(1),
      .DEPTH(6),
      .INIT (0)
  ) i_delay_init_n (
      .clk (clk_l),
      .rst (rst),
      .cen (1'b1),
      .din (init_n),
      .dout(init_n_d)
  );

  delay #(
      .WIDTH(3),
      .DEPTH(6),
      .INIT (0)
  ) i_delay_count (
      .clk (clk_l),
      .rst (rst),
      .cen (1'b1),
      .din (count),
      .dout(count_d)
  );

  // Output

  always_ff @(posedge clk) begin
    sync_f <= sync;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      seq <= 'd0;
    end else if (sync && ~sync_f) begin
      seq <= 'd0;
    end else begin
      seq <= seq + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (seq == 4'd7) begin
      dout0 <= dout_reg[0];
      dout1 <= dout_reg[1];
      dout2 <= dout_reg[2];
    end
  end

endmodule

`default_nettype wire

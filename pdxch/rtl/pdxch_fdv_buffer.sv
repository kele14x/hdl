`timescale 1 ns / 1 ps
//
`default_nettype none

module pdxch_fdv_buffer #(
    parameter int CC_ID      = 0,
    parameter int NUM_ANT    = 4,
    parameter bit HALF_BLOCK = 1'b0
) (
    input  wire         clk_eth_xran,
    input  wire         rst_eth_xran,
    //
    input  wire         sync_in,
    //
    output wire         defm_radio_start_10ms,
    input  wire [ 11:0] s_dl_sym_num,
    // U-Plane
    input  wire [127:0] s_axis_tdata         [NUM_ANT],
    input  wire [ 15:0] s_axis_tkeep         [NUM_ANT],
    input  wire         s_axis_tvalid        [NUM_ANT],
    input  wire         s_axis_tlast         [NUM_ANT],
    input  wire [ 90:0] s_axis_tuser         [NUM_ANT],
    //
    input  wire         clk,
    input  wire         rst,
    //
    output wire [ 15:0] dout_dr,
    output wire [ 15:0] dout_di,
    output wire         dout_sf,
    output wire         dout_sl,
    output wire         dout_sy,
    output wire [  3:0] dout_chn,
    output wire         dout_dv,
    output wire         dout_last,
    // CSR
    //----
    input  wire [  3:0] ctrl_en,
    input  wire [  1:0] ctrl_rat,
    input  wire [  3:0] ctrl_bist,
    input  wire [  3:0] ctrl_bw,
    input  wire [  8:0] ctrl_nprb,
    input  wire [ 22:0] ctrl_rfs_offset
);

  // Signals

  logic [ 22:0] ctrl_rfs_offset_s;

  logic         defm_radio_start_10ms_s;
  logic         defm_radio_start_10ms_cdc;

  logic         start_of_frame;
  logic         start_of_slot;
  logic [  1:0] start_of_symbol;

  logic [ 10:0] wr_addr                   [NUM_ANT];
  logic         wr_en                     [NUM_ANT];
  logic [127:0] wr_data                   [NUM_ANT];

  logic [ 12:0] rd_addr                   [NUM_ANT];
  logic         rd_en                     [NUM_ANT];
  logic [ 31:0] rd_data                   [NUM_ANT];
  logic         unused_stat_resync;

  // Main

  // sync_in -> | rfs_offset | -> defm_radio_start_10ms -> | 4096 | -> defm_radio_start_10ms_s
  //   -> | CDC | -> defm_radio_start_10ms_cdc -> start_of_frame

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (23)
  ) u_cdc_ctrl_rfs_offset (
      .src_clk (1'b1),
      .src_in  (ctrl_rfs_offset),
      //
      .dest_clk(clk_eth_xran),
      .dest_out(ctrl_rfs_offset_s)
  );

  pulse_delay #(
      .WIDTH(23)
  ) u_pulse_delay_0 (
      .clk      (clk_eth_xran),
      .rst      (rst_eth_xran),
      //
      .pulse_in (sync_in),
      .pulse_out(defm_radio_start_10ms),
      //
      .delay    (ctrl_rfs_offset_s)
  );

  // Delay the defm_radio_start_10ms for 10us, this time is for ORAN-IP read out
  // the symbol data from it's buffer and write to fdv_buffer
  pulse_delay #(
      .WIDTH(23)
  ) u_pulse_delay_1 (
      .clk      (clk_eth_xran),
      .rst      (rst_eth_xran),
      //
      .pulse_in (defm_radio_start_10ms),
      .pulse_out(defm_radio_start_10ms_s),
      //
      .delay    (4000)
  );

  // Trigger the symbol timer
  cdc_pulse #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1'b1),
      .REG_OUTPUT  (1'b1),
      .RST_USED    (1'b1)
  ) u_cdc_defm_radio_start_10ms (
      .src_clk   (clk_eth_xran),
      .src_rst   (rst_eth_xran),
      .src_pulse (defm_radio_start_10ms_s),
      //
      .dest_clk  (clk),
      .dest_rst  (rst),
      .dest_pulse(defm_radio_start_10ms_cdc)
  );

  symbol_timer #(
      .ASYNC(1'b0),
      .MODE (1'b1),
      .FREQ (128),
      .AUTO (1'b0)
  ) u_symbol_timer (
      .clk            (clk),
      .rst            (rst),
      //
      .sync           (defm_radio_start_10ms_cdc),
      //
      .start_of_frame (start_of_frame),
      .start_of_slot  (start_of_slot),
      .start_of_symbol(start_of_symbol),
      //
      .ctrl_delay     ('0),
      .stat_resync    (unused_stat_resync)
  );

  generate
    for (genvar ant = 0; ant < NUM_ANT; ant++) begin : g_ant

      pdxch_fdv_buffer_write #(
          .CC_ID(CC_ID)
      ) u_write (
          .clk          (clk_eth_xran),
          .rst          (rst_eth_xran),
          //
          .s_dl_sym_num (s_dl_sym_num),
          //
          .s_axis_tdata (s_axis_tdata[ant]),
          .s_axis_tkeep (s_axis_tkeep[ant]),
          .s_axis_tvalid(s_axis_tvalid[ant]),
          .s_axis_tlast (s_axis_tlast[ant]),
          .s_axis_tuser (s_axis_tuser[ant]),
          //
          .wr_addr      (wr_addr[ant]),
          .wr_en        (wr_en[ant]),
          .wr_data      (wr_data[ant])
      );

      if (HALF_BLOCK) begin : g_half

        logic [ 9:0] wr_addr_s;
        logic        wr_en_s;

        logic [11:0] rd_addr_s;
        logic        rd_en_s;
        logic [127:0] unused_ram_douta;

        assign wr_addr_s = {wr_addr[ant][10], wr_addr[ant][8:0]};
        assign wr_en_s   = wr_en[ant] && ~wr_addr[ant][9];

        assign rd_addr_s = {rd_addr[ant][12], rd_addr[ant][10:0]};
        assign rd_en_s   = rd_en[ant] && ~rd_addr[ant][11];

        // wr_addr: [10]: bank, [9]: null, [8:0]: address
        // rd_addr: [12]: bank, [11]: null, [10:0]: address

        ram_tdp_asym #(
            .ADDR_WIDTH_A(10),
            .DATA_WIDTH_A(128),
            .OUTPUT_REG_A(1'b1),
            .WRITE_MODE_A("READ_FIRST"),
            //
            .ADDR_WIDTH_B(12),
            .DATA_WIDTH_B(32),
            .OUTPUT_REG_B(1'b1),
            .WRITE_MODE_B("READ_FIRST"),
            //
            .INIT_FILE   (""),
            .RAM_STYLE   ("BLOCK")
        ) u_ram (
            .clka (clk_eth_xran),
            .rsta (2'b00),
            .ena  ({1'b1, wr_en_s}),
            .wea  (wr_en_s),
            .addra(wr_addr_s),
            .dina (wr_data[ant]),
            .douta(unused_ram_douta),
            //
            .clkb (clk),
            .rstb (2'b00),
            .enb  ({1'b1, rd_en_s}),
            .web  (1'b0),
            .addrb(rd_addr_s),
            .dinb ('d0),
            .doutb(rd_data[ant])
        );

      end else begin : g_full

        logic [127:0] unused_ram_douta;

        ram_tdp_asym #(
            .ADDR_WIDTH_A(11),
            .DATA_WIDTH_A(128),
            .OUTPUT_REG_A(1'b1),
            .WRITE_MODE_A("READ_FIRST"),
            //
            .ADDR_WIDTH_B(13),
            .DATA_WIDTH_B(32),
            .OUTPUT_REG_B(1'b1),
            .WRITE_MODE_B("READ_FIRST"),
            //
            .INIT_FILE   (""),
            .RAM_STYLE   ("BLOCK")
        ) u_ram (
            .clka (clk_eth_xran),
            .rsta (2'b00),
            .ena  ({1'b1, wr_en[ant]}),
            .wea  (wr_en[ant]),
            .addra(wr_addr[ant]),
            .dina (wr_data[ant]),
            .douta(unused_ram_douta),
            //
            .clkb (clk),
            .rstb (2'b00),
            .enb  ({1'b1, rd_en[ant]}),
            .web  (1'b0),
            .addrb(rd_addr[ant]),
            .dinb ('d0),
            .doutb(rd_data[ant])
        );

      end
    end
  endgenerate

  pdxch_fdv_buffer_readout #(
      .NUM_ANT(NUM_ANT)
  ) u_readout (
      .clk            (clk),
      .rst            (rst),
      //
      .start_of_frame (start_of_frame),
      .start_of_slot  (start_of_slot),
      .start_of_symbol(start_of_symbol),
      //
      .rd_addr        (rd_addr),
      .rd_en          (rd_en),
      .rd_data        (rd_data),
      //
      .dout_dr        (dout_dr),
      .dout_di        (dout_di),
      .dout_sf        (dout_sf),
      .dout_sl        (dout_sl),
      .dout_sy        (dout_sy),
      .dout_chn       (dout_chn),
      .dout_dv        (dout_dv),
      .dout_last      (dout_last),
      //
      .ctrl_en        (ctrl_en),
      .ctrl_rat       (ctrl_rat),
      .ctrl_bist      (ctrl_bist),
      .ctrl_bw        (ctrl_bw),
      .ctrl_nprb      (ctrl_nprb)
  );

endmodule

`default_nettype wire

`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_framer_buffer #(
    parameter int CC_ID   = 0,
    parameter int ANT_ID  = 0,
    parameter int NUM_ANT = 4
) (
    input var         clk,
    input var         rst,
    //
    input var  [15:0] din_dr,
    input var  [15:0] din_di,
    input var         din_sf,
    input var         din_sl,
    input var         din_sy,
    input var  [ 1:0] din_chn,
    input var         din_dv,
    input var         din_last,
    //
    input var  [11:0] rd_section_id,
    input var  [ 3:0] ctrl_fs_offset,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tlast,
    output var [31:0] m_axis_tuser,
    output var        m_axis_tvalid
);

  logic [        3:0] ctrl_fs_offset_s;

  logic [NUM_ANT-1:0] wr_we;
  logic [        8:0] wr_addr;
  logic [       35:0] wr_data;
  logic [NUM_ANT-1:0] exp_we;
  logic [        6:0] exp_addr;
  logic [        3:0] exp_wdata;
  logic [NUM_ANT-1:0] section_done;

  logic [NUM_ANT-1:0] ap_req;
  logic [NUM_ANT-1:0] ap_ack;
  logic               gearbox_start;
  logic               gearbox_busy;
  logic               gearbox_done;
  logic [        1:0] read_ant;
  logic [       31:0] gearbox_tuser;

  logic [        1:0] data_rd_en;
  logic [        8:0] data_rd_addr;
  logic [       35:0] data_rd_data     [NUM_ANT];
  logic [       35:0] data_rd_data_c;
  logic [        1:0] exp_rd_en;
  logic [        6:0] exp_rd_addr;
  logic [        3:0] exp_rd_data      [NUM_ANT];
  logic [        3:0] exp_rd_data_c;

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (4)
  ) u_cdc_fs_offset (
      .src_clk (1'b1),
      .src_in  (ctrl_fs_offset),
      .dest_clk(clk),
      .dest_out(ctrl_fs_offset_s)
  );

  prach_bfp_compress #(
      .NUM_ANT(NUM_ANT)
  ) u_compress (
      .clk           (clk),
      .rst           (rst),
      .din_dr        (din_dr),
      .din_di        (din_di),
      .din_dv        (din_dv),
      .din_sy        (din_sy),
      .din_chn       (din_chn),
      .ctrl_fs_offset(ctrl_fs_offset_s),
      .wr_we         (wr_we),
      .wr_addr       (wr_addr),
      .wr_data       (wr_data),
      .exp_we        (exp_we),
      .exp_addr      (exp_addr),
      .exp_wdata     (exp_wdata),
      .section_done  (section_done)
  );

  generate
    for (genvar ant = 0; ant < NUM_ANT; ant++) begin : g_ap
      always_ff @(posedge clk) begin
        if (rst) begin
          ap_req[ant] <= 1'b0;
        end else if (section_done[ant]) begin
          ap_req[ant] <= 1'b1;
        end else if (ap_ack[ant]) begin
          ap_req[ant] <= 1'b0;
        end
      end

      always_comb begin
        ap_ack[ant] = ap_req[ant] && !gearbox_busy;
        for (int lower_ant = 0; lower_ant < ant; lower_ant++) begin
          if (ap_req[lower_ant]) begin
            ap_ack[ant] = 1'b0;
          end
        end
      end
    end
  endgenerate

  assign gearbox_start = |ap_ack;
  assign gearbox_tuser = {8'b0, 4'(CC_ID), 8'(ANT_ID), rd_section_id};

  always_ff @(posedge clk) begin
    if (rst) begin
      read_ant <= '0;
    end else begin
      for (int ant = 0; ant < NUM_ANT; ant++) begin
        if (ap_ack[ant]) begin
          read_ant <= 2'(ant);
        end
      end
    end
  end

  generate
    for (genvar ant = 0; ant < NUM_ANT; ant++) begin : g_ram
      ram_sdp #(
          .ADDR_WIDTH  (9),
          .DATA_WIDTH  (36),
          .READ_LATENCY(2),
          .DEPTH       (512),
          .RAM_STYLE   ("BLOCK")
      ) u_data_ram (
          .clka (clk),
          .wea  (wr_we[ant]),
          .addra(wr_addr),
          .dina (wr_data),
          .clkb (clk),
          .rstb (rst),
          .enb  (data_rd_en & {2{read_ant == ant}}),
          .addrb(data_rd_addr),
          .doutb(data_rd_data[ant])
      );

      ram_sdp #(
          .ADDR_WIDTH  (7),
          .DATA_WIDTH  (4),
          .READ_LATENCY(2),
          .DEPTH       (128),
          .RAM_STYLE   ("DISTRIBUTED")
      ) u_exp_ram (
          .clka (clk),
          .wea  (exp_we[ant]),
          .addra(exp_addr),
          .dina (exp_wdata),
          .clkb (clk),
          .rstb (rst),
          .enb  (exp_rd_en & {2{read_ant == ant}}),
          .addrb(exp_rd_addr),
          .doutb(exp_rd_data[ant])
      );
    end
  endgenerate

  always_comb begin
    data_rd_data_c = '0;
    exp_rd_data_c  = '0;
    for (int ant = 0; ant < NUM_ANT; ant++) begin
      if (int'(read_ant) == ant) begin
        data_rd_data_c = data_rd_data[ant];
        exp_rd_data_c  = exp_rd_data[ant];
      end
    end
  end

  prach_bfp_gearbox #(
      .USER_WIDTH(32)
  ) u_gearbox (
      .clk          (clk),
      .rst          (rst),
      .start        (gearbox_start),
      .num_prb      (7'd72),
      .start_tuser  (gearbox_tuser),
      .busy         (gearbox_busy),
      .done         (gearbox_done),
      .data_rd_en   (data_rd_en),
      .data_rd_addr (data_rd_addr),
      .data_rd_data (data_rd_data_c),
      .exp_rd_en    (exp_rd_en),
      .exp_rd_addr  (exp_rd_addr),
      .exp_rd_data  (exp_rd_data_c),
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tkeep (m_axis_tkeep),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tuser (m_axis_tuser),
      .m_axis_tvalid(m_axis_tvalid)
  );

  wire unused_framer_buffer = &{1'b0, din_sf, din_sl, din_last, gearbox_done};

endmodule

`default_nettype wire

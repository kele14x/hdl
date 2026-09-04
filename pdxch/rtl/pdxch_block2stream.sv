`timescale 1 ns / 1 ps
//
`default_nettype none

module pdxch_block2stream #(
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
    input var  [ 3:0] din_chn,
    input var         din_dv,
    input var         din_last,
    //
    output var [31:0] m_axis_tdata [NUM_ANT],
    output var [ 7:0] m_axis_tuser [NUM_ANT],
    output var        m_axis_tlast [NUM_ANT],
    output var        m_axis_tvalid[NUM_ANT],
    input var         m_axis_tready[NUM_ANT]
);

  localparam int AddrWidth = 9;
  localparam int DataWidth = 32;
  localparam int AntAddrWidth = NUM_ANT <= 1 ? 1 : $clog2(NUM_ANT);

  initial begin : drc_check
    assert (NUM_ANT >= 1)
    else $error("[%m]: NUM_ANT (%0d) must be at least 1.", NUM_ANT);
  end

  // Signals

  // din_sl/din_last do not pace the block readout, and the antenna streams
  // are emitted free-running (m_axis_tready is ignored).
  wire unused_inputs = &{1'b0, din_sl, din_last, m_axis_tready};

  logic [         15:0] din_dr_d;
  logic [         15:0] din_di_d;
  logic [          3:0] din_chn_d;
  logic                 din_dv_d;

  logic [         11:0] wr_cnt_ch   [NUM_ANT];
  logic [         11:0] wr_cnt_next;
  logic [AddrWidth-1:0] wr_cnt_r;

  logic [AddrWidth-1:0] wr_addr;
  logic                 wr_en       [NUM_ANT];
  logic [DataWidth-1:0] wr_data;

  logic                 sync        [NUM_ANT];

  logic                 rd_run      [NUM_ANT];
  logic [AddrWidth-1:0] rd_addr     [NUM_ANT];
  logic                 rd_en       [NUM_ANT];
  logic                 rd_en_d     [NUM_ANT];
  logic                 rd_en_dd    [NUM_ANT];
  logic [DataWidth-1:0] rd_data     [NUM_ANT];

  logic [         31:0] dout        [NUM_ANT];

  // Main

  // Buffer write

  always_comb begin
    if (din_sy) begin
      wr_cnt_next = 'd0;
    end else if (din_dv && (din_chn < 4'(NUM_ANT))) begin
      wr_cnt_next = wr_cnt_ch[din_chn[AntAddrWidth-1:0]] + 12'd1;
    end else begin
      wr_cnt_next = 'd0;
    end
  end

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_wr

      always_ff @(posedge clk) begin
        if (rst) begin
          wr_cnt_ch[i] <= '0;
        end else if (din_chn == i) begin
          wr_cnt_ch[i] <= wr_cnt_next;
        end
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    wr_cnt_r <= wr_cnt_next[AddrWidth-1:0];
  end

  assign wr_addr = wr_cnt_r[AddrWidth-1:0];

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_wr_en
      always_ff @(posedge clk) begin
        wr_en[i] <= (wr_cnt_next[11:AddrWidth] == 0) && din_dv && (din_chn == i);
      end
    end
  endgenerate

  always_ff @(posedge clk) begin
    wr_data <= {din_di, din_dr};
  end

  delay #(
      .WIDTH(37),
      .DEPTH(3)
  ) u_delay_din (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({din_dv, din_chn, din_di, din_dr}),
      .dout({din_dv_d, din_chn_d, din_di_d, din_dr_d})
  );

  // Buffer read
  //------------

  // sym3 ->  rd_cnt ->  rd_addr -> 2 rd_data_c -> data_out
  //          rd_sym ->  rd_en
  //          rd_bank
  //          sync


  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_rd

      always_ff @(posedge clk) begin
        if (din_sf && din_dv && din_chn == i) begin
          sync[i] <= 1'b1;
        end else begin
          sync[i] <= 1'b0;
        end
      end

      always_ff @(posedge clk) begin
        if (din_sy && din_dv && din_chn == i) begin
          rd_run[i] <= 1'b1;
        end else if (&rd_addr[i]) begin
          rd_run[i] <= 1'b0;
        end
      end

      always_ff @(posedge clk) begin
        if (din_sy && din_dv && din_chn == i) begin
          rd_addr[i] <= 'd0;
        end else if (rd_en[i]) begin
          rd_addr[i] <= rd_addr[i] + 1'b1;
        end
      end

      always_ff @(posedge clk) begin
        if (rd_run[i] && ~din_dv && din_chn == i) begin
          rd_en[i] <= 1'b1;
        end else begin
          rd_en[i] <= 1'b0;
        end
      end

      always_ff @(posedge clk) begin
        rd_en_d[i]  <= rd_en[i];
        rd_en_dd[i] <= rd_en_d[i];
      end

      always_ff @(posedge clk) begin
        if (din_dv_d && din_chn_d == i) begin
          dout[i] <= {din_di_d, din_dr_d};
        end else if (rd_en_dd[i]) begin
          dout[i] <= rd_data[i];
        end
      end

      delay #(
          .WIDTH(32),
          .DEPTH(NUM_ANT - i - 1)
      ) u_delay_tdata (
          .clk (clk),
          .rst (1'b0),
          .cen (1'b1),
          .din (dout[i]),
          .dout(m_axis_tdata[i])
      );

      delay #(
          .WIDTH(1),
          .DEPTH(6 - i)
      ) u_delay_tuser (
          .clk (clk),
          .rst (1'b0),
          .cen (1'b1),
          .din (sync[i]),
          .dout(m_axis_tuser[i][0])
      );

      assign m_axis_tuser[i][7:1] = 'b0;

      assign m_axis_tlast[i] = 1'b0;

      assign m_axis_tvalid[i] = 1'b1;

      // ignore m_dl_axis_tready

    end
  endgenerate

  // The buffer

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_ch

      // 2 * 4k * 32, read latency = 2
      ram_sdp #(
          .ADDR_WIDTH  (AddrWidth),
          .DATA_WIDTH  (DataWidth),
          .READ_LATENCY(2),
          .INIT_FILE   ("NONE")
      ) u_ram (
          .clka (clk),
          .wea  (wr_en[i]),
          .addra(wr_addr),
          .dina (wr_data),
          //
          .clkb (clk),
          .rstb (1'b0),
          .enb  ({rd_en_d[i], rd_en[i]}),
          .addrb(rd_addr[i]),
          .doutb(rd_data[i])
      );

    end
  endgenerate

endmodule

`default_nettype wire

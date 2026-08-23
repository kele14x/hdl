`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_puxch_top;

  localparam int NUM_CC = 1;
  localparam int NUM_ANT = 4;

  logic         clk;
  logic         rst;
  logic [31:0]  s_axis_tdata  [NUM_CC][NUM_ANT];
  logic [ 7:0]  s_axis_tuser  [NUM_CC][NUM_ANT];
  logic         s_axis_tlast  [NUM_CC][NUM_ANT];
  logic         s_axis_tvalid [NUM_CC][NUM_ANT];
  logic         s_axis_tready [NUM_CC][NUM_ANT];

  logic         clk_eth_xran;
  logic         rst_eth_xran;
  logic         sync_in;
  logic         fram_radio_start_10ms[NUM_CC];
  logic [11:0]  s_ul_sym_num [NUM_CC];
  logic [63:0]  m_fram_data_tdata  [NUM_ANT];
  logic [ 7:0]  m_fram_data_tkeep  [NUM_ANT];
  logic         m_fram_data_tvalid [NUM_ANT];
  logic         m_fram_data_tlast  [NUM_ANT];
  logic         m_fram_data_tready [NUM_ANT];
  logic [32:0]  m_fram_data_req   [NUM_ANT];

  logic         ctrl_clk;
  logic         ctrl_rst;
  logic [ 3:0]  ctrl_ud_comp_meth;
  logic [ 3:0]  ctrl_ud_iq_width;
  logic [ 3:0]  ctrl_fs_offset;
  logic [ 3:0]  ctrl_en       [NUM_CC];
  logic [ 1:0]  ctrl_rat      [NUM_CC];
  logic [ 3:0]  ctrl_bist     [NUM_CC];
  logic [ 3:0]  ctrl_bw       [NUM_CC];
  logic [ 8:0]  ctrl_nprb     [NUM_CC];
  logic [22:0]  ctrl_rfs_offset[NUM_CC];
  logic [16:0]  ctrl_gain     [NUM_CC][NUM_ANT];
  logic [ 5:0]  ctrl_phase_comp_addr;
  logic         ctrl_phase_comp_en;
  logic         ctrl_phase_comp_we;
  logic [31:0]  ctrl_phase_comp_din;
  logic [31:0]  ctrl_phase_comp_dout;
  logic         ctrl_phase_comp_valid;

  integer sample_count;
  integer output_count;

  // The radio stream is kept valid continuously.  A small changing pattern
  // makes the signal path visible in a waveform and in the output log.
  always @(posedge clk) begin
    if (rst) begin
      sample_count <= 0;
      for (int cc = 0; cc < NUM_CC; cc++) begin
        for (int antenna = 0; antenna < NUM_ANT; antenna++) begin
          s_axis_tdata[cc][antenna]  <= '0;
          s_axis_tuser[cc][antenna]  <= 8'(antenna);
          s_axis_tlast[cc][antenna]  <= 1'b0;
          s_axis_tvalid[cc][antenna] <= 1'b1;
        end
      end
    end else begin
      sample_count <= sample_count + 1;
      for (int cc = 0; cc < NUM_CC; cc++) begin
        for (int antenna = 0; antenna < NUM_ANT; antenna++) begin
          s_axis_tdata[cc][antenna] <= {
            16'h1000 + sample_count[15:0] + 16'(antenna),
            16'h2000 + sample_count[15:0] + 16'(antenna)
          };
          s_axis_tuser[cc][antenna]  <= 8'(antenna);
          s_axis_tlast[cc][antenna]  <= 1'b0;
          s_axis_tvalid[cc][antenna] <= 1'b1;
        end
      end
    end
  end

  // Passive output logger.  This deliberately does not compare against a
  // reference; the cocotb test is the checking test for the same pipeline.
  always @(posedge clk_eth_xran) begin
    if (!rst_eth_xran) begin
      if (fram_radio_start_10ms[0]) begin
        $display("[%0t] radio frame marker", $time);
      end
      if (ctrl_phase_comp_valid) begin
        $display("[%0t] phase table readback data=%08h", $time, ctrl_phase_comp_dout);
      end
      for (int antenna = 0; antenna < NUM_ANT; antenna++) begin
        if (m_fram_data_tvalid[antenna] && m_fram_data_tready[antenna]) begin
          $display(
            "[%0t] antenna %0d output[%0d] data=%016h keep=%02h last=%0d",
            $time,
            antenna,
            output_count,
            m_fram_data_tdata[antenna],
            m_fram_data_tkeep[antenna],
            m_fram_data_tlast[antenna]
          );
          output_count <= output_count + 1;
        end
      end
    end
  end

  initial begin
    clk = 1'b0;
    forever #1 clk = ~clk;
  end

  initial begin
    clk_eth_xran = 1'b0;
    forever #1 clk_eth_xran = ~clk_eth_xran;
  end

  initial begin
    ctrl_clk = 1'b0;
    forever #5 ctrl_clk = ~ctrl_clk;
  end

  initial begin
    rst = 1'b1;
    rst_eth_xran = 1'b1;
    ctrl_rst = 1'b1;
    sync_in = 1'b0;
    output_count = 0;

    ctrl_ud_comp_meth = 4'd0;
    ctrl_ud_iq_width = 4'd9;
    ctrl_fs_offset = 4'd0;
    ctrl_phase_comp_addr = '0;
    ctrl_phase_comp_en = 1'b0;
    ctrl_phase_comp_we = 1'b0;
    ctrl_phase_comp_din = 32'h0000_4000;

    for (int cc = 0; cc < NUM_CC; cc++) begin
      s_ul_sym_num[cc] = '0;
      ctrl_en[cc] = 4'hf;
      ctrl_rat[cc] = 2'd2;
      ctrl_bist[cc] = '0;
      ctrl_bw[cc] = 4'd4;
      ctrl_nprb[cc] = 9'd273;
      ctrl_rfs_offset[cc] = '0;
      for (int antenna = 0; antenna < NUM_ANT; antenna++) begin
        ctrl_gain[cc][antenna] = 17'h04000;
      end
    end

    for (int antenna = 0; antenna < NUM_ANT; antenna++) begin
      m_fram_data_tready[antenna] = 1'b1;
      m_fram_data_req[antenna] = '0;
    end

    repeat (10) @(posedge clk);
    rst = 1'b0;
    repeat (10) @(posedge clk_eth_xran);
    rst_eth_xran = 1'b0;
    repeat (10) @(posedge ctrl_clk);
    ctrl_rst = 1'b0;

    // Write unity phase compensation values for the first carrier page.
    for (int symbol = 0; symbol < 16; symbol++) begin
      @(posedge ctrl_clk);
      ctrl_phase_comp_addr <= 6'(symbol);
      ctrl_phase_comp_din <= 32'h0000_4000;
      ctrl_phase_comp_en <= 1'b1;
      ctrl_phase_comp_we <= 1'b1;
    end
    @(posedge ctrl_clk);
    ctrl_phase_comp_en <= 1'b0;
    ctrl_phase_comp_we <= 1'b0;

    // Start radio timing, allow the FFT and buffer to fill, then request one
    // PRB so a short sequence of output words is visible in the transcript.
    @(posedge clk_eth_xran);
    sync_in <= 1'b1;
    @(posedge clk_eth_xran);
    sync_in <= 1'b0;
    repeat (50000) @(posedge clk_eth_xran);
    @(posedge clk_eth_xran);
    m_fram_data_req[0] <= (33'h1 << 24) | (33'h1 << 7);
    @(posedge clk_eth_xran);
    m_fram_data_req[0] <= '0;
    repeat (128) @(posedge clk_eth_xran);
    $finish;
  end

  puxch_top #(
    .NUM_CC(NUM_CC),
    .NUM_ANT(NUM_ANT),
    .HAS_BFP(0),
    .HALF_BLOCK(0),
    .HALF_FFT(0)
  ) dut (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tuser(s_axis_tuser),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .clk_eth_xran(clk_eth_xran),
    .rst_eth_xran(rst_eth_xran),
    .sync_in(sync_in),
    .fram_radio_start_10ms(fram_radio_start_10ms),
    .s_ul_sym_num(s_ul_sym_num),
    .m_fram_data_tdata(m_fram_data_tdata),
    .m_fram_data_tkeep(m_fram_data_tkeep),
    .m_fram_data_tvalid(m_fram_data_tvalid),
    .m_fram_data_tlast(m_fram_data_tlast),
    .m_fram_data_tready(m_fram_data_tready),
    .m_fram_data_req(m_fram_data_req),
    .ctrl_clk(ctrl_clk),
    .ctrl_rst(ctrl_rst),
    .ctrl_ud_comp_meth(ctrl_ud_comp_meth),
    .ctrl_ud_iq_width(ctrl_ud_iq_width),
    .ctrl_fs_offset(ctrl_fs_offset),
    .ctrl_en(ctrl_en),
    .ctrl_rat(ctrl_rat),
    .ctrl_bist(ctrl_bist),
    .ctrl_bw(ctrl_bw),
    .ctrl_nprb(ctrl_nprb),
    .ctrl_rfs_offset(ctrl_rfs_offset),
    .ctrl_gain(ctrl_gain),
    .ctrl_phase_comp_addr(ctrl_phase_comp_addr),
    .ctrl_phase_comp_en(ctrl_phase_comp_en),
    .ctrl_phase_comp_we(ctrl_phase_comp_we),
    .ctrl_phase_comp_din(ctrl_phase_comp_din),
    .ctrl_phase_comp_dout(ctrl_phase_comp_dout),
    .ctrl_phase_comp_valid(ctrl_phase_comp_valid)
  );

endmodule

`default_nettype wire

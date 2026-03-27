`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_puxch_top;

  // Parameters

  parameter int NUM_CC = 3;
  parameter int NUM_ANT = 4;
  parameter bit HAS_BFP = 1'b0;

  parameter logic [3:0] TEST_EN[NUM_CC] = '{0: 4'h1, default: 0};
  parameter logic [1:0] TEST_RAT[NUM_CC] = '{default: 0};
  parameter logic [3:0] TEST_BIST[NUM_CC] = '{default: 0};
  parameter logic [3:0] TEST_BW[NUM_CC] = '{0: 4'd2, default: 0};
  parameter logic [8:0] TEST_NPRB[NUM_CC] = '{0: 100, default: 0};
  parameter logic [22:0] TEST_RFS_OFFSET[NUM_CC] = '{default: 0};

  parameter logic [16:0] TEST_GAIN[NUM_CC][NUM_ANT] = '{default: 'h4000};

  parameter int TEST_CC = 0;
  parameter int TEST_ANT = 0;
  parameter int TEST_LEN = 30720;

  // Signals

  logic        clk;
  logic        rst;
  //
  logic [31:0] s_axis_tdata          [  NUM_CC] [NUM_ANT];
  logic [ 7:0] s_axis_tuser          [  NUM_CC] [NUM_ANT];
  logic        s_axis_tlast          [  NUM_CC] [NUM_ANT];
  logic        s_axis_tvalid         [  NUM_CC] [NUM_ANT];
  logic        s_axis_tready         [  NUM_CC] [NUM_ANT];
  // O-RAN U-Plane
  logic        clk_eth_xran;
  logic        rst_eth_xran;
  //
  logic        sync_in;
  //
  logic        fram_radio_start_10ms [  NUM_CC];
  logic [11:0] s_ul_sym_num          [  NUM_CC];
  //
  logic [63:0] m_fram_data_tdata     [ NUM_ANT];
  logic [ 7:0] m_fram_data_tkeep     [ NUM_ANT];
  logic        m_fram_data_tvalid    [ NUM_ANT];
  logic        m_fram_data_tlast     [ NUM_ANT];
  logic        m_fram_data_tready    [ NUM_ANT];
  logic [32:0] m_fram_data_req       [ NUM_ANT];
  // CSR
  logic        ctrl_clk;
  logic        ctrl_rst;
  //
  logic [ 3:0] ctrl_ud_comp_meth;
  logic [ 3:0] ctrl_ud_iq_width;
  logic [ 3:0] ctrl_fs_offset;
  //
  logic [ 3:0] ctrl_en               [  NUM_CC];
  logic [ 1:0] ctrl_rat              [  NUM_CC];
  logic [ 3:0] ctrl_bist             [  NUM_CC];
  logic [ 3:0] ctrl_bw               [  NUM_CC];
  logic [ 8:0] ctrl_nprb             [  NUM_CC];
  logic [22:0] ctrl_rfs_offset       [  NUM_CC];
  //
  logic [16:0] ctrl_gain             [  NUM_CC] [NUM_ANT];
  //
  logic [ 5:0] ctrl_phase_comp_addr;
  logic        ctrl_phase_comp_en;
  logic        ctrl_phase_comp_we;
  logic [31:0] ctrl_phase_comp_din;
  logic [31:0] ctrl_phase_comp_dout;
  logic        ctrl_phase_comp_valid;

  logic [31:0] test_input            [TEST_LEN];

  initial begin
    $readmemh("tb_puxch_top_input.txt", test_input);
  end

  // Clock & Reset

  initial begin
    clk = 1'b0;
    forever #1 clk = ~clk;
  end

  initial begin
    rst = 1'b1;
    repeat (100) @(posedge clk);
    rst <= 1'b0;
  end

  initial begin
    clk_eth_xran = 1'b0;
    forever #(1.25) clk_eth_xran = ~clk_eth_xran;
  end

  initial begin
    rst_eth_xran = 1'b1;
    repeat (100) @(posedge clk_eth_xran);
    rst_eth_xran <= 1'b0;
  end

  initial begin
    ctrl_clk = 1'b0;
    forever #5 ctrl_clk = ~ctrl_clk;
  end

  initial begin
    ctrl_rst = 1'b1;
    repeat (100) @(posedge ctrl_clk);
    ctrl_rst <= 1'b0;
  end

  // Stimulus

  // Configuration
  initial begin
    $display("*** Simulation starts ***");

    ctrl_ud_comp_meth    = 0;
    ctrl_ud_iq_width     = 0;
    ctrl_fs_offset       = 0;

    ctrl_en              = TEST_EN;
    ctrl_rat             = TEST_RAT;
    ctrl_bist            = TEST_BIST;
    ctrl_bw              = TEST_BW;
    ctrl_nprb            = TEST_NPRB;
    ctrl_rfs_offset      = TEST_RFS_OFFSET;

    ctrl_gain            = TEST_GAIN;

    ctrl_phase_comp_addr = 0;
    ctrl_phase_comp_en   = 0;
    ctrl_phase_comp_we   = 0;
    ctrl_phase_comp_din  = 0;
  end

  final begin
    $display("*** Simulation ends ***");
  end

  // The 10ms sync signal @clk_eth_xran
  initial begin
    sync_in = 1'b0;
    wait (!rst);
    // Wait to flush the data path pipeline
    repeat (40_000) @(posedge clk_eth_xran);
    // Loop to generate 10ms sync strobe @clk_eth_xran
    forever begin
      sync_in <= 1'b1;
      @(posedge clk_eth_xran);
      sync_in <= 1'b0;
      repeat (399_999_9) @(posedge clk_eth_xran);
    end
  end

  // O-RAN U-Plane request
  initial begin
    s_ul_sym_num = '{default: 0};
    m_fram_data_req = '{default: 0};
    m_fram_data_tready = '{default: 0};

    forever begin
      // wait for sync
      forever begin
        @(posedge clk_eth_xran);
        if (fram_radio_start_10ms[TEST_CC]) break;
      end

      // Send request and assert TREADY
      for (int sym = 0; sym < 140; sym++) begin
        @(posedge clk_eth_xran);
        // {-, en, start_prb, num_prb, -, cc}
        s_ul_sym_num[TEST_CC] = sym;
        m_fram_data_req[TEST_ANT] <= {8'b0, 1'b1, 9'd0, 8'd100, 3'b0, 4'b0};

        @(posedge clk_eth_xran);
        m_fram_data_req[TEST_ANT] <= '0;
        m_fram_data_tready[TEST_ANT] <= 1'b1;
        repeat (28085) @(posedge clk_eth_xran);
      end
    end
  end

  // Data input
  initial begin
    s_axis_tdata  = '{default: 0};
    s_axis_tuser  = '{default: 0};
    s_axis_tlast  = '{default: 0};
    s_axis_tvalid = '{default: 0};

    // Wait for sync
    forever begin
      @(posedge clk_eth_xran);
      if (sync_in) break;
    end
    @(posedge clk);

    // Send data
    for (int i = 0; i < TEST_LEN; i++) begin
      s_axis_tdata[TEST_CC][TEST_ANT]  <= test_input[i];
      s_axis_tuser[TEST_CC][TEST_ANT]  <= 0;
      s_axis_tlast[TEST_CC][TEST_ANT]  <= 0;
      s_axis_tvalid[TEST_CC][TEST_ANT] <= 1'b1;
      repeat (16) @(posedge clk);
    end

    s_axis_tvalid[TEST_CC][TEST_ANT] <= 1'b0;
    #10000;
    $finish;
  end

  // Output data logger

  int fout;

  initial begin
    fout = $fopen("tb_puxch_top_output.txt");
    if (!fout) begin
      $display("Failed to open output file");
      $finish;
    end

    forever begin
      @(posedge clk_eth_xran);
      if (m_fram_data_tvalid[TEST_ANT]) begin
        $fwrite(fout, "%d, %d\n", $signed({m_fram_data_tdata[TEST_ANT][7:0],
                                           m_fram_data_tdata[TEST_ANT][15:8]}),
                $signed({m_fram_data_tdata[TEST_ANT][23:16], m_fram_data_tdata[TEST_ANT][31:24]}));
        $fwrite(fout, "%d, %d\n", $signed({m_fram_data_tdata[TEST_ANT][39:32],
                                           m_fram_data_tdata[TEST_ANT][47:40]}),
                $signed({m_fram_data_tdata[TEST_ANT][55:48], m_fram_data_tdata[TEST_ANT][63:56]}));
      end
    end

    // // Wait for sync
    // forever begin
    //   @(posedge clk);
    //   if (DUT.g_cc[TEST_CC].u_channel.fft_dout_sf) break;
    // end

    // // Log data output to file
    // forever begin
    //   if ((DUT.g_cc[TEST_CC].u_channel.fft_dout_chn == TEST_ANT) && DUT.g_cc[TEST_CC].u_channel.fft_dout_dv) begin
    //     $fwrite(fout, "%d, %d\n", $signed(DUT.g_cc[TEST_CC].u_channel.fft_dout_dr),
    //             $signed(DUT.g_cc[TEST_CC].u_channel.fft_dout_di));
    //   end
    //   @(posedge clk);
    // end
  end

  final begin
    $fclose(fout);
  end

  // DUT

  puxch_top #(
      .NUM_CC (NUM_CC),
      .NUM_ANT(NUM_ANT),
      .HAS_BFP(HAS_BFP)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire

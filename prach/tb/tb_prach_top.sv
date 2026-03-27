`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_prach_top;

  // Parameters

  parameter int NUM_CC = 1;
  parameter int NUM_ANT = 1;
  parameter int ANT_ID = 'h40;
  parameter bit HAS_BFP = 1'b0;

  parameter logic [3:0] TEST_UD_COMP_METH = 1;
  parameter logic [3:0] TEST_UD_IQ_WIDTH = 9;
  parameter logic [3:0] TEST_FS_OFFSET = 0;

  parameter logic [3:0] TEST_BIST[NUM_CC] = '{default: 0};
  parameter logic [3:0] TEST_EN[NUM_CC] = '{0: 4'hF, default: 0};
  parameter logic [1:0] TEST_RAT[NUM_CC] = '{default: 0};
  parameter logic [3:0] TEST_BW[NUM_CC] = '{0: 4'd2, default: 0};
  parameter logic [22:0] TEST_RFS_OFFSET[NUM_CC] = '{default: 0};
  parameter logic [22:0] TEST_TA3_OFFSET[NUM_CC] = '{default: 0};

  parameter logic [3:0] TEST_STATIC_C[NUM_CC] = '{default: 0};

  parameter logic [3:0] TEST_SUBFRAME_ID[NUM_CC] = '{default: 0};
  parameter logic [5:0] TEST_SLOT_ID[NUM_CC] = '{default: 0};
  parameter logic [5:0] TEST_SYMBOL_ID[NUM_CC] = '{default: 0};

  parameter logic [15:0] TEST_TIME_OFFSET[NUM_CC] = '{default: 0};
  parameter logic [15:0] TEST_CP_LENGTH[NUM_CC] = '{default: 0};

  parameter logic [3:0] TEST_NUM_SYMBOL[NUM_CC] = '{default: 0};
  parameter logic [23:0] TEST_FREQ_OFFSET[NUM_CC] = '{default: 0};

  parameter logic [15:0] TEST_SAMPLING_OFFSET[NUM_CC] = '{default: 0};

  parameter int TEST_CC = 0;
  parameter int TEST_ANT = 0;
  parameter int TEST_NUM_SAMPLE = 30720;

  // Signals

  logic        clk;
  logic        rst;

  logic        sync_in;

  // Clock & Reset
  //--------------
  logic [31:0] s_axis_tdata            [NUM_CC] [NUM_ANT];
  logic        s_axis_tlast            [NUM_CC] [NUM_ANT];
  logic [ 7:0] s_axis_tuser            [NUM_CC] [NUM_ANT];
  logic        s_axis_tvalid           [NUM_CC] [NUM_ANT];
  logic        s_axis_tready           [NUM_CC] [NUM_ANT];

  // ORAN
  //--------
  logic        clk_eth_xran;
  logic        rst_eth_xran;

  // PRACH C plane messages
  logic        s_prach_tvalid;
  logic        s_prach_tready;
  logic [15:0] s_prach_rtc_pc_id;
  logic [ 3:0] s_prach_cc;
  logic [ 7:0] s_prach_ss;
  logic [11:0] s_prach_section_id;
  logic [ 3:0] s_prach_return_port;
  logic [ 3:0] s_prach_filter_index;
  logic [ 7:0] s_prach_f;
  logic [ 3:0] s_prach_sf;
  logic [ 5:0] s_prach_sl;
  logic [ 5:0] s_prach_sy;
  logic [15:0] s_prach_time_offset;
  logic [ 7:0] s_prach_frame_structure;
  logic [15:0] s_prach_cp_length;
  logic [ 7:0] s_prach_udcomphdr;
  logic        s_prach_rb;
  logic        s_prach_syminc;
  logic [ 9:0] s_prach_start_prbc;
  logic [ 7:0] s_prach_num_prbc;
  logic [11:0] s_prach_remask;
  logic [ 3:0] s_prach_num_symbol;
  logic [14:0] s_prach_beamid;
  logic [23:0] s_prach_freqoffset;

  // PRACH U-Plane
  logic [63:0] m_fram_prach_tdata;
  logic [ 7:0] m_fram_prach_tkeep;
  logic        m_fram_prach_tlast;
  logic [31:0] m_fram_prach_tuser;
  logic        m_fram_prach_tvalid;
  logic        m_fram_prach_tready;

  // CSR
  //----
  logic        ctrl_clk;
  logic        ctrl_rst;

  logic [ 3:0] ctrl_ud_comp_meth;
  logic [ 3:0] ctrl_ud_iq_width;
  logic [ 3:0] ctrl_fs_offset;

  logic [ 3:0] ctrl_bist               [NUM_CC];
  logic [ 3:0] ctrl_en                 [NUM_CC];
  logic [ 1:0] ctrl_rat                [NUM_CC];
  logic [ 3:0] ctrl_bw                 [NUM_CC];
  logic [22:0] ctrl_rfs_offset         [NUM_CC];
  logic [22:0] ctrl_ta3_offset         [NUM_CC];

  logic [ 3:0] ctrl_static_c           [NUM_CC];

  logic [ 3:0] ctrl_subframe_inc       [NUM_CC];
  logic [ 3:0] ctrl_subframe_id        [NUM_CC];
  logic [ 5:0] ctrl_slot_id            [NUM_CC];
  logic [ 5:0] ctrl_symbol_id          [NUM_CC];

  logic [15:0] ctrl_time_offset        [NUM_CC];
  logic [15:0] ctrl_cp_length          [NUM_CC];

  logic [ 3:0] ctrl_num_symbol         [NUM_CC];
  logic [23:0] ctrl_freq_offset        [NUM_CC];

  logic [15:0] ctrl_sampling_offset    [NUM_CC];

  logic [ 3:0] stat_subframe_id        [NUM_CC];
  logic [ 5:0] stat_slot_id            [NUM_CC];
  logic [ 5:0] stat_symbol_id          [NUM_CC];

  logic [15:0] stat_time_offset        [NUM_CC];
  logic [15:0] stat_cp_length          [NUM_CC];

  logic [ 3:0] stat_num_symbol         [NUM_CC];
  logic [23:0] stat_freq_offset        [NUM_CC];

  // Clock & Reset

  // clk @ 491.52 MHz
  initial begin
    clk = 1'b0;
    forever #1 clk = ~clk;
  end

  initial begin
    rst = 1'b1;
    repeat (10) @(posedge clk);
    rst <= 1'b0;
  end

  // clk_eth_xran @ 400 MHz
  initial begin
    clk_eth_xran = 1'b0;
    forever #(1.25) clk_eth_xran = ~clk_eth_xran;
  end

  initial begin
    rst_eth_xran = 1'b1;
    repeat (10) @(posedge clk_eth_xran);
    rst_eth_xran <= 1'b0;
  end

  initial begin
    ctrl_clk = 1'b0;
    forever #5 ctrl_clk = ~ctrl_clk;
  end

  initial begin
    ctrl_rst = 1'b1;
    repeat (10) @(posedge ctrl_clk);
    ctrl_rst <= 1'b0;
  end

  // ORAN-IF

  assign m_fram_prach_tready = 1'b1;

  // Data loader

  logic [31:0] tb_prach_top_input[TEST_NUM_SAMPLE];

  initial begin
    $readmemh("tb_prach_top_input.txt", tb_prach_top_input);
    s_axis_tdata  = '{default: 0};
    s_axis_tlast  = '{default: 0};
    s_axis_tuser  = '{default: 0};
    s_axis_tvalid = '{default: 0};
    wait (rst == 1'b0);

    // wait for sync
    forever @(posedge clk_eth_xran) begin
      if (sync_in) break;
    end
    @(posedge clk);

    repeat(2) begin
        // Send data
        for (int i = 0; i < TEST_NUM_SAMPLE; i++) begin
          s_axis_tdata[TEST_CC][TEST_ANT]  <= tb_prach_top_input[i];
          // s_axis_tdata[TEST_CC][TEST_ANT][15:0] <= 5827 * $cos(2 * 3.141592653589793 * i * 270e3 / 30.72e6);
          // s_axis_tdata[TEST_CC][TEST_ANT][31:16] <= 5827 * $sin(2 * 3.141592653589793 * i * 270e3 / 30.72e6);
          s_axis_tlast[TEST_CC][TEST_ANT]  <= i == TEST_NUM_SAMPLE - 1;
          s_axis_tuser[TEST_CC][TEST_ANT]  <= i == 0 ? 8'd1 : 0;
          s_axis_tvalid[TEST_CC][TEST_ANT] <= 1'b1;
          repeat (16) @(posedge clk);
        end
    end

    // End of data
    s_axis_tvalid[0][0] <= 1'b0;

    repeat (2000) @(posedge clk);
    $finish;
  end

  // Data logger

  int fout;

  initial begin
    fout = $fopen("tb_prach_top_output.txt");
    if (!fout) begin
      $display("Failed to open tb_prach_top_output.txt");
      $finish;
    end

    // Wait for sync
    forever
    @(posedge clk) begin
      if (DUT.g_cc[TEST_CC].u_channel.stream2block_dout_sy) break;
    end

    forever
    @(posedge clk) begin
      if (DUT.g_cc[TEST_CC].u_channel.stream2block_dout_dv && (DUT.g_cc[TEST_CC].u_channel.stream2block_dout_chn == TEST_ANT)) begin
        $fwrite(fout, "%d, %d\n", $signed(DUT.g_cc[TEST_CC].u_channel.stream2block_dout_dr),
                $signed(DUT.g_cc[TEST_CC].u_channel.stream2block_dout_di));
      end
    end
  end

  // Sync in

  initial begin
    sync_in = 1'b0;
    wait (rst == 1'b0);
    repeat (3000) @(posedge clk_eth_xran);
    forever begin
      sync_in <= 1'b1;
      @(posedge clk_eth_xran);
      sync_in <= 1'b0;
      repeat (40000000) @(posedge clk_eth_xran);
    end
  end

  // Send PRACH C-Plane messages

  initial begin
    s_prach_tvalid = 0;
    s_prach_rtc_pc_id = 0;
    s_prach_cc = 0;
    s_prach_ss = 0;
    s_prach_section_id = 0;
    s_prach_return_port = 0;
    s_prach_filter_index = 0;
    s_prach_f = 0;
    s_prach_sf = 0;
    s_prach_sl = 0;
    s_prach_sy = 0;
    s_prach_time_offset = 0;
    s_prach_frame_structure = 0;
    s_prach_cp_length = 0;
    s_prach_udcomphdr = 0;
    s_prach_rb = 0;
    s_prach_syminc = 0;
    s_prach_start_prbc = 0;
    s_prach_num_prbc = 0;
    s_prach_remask = 0;
    s_prach_num_symbol = 0;
    s_prach_beamid = 0;
    s_prach_freqoffset = 0;

    wait (rst_eth_xran == 1'b0);
    @(posedge clk_eth_xran);

    for (int sf = 0; sf < 2; sf++) begin
      // Send PRACH C-Plane messages
      for (int i = 0; i < 1; i++) begin
        s_prach_tvalid <= 1;
        s_prach_rtc_pc_id <= 0;
        s_prach_cc <= 0;
        s_prach_ss <= 'h40 + i;
        s_prach_section_id <= 12'h800;
        s_prach_return_port <= 0;
        s_prach_filter_index <= 1;
        s_prach_f <= 0;
        s_prach_sf <= sf;
        s_prach_sl <= 0;
        s_prach_sy <= 1;
        s_prach_time_offset <= 'h0C60;
        s_prach_frame_structure <= 'hAC;
        s_prach_cp_length <= 0;
        s_prach_udcomphdr <= 'h91;
        s_prach_rb <= 0;
        s_prach_syminc <= 0;
        s_prach_start_prbc <= 0;
        s_prach_num_prbc <= 'h48;
        s_prach_remask <= 'hFFF;
        s_prach_num_symbol <= 1;
        s_prach_beamid <= 0;
        s_prach_freqoffset <= 'hFFCB2C;
        forever begin
          @(posedge clk_eth_xran);
          if (s_prach_tready) break;
        end
        // Add some gap between C-Message
        s_prach_tvalid <= 0;
        repeat(10) @(posedge clk_eth_xran);
      end
      // Wait about 1 ms
      repeat(400000 - 5000) @(posedge clk_eth_xran);
    end
  end

  // Configuration

  initial begin
    $display("*** Start simulation ***");
    ctrl_ud_comp_meth    = TEST_UD_COMP_METH;
    ctrl_ud_iq_width     = TEST_UD_IQ_WIDTH;
    ctrl_fs_offset       = TEST_FS_OFFSET;

    ctrl_bist            = TEST_BIST;
    ctrl_en              = TEST_EN;
    ctrl_rat             = TEST_RAT;
    ctrl_bw              = TEST_BW;
    ctrl_rfs_offset      = TEST_RFS_OFFSET;

    ctrl_static_c        = TEST_STATIC_C;

    ctrl_subframe_inc    = '{default: 'd0};
    ctrl_subframe_id     = TEST_SUBFRAME_ID;
    ctrl_slot_id         = TEST_SLOT_ID;
    ctrl_symbol_id       = TEST_SYMBOL_ID;

    ctrl_time_offset     = TEST_TIME_OFFSET;
    ctrl_cp_length       = TEST_CP_LENGTH;

    ctrl_num_symbol      = TEST_NUM_SYMBOL;
    ctrl_freq_offset     = TEST_FREQ_OFFSET;
    ctrl_ta3_offset      = TEST_TA3_OFFSET;

    ctrl_sampling_offset = TEST_SAMPLING_OFFSET;
  end

  final begin
    $display("*** End simulation ***");
  end

  // DUT

  prach_top #(
      .NUM_CC (NUM_CC),
      .NUM_ANT(NUM_ANT),
      .ANT_ID (ANT_ID),
      .HAS_BFP(HAS_BFP)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire

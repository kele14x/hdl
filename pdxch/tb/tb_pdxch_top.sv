`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_pdxch_top;

  // Parameters

  parameter int NUM_CC = 3;
  parameter int NUM_ANT = 4;
  parameter bit HAS_BFP = 1'b1;

  parameter logic [3:0] TEST_EN[NUM_CC] = '{0: 4'hF, default: 4'h0};
  parameter logic [1:0] TEST_RAT[NUM_CC] = '{0: 2'd0, default: 2'd0};
  parameter logic [3:0] TEST_BIST[NUM_CC] = '{default: 4'h0};
  parameter logic [3:0] TEST_BW[NUM_CC] = '{0: 4'd2, default: 4'd0};
  parameter logic [8:0] TEST_NPRB[NUM_CC] = '{0: 9'd100, default: 9'd0};
  parameter logic [22:0] TEST_RFS_OFFSET[NUM_CC] = '{default: 23'd0};

  parameter int TEST_CC = 0;
  parameter int TEST_ANT = 0;
  parameter int TEST_SYMBOL = 14;

  // Signals

  // iFFT
  //-----
  logic        clk;
  logic        rst;
  //
  logic        sync_in;
  //
  logic [31:0] m_axis_tdata          [ NUM_CC] [NUM_ANT];
  logic [ 7:0] m_axis_tuser          [ NUM_CC] [NUM_ANT];
  logic        m_axis_tlast          [ NUM_CC] [NUM_ANT];
  logic        m_axis_tvalid         [ NUM_CC] [NUM_ANT];
  logic        m_axis_tready         [ NUM_CC] [NUM_ANT];

  // O-RAN
  //------
  logic        clk_eth_xran;
  logic        rst_eth_xran;
  //
  logic        defm_radio_start_10ms [ NUM_CC];
  logic [11:0] s_dl_sym_num          [ NUM_CC];
  // U-Plane
  logic [63:0] s_defm_data_tdata     [NUM_ANT];
  logic [ 7:0] s_defm_data_tkeep     [NUM_ANT];
  logic        s_defm_data_tvalid    [NUM_ANT];
  logic        s_defm_data_tlast     [NUM_ANT];
  logic        s_defm_data_tready    [NUM_ANT];
  logic [90:0] s_defm_data_tuser     [NUM_ANT];
  logic [ 4:0] s_defm_data_tdest     [NUM_ANT];
  // CSR
  //----
  logic        ctrl_clk;
  logic        ctrl_rst;
  //
  logic [ 3:0] ctrl_ud_comp_meth;
  logic [ 3:0] ctrl_ud_iq_width;
  logic [ 3:0] ctrl_fs_offset;
  //
  logic [ 3:0] ctrl_en               [ NUM_CC];
  logic [ 1:0] ctrl_rat              [ NUM_CC];
  logic [ 3:0] ctrl_bist             [ NUM_CC];
  logic [ 3:0] ctrl_bw               [ NUM_CC];
  logic [ 8:0] ctrl_nprb             [ NUM_CC];
  logic [22:0] ctrl_rfs_offset       [ NUM_CC];
  //
  logic [16:0] ctrl_gain             [ NUM_CC] [NUM_ANT];
  //
  logic [ 5:0] ctrl_phase_comp_addr;
  logic        ctrl_phase_comp_en;
  logic        ctrl_phase_comp_we;
  logic [31:0] ctrl_phase_comp_din;
  logic [31:0] ctrl_phase_comp_dout;
  logic        ctrl_phase_comp_valid;

  // Test signals

  logic [31:0] test_data             [  16800];
  logic        s_dl_sym_update       [ NUM_CC];

  // Helpers

  function automatic logic [63:0] byte_reverse(input logic [63:0] data);
    for (int i = 0; i < 8; i++) begin
      byte_reverse[i*8+7-:8] = data[63-i*8-:8];
    end
  endfunction

  // Main

  initial begin
    $readmemh("tb_pdxch_top_input.txt", test_data);
  end

  // Clock & Reset Generation

  // clk_eth_xran @ 400 MHz
  initial begin
    clk_eth_xran = 0;
    forever #(1.25) clk_eth_xran = ~clk_eth_xran;
  end

  initial begin
    rst_eth_xran = 1;
    repeat (10) @(posedge clk_eth_xran);
    rst_eth_xran <= 0;
  end

  // clk @ 491.52 MHz
  initial begin
    clk = 0;
    forever #(1) clk = ~clk;
  end

  initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst <= 0;
  end

  // ctrl_clk @ 100 MHz
  initial begin
    ctrl_clk = 0;
    forever #(5) ctrl_clk = ~ctrl_clk;
  end

  initial begin
    ctrl_rst = 1;
    repeat (10) @(posedge ctrl_clk);
    ctrl_rst <= 0;
  end

  // Stimulus

  // `sync_in` pulses 1 clock cycle every 4000000 clocks (10 ms)
  initial begin
    sync_in = 0;
    wait (rst == 0);
    repeat (1000) @(posedge clk_eth_xran);
    forever begin
      sync_in <= 1;
      @(posedge clk_eth_xran);
      sync_in <= 0;
      repeat (4000000 - 1) @(posedge clk);
    end
  end

  initial begin
    // Initialize the input data
    s_dl_sym_num = '{default: 0};
    s_dl_sym_update = '{default: 0};
 
    // Wait for start of 10 ms
    forever begin
      @(posedge clk_eth_xran);
      if (defm_radio_start_10ms[0]) break;
    end

    // Generate the symbol_index
    for (int sym = 0; sym < TEST_SYMBOL; sym++) begin
      // Update symbol number
      for (int cc = 0; cc < NUM_CC; cc++) begin
        s_dl_sym_num[cc]    <= sym;
        s_dl_sym_update[cc] <= 1;
      end
      @(posedge clk_eth_xran);
      for (int cc = 0; cc < NUM_CC; cc++) begin
        s_dl_sym_update[cc] <= 0;
      end
      repeat (28570) @(posedge clk_eth_xran);
    end
  end

  initial begin
    m_axis_tready = '{default: 1};
  end

  initial begin
    automatic logic [15:0] di0;
    automatic logic [15:0] dq0;
    automatic logic [15:0] di1;
    automatic logic [15:0] dq1;

    // Initialize the input data
    s_defm_data_tdata = '{default: 64'b0};
    s_defm_data_tkeep = '{default: 8'b0};
    s_defm_data_tvalid = '{default: 1'b0};
    s_defm_data_tlast = '{default: 1'b0};
    s_defm_data_tuser = '{default: 91'b0};
    s_defm_data_tdest = '{default: 5'b0};
      
    for (int sym = 0; sym < TEST_SYMBOL; sym++) begin

      // Wait for the symbol number to be valid
      forever begin
        @(posedge clk_eth_xran);
        if (s_dl_sym_update[0]) break;
      end

      for (int cc = 0; cc < NUM_CC; cc++) begin
        // Send 1 symbol data
        for (int i = 0; i < TEST_NPRB[cc] * 6; i++) begin
          di0 = test_data[sym*TEST_NPRB[cc]*12+2*i][15:0];
          dq0 = test_data[sym*TEST_NPRB[cc]*12+2*i][31:16];
          di1 = test_data[sym*TEST_NPRB[cc]*12+2*i+1][15:0];
          dq1 = test_data[sym*TEST_NPRB[cc]*12+2*i+1][31:16];
  
          s_defm_data_tdata[TEST_ANT]  <= byte_reverse({di0, dq0, di1, dq1});
          s_defm_data_tkeep[TEST_ANT]  <= 8'hFF;
          s_defm_data_tvalid[TEST_ANT] <= 1'b1;
          s_defm_data_tlast[TEST_ANT]  <= (i == TEST_NPRB[cc] * 6 - 1) ? 1'b1 : 1'b0;
          s_defm_data_tuser[TEST_ANT]  <= 91'b0;
          if (i == 0) begin
            s_defm_data_tuser[TEST_ANT][90] <= 1'b1;
            s_defm_data_tuser[TEST_ANT][30:27] <= cc;
          end
          s_defm_data_tdest[TEST_ANT]  <= 5'b0;
  
          // Wait the data to be accepted
          forever begin
            @(posedge clk_eth_xran);
            if (s_defm_data_tready[TEST_ANT]) break;
          end
        end
        // Done for 1 symbol
        s_defm_data_tvalid[TEST_ANT] <= 1'b0;
        repeat(11) @(posedge clk_eth_xran);
      end
    end

    #(500000);
    $finish;
  end

  // Data logger

  int fout;

  initial begin
    fout = $fopen("tb_pdxch_top_output.txt");
    if (!fout) begin
      $display("Failed to open tb_pdxch_top_output.txt");
      $finish;
    end

    // Wait for sync
    forever begin
      @(posedge clk);
      if (m_axis_tuser[TEST_CC][TEST_ANT]) break;
    end

    forever begin
      $fwrite(fout, "%d, %d\n", $signed(m_axis_tdata[TEST_CC][TEST_ANT][15:0]),  //
              $signed(m_axis_tdata[TEST_CC][TEST_ANT][31:16]));
      repeat (16) @(posedge clk);
    end
  end

  final begin
    $fclose(fout);
  end

  // Main

  initial begin
    $display("*** Simulation starts ***");
    // Initialize the control signals
    ctrl_ud_comp_meth = 0;
    ctrl_ud_iq_width  = 0;
    ctrl_fs_offset    = 0;

    ctrl_en           = TEST_EN;
    ctrl_rat          = TEST_RAT;
    ctrl_bist         = TEST_BIST;
    ctrl_bw           = TEST_BW;
    ctrl_nprb         = TEST_NPRB;
    ctrl_rfs_offset   = TEST_RFS_OFFSET;

    //
    for (int cc = 0; cc < NUM_CC; cc++) begin
      for (int ant = 0; ant < NUM_ANT; ant++) begin
        ctrl_gain[cc][ant] = 17'h4000;
      end
    end

    ctrl_phase_comp_addr = 0;
    ctrl_phase_comp_en   = 0;
    ctrl_phase_comp_we   = 0;
    ctrl_phase_comp_din  = 0;

    wait (rst == 0);

  end

  final begin
    $display("*** Simulation ends ***");
  end

  // DUT

  pdxch_top #(
      .NUM_CC (NUM_CC),
      .NUM_ANT(NUM_ANT),
      .HAS_BFP(HAS_BFP)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire

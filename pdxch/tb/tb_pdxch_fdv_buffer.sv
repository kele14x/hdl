`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_pdxch_fdv_buffer;

  parameter int NUM_CC = 1;
  parameter int NUM_ANT = 1;

  parameter logic [3:0] TEST_EN[NUM_CC] = '{default: 1};
  parameter logic [1:0] TEST_RAT[NUM_CC] = '{default: 0};
  parameter logic [3:0] TEST_BIST[NUM_CC] = '{default: 0};
  parameter logic [3:0] TEST_BW[NUM_CC] = '{default: 0};
  parameter logic [7:0] TEST_NPRB[NUM_CC] = '{default: 25};
  parameter logic [22:0] TEST_RFS_OFFSET[NUM_CC] = '{default: 0};

  // O-RAN
  //------
  logic         clk_eth_xran;
  logic         rst_eth_xran;
  //
  logic         defm_radio_start_10ms[ NUM_CC];
  logic [ 11:0] s_dl_sym_num         [ NUM_CC];
  // U-Plane
  logic [127:0] s_axis_tdata         [NUM_ANT];
  logic [ 15:0] s_axis_tkeep         [NUM_ANT];
  logic         s_axis_tvalid        [NUM_ANT];
  logic         s_axis_tlast         [NUM_ANT];
  logic [ 90:0] s_axis_tuser         [NUM_ANT];

  // iFFT
  //-----
  logic         clk;
  logic         rst;
  //
  logic         sync_in;
  //
  logic [ 15:0] dout_dr              [ NUM_CC];
  logic [ 15:0] dout_di              [ NUM_CC];
  logic         dout_sf              [ NUM_CC];
  logic         dout_sl              [ NUM_CC];
  logic         dout_sy              [ NUM_CC];
  logic [  3:0] dout_chn             [ NUM_CC];
  logic         dout_dv              [ NUM_CC];
  logic         dout_last            [ NUM_CC];

  // CSR
  //----
  logic [  3:0] ctrl_en              [ NUM_CC];
  logic [  1:0] ctrl_rat             [ NUM_CC];
  logic [  3:0] ctrl_bist            [ NUM_CC];
  logic [  3:0] ctrl_bw              [ NUM_CC];
  logic [  7:0] ctrl_nprb            [ NUM_CC];
  logic [ 22:0] ctrl_rfs_offset      [ NUM_CC];

  bit           symbol_strobe        [ NUM_CC];

  // Helpers

  function automatic logic [63:0] byte_reverse64(input logic [63:0] data);
    for (int i = 0; i < 8; i++) begin
      byte_reverse64[i*8+7-:8] = data[63-i*8-:8];
    end
  endfunction

  function automatic logic [127:0] byte_reverse128(input logic [127:0] data);
    for (int i = 0; i < 16; i++) begin
      byte_reverse128[i*8+7-:8] = data[127-i*8-:8];
    end
  endfunction

  // Clock & Reset Generation

  // clk_eth_xran @ 312.5 MHz
  initial begin
    clk_eth_xran = 0;
    forever #(1.6) clk_eth_xran = ~clk_eth_xran;
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

  // Stimulus

  initial begin
    sync_in = 0;
    wait (rst == 0);
    repeat (1000) @(posedge clk);
    forever begin
      sync_in <= 1;
      @(posedge clk);
      sync_in <= 0;
      repeat (4915200 - 1) @(posedge clk);
    end
  end

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cc

      initial begin
        s_dl_sym_num[cc] = 0;

        forever begin
          wait (defm_radio_start_10ms[cc]);
          for (int i = 0; i < 140; i++) begin
            @(posedge clk_eth_xran);
            s_dl_sym_num[cc]  <= i;
            symbol_strobe[cc] <= 1;
            @(posedge clk_eth_xran);
            symbol_strobe[cc] <= 0;
            repeat (22321 - 1) @(posedge clk_eth_xran);
          end
        end
      end

    end
  endgenerate

  initial begin
    logic [127:0] tdata;

    // Initialize the input data
    for (int ant = 0; ant < NUM_ANT; ant++) begin
      s_axis_tdata[ant]  = 0;
      s_axis_tkeep[ant]  = 0;
      s_axis_tvalid[ant] = 0;
      s_axis_tlast[ant]  = 0;
      s_axis_tuser[ant]  = 0;
    end

    // Drive CC0 data
    forever begin
      forever begin
        @(posedge clk_eth_xran);
        if (symbol_strobe[0]) break;
      end

      // Send 1 symbol data
      for (int i = 0; i < 6 * TEST_NPRB[0]; i++) begin
        for (int ant = 0; ant < NUM_ANT; ant++) begin
          // IQ data
          tdata = 'b0;
          for (int k = 0; k < 4; k++) begin
            // tdata[127-16*k-:16] = $urandom_range(1) ? 16'sd5827 : -16'sd5827;
            // tdata[127-16*k-:16] = 2 * i + k / 2;
            tdata[127-16*k-:16] = $urandom_range(2 ** 16 - 1);
          end
          // AXIS
          s_axis_tdata[ant]  <= byte_reverse128(tdata);
          s_axis_tkeep[ant]  <= 16'h00FF;
          s_axis_tvalid[ant] <= 1'b1;
          s_axis_tlast[ant]  <= (i == 6 * TEST_NPRB[0] - 1) ? 1'b1 : 1'b0;
          s_axis_tuser[ant]  <= (i == 0) ? 91'h40000000000000000000000 : 91'h0;
        end
        @(posedge clk_eth_xran);
      end

      // Done for 1 symbol
      for (int ant = 0; ant < NUM_ANT; ant++) begin
        s_axis_tvalid[ant] <= 1'b0;
      end
    end
  end

  // Main

  initial begin
    $display("*** Simulation starts ***");

    ctrl_en         = TEST_EN;
    ctrl_rat        = TEST_RAT;
    ctrl_bist       = TEST_BIST;
    ctrl_bw         = TEST_BW;
    ctrl_nprb       = TEST_NPRB;
    ctrl_rfs_offset = TEST_RFS_OFFSET;
    wait (rst == 0);

    #(500000);
    $finish;
  end

  final begin
    $display("*** Simulation ends ***");
  end

  // Input logger

  int fin;

  initial begin
    fin = $fopen("tb_pdxch_fdv_buffer_input.txt");
    if (!fin) begin
      $display("Failed to open tb_pdxch_fdv_buffer_input.txt");
      $finish;
    end

    // Log data
    forever begin
      @(posedge clk_eth_xran);
      if (s_axis_tvalid[0]) begin
        // IQ0
        $fwrite(fin, "%d, %d\n", $signed({s_axis_tdata[0][ 7: 0], s_axis_tdata[0][15: 8]}), 
                                 $signed({s_axis_tdata[0][23:16], s_axis_tdata[0][31:24]}));
        // IQ1
        $fwrite(fin, "%d, %d\n", $signed({s_axis_tdata[0][39:32], s_axis_tdata[0][47:40]}), 
                                 $signed({s_axis_tdata[0][55:48], s_axis_tdata[0][63:56]}));
      end
    end
  end

  final begin
    $fclose(fin);
  end

  // Output logger

  int fout;

  initial begin
    fout = $fopen("tb_pdxch_fdv_buffer_output.txt");
    if (!fout) begin
      $display("Failed to open tb_pdxch_fdv_buffer_output.txt");
      $finish;
    end

    forever begin
      @(posedge clk);
      if (dout_dv[0]) begin
        $fwrite(fout, "%d, %d\n", $signed(dout_dr[0]), $signed(dout_di[0]));
      end
    end
  end

  final begin
    $fclose(fout);
  end

  // DUT

  pdxch_fdv_buffer #(
      .NUM_CC (NUM_CC),
      .NUM_ANT(NUM_ANT)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire

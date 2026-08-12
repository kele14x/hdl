`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_pdxch;

  localparam int NUM_CC = 3;
  localparam int NUM_ANT = 4;

  localparam int NUM_PRB = 273;
  localparam int NUM_INPUT_SYMBOLS = 2;
  localparam int BFP9_BYTES_PER_PRB = 28;
  localparam int BFP9_BYTES_PER_SYMBOL = NUM_PRB * BFP9_BYTES_PER_PRB;
  localparam int BFP9_BEATS_PER_SYMBOL = (BFP9_BYTES_PER_SYMBOL + 7) / 8;

  localparam int MONITOR_CC = 0;
  localparam int MONITOR_ANT = 0;

  localparam logic [11:0] DL_EN = 12'h010;
  localparam logic [11:0] DL_RAT = 12'h014;
  localparam logic [11:0] DL_BIST = 12'h018;
  localparam logic [11:0] DL_BW = 12'h01c;
  localparam logic [11:0] DL_NPRB_BASE = 12'h020;
  localparam logic [11:0] DL_RFS_OFFSET_BASE = 12'h030;
  localparam logic [11:0] DL_UD = 12'h058;
  localparam logic [11:0] DL_GAIN_BASE = 12'h100;
  localparam logic [11:0] DL_PHASE_COMP_BASE = 12'h800;

  localparam logic [31:0] UNITY_Q14 = 32'h0000_4000;
  localparam logic [8:0] BFP9_POSITIVE = 9'h010;
  localparam logic [8:0] BFP9_NEGATIVE = 9'h1f0;

  // AXI4-Lite control interface
  logic          s_axi_aclk;
  logic          s_axi_aresetn;
  logic   [11:0] s_axi_awaddr;
  logic   [ 2:0] s_axi_awprot;
  logic          s_axi_awvalid;
  logic          s_axi_awready;
  logic   [31:0] s_axi_wdata;
  logic   [ 3:0] s_axi_wstrb;
  logic          s_axi_wvalid;
  logic          s_axi_wready;
  logic   [ 1:0] s_axi_bresp;
  logic          s_axi_bvalid;
  logic          s_axi_bready;
  logic   [11:0] s_axi_araddr;
  logic   [ 2:0] s_axi_arprot;
  logic          s_axi_arvalid;
  logic          s_axi_arready;
  logic   [31:0] s_axi_rdata;
  logic   [ 1:0] s_axi_rresp;
  logic          s_axi_rvalid;
  logic          s_axi_rready;

  // Radio interface
  logic          clk;
  logic          rst;
  logic   [31:0] m_axis_tdata         [ NUM_CC] [NUM_ANT];
  logic   [ 7:0] m_axis_tuser         [ NUM_CC] [NUM_ANT];
  logic          m_axis_tlast         [ NUM_CC] [NUM_ANT];
  logic          m_axis_tvalid        [ NUM_CC] [NUM_ANT];
  logic          m_axis_tready        [ NUM_CC] [NUM_ANT];

  // O-RAN U-Plane interface
  logic          clk_eth_xran;
  logic          rst_eth_xran;
  logic          sync_in;
  logic          defm_radio_start_10ms[ NUM_CC];
  logic   [11:0] s_dl_sym_num         [ NUM_CC];
  logic   [63:0] s_defm_data_tdata    [NUM_ANT];
  logic   [ 7:0] s_defm_data_tkeep    [NUM_ANT];
  logic          s_defm_data_tvalid   [NUM_ANT];
  logic          s_defm_data_tlast    [NUM_ANT];
  logic          s_defm_data_tready   [NUM_ANT];
  logic   [90:0] s_defm_data_tuser    [NUM_ANT];
  logic   [ 4:0] s_defm_data_tdest    [NUM_ANT];

  integer        monitor_file;
  integer        monitor_frame;
  integer        monitor_sample;
  integer        monitor_i;
  integer        monitor_q;

  // Deterministic QPSK mantissas. Exponent 15 converts +/-16 into a useful
  // full-band stimulus while retaining IFFT headroom.
  function automatic logic [8:0] bfp9_mantissa(input int cc, input int antenna,
                                               input int symbol_index, input int prb,
                                               input int re_index, input int component);
    logic [31:0] state;
    begin
      state = 32'h5a17_0001;
      state = state ^ (cc * 32'h9e37_79b9);
      state = state ^ (antenna * 32'h7f4a_7c15);
      state = state ^ (symbol_index * 32'h6a09_e667);
      state = state ^ (prb * 32'h3c6e_f372);
      state = state ^ (re_index * 32'ha54f_f53a);
      state = state ^ (component * 32'h510e_527f);
      state = state ^ (state << 13);
      state = state ^ (state >> 17);
      state = state ^ (state << 5);
      bfp9_mantissa = state[0] ? BFP9_POSITIVE : BFP9_NEGATIVE;
    end
  endfunction

  // Each BFP9 PRB is one exponent byte followed by twelve complex, 9-bit IQ
  // pairs. Bytes appear on TDATA in ascending byte-lane order.
  function automatic logic [7:0] bfp9_byte(input int byte_index, input int cc, input int antenna,
                                           input int symbol_index);
    logic [223:0] prb_bits;
    int prb;
    int byte_in_prb;
    begin
      prb = byte_index / BFP9_BYTES_PER_PRB;
      byte_in_prb = byte_index % BFP9_BYTES_PER_PRB;
      prb_bits = '0;
      prb_bits[223-:8] = 8'h0f;
      for (int re_index = 0; re_index < 12; re_index++) begin
        prb_bits[215-18*re_index-:9] = bfp9_mantissa(cc, antenna, symbol_index, prb, re_index, 0);
        prb_bits[206-18*re_index-:9] = bfp9_mantissa(cc, antenna, symbol_index, prb, re_index, 1);
      end
      bfp9_byte = prb_bits[223-byte_in_prb*8-:8];
    end
  endfunction

  function automatic logic [63:0] bfp9_beat(input int beat_index, input int cc, input int antenna,
                                            input int symbol_index);
    logic [63:0] data;
    int byte_index;
    begin
      data = '0;
      for (int lane = 0; lane < 8; lane++) begin
        byte_index = beat_index * 8 + lane;
        if (byte_index < BFP9_BYTES_PER_SYMBOL) begin
          data[lane*8+:8] = bfp9_byte(byte_index, cc, antenna, symbol_index);
        end
      end
      bfp9_beat = data;
    end
  endfunction

  task automatic axi_write(input logic [11:0] address, input logic [31:0] data);
    logic address_done;
    logic data_done;
    begin
      address_done = 1'b0;
      data_done = 1'b0;

      @(posedge s_axi_aclk);
      s_axi_awaddr  <= address;
      s_axi_awvalid <= 1'b1;
      s_axi_wdata   <= data;
      s_axi_wstrb   <= 4'hf;
      s_axi_wvalid  <= 1'b1;

      while (!address_done || !data_done) begin
        @(posedge s_axi_aclk);
        if (!address_done && s_axi_awready) begin
          address_done = 1'b1;
          s_axi_awvalid <= 1'b0;
        end
        if (!data_done && s_axi_wready) begin
          data_done = 1'b1;
          s_axi_wvalid <= 1'b0;
        end
      end

      s_axi_bready <= 1'b1;
      while (!s_axi_bvalid) begin
        @(posedge s_axi_aclk);
      end
      @(posedge s_axi_aclk);
      s_axi_bready <= 1'b0;
    end
  endtask

  task automatic configure_nr100m;
    begin
      // All CCs and antennas enabled, NR 30 kHz SCS, 100 MHz, BFP9.
      axi_write(DL_EN, 32'h0000_0fff);
      axi_write(DL_RAT, 32'h0000_0222);
      axi_write(DL_BIST, 32'h0000_0000);
      axi_write(DL_BW, 32'h0000_0444);
      axi_write(DL_UD, 32'h0000_0091);

      for (int cc = 0; cc < NUM_CC; cc++) begin
        axi_write(12'(DL_NPRB_BASE + 4 * cc), NUM_PRB);
        axi_write(12'(DL_RFS_OFFSET_BASE + 4 * cc), 32'h0000_0000);
        for (int antenna = 0; antenna < NUM_ANT; antenna++) begin
          axi_write(12'(DL_GAIN_BASE + 4 * (cc * NUM_ANT + antenna)), UNITY_Q14);
        end
      end

      // NR uses phase compensation. Unity initializes all four 16-entry pages.
      for (int address = 0; address < 64; address++) begin
        axi_write(12'(DL_PHASE_COMP_BASE + 4 * address), UNITY_Q14);
      end
    end
  endtask

  task automatic send_bfp9_symbol(input int cc, input int symbol_index);
    logic [NUM_ANT-1:0] active;
    logic [90:0] user;
    int beat_index[NUM_ANT];
    begin
      s_dl_sym_num[cc] = 12'(symbol_index);
      user = '0;
      user[30:27] = 4'(cc);
      user[9:0] = 10'd0;

      // Present the first beat immediately after a rising edge. It remains
      // stable for a full cycle before the DUT can accept it on the next edge.
      @(posedge clk_eth_xran);
      active = {NUM_ANT{1'b1}};
      for (int antenna = 0; antenna < NUM_ANT; antenna++) begin
        beat_index[antenna] = 0;
        s_defm_data_tdata[antenna]  <= bfp9_beat(0, cc, antenna, symbol_index);
        s_defm_data_tkeep[antenna]  <= 8'hff;
        s_defm_data_tlast[antenna]  <= 1'b0;
        s_defm_data_tuser[antenna]  <= user;
        s_defm_data_tdest[antenna]  <= 5'd0;
        s_defm_data_tvalid[antenna] <= 1'b1;
      end

      // Keep every lane fully stressed. Each antenna independently advances
      // on its own handshake, holds its beat under backpressure, and keeps
      // TVALID asserted without bubbles through the accepted TLAST beat.
      while (active != '0) begin
        @(posedge clk_eth_xran);
        for (int antenna = 0; antenna < NUM_ANT; antenna++) begin
          if (active[antenna] && s_defm_data_tready[antenna]) begin
            if (beat_index[antenna] == BFP9_BEATS_PER_SYMBOL - 1) begin
              active[antenna] = 1'b0;
              s_defm_data_tvalid[antenna] <= 1'b0;
              s_defm_data_tlast[antenna]  <= 1'b0;
            end else begin
              beat_index[antenna] = beat_index[antenna] + 1;
              s_defm_data_tdata[antenna] <=
                  bfp9_beat(beat_index[antenna], cc, antenna, symbol_index);
              s_defm_data_tkeep[antenna] <=
                  (beat_index[antenna] == BFP9_BEATS_PER_SYMBOL - 1) ? 8'h0f : 8'hff;
              s_defm_data_tlast[antenna] <=
                  (beat_index[antenna] == BFP9_BEATS_PER_SYMBOL - 1);
            end
          end
        end
      end
    end
  endtask

  task automatic pulse_radio_sync;
    begin
      @(posedge clk_eth_xran);
      sync_in <= 1'b1;
      @(posedge clk_eth_xran);
      sync_in <= 1'b0;
    end
  endtask

  // Clocks: AXI control at 100 MHz and the two data clocks at 500 MHz.
  initial begin
    s_axi_aclk = 1'b0;
    forever #5 s_axi_aclk = ~s_axi_aclk;
  end

  initial begin
    clk = 1'b0;
    forever #(1.017) clk = ~clk;
  end

  initial begin
    clk_eth_xran = 1'b0;
    forever #(1.25) clk_eth_xran = ~clk_eth_xran;
  end

`ifdef DUMP_WAVES
  initial begin
    $dumpfile("tb_pdxch.vcd");
    $dumpvars(0, tb_pdxch);
  end
`endif

  // Passive monitor for one radio output. The complete 3 CC x 4 antenna set
  // remains visible in the waveform. One sample is logged every NUM_ANT radio
  // clocks because the processing path interleaves the antenna channels.
  initial begin
    monitor_file   = $fopen("tb_pdxch_output.csv", "w");
    monitor_frame  = -1;
    monitor_sample = 0;
    if (monitor_file != 0) begin
      $fwrite(monitor_file, "frame,sample,i,q\n");
    end

    forever begin
      @(posedge clk);
      if (!rst && m_axis_tvalid[MONITOR_CC][MONITOR_ANT] &&
          m_axis_tready[MONITOR_CC][MONITOR_ANT] &&
          m_axis_tuser[MONITOR_CC][MONITOR_ANT][0]) begin
        monitor_frame  = monitor_frame + 1;
        monitor_sample = 0;
        $display("[%0t] monitoring CC%0d antenna%0d frame %0d", $time, MONITOR_CC, MONITOR_ANT,
                 monitor_frame);
        break;
      end
    end

    forever begin
      if (monitor_file != 0 && m_axis_tvalid[MONITOR_CC][MONITOR_ANT] &&
          m_axis_tready[MONITOR_CC][MONITOR_ANT]) begin
        monitor_i = $signed(
            {
              {16{m_axis_tdata[MONITOR_CC][MONITOR_ANT][15]}},
              m_axis_tdata[MONITOR_CC][MONITOR_ANT][15:0]
            }
        );
        monitor_q = $signed(
            {
              {16{m_axis_tdata[MONITOR_CC][MONITOR_ANT][31]}},
              m_axis_tdata[MONITOR_CC][MONITOR_ANT][31:16]
            }
        );
        $fwrite(monitor_file, "%0d,%0d,%0d,%0d\n", monitor_frame, monitor_sample, monitor_i,
                monitor_q);
        monitor_sample = monitor_sample + 1;
      end
      repeat (NUM_ANT) @(posedge clk);
      if (m_axis_tuser[MONITOR_CC][MONITOR_ANT][0]) begin
        monitor_frame  = monitor_frame + 1;
        monitor_sample = 0;
        $display("[%0t] monitoring CC%0d antenna%0d frame %0d", $time, MONITOR_CC, MONITOR_ANT,
                 monitor_frame);
      end
    end
  end

  initial begin
    $display("*** PDXCH stream visualization starts ***");

    s_axi_aresetn = 1'b0;
    rst = 1'b1;
    rst_eth_xran = 1'b1;
    sync_in = 1'b0;

    s_axi_awaddr = '0;
    s_axi_awprot = '0;
    s_axi_awvalid = 1'b0;
    s_axi_wdata = '0;
    s_axi_wstrb = '0;
    s_axi_wvalid = 1'b0;
    s_axi_bready = 1'b0;
    s_axi_araddr = '0;
    s_axi_arprot = '0;
    s_axi_arvalid = 1'b0;
    s_axi_rready = 1'b0;

    for (int cc = 0; cc < NUM_CC; cc++) begin
      s_dl_sym_num[cc] = '0;
      for (int antenna = 0; antenna < NUM_ANT; antenna++) begin
        m_axis_tready[cc][antenna] = 1'b1;
      end
    end
    for (int antenna = 0; antenna < NUM_ANT; antenna++) begin
      s_defm_data_tdata[antenna]  = '0;
      s_defm_data_tkeep[antenna]  = '0;
      s_defm_data_tvalid[antenna] = 1'b0;
      s_defm_data_tlast[antenna]  = 1'b0;
      s_defm_data_tuser[antenna]  = '0;
      s_defm_data_tdest[antenna]  = '0;
    end

    repeat (10) @(posedge s_axi_aclk);
    s_axi_aresetn = 1'b1;
    rst = 1'b0;
    rst_eth_xran = 1'b0;
    repeat (10) @(posedge s_axi_aclk);

    configure_nr100m();
    repeat (32) @(posedge clk);
    $display("[%0t] NR 100 MHz register configuration complete", $time);

    // Preload the two FDV ping-pong banks before the radio-frame pulse.
    for (int symbol_index = 0; symbol_index < NUM_INPUT_SYMBOLS; symbol_index++) begin
      for (int cc = 0; cc < NUM_CC; cc++) begin
        send_bfp9_symbol(cc, symbol_index);
      end
      $display("[%0t] BFP9 symbol %0d preloaded", $time, symbol_index);
    end

    pulse_radio_sync();
    $display("[%0t] radio-frame sync issued", $time);

    // Leave enough time to visualize several radio-output symbols.
    repeat (60000) @(posedge clk);
    $finish;
  end

  final begin
    if (monitor_file != 0) begin
      $fclose(monitor_file);
    end
    $display("*** PDXCH stream visualization ends ***");
  end

  pdxch #(
      .NUM_CC    (NUM_CC),
      .NUM_ANT   (NUM_ANT),
      .HALF_BLOCK(0),
      .HALF_FFT  (0)
  ) dut (
      .*
  );

endmodule

`default_nettype wire

`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_pdxch_channel;

  parameter bit HAS_CDC = 1'b0;
  parameter int NUM_ANT = 4;

  // Clock & Reset
  logic        clk;
  logic        rst;
  // 4 ant sequential
  logic [15:0] din_dr;
  logic [15:0] din_di;
  logic        din_sf;
  logic        din_sl;
  logic        din_sy;
  logic [ 3:0] din_chn;
  logic        din_dv;
  logic        din_last;
  //
  logic [31:0] m_axis_tdata         [NUM_ANT];
  logic [ 7:0] m_axis_tuser         [NUM_ANT];
  logic        m_axis_tlast         [NUM_ANT];
  logic        m_axis_tvalid        [NUM_ANT];
  logic        m_axis_tready        [NUM_ANT];
  // CSR
  logic        ctrl_clk;
  logic        ctrl_rst;
  //
  logic [ 1:0] ctrl_rat;
  logic [ 3:0] ctrl_bw;
  logic [16:0] ctrl_gain            [NUM_ANT];
  //
  logic [ 3:0] ctrl_phase_comp_addr;
  logic        ctrl_phase_comp_we;
  logic [31:0] ctrl_phase_comp_din;

  function static [11:0] bitrevorder(input logic [11:0] index);
    for (int i = 0; i < 12; i++) begin
      bitrevorder[i] = index[11-i];
    end
  endfunction

  // Clock & Reset

  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst <= 0;
  end

  initial begin
    ctrl_clk = 0;
    forever #5 ctrl_clk = ~ctrl_clk;
  end

  initial begin
    ctrl_rst = 1;
    repeat (10) @(posedge ctrl_clk);
    ctrl_rst <= 0;
  end

  // Configuration

  initial begin
    $display("*** Simulation Start ***");
    //
    ctrl_rat = 0;
    ctrl_bw = 0;
    ctrl_gain = '{default: 17'h04000};
    ctrl_phase_comp_addr = 0;
    ctrl_phase_comp_we = 0;
    ctrl_phase_comp_din = 0;

    #(1000 * 1000);
    $finish;
  end

  final begin
    $display("*** Simulation End ***");
    $stop;
  end

  // Input driver

  initial begin
    int cplen;
    logic [11:0] index;
    int symbol;

    din_dr  = 0;
    din_di  = 0;
    din_sf  = 0;
    din_sl  = 0;
    din_sy  = 0;
    din_chn = 0;
    din_dv  = 0;
    wait (rst == 0);
    @(posedge clk);

    for (int sym = 0; sym < 14; sym++) begin

      // Symbol data
      for (int i = 0; i < 2048; i++) begin
        index = i * 2;
        index = bitrevorder(index);
        for (int chn = 0; chn < 16; chn++) begin
          if (chn < NUM_ANT && ((1 <= index && index <= 300) || (1748 <= index))) begin
            symbol = $urandom_range(3);
          end else begin
            symbol = -1;
          end

          // Modulation
          case (symbol)
            0: begin
              din_dr <= 5827;
              din_di <= 5827;
            end
            1: begin
              din_dr <= -5827;
              din_di <= 5827;
            end
            2: begin
              din_dr <= 5827;
              din_di <= -5827;
            end
            3: begin
              din_dr <= -5827;
              din_di <= -5827;
            end
            default: begin
              din_dr <= 0;
              din_di <= 0;
            end
          endcase
          din_sf   <= (chn < NUM_ANT && i == 0 && sym == 0);
          din_sl   <= (chn < NUM_ANT && i == 0 && sym % 14 == 0);
          din_sy   <= (chn < NUM_ANT && i == 0);
          din_chn  <= chn;
          din_dv   <= (chn < NUM_ANT);
          din_last <= (chn < NUM_ANT && i == 2047);
          @(posedge clk);
        end
      end

      // Insert CP
      cplen = sym % 14 == 0 ? 160 : 144;
      for (int i = 0; i < cplen; i++) begin
        for (int chn = 0; chn < 16; chn++) begin
          din_dr   <= 0;
          din_di   <= 0;
          din_sf   <= 0;
          din_sl   <= 0;
          din_sy   <= 0;
          din_chn  <= chn;
          din_dv   <= 0;
          din_last <= 0;
          @(posedge clk);
        end
      end

    end
  end

  // Input logger

  integer fin;

  initial begin
    fin = $fopen("pdxch_channel_input.txt", "w");
    if (!fin) begin
      $error("Failed to open pdxch_channel_input.txt");
      $finish;
    end

    wait (rst == 0);

    // wait for sync
    forever begin
      @(posedge clk);
      if (din_sf) break;
    end

    // Log data
    forever begin
      if (din_dv && din_chn == 0) begin
        $fwrite(fin, "%d, %d\n", $signed(din_dr), $signed(din_di));
      end
      @(posedge clk);
    end
  end

  final begin
    $fclose(fin);
  end

  // Output logger

  integer fout;

  initial begin
    fout = $fopen("pdxch_channel_output.txt", "w");
    if (fout == 0) begin
      $error("Failed to open pdxch_channel_output.txt");
      $finish;
    end

    wait (rst == 0);

    // Wait for sync
    forever begin
      @(posedge clk);
      if (m_axis_tuser[0]) break;
    end

    // Log data
    forever begin
      for (int i = 0; i < 16; i++) begin
        if (i == 0) begin
          $fwrite(fout, "%d, %d\n",  //
                  $signed(m_axis_tdata[0][15:0]), $signed(m_axis_tdata[0][31:16]));
        end
        @(posedge clk);
      end
    end
  end

  final begin
    $fclose(fout);
  end

  // DUT

  pdxch_channel #(
    .HAS_CDC(HAS_CDC),
    .NUM_ANT(NUM_ANT)
  ) DUT (.*);

endmodule

`default_nettype wire

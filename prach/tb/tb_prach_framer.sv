`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_prach_framer;

  // Parameters

  localparam int CC_ID = 0;
  localparam int NUM_ANT = 1;
  localparam bit HAS_BFP = 1'b0;

  // Signals

  logic        clk;
  logic        rst;

  logic [15:0] din_dr;
  logic [15:0] din_di;
  logic        din_sf;
  logic        din_sl;
  logic        din_sy;
  logic [ 1:0] din_chn;
  logic        din_dv;
  logic        din_last;

  // ORAN Interface signals
  logic        clk_eth_xran;
  logic        rst_eth_xran;

  // C-Plane signals
  logic        s_prach_tvalid;
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

  // U-Plane signals
  logic [63:0] m_axis_tdata;
  logic [ 7:0] m_axis_tkeep;
  logic        m_axis_tlast;
  logic [31:0] m_axis_tuser;
  logic        m_axis_tvalid;
  logic        m_axis_tready;

  // CSR signals
  logic [ 3:0] ctrl_ud_comp_meth;
  logic [ 3:0] ctrl_ud_iq_width;
  logic [ 3:0] ctrl_fs_offset;
  logic [ 3:0] ctrl_static_c;

  // Clock and reset

  initial begin
    clk = 1'b0;
    forever #1 clk = ~clk;
  end

  initial begin
    rst = 1'b1;
    repeat (10) @(posedge clk);
    rst <= 1'b0;
  end

  initial begin
    clk_eth_xran = 1'b0;
    forever #(1.25) clk_eth_xran = ~clk_eth_xran;
  end

  initial begin
    rst_eth_xran = 1'b1;
    repeat (10) @(posedge clk_eth_xran);
    rst_eth_xran <= 1'b0;
  end

  // Stimulus

  initial begin
    // Initialize signals
    din_dr   = 16'h0000;
    din_di   = 16'h0000;
    din_sf   = 1'b0;
    din_sl   = 1'b0;
    din_sy   = 1'b0;
    din_chn  = 2'b00;
    din_dv   = 1'b0;
    din_last = 1'b0;

    wait (!rst);
    @(posedge clk);

    // Send PRACH frame
    for (int i = 0; i < 1536; i++) begin
      din_dr   <= $urandom_range(0, 16'hFFFF);
      din_di   <= $urandom_range(0, 16'hFFFF);
      din_sf   <= 1'b0;
      din_sl   <= 1'b0;
      din_sy   <= (i == 0);
      din_chn  <= 2'b00;
      din_dv   <= 1'b1;
      din_last <= (i == 1535);
      @(posedge clk);
    end

    // Done
    din_dv <= 1'b0;

    #10000;
    $finish;
  end

  initial begin
    m_axis_tready = 1'b1;
  end

  initial begin
    s_prach_tvalid = 1'b0;
    s_prach_rtc_pc_id = 16'h0000;
    s_prach_cc = 4'h0;
    s_prach_ss = 8'h00;
    s_prach_section_id = 12'h000;
    s_prach_return_port = 4'h0;
    s_prach_filter_index = 4'h0;
    s_prach_f = 8'h00;
    s_prach_sf = 4'h0;
    s_prach_sl = 6'h00;
    s_prach_sy = 6'h00;
    s_prach_time_offset = 16'h0000;
    s_prach_frame_structure = 8'h00;
    s_prach_cp_length = 16'h0000;
    s_prach_udcomphdr = 8'h00;
    s_prach_rb = 1'b0;
    s_prach_syminc = 1'b0;
    s_prach_start_prbc = 10'h000;
    s_prach_num_prbc = 8'h00;
    s_prach_remask = 12'h000;
    s_prach_num_symbol = 4'h0;
    s_prach_beamid = 15'h0000;
    s_prach_freqoffset = 24'h000000;
  end

  initial begin
    $display("*** Simulation started ***");
    ctrl_ud_comp_meth = 4'h0;
    ctrl_ud_iq_width  = 4'h0;
    ctrl_fs_offset    = 4'h0;
    ctrl_static_c     = 4'hF;
  end

  final begin
    $display("*** Simulation finished ***");
  end

  // DUT

  prach_framer #(
      .CC_ID  (CC_ID),
      .NUM_ANT(NUM_ANT),
      .HAS_BFP(HAS_BFP)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire

`timescale 1 ns / 1 ps `default_nettype none

module tb_dl_adaptor_gearbox_mod4;

  parameter int NUM_CC = 1;
  parameter int NUM_DL_LAYER = 4;

  // DUT Signals

  logic        clk_400m;
  logic        rst_400m;

  // Timing ports
  logic        defm_radio_start_10ms;
  logic        s_dl_update                      [      NUM_CC];

  // 4 branch/layer stream; CC shared
  logic [63:0] s_defm_data_tdata                [NUM_DL_LAYER];
  logic [ 7:0] s_defm_data_tkeep                [NUM_DL_LAYER];
  logic        s_defm_data_tvalid               [NUM_DL_LAYER];
  logic        s_defm_data_tlast                [NUM_DL_LAYER];
  logic        s_defm_data_tready               [NUM_DL_LAYER];
  logic [89:0] s_defm_data_tuser                [NUM_DL_LAYER];

  // Interface with DFE
  logic        clk_491m52;
  logic        rst_491m52;

  // DL symbol timing
  logic        dl_radio_start_10ms = 0;

  // 2 CC port; each will have interleaved 4 layer data
  logic        dl_sof                           [      NUM_CC];
  logic        dl_sop                           [      NUM_CC];
  logic        dl_sof_ahead_11                  [      NUM_CC];
  logic        dl_sop_ahead_11                  [      NUM_CC];
  logic [15:0] dl_data_i                        [      NUM_CC] [NUM_DL_LAYER/4];
  logic [15:0] dl_data_q                        [      NUM_CC] [NUM_DL_LAYER/4];
  logic        dl_valid                         [      NUM_CC];

  // Control Interface
  logic        clk_axi;

  logic [ 3:0] ctrl_bandwidth                   [      NUM_CC];
  logic [ 1:0] ctrl_numerology                  [      NUM_CC];
  logic [ 1:0] ctrl_compression_mode            [      NUM_CC] [NUM_DL_LAYER];

  logic        ctrl_enmask                      [      NUM_CC];
  logic [11:0] ctrl_remask                      [      NUM_CC];
  logic [13:0] ctrl_symmask                     [      NUM_CC];

  logic [10:0] dl_eq_gain_mem_addr              [      NUM_CC];
  logic [31:0] dl_eq_gain_mem_wdata             [      NUM_CC];
  logic        dl_eq_gain_mem_we                [      NUM_CC];
  logic [31:0] dl_eq_gain_mem_rdata             [      NUM_CC];
  logic [15:0] dl_iq_gain                       [      NUM_CC];
  logic [ 3:0] dl_iq_exp_offset                 [      NUM_CC];

  logic [ 1:0] buffer_mem_ctrl_en               [      NUM_CC];
  logic [ 8:0] dfe_dl_adaptor_mem_symbol_no_sel;
  logic [11:0] buffer_mem_addr_i                [      NUM_CC] [NUM_DL_LAYER];
  logic [31:0] buffer_mem_data_i                [      NUM_CC] [NUM_DL_LAYER];
  logic        buffer_mem_we                    [      NUM_CC] [NUM_DL_LAYER];
  logic [31:0] buffer_mem_data_o                [      NUM_CC] [NUM_DL_LAYER];

  // Simulation signals

  logic [63:0] TDATA                            [        1000];
  logic [ 7:0] TKEEP                            [        1000];
  logic [89:0] TUSER                            [        1000];


  task send_section(input int start_rb, input int number_rb, input int cc);
    automatic int odd = (number_rb % 2);
    automatic int len = (number_rb / 2) * 3 + odd * 2;
    begin
      for (int i = 0; i < len; i++) begin
        TDATA[i] = 64'h0123456789ABCDEF;
        TKEEP[i] = (i == len - 1 && odd) ? 0 : 7;
        TUSER[i] = '0;
      end
      i_axi4s_vip.IF.master_send(len, TDATA, TKEEP, TUSER);
      @(posedge clk_400m);
      @(posedge clk_400m);
    end
  endtask


  // Stimulation
  //============

  // Clock Generation
  //-----------------

  initial begin
    clk_400m = 0;
    forever begin
      #(1.25) clk_400m = ~clk_400m;
    end
  end

  initial begin
    clk_491m52 = 0;
    forever begin
      #(1.017) clk_491m52 = ~clk_491m52;
    end
  end


  // Reset Generation
  //-----------------

  initial begin
    rst_400m = 1;
    repeat (100) @(posedge clk_400m);
    rst_400m <= 0;
  end

  initial begin
    rst_491m52 = 1;
    repeat (100) @(posedge clk_491m52);
    rst_491m52 <= 0;
  end


  // Main Process
  //-------------

  initial begin

    // Reset

    i_axi4s_vip.set_master_mode();
    i_axi4s_vip.IF.reset();

    for (int cc = 0; cc < NUM_CC; cc++) begin
      s_dl_update[cc] = 0;
      ctrl_bandwidth[cc] = 0;
      ctrl_numerology[cc] = 0;
      ctrl_enmask[cc] = 1;
      ctrl_remask[cc] = 12'hAAA;
      ctrl_symmask[cc] = 14'b00100000000101;
      for (int ly = 0; ly < NUM_DL_LAYER; ly++) begin
        ctrl_compression_mode[cc][ly] = 2;
        buffer_mem_ctrl_en[cc][ly] = 0;
      end
    end

    wait (rst_400m == 0);
    #1000;

    // Stimulate

    fork

      begin : set_sof
        @(posedge clk_491m52);
        dl_radio_start_10ms <= 1;
        @(posedge clk_491m52);
        dl_radio_start_10ms <= 0;
        #10;
      end

      begin : set_sop
        #100;
        repeat (10) begin
          @(posedge clk_400m);
          s_dl_update <= '{NUM_CC{1}};
          @(posedge clk_400m);
          s_dl_update <= '{NUM_CC{0}};
          repeat (14685 - 2) @(posedge clk_400m);
        end
      end

      begin : set_dl_data
        #200;
        send_section(0, 136, 0);
        send_section(136, 137, 0);
        send_section(0, 136, 1);
        send_section(136, 137, 1);
        #100;
      end

    join

    #(1000);
    $finish(2);
  end


  // DUT
  //====

  axi4s_vip #(
      .HAS_TKEEP  (1),
      .HAS_TLAST  (1),
      .TDATA_WIDTH(64),
      .TUSER_WIDTH(90)
  ) i_axi4s_vip (
      .aclk         (clk_400m),
      .aresetn      (~rst_400m),
      //
      .m_axis_tdata (s_defm_data_tdata[0]),
      .m_axis_tkeep (s_defm_data_tkeep[0]),
      .m_axis_tlast (s_defm_data_tlast[0]),
      .m_axis_tvalid(s_defm_data_tvalid[0]),
      .m_axis_tuser (s_defm_data_tuser[0]),
      .m_axis_tready(s_defm_data_tready[0])
  );

  dl_adaptor #(
      .NUM_CC      (NUM_CC),
      .NUM_DL_LAYER(NUM_DL_LAYER)
  ) UUT (
      // Interface with XORIF
      //=====================
      // Note, connect these ports to XORIF same name ports
      .clk_400m                        (clk_400m),
      .rst_400m                        (rst_400m),
      // Timing ports
      .defm_radio_start_10ms           (defm_radio_start_10ms),
      .s_dl_update                     (s_dl_update),
      // 16 branch/layer stream, CC shared
      .s_defm_data_tdata               (s_defm_data_tdata),
      .s_defm_data_tkeep               (s_defm_data_tkeep),
      .s_defm_data_tvalid              (s_defm_data_tvalid),
      .s_defm_data_tlast               (s_defm_data_tlast),
      .s_defm_data_tready              (s_defm_data_tready),
      .s_defm_data_tuser               (s_defm_data_tuser),
      // Interface with DFE
      //===================
      .clk_491m52                      (clk_491m52),
      .rst_491m52                      (rst_491m52),
      // DL symbol timing
      // This is base line of DL timing
      .dl_radio_start_10ms             (dl_radio_start_10ms),
      // 2 CC port, each will have interleaved 4 layer data
      .dl_sof                          (dl_sof),
      .dl_sop                          (dl_sop),
      .dl_sof_ahead_11                 (dl_sof_ahead_11),
      .dl_sop_ahead_11                 (dl_sop_ahead_11),
      .dl_data_i                       (dl_data_i),
      .dl_data_q                       (dl_data_q),
      .dl_valid                        (dl_valid),
      // Control Interface
      //==================
      .clk_axi                         (clk_axi),
      //
      .ctrl_bandwidth                  (ctrl_bandwidth),
      .ctrl_numerology                 (ctrl_numerology),
      .ctrl_compression_mode           (ctrl_compression_mode),
      //
      .ctrl_enmask                     (ctrl_enmask),
      .ctrl_remask                     (ctrl_remask),
      .ctrl_symmask                    (ctrl_symmask),
      //
      .dl_eq_gain_mem_addr             (dl_eq_gain_mem_addr),
      .dl_eq_gain_mem_wdata            (dl_eq_gain_mem_wdata),
      .dl_eq_gain_mem_we               (dl_eq_gain_mem_we),
      .dl_eq_gain_mem_rdata            (dl_eq_gain_mem_rdata),
      //
      .buffer_mem_ctrl_en              (buffer_mem_ctrl_en),
      .dfe_dl_adaptor_mem_symbol_no_sel(dfe_dl_adaptor_mem_symbol_no_sel),
      .buffer_mem_addr_i               (buffer_mem_addr_i),
      .buffer_mem_data_i               (buffer_mem_data_i),
      .buffer_mem_we                   (buffer_mem_we),
      .buffer_mem_data_o               (buffer_mem_data_o)
  );

endmodule

`default_nettype wire

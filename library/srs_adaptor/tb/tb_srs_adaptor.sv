`timescale 1 ns / 1 ps `default_nettype none

module tb_srs_adaptor;

  parameter int NUM_ETH_PORT = 2;
  parameter int NUM_SRS_LAYER = 64;
  parameter int NUM_CC = 2;

  // DUT Signal
  //===========

  // DFE Clock & Reset
  logic        clk_491m52;
  logic        rst_491m52;

  // SRS Configuration
  logic [ 3:0] srs_cfg_cc;
  logic [11:0] srs_cfg_symbol;
  logic [ 3:0] srs_cfg_numsymbol;
  logic        srs_cfg_valid;

  // SRS Data Request
  logic [ 3:0] srs_req_cc;
  logic [ 5:0] srs_req_layer;
  logic [11:0] srs_req_symbol;
  logic        srs_req_valid;

  // SRS Data
  logic [23:0] srs_data = 0;
  logic        srs_valid = 0;
  logic        srs_sop = 0;
  logic        srs_eop = 0;

  // XORIF Clock & Reset
  logic        clk_400m;
  logic        rst_400m;

  // UL Timing
  logic [11:0] s_ul_sym_num                             [      NUM_CC] = '{NUM_CC{'0}};
  logic        s_ul_update                              [      NUM_CC] = '{NUM_CC{'0}};

  // ORAN Parse Port
  logic        s_t_header_offset_valid                  [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic        s_runt_packet_len                        [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [15:0] s_rtc_pc_id                              [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic        s_concat                                 [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [ 2:0] s_messagetype                            [NUM_ETH_PORT] = '{NUM_ETH_PORT{'d2}};
  logic [ 7:0] s_seqid                                  [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [ 6:0] s_subseqid                               [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic        s_ebit                                   [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [15:0] s_payloadsize                            [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic        s_packet_in_window                       [NUM_ETH_PORT] = '{NUM_ETH_PORT{'d1}};
  logic [11:0] s_offset_in_symbol                       [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  //
  logic        s_radio_app_head_valid                   [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic        s_datadirection                          [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [ 7:0] s_numsections                            [NUM_ETH_PORT] = '{NUM_ETH_PORT{'d1}};
  logic [ 2:0] s_sectiontype                            [NUM_ETH_PORT] = '{NUM_ETH_PORT{'d1}};
  logic [ 3:0] s_filterindex                            [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [ 7:0] s_frameid                                [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [ 3:0] s_subframeid                             [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [ 5:0] s_slotid                                 [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [ 5:0] s_symbolid                               [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [ 7:0] s_udcomphdr                              [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [15:0] s_timeoffset                             [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [ 7:0] s_framestructure                         [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [15:0] s_cplength                               [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  //
  logic        s_section_header_valid                   [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [ 3:0] s_numsymbol                              [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [ 7:0] s_numprbc                                [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [ 9:0] s_startprbc                              [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [11:0] s_sectionid                              [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic        s_rb                                     [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [11:0] s_remask                                 [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [14:0] s_beamid15                               [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};
  logic [23:0] s_freqoffset                             [NUM_ETH_PORT] = '{NUM_ETH_PORT{'0}};

  // UNSOL Port
  logic [63:0] m_fram_unsol_tdata;
  logic [ 7:0] m_fram_unsol_tkeep;
  logic        m_fram_unsol_tvalid;
  logic        m_fram_unsol_tlast;
  logic        m_fram_unsol_tready = 1;
  logic [31:0] m_fram_unsol_tuser;

  logic [ 1:0] ctrl_numerology = 0;  // 0 for 30 kHz SCS


  task automatic srs_c_message(input [3:0] cc, input [5:0] layer, input [7:0] frameid,
                               input [3:0] subframeid, input [5:0] slotid, input [5:0] symbolid,
                               input [3:0] numsymbol, input [7:0] numprbc, input [9:0] startprbc,
                               input [11:0] sectionid);
    begin
      @(posedge clk_400m);
      s_t_header_offset_valid[0] <= 1;
      // [15:12] DU Port ID
      // [   11] Band Sector
      // [10: 8] CC ID
      // [ 7: 0] RU Port ID
      s_rtc_pc_id[0] <= {4'b0, 1'b0, cc[2:0], 2'b01, layer};
      @(posedge clk_400m);
      s_t_header_offset_valid[0] <= 0;

      @(posedge clk_400m);
      s_radio_app_head_valid[0] <= 1;
      s_frameid[0] <= frameid;
      s_subframeid[0] <= subframeid;
      s_slotid[0] <= slotid;
      s_symbolid[0] <= symbolid;
      @(posedge clk_400m);
      s_radio_app_head_valid[0] <= 0;

      @(posedge clk_400m);
      s_section_header_valid[0] <= 1;
      s_numsymbol[0] <= numsymbol;
      s_numprbc[0] <= numprbc;
      s_startprbc[0] <= startprbc;
      s_sectionid[0] <= sectionid;
      @(posedge clk_400m);
      s_section_header_valid[0] <= 0;
    end
  endtask

  task automatic update_sym(input [11:0] sym);
    begin
      @(posedge clk_400m);
      s_ul_sym_num <= '{NUM_CC{sym}};
      s_ul_update  <= '{NUM_CC{'1}};
      @(posedge clk_400m);
      s_ul_update <= '{NUM_CC{'0}};
    end
  endtask


  // Stimulation
  //============

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

  initial begin
    wait(rst_400m == 0);
    wait(rst_491m52 == 0);


    for (int layer = 0; layer < 64; layer++) begin
      srs_c_message(0, layer, 0, 0, 0, 1, 3, 273, 0, 0);
    end

    #1000;
    update_sym(1);

    #100000;
    $finish();
  end


  // UUT
  //====

  srs_adaptor UUT (.*);

endmodule

`default_nettype wire

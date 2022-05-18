`timescale 1 ns / 1 ps `default_nettype none

module tb_dl_adaptor;

  parameter int NUM_CC = 2;

  // DUT Signals

  logic        clk;
  logic        rst;

  // branch/layer stream; CC shared
  logic [63:0] s_axis_tdata;
  logic [ 7:0] s_axis_tkeep;
  logic        s_axis_tvalid;
  logic        s_axis_tlast;
  logic        s_axis_tready;
  logic [89:0] s_axis_tuser;

  // 2 CC port
  logic [63:0] gb_data                          [      NUM_CC];
  logic        gb_valid                         [      NUM_CC];
  logic [11:0] gb_re                            [      NUM_CC];

  // Simulation signals

  logic [63:0] TDATA                            [        1000];
  logic [ 7:0] TKEEP                            [        1000];
  logic [89:0] TUSER                            [        1000];


  task send_section(input int start_rb, input int number_rb, input int cc);
    automatic int odd = (number_rb % 2);
    automatic int len = (number_rb / 2) * 3 + odd * 2;
    begin
      for (int i = 0; i < len; i++) begin
        TDATA[i] = i;
        TKEEP[i] = (i == len - 1 && odd) ? 15 : 7;
        //
        TUSER[i] = '0;
        TUSER[i][9:0] = start_rb; 
        TUSER[i][17:10] = number_rb;
        TUSER[i][27] = (i == 0); // start_of_symbol
        TUSER[i][30:28] = 0; // cc
        TUSER[i][31] = (i == 2); // ModParamValid
        TUSER[i][33:32] = 1; // Modulation Compress
        TUSER[i][48:34] = 0; // Modulation Compress Scalar Value
        TUSER[i][49] = 0; // Constellation Shift Factor
        TUSER[i][61:50] = 4095; // Modulation Compress RE Mask
      end
      i_axi4s_vip.IF.master_send(len, TDATA, TKEEP, TUSER);
      @(posedge clk);
      @(posedge clk);
    end
  endtask


  // Stimulation
  //============

  // Clock Generation
  //-----------------

  initial begin
    clk = 0;
    forever begin
      #(1.25) clk = ~clk;
    end
  end

  // Reset Generation
  //-----------------

  initial begin
    rst = 1;
    repeat (100) @(posedge clk);
    rst <= 0;
  end

  // Main Process
  //-------------

  initial begin

    // Reset

    i_axi4s_vip.set_master_mode();
    i_axi4s_vip.IF.reset();

    wait (rst == 0);
    #1000;

    // Stimulate

    fork

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
      .aclk         (clk),
      .aresetn      (~rst),
      //
      .m_axis_tdata (s_axis_tdata),
      .m_axis_tkeep (s_axis_tkeep),
      .m_axis_tlast (s_axis_tlast),
      .m_axis_tvalid(s_axis_tvalid),
      .m_axis_tuser (s_axis_tuser),
      .m_axis_tready(s_axis_tready)
  );

  dl_adaptor_gearbox_mod4 #(
      .NUM_CC      (NUM_CC)
  ) UUT (
      // Interface with XORIF
      //=====================
      // Note, connect these ports to XORIF same name ports
      .clk                        (clk),
      .rst                        (rst),
      // 16 branch/layer stream, CC shared
      .s_axis_tdata               (s_axis_tdata),
      .s_axis_tkeep               (s_axis_tkeep),
      .s_axis_tvalid              (s_axis_tvalid),
      .s_axis_tlast               (s_axis_tlast),
      .s_axis_tready              (s_axis_tready),
      .s_axis_tuser               (s_axis_tuser),
      //
      .gb_data                    (gb_data),
      .gb_valid                   (gb_valid),
      .gb_re                      (gb_re)
  );

endmodule

`default_nettype wire

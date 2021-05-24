// file: tb_adaptor.sv
// brief: Test bench for dl_adaptor and ul_adaptor.
`timescale 1 ns / 1 ps `default_nettype none

module tb_adaptor ();

  parameter int NUM_CC = 1;
  parameter int NUM_DL_LAYER = 1;
  parameter int NUM_UL_LAYER = 1;


  // DUT Signals
  //============

  // XORIF
  logic        clk_400m;
  logic        rst_400m;

  // Timing signals
  logic        dl_radio_start_10ms = 0;
  logic        s_dl_update               [      NUM_CC] = '{NUM_CC{'0}};
  //
  logic        fram_radio_start_10ms = 0;
  logic        s_ul_update               [      NUM_CC] = '{NUM_CC{'0}};

  // 16 branch/layer stream; CC shared
  logic [63:0] s_defm_data_tdata         [NUM_DL_LAYER];
  logic [ 7:0] s_defm_data_tkeep         [NUM_DL_LAYER];
  logic        s_defm_data_tvalid        [NUM_DL_LAYER];
  logic        s_defm_data_tlast         [NUM_DL_LAYER];
  logic        s_defm_data_tready        [NUM_DL_LAYER];
  logic [30:0] s_defm_data_tuser         [NUM_DL_LAYER];

  // 8 branch/layer stream; CC shared
  logic [63:0] m_fram_data_tdata         [NUM_UL_LAYER];
  logic [ 7:0] m_fram_data_tkeep         [NUM_UL_LAYER];
  logic        m_fram_data_tvalid        [NUM_UL_LAYER];
  logic        m_fram_data_tlast         [NUM_UL_LAYER];
  logic        m_fram_data_tready        [NUM_UL_LAYER] = '{NUM_UL_LAYER{'1}};
  //
  logic [24:0] m_fram_data_req           [NUM_UL_LAYER] = '{NUM_UL_LAYER{'0}};

  // DFE
  logic        clk_491m52;
  logic        rst_491m52;

  // DL output
  logic        dl_sof                    [      NUM_CC];
  logic        dl_sop                    [      NUM_CC];
  logic        dl_sof_ahead_7            [      NUM_CC];
  logic        dl_sop_ahead_7            [      NUM_CC];
  logic [15:0] dl_data_i                 [      NUM_CC]                         [NUM_DL_LAYER];
  logic [15:0] dl_data_q                 [      NUM_CC]                         [NUM_DL_LAYER];
  logic        dl_valid                  [      NUM_CC];

  // UL input
  logic        ul_sof_ahead_3            [      NUM_CC];
  logic        ul_sop_ahead_3            [      NUM_CC];
  logic [15:0] ul_data_i                 [      NUM_CC]                         [NUM_UL_LAYER];
  logic [15:0] ul_data_q                 [      NUM_CC]                         [NUM_UL_LAYER];

  // Control signals
  logic [ 3:0] ctrl_bandwidth            [      NUM_CC] = '{NUM_CC{4'b0}};
  logic [ 1:0] ctrl_numerology           [      NUM_CC] = '{NUM_CC{2'b0}};
  logic [ 1:0] ctrl_compression_mode     [      NUM_CC] = '{NUM_CC{2'b1}};

  logic  [ 1:0] dl_buffer_mem_ctrl_en    [      NUM_CC] = '{NUM_CC {'0} };
  logic  [11:0] dl_buffer_mem_addr_i     [      NUM_CC][NUM_DL_LAYER] = '{NUM_CC {'{NUM_DL_LAYER {'0} }} };
  logic  [31:0] dl_buffer_mem_data_i     [      NUM_CC][NUM_DL_LAYER] = '{NUM_CC {'{NUM_DL_LAYER {'0} }} };
  logic         dl_buffer_mem_we         [      NUM_CC][NUM_DL_LAYER] = '{NUM_CC {'{NUM_DL_LAYER {'0} }} };

  logic  [ 1:0] ul_buffer_mem_ctrl_en    [      NUM_CC] = '{NUM_CC {'0} };
  logic  [11:0] ul_buffer_mem_addr_i     [      NUM_CC][NUM_UL_LAYER] = '{NUM_CC {'{NUM_UL_LAYER {'0} }} };
  logic  [31:0] ul_buffer_mem_data_i     [      NUM_CC][NUM_UL_LAYER] = '{NUM_CC {'{NUM_UL_LAYER {'0} }} };
  logic         ul_buffer_mem_we         [      NUM_CC][NUM_UL_LAYER] = '{NUM_CC {'{NUM_UL_LAYER {'0} }} };

  // Simulation signals
  //=====================

  int          fin, fout;

  logic [63:0] TDATA                     [        1000];
  logic [ 7:0] TKEEP                     [        1000];
  logic        TVALID                    [        1000];
  logic        TLAST                     [        1000];
  logic        TREADY                    [        1000];
  logic [30:0] TUSER                     [        1000];

  int          len;

  logic        sof_ahead_d               [      NUM_CC][4];
  logic        sop_ahead_d               [      NUM_CC][4];

  function automatic int load_packet();
    int n = 0;
    int r = 0;
    forever begin
      r = $fscanf(fin, "%x, %x, %x, %x, %x, %x", TDATA[n], TKEEP[n], TVALID[n], TLAST[n], TREADY[n],
              TUSER[n]);
      if (r <= 0) return 0;
      if (TLAST[n]) break;
      n++;
    end
    $display("%0d words loaded from file", n + 1);
    return n + 1;
  endfunction

  // Connect DL to UL
  //-----------------

  always_ff @ (posedge clk_491m52) begin
    for (int cc = 0; cc < NUM_CC; cc++) begin
      sof_ahead_d[cc][0] <= dl_sof_ahead_7[cc];
      for (int i = 1; i < 4; i++) begin
        sof_ahead_d[cc][i] <= sof_ahead_d[cc][i-1];
      end
    end
  end

  always_ff @ (posedge clk_491m52) begin
    for (int cc = 0; cc < NUM_CC; cc++) begin
      sop_ahead_d[cc][0] <= dl_sop_ahead_7[cc];
      for (int i = 1; i < 4; i++) begin
        sop_ahead_d[cc][i] <= sop_ahead_d[cc][i-1];
      end
    end
  end

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin
      assign ul_sof_ahead_3[i] = sof_ahead_d[i][3];
      assign ul_sop_ahead_3[i] = sop_ahead_d[i][3];
    end
  endgenerate

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin
      assign ul_data_i[i] = dl_data_i[i][0:NUM_UL_LAYER-1];
      assign ul_data_q[i] = dl_data_q[i][0:NUM_UL_LAYER-1];
    end
  endgenerate

  // DUT
  //====

  axi4s_vip #(
      .HAS_TKEEP  (1),
      .HAS_TLAST  (1),
      .TDATA_WIDTH(64),
      .TUSER_WIDTH(31)
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
  ) i_dl_adaptor (
      .clk_400m             (clk_400m),
      .rst_400m             (rst_400m),
      //
      .s_dl_update          (s_dl_update),
      //
      .s_defm_data_tdata    (s_defm_data_tdata),
      .s_defm_data_tkeep    (s_defm_data_tkeep),
      .s_defm_data_tvalid   (s_defm_data_tvalid),
      .s_defm_data_tlast    (s_defm_data_tlast),
      .s_defm_data_tready   (s_defm_data_tready),
      .s_defm_data_tuser    (s_defm_data_tuser),
      //
      .clk_491m52           (clk_491m52),
      .rst_491m52           (rst_491m52),
      //
      .dl_radio_start_10ms  (dl_radio_start_10ms),
      //
      .dl_sof               (dl_sof),
      .dl_sop               (dl_sop),
      .dl_sof_ahead_7       (dl_sof_ahead_7),
      .dl_sop_ahead_7       (dl_sop_ahead_7),
      .dl_data_i            (dl_data_i),
      .dl_data_q            (dl_data_q),
      .dl_valid             (dl_valid),
      //
      .ctrl_bandwidth       (ctrl_bandwidth),
      .ctrl_numerology      (ctrl_numerology),
      .ctrl_compression_mode(ctrl_compression_mode),
      //
      .buffer_mem_ctrl_en   (dl_buffer_mem_ctrl_en),
      .buffer_mem_addr_i    (dl_buffer_mem_addr_i),
      .buffer_mem_data_i    (dl_buffer_mem_data_i),
      .buffer_mem_we        (dl_buffer_mem_we),
      .buffer_mem_data_o    ()
  );

  ul_adaptor #(
      .NUM_CC(NUM_CC),
      .NUM_UL_LAYER(NUM_UL_LAYER)
  ) i_ul_adaptor (
      //
      .clk_400m             (clk_400m),
      .rst_400m             (rst_400m),
      //
      .fram_radio_start_10ms(fram_radio_start_10ms),
      .s_ul_update          (s_ul_update),
      //
      .m_fram_data_tdata    (m_fram_data_tdata),
      .m_fram_data_tkeep    (m_fram_data_tkeep),
      .m_fram_data_tvalid   (m_fram_data_tvalid),
      .m_fram_data_tlast    (m_fram_data_tlast),
      .m_fram_data_tready   (m_fram_data_tready),
      //
      .m_fram_data_req      (m_fram_data_req),
      //
      .clk_491m52           (clk_491m52),
      .rst_491m52           (rst_491m52),
      //
      .ul_sof_ahead_3       (ul_sof_ahead_3),
      .ul_sop_ahead_3       (ul_sop_ahead_3),
      .ul_data_i            (ul_data_i),
      .ul_data_q            (ul_data_q),
      //
      .ctrl_bandwidth       (ctrl_bandwidth),
      .ctrl_numerology      (ctrl_numerology),
      .ctrl_compression_mode(ctrl_compression_mode),
      //
      .buffer_mem_ctrl_en   (ul_buffer_mem_ctrl_en),
      .buffer_mem_addr_i    (ul_buffer_mem_addr_i),
      .buffer_mem_data_i    (ul_buffer_mem_data_i),
      .buffer_mem_we        (ul_buffer_mem_we),
      .buffer_mem_data_o    ()
  );


  // Stimulation
  //============

  // Clock and reset generation
  //---------------------------

  initial begin
    clk_400m = 0;
    forever begin
      #(1.25) clk_400m = ~clk_400m;
    end
  end

  initial begin
    rst_400m = 1;
    repeat (100) @(posedge clk_400m);
    rst_400m = 0;
  end

  initial begin
    clk_491m52 = 0;
    forever begin
      #(1.017) clk_491m52 = ~clk_491m52;
    end
  end

  initial begin
    rst_491m52 = 1;
    repeat (100) @(posedge clk_491m52);
    rst_491m52 = 0;
  end

  // Main Process
  //-------------

  // set dl_radio_start_10ms every 10 ms
  initial begin
    wait(rst_491m52 == 0);
    wait(rst_400m   == 0);
    #100;

    forever begin
      @(posedge clk_491m52);
      dl_radio_start_10ms <= 1;
      @(posedge clk_491m52);
      dl_radio_start_10ms <= 0;
      repeat(4915200 - 2) @(posedge clk_491m52);
    end
  end

  // Set s_dl_update like XORIF
  initial begin
    forever begin
      @(posedge clk_491m52);
      if (dl_radio_start_10ms) break;
    end
    #10;
    forever begin
      @(posedge clk_400m);
      s_dl_update <= '{NUM_CC{1}};
      @(posedge clk_400m);
      s_dl_update <= '{NUM_CC{0}};
      repeat(14285 - 2) @(posedge clk_400m);
    end
  end

  // Set s_ul_update like XORIF
  initial begin
    forever begin
      @(posedge clk_400m);
      if (fram_radio_start_10ms) break;
    end

    forever begin
      @(posedge clk_400m);
      s_ul_update <= '{NUM_CC{1}};
      @(posedge clk_400m);
      s_ul_update <= '{NUM_CC{0}};
      repeat(14285 - 2) @(posedge clk_400m);
    end
  end

  // Send DL packets
  initial begin
    string line;
    fin = $fopen("s_defm_data.txt", "r");
    if (fin == 0) begin
      $error("Error open file");
      $finish();
    end
    // Skip first line which is table header
    $fgets(line, fin);

    i_axi4s_vip.set_master_mode();
    i_axi4s_vip.IF.reset();

    repeat(7) begin
      forever begin
        @(posedge clk_400m);
        if (s_dl_update[0]) break;
      end

      repeat (3) begin
        len = load_packet();
        i_axi4s_vip.IF.master_send(len, TDATA, TKEEP, TUSER);
        #100;
      end
      $display("Send 1 symbol OK");
    end

    $finish(2);
  end

  // Send UL request
  initial begin
    forever begin
      forever begin
        @(posedge clk_400m);
        if (s_ul_update[0]) break;
      end

      @(posedge clk_400m);
      m_fram_data_req[0] <= {1'b1, 9'd0,   8'd119, 3'd0, 4'd0};
      @(posedge clk_400m);
      m_fram_data_req[0] <= {1'b1, 9'd119, 8'd119, 3'd0, 4'd0};
      @(posedge clk_400m);
      m_fram_data_req[0] <= {1'b1, 9'd238, 8'd35,  3'd0, 4'd0};
      @(posedge clk_400m);
      m_fram_data_req[0] <= '0;
    end
  end

  // Log UL packet
  
  initial begin
    fout = $fopen("m_fram_data.txt", "w");
    if (fout == 0) begin
      $error("Error open file");
      $finish();
    end
    $fwrite(fout, "tdata, tkeep, tvalid, tlast, tready\n");
    
    wait(rst_400m ==0);
    forever begin
      @(posedge clk_400m);
      if (m_fram_data_tvalid[0] && m_fram_data_tready[0]) begin
        $fwrite(fout, "%16x, %2x, %0x, %0x, %0x\n", m_fram_data_tdata[0], m_fram_data_tkeep[0], m_fram_data_tvalid[0], m_fram_data_tlast[0], m_fram_data_tready[0]);
      end
    end
  end

  final begin
    $fclose(fin);
    $fclose(fout);
  end

endmodule

`default_nettype wire

`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_lowphy_top;

  parameter int CH_NUM = 1;
  parameter int TEST_NUM_SYMBOL = 28;

  logic        s_axi_aclk;
  logic        s_axi_aresetn;

  logic [ 8:0] s_axi_awaddr;
  logic [ 2:0] s_axi_awprot;
  logic        s_axi_awvalid;
  logic        s_axi_awready;
  //
  logic [31:0] s_axi_wdata;
  logic [ 3:0] s_axi_wstrb;
  logic        s_axi_wvalid;
  logic        s_axi_wready;
  //
  logic [ 1:0] s_axi_bresp;
  logic        s_axi_bvalid;
  logic        s_axi_bready;
  //
  logic [ 8:0] s_axi_araddr;
  logic [ 2:0] s_axi_arprot;
  logic        s_axi_arvalid;
  logic        s_axi_arready;
  //
  logic [31:0] s_axi_rdata;
  logic [ 1:0] s_axi_rresp;
  logic        s_axi_rvalid;
  logic        s_axi_rready;
  //
  logic        clk;
  logic        rst;
  //
  logic        lowphy_dl_sof   [CH_NUM];
  logic        lowphy_dl_sos   [CH_NUM];
  logic [31:0] lowphy_dl_data  [CH_NUM];
  logic        lowphy_dl_valid [CH_NUM];
  //
  logic        lowphy_ul_sof   [CH_NUM];
  logic        lowphy_ul_sos   [CH_NUM];
  logic [31:0] lowphy_ul_data  [CH_NUM];
  logic        lowphy_ul_valid [CH_NUM];
  //
  logic        dl_sof          [CH_NUM];
  logic        dl_sos          [CH_NUM];
  logic [31:0] dl_data         [CH_NUM];
  logic        dl_valid        [CH_NUM];
  //
  logic        ul_sof          [CH_NUM];
  logic        ul_sos          [CH_NUM];
  logic [31:0] ul_data         [CH_NUM];
  logic        ul_valid        [CH_NUM];

  integer fin;
  integer fout1;
  integer fout2;

  // Loop back DL data to UL

  always_ff @(posedge clk) begin
    ul_data  <= dl_data;
    ul_valid <= dl_valid;
  end
  
  initial begin
    ul_sof[0] = 0;

    forever begin
      @(posedge clk);
      if (dl_sof[0]) begin
        repeat(88*4) @(posedge clk);
        ul_sof[0] <= 1;
        @(posedge clk);
        ul_sof[0] <= 0;
      end
    end
  end

  initial begin
    static int current_symbol = 0;
    ul_sos[0] = 0;

    forever begin
      @(posedge clk);
      if (dl_sof[0]) begin
        current_symbol = 0;
      end else if (dl_sos[0]) begin
        current_symbol = (current_symbol + 1) % 14;;
      end

      if (dl_sos[0]) begin
        if (current_symbol == 0) begin
          repeat(88*4) @(posedge clk);
        end else begin
          repeat(72*4) @(posedge clk);
        end
        ul_sos[0] <= 1;
        @(posedge clk);
        ul_sos[0] <= 0;
      end
    end
  end


  // DUT

  lowphy_top #(
    .CH_NUM(CH_NUM)
  ) UUT (.*);


  // Test stimulation

  initial begin
    clk = 0;
    forever begin
      #(4.069) clk = ~clk;
    end
  end

  initial begin
    s_axi_aclk = 0;
    forever begin
      #5 s_axi_aclk = ~s_axi_aclk;
    end
  end

  initial begin
    rst = 1;
    #1000;
    rst = 0;
  end

  initial begin
    s_axi_aresetn = 0;
    #1000;
    s_axi_aresetn = 1;
  end


  // Read test input from file

  initial begin
    int max_sample;
    bit [31:0] tmp;

    lowphy_dl_sof[0]   <= 1'b0;
    lowphy_dl_sos[0]   <= 1'b0;
    lowphy_dl_data[0]  <= '0;
    lowphy_dl_valid[0] <= 1'b0;

    #1000;
    wait (rst == 0);
    #1000;

    fin = $fopen("lowphy_ifft_input.txt", "r");
    if (fin == 0) begin
      $error("Error opening file!");
      #1 $finish;
    end

    for (int symbol = 0; symbol < TEST_NUM_SYMBOL; symbol++) begin
      // TODO: this is only for mu = 1
      max_sample = (1024 + ((symbol % 14 == 0) ? 88 : 72)) * 4;
      for (int sample = 0; sample < max_sample; sample ++) begin

        // Writ 4k data to input
        @(posedge clk);
        lowphy_dl_sof[0] <= (sample == 0) && (symbol == 0);
        lowphy_dl_sos[0] <= (sample == 0);
        if (sample < 1024) begin
          if ($fscanf(fin, "%x\n", tmp) < 0) begin
            lowphy_dl_data[0] <= '0;
          end else begin
            lowphy_dl_data[0] <= tmp;
          end
        end
        lowphy_dl_valid[0] <= (sample < 1024);

      end
    end
  end

  // Log lowphy iFFT output to file

  initial begin
    fout1 = $fopen("lowphy_ifft_output.txt", "w");
    if (fout1 == 0) begin
      $error("Error openning file!");
      #1 $finish;
    end

    // wait
    forever begin
      @(posedge clk);
      if (dl_sof[0]) break;
    end

    repeat(TEST_NUM_SYMBOL * 15360 / 14) begin
      forever begin
        if (dl_valid[0]) begin
          $fwrite(fout1, "%x\n", dl_data[0]);
          @(posedge clk);
          break;
        end else begin
          @(posedge clk);
        end
      end
    end
  end

  // Log lowphy FFT output to file

  initial begin
    fout2 = $fopen("lowphy_fft_output.txt", "w");
    if (fout2 == 0) begin
      $error("Error openning file!");
      #1 $finish;
    end

    // wait
    forever begin
      @(posedge clk);
      if (lowphy_ul_sof[0]) break;
    end

    repeat(TEST_NUM_SYMBOL * 1024) begin
      forever begin
        if (lowphy_ul_valid[0]) begin
          $fwrite(fout2, "%x\n", lowphy_ul_data[0]);
          @(posedge clk);
          break;
        end else begin
          @(posedge clk);
        end
      end
    end

    #10000;
    $finish;
  end

  final begin
    $fclose(fin);
    $fclose(fout1);
    $fclose(fout2);
  end

endmodule

`default_nettype wire

// file: tb_ul_adaptor.sv
// brief: Test bench for ul_adaptor
`timescale 1 ns / 1 ps `default_nettype none

module tb_ul_adaptor ();

  parameter int NUM_CC = 2;
  parameter int NUM_UL_LAYER = 8;

  // DUT Signals
  //============

  // XORIF
  logic        clk_400m;
  logic        rst_400m;
  //
  logic        fram_radio_start_10ms = 0;
  logic        ul_update                 [      NUM_CC] = '{NUM_CC{1'b0}};
  // AXIS
  logic [63:0] m_fram_data_tdata         [NUM_UL_LAYER];
  logic [ 7:0] m_fram_data_tkeep         [NUM_UL_LAYER];
  logic        m_fram_data_tvalid        [NUM_UL_LAYER];
  logic        m_fram_data_tlast         [NUM_UL_LAYER];
  logic        m_fram_data_tready        [NUM_UL_LAYER] = '{NUM_UL_LAYER{1'b1}};
  // FIFO
  logic [24:0] m_fram_data_req           [NUM_UL_LAYER] = '{NUM_UL_LAYER{'0}};

  // DFE
  logic        clk_491m52;
  logic        rst_491m52;
  // URAM
  logic        ul_sof_ahead_3            [      NUM_CC] = '{NUM_CC{1'b0}};
  logic        ul_sop_ahead_3            [      NUM_CC] = '{NUM_CC{1'b0}};
  logic [15:0] ul_data_i                 [      NUM_CC]                         [NUM_UL_LAYER];
  logic [15:0] ul_data_q                 [      NUM_CC]                         [NUM_UL_LAYER];

  logic [ 3:0] ctrl_bandwidth            [      NUM_CC] = '{NUM_CC{4'b0}};
  logic [ 1:0] ctrl_numerology           [      NUM_CC] = '{NUM_CC{2'b0}};
  logic [ 1:0] ctrl_compression_mode     [      NUM_CC] = '{NUM_CC{2'b0}};
  //
  logic [ 1:0] buffer_mem_ctrl_en        [      NUM_CC];
  logic [11:0] buffer_mem_addr_i         [      NUM_CC]                         [NUM_UL_LAYER];
  logic [31:0] buffer_mem_data_i         [      NUM_CC]                         [NUM_UL_LAYER];
  logic        buffer_mem_we             [      NUM_CC]                         [NUM_UL_LAYER];
  logic [31:0] buffer_mem_data_o         [      NUM_CC]                         [NUM_UL_LAYER];


  // One OFDM symbol data
  //=====================

  logic [31:0] SYMBOL_MEM                [        4096];
  logic [11:0] cnt = 0;

  initial begin : init_symbol_mem
    logic [2:0] exp;
    logic [8:0] mantissa;

    for (int addr = 0; addr < 4096; addr++) begin
      exp = $urandom();
      for (int i = 0; i < 2; i++) begin
        mantissa = $urandom();
        SYMBOL_MEM[addr][i*16+15-:16] = (mantissa << exp);
      end
    end

  end

  // Clock and reset generation
  //===========================

  initial begin
    clk_400m = 0;
    forever begin
      #(1.25) clk_400m = ~clk_400m;
    end
  end

  initial begin
    rst_400m = 1;
    repeat (10) @(posedge clk_400m);
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
    repeat (10) @(posedge clk_491m52);
    rst_491m52 = 0;
  end

  // Generate UL data
  //=================

  initial begin
    wait(rst_491m52 == 0);
    #100;

    fork

      //++++++++++++++++++
      begin : gen_sof
        forever begin
          // Set ul_sof_ahead_3 every radio frame
          @(posedge clk_491m52);
          ul_sof_ahead_3 <= '{NUM_CC{1'b1}};
          @(posedge clk_491m52);
          ul_sof_ahead_3 <= '{NUM_CC{1'b0}};
          repeat (4915200 - 2) @(posedge clk_491m52);
        end
      end

      //++++++++++++++++++
      begin : gen_sop
        forever begin
          // One radio fram
          repeat (14) begin
            // One symbol
            @(posedge clk_491m52);
            ul_sop_ahead_3 <= '{NUM_CC{1'b1}};
            @(posedge clk_491m52);
            ul_sop_ahead_3 <= '{NUM_CC{1'b0}};
            // Wait N tick, which is 4096 + CP time
            repeat ((4096 + 352) * 4 - 2) @(posedge clk_491m52);
          end
        end
      end

      //++++++++++++++++++
      begin : gen_ul_data
        // wait 3 ticks
        repeat (3) @(posedge clk_491m52);
        forever begin
          // One radio frame
          repeat (14) begin
            // One symbol
            repeat (4096) begin
              // One sample, takes 4 ticks to set
              @(posedge clk_491m52);
              {ul_data_q[0][0], ul_data_i[0][0]} <= SYMBOL_MEM[cnt++];
              repeat (3) @(posedge clk_491m52);
            end
            // Wait CP time
            repeat (352 * 4 - 2) @(posedge clk_491m52);
          end
        end
      end

    join
  end

  ul_adaptor #(
      .NUM_CC(NUM_CC),
      .NUM_UL_LAYER(NUM_UL_LAYER)
  ) UUT (
      .*
  );

endmodule

`default_nettype wire

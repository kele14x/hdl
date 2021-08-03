// file: tb_ul_adaptor.sv
// brief: Test bench for ul_adaptor
`timescale 1 ns / 1 ps `default_nettype none

module tb_ul_adaptor ();

  parameter int NUM_CC = 1;
  parameter int NUM_UL_LAYER = 1;

  // DUT Signals
  //============

  // XORIF
  logic        clk_400m;
  logic        rst_400m;
  //
  logic        fram_radio_start_10ms = 0;
  logic        s_ul_update               [      NUM_CC] = '{NUM_CC{1'b0}};
  // AXIS
  logic [63:0] m_fram_data_tdata         [NUM_UL_LAYER];
  logic [ 7:0] m_fram_data_tkeep         [NUM_UL_LAYER];
  logic        m_fram_data_tvalid        [NUM_UL_LAYER];
  logic        m_fram_data_tlast         [NUM_UL_LAYER];
  logic        m_fram_data_tready        [NUM_UL_LAYER] = '{NUM_UL_LAYER{1'b0}};
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
  logic [ 1:0] buffer_mem_ctrl_en        [      NUM_CC] = '{NUM_CC{2'b0}};
  logic [11:0] buffer_mem_addr_i         [      NUM_CC]                         [NUM_UL_LAYER] = '{NUM_CC{'{NUM_UL_LAYER{'0}}}};
  logic [31:0] buffer_mem_data_i         [      NUM_CC]                         [NUM_UL_LAYER] = '{NUM_CC{'{NUM_UL_LAYER{'0}}}};
  logic        buffer_mem_we             [      NUM_CC]                         [NUM_UL_LAYER] = '{NUM_CC{'{NUM_UL_LAYER{'0}}}};
  logic [31:0] buffer_mem_data_o         [      NUM_CC]                         [NUM_UL_LAYER];

  logic ul_radio_start_10ms = 0;

  // One OFDM symbol data
  //=====================

  logic [31:0] SYMBOL_MEM                [        4096];
  logic [11:0] cnt = 0;

  initial begin : init_symbol_mem
    $readmemh("symbols.mem", SYMBOL_MEM, 0, 4095);
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


  // XORIF Simply
  //=============

  initial begin

    fork

      //++++++++++++++++++
      begin : gen_fram_req
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
          m_fram_data_req[0] <= {1'b1, 9'd238, 8'd53,  3'd0, 4'd0};
          @(posedge clk_400m);
          m_fram_data_req[0] <= '0;
        end
      end

      //++++++++++++++
      begin : gen_m_fram_data_tready
        forever begin
          forever begin
            @(posedge clk_400m);
            if (s_ul_update[0]) break;
          end
          
          repeat(3) begin
            repeat(1000) begin
              @(posedge clk_400m);
              m_fram_data_tready[0] <= 1'b1;
              if (m_fram_data_tvalid[0] == 1 && m_fram_data_tlast[0] == 1) break;
            end
            m_fram_data_tready[0] <= 1'b0;
            repeat(2) begin
              @(posedge clk_400m);
              m_fram_data_tready[0] <= 1'b0;
            end
          end
        end
      end

      //++++++++++++++++
      begin : gen_s_ul_update
        forever begin
          forever begin
            @(posedge clk_400m);
            if (fram_radio_start_10ms) break;
          end

          for (int slot = 0; slot < 20; slot++) begin
            for (int sym = 0; sym < 14; sym++) begin
              @(posedge clk_400m);
              s_ul_update <= '{NUM_CC{1'b1}};
              @(posedge clk_400m);
              s_ul_update <= '{NUM_CC{1'b0}};
              repeat(14285 - 2) @(posedge clk_400m);
              // or 14285 * 4 + 14286 * 10
            end
          end
        end
      end

      //++++++++++++
      begin : gen_ul_radio_start_10ms
        wait(rst_491m52 == 0);
        #1000;
        @(posedge clk_491m52);
        ul_radio_start_10ms <= 1;
        @(posedge clk_491m52);
        ul_radio_start_10ms <= 0;
      end

    join
  end

  // DUT
  //====

  ul_adaptor #(
      .NUM_CC(NUM_CC),
      .NUM_UL_LAYER(NUM_UL_LAYER)
  ) UUT (
      .*
  );

  ul_traffic_gen i_ul_traffic_gen (
    .clk                (clk_491m52),
    .rst                (rst_491m52),
    //
    .ul_radio_start_10ms(ul_radio_start_10ms),
    //
    .ul_sof_ahead_3     (ul_sof_ahead_3[0]),
    .ul_sop_ahead_3     (ul_sop_ahead_3[0]),
    .ul_data_i          (ul_data_i[0][0]),
    .ul_data_q          (ul_data_q[0][0]),
    // Control
    .ctrl_numerology    (ctrl_numerology[0])
  );

endmodule

`default_nettype wire

// file: cfr_upx.sv
// brief: Perform up-sampling of input signal streams

`timescale 1ns / 1ps `default_nettype none

module cfr_pc_upx #(
    // Architecture parameters
    parameter int CSR        = 2,
    parameter int UP_FACTOR  = 2,
    // Data path parameters
    parameter int DATA_WIDTH = 16
) (
    // Data interface
    input var  logic                  clk,
    input var  logic                  rst,
    // Data input
    input var  logic [DATA_WIDTH-1:0] data_i_in,
    input var  logic [DATA_WIDTH-1:0] data_q_in,
    // Data output
    output var logic [DATA_WIDTH-1:0] data_i_out[UP_FACTOR],
    output var logic [DATA_WIDTH-1:0] data_q_out[UP_FACTOR]
);


  localparam int Latency_1 = (UP_FACTOR < 2) ? 0 : (CSR == 1) ? 9 : 12;
  localparam int Latency_2 = (UP_FACTOR < 4) ? 0 : (CSR == 1) ? 6 : 8;
  localparam int Latency = Latency_1 + Latency_2;


  logic signed [DATA_WIDTH-1:0] data_up2_i_p0;
  logic signed [DATA_WIDTH-1:0] data_up2_i_p1;
  logic signed [DATA_WIDTH-1:0] data_up2_q_p0;
  logic signed [DATA_WIDTH-1:0] data_up2_q_p1;

  logic signed [DATA_WIDTH-1:0] data_up4_i_p0;
  logic signed [DATA_WIDTH-1:0] data_up4_i_p1;
  logic signed [DATA_WIDTH-1:0] data_up4_i_p2;
  logic signed [DATA_WIDTH-1:0] data_up4_i_p3;
  logic signed [DATA_WIDTH-1:0] data_up4_q_p0;
  logic signed [DATA_WIDTH-1:0] data_up4_q_p1;
  logic signed [DATA_WIDTH-1:0] data_up4_q_p2;
  logic signed [DATA_WIDTH-1:0] data_up4_q_p3;


  // TODO: absorb the logic into HB_UP2 module

  // Up-sample original => 2x
  generate
    if (UP_FACTOR >= 2) begin : g_up2
      if (CSR == 1) begin : g_csr1_up2

        // Up-sample by 2
        // 9 clock tick impulse latency

        hb_up2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(3),
            .COE_NUMS      ({1277, -4710, 20014}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_i (
            .clk  (clk),
            .rst  (rst),
            .xin  (data_i_in),
            .yout0(data_up2_i_p0),
            .yout1(data_up2_i_p1),
            .ovf  (  /* Not used */)
        );

        hb_up2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(3),
            .COE_NUMS      ({1277, -4710, 20014}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_q (
            .clk  (clk),
            .rst  (rst),
            .xin  (data_q_in),
            .yout0(data_up2_q_p0),
            .yout1(data_up2_q_p1),
            .ovf  (  /* Not used */)
        );

      end else begin : g_csr2_up2

        // Up-sample by 2
        // 12 clock tick impulse latency

        hb_up2_int2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(3),
            .COE_NUMS      ({1277, -4710, 20014}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_i (
            .clk  (clk),
            .rst  (rst),
            .xin  (data_i_in),
            .yout0(data_up2_i_p0),
            .yout1(data_up2_i_p1),
            .ovf  (  /* Not used */)
        );

        hb_up2_int2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(3),
            .COE_NUMS      ({1277, -4710, 20014}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_q (
            .clk  (clk),
            .rst  (rst),
            .xin  (data_q_in),
            .yout0(data_up2_q_p0),
            .yout1(data_up2_q_p1),
            .ovf  (  /* Not used */)
        );

      end  // CSR switch
    end  // UP_FACTOR switch
  endgenerate


  // Up-sample 2x => 4x
  generate
    if (UP_FACTOR >= 4) begin : g_up4

      if (CSR == 1) begin : g_csr1_up4

        // Up-sample by 2 again
        // ?? clock tick impulse latency
        // TODO: may not exist

        hb_up2_p2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(2),
            .COE_NUMS      ({-2788, 19030}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_2_i (
            .clk  (clk),
            .rst  (rst),
            .xin0 (data_up2_i_p0),
            .xin1 (data_up2_i_p1),
            .yout0(data_up4_i_p0),
            .yout1(data_up4_i_p1),
            .yout2(data_up4_i_p2),
            .yout3(data_up4_i_p3),
            .ovf  (  /* Not used */)
        );

        hb_up2_p2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(2),
            .COE_NUMS      ({-2788, 19030}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_2_q (
            .clk  (clk),
            .rst  (rst),
            .xin0 (data_up2_q_p0),
            .xin1 (data_up2_q_p1),
            .yout0(data_up4_q_p0),
            .yout1(data_up4_q_p1),
            .yout2(data_up4_q_p2),
            .yout3(data_up4_q_p3),
            .ovf  (  /* Not used */)
        );

      end else begin : g_csr2_up4

        // Up-sample by 2 again
        // 8 clock tick impulse latency

        hb_up2_int2_p2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(2),
            .COE_NUMS      ({-2788, 19030}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_2_i (
            .clk  (clk),
            .rst  (rst),
            .xin0 (data_up2_i_p0),
            .xin1 (data_up2_i_p1),
            .yout0(data_up4_i_p0),
            .yout1(data_up4_i_p1),
            .yout2(data_up4_i_p2),
            .yout3(data_up4_i_p3),
            .ovf  (  /* Not used */)
        );

        hb_up2_int2_p2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(2),
            .COE_NUMS      ({-2788, 19030}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_2_q (
            .clk  (clk),
            .rst  (rst),
            .xin0 (data_up2_q_p0),
            .xin1 (data_up2_q_p1),
            .yout0(data_up4_q_p0),
            .yout1(data_up4_q_p1),
            .yout2(data_up4_q_p2),
            .yout3(data_up4_q_p3),
            .ovf  (  /* Not used */)
        );

      end  // CSR switch
    end  // UP_FACTOR switch
  endgenerate

  // Connect the output
  generate
    if (UP_FACTOR == 1) begin : g_up1_out

      // No up-sample
      assign data_i_out[0] = data_i_in;
      assign data_q_out[0] = data_q_in;

    end else if (UP_FACTOR == 2) begin : g_up2_out

      assign data_i_out[0] = data_up2_i_p0;
      assign data_i_out[1] = data_up2_i_p1;
      assign data_q_out[0] = data_up2_q_p0;
      assign data_q_out[1] = data_up2_q_p1;


    end else begin : g_up4_out

      assign data_i_out[0] = data_up4_i_p0;
      assign data_i_out[1] = data_up4_i_p1;
      assign data_i_out[2] = data_up4_i_p2;
      assign data_i_out[3] = data_up4_i_p3;
      assign data_q_out[0] = data_up4_q_p0;
      assign data_q_out[1] = data_up4_q_p1;
      assign data_q_out[2] = data_up4_q_p2;
      assign data_q_out[3] = data_up4_q_p3;

    end  // UP_FACTOR switch
  endgenerate

endmodule

`default_nettype wire

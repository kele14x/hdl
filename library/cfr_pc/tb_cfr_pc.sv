// File: tb_cfr_pc.sv
// Brief: Test bench for module cfr_pc

`timescale 1ns / 1ps `default_nettype none

module tb_cfr_pc ();

  localparam int TestVectorLength = 4096;
  localparam int DutLatency = 129;

  localparam int DataWidth = 16;
  localparam int CpwAddrWidth = 8;

  logic                           clk;
  logic                           rst;

  logic signed [   DataWidth-1:0] data_i_in;
  logic signed [   DataWidth-1:0] data_q_in;

  logic signed [   DataWidth-1:0] data_i_out;
  logic signed [   DataWidth-1:0] data_q_out;

  logic                           ctrl_clk;
  logic                           ctrl_rst;

  logic                           ctrl_enable;
  logic        [             3:0] ctrl_spacing;
  logic        [     DataWidth:0] ctrl_clipping_threshold;
  logic        [     DataWidth:0] ctrl_pd_threshold;

  logic        [CpwAddrWidth-1:0] ctrl_cpw_addr;
  logic                           ctrl_cpw_en;
  logic                           ctrl_cpw_we;
  logic        [   DataWidth-1:0] ctrl_cpw_wr_data_i;
  logic        [   DataWidth-1:0] ctrl_cpw_wr_data_q;


  logic signed [   DataWidth-1:0] data_i_out_ref;
  logic signed [   DataWidth-1:0] data_q_out_ref;

  logic signed [   DataWidth-1:0] data_i_out_err;
  logic signed [   DataWidth-1:0] data_q_out_err;

  logic signed [   DataWidth-1:0] data_i_in_mem           [TestVectorLength];
  logic signed [   DataWidth-1:0] data_q_in_mem           [TestVectorLength];
  logic signed [   DataWidth-1:0] data_i_out_mem          [TestVectorLength];
  logic signed [   DataWidth-1:0] data_q_out_mem          [TestVectorLength];

  logic signed [   DataWidth-1:0] cancellation_pulse_i_mem[ 2**CpwAddrWidth];
  logic signed [   DataWidth-1:0] cancellation_pulse_q_mem[ 2**CpwAddrWidth];

  initial begin
    $readmemh("test_cfr_pc_cancellation_pulse_i.txt", cancellation_pulse_i_mem, 0,
              2 ** CpwAddrWidth - 1);
    $readmemh("test_cfr_pc_cancellation_pulse_q.txt", cancellation_pulse_q_mem, 0,
              2 ** CpwAddrWidth - 1);
    //
    $readmemh("test_cfr_pc_data_i_in.txt", data_i_in_mem, 0, TestVectorLength - 1);
    $readmemh("test_cfr_pc_data_q_in.txt", data_q_in_mem, 0, TestVectorLength - 1);
    $readmemh("test_cfr_pc_data_i_out.txt", data_i_out_mem, 0, TestVectorLength - 1);
    $readmemh("test_cfr_pc_data_q_out.txt", data_q_out_mem, 0, TestVectorLength - 1);
  end

  initial begin
    clk = 0;
    ctrl_clk = 0;
    forever begin
      #5;
      clk = ~clk;
      ctrl_clk = ~ctrl_clk;
    end
  end

  initial begin
    rst = 1;
    ctrl_rst = 1;
    data_i_in = 0;
    data_q_in = 0;
    ctrl_enable = 1;
    ctrl_spacing = 1;
    ctrl_clipping_threshold = 13818;
    ctrl_pd_threshold = 13818;
    ctrl_cpw_addr = 0;
    ctrl_cpw_en = 0;
    ctrl_cpw_we = 0;
    ctrl_cpw_wr_data_i = 0;
    ctrl_cpw_wr_data_q = 0;
    #10000;
    rst = 0;
    ctrl_rst = 0;
  end

  cfr_pc #(
      .DATA_WIDTH    (DataWidth),
      .CPW_ADDR_WIDTH(CpwAddrWidth)
  ) DUT (
      .*
  );

  assign data_i_out_err = data_i_out - data_i_out_ref;
  assign data_q_out_err = data_q_out - data_q_out_ref;

  initial begin
    $display("**************************");
    $display("Simulation starts.");

    wait(rst == 0);

    #100;
    // Set cancellation pulse
    for (int i = 0; i < 2 ** CpwAddrWidth; i++) begin
      @(posedge ctrl_clk);
      ctrl_cpw_addr <= i;
      ctrl_cpw_en <= 1'b1;
      ctrl_cpw_we <= 1'b1;
      ctrl_cpw_wr_data_i <= cancellation_pulse_i_mem[i];
      ctrl_cpw_wr_data_q <= cancellation_pulse_q_mem[i];
    end
    @(posedge ctrl_clk);
    ctrl_cpw_addr <= 0;
    ctrl_cpw_en <= 1'b0;
    ctrl_cpw_we <= 1'b0;
    ctrl_cpw_wr_data_i <= 0;
    ctrl_cpw_wr_data_q <= 0;


    fork
      begin : feed_input
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          //          data_i_in <= (i == 0) ? 100000 : 0;
          //          data_q_in <= 0;
          data_i_in <= data_i_in_mem[i];
          data_q_in <= data_q_in_mem[i];
        end
      end

      begin : gen_ref_output
        repeat (DutLatency) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          data_i_out_ref <= data_i_out_mem[i];
          data_q_out_ref <= data_q_out_mem[i];
        end
      end

      begin : check_output
        repeat (DutLatency + 1) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          if (data_i_out_err) begin
            $warning("\"data_i_out\" mismatch with golden reference, ", "time = %t, ", $time,
                     "i = %d, ", i, "expected = %d, ", data_i_out_ref, "got = %d", data_i_out);
          end
          if (data_q_out_err) begin
            $warning("\"data_q_out\" mismatch with golden reference, ", "time = %t, ", $time,
                     "i = %d, ", i, "expected = %d, ", data_q_out_ref, "got = %d", data_q_out);
          end
        end
      end
    join

    #100;
    $display("Simulation ends.");
    $finish();
  end

endmodule

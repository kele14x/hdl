// File: tb_ch_fir.sv
// Brief: Testbench for ch_fir module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_ch_fir;

  parameter int CSR_SUPPORT = 4;
  parameter int NUM_STAGES = 2;
  parameter int DATA_WIDTH = 16;
  parameter int COE_DATA_WIDTH = 16;
  parameter int SRA_BITS = 0;


  bit                                                     clk;
  bit                                                     rst;
  //
  bit signed [                            DATA_WIDTH-1:0] data_in;
  bit                                                     data_valid_in;
  //
  bit signed [                            DATA_WIDTH-1:0] data_out;
  bit                                                     data_valid_out;
  // Control signals
  //----------------
  bit                                                     ctrl_clk;
  bit                                                     ctrl_rst;
  // Coefficient memory
  bit                                                     ctrl_coe_en;
  bit                                                     ctrl_coe_we;
  bit        [$clog2(NUM_STAGES)+$clog2(CSR_SUPPORT)-1:0] ctrl_coe_addr;
  bit        [                        COE_DATA_WIDTH-1:0] ctrl_coe_din;
  bit        [                        COE_DATA_WIDTH-1:0] ctrl_coe_dout;


  // Stimulation
  //============

  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    repeat (16) @(posedge clk);
    rst <= 0;
  end

  initial begin
    ctrl_clk = 0;
    forever begin
      #5 ctrl_clk = ~ctrl_clk;
    end
  end

  initial begin
    ctrl_rst = 1;
    repeat (16) @(posedge ctrl_clk);
    ctrl_rst <= 0;
  end

  initial begin
    ctrl_coe_en   = 0;
    ctrl_coe_we   = 0;
    ctrl_coe_addr = 0;
    ctrl_coe_din  = 0;
    wait (ctrl_rst == 0);
    for (int i = 0; i < NUM_STAGES; i++) begin
      for (int j = 0; j < CSR_SUPPORT; j++) begin
        @(posedge ctrl_clk);
        ctrl_coe_en   <= 1;
        ctrl_coe_we   <= 1;
        ctrl_coe_addr <= i * CSR_SUPPORT + j;
        ctrl_coe_din  <= i * CSR_SUPPORT + j + 1;
      end
    end
    @(posedge ctrl_clk);
    ctrl_coe_en   <= 0;
    ctrl_coe_we   <= 0;
    ctrl_coe_addr <= 0;
    ctrl_coe_din  <= 0;
  end

  initial begin
    data_in = 0;
    data_valid_in = 0;
    wait (rst == 0);
    for (int i = 0; i < 10000; i++) begin
      @(posedge clk);
      data_in <= (i == 6000);
      data_valid_in <= (i % 4 == 0);
    end
    #1000;
    $finish;
  end


  // DUT
  //====

  ch_fir #(
      .CSR_SUPPORT   (CSR_SUPPORT),
      .NUM_STAGES    (NUM_STAGES),
      .DATA_WIDTH    (DATA_WIDTH),
      .COE_DATA_WIDTH(COE_DATA_WIDTH),
      .SRA_BITS      (SRA_BITS)
  ) DUT (
      .clk           (clk),
      .rst           (rst),
      //
      .data_in       (data_in),
      .data_valid_in (data_valid_in),
      //
      .data_out      (data_out),
      .data_valid_out(data_valid_out),
      // Control signals
      //----------------
      .ctrl_clk      (ctrl_clk),
      .ctrl_rst      (ctrl_rst),
      // Coefficient memory
      .ctrl_coe_en   (ctrl_coe_en),
      .ctrl_coe_we   (ctrl_coe_we),
      .ctrl_coe_addr (ctrl_coe_addr),
      .ctrl_coe_din  (ctrl_coe_din),
      .ctrl_coe_dout (ctrl_coe_dout)
  );

endmodule

`default_nettype wire

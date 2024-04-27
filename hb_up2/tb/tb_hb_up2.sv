// File: tb_hb_up2.sv
// Brief: Test bench for hb_up2
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_hb_up2;

  parameter int NUM_CHANNELS = 16;
  parameter int NUM_STAGES = 3;
  parameter int DATA_WIDTH = 16;
  parameter int COE_ADDR_WIDTH = 3;
  parameter int COE_DATA_WIDTH = 16;
  parameter int SRA_BITS = 0;


  bit                                                clk;
  bit                                                rst;
  //
  bit signed [                       DATA_WIDTH-1:0] data_in;
  bit                                                data_sync_in;
  //
  bit signed [                       DATA_WIDTH-1:0] data_p0_out;
  bit signed [                       DATA_WIDTH-1:0] data_p1_out;
  bit                                                data_sync_out;
  //
  bit                                                ovf;
  //
  bit                                                ctrl_clk;
  bit                                                ctrl_rst;
  //
  bit                                                ctrl_coe_en;
  bit                                                ctrl_coe_we;
  bit        [$clog2(NUM_STAGES)+COE_ADDR_WIDTH-1:0] ctrl_coe_addr;
  bit        [                   COE_DATA_WIDTH-1:0] ctrl_coe_din;
  bit        [                   COE_DATA_WIDTH-1:0] ctrl_coe_dout;


  always begin
    clk = 0;
    #1;
    clk = 1;
    #1;
  end

  initial begin
    rst = 1;
    repeat (16) @(posedge clk);
    rst <= 0;
  end

  always begin
    ctrl_clk = 0;
    #5;
    ctrl_clk = 1;
    #5;
  end

  initial begin
    ctrl_rst = 1;
    repeat (16) @(posedge ctrl_clk);
    ctrl_rst <= 0;
  end


  initial begin
    $display("*****************");
    $display("Simulation start.");
    data_in = 0;
    data_sync_in = 0;
    ctrl_coe_en = 0;
    ctrl_coe_we = 0;
    ctrl_coe_addr = 0;
    ctrl_coe_din = 0;

    // Set coefficients
    wait (ctrl_rst == 0);
    #100;
    for (int c = 0; c < 1; c++) begin
      for (int s = 0; s < NUM_STAGES; s++) begin
        @(posedge ctrl_clk);
        ctrl_coe_en <= 1;
        ctrl_coe_we <= 1;
        ctrl_coe_addr <= s * (2 ** COE_ADDR_WIDTH) + c;
        ctrl_coe_din <= 1 + s;
      end
    end
    @(posedge ctrl_clk);
    ctrl_coe_en <= 0;
    ctrl_coe_we <= 0;
    ctrl_coe_addr <= 0;
    ctrl_coe_din <= 0;
  end

  initial begin
    data_in = 0;
    data_sync_in = 0;
    wait (rst == 0);
    for (int i = 0; i < 1000; i++) begin
      for (int j = 0; j < NUM_CHANNELS; j++) begin
        @(posedge clk);
        data_in <= (i == 100) && (j == 0);
        data_sync_in <= (j == 0);
      end
    end
    #1000;
    $display("Simulation ends.");
    $finish;
  end


  hb_up2 #(
      .NUM_CHANNELS  (NUM_CHANNELS),
      .NUM_STAGES    (NUM_STAGES),
      .DATA_WIDTH    (DATA_WIDTH),
      .COE_ADDR_WIDTH(COE_ADDR_WIDTH),
      .COE_DATA_WIDTH(COE_DATA_WIDTH),
      .SRA_BITS      (SRA_BITS)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire

// File: tb_fir.sv
// Brief: Testbench for fir module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_fir;

  parameter int NUM_CHANNELS = 16;
  parameter int NUM_STAGES = 64;
  parameter bit EVEN_TAPS = 0;
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
  bit signed [                       DATA_WIDTH-1:0] data_out;
  bit                                                data_sync_out;
  //
  bit                                                ctrl_clk;
  bit                                                ctrl_rst;
  //
  bit                                                ctrl_coe_en;
  bit                                                ctrl_coe_we;
  bit        [$clog2(NUM_STAGES)+COE_ADDR_WIDTH-1:0] ctrl_coe_addr;
  bit        [                   COE_DATA_WIDTH-1:0] ctrl_coe_din;
  bit        [                   COE_DATA_WIDTH-1:0] ctrl_coe_dout;


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
    for (int s = 0; s < NUM_STAGES; s++) begin
      for (int c = 0; c < 1; c++) begin
        @(posedge ctrl_clk);
        ctrl_coe_en   <= 1;
        ctrl_coe_we   <= 1;
        ctrl_coe_addr <= s * (2**COE_ADDR_WIDTH) + c;
        ctrl_coe_din  <= s + 1;
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
    $finish;
  end


  // DUT
  //====

  fir #(
      .NUM_CHANNELS  (NUM_CHANNELS),
      .NUM_STAGES    (NUM_STAGES),
      .EVEN_TAPS     (EVEN_TAPS),
      .DATA_WIDTH    (DATA_WIDTH),
      .COE_ADDR_WIDTH(COE_ADDR_WIDTH),
      .COE_DATA_WIDTH(COE_DATA_WIDTH),
      .SRA_BITS      (SRA_BITS)
  ) DUT (
      .clk          (clk),
      .rst          (rst),
      //
      .data_in      (data_in),
      .data_sync_in (data_sync_in),
      //
      .data_out     (data_out),
      .data_sync_out(data_sync_out),
      // Control signals
      //----------------
      .ctrl_clk     (ctrl_clk),
      .ctrl_rst     (ctrl_rst),
      // Coefficient memory
      .ctrl_coe_en  (ctrl_coe_en),
      .ctrl_coe_we  (ctrl_coe_we),
      .ctrl_coe_addr(ctrl_coe_addr),
      .ctrl_coe_din (ctrl_coe_din),
      .ctrl_coe_dout(ctrl_coe_dout)
  );

endmodule

`default_nettype wire

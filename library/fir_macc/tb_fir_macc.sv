// File: tb_fir_macc.sv
// Brief: Testbench for module fir_macc.
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_fir_macc;

  parameter int XIN_WIDTH = 24;
  parameter int COE_WIDTH = 16;
  parameter int YOUT_WIDTH = 24;
  parameter int SRA_BITS = 15;

  logic                  aclk;
  logic                  aresetn;
  // Data input
  logic [ XIN_WIDTH-1:0] s_axis_tdata;
  logic                  s_axis_tvalid;
  logic                  s_axis_tready;
  logic [           3:0] s_axis_tuser;
  // Data output
  logic [YOUT_WIDTH-1:0] m_axis_tdata;
  logic                  m_axis_tvalid;
  logic                  m_axis_tready;
  logic [           3:0] m_axis_tuser;
  // Control interface
  logic [           9:0] ctrl_coe_wr_addr;
  logic                  ctrl_coe_wr_en;
  logic [ COE_WIDTH-1:0] ctrl_coe_wr_din;
  //
  logic [           6:0] ctrl_coefficient_length;
  logic [           2:0] ctrl_coefficient_set;
  // Status
  logic                  err_ovf;


  // Stimulation
  //============

  initial begin
    aclk = 0;
    forever begin
      #5 aclk = ~aclk;
    end
  end

  initial begin
    aresetn = 0;
    #100;
    aresetn = 1;
  end

  initial begin
    // Reset interface    

    s_axis_tdata  <= 0;
    s_axis_tvalid <= 0;
    s_axis_tuser  <= 0;
    
    m_axis_tready <= 1;

    ctrl_coe_wr_addr <= 0;
    ctrl_coe_wr_en   <= 0;
    ctrl_coe_wr_din  <= 0;
    
    // Setup coefficient length, the actual length is this value + 1
    ctrl_coefficient_length = 99; 
    // Setup coefficient set
    ctrl_coefficient_set = 0;

    wait(aresetn == 1);

    // Load coefficient to memory

    for (int i = 0; i < 100; i++) begin
      @(posedge aclk);
      ctrl_coe_wr_addr <= i;
      ctrl_coe_wr_en   <= 1;
      ctrl_coe_wr_din  <= 100 + i;
    end
    @(posedge aclk);
    ctrl_coe_wr_addr <= 0;
    ctrl_coe_wr_en   <= 0;
    ctrl_coe_wr_din  <= 0;

    // Send one data

    @(posedge aclk);
    s_axis_tdata  <= 1000;
    s_axis_tvalid <= 1;
    s_axis_tuser  <= 0;
    @(posedge aclk);
    s_axis_tdata  <= 0;
    s_axis_tvalid <= 0;
    s_axis_tuser  <= 0;

    #1000;
    $finish();
  end

  // DUT
  //====

  fir_macc #(
      .XIN_WIDTH (XIN_WIDTH),
      .COE_WIDTH (COE_WIDTH),
      .YOUT_WIDTH(YOUT_WIDTH),
      .SRA_BITS  (SRA_BITS)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire

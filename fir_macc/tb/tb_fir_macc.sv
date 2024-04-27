// File: tb_fir_macc.sv
// Brief: Testbench for module fir_macc.
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_fir_macc;

  parameter int W_CHANNEL = 3;  // 8 channels
  parameter int W_COE_SETS = 3;  // 8 coefficients sets
  parameter int W_COE_LENGTH = 10;  // 1024 coefficients length

  parameter int XIN_WIDTH = 24;
  parameter int COE_WIDTH = 16;
  parameter int YOUT_WIDTH = 24;
  parameter int SRA_BITS = 15;

  logic                               aclk;
  logic                               aresetn;
  // Data input
  logic [              XIN_WIDTH-1:0] s_axis_tdata;
  logic                               s_axis_tvalid;
  logic                               s_axis_tready;
  logic [              W_CHANNEL-1:0] s_axis_tuser;
  // Data output
  logic [             YOUT_WIDTH-1:0] m_axis_tdata;
  logic                               m_axis_tvalid;
  logic                               m_axis_tready;
  logic [              W_CHANNEL-1:0] m_axis_tuser;
  // Control interface
  logic [W_COE_SETS+W_COE_LENGTH-1:0] ctrl_coe_wr_addr;
  logic                               ctrl_coe_wr_en;
  logic [              COE_WIDTH-1:0] ctrl_coe_wr_din;
  //
  logic [           W_COE_LENGTH-1:0] ctrl_coefficient_length;
  logic [             W_COE_SETS-1:0] ctrl_coefficient_set;
  // Status
  logic                               err_ovf;


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

    ctrl_coefficient_length = 1000; // The actual length is this value + 1
    ctrl_coefficient_set    = 0;

    fork
      begin : p_send_data
        wait (aresetn == 1);
        @(posedge aclk);
    
        for (int i = 0; i < 2000; i++) begin
          if (i == 0) begin
            s_axis_tdata  <= 10000;
          end else begin
            s_axis_tdata  <= 0;
          end
          s_axis_tvalid <= 1;
          s_axis_tuser  <= 0;
          
          // Wait input AXIS ready
          forever begin
            @(posedge aclk);
            if (s_axis_tready) break;
          end
        end

        // Done sending
        s_axis_tdata  <= 0;
        s_axis_tvalid <= 0;
        s_axis_tuser  <= 0;
      end

      begin : p_check_data
        for (int i = 0; i < 2000; i++) begin
          forever begin
            @(posedge aclk);
            if (m_axis_tvalid) break;
          end
          $display("ch[%d]: %d", m_axis_tuser, $signed(m_axis_tdata));
        end
      end

    join
    #1000;
    $finish();
  end

  // DUT
  //====

  fir_macc #(
      .W_CHANNEL   (W_CHANNEL),
      .W_COE_SETS  (W_COE_SETS),
      .W_COE_LENGTH(W_COE_LENGTH),
      //
      .XIN_WIDTH (XIN_WIDTH),
      .COE_WIDTH (COE_WIDTH),
      .YOUT_WIDTH(YOUT_WIDTH),
      .SRA_BITS  (SRA_BITS)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire

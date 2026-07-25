`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_bfp_comp;

  parameter bit BYTE_REVERSE = 1;

  // Signals
  logic        clk;
  logic        rst;

  logic [63:0] s_axis_tdata;
  logic [ 7:0] s_axis_tkeep;
  logic        s_axis_tvalid;
  logic        s_axis_tlast;
  logic [31:0] s_axis_tuser;

  logic [63:0] m_axis_tdata;
  logic [ 7:0] m_axis_tkeep;
  logic        m_axis_tvalid;
  logic        m_axis_tlast;
  logic [31:0] m_axis_tuser;

  logic [ 3:0] ctrl_ud_comp_meth;
  logic [ 3:0] ctrl_ud_iq_width;
  logic [ 3:0] ctrl_fs_offset;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset generation
  initial begin
    rst = 1;
    // Wait 100 ns for global reset
    repeat (10) @(posedge clk);
    rst <= 0;
  end

  // DUT
  bfp_comp #(
      .BYTE_REVERSE(BYTE_REVERSE)
  ) DUT (
      .clk              (clk),
      .rst              (rst),
      .s_axis_tdata     (s_axis_tdata),
      .s_axis_tkeep     (s_axis_tkeep),
      .s_axis_tvalid    (s_axis_tvalid),
      .s_axis_tlast     (s_axis_tlast),
      .s_axis_tuser     (s_axis_tuser),
      .m_axis_tdata     (m_axis_tdata),
      .m_axis_tkeep     (m_axis_tkeep),
      .m_axis_tvalid    (m_axis_tvalid),
      .m_axis_tlast     (m_axis_tlast),
      .m_axis_tuser     (m_axis_tuser),
      .ctrl_ud_comp_meth(ctrl_ud_comp_meth),
      .ctrl_ud_iq_width (ctrl_ud_iq_width),
      .ctrl_fs_offset   (ctrl_fs_offset)
  );

  // Test stimulus
  initial begin
    // Initialize signals
    s_axis_tdata = 0;
    s_axis_tkeep = 0;
    s_axis_tvalid = 0;
    s_axis_tlast = 0;
    s_axis_tuser = 0;

    ctrl_ud_comp_meth = 1;
    ctrl_ud_iq_width = 9;  // BFP9 mode
    ctrl_fs_offset = 4;

    // Wait global reset
    wait (rst == 0);
    repeat (10) @(posedge clk);

    // Test case 1: Send one RB (6 cycles) of data
    @(posedge clk);
    for (int i = 0; i < 6; i++) begin
      for (int j = 0; j < 8; j++) begin
        s_axis_tdata[8*j+7-:8] <= $urandom_range(255);
      end
      s_axis_tkeep  <= 8'hFF;
      s_axis_tvalid <= 1;
      s_axis_tlast  <= (i == 5);  // Assert tlast on last cycle
      s_axis_tuser  <= 32'hA5A5_0001;
      @(posedge clk);
    end
    s_axis_tvalid <= 0;
    s_axis_tlast  <= 0;

    // Wait for processing
    repeat (100) @(posedge clk);

    $finish;
  end

  // Monitor outputs
  initial begin
    forever begin
      @(posedge clk);
      if (m_axis_tvalid) begin
        $display("Output data: %h, last=%b, keep=%h", m_axis_tdata, m_axis_tlast, m_axis_tkeep);
      end
    end
  end

endmodule

`default_nettype wire

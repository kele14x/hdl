`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_bfp_decomp;

  parameter bit BYTE_REVERSE = 1;
  parameter int USER_WIDTH = 91;

  parameter int TEST_UD_COMP_METH = 1;
  parameter int TEST_UD_IQ_WIDTH = 9;
  parameter int TEST_FS_OFFSET = 0;

  logic                  clk;
  logic                  rst;
  //
  logic [          63:0] s_axis_tdata;
  logic [           7:0] s_axis_tkeep;
  logic                  s_axis_tlast;
  logic [USER_WIDTH-1:0] s_axis_tuser;
  logic                  s_axis_tvalid;
  logic                  s_axis_tready;
  //
  logic [         127:0] m_axis_tdata;
  logic                  m_axis_tlast;
  logic [USER_WIDTH-1:0] m_axis_tuser;
  logic                  m_axis_tvalid;
  // CSR
  logic [           3:0] ctrl_ud_comp_meth;
  logic [           3:0] ctrl_ud_iq_width;
  logic [           3:0] ctrl_fs_offset;
  //
  logic                  err_unexpected_tlast;

  // Clock & reset

  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst <= 0;
  end

  // CSR

  initial begin
    $display("*** Simulation started ***");
    ctrl_ud_comp_meth <= TEST_UD_COMP_METH;
    ctrl_ud_iq_width <= TEST_UD_IQ_WIDTH;
    ctrl_fs_offset <= TEST_FS_OFFSET;
  end

  final begin
    $display("*** Simulation finished ***");
  end

  // Input driver
  
  initial begin
    int nPRB;
    int nByte;
    int nWord;
    int ipg;

    s_axis_tdata = 0;
    s_axis_tkeep = 0;
    s_axis_tlast = 0;
    s_axis_tuser = 0;
    s_axis_tvalid = 0;
    wait (!rst);
    @(posedge clk);

    repeat(10) begin
      // Send one packet
      nPRB = $urandom_range(1, 10);
      nByte = nPRB * (1 + 9 * 3);
      nWord = (nByte + 7) / 8;

      for (int i = 0; i < nWord; i++) begin
        s_axis_tdata <= 0;
        s_axis_tkeep <= 0;
        for (int j = 0; (j < 8) && (i * 8 + j < nByte); j++) begin
          s_axis_tdata[j*8+7-:8] <= $urandom_range(255);
          s_axis_tkeep[j] <= 1'b1;
        end
        s_axis_tlast  <= (i == nWord - 1);
        s_axis_tvalid <= 1;
        s_axis_tuser  <= $urandom_range(255);
        @(posedge clk);  
      end
      s_axis_tvalid <= 0;

      // Insert ipg
      ipg = $urandom_range(10);
      repeat(ipg) @(posedge clk);
    end

    #1000;
    $finish;
  end

  // DUT

  bfp_decomp #(
      .BYTE_REVERSE(BYTE_REVERSE),
      .USER_WIDTH  (USER_WIDTH)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire

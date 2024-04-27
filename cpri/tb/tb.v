`timescale 1ns / 1ps

module tb ();

  reg         clk_cpri;
  reg         rst_cpri;

  reg  [14:0] axc0_data_i;
  reg  [14:0] axc0_data_q;
  reg  [14:0] axc1_data_i;
  reg  [14:0] axc1_data_q;
  //
  reg  [ 3:0] l_cntw;
  reg         l_cnty;
  //
  wire [63:0] cpri_frm_data;

  initial begin
    clk_cpri = 0;
    forever begin
      #5 clk_cpri = ~clk_cpri;
    end
  end

  initial begin
    rst_cpri = 1;
    #100 rst_cpri = 0;
  end

  initial begin : p_stimu
    integer i;
    wait (rst_cpri == 0);
    forever begin
      for (i = 0; i < 32; i = i + 1) begin
        @(posedge clk_cpri);
        l_cntw <= i / 2;
        l_cnty <= i % 2;
        axc0_data_i <= $urandom;
        axc0_data_q <= $urandom;
        axc1_data_i <= 0;
        axc1_data_q <= 0;
      end
    end
  end


  cpri_iq_framing DUT (
      .clk_cpri     (clk_cpri),
      .rst_cpri     (rst_cpri),
      //
      .axc0_data_i  (axc0_data_i),
      .axc0_data_q  (axc0_data_q),
      .axc1_data_i  (axc1_data_i),
      .axc1_data_q  (axc1_data_q),
      .l_cntw       (l_cntw),
      .l_cnty       (l_cnty),
      //
      .cpri_frm_data(cpri_frm_data)
  );

endmodule

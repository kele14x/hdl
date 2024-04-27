// File: ft.sv
// Brief: Frequency transfer module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ft #(
    parameter int DATA_WIDTH = 16
) (
    input var                   clk,
    input var                   rst,
    //
    input var  [DATA_WIDTH-1:0] data_i_in,
    input var  [DATA_WIDTH-1:0] data_q_in,
    input var                   data_sync_in,
    //
    output var [DATA_WIDTH-1:0] data_i_out,
    output var [DATA_WIDTH-1:0] data_q_out,
    output var                  data_sync_out,
    // Control signals
    //================
    input var  [          31:0] ctrl_pinc,
    input var  [          31:0] ctrl_poff
);


  // Local parameters

  localparam int NcoDataWidth = 16;
  localparam int NcoPhaseFractionWidth = 20;
  localparam int NcoPhaseEntries = 3072;
  localparam bit [NcoPhaseFractionWidth-1:0] NcoLfsrInitial = 20'hFFFFF;
  localparam bit [NcoPhaseFractionWidth:0] NcoLfsrPolynomial = 21'h100005;


  // Signals

  logic [NcoDataWidth-1:0] nco_i_s;
  logic [NcoDataWidth-1:0] nco_q_s;


  // Main

  nco #(
      .PHASE_FRACTION_WIDTH(NcoPhaseFractionWidth),
      .PHASE_ENTRIES       (NcoPhaseEntries),
      .DATA_WIDTH          (NcoDataWidth),
      .LFSR_INITIAL        (NcoLfsrInitial),
      .LFSR_POLYNOMIAL     (NcoLfsrPolynomial)
  ) i_nco (
      .clk      (clk),
      .rst      (rst),
      //
      .sync     (data_sync_in),
      //
      .cos      (nco_i_s),
      .sin      (nco_q_s),
      //
      .ctrl_poff(ctrl_poff),
      .ctrl_pinc(ctrl_pinc)
  );

  cmult #(
      .A_WIDTH (DATA_WIDTH),
      .B_WIDTH (NcoDataWidth),
      .P_WIDTH (DATA_WIDTH),
      .SRA_BITS(NcoDataWidth - 1)
  ) i_cmult (
      .clk(clk),
      .rst(rst),
      //
      .ar (data_i_in),
      .ai (data_q_in),
      //
      .br (nco_i_s),
      .bi (nco_q_s),
      //
      .pr (data_i_out),
      .pi (data_q_out),
      // Overflow indicator
      .ovf(  /* not used */)
  );

  delay #(
      .DATA_WIDTH(1),
      .DEPTH     (8)
  ) i_delay_sync (
      .clk (clk),
      .cen (1'b1),
      //
      .din (data_sync_in),
      .dout(data_sync_out)
  );

endmodule

`default_nettype wire

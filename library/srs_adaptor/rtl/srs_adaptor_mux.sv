// file: srs_adaptor_mux.sv
// brief: This block accept all SRS message from different Ethernet port, and
//        MUX them into one port. The process is based on the fact that SRS
//        messages will not coming from two or more Ethernet ports at same 
//        time.
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_mux #(
    parameter int NUM_ETH_PORT = 2
) (
    // XORIF
    //======
    input var         clk,
    input var         rst,
    // SRS Filter
    input var  [15:0] srs_flt_rtc_pc_id[NUM_ETH_PORT],
    input var  [ 3:0] srs_flt_cc       [NUM_ETH_PORT],
    input var  [11:0] srs_flt_symbol   [NUM_ETH_PORT],
    input var  [ 3:0] srs_flt_numsymbol[NUM_ETH_PORT],
    input var  [ 7:0] srs_flt_numprbc  [NUM_ETH_PORT],
    input var  [ 9:0] srs_flt_startprbc[NUM_ETH_PORT],
    input var  [11:0] srs_flt_sectionid[NUM_ETH_PORT],
    input var         srs_flt_valid    [NUM_ETH_PORT],
    // SRS MUX
    output var [15:0] srs_mux_rtc_pc_id,
    output var [ 3:0] srs_mux_cc,
    output var [11:0] srs_mux_symbol,
    output var [ 3:0] srs_mux_numsymbol,
    output var [ 7:0] srs_mux_numprbc,
    output var [ 9:0] srs_mux_startprbc,
    output var [11:0] srs_mux_sectionid,
    output var [ 3:0] srs_mux_ethport,
    output var        srs_mux_valid
);

  // 

  always_ff @(posedge clk) begin
    for (int i = 0; i < NUM_ETH_PORT; i++) begin
      if (srs_flt_valid[i]) begin
        srs_mux_rtc_pc_id <= srs_flt_rtc_pc_id[i];
        srs_mux_cc        <= srs_flt_cc[i];
        srs_mux_symbol    <= srs_flt_symbol[i];
        srs_mux_numsymbol <= srs_flt_numsymbol[i];
        srs_mux_numprbc   <= srs_flt_numprbc[i];
        srs_mux_startprbc <= srs_flt_startprbc[i];
        srs_mux_sectionid <= srs_flt_sectionid[i];
        srs_mux_ethport   <= i;
        break;
      end
    end
  end

  always_ff @(posedge clk) begin
    srs_mux_valid <= 1'b0;
    for (int i = 0; i < NUM_ETH_PORT; i++) begin
      if (srs_flt_valid[i]) begin
        srs_mux_valid <= 1'b1;
        break;
      end
    end
  end

endmodule

`default_nettype wire

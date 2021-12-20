// file: srs_adaptor_mux.sv
// brief: This block accept all SRS message from different Ethernet port, and
//        MUX them into one port. The process is based on the fact that SRS
//        messages will not coming from two or more Ethernet ports at same 
//        time.
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_mux #(
    parameter int NUM_CC = 2,
    parameter int NUM_ETH_PORT = 2
) (
    // XORIF
    //======
    input var         clk,
    input var         rst,
    // SRS Filter
    //===========
    input var  [15:0] srs_flt_rtc_pc_id  [NUM_ETH_PORT],
    //
    input var  [ 7:0] srs_flt_frameid    [NUM_ETH_PORT],
    input var  [ 3:0] srs_flt_subframeid [NUM_ETH_PORT],
    input var  [ 5:0] srs_flt_slotid     [NUM_ETH_PORT],
    input var  [ 5:0] srs_flt_symbolid   [NUM_ETH_PORT],
    //
    input var  [ 3:0] srs_flt_numsymbol  [NUM_ETH_PORT],
    input var  [ 7:0] srs_flt_numprbc    [NUM_ETH_PORT],
    input var  [ 9:0] srs_flt_startprbc  [NUM_ETH_PORT],
    input var  [11:0] srs_flt_sectionid  [NUM_ETH_PORT],
    //
    input var         srs_flt_valid      [NUM_ETH_PORT],
    // SRS MUX
    //========
    output var [ 2:0] srs_mux_cc,
    output var [ 5:0] srs_mux_layer,
    output var [11:0] srs_mux_symbol,
    //
    output var [15:0] srs_mux_rtc_pc_id,
    //
    output var [ 7:0] srs_mux_frameid,
    output var [ 3:0] srs_mux_subframeid,
    output var [ 5:0] srs_mux_slotid,
    output var [ 5:0] srs_mux_symbolid,
    //
    output var [ 3:0] srs_mux_numsymbol,
    output var [ 7:0] srs_mux_numprbc,
    output var [ 9:0] srs_mux_startprbc,
    output var [11:0] srs_mux_sectionid,
    //
    output var [ 2:0] srs_mux_ethport,
    //
    output var        srs_mux_valid,
    // Control Port
    //=============
    // Enable SRS function
    input var         ctrl_srs_en,
    // M-Plane SRS Configuration
    // Use generated SRS message instead from DU
    input var         ctrl_srs_gen_en,
    // SRS message generator
    input var  [15:0] ctrl_srs_rtc_pc_id,
    //
    input var  [ 7:0] ctrl_srs_frameid,
    input var  [ 3:0] ctrl_srs_subframeid,
    input var  [ 5:0] ctrl_srs_slotid,
    input var  [ 5:0] ctrl_srs_symbolid,
    //
    input var  [ 3:0] ctrl_srs_numsymbol,
    input var  [ 7:0] ctrl_srs_numprbc,
    input var  [ 9:0] ctrl_srs_startprbc,
    input var  [11:0] ctrl_srs_sectionid,
    //
    input var  [ 2:0] ctrl_srs_ethport,
    //
    input var         ctrl_srs_valid,
    //
    input var  [ 1:0] ctrl_numerology    [      NUM_CC]
);


  logic [11:0] srs_flt_symbol  [NUM_ETH_PORT];
  logic [11:0] ctrl_srs_symbol;

  function [11:0] get_symbol(input [15:0] rtc_pc_id, input [3:0] subframeid, input [5:0] slotid,
                             input [5:0] symbolid, input [1:0] ctrl_numerology[NUM_CC]);
    begin
      logic [2:0] cc;
      logic [1:0] mu;

      // NR Symbol number calculation
      cc = rtc_pc_id[10:8];
      // 0 : 30 kHz SCS, 1: 15 khz SCS, others: 60 kHz SCS
      mu = ctrl_numerology[cc] == 0 ? 1 : ctrl_numerology[cc] == 1 ? 0 : 2;
      get_symbol = ((subframeid * (2 ** mu) + slotid) * 14 + symbolid);
    end
  endfunction


  generate
    for (genvar i = 0; i < NUM_ETH_PORT; i++) begin
      assign srs_flt_symbol[i] = get_symbol(
          srs_flt_rtc_pc_id[i],
          srs_flt_subframeid[i],
          srs_flt_slotid[i],
          srs_flt_symbolid[i],
          ctrl_numerology
      );
    end
  endgenerate

  assign ctrl_srs_symbol = get_symbol(
      ctrl_srs_rtc_pc_id, ctrl_srs_subframeid, ctrl_srs_slotid, ctrl_srs_symbolid, ctrl_numerology
  );


  // MUX
  //====
  // NUM_ETH_PORT to 1 MUX

  always_ff @(posedge clk) begin
    if (ctrl_srs_en && ~ctrl_srs_gen_en) begin

      // SRS information from C-Plane
      for (int i = 0; i < NUM_ETH_PORT; i++) begin
        if (srs_flt_valid[i]) begin
          srs_mux_cc         <= srs_flt_rtc_pc_id[i][10:8];
          srs_mux_layer      <= srs_flt_rtc_pc_id[i][5:0];
          srs_mux_symbol     <= srs_flt_symbol[i];
          //
          srs_mux_rtc_pc_id  <= srs_flt_rtc_pc_id[i];
          //
          srs_mux_frameid    <= srs_flt_frameid[i];
          srs_mux_subframeid <= srs_flt_subframeid[i];
          srs_mux_slotid     <= srs_flt_slotid[i];
          srs_mux_symbolid   <= srs_flt_symbolid[i];
          //
          srs_mux_numsymbol  <= srs_flt_numsymbol[i];
          srs_mux_numprbc    <= srs_flt_numprbc[i];
          srs_mux_startprbc  <= srs_flt_startprbc[i];
          srs_mux_sectionid  <= srs_flt_sectionid[i];
          //
          srs_mux_ethport    <= i;
          break;
        end
      end

    end else if (ctrl_srs_en && ctrl_srs_gen_en) begin

      // SRS information from M-Plane
      srs_mux_cc         <= ctrl_srs_rtc_pc_id[10:8];
      srs_mux_layer      <= ctrl_srs_rtc_pc_id[5:0];
      srs_mux_symbol     <= ctrl_srs_symbol;
      //
      srs_mux_rtc_pc_id  <= ctrl_srs_rtc_pc_id;
      //
      srs_mux_frameid    <= ctrl_srs_frameid;
      srs_mux_subframeid <= ctrl_srs_subframeid;
      srs_mux_slotid     <= ctrl_srs_slotid;
      srs_mux_symbolid   <= ctrl_srs_symbolid;
      //
      srs_mux_numsymbol  <= ctrl_srs_numsymbol;
      srs_mux_numprbc    <= ctrl_srs_numprbc;
      srs_mux_startprbc  <= ctrl_srs_startprbc;
      srs_mux_sectionid  <= ctrl_srs_sectionid;
      //
      srs_mux_ethport    <= ctrl_srs_ethport;

    end else begin

      // SRS disabled
      srs_mux_cc         <= '0;
      srs_mux_layer      <= '0;
      srs_mux_symbol     <= '0;
      //
      srs_mux_rtc_pc_id  <= '0;
      //
      srs_mux_frameid    <= '0;
      srs_mux_subframeid <= '0;
      srs_mux_slotid     <= '0;
      srs_mux_symbolid   <= '0;
      //
      srs_mux_numsymbol  <= '0;
      srs_mux_numprbc    <= '0;
      srs_mux_startprbc  <= '0;
      srs_mux_sectionid  <= '0;
      //
      srs_mux_ethport    <= '0;

    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_srs_en && ~ctrl_srs_gen_en) begin

      // SRS information from C-Plane
      srs_mux_valid <= 1'b0;
      for (int i = 0; i < NUM_ETH_PORT; i++) begin
        if (srs_flt_valid[i]) begin
          srs_mux_valid <= 1'b1;
          break;
        end
      end

    end else if (ctrl_srs_en && ctrl_srs_gen_en) begin

      // SRS information from M-Plane
      srs_mux_valid <= ctrl_srs_valid;

    end else begin

      // SRS disabled
      srs_mux_valid <= 1'b0;

    end
  end

endmodule

`default_nettype wire

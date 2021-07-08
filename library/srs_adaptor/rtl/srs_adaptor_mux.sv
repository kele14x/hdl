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
    output var [15:0] srs_mux_rtc_pc_id,
    output var [ 2:0] srs_mux_cc,
    //
    output var [ 7:0] srs_mux_frameid,
    output var [ 3:0] srs_mux_subframeid,
    output var [ 5:0] srs_mux_slotid,
    output var [ 5:0] srs_mux_symbolid,
    output var [11:0] srs_mux_symbol,
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
    input var  [15:0] ctrl_srs_rtc_pc_id,
    //
    input var  [ 7:0] ctrl_srs_frameid,
    input var  [ 3:0] ctrl_srs_subframeid,
    input var  [ 5:0] ctrl_srs_slotid,
    input var  [ 5:0] ctrl_srs_symbolid,
    //
    input var  [11:0] ctrl_srs_numsymbol,
    input var  [ 7:0] ctrl_srs_numprbc,
    input var  [ 9:0] ctrl_srs_startprbc,
    input var  [11:0] ctrl_srs_sectionid,
    //
    input var  [ 3:0] ctrl_srs_ethport,
    //
    input var         ctrl_srs_valid,
    //
    input var  [ 1:0] ctrl_numerology    [      NUM_CC]
);


  // Temporary store one message
  logic [15:0] srs_temp_rtc_pc_id;
  //
  logic [ 7:0] srs_temp_frameid;
  logic [ 3:0] srs_temp_subframeid;
  logic [ 5:0] srs_temp_slotid;
  logic [ 5:0] srs_temp_symbolid;
  //
  logic [ 3:0] srs_temp_numsymbol;
  logic [ 7:0] srs_temp_numprbc;
  logic [ 9:0] srs_temp_startprbc;
  logic [11:0] srs_temp_sectionid;
  //
  logic [ 2:0] srs_temp_ethport;
  //
  logic        srs_temp_valid;

  // Previous message
  logic [15:0] srs_prev_rtc_pc_id;
  //
  logic [ 7:0] srs_prev_frameid;
  logic [ 3:0] srs_prev_subframeid;
  logic [ 5:0] srs_prev_slotid;
  logic [ 5:0] srs_prev_symbolid;
  //
  logic [ 3:0] srs_prev_numsymbol;
  logic [ 7:0] srs_prev_numprbc;
  logic [ 9:0] srs_prev_startprbc;
  logic [11:0] srs_prev_sectionid;
  //
  logic [ 2:0] srs_prev_ethport;
  //
  logic        srs_prev_valid;

  logic        new_message;

  // For calculation symbol
  logic [15:0] srs_calc_rtc_pc_id;
  //
  logic [ 7:0] srs_calc_frameid;
  logic [ 3:0] srs_calc_subframeid;
  logic [ 5:0] srs_calc_slotid;
  logic [ 5:0] srs_calc_symbolid;
  //
  logic [ 3:0] srs_calc_numsymbol;
  logic [ 7:0] srs_calc_numprbc;
  logic [ 9:0] srs_calc_startprbc;
  logic [11:0] srs_calc_sectionid;
  //
  logic [ 2:0] srs_calc_ethport;
  //
  logic        srs_calc_valid;

  // MUX
  //====
  // NUM_ETH_PORT to 1 MUX

  always_ff @(posedge clk) begin
    for (int i = 0; i < NUM_ETH_PORT; i++) begin
      if (srs_flt_valid[i]) begin
        srs_temp_rtc_pc_id <= srs_flt_rtc_pc_id[i];
        //
        srs_temp_frameid   <= srs_flt_frameid[i];
        srs_temp_subframeid<= srs_flt_subframeid[i];
        srs_temp_slotid    <= srs_flt_slotid[i];
        srs_temp_symbolid  <= srs_flt_symbolid[i];
        //
        srs_temp_numsymbol <= srs_flt_numsymbol[i];
        srs_temp_numprbc   <= srs_flt_numprbc[i];
        srs_temp_startprbc <= srs_flt_startprbc[i];
        srs_temp_sectionid <= srs_flt_sectionid[i];
        //
        srs_temp_ethport   <= i;
        break;
      end
    end
  end

  always_ff @(posedge clk) begin
    srs_temp_valid <= 1'b0;
    for (int i = 0; i < NUM_ETH_PORT; i++) begin
      if (srs_flt_valid[i]) begin
        srs_temp_valid <= 1'b1;
        break;
      end
    end
  end


  // Store previous message
  //=======================
  // Be smart not output similar message

  always_ff @(posedge clk) begin
    if (rst) begin
      srs_prev_valid <= 1'b0;
    end else if (srs_temp_valid) begin
      srs_prev_valid <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (srs_temp_valid) begin
      srs_prev_rtc_pc_id  <= srs_temp_rtc_pc_id;
      //
      srs_prev_frameid    <= srs_temp_frameid;
      srs_prev_subframeid <= srs_temp_subframeid;
      srs_prev_slotid     <= srs_temp_slotid;
      srs_prev_symbolid   <= srs_temp_symbolid;
      //
      srs_prev_numsymbol  <= srs_temp_numsymbol;
      srs_prev_numprbc    <= srs_temp_numprbc;
      srs_prev_startprbc  <= srs_temp_startprbc;
      srs_prev_sectionid  <= srs_temp_sectionid;
      //
      srs_prev_ethport    <= srs_temp_ethport;
    end
  end

  assign new_message = (
    srs_temp_rtc_pc_id[15:9] != srs_prev_rtc_pc_id[15:9] ||
    srs_temp_frameid         != srs_prev_frameid ||
    srs_temp_subframeid      != srs_prev_subframeid ||
    srs_temp_slotid          != srs_prev_slotid ||
    srs_temp_symbolid        != srs_prev_symbolid ||
    srs_temp_numsymbol       != srs_prev_numsymbol ||
    srs_temp_numprbc         != srs_prev_numprbc ||
    srs_temp_startprbc       != srs_prev_startprbc ||
    srs_temp_sectionid       != srs_prev_sectionid ||
    srs_prev_valid           != 1'b1
  );


  // Update output
  //==============
  // Message from control port will always be outptu
  // message from filter will be compared with previous one, and only write 
  // new one

  always_ff @(posedge clk) begin
    if (ctrl_srs_valid) begin
      srs_calc_rtc_pc_id  <= ctrl_srs_rtc_pc_id;
      //
      srs_calc_frameid    <= ctrl_srs_frameid;
      srs_calc_subframeid <= ctrl_srs_subframeid;
      srs_calc_slotid     <= ctrl_srs_slotid;
      srs_calc_symbolid   <= ctrl_srs_symbolid;
      //
      srs_calc_numsymbol  <= ctrl_srs_numsymbol;
      srs_calc_numprbc    <= ctrl_srs_numprbc;
      srs_calc_startprbc  <= ctrl_srs_startprbc;
      srs_calc_sectionid  <= ctrl_srs_sectionid;
      //
      srs_calc_ethport    <= ctrl_srs_ethport;
    end else if (srs_temp_valid && new_message) begin
      srs_calc_rtc_pc_id  <= srs_temp_rtc_pc_id;
      //
      srs_calc_frameid    <= srs_temp_frameid;
      srs_calc_subframeid <= srs_temp_subframeid;
      srs_calc_slotid     <= srs_temp_slotid;
      srs_calc_symbolid   <= srs_temp_symbolid;
      //
      srs_calc_numsymbol  <= srs_temp_numsymbol;
      srs_calc_numprbc    <= srs_temp_numprbc;
      srs_calc_startprbc  <= srs_temp_startprbc;
      srs_calc_sectionid  <= srs_temp_sectionid;
      //
      srs_calc_ethport    <= srs_temp_ethport;
    end
  end

  always_ff @(posedge clk) begin
    srs_calc_valid <= 1'b0;
    if (ctrl_srs_valid) begin
      srs_calc_valid <= 1'b1;
    end else if (srs_temp_valid && new_message) begin
      srs_calc_valid <= 1'b1;
    end
  end


  logic [2:0] cc;
  logic [1:0] mu;

  assign cc = srs_calc_rtc_pc_id[10:8];
  // 0 : 30 kHz SCS, 1: 15 khz SCS, others: 60 kHz SCS
  assign mu = ctrl_numerology[cc] == 0 ? 1 : ctrl_numerology[cc] == 1 ? 0 : 2;

  always_ff @(posedge clk) begin
    if (srs_calc_valid) begin
      srs_mux_rtc_pc_id <= srs_calc_rtc_pc_id;
      srs_mux_cc <= cc;
      //
      srs_mux_frameid <= srs_calc_frameid;
      srs_mux_subframeid <= srs_calc_subframeid;
      srs_mux_slotid <= srs_calc_slotid;
      srs_mux_symbolid <= srs_calc_symbolid;
      srs_mux_symbol     <= ((srs_calc_subframeid * (2 ** mu) + srs_calc_slotid) * 14 + srs_calc_symbolid);
      //
      srs_mux_numsymbol <= srs_calc_numsymbol;
      srs_mux_numprbc <= srs_calc_numprbc;
      srs_mux_startprbc <= srs_calc_startprbc;
      srs_mux_sectionid <= srs_calc_sectionid;
      //
      srs_mux_ethport <= srs_calc_ethport;
    end
  end

  always_ff @(posedge clk) begin
    srs_mux_valid <= srs_calc_valid;
  end

endmodule

`default_nettype wire

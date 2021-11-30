// file: srs_adaptor_gen.sv
// brief: This block generate SRS message for testing purpose.
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_gen #(
    parameter int NUM_CC = 2
) (
    // XORIF
    //======
    input var         clk,
    input var         rst,
    // UL Timing
    input var  [11:0] s_ul_sym_num       [NUM_CC],
    input var         s_ul_update        [NUM_CC],
    // SRS Filter
    //===========
    input var  [15:0] srs_mux_rtc_pc_id,
    input var  [ 2:0] srs_mux_cc,
    //
    input var  [ 7:0] srs_mux_frameid,
    input var  [ 3:0] srs_mux_subframeid,
    input var  [ 5:0] srs_mux_slotid,
    input var  [ 5:0] srs_mux_symbolid,
    input var  [11:0] srs_mux_symbol,
    //
    input var  [ 3:0] srs_mux_numsymbol,
    input var  [ 7:0] srs_mux_numprbc,
    input var  [ 9:0] srs_mux_startprbc,
    input var  [11:0] srs_mux_sectionid,
    //
    input var  [ 2:0] srs_mux_ethport,
    //
    input var         srs_mux_valid,
    // SRS Generated
    //==============
    output var [15:0] srs_gen_rtc_pc_id,
    output var [ 2:0] srs_gen_cc,
    //
    output var [ 7:0] srs_gen_frameid,
    output var [ 3:0] srs_gen_subframeid,
    output var [ 5:0] srs_gen_slotid,
    output var [ 5:0] srs_gen_symbolid,
    output var [11:0] srs_gen_symbol,
    //
    output var [ 3:0] srs_gen_numsymbol,
    output var [ 7:0] srs_gen_numprbc,
    output var [ 9:0] srs_gen_startprbc,
    output var [11:0] srs_gen_sectionid,
    //
    output var [ 2:0] srs_gen_ethport,
    //
    output var        srs_gen_valid,
    // Control Port
    //=============
    input var         ctrl_srs_en,
    //
    input var         ctrl_srs_gen_en,
    //
    input var  [15:0] ctrl_srs_rtc_pc_id,
    input var  [ 2:0] ctrl_srs_cc,
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
    input var  [ 1:0] ctrl_numerology    [NUM_CC]
);


  logic ctrl_srs_valid_d, ctrl_srs_valid_dd, ctrl_srs_valid_rising;

  // Configuration store for each CC

  logic [15:0] srs_gen_rtc_pc_id_store [NUM_CC];
  //
  logic [ 7:0] srs_gen_frameid_store   [NUM_CC];
  logic [ 3:0] srs_gen_subframeid_store[NUM_CC];
  logic [ 5:0] srs_gen_slotid_store    [NUM_CC];
  logic [ 5:0] srs_gen_symbolid_store  [NUM_CC];
  logic [11:0] srs_gen_symbol_store    [NUM_CC];
  //
  logic [ 3:0] srs_gen_numsymbol_store [NUM_CC];
  logic [ 7:0] srs_gen_numprbc_store   [NUM_CC];
  logic [ 9:0] srs_gen_startprbc_store [NUM_CC];
  logic [11:0] srs_gen_sectionid_store [NUM_CC];
  //
  logic [ 2:0] srs_gen_ethport_store   [NUM_CC];
  //
  logic [ 2:0] srs_gen_valid_store     [NUM_CC];

  logic [11:0] srs_gen_symbol_ahead    [NUM_CC];

  logic [11:0] ctrl_srs_symbol_s;
  logic [11:0] ctrl_srs_symbol_ahead_s;

  // Generated SRS message

  logic [15:0] srs_gen_rtc_pc_id_r;
  logic [ 2:0] srs_gen_cc_r;
  //
  logic [ 7:0] srs_gen_frameid_r;
  logic [ 3:0] srs_gen_subframeid_r;
  logic [ 5:0] srs_gen_slotid_r;
  logic [ 5:0] srs_gen_symbolid_r;
  logic [11:0] srs_gen_symbol_r;
  //
  logic [ 3:0] srs_gen_numsymbol_r;
  logic [ 7:0] srs_gen_numprbc_r;
  logic [ 9:0] srs_gen_startprbc_r;
  logic [11:0] srs_gen_sectionid_r;
  //
  logic [ 2:0] srs_gen_ethport_r;
  //
  logic        srs_gen_valid_r;


  // Functions

  function [11:0] calc_symbol([1:0] numerology, [3:0] subframeid, [5:0] slotid, [5:0] symbolid);
    logic [1:0] mu;
    begin
      mu = numerology == 0 ? 1 : numerology == 1 ? 0 : 2;
      calc_symbol = ((subframeid * (2 ** mu) + slotid) * 14 + symbolid);
    end
  endfunction

  function [11:0] calc_symbol_ahead([1:0] numerology, [3:0] subframeid, [5:0] slotid,
                                    [5:0] symbolid);
    logic [11:0] symbol;
    logic [11:0] max_symbol;
    begin
      symbol = calc_symbol(numerology, subframeid, slotid, symbolid);
      max_symbol = numerology == 0 ? 280 : numerology == 1 ? 140 : 560;
      calc_symbol_ahead = symbol < 3 ? max_symbol + symbol - 3 : symbol - 3;
    end
  endfunction


  // Stores SRS configuration for each CC

  assign ctrl_srs_symbol_s = calc_symbol(
      ctrl_numerology[ctrl_srs_cc], ctrl_srs_subframeid, ctrl_srs_slotid, ctrl_srs_symbolid
  );

  // Put out generated SRS message 3 symbol ahead it's specified symbol number
  assign ctrl_srs_symbol_ahead_s = calc_symbol_ahead(
      ctrl_numerology[ctrl_srs_cc], ctrl_srs_subframeid, ctrl_srs_slotid, ctrl_srs_symbolid
  );

  // Load ctrl_srs_* ports on ctrl_srs_valid rising edge (CDC)
  always_ff @(posedge clk) begin
    ctrl_srs_valid_d      <= ctrl_srs_valid;
    ctrl_srs_valid_dd     <= ctrl_srs_valid_d;
    ctrl_srs_valid_rising <= ctrl_srs_valid_d && ~ctrl_srs_valid_dd;
  end

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cc_store

      always_ff @(posedge clk) begin
        if (!ctrl_srs_gen_en || rst) begin
          srs_gen_valid_store[cc] <= '0;
        end else if (ctrl_srs_valid_rising && ctrl_srs_cc == cc) begin
          srs_gen_valid_store[cc] <= 1'b1;
        end
      end

      always_ff @(posedge clk) begin
        if (ctrl_srs_valid_rising && ctrl_srs_cc == cc) begin
          srs_gen_rtc_pc_id_store[cc]  <= ctrl_srs_rtc_pc_id;
          //
          srs_gen_frameid_store[cc]    <= ctrl_srs_frameid;
          srs_gen_subframeid_store[cc] <= ctrl_srs_subframeid;
          srs_gen_slotid_store[cc]     <= ctrl_srs_slotid;
          srs_gen_symbolid_store[cc]   <= ctrl_srs_symbolid;
          srs_gen_symbol_store[cc]     <= ctrl_srs_symbol_s;
          //
          srs_gen_numsymbol_store[cc]  <= ctrl_srs_numsymbol;
          srs_gen_numprbc_store[cc]    <= ctrl_srs_numprbc;
          srs_gen_startprbc_store[cc]  <= ctrl_srs_startprbc;
          srs_gen_sectionid_store[cc]  <= ctrl_srs_sectionid;
          //
          srs_gen_ethport_store[cc]    <= ctrl_srs_ethport;
          //
          srs_gen_symbol_ahead[cc]     <= ctrl_srs_symbol_ahead_s;
        end
      end

    end
  endgenerate


  // Generate SRS message when symbol time is approaching

  logic       cc_req[NUM_CC];
  logic [5:0] cc_cid[NUM_CC];

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cc_req

      // If symbol time is approaching for this CC, rise cc_req
      // This takes care if multi-cc send request together
      always_ff @(posedge clk) begin
        if (rst) begin
          cc_req[cc] <= '0;
        end else if (s_ul_sym_num[cc] == srs_gen_symbol_ahead[cc] && s_ul_update[cc] && srs_gen_valid_store[cc]) begin
          cc_req[cc] <= 1'b1;
        end else if (&cc_cid[cc]) begin
          cc_req[cc] <= 1'b0;
        end
      end

      // Arbiter, cc #0 has higher priority, then #1...
      always_ff @(posedge clk) begin
        if (rst) begin
          cc_cid[cc] <= '0;
        end else if (cc_req[cc]) begin
          for (int i = 0; i <= cc; i++) begin
            if (cc_req[i]) begin
              if (i == cc) begin
                cc_cid[cc] <= cc_cid[cc] + 1;
              end
              break;
            end
          end
        end
      end

    end
  endgenerate

  // This is also arbiter, cc #0 goes first
  always_ff @(posedge clk) begin
    for (int cc = 0; cc < NUM_CC; cc++) begin
      if (cc_req[cc]) begin
        srs_gen_rtc_pc_id_r  <= {srs_gen_rtc_pc_id_store[cc][15:6], cc_cid[cc]};
        srs_gen_cc_r         <= cc;
        //
        srs_gen_frameid_r    <= srs_gen_frameid_store[cc];
        srs_gen_subframeid_r <= srs_gen_subframeid_store[cc];
        srs_gen_slotid_r     <= srs_gen_slotid_store[cc];
        srs_gen_symbolid_r   <= srs_gen_symbolid_store[cc];
        srs_gen_symbol_r     <= srs_gen_symbol_store[cc];
        //
        srs_gen_numsymbol_r  <= srs_gen_numsymbol_store[cc];
        srs_gen_numprbc_r    <= srs_gen_numprbc_store[cc];
        srs_gen_startprbc_r  <= srs_gen_startprbc_store[cc];
        srs_gen_sectionid_r  <= srs_gen_sectionid_store[cc];
        //
        srs_gen_ethport_r    <= srs_gen_ethport_store[cc];
        break;
      end
    end
  end

  // If any cc requested to send out message, set valid
  always_ff @(posedge clk) begin
    for (int cc = 0; cc < NUM_CC; cc++) begin
      if (cc_req[cc]) begin
        srs_gen_valid_r <= 1'b1;
        break;
      end else begin
        srs_gen_valid_r <= 1'b0;
      end
    end
  end


  // Choose which SRS message to output

  always_ff @(posedge clk) begin
    if (ctrl_srs_gen_en) begin
      // Choose generated SRS message
      srs_gen_rtc_pc_id  <= srs_gen_rtc_pc_id_r;
      srs_gen_cc         <= srs_gen_cc_r;
      //
      srs_gen_frameid    <= srs_gen_frameid_r;
      srs_gen_subframeid <= srs_gen_subframeid_r;
      srs_gen_slotid     <= srs_gen_slotid_r;
      srs_gen_symbolid   <= srs_gen_symbolid_r;
      srs_gen_symbol     <= srs_gen_symbol_r;
      //
      srs_gen_numsymbol  <= srs_gen_numsymbol_r;
      srs_gen_numprbc    <= srs_gen_numprbc_r;
      srs_gen_startprbc  <= srs_gen_startprbc_r;
      srs_gen_sectionid  <= srs_gen_sectionid_r;
      //
      srs_gen_ethport    <= srs_gen_ethport_r;
    end else begin
      // Choose mutex output
      srs_gen_rtc_pc_id  <= srs_mux_rtc_pc_id;
      srs_gen_cc         <= srs_mux_cc;
      //
      srs_gen_frameid    <= srs_mux_frameid;
      srs_gen_subframeid <= srs_mux_subframeid;
      srs_gen_slotid     <= srs_mux_slotid;
      srs_gen_symbolid   <= srs_mux_symbolid;
      srs_gen_symbol     <= srs_mux_symbol;
      //
      srs_gen_numsymbol  <= srs_mux_numsymbol;
      srs_gen_numprbc    <= srs_mux_numprbc;
      srs_gen_startprbc  <= srs_mux_startprbc;
      srs_gen_sectionid  <= srs_mux_sectionid;
      //
      srs_gen_ethport    <= srs_mux_ethport;
    end
  end

  always_ff @(posedge clk) begin
    if (!ctrl_srs_en) begin
      srs_gen_valid      <= '0;
    end else if (ctrl_srs_gen_en) begin
      srs_gen_valid      <= srs_gen_valid_r;
    end else begin
      srs_gen_valid      <= srs_mux_valid;
    end
  end

endmodule

`default_nettype wire

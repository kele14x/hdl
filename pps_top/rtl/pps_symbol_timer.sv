`timescale 1 ns / 1 ps
//
`default_nettype none

module pps_symbol_timer #(
    parameter int FREQUENCY = 1  // 1 for 122.88, 2 for 245.76, 4 for 491.52
) (
    // System
    //-------
    input var         clk,
    input var         rst,
    //
    input var         sync_in,
    //
    input var  [ 1:0] sample_inc,
    input var  [32:0] sample_frac,
    // O-RAN symbol timer I/F
    output var        start_of_frame,
    output var        start_of_symbol,
    output var [32:0] start_of_symbol_frac
);

  localparam logic [14:0] SampleCntMax0 = (4096 + 352) * FREQUENCY - 1;
  localparam logic [14:0] SampleCntMax1 = (4096 + 288) * FREQUENCY - 1;
  localparam logic [14:0] SampleCntMax2 = (4096 + 352) * FREQUENCY - 2;
  localparam logic [14:0] SampleCntMax3 = (4096 + 288) * FREQUENCY - 2;
  localparam logic [3:0] SymbolCntMax = 13;
  localparam logic [4:0] SubframeSlotCntMax = 19;


  logic [14:0] current_sample_max01;
  logic [14:0] current_sample_max23;

  logic [14:0] current_sample;  // 0 ~ (4096+352)*FREQUENCY-1
  logic [ 3:0] current_symbol;  // 0 ~ 13, symbol
  logic [ 4:0] current_subframe_slot;  // 0 ~ 19, slot + subframe
  logic [ 7:0] current_frame;  // 0 ~ 255, frame

  logic        sample_wrap_r1;
  logic        sample_wrap_r2;
  logic        sample_wrap;
  logic        symbol_wrap;
  logic        subframe_slot_wrap;


  // Sample counter in a symbol
  //---------------------------
  // First symbol in every 14 symbols (1 slot) has 352 samples CP length.
  // Other symbols has 288 samples CP length.
  // So it's 4447/4448 for first symbol in slot or 4383/4384 for left symbols.
  // We need 2 numbers as guard since the sample_cnt may jump over 4447 (4383)
  // if FCW is larger than 1.
  // TODO: this is only for SCS = 30kHz & mu = 1

  assign current_sample_max01 = current_symbol == 0 ? SampleCntMax0 : SampleCntMax1;
  assign current_sample_max23 = current_symbol == 0 ? SampleCntMax2 : SampleCntMax3;

  // Wrap to 0
  assign sample_wrap_r1 = ((sample_inc == 2'b01) && (current_sample == current_sample_max01)) ||
    ((sample_inc == 2'b11) && (current_sample == current_sample_max23));
  // Wrap to 1
  assign sample_wrap_r2 = (sample_inc == 2'b11) && (current_sample == current_sample_max01);
  // Any way
  assign sample_wrap = sample_wrap_r1 || sample_wrap_r2;

  always_ff @(posedge clk) begin
    if (rst) begin
      current_sample <= '0;
    end else if (sync_in && sample_inc[1]) begin
      current_sample <= 15'd1;
    end else if (sync_in) begin
      current_sample <= '0;
    end else if (sample_wrap_r1) begin
      current_sample <= '0;
    end else if (sample_wrap_r2) begin
      current_sample <= 15'd1;
    end else if (sample_inc == 2'b01) begin
      current_sample <= current_sample + 1;
    end else if (sample_inc == 2'b11) begin
      current_sample <= current_sample + 2;
    end
  end

  // Symbol counter
  //---------------

  always_ff @(posedge clk) begin
    if (rst || sync_in) begin
      current_symbol <= '0;
    end else if (sample_wrap && symbol_wrap) begin
      current_symbol <= '0;
    end else if (sample_wrap) begin
      current_symbol <= current_symbol + 1;
    end
  end

  assign symbol_wrap = current_symbol == SymbolCntMax;


  // Slot + Sub-frame counter
  //-------------------------

  always_ff @(posedge clk) begin
    if (rst || sync_in) begin
      current_subframe_slot <= '0;
    end else if (sample_wrap && symbol_wrap && subframe_slot_wrap) begin
      current_subframe_slot <= '0;
    end else if (sample_wrap && symbol_wrap) begin
      current_subframe_slot <= current_subframe_slot + 1;
    end
  end

  assign subframe_slot_wrap = current_subframe_slot == SubframeSlotCntMax;


  // Frame counter
  //--------------

  // Be ware that frame counter does not sync with `sync_in` (1PPS), since that
  // the frame counter wraps at 255
  // TODO: sync with second counter
  always_ff @(posedge clk) begin
    if (rst) begin
      current_frame <= '0;
    end else if (sample_wrap && symbol_wrap && subframe_slot_wrap) begin
      current_frame <= current_frame + 1;
    end
  end


  // Output
  //-------

  always_ff @(posedge clk) begin
    start_of_frame <= sync_in || (sample_wrap && symbol_wrap && subframe_slot_wrap);
  end

  always_ff @(posedge clk) begin
    start_of_symbol <= sync_in || sample_wrap;
  end

  always_ff @(posedge clk) begin
    if (sync_in || sample_wrap) begin
      start_of_symbol_frac <= sample_frac;
    end
  end

endmodule

`default_nettype wire

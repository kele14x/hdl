`timescale 1 ns / 1 ps
//
`default_nettype none

module symbol_timer #(
    parameter int MODE      = 0,  // 0 for DL, 1 for UL
    parameter int FREQUENCY = 4   // 1 for 122.88, 2 for 245.76, 4 for 491.52
) (
    input var         clk,
    input var         rst,
    //
    input var         sync,                   // required 10ms strobe
    input var  [ 7:0] sync_frame,
    //
    output var        start_of_frame,
    output var        start_of_symbol,
    //
    output var [14:0] current_sample,         // 0 ~ (4096+352)*FREQUENCY-1
    output var [ 3:0] current_symbol,         // 0 ~ 13
    output var [ 4:0] current_subframe_slot,  // 0 ~ 19, slot + subframe
    output var [ 7:0] current_frame,
    //
    input var  [22:0] shift
);

  // From posedge of sync to output `start_of_frame`
  localparam int Latency = 4;

  logic        sync_d1;
  logic        sync_d2;
  logic        sync_posedge;

  // 0 ~ 1228800*FREQUENCY-1
  logic [22:0] frame_cnt;
  logic [ 7:0] frame_id;
  logic        frame_sof;

  logic [14:0] current_sample_max;
  logic [ 3:0] current_symbol_max = 13;
  logic [ 4:0] current_subframe_slot_max = 19;


  always_ff @(posedge clk) begin
    sync_d1 <= sync;
    sync_d2 <= sync_d1;
  end

  assign sync_posedge = ({sync_d2, sync_d1} == 2'b01);

  always_ff @(posedge clk) begin
    if (sync_posedge) begin
      frame_id <= sync_frame;
    end
  end

  // `frame_cnt` does not reset to 0 when reach max, so 10 ms sync is required
  always_ff @(posedge clk) begin
    if (sync_posedge) begin
      frame_cnt <= '0;
    end else if (&frame_cnt) begin
      frame_cnt <= frame_cnt;
    end else begin
      frame_cnt <= frame_cnt + 1;
    end
  end

  always_ff @(posedge clk) begin
    frame_sof <= (frame_cnt == shift);
  end

  // Sample counter in a symbol
  always_ff @(posedge clk) begin
    if (frame_sof) begin
      current_sample <= '0;
    end else if (current_sample == current_sample_max &&
                 current_symbol == current_symbol_max &&
                 current_subframe_slot == current_subframe_slot_max) begin
      // Stop the counter at last tick of 10ms
      current_sample <= current_sample;
    end else if (current_sample == current_sample_max) begin
      current_sample <= '0;
    end else begin
      current_sample <= current_sample + 1;
    end
  end

  // First symbol in every 14 symbols has 352 samples CP length Other symbols
  // has 288 samples CP length. However, for UL mode, this counter skip CP
  // and count for symbol data. So last symbol will has 352 sample suffix
  // TODO: this is for mu = 1, add other mu support

  generate
    if (MODE == 0) begin : g_dl
      always_comb begin
        if (current_symbol == 0) begin
          current_sample_max = (4096 + 352) * FREQUENCY - 1;
        end else begin
          current_sample_max = (4096 + 288) * FREQUENCY - 1;
        end
      end
    end else begin : g_ul
      always_comb begin
        if (current_symbol == 13) begin
          current_sample_max = (4096 + 352) * FREQUENCY - 1;
        end else begin
          current_sample_max = (4096 + 288) * FREQUENCY - 1;
        end
      end
    end
  endgenerate

  // Symbol counter
  always_ff @(posedge clk) begin
    if (frame_sof) begin
      current_symbol <= '0;
    end else if (current_sample == current_sample_max &&
                 current_symbol == current_symbol_max &&
                 current_subframe_slot == current_subframe_slot_max) begin
      current_symbol <= current_symbol;
    end else if (current_sample == current_sample_max && current_symbol == current_symbol_max) begin
      current_symbol <= '0;
    end else if (current_sample_max == current_sample) begin
      current_symbol <= current_symbol + 1;
    end
  end

  // Slot + subframe counter
  always_ff @(posedge clk) begin
    if (frame_sof) begin
      current_subframe_slot <= '0;
    end else if (current_sample == current_sample_max &&
                 current_symbol == current_symbol_max &&
                 current_subframe_slot == current_subframe_slot_max) begin
      current_subframe_slot <= current_subframe_slot;
    end else if (current_sample == current_sample_max && current_symbol == current_symbol_max) begin
      current_subframe_slot <= current_subframe_slot + 1;
    end
  end

  // Frame counter
  always_ff @(posedge clk) begin
    if (frame_sof) begin
      current_frame <= frame_id;
    end
  end

  // Output

  always_ff @(posedge clk) begin
    start_of_frame <= frame_sof;
  end

  always_ff @(posedge clk) begin
    start_of_symbol <= (frame_sof || ((current_sample_max == current_sample) &&
      !((current_symbol == current_symbol_max) &&
      (current_subframe_slot == current_subframe_slot_max))));
  end

endmodule

`default_nettype wire

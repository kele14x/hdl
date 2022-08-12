// File: symbol_timer.sv
// Brief: Generate 5G NR symbol timing information based on the parameters.
`timescale 1 ns / 100 ps
//
`default_nettype none

module symbol_timer #(
    parameter int CLOCK_RATIO = 1
) (
    input var        clk,                        // Assume 491.52 MHz clock
    input var        rst,
    //
    input var        radio_frame_start_10ms_in,
    //
    output var       radio_frame_start,
    output var       subframe_start,
    output var       slot_start,
    output var       symbol_start,
    output var       symbol_long_cp,
    // Control information
    input var  [2:0] ctrl_numerology,            // 0 ~ 4
    input var        ctrl_extended_cp            // 0 or 1, only applicable to numerology 2
);

  // mu       num_subframe num_slot  num_symbol  sample_cp_long  sample_cp_other  long/other  sample_symbol
  //  0       10           1         14          2560            2304             1/7         32768
  //  1       10           2         14          1408            1152             1/14        16384
  //  2       10           4         14          832             576              1/28        8192
  //  2, ecp  10           4         12          -               2048             -           8192
  //  3       10           8         14          544             288              1/56        4096
  //  4       10           16        14          400             144              1/112       2048

  logic [7:0] frame_counter;  // 0 ~ 255
  logic [3:0] subframe_counter;  // 0 ~ 9
  logic [4:0] slot_counter, slot_max;  // 0, 0~1, 0~3, 0~7, 0~15
  logic [3:0] symbol_counter, symbol_max;  // 0~13, 0~11
  logic [15:0] sample_counter, sample_max;

  logic is_long_cp;


  // Frame counter

  always_ff @(posedge clk) begin
    if (rst) begin
      frame_counter <= 0;
    end else if (subframe_counter == 9 && slot_counter == slot_max &&
                 symbol_counter == symbol_max && sample_counter == sample_max) begin
      frame_counter <= frame_counter + 1;
    end
  end


  // Subframe counter

  always_ff @(posedge clk) begin
    if (rst) begin
      subframe_counter <= 0;
    end else if (slot_counter == slot_max && symbol_counter == symbol_max &&
                 sample_counter == sample_max) begin
      if (subframe_counter == 9) begin
        subframe_counter <= 0;
      end else begin
        subframe_counter <= subframe_counter + 1;
      end
    end
  end


  // Slot counter

  always_ff @(posedge clk) begin
    if (rst) begin
      slot_counter <= 0;
    end else if (symbol_counter == symbol_max && sample_counter == sample_max) begin
      if (slot_counter == slot_max) begin
        slot_counter <= 0;
      end else begin
        slot_counter <= slot_counter + 1;
      end
    end
  end

  always_ff @(posedge clk) begin
    slot_max <= 2 ** ctrl_numerology - 1;
  end


  // Symbol counter

  always_ff @(posedge clk) begin
    if (rst) begin
      symbol_counter <= 0;
    end else if (sample_counter == sample_max) begin
      if (symbol_counter == symbol_max) begin
        symbol_counter <= 0;
      end else begin
        symbol_counter <= symbol_counter + 1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_numerology == 2 && ctrl_extended_cp == 1) begin
      symbol_max <= 11;
    end else begin
      symbol_max <= 13;
    end
  end


  // Sample counter

  always_ff @(posedge clk) begin
    if (rst) begin
      sample_counter <= 0;
    end else if (sample_counter == sample_max) begin
      sample_counter <= 0;
    end else begin
      sample_counter <= sample_counter + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (is_long_cp) begin
      case (ctrl_numerology)
        0:       sample_max <= (32768 + 2560) / CLOCK_RATIO - 1;
        1:       sample_max <= (16384 + 1408) / CLOCK_RATIO - 1;
        2:       sample_max <= (8192 + 832) / CLOCK_RATIO - 1;
        3:       sample_max <= (4096 + 544) / CLOCK_RATIO - 1;
        default: sample_max <= (2048 + 400) / CLOCK_RATIO - 1;
      endcase
    end else begin
      case (ctrl_numerology)
        0:       sample_max <= (32768 + 2304) / CLOCK_RATIO - 1;
        1:       sample_max <= (16384 + 1152) / CLOCK_RATIO - 1;
        2:       sample_max <= (8192 + 576) / CLOCK_RATIO - 1;
        3:       sample_max <= (4096 + 288) / CLOCK_RATIO - 1;
        default: sample_max <= (2048 + 144) / CLOCK_RATIO - 1;
      endcase
    end
  end

  always_comb begin
    is_long_cp = 0;
    if (ctrl_numerology == 0 && (symbol_counter == 0 || symbol_counter == 7)) begin
      is_long_cp = 1;
    end else if (ctrl_numerology == 1 && symbol_counter == 0) begin
      is_long_cp = 1;
    end else if (ctrl_numerology == 2 && ctrl_extended_cp == 0 && symbol_counter == 0 && (slot_counter == 0 || slot_counter == 2)) begin
      is_long_cp = 1;
    end else if (ctrl_numerology == 3 && symbol_counter == 0 && (slot_counter == 0 || slot_counter == 4)) begin
      is_long_cp = 1;
    end else if (ctrl_numerology == 4 && symbol_counter == 0 && (slot_counter == 0 || slot_counter == 8)) begin
      is_long_cp = 1;
    end
  end


  // Output

  always_ff @(posedge clk) begin
    if (rst) begin
      radio_frame_start <= 0;
      subframe_start    <= 0;
      slot_start        <= 0;
      symbol_start      <= 0;
      symbol_long_cp    <= 0;
    end else begin
      radio_frame_start <= (sample_counter == 0 && symbol_counter == 0 && slot_counter == 0 &&
                            subframe_counter == 0);
      subframe_start <= (sample_counter == 0 && symbol_counter == 0 && slot_counter == 0);
      slot_start <= (sample_counter == 0 && symbol_counter == 0);
      symbol_start <= (sample_counter == 0);
      symbol_long_cp <= (sample_counter == 0) && is_long_cp;
    end
  end

endmodule

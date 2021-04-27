// file: up_adaptor_gearbox_bfp9_comp.sv
// brief: Do BFP9 compression on input data stream. Input data stream is 2-RE
//        Stream with additional helper signals.
`timescale 1 ns / 1 ps `default_nettype none

module ul_adaptor_gearbox_bfp9_comp (
    input var         clk,
    input var         rst,
    //
    input var  [63:0] re_data,  // RE pair, {re1_q, re1_i, re0_q, re0_i}
    input var  [ 2:0] re_cnt,  // 0 ~ 5
    input var         re_valid,  // Should be valid all alone the packet
    input var         re_done,  // Pulse at last RE pair
    //
    output var [ 3:0] comp_exp,  // actually 0 ~ 7, but 4-bit is specified in std.
    output var [35:0] comp_mantissa,  // {re0_i, re0_q, re1_i, re1_q}
    output var [ 3:0] comp_cnt,  // 0 ~ 11, 12-state
    output var        comp_valid,
    output var        comp_done
);


  // Data delay line
  //----------------

  localparam int DelayTaps = 9;

  logic [63:0] re_data_d [DelayTaps];
  logic [ 2:0] re_cnt_d  [DelayTaps];
  logic        re_valid_d[DelayTaps];
  logic        re_done_d [DelayTaps];

  // Delay line

  always_ff @(posedge clk) begin
    re_cnt_d[0] <= re_cnt;
    for (int i = 1; i < DelayTaps; i++) begin
      re_cnt_d[i] <= re_cnt_d[i-1];
    end
  end

  always_ff @(posedge clk) begin
    re_data_d[0] <= re_data;
    for (int i = 1; i < DelayTaps; i++) begin
      re_data_d[i] <= re_data_d[i-1];
    end
  end

  always_ff @(posedge clk) begin
    re_valid_d[0] <= re_valid;
    for (int i = 1; i < DelayTaps; i++) begin
      re_valid_d[i] <= re_valid_d[i-1];
    end
  end

  always_ff @(posedge clk) begin
    re_done_d[0] <= re_done;
    for (int i = 1; i < DelayTaps; i++) begin
      re_done_d[i] <= re_done_d[i-1];
    end
  end


  // Exponent search path
  //---------------------

  logic [3:0] exp_0, exp_1, exp_2, exp_3, exp_mt, exp_ma, exp_pre, exp_pre_d;

  // 10-bit, extra 1-bit is used to do rounding
  logic [9:0] comp_mantissa_pre_0_i;
  logic [9:0] comp_mantissa_pre_0_q;
  logic [9:0] comp_mantissa_pre_1_i;
  logic [9:0] comp_mantissa_pre_1_q;

  // 9-bit rounded value
  logic [8:0] comp_mantissa_0_i;
  logic [8:0] comp_mantissa_0_q;
  logic [8:0] comp_mantissa_1_i;
  logic [8:0] comp_mantissa_1_q;

  // Get the BFP9 exponent value based on the 16-bit data, for example
  // 16'b0000000_000000001_ => exp = 0
  // 16'b0000_010000000_000 => exp = 3
  // 16'b_010000000_0000000 => exp = 7
  function automatic [3:0] get_exp(input logic [15:0] data);
    for (int i = 15; i >= 9; i--) begin
      if (data[i] != data[i-1]) begin
        return (i - 8);
      end
    end
    return 0;
  endfunction

  function automatic [3:0] max4(input logic [3:0] d1, input logic [3:0] d2, input logic [3:0] d3,
                                input logic [3:0] d4);
    automatic logic [3:0] temp;
    temp = (d1 > d2) ? d1 : d2;
    temp = temp > d3 ? temp : d3;
    temp = temp > d4 ? temp : d4;
    return temp;
  endfunction

  assign exp_0 = get_exp(re_data[15:0]);
  assign exp_1 = get_exp(re_data[31:16]);
  assign exp_2 = get_exp(re_data[47:32]);
  assign exp_3 = get_exp(re_data[63:48]);

  // `exp_mt` is largest of exp_0 ~ exp_3
  always_ff @(posedge clk) begin
    exp_mt <= max4(exp_0, exp_1, exp_2, exp_3);
  end

  // `exp_ma` is largest of exp_mt for cnt 0 ~ 5 (one block)
  always_ff @(posedge clk) begin
    if (re_cnt_d[0] == 0) begin
      exp_ma <= exp_mt;
    end else begin
      exp_ma <= exp_ma > exp_mt ? exp_ma : exp_mt;
    end
  end

  // Lock the exponent value for 6 ticks
  always_ff @(posedge clk) begin
    if (re_cnt_d[1] == 5) begin
      exp_pre <= exp_ma;
    end
  end

  always_ff @(posedge clk) begin
    comp_mantissa_pre_0_i <= re_data_d[7][15:0] >> (exp_pre - 1);  // re0_i
    comp_mantissa_pre_0_q <= re_data_d[7][31:16] >> (exp_pre - 1);  // re0_q
    comp_mantissa_pre_1_i <= re_data_d[7][47:32] >> (exp_pre - 1);  // re1_i
    comp_mantissa_pre_1_q <= re_data_d[7][63:48] >> (exp_pre - 1);  // re1_q
  end

  // Rounding stage
  //---------------

  function automatic [8:0] rounding(input logic [9:0] data);
    automatic logic [8:0] ret;
    if (data == '1) begin
      ret = '1;
    end else begin
      ret = (data[0] == 1'b1) ? data[9:1] + 1 : data[9:1];
    end
    return ret;
  endfunction

  always_ff @(posedge clk) begin
    comp_mantissa_0_i <= rounding(comp_mantissa_pre_0_i);
    comp_mantissa_0_q <= rounding(comp_mantissa_pre_0_q);
    comp_mantissa_1_i <= rounding(comp_mantissa_pre_1_i);
    comp_mantissa_1_q <= rounding(comp_mantissa_pre_1_q);
  end

  // Output
  //-------

  always_ff @(posedge clk) begin
    exp_pre_d <= exp_pre;
    comp_exp  <= exp_pre_d;
  end

  assign comp_mantissa = {
    comp_mantissa_0_i, comp_mantissa_0_q, comp_mantissa_1_i, comp_mantissa_1_q
  };

  always_ff @(posedge clk) begin
    comp_valid <= re_valid_d[DelayTaps-1];
  end

  always_ff @(posedge clk) begin
    comp_done <= re_done_d[DelayTaps-1];
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      comp_cnt <= '1;
    end else if (re_valid_d[DelayTaps-1]) begin
      comp_cnt <= ((comp_cnt == 11) ? 0 : (comp_cnt + 1));
    end else begin
      comp_cnt <= '1;
    end
  end

endmodule

`default_nettype wire

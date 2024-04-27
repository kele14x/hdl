// File: bfp_comp_exp.sv
// Brief: Find the exponent value, and use shift to compress. 
// Latency: 11
`timescale 1 ns / 1 ps
//
`default_nettype none

module bfp_comp_exp (
    input var         clk,
    input var         rst,
    //
    input var  [63:0] din_data,
    input var         din_valid,
    input var         din_sync,
    input var         din_last,
    //
    output var [63:0] dout_data,
    output var [ 2:0] dout_state,
    output var        dout_valid,
    output var        dout_sync,
    output var        dout_last,
    // Control
    //--------
    input var  [ 3:0] ud_iq_width
);


  //
  // This function get the max value out of 2
  //
  function static logic [15:0] get_max2(input logic [15:0] din[2]);
    logic [15:0] d0;
    logic [15:0] d1;
    d0 = din[0][15] ? ~din[0] : din[0];
    d1 = din[1][15] ? ~din[1] : din[1];
    return d0 > d1 ? d0 : d1;
  endfunction

  //
  // This function get the max value out of 4
  //
  function static logic [15:0] get_max4(input logic [15:0] din[4]);
    logic [15:0] d0;
    logic [15:0] d1;
    d0 = get_max2(din[0:1]);
    d1 = get_max2(din[2:3]);
    return d0 > d1 ? d0 : d1;
  endfunction

  //
  // This function get MSB position of input data
  //
  function static logic [3:0] get_msb(input logic [15:0] din);
    for (int i = 15; i > 0; i--) begin
      if (din[i] ^ din[i-1]) return i;
    end
    return 0;
  endfunction

  //
  // This function get shift value
  //
  function static logic [3:0] get_shift(input logic [3:0] msb, input logic [3:0] width);
    get_shift = width == 0 ? 0 : 15 - msb;
    get_shift = get_shift < 16 - width ? get_shift : 16 - width;
  endfunction

  //
  // This function get the exp value of input data
  //
  function static logic [3:0] get_exp(input logic [3:0] msb, input logic [3:0] width);
    logic [4:0] temp;
    if (width == '0) begin
      temp = '0;
    end else begin
      temp = {1'b0, msb} - width + 1;
    end
    return temp[4] ? 0 : temp[3:0];
  endfunction

  //
  // This function calculates the rounding mask
  //
  function static logic [15:0] get_mask(input logic [3:0] w);
    logic [15:0] mask;
    case (w)
      0: mask = 16'h0000;
      1: mask = 16'h7FFF;
      2: mask = 16'h3FFF;
      3: mask = 16'h1FFF;
      4: mask = 16'h0FFF;
      5: mask = 16'h07FF;
      6: mask = 16'h03FF;
      7: mask = 16'h01FF;
      8: mask = 16'h00FF;
      9: mask = 16'h007F;
      10: mask = 16'h003F;
      11: mask = 16'h001F;
      12: mask = 16'h000F;
      13: mask = 16'h0007;
      14: mask = 16'h0003;
      default: mask = 16'h0001;
    endcase
    return mask;
  endfunction


  // Main
  //-----

  // r0: state

  logic [15:0] data0  [4];
  logic [ 2:0] state0;

  generate
    for (genvar i = 0; i < 4; i++) begin : g_data0
      assign data0[i] = din_data[63-i*16-:16];
    end
  endgenerate

  // This is state0 has 0/1/2/3/4/5 and sync with input
  always_ff @(posedge clk) begin
    if (rst || (din_valid && din_last)) begin
      state0 <= '0;
    end else if (din_valid) begin
      state0 <= state0 == 5 ? 0 : state0 + 1;
    end
  end

  // r1: get max of 4

  logic [15:0] max1;
  logic [ 2:0] state1;
  logic        valid1;
  logic        last1;

  always_ff @(posedge clk) begin
    max1 <= get_max4(data0);
  end

  always_ff @(posedge clk) begin
    state1 <= state0;
    valid1 <= din_valid;
    last1  <= din_last;
  end

  // r2: max of 6 state (1 RB)

  logic [15:0] max2;
  logic [ 2:0] state2;
  logic [ 3:0] shift2;
  logic [ 3:0] exp2;
  logic        valid2;
  logic        last2;

  always_ff @(posedge clk) begin
    if (valid1) begin
      if (state1 == 0) begin
        max2 <= max1;
      end else begin
        max2 <= get_max2('{max1, max2});
      end
    end
  end

  assign shift2 = get_shift(get_msb(max2), ud_iq_width);
  assign exp2   = get_exp(get_msb(max2), ud_iq_width);

  always_ff @(posedge clk) begin
    state2 <= state1;
    valid2 <= valid1;
    last2  <= last1;
  end

  // r3: get shift value

  logic [64:0] fifo3;
  logic [15:0] mask3;
  logic [15:0] data3  [4];
  logic [ 3:0] shift3;
  logic [ 3:0] exp3;
  logic [ 2:0] state3;
  logic        empty3;
  logic        valid3;
  logic        sync3;
  logic        last3;

  always_ff @(posedge clk) begin
    mask3 <= get_mask(ud_iq_width) >> 1;
  end

  generate
    for (genvar i = 0; i < 4; i++) begin : g_data3
      assign data3[i] = fifo3[63-i*16-:16];
    end
  endgenerate

  // If exp fifo is not empty, read out data fifo for one RB data
  always_ff @(posedge clk) begin
    if (rst || (valid3 && last3)) begin
      state3 <= '0;
    end else if (~empty3 || valid3) begin
      state3 <= state3 == 5 ? 0 : state3 + 1;
    end
  end

  assign valid3 = ~empty3 || state3 > 0;

  always_ff @(posedge clk) begin
    if (rst) begin
      sync3 <= 1'b0;
    end else if (valid3 && last3) begin
      sync3 <= 1'b0;
    end else if (valid3) begin
      sync3 <= 1'b1;
    end
  end

  assign last3 = fifo3[64];

  // r4: shifting to remove msb, get shift4 value

  logic [15:0] mask4;
  logic [15:0] data4  [4];
  logic [ 3:0] exp4;
  logic [ 2:0] state4;
  logic        valid4;
  logic        sync4;
  logic        last4;

  always_ff @(posedge clk) begin
    mask4 <= ~get_mask(ud_iq_width);
  end

  generate
    for (genvar i = 0; i < 4; i++) begin : g_data4
      always_ff @(posedge clk) begin
        data4[i] <= (data3[i] << shift3) | mask3;
      end
    end
  endgenerate

  always_ff @(posedge clk) begin
    exp4   <= exp3;
    state4 <= state3;
    valid4 <= valid3;
    sync4  <= sync3;
    last4  <= last3;
  end

  // r5: rounding, and calculate shift5 value

  logic [63:0] data5_or;
  logic [63:0] data5_shift[4];
  logic [15:0] data5      [4];
  logic [ 6:0] shift5     [4];
  logic [ 3:0] exp5;
  logic [ 2:0] state5;
  logic        valid5;
  logic        sync5;
  logic        last5;

  generate
    for (genvar i = 0; i < 4; i++) begin : g_data5

      always_ff @(posedge clk) begin
        if (data4[i] == 16'h7FFF) begin
          data5[i] <= data4[i] & mask4;
        end else begin
          // TODO: test
          // data5[i] <= (data4[i] + 1) & mask4 | mask4;
          data5[i] <= (data4[i] + 1) & mask4;
        end
      end

      always_comb begin
        data5_shift[i] = {data5[i], 48'b0} >> shift5[i];
      end

    end
  endgenerate

  always_comb begin
    if (state5 == 0) begin
      data5_or = {4'b0, exp5, 56'b0};
    end else begin
      data5_or = 64'b0;
    end
    //
    for (int i = 0; i < 4; i++) begin
      data5_or = data5_or | data5_shift[i];
    end
  end

  generate
    for (genvar i = 0; i < 4; i++) begin : g_shift5
      always_ff @(posedge clk) begin
        if (state4 == 0) begin
          shift5[i] <= i * ud_iq_width + 8;
        end else begin
          shift5[i] <= i * ud_iq_width;
        end
      end
    end
  endgenerate

  always_ff @(posedge clk) begin
    exp5   <= exp4;
    state5 <= state4;
    valid5 <= valid4;
    sync5  <= sync4;
    last5  <= last4;
  end

  // r6: output

  always_ff @(posedge clk) begin
    dout_data  <= data5_or;
    dout_state <= state5;
    dout_sync  <= sync5;
    dout_valid <= valid5;
    dout_last  <= last5;
  end


  // Store data in SRL FIFO
  //-----------------------

  // The full/empty state is not check as we know the FIFO will never full
  // and we will be read at right time

  logic [7:0] exp_fifo_din;
  logic       exp_fifo_wr;
  logic [7:0] exp_fifo_dout;
  logic       exp_fifo_rd;

  assign exp_fifo_din = {shift2, exp2};
  assign exp_fifo_wr  = valid2 && (state2 == 5 || last2);
  assign exp_fifo_rd  = (state3 == 0);

  assign {shift3, exp3} = exp_fifo_dout;

  fifo_srl #(
      .DATA_WIDTH(8)
  ) i_exp_fifo (
      .clk  (clk),
      .rst  (rst),
      //
      .din  (exp_fifo_din),
      .wr_en(exp_fifo_wr),
      .full (  /* not used */),
      //
      .dout (exp_fifo_dout),
      .empty(empty3),
      .rd_en(exp_fifo_rd)
  );

  fifo_srl #(
      .DATA_WIDTH(65)
  ) i_data_fifo (
      .clk  (clk),
      .rst  (rst),
      //
      .din  ({din_last, din_data}),
      .wr_en(din_valid),
      .full (  /* not used */),
      //
      .dout (fifo3),
      .empty(  /* not used */),
      .rd_en(valid3)
  );

endmodule

`default_nettype wire

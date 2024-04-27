// File: bfp_comp_gearbox.sv
// Brief: Bit remap to compress data into bitstream
`timescale 1 ns / 1 ps
//
`default_nettype none

module bfp_comp_gearbox (
    input var         clk,
    input var         rst,
    //
    input var  [63:0] din_data,
    input var  [ 2:0] din_state,
    input var         din_valid,
    input var         din_sync,
    input var         din_last,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    // Control
    //--------
    input var [3:0] ud_iq_width
);

  import bfp_pkg::*;

  logic [63:0] data_shift;
  logic [63:0] data_shift_f;

  logic [63:0] tdata;
  logic [63:0] tdata_f;

  logic [ 4:0] cnt;
  logic [ 4:0] cnt_next;
  logic [ 5:0] shift;

  logic        last_extend;


  // Main
  //-----

  assign {data_shift, data_shift_f} = {din_data, 64'b0} >> shift;

  // `cnt` is how many bits are already registered in module, divided by 4
  always_ff @(posedge clk) begin
    if (rst) begin
      cnt <= '0;
    end else if (din_valid && din_last && cnt_next > 16) begin
      cnt <= cnt_next;
    end else if (din_valid && din_last) begin
      cnt <= '0;
    end else if (din_valid) begin
      cnt <= cnt_next;
    end else if (last_extend) begin
      cnt <= '0;
    end
  end

  always_comb begin
    if (din_state == 0) begin
      cnt_next = (cnt & 5'h0F) + 2 + ud_iq_width;
    end else begin
      cnt_next = (cnt & 5'h0F) + ud_iq_width;
    end
  end

  assign shift = {cnt[3:0], 2'b0};

  always_ff @(posedge clk) begin
    last_extend <= din_valid && din_last && (cnt_next > 16);
  end

  always_ff @(posedge clk) begin
    if (last_extend) begin
        tdata <= tdata_f | data_shift;
    end else if (din_valid) begin
      if (~din_sync) begin
        tdata <= data_shift;
      end else if (cnt[4]) begin
        tdata <= tdata_f | data_shift;
      end else begin
        tdata <= tdata | data_shift;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (din_valid) begin
      tdata_f <= data_shift_f;
    end
  end

  assign m_axis_tdata  = byte_reverse(tdata);

  always_ff @(posedge clk) begin
    if (din_valid && din_last) begin
      m_axis_tvalid <= 1'b1;
    end else if (last_extend) begin
      m_axis_tvalid <= 1'b1;
    end else if (din_valid && cnt_next >= 16) begin
      m_axis_tvalid <= 1'b1;
    end else begin
      m_axis_tvalid <= 1'b0;
    end
    // m_axis_tvalid <= (cnt_next[4] && din_valid) || last_extend;
  end

  always_ff @(posedge clk) begin
    if (din_valid && din_last && cnt_next <= 16) begin
      m_axis_tlast <= 1'b1;
    end else if (last_extend) begin
      m_axis_tlast <= 1'b1;
    end else if (din_valid) begin
      m_axis_tlast <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (din_valid && din_last && cnt_next < 16) begin
      m_axis_tkeep <= 8'hFF >> (8 - shift / 8);
    end else if (last_extend) begin
      m_axis_tkeep <= 8'hFF >> (8 - shift / 8);
    end else if (din_valid) begin
      m_axis_tkeep <= 8'hFF;
    end
  end

  // TODO: tkeep?

endmodule

`default_nettype wire

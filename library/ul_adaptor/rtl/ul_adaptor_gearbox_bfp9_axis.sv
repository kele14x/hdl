// file: ul_adaptor_gearbox_bfp9_axis
// brief: Compressed BFP9 data to AXIS interface mover
`timescale 1 ns / 1 ps `default_nettype none

module ul_adaptor_gearbox_bfp9_axis (
    input var         clk,
    input var         rst,
    //
    input var  [ 3:0] comp_exp,
    input var  [35:0] comp_mantissa,
    input var  [ 3:0] comp_cnt,
    input var         comp_valid,
    input var         comp_done,
    // AXIS
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    input var         m_axis_tready
);

  function automatic [63:0] byte_reverse(input logic [63:0] din);
    automatic logic [63:0] ret;
    ret = {
      din[7:0], din[15:8], din[23:16], din[31:24], din[39:32], din[47:40], din[55:48], din[63:56]
    };
    return ret;
  endfunction

  logic [35:0] comp_mantissa_d;
  logic [35:0] comp_mantissa_dd;

  logic        comp_done_odd;

  logic [63:0] tdata;
  logic        tvalid;

  always_ff @(posedge clk) begin
    comp_mantissa_d  <= comp_mantissa;
    comp_mantissa_dd <= comp_mantissa_d;
  end

  assign tvalid = ((comp_cnt == 1) || (comp_cnt == 3) ||
    (comp_cnt == 5) || (comp_cnt == 6) || (comp_cnt == 8) ||
    (comp_cnt == 10) || (comp_cnt == 11)) && comp_valid || comp_done_odd;

  always_comb begin
    if (comp_cnt == 1) begin
      tdata = {4'b0, comp_exp, comp_mantissa_d, comp_mantissa[35:16]};
    end else if (comp_cnt == 3) begin
      tdata = {comp_mantissa_dd[15:0], comp_mantissa_d, comp_mantissa[35:24]};
    end else if (comp_cnt == 5) begin
      tdata = {comp_mantissa_dd[23:0], comp_mantissa_d, comp_mantissa[35:32]};
    end else if (comp_cnt == 6 || comp_done_odd) begin
      tdata = {comp_mantissa_d[31:0], 4'b0, comp_exp, comp_mantissa[35:12]};
    end else if (comp_cnt == 8) begin
      tdata = {comp_mantissa_dd[11:0], comp_mantissa_d, comp_mantissa[35:20]};
    end else if (comp_cnt == 10) begin
      tdata = {comp_mantissa_dd[19:0], comp_mantissa_d, comp_mantissa[35:28]};
    end else begin  // 11 and other
      tdata = {comp_mantissa_d[27:0], comp_mantissa};
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tdata <= '0;
    end else if (tvalid) begin
      m_axis_tdata <= byte_reverse(tdata);
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tkeep <= '0;
    end else begin
      m_axis_tkeep <= comp_done_odd ? 8'h0F : 8'hFF;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tvalid <= '0;
    end else begin
      m_axis_tvalid <= tvalid;
    end
  end

  always_ff @(posedge clk) begin
    comp_done_odd <= (comp_cnt == 5 && comp_done);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tlast <= '0;
    end else begin
      m_axis_tlast <= comp_done_odd || (comp_done && comp_cnt == 11);
    end
  end

endmodule

`default_nettype wire

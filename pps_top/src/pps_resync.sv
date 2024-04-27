`timescale 1 ns / 1 ps
//
`default_nettype none

module pps_resync (
    input var         clk,
    input var         rst,
    //
    input var         in_sof,
    input var         in_sos,
    input var  [32:0] in_frac,
    //
    output var        out_sof,
    output var        out_sos,
    output var [32:0] out_frac
);

  logic [ 1:0] cnt;
  logic        sof_req;
  logic        sos_req;
  logic [32:0] frac_req;

  always_ff @(posedge clk) begin
    if (rst) begin
      cnt <= 0;
    end else begin
      cnt <= cnt + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (cnt != 0 && in_sof) begin
      sof_req <= 1'b1;
    end else if (cnt == 0) begin
      sof_req <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (cnt == 0 && in_sof) begin
      out_sof <= 1'b1;
    end else if (cnt == 0 && sof_req) begin
      out_sof <= 1'b1;
    end else begin
      out_sof <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (cnt != 0 && in_sos) begin
      sos_req <= 1'b1;
    end else if (cnt == 0) begin
      sos_req <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (cnt == 0 && in_sos) begin
      out_sos <= 1'b1;
    end else if (cnt == 0 && sos_req) begin
      out_sos <= 1'b1;
    end else begin
      out_sos <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (cnt == 1 && in_sos) begin
      frac_req <= (in_frac >> 2) + 32'h0C0000000;
    end else if (cnt == 2 && in_sos) begin
      frac_req <= (in_frac >> 2) + 32'h080000000;
    end else if (cnt == 3 && in_sos) begin
      frac_req <= (in_frac >> 2) + 32'h040000000;
    end
  end

  always_ff @(posedge clk) begin
    if (cnt == 0 && in_sos) begin
      out_frac <= (in_frac >> 2);
    end else if (cnt == 0 && sos_req) begin
      out_frac <= frac_req;
    end
  end

endmodule

`default_nettype wire

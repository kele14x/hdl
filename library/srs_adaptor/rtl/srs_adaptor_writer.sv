`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_writer (
    // DFE
    //====
    input var         clk,
    input var         rst,
    //
    input var  [23:0] srs_data,   // {4'b exponent, 9'b mantissa Q, 9'b mantissa I}
    input var         srs_valid,
    input var         srs_eop,
    //
    output var [11:0] wr_addr,
    output var        wr_en,
    output var [23:0] wr_data
);

  logic synced, synced_next;

  always_ff @(posedge clk) begin
    if (rst) begin
      synced <= 1'b0;
    end else begin
      synced <= synced_next;
    end
  end

  always_comb begin
    case (synced)
      1'b0:    synced_next = srs_valid ? 1'b1 : 1'b0;
      1'b1:    synced_next = (srs_valid && srs_eop) ? 1'b0 : 1'b1;
      default: synced_next = 1'b0;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_en <= 0;
    end else begin
      wr_en <= srs_valid;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_addr <= '0;
    end else if (srs_valid) begin
      wr_addr <= synced ? wr_addr + 1 : '0;
    end
  end

  always_ff @(posedge clk) begin
    wr_data <= srs_data;
  end

endmodule

`default_nettype wire

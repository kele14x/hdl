// file: srs_adaptor_write.sv
// brief: When a packet of SRS message arrives, it will write it into a BRAM
//        buffer. Generally this module generates the write address and write
//        enable signal.
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_writer (
    // DFE
    //====
    input var         clk,
    input var         rst,
    //
    input var  [23:0] srs_data_tdata,   // {4'b exponent, 9'b mantissa Q, 9'b mantissa I}
    input var         srs_data_tvalid,
    input var         srs_data_tlast,
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
      1'b0:    synced_next = srs_data_tvalid ? 1'b1 : 1'b0;
      1'b1:    synced_next = (srs_data_tvalid && srs_data_tlast) ? 1'b0 : 1'b1;
      default: synced_next = 1'b0;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_en <= 0;
    end else begin
      wr_en <= srs_data_tvalid;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_addr <= '0;
    end else if (srs_data_tvalid) begin
      wr_addr <= synced ? wr_addr + 1 : '0;
    end
  end

  always_ff @(posedge clk) begin
    wr_data <= srs_data_tdata;
  end

endmodule

`default_nettype wire

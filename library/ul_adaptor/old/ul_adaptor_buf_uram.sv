// File: ul_adaptor_buf_uram.sv
// Brief: Simplified URAM model, simple dual port.
`timescale 1 ns / 1 ps `default_nettype none

module ul_adaptor_buf_uram (
    input var         clk,
    input var         rst,
    //
    input var  [12:0] wr_addr,
    input var  [31:0] wr_data,
    input var         wr_en,
    //
    input var  [11:0] rd_addr,
    input var         rd_en,
    output var [63:0] rd_data
);


  (* ram_style="ultra" *)
  logic [63:0] URAM[4096];

  logic [63:0] rd_data_pre;

  // URAM does not support asymmetric read/write port width, but it does 
  // support byte enable. So 32-bit write is done using byte enable
  always_ff @(posedge clk) begin
    if (wr_en) begin
      if (wr_addr[0] == 0) begin
        URAM[wr_addr[12:1]][31:0] <= wr_data;
      end
      if (wr_addr[0] == 1) begin
        URAM[wr_addr[12:1]][63:32] <= wr_data;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rd_en) begin
      rd_data_pre <= URAM[rd_addr];
    end
  end

  always_ff @(posedge clk) begin
    rd_data <= rd_data_pre;
  end

endmodule

`default_nettype wire

// File: dl_adaptor_buffer.sv
// Brief: Downlink PDxCH (DL U-Plane data) adaptor buffer. It should be a URAM
//        with some surrounding logic.
`timescale 1 ns / 1 ps `default_nettype none

module dl_adaptor_buffer (
    // Interface with DFE
    //===================
    input var         clk,
    input var         rst,
    // Write
    input var  [11:0] wr_addr,
    input var         wr_en,
    input var  [63:0] wr_data,
    // Read
    input var  [11:0] rd_addr,
    input var         rd_en,
    output var [63:0] rd_data
);

  logic [63:0] rd_data_reg;
  logic        rd_en_d;

  (* ram_style="ultra" *)
  logic [63:0] mem         [4096];

  always_ff @(posedge clk) begin
    if (wr_en) begin
      mem[wr_addr] <= wr_data;
    end
  end

  always_ff @(posedge clk) begin
    if (rd_en) begin
      rd_data_reg <= mem[rd_addr];
    end
  end

  always_ff @(posedge clk) begin
    rd_en_d <= rd_en;
  end

  always_ff @(posedge clk) begin
    if (rd_en_d) begin
      rd_data <= rd_data_reg;
    end
  end

endmodule

`default_nettype wire

// file: srs_adaptor_controller_mem.sv
// brief: Simple dual port RAM to store SRS message

`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_controller_mem #(
    parameter int ADDR_WIDTH = 10,
    parameter int DATA_WIDTH = 72
) (
    input var                   clk,
    input var                   rst,
    // UL Timing
    input var  [ADDR_WIDTH-1:0] wr_addr,
    input var                   wr_en,
    input var  [DATA_WIDTH-1:0] wr_data,
    //
    input var  [ADDR_WIDTH-1:0] rd_addr,
    input var                   rd_en,
    input var                   rd_clr,
    output var [DATA_WIDTH-1:0] rd_data
);


  logic [DATA_WIDTH-1:0] MEM[2**ADDR_WIDTH];

  // Port A

  always_ff @(posedge clk) begin
    if (wr_en) begin
      MEM[wr_addr] <= wr_data;
    end
  end

  // Port B

  always_ff @(posedge clk) begin
    if (rd_en && rd_clr) begin
      MEM[rd_addr] <= '0;
    end
  end

  always_ff @(posedge clk) begin
    if (rd_en) begin
      rd_data <= MEM[rd_addr];
    end
  end

endmodule

`default_nettype wire

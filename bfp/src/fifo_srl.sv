// File: fifo_srl.sv
// Brief: FIFO implemented using Xilinx SRL16
`timescale 1 ns / 1 ps
//
`default_nettype none

module fifo_srl #(
    parameter int ADDR_WIDTH = 4,
    parameter int DATA_WIDTH = 8
) (
    input var                   clk,
    input var                   rst,
    //
    input var  [DATA_WIDTH-1:0] din,
    input var                   wr_en,
    output var                  full,
    //
    output var [DATA_WIDTH-1:0] dout,
    output var                  empty,
    input var                   rd_en
);

  localparam int Depth = 2 ** ADDR_WIDTH;

  logic [DATA_WIDTH-1:0] srl   [Depth];
  logic [ADDR_WIDTH-1:0] addr;
  logic                  valid;

  // TODO: we can register it to improve timing
  assign full = &addr;

  initial begin
    for (int i = 0; i < 16; i++) begin
      srl[i] = '0;
    end
  end

  always_ff @(posedge clk) begin
    if (wr_en && !full) begin
      srl[0] <= din;
      for (int i = 1; i < 16; i++) begin
        srl[i] <= srl[i-1];
      end
    end
  end

  assign dout = srl[addr];

  always_ff @(posedge clk) begin
    if (rst) begin
      addr <= '0;
    end else if (wr_en && ~rd_en && ~&addr && valid) begin
      addr <= addr + 1;
    end else if (rd_en && (&addr || (~wr_en && |addr))) begin
      addr <= addr - 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      valid <= 1'b0;
    end else if (addr == '0 && wr_en) begin
      valid <= 1'b1;
    end else if (addr == '0 && ~wr_en && rd_en) begin
      valid <= 1'b0;
    end
  end

  assign empty = ~valid;

endmodule

`default_nettype wire

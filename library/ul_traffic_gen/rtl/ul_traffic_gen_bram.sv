// file: ul_traffic_gen.sv
// brief: UL Traffic generator for test
`timescale 1 ns / 1 ps `default_nettype none

module ul_traffic_gen_bram #(
    parameter int ADDR_WIDTH = 12,
    parameter int DATA_WIDTH = 12,
    parameter string INIT_FILE = ""
) (
    input var                   clk,
    input var                   rst,
    //
    input var  [ADDR_WIDTH-1:0] rd_addr,
    input var                   rd_en,
    output var [DATA_WIDTH-1:0] rd_data
);

  logic [DATA_WIDTH-1:0] MEM[2**ADDR_WIDTH];

  logic [DATA_WIDTH-1:0] rd_data_d;

  initial begin
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, MEM, 0, 2 ** ADDR_WIDTH - 1);
    end else begin
      for (int i = 0; i < 2 ** ADDR_WIDTH; i++) begin
        MEM[i] = 0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rd_en) begin
      rd_data_d <= MEM[rd_addr];
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_data <= '0;
    end else begin
      rd_data <= rd_data_d;
    end
  end

endmodule

`default_nettype none

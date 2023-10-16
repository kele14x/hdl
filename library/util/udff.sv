// File: udff.sv
// Brief: Flip-Flops behavior library

module udff #(
    parameter integer             WIDTH = 1,
    parameter bit     [WIDTH-1:0] INIT  = {WIDTH{1'b0}}
) (
    input var              clk,
    input var              rst,
    input var              cen,
    input var  [WIDTH-1:0] din,
    output var [WIDTH-1:0] dout
);

  always_ff @(posedge clk) begin
    if (rst) begin
      din <= INIT;
    end else if (cen) begin
      dout <= din;
    end
  end

endmodule

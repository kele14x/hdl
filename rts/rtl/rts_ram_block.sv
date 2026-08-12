/*
 * Each block is 32k * 64 bits
 * Write latency is 1 clock cycle (from en to memory)
 * Read latency is 3 clock cycles (from en to output)
 */

`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY="yes" *)
module rts_ram_block #(
    parameter ADDR_WIDTH = 15,
    parameter DATA_WIDTH = 64
) (
    input var                     clk,
    // Port A
    input var                     rsta,
    input var  [  ADDR_WIDTH-1:0] addra,
    input var                     ena,
    input var  [DATA_WIDTH/8-1:0] wea,
    input var  [  DATA_WIDTH-1:0] dina,
    output var [  DATA_WIDTH-1:0] douta,
    // Port B
    input var                     rstb,
    input var  [  ADDR_WIDTH-1:0] addrb,
    input var                     enb,
    input var  [DATA_WIDTH/8-1:0] web,
    input var  [  DATA_WIDTH-1:0] dinb,
    output var [  DATA_WIDTH-1:0] doutb
);

  (* RAM_STYLE="ultra" *)
  logic [DATA_WIDTH-1:0] mem    [0:2**ADDR_WIDTH-1];

  logic                  ena_d;
  logic                  ena_dd;
  logic [DATA_WIDTH-1:0] prega;
  logic [DATA_WIDTH-1:0] orega;

  logic                  enb_d;
  logic                  enb_dd;
  logic [DATA_WIDTH-1:0] pregb;
  logic [DATA_WIDTH-1:0] oregb;

  // Port A

  // Memory write
  always @(posedge clk) begin : p_mem_wea
    integer i;
    if (ena) begin
      for (i = 0; i < DATA_WIDTH / 8; i = i + 1) begin
        if (wea[i]) begin
          mem[addra][i*8+7-:8] <= dina[i*8+7-:8];
        end
      end
    end
  end

  // Memory read
  always_ff @(posedge clk) begin
    if (ena) begin
      if (~|wea) begin
        prega <= mem[addra];
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rsta) begin
      ena_d  <= 1'b0;
      ena_dd <= 1'b0;
    end else begin
      ena_d  <= ena;
      ena_dd <= ena_d;
    end
  end

  always_ff @(posedge clk) begin
    if (ena_d) begin
      orega <= prega;
    end
  end

  always_ff @(posedge clk) begin
    if (ena_dd) begin
      douta <= orega;
    end else begin
      douta <= 'b0;
    end
  end

  // Port B

  // Memory write
  always @(posedge clk) begin : p_mem_web
    integer i;
    if (enb) begin
      for (i = 0; i < DATA_WIDTH / 8; i = i + 1) begin
        if (web[i]) begin
          mem[addrb][i*8+7-:8] <= dinb[i*8+7-:8];
        end
      end
    end
  end

  // Memory read
  always_ff @(posedge clk) begin
    if (enb) begin
      if (~|web) begin
        pregb <= mem[addrb];
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rstb) begin
      enb_d  <= 1'b0;
      enb_dd <= 1'b0;
    end else begin
      enb_d  <= enb;
      enb_dd <= enb_d;
    end
  end

  always_ff @(posedge clk) begin
    if (enb_d) begin
      oregb <= pregb;
    end
  end

  always_ff @(posedge clk) begin
    if (enb_dd) begin
      doutb <= oregb;
    end else begin
      doutb <= 'b0;
    end
  end

endmodule

`default_nettype wire

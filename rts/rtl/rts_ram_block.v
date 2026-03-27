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
    input  wire                    clk,
    // Port A
    input  wire                    rsta,
    input  wire [  ADDR_WIDTH-1:0] addra,
    input  wire                    ena,
    input  wire [DATA_WIDTH/8-1:0] wea,
    input  wire [  DATA_WIDTH-1:0] dina,
    output reg  [  DATA_WIDTH-1:0] douta,
    // Port B
    input  wire                    rstb,
    input  wire [  ADDR_WIDTH-1:0] addrb,
    input  wire                    enb,
    input  wire [DATA_WIDTH/8-1:0] web,
    input  wire [  DATA_WIDTH-1:0] dinb,
    output reg  [  DATA_WIDTH-1:0] doutb
);

  (* RAM_STYLE="ultra" *)
  reg [DATA_WIDTH-1:0] mem    [0:2**ADDR_WIDTH-1];

  reg                  ena_d;
  reg                  ena_dd;
  reg [DATA_WIDTH-1:0] prega;
  reg [DATA_WIDTH-1:0] orega;

  reg                  enb_d;
  reg                  enb_dd;
  reg [DATA_WIDTH-1:0] pregb;
  reg [DATA_WIDTH-1:0] oregb;

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
  always @(posedge clk) begin
    if (ena) begin
      if (~|wea) begin
        prega <= mem[addra];
      end
    end
  end

  always @(posedge clk) begin
    ena_d  <= ena;
    ena_dd <= ena_d;
  end

  always @(posedge clk) begin
    if (ena_d) begin
      orega <= prega;
    end
  end

  always @(posedge clk) begin
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
  always @(posedge clk) begin
    if (enb) begin
      if (~|web) begin
        pregb <= mem[addrb];
      end
    end
  end

  always @(posedge clk) begin
    enb_d  <= enb;
    enb_dd <= enb_d;
  end

  always @(posedge clk) begin
    if (enb_d) begin
      oregb <= pregb;
    end
  end

  always @(posedge clk) begin
    if (enb_dd) begin
      doutb <= oregb;
    end else begin
      doutb <= 'b0;
    end
  end

endmodule

`default_nettype wire

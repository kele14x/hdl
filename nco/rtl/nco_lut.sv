// File: nco_lut.v
// Brief: The stored in memory part of DDS LUT.
`timescale 1 ns / 1 ps
//
`default_nettype none

module nco_lut #(
    parameter int NUM_PARALLEL   = 1,
    parameter int INDEX_PARALLEL = 0,
    parameter int PHASE_ENTRIES  = 3072,
    parameter int DATA_WIDTH     = 16
) (
    input var                                     clk,
    //
    input var                                     rsta,
    input var                                     ena,
    input var         [$clog2(PHASE_ENTRIES)-1:0] addra,
    output var signed [           DATA_WIDTH-1:0] douta,
    //
    input var                                     rstb,
    input var                                     enb,
    input var         [$clog2(PHASE_ENTRIES)-1:0] addrb,
    output var signed [           DATA_WIDTH-1:0] doutb
);


  localparam int Latency = 2;
  localparam int AddrWidth = $clog2(PHASE_ENTRIES);
  localparam real PI = 3.14159265359;


  // The Memory
  (* ram_style="block" *)
  logic signed [DATA_WIDTH-1:0] MEM     [2**AddrWidth];

  logic                         ena_d;
  logic                         enb_d;

  logic                         rsta_d;
  logic                         rstb_d;

  logic signed [DATA_WIDTH-1:0] douta_s;
  logic signed [DATA_WIDTH-1:0] doutb_s;


  initial begin
    for (int i = 0; i < PHASE_ENTRIES; i++) begin
      MEM[i] = (2 ** (DATA_WIDTH - 1) - 2) *
        $cos(2 * PI * (i + $itor(INDEX_PARALLEL) / NUM_PARALLEL) / PHASE_ENTRIES);
    end
  end


  // Memory port A

  always @(posedge clk) begin
    ena_d  <= ena;
    rsta_d <= rsta;
  end

  always @(posedge clk) begin
    if (ena) begin
      douta_s <= MEM[addra];
    end
  end

  always @(posedge clk) begin
    if (rsta_d) begin
      douta <= '0;
    end else if (ena_d) begin
      douta <= douta_s;
    end
  end


  // Memory port B

  always @(posedge clk) begin
    enb_d  <= enb;
    rstb_d <= rstb;
  end

  always @(posedge clk) begin
    if (enb) begin
      doutb_s <= MEM[addrb];
    end
  end

  always @(posedge clk) begin
    if (rstb_d) begin
      doutb <= '0;
    end else if (enb_d) begin
      doutb <= doutb_s;
    end
  end

endmodule

`default_nettype wire

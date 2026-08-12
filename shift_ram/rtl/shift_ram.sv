`timescale 1 ns / 1 ps
//
`default_nettype none

module shift_ram #(
    parameter int WIDTH       = 8,
    parameter int DEPTH       = 8,
    parameter int INPUT_REG   = 0,
    parameter int PACKED_URAM = 0,
    parameter     RAM_STYLE   = "AUTO"
) (
    input var              clk,
    input var              rst,
    input var              cen,
    //
    input var  [WIDTH-1:0] din,
    output var [WIDTH-1:0] dout
);

  // Local parameters

  // Memory write and read address has minimal gap of 1 to avoid collision,
  // which means maximum delay taps 2 ** (AddrWidth) - 1. Additional
  // RAM is configured to have latency of 3, result maximum depth is
  // 2 ** (AddrWidth) + 2.
  localparam int AddrWidth = $clog2(DEPTH - 2 - (INPUT_REG != 0 ? 1 : 0));

  localparam int MinDepth = INPUT_REG != 0 ? 5 : 4;
  localparam int RamReadLatency = PACKED_URAM != 0 ? 3 : 2;

  // Check parameters

  // verilog_format: off
  initial begin
    // Check DEPTH
    if (DEPTH < MinDepth || 16384 < DEPTH) begin
      $fatal(1, "Delay depth (DEPTH) must be within the range %0d to 16384, got %0d. [%m]", MinDepth, DEPTH);
    end

    assert (PACKED_URAM == 0 || PACKED_URAM == 1)
    else $fatal(1, "PACKED_URAM must be 0 or 1, got %0d. [%m]", PACKED_URAM);

    if (PACKED_URAM != 0) begin
      assert (WIDTH == 36 && DEPTH == 8192 && INPUT_REG != 0)
      else $fatal(1, "PACKED_URAM requires WIDTH=36, DEPTH=8192, and INPUT_REG=1. [%m]");
    end
  end
  // verilog_format: on

  // Signals

  logic [     AddrWidth-1:0] addra;
  logic [     AddrWidth-1:0] addrb;

  logic [         WIDTH-1:0] dina;

  logic [         WIDTH-1:0] doutb;
  logic [RamReadLatency-1:0] vld;

  function automatic [AddrWidth-1:0] addr_cast(input integer value);
    addr_cast = value[AddrWidth-1:0] ^ {AddrWidth{|value[31:AddrWidth] & 1'b0}};
  endfunction

  // Write & read address

  always_ff @(posedge clk) begin
    if (rst) begin
      addra <= {AddrWidth{1'b0}};
    end else if (cen) begin
      addra <= addra + 1'd1;
    end
  end

  generate
    if (INPUT_REG != 0) begin : g_ireg
      always_ff @(posedge clk) begin
        if (cen) begin
          dina <= din;
        end
      end
    end else begin : g_no_ireg
      always_comb begin
        dina = din;
      end
    end
  endgenerate

  // Compensate the RAM pipeline so the externally visible delay stays DEPTH.
  always_ff @(posedge clk) begin
    if (rst) begin
      addrb <= addr_cast(-DEPTH + 1 + RamReadLatency + (INPUT_REG != 0 ? 1 : 0));
    end else if (cen) begin
      addrb <= addr_cast(integer'(addra) + 2 + RamReadLatency - DEPTH + (INPUT_REG != 0 ? 1 : 0));
    end
  end

  generate
    if (PACKED_URAM != 0) begin : g_packed_uram
      ram_sdp_uram_8k36 i_ram_sdp (
          // Port A, write port
          .clka (clk),
          .wea  (cen),
          .addra(addra),
          .dina (dina),
          // Port B, read port
          .clkb (clk),
          .rstb (1'b0),
          .enb  ({3{cen}}),
          .addrb(addrb),
          .doutb(doutb)
      );
    end else begin : g_standard_ram
      ram_sdp #(
          .ADDR_WIDTH  (AddrWidth),
          .DATA_WIDTH  (WIDTH),
          .READ_LATENCY(2),
          .INIT_FILE   ("NONE"),
          .RAM_STYLE   (RAM_STYLE)
      ) i_ram_sdp (
          // Port A, write port
          .clka (clk),
          .wea  (cen),
          .addra(addra),
          .dina (dina),
          // Port B, read port
          .clkb (clk),
          .rstb (1'b0),
          .enb  ({2{cen}}),
          .addrb(addrb),
          .doutb(doutb)
      );
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (rst) begin
      vld <= {RamReadLatency{1'b0}};
    end else if (cen) begin
      vld <= {vld[RamReadLatency-2:0], 1'b1};
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      dout <= {WIDTH{1'b0}};
    end else if (cen) begin
      dout <= doutb & {WIDTH{vld[RamReadLatency-1]}};
    end
  end

endmodule

`default_nettype wire

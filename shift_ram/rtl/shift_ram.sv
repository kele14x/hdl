`timescale 1 ns / 1 ps
//
`default_nettype none

module shift_ram #(
    parameter int WIDTH     = 8,
    parameter int DEPTH     = 8,
    parameter int INPUT_REG = 0,
    parameter     RAM_STYLE = "AUTO"
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
  localparam integer AddrWidth = $clog2(DEPTH - 2 - (INPUT_REG > 0 ? 1 : 0));

  localparam integer MinDepth = INPUT_REG > 0 ? 5 : 4;

  // Check parameters

  // verilog_format: off
  initial begin
    // Check DEPTH
    if (DEPTH < MinDepth || 16384 < DEPTH) begin
      $fatal(1, "Delay depth (DEPTH) must be within the range %0d to 16384, got %0d. [%m]", MinDepth, DEPTH);
    end
  end
  // verilog_format: on

  // Signals

  logic [AddrWidth-1:0] addra;
  logic [AddrWidth-1:0] addrb;

  logic [    WIDTH-1:0] dina;

  logic [    WIDTH-1:0] doutb;
  logic [          1:0] vld;

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
    if (INPUT_REG > 0) begin : g_ireg
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

  // At minimal depth=4, read address is reset to -1, which is bottom of RAM.
  always_ff @(posedge clk) begin
    if (rst) begin
      addrb <= addr_cast(-DEPTH + 3 + (INPUT_REG > 0 ? 1 : 0));
    end else if (cen) begin
      addrb <= addr_cast(integer'(addra) + 4 - DEPTH + (INPUT_REG > 0 ? 1 : 0));
    end
  end

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

  always_ff @(posedge clk) begin
    if (rst) begin
      vld <= 2'b00;
    end else if (cen) begin
      vld <= {vld[0], 1'b1};
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      dout <= {WIDTH{1'b0}};
    end else if (cen) begin
      dout <= doutb & {WIDTH{vld[1]}};
    end
  end

endmodule

`default_nettype wire

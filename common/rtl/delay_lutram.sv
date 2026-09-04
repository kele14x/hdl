`timescale 1 ns / 1 ps
//
`default_nettype none

// Event-advanced delay line implemented with single-port distributed RAM.
// The write and read use one address, allowing Vivado to infer a RAM32X1S,
// RAM64X1S, or RAM128X1S per data bit instead of an SRL per data bit.
//
// The memory is initialized for simulation/configuration but is not cleared
// by rst. Only the event pointer and output register are reset. This matches
// the non-flushing behavior of the RAM-backed delay path.
module delay_lutram #(
    parameter int WIDTH = 36,
    parameter int DEPTH = 32
) (
    input var              clk,
    input var              rst,
    input var              cen,
    //
    input var  [WIDTH-1:0] din,
    output var [WIDTH-1:0] dout
);

  // The output register supplies one event of delay, so only DEPTH-1 entries
  // are used. Keep the physical array at a power-of-two depth so Vivado can
  // infer the native LUTRAM primitive without a non-power-of-two wrapper.
  localparam int DelayEntries = DEPTH - 1;
  localparam int RamDepth     = 1 << $clog2(DEPTH);
  localparam int AddrWidth    = $clog2(RamDepth);

  initial begin : drc_check
    assert (DEPTH >= 3 && DEPTH <= 256)
    else $error("[%m]: DEPTH (%0d) must be within the range 3 to 256.", DEPTH);

    assert (WIDTH >= 1 && WIDTH <= 1024)
    else $error("[%m]: WIDTH (%0d) must be within the range 1 to 1024.", WIDTH);
  end

  (* ram_style = "distributed" *)
  logic [WIDTH-1:0] mem [0:RamDepth-1];

  logic [AddrWidth-1:0] addr;
  logic [WIDTH-1:0]     mem_read;
  logic [WIDTH-1:0]     dout_r;

  initial begin : p_init
    for (int i = 0; i < RamDepth; i++) begin
      mem[i] = '0;
    end
  end

  // Distributed RAM has an asynchronous read. Keeping the read address equal
  // to the write address makes the value observed before the current write
  // the value captured by dout_r on this event.
  assign mem_read = mem[addr];

  always_ff @(posedge clk) begin
    if (rst) begin
      addr <= '0;
    end else if (cen) begin
      addr <= (addr == AddrWidth'(DelayEntries - 1)) ? '0 : addr + 1'b1;
    end
  end

  // Plain always, not always_ff: mem is also driven by p_init above, which
  // Questa rejects for always_ff (vopt-7061).
  always @(posedge clk) begin
    if (!rst && cen) begin
      mem[addr] <= din;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      dout_r <= '0;
    end else if (cen) begin
      dout_r <= mem_read;
    end
  end

  assign dout = dout_r;

endmodule

`default_nettype wire

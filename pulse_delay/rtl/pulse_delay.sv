`timescale 1 ns / 1 ps
//
`default_nettype none

module pulse_delay #(
    parameter integer WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst,
    //
    input  wire             pulse_in,
    output reg              pulse_out,
    //
    input  wire [WIDTH-1:0] delay
);

  localparam [WIDTH-1:0] DelayOffset = 2;

  reg  [WIDTH-1:0] counter;
  reg  [WIDTH-1:0] counter_in;
  wire [WIDTH-1:0] counter_out;
  wire             counter_empty;
  wire             pulse_v;
  wire             fifo_full;

  always @(posedge clk) begin
    if (rst) begin
      counter <= 'b0;
    end else begin
      counter <= counter + 1'b1;
    end
  end

  always @(posedge clk) begin
    counter_in <= counter + delay + DelayOffset;
  end

  fifo_srl #(
      .FIFO_DEPTH(16),
      .DATA_WIDTH(WIDTH)
  ) i_fifo_srl (
      // Common to write and read
      .clk  (clk),
      .rst  (rst),
      // Write interface
      .wren (pulse_in),
      .din  (counter_in),
      .full (fifo_full),
      // Read interface
      .rden (pulse_v),
      .dout (counter_out),
      .empty(counter_empty)
  );

  assign pulse_v = ~counter_empty && (counter == counter_out);

  always @(posedge clk) begin
    if (!rst && pulse_in && fifo_full) begin
      $error("[%m]: pulse delay FIFO overflow.");
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      pulse_out <= 1'b0;
    end else begin
      pulse_out <= pulse_v;
    end
  end

endmodule

`default_nettype wire

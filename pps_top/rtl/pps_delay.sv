// File: pps_delay.sv
// Brief: Delay the input strobe for some clock ticks.
`timescale 1 ns / 1 ps
//
`default_nettype none

module pps_delay (
    input var         clk,
    input var         rst,
    //
    input var         sync_in,       // required 10ms strobe
    //
    output var        strobe_10ms,
    //
    input var  [22:0] ctrl_offset
);

  logic [22:0] sample_cnt;

  // 10 ms strobe

  always_ff @(posedge clk) begin
    if (rst) begin
      sample_cnt <= '0;
    end else if (sync_in) begin
      sample_cnt <= '0;
    end else if (~&sample_cnt) begin
      sample_cnt <= sample_cnt + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      strobe_10ms <= 1'b0;
    end else begin
      strobe_10ms <= (sample_cnt == ctrl_offset);
    end
  end

endmodule

`default_nettype wire

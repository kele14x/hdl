`timescale 1 ns / 1 ps
`default_nettype none

module leds #(parameter C_CLK_FREQ = 100000000) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF LED, ASSOCIATED_RESET rst" *)
    input  wire clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input  wire rst,
    output reg  led
);

    localparam C_LED_OFF = 0;
    localparam C_LED_ON  = 1;

    localparam C_CNT_MAX   = C_CLK_FREQ - 1   ;
    localparam C_CNT_WIDTH = $clog2(C_CNT_MAX);

    reg [C_CNT_WIDTH-1:0] cnt;

    always @ (posedge clk) begin
        if (rst) begin
            cnt <= 'd0;
        end else begin
            cnt <= (cnt == C_CNT_MAX) ? 0 : cnt + 1;
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            led <= C_LED_OFF;
        end else begin
            led <= (cnt > C_CNT_MAX / 2) ? C_LED_ON : C_LED_OFF;
        end
    end

endmodule

`default_nettype wire

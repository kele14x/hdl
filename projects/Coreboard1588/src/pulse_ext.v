/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module pulse_ext (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF LED, ASSOCIATED_RESET rst" *)
	input  wire clk     ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	input  wire rst     ,
	input  wire pulse_in,
	output reg  ext_out
);

	reg [9:0] ext_reg;

	always @ (posedge clk) begin
		if (rst) begin
			ext_reg <= 'd0;
		end else if (pulse_in) begin
			ext_reg <= 'd1;
		end else if (ext_reg != 0) begin
			ext_reg <= ext_reg + 1;
			// will go back to 0
		end else begin
			ext_reg <= ext_reg;
		end
	end

	always @ (posedge clk) begin
		ext_out <= |ext_reg;
	end

endmodule

`default_nettype wire

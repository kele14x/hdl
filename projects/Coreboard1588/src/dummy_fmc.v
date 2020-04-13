`timescale 1 ns / 1 ps
`default_nettype none

module dummy_fmc (
    // AXIS
    //-----
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axis, ASSOCIATED_RESET aresetn, FREQ_HZ 125000000" *)
    input  wire        aclk         ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire        aresetn      ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TDATA" *)
    input  wire [55:0] s_axis_tdata ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TVALID" *)
    input  wire        s_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TREADY" *)
    output reg         s_axis_tready,
    // PPS
    input  wire        pps          ,
    // BRAM interface
    //---------------
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram CLK" *)
    output wire        bram_clk     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram RST" *)
    output wire        bram_rst     ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram ADDR" *)
    output reg  [11:0] bram_addr    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram EN" *)
    output reg         bram_en      ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram DOUT" *)
    input  wire [15:0] bram_dout    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram DIN" *)
    output reg  [15:0] bram_din     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram WE" *)
    output reg  [ 1:0] bram_we      ,
    //
    output reg         ts_irq
);

	reg [31:0] counter_s;
	reg [31:0] counter_ns;

	// nano second counter
	always @ (posedge aclk) begin
		if (!aresetn || pps) begin
			counter_ns <= 'd0;
		end else begin
			counter_ns <= (counter_ns == (10**9-8)) ? 0 : counter_ns + 8;
		end
	end

	// second counter
	always @ (posedge aclk) begin
		if (!aresetn) begin
			counter_s <= 'd0;
		end else begin
			counter_s <= (counter_ns == (10**9-8)) ? counter_s + 1 : counter_s;
		end
	end

	localparam C_CLOCK_FREQUECNY = 125000000;
	localparam C_FS_COUNTER_MAX = C_CLOCK_FREQUECNY/1000-1;
	localparam C_FS_COUNTER_WIDTH = $clog2(C_FS_COUNTER_MAX);


	// Write frame to bram
	// -------------------

	always @ (posedge aclk) begin
		if (aresetn) begin
			s_axis_tready <= 1'b0;
		end else begin
			s_axis_tready <= 1'b1;
		end
	end

    // Write 80 byte to BRAM
    //----------------------

    reg [31:0] counter_s_temp;
    reg [31:0] counter_ns_temp;
    reg ads868x_ts_dv, ads868x_ts_dv_d, ads868x_ts_dv_dd, ads868x_ts_dv_d3;
    
    // Move second & nano second counter to temp register
    always @ (posedge aclk) begin
        if (s_axis_tvalid && s_axis_tdata[23:16] == 8'h3F) begin
            counter_s_temp  <= counter_s;
            counter_ns_temp <= counter_ns;
        end
    end

    always @ (posedge aclk) begin
        ads868x_ts_dv    <= (s_axis_tvalid && s_axis_tdata[23:16] == 8'h3F);
        ads868x_ts_dv_d  <= ads868x_ts_dv;
        ads868x_ts_dv_dd <= ads868x_ts_dv_d;
        ads868x_ts_dv_d3 <= ads868x_ts_dv_dd;
    end

    // BRAM clock
    assign bram_clk = aclk;

    // BRAM reset
    assign bram_rst = !aresetn;

    // BRAM dout
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_din <= 'd0;
        end else begin
            if (ads868x_ts_dv) begin
                bram_din <= counter_s_temp[31:16];
            end else if (ads868x_ts_dv_d) begin
                bram_din <= counter_s_temp[15: 0];
            end else if (ads868x_ts_dv_dd) begin
                bram_din <= counter_ns_temp[31:16];
            end else if (ads868x_ts_dv_d3) begin
                bram_din <= counter_ns_temp[15: 0];
            end else if (s_axis_tvalid && s_axis_tdata[23:16] <= 31) begin
                bram_din <= s_axis_tdata[15:0];
            end else begin
                bram_din <= 'd0;
            end
        end
    end

    // BRAM enable
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_en <= 1'b0;
        end else begin
            bram_en <= ads868x_ts_dv || ads868x_ts_dv_d || ads868x_ts_dv_dd || 
                ads868x_ts_dv_d3 || s_axis_tvalid && s_axis_tdata[23:16] <= 31;
        end
    end

    // BRAM write enable
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_we <= 2'b00;
        end else begin
            bram_we <= (ads868x_ts_dv || ads868x_ts_dv_d || ads868x_ts_dv_dd || 
                ads868x_ts_dv_d3 || s_axis_tvalid && s_axis_tdata[23:16] <= 31) ? 2'b11 : 2'b00;
        end
    end

    // BRAM address enable
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_addr <= 'd0;
        end else begin
            bram_addr <= 
                ads868x_ts_dv     ? 0 : 
                ads868x_ts_dv_d   ? 1 : 
                ads868x_ts_dv_dd  ? 2 : 
                ads868x_ts_dv_d3  ? 3 : 
                s_axis_tvalid && s_axis_tdata[23:16] <= 31 ? s_axis_tdata[23:16] + 4 :
                0;
        end
    end

    //
    reg [8:0] ts_irq_ext;
    
    always @ (posedge aclk) begin
        if (!aresetn) begin
            ts_irq_ext <= 'd0;
        end else begin
            if (s_axis_tvalid && s_axis_tdata[23:16] == 31) begin
                ts_irq_ext <= 'd1;
            end else if (|ts_irq_ext) begin
                ts_irq_ext <= ts_irq_ext + 1;
            end 
        end 
    end

    // 
    always @ (posedge aclk) begin
        if (!aresetn) begin
            ts_irq <= 1'b0;
        end else begin
            ts_irq <= |ts_irq_ext;
        end
    end
            

endmodule

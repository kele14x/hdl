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
    input  wire [15:0] s_axis_tdata ,
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

	// Sample point counter
	// which should be fixed to 1 kHz

	reg [C_FS_COUNTER_WIDTH-1:0] counter_fs;

	always @ (posedge aclk) begin
		if (!aresetn || pps) begin
			counter_fs <= 1'b0;
		end else begin
			counter_fs <= (counter_fs == C_FS_COUNTER_MAX) ? 0 : counter_fs + 1;
		end
	end

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

    // Move second & nano second counter to temp register
    always @ (posedge aclk) begin
        if (counter_fs == 99) begin
            counter_s_temp <= counter_s;
            counter_ns_temp <= counter_ns;
        end
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
            case (counter_fs)
                100     : bram_din <= counter_s_temp[31:16];
                101     : bram_din <= counter_s_temp[15: 0];
                102     : bram_din <= counter_ns_temp[31:16];
                103     : bram_din <= counter_ns_temp[15: 0];
                // TCH 0 ~ 15
                104     : bram_din <= s_axis_tdata;
                105     : bram_din <= s_axis_tdata;
                106     : bram_din <= s_axis_tdata;
                107     : bram_din <= s_axis_tdata;
                108     : bram_din <= s_axis_tdata;
                109     : bram_din <= s_axis_tdata;
                110     : bram_din <= s_axis_tdata;
                111     : bram_din <= s_axis_tdata;
                112     : bram_din <= s_axis_tdata;
                113     : bram_din <= s_axis_tdata;
                114     : bram_din <= s_axis_tdata;
                115     : bram_din <= s_axis_tdata;
                116     : bram_din <= s_axis_tdata;
                117     : bram_din <= s_axis_tdata;
                118     : bram_din <= s_axis_tdata;
                119     : bram_din <= s_axis_tdata;
                // PCH 0 ~ 15
                120     : bram_din <= s_axis_tdata;
                121     : bram_din <= s_axis_tdata;
                122     : bram_din <= s_axis_tdata;
                123     : bram_din <= s_axis_tdata;
                124     : bram_din <= s_axis_tdata;
                125     : bram_din <= s_axis_tdata;
                126     : bram_din <= s_axis_tdata;
                127     : bram_din <= s_axis_tdata;
                128     : bram_din <= s_axis_tdata;
                129     : bram_din <= s_axis_tdata;
                130     : bram_din <= s_axis_tdata;
                131     : bram_din <= s_axis_tdata;
                132     : bram_din <= s_axis_tdata;
                133     : bram_din <= s_axis_tdata;
                134     : bram_din <= s_axis_tdata;
                135     : bram_din <= s_axis_tdata;
                //
                136     : bram_din <= s_axis_tdata;
                137     : bram_din <= s_axis_tdata;
                138     : bram_din <= s_axis_tdata;
                139     : bram_din <= s_axis_tdata;
                //
                default : bram_din <= 'd0;
            endcase // counter_fs
        end
    end

    // BRAM enable
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_en <= 1'b0;
        end else begin
            bram_en <= (counter_fs >= 100 && counter_fs <= 139);
        end
    end

    // BRAM write enable
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_we <= 2'b00;
        end else begin
            bram_we <= (counter_fs >= 100 && counter_fs <= 139) ? 2'b11 : 2'b00;
        end
    end

    // BRAM address enable
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_addr <= 'd0;
        end else begin
            bram_addr <= (counter_fs >= 100 && counter_fs <= 139) ? (counter_fs - 100) : 'd0;
        end
    end

    // 
    always @ (posedge aclk) begin
        if (!aresetn) begin
            ts_irq <= 1'b0;
        end else begin
            ts_irq <= (counter_fs >= 150 && counter_fs <= 400);
        end
    end
            

endmodule

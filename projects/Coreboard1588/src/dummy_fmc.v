`timescale 1 ns / 1 ps
`default_nettype none

//****************************************************************************
// s00_axis_tdata[31:0]:
//  [31:24] Not used
//  [23:16] Channel ID
//  [15: 0] ADC data
//
// s01_axis_tdata[31:0]
//   [31:24] Channel ID
//   [23: 0] ADC data
//****************************************************************************

module dummy_fmc (
    // AXIS
    //-----
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S00_AXIS:S01_AXIS, ASSOCIATED_RESET aresetn, FREQ_HZ 125000000" *)
    input  wire        aclk           ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire        aresetn        ,
    //
    // ADS868x S_AXIS
    //----------
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S00_AXIS TDATA" *)
    input  wire [31:0] s00_axis_tdata ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S00_AXIS TVALID" *)
    input  wire        s00_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S00_AXIS TREADY" *)
    output reg         s00_axis_tready,
    //
    // ADS124x S_AXIS
    //---------------
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S01_AXIS TDATA" *)
    input  wire [31:0] s01_axis_tdata ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S01_AXIS TVALID" *)
    input  wire        s01_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S01_AXIS TREADY" *)
    output reg         s01_axis_tready,
    //
    // PPS
    //
    input  wire        pps            ,
    // BRAM interface
    //---------------
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram CLK" *)
    output wire        bram_clk       ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram RST" *)
    output wire        bram_rst       ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram ADDR" *)
    output reg  [11:0] bram_addr      ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram EN" *)
    output reg         bram_en        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram DOUT" *)
    input  wire [15:0] bram_dout      ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram DIN" *)
    output reg  [15:0] bram_din       ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram WE" *)
    output reg  [ 1:0] bram_we        ,
    //
    output reg         ts_irq
);

    // Sencond & Nanosecond internal counter
    //--------------------------------------

	localparam C_CLK_FREQ = 125000000;
	localparam C_NS_CNT_INC = 10**9 / C_CLK_FREQ;
	localparam C_NS_CNT_MAX = 10**9 - C_NS_CNT_INC;

	reg [31:0] counter_s;  // Sample tick s
	reg [31:0] counter_ns; // Sample tick ns

	// Nanosecond counter
	// Real nanosecond value range from 0 to last tick
	always @ (posedge aclk) begin
		if (!aresetn || pps) begin
			counter_ns <= 'd0;
		end else begin
			counter_ns <= (counter_ns == C_NS_CNT_MAX) ? 0 : counter_ns + C_NS_CNT_INC;
		end
	end

	// Second counter
	// Real second value range from 0 to maximum, it should be enough for use
	always @ (posedge aclk) begin
		if (!aresetn) begin
			counter_s <= 'd0;
		end else begin
			counter_s <= (counter_ns == C_NS_CNT_MAX) ? counter_s + 1 : counter_s;
		end
	end

    // Data Buffer
    //-------------
	// total 40 half word (80 byte)

    reg [31:0] ts_s_reg;  // Sample time second value
    reg [31:0] ts_ns_reg; // Sample time nanosacond value

    reg [15:0] pch_data[0:15]; // PCH data from ADS868x
    reg [15:0] tch_data[0:15]; // TCH data from ADS868x

    reg [23:0] pt100[0:1]; // PT100 value from ADS124x

    // Move second & nano second counter to temp register
    always @ (posedge aclk) begin
        if (s00_axis_tvalid && s00_axis_tdata[23:16] == 8'hFF) begin
            ts_s_reg  <= counter_s;
            ts_ns_reg <= counter_ns;
        end
    end

    // Save PCH/TCH value to temp register
    // s00_axis_tdata[23:16] is MUX value, where:
    // [1:0] is ADS868x internal MUX (4 to 1)
    // [4:2] is external MUX (8 to 1)
    // Mapping is need due to PCB rounting
    // ID    0        1        2        3
    //     TCH8     PCH8     TCH0     PCH0
    // ID    4        5        6        7
    //     TCH9     PCH9     TCH1     PCH1
    // ...
    // ID   28       29       30       31
    //     TCH15    PCH15    TCH7     PCH7

    always @ (posedge aclk) begin: p_tpch
        integer i;
        integer pid, tid;
        for (i = 0; i < 16; i = i + 1) begin
            // pid is PCH MUX value, see PCB for detail
            pid = (i < 8) ? (i * 4 + 3) : ((i - 8) * 4 + 1);
            if (s00_axis_tvalid && s00_axis_tdata[23:16] == pid) begin
                pch_data[i] <= s00_axis_tdata[15:0];
            end
            // tid is TCH MUX value, see PCB for detail
            tid = (i < 8) ? (i * 4 + 2) : ((i - 8) * 4 + 0);
            if (s00_axis_tvalid && s00_axis_tdata[23:16] == tid) begin
                tch_data[i] <= s00_axis_tdata[15:0];
            end
        end
    end

    // Save PT100 value to buffer
    // ID = 0: Channel 0
    // ID = 1: Channel 1

    always @ (posedge aclk) begin: p_pt100
        if (s01_axis_tvalid && s01_axis_tdata[31:24] == 8'd0) begin
            pt100[0] <= s01_axis_tdata[23:0];
        end
        if (s01_axis_tvalid && s01_axis_tdata[31:24] == 8'd0) begin
            pt100[1] <= s01_axis_tdata[23:0];
        end
    end

	always @ (posedge aclk) begin
		if (!aresetn) begin
			s00_axis_tready <= 1'b0;
		end else begin
			s00_axis_tready <= 1'b1;
		end
	end

    always @ (posedge aclk) begin
        if (!aresetn) begin
            s01_axis_tready <= 1'b0;
        end else begin
            s01_axis_tready <= 1'b1;
        end
    end


    // Write 80 byte to BRAM
    //----------------------


    reg [7:0] bram_wr_state;

    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_wr_state <= {8{1'b1}}; // Reset state
        end else if (s00_axis_tvalid && s00_axis_tdata[23:16] == 8'd31) begin
            // last P/TCH data is writed into buffer
            bram_wr_state <= 0;
        end else if (bram_wr_state < 40) begin
            bram_wr_state <= bram_wr_state + 1;
        end else begin
            bram_wr_state <= {8{1'b1}};
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
            // {halfword [0], halfword [1]}: Second
            if (bram_wr_state == 0) begin
                bram_din <= ts_s_reg[31:16];
            end else if (bram_wr_state == 1) begin
                bram_din <= ts_s_reg[15: 0];
            // {halfword [2], halfword [3]}: Nanosecond
            end else if (bram_wr_state == 2) begin
                bram_din <= ts_ns_reg[31:16];
            end else if (bram_wr_state == 3) begin
                bram_din <= ts_ns_reg[15: 0];
            // {halfword [4] ~ halfword [19]}: PCH[0] ~ PCH[15]
            end else if (bram_wr_state <= 19) begin
                bram_din <= pch_data[bram_wr_state-4];
            // {halfword [20] ~ halfword [35]}: TCH[0] ~ TCH[15]
            end else if (bram_wr_state <= 35) begin
                bram_din <= tch_data[bram_wr_state-20];
            // {halfword [36], halfword [37]}: PT100[0]
            end else if (bram_wr_state == 36) begin
                bram_din <= {8'b0, pt100[0][23:16]};
            end else if (bram_wr_state == 37) begin
                bram_din <= pt100[0][15:0];
            // {halfword [38], halfword [39]}: PT100[1]
            end else if (bram_wr_state == 38) begin
                bram_din <= {8'b0, pt100[1][23:16]};
            end else if (bram_wr_state == 39) begin
                bram_din <= pt100[1][15:0];
            //
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
            bram_en <= (bram_wr_state >=0 && bram_wr_state <= 39);
        end
    end

    // BRAM write enable
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_we <= 2'b00;
        end else begin
            bram_we <= (bram_wr_state >=0 && bram_wr_state <= 39) ? 2'b11 : 2'b00;
        end
    end

    // BRAM address enable
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_addr <= 'd0;
        end else begin
            bram_addr <= (bram_wr_state >=0 && bram_wr_state <= 39) ? bram_wr_state : 'd0;
        end
    end

    // IRQ signal pulse width extern
    reg [8:0] ts_irq_ext;

    always @ (posedge aclk) begin
        if (!aresetn) begin
            ts_irq_ext <= 'd0;
        end else begin
            if (bram_wr_state == 39) begin
                ts_irq_ext <= 'd1;
            end else if (|ts_irq_ext) begin
                ts_irq_ext <= ts_irq_ext + 1;
            end
        end
    end

    // IRQ signal
    always @ (posedge aclk) begin
        if (!aresetn) begin
            ts_irq <= 1'b0;
        end else begin
            ts_irq <= |ts_irq_ext;
        end
    end


endmodule

`default_nettype wire

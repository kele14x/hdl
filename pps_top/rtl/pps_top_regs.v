// File: pps_top_regs.v
// Brief: Register block generate for pps_top
`timescale 1 ns / 1 ps
//
`default_nettype none

module pps_top_regs (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    //
    input  wire [ 6:0] s_axi_awaddr,
    /* verilator lint_off UNUSED */
    input  wire [ 2:0] s_axi_awprot,
    /* verilator lint_on UNUSED */
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    //
    input  wire [31:0] s_axi_wdata,
    input  wire [ 3:0] s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    //
    output wire [ 1:0] s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    //
    input  wire [ 6:0] s_axi_araddr,
    /* verilator lint_off UNUSED */
    input  wire [ 2:0] s_axi_arprot,
    /* verilator lint_on UNUSED */
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    //
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    // ctrl.rst,
    output wire [ 0:0] ctrl_rst_out,
    // adj_ns.val,
    output wire [31:0] adj_ns_val_out,
    // adj_valid.val,
    output wire [ 0:0] adj_valid_val_out,
    // freq.val,
    output wire [31:0] freq_val_out,
    // gettime.sh.val,
    input  wire [15:0] gettime_sh_val_in,
    // gettime.sl.val,
    input  wire [31:0] gettime_sl_val_in,
    // gettime.ns.val,
    input  wire [31:0] gettime_ns_val_in,
    // gettime.v.val,
    output wire [ 0:0] gettime_v_val_out,
    // settime.sh.val,
    output wire [15:0] settime_sh_val_out,
    // settime.sl.val,
    output wire [31:0] settime_sl_val_out,
    // settime.ns.val,
    output wire [31:0] settime_ns_val_out,
    // settime.v.val,
    output wire [ 0:0] settime_v_val_out,
    // pps_offset.val,
    input  wire [31:0] pps_offset_val_in,
    // ts_cnt.val,
    input  wire [31:0] ts_cnt_val_in,
    // ts_offset_l.val,
    input  wire [31:0] ts_offset_l_val_in,
    // ts_offset_h.val,
    input  wire [15:0] ts_offset_h_val_in
);

    wire        aclk;
    wire        aresetn;

    reg         init;

    wire        aw_hsk;
    reg  [ 6:0] aw_addr;
    reg         aw_ready;
    reg         aw_req;
    reg         aw_ack;

    wire        w_hsk;
    reg  [31:0] w_data;
    reg  [ 3:0] w_strb;
    reg         w_ready;
    reg         w_req;
    reg         w_ack;

    wire        b_hsk;
    reg  [ 1:0] b_resp;
    reg         b_valid;

    wire        ar_hsk;
    reg  [ 6:0] ar_addr;
    reg         ar_ready;
    reg         ar_req;
    reg         ar_ack;

    wire        r_hsk;
    reg  [31:0] r_data;
    reg  [ 1:0] r_resp;
    reg         r_valid;

    // Internal interface signals

    /* verilator lint_off UNUSED */
    reg  [ 6:0] int_addr;
    /* verilator lint_on UNUSED */
    reg  [31:0] int_wr_data;
    /* verilator lint_off UNUSED */
    reg  [ 3:0] int_wr_strb;
    /* verilator lint_on UNUSED */
    reg         int_wr_en;
    reg         int_rd_en;

    reg         int_wr_ack;
    reg         int_wr_err;

    reg         int_rd_ack;
    reg         int_rd_err;
    reg  [31:0] int_rd_data;


    //--------------------------------------------------------------------------
    // AXI4-Lite Interface
    //--------------------------------------------------------------------------

    assign aclk    = s_axi_aclk;
    assign aresetn = s_axi_aresetn;

    // Out of reset initialize

    always @(posedge aclk) begin
        if (!aresetn) begin
            init <= 1'b0;
        end else begin
            init <= 1'b1;
        end
    end


    // Write address

    assign aw_hsk        = (s_axi_awvalid & s_axi_awready);
    assign s_axi_awready = aw_ready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_addr <= '0;
        end else if (aw_hsk == 1'b1) begin
            aw_addr <= s_axi_awaddr;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_ready <= 1'b0;
        end else if (init == 1'b0) begin
            aw_ready <= 1'b1;
        end else if (b_hsk) begin
            aw_ready <= 1'b1;
        end else if (aw_hsk) begin
            aw_ready <= 1'b0;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_req <= 1'b0;
        end else if (aw_ack) begin
            aw_req <= 1'b0;
        end else if (aw_hsk) begin
            aw_req <= 1'b1;
        end
    end


    // Write data

    assign w_hsk        = (s_axi_wvalid & s_axi_wready);
    assign s_axi_wready = w_ready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            w_data <= '0;
        end else if (w_hsk == 1'b1) begin
            w_data <= s_axi_wdata;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            w_strb <= '0;
        end else if (w_hsk == 1'b1) begin
            w_strb <= s_axi_wstrb;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            w_ready <= 1'b0;
        end else if (init == 1'b0) begin
            w_ready <= 1'b1;
        end else if (b_hsk) begin
            w_ready <= 1'b1;
        end else if (w_hsk) begin
            w_ready <= 1'b0;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            w_req <= 1'b0;
        end else if (w_ack) begin
            w_req <= 1'b0;
        end else if (w_hsk) begin
            w_req <= 1'b1;
        end
    end


    // Write response

    assign b_hsk        = (s_axi_bvalid && s_axi_bready);
    assign s_axi_bresp  = b_resp;
    assign s_axi_bvalid = b_valid;

    always @(posedge aclk) begin
        if (!aresetn) begin
            b_resp <= '0;
        end else if (int_wr_ack) begin
            b_resp <= { 2 { int_wr_err } };
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            b_valid <= 1'b0;
        end else if (b_hsk) begin
            b_valid <= 1'b0;
        end else if (int_wr_ack) begin
            b_valid <= 1'b1;
        end
    end


    // Read address

    assign ar_hsk        = (s_axi_arvalid & s_axi_arready);
    assign s_axi_arready = ar_ready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ar_addr <= '0;
        end else if (ar_hsk == 1'b1) begin
            ar_addr <= s_axi_araddr;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            ar_ready <= 1'b0;
        end else if (init == 1'b0) begin
            ar_ready <= 1'b1;
        end else if (r_hsk) begin
            ar_ready <= 1'b1;
        end else if (ar_hsk) begin
            ar_ready <= 1'b0;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            ar_req <= 1'b0;
        end else if (ar_ack) begin
            ar_req <= 1'b0;
        end else if (ar_hsk) begin
            ar_req <= 1'b1;
        end
    end


    // Read response

    assign r_hsk        = (s_axi_rvalid && s_axi_rready);
    assign s_axi_rdata  = r_data;
    assign s_axi_rresp  = r_resp;
    assign s_axi_rvalid = r_valid;

    always @(posedge aclk) begin
        if (!aresetn) begin
            r_data <= '0;
        end else if (int_rd_ack) begin
            r_data <= int_rd_data;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            r_resp <= '0;
        end else if (int_rd_ack) begin
            r_resp <= { 2 { int_rd_err } };
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            r_valid <= 1'b0;
        end else if (r_hsk) begin
            r_valid <= 1'b0;
        end else if (int_rd_ack) begin
            r_valid <= 1'b1;
        end
    end


    // Internal interface

    always @(*) begin
        if (aw_req && w_req) begin
            aw_ack = 1'b1;
            w_ack  = 1'b1;
        end else begin
            aw_ack = 1'b0;
            w_ack  = 1'b0;
        end
    end

    always @(*) begin
        if (aw_req && w_req) begin
            ar_ack = 1'b0;
        end else if (ar_req) begin
            ar_ack = 1'b1;
        end else begin
            ar_ack = 0;
        end
    end

    always @(*) begin
        if (aw_req && w_req) begin
            int_addr = aw_addr;
        end else if (ar_req) begin
            int_addr = ar_addr;
        end else begin
            int_addr = 0;
        end
    end

    always @(*) begin
      int_wr_data = w_data;
    end

    always @(*) begin
      int_wr_strb = w_strb;
    end

    always @(*) begin
        if (aw_req && w_req) begin
            int_wr_en = 1'b1;
        end else begin
            int_wr_en = 1'b0;
        end
    end

    always @(*) begin
        if (aw_req && w_req) begin
            int_rd_en = 1'b0;
        end else if (ar_req) begin
            int_rd_en = 1'b1;
        end else begin
            int_rd_en = 1'b0;
        end
    end


    //--------------------------------------------------------------------------
    // Address decoder
    //--------------------------------------------------------------------------

    wire version_val_strb;

    assign version_val_strb = (int_addr[6:2] == 'h0);

    wire ctrl_rst_strb;

    assign ctrl_rst_strb = (int_addr[6:2] == 'h1);

    wire adj_ns_val_strb;

    assign adj_ns_val_strb = (int_addr[6:2] == 'h4);

    wire adj_valid_val_strb;

    assign adj_valid_val_strb = (int_addr[6:2] == 'h5);

    wire freq_val_strb;

    assign freq_val_strb = (int_addr[6:2] == 'h6);

    wire gettime_sh_val_strb;

    assign gettime_sh_val_strb = (int_addr[6:2] == 'h8);

    wire gettime_sl_val_strb;

    assign gettime_sl_val_strb = (int_addr[6:2] == 'h9);

    wire gettime_ns_val_strb;

    assign gettime_ns_val_strb = (int_addr[6:2] == 'ha);

    wire gettime_v_val_strb;

    assign gettime_v_val_strb = (int_addr[6:2] == 'hb);

    wire settime_sh_val_strb;

    assign settime_sh_val_strb = (int_addr[6:2] == 'hc);

    wire settime_sl_val_strb;

    assign settime_sl_val_strb = (int_addr[6:2] == 'hd);

    wire settime_ns_val_strb;

    assign settime_ns_val_strb = (int_addr[6:2] == 'he);

    wire settime_v_val_strb;

    assign settime_v_val_strb = (int_addr[6:2] == 'hf);

    wire pps_offset_val_strb;

    assign pps_offset_val_strb = (int_addr[6:2] == 'h10);

    wire ts_cnt_val_strb;

    assign ts_cnt_val_strb = (int_addr[6:2] == 'h14);

    wire ts_offset_l_val_strb;

    assign ts_offset_l_val_strb = (int_addr[6:2] == 'h15);

    wire ts_offset_h_val_strb;

    assign ts_offset_h_val_strb = (int_addr[6:2] == 'h16);

    always @(*) begin
        int_wr_ack = int_wr_en;
    end

    always @(*) begin
        int_wr_err = 1'b1;
        if (int_addr[6:2] == 'h1) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[6:2] == 'h4) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[6:2] == 'h5) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[6:2] == 'h6) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[6:2] == 'hb) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[6:2] == 'hc) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[6:2] == 'hd) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[6:2] == 'he) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[6:2] == 'hf) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[6:2] == 'h10) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[6:2] == 'h14) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[6:2] == 'h15) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[6:2] == 'h16) begin
            int_wr_err = 1'b0;
        end
    end

    always @(posedge aclk) begin
        int_rd_ack <= int_rd_en;
    end

    always @(posedge aclk) begin
        int_rd_err <= 1'b1;
        if (int_addr[6:2] == 'h0) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'h1) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'h4) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'h5) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'h6) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'h8) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'h9) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'ha) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'hb) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'hc) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'hd) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'he) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'hf) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'h10) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'h14) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'h15) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[6:2] == 'h16) begin
            int_rd_err <= 1'b0;
        end
    end


    //--------------------------------------------------------------------------
    // Field logic
    //--------------------------------------------------------------------------

    // Field version.val @'h0[31:0]

    reg [31:0] version_val_value;

    initial begin
        version_val_value = 'h20230922;
    end

    // Field ctrl.rst @'h4[0:0]

    reg [0:0] ctrl_rst_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ctrl_rst_value <= 'h0;
        end else if (int_wr_en && ctrl_rst_strb) begin
            ctrl_rst_value <= int_wr_data[0:0];
        end
    end

    assign ctrl_rst_out = ctrl_rst_value;

    // Field adj_ns.val @'h10[31:0]

    reg [31:0] adj_ns_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            adj_ns_val_value <= 'h0;
        end else if (int_wr_en && adj_ns_val_strb) begin
            adj_ns_val_value <= int_wr_data[31:0];
        end
    end

    assign adj_ns_val_out = adj_ns_val_value;

    // Field adj_valid.val @'h14[0:0]

    reg [0:0] adj_valid_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            adj_valid_val_value <= 'h0;
        end else if (int_wr_en && adj_valid_val_strb) begin
            adj_valid_val_value <= int_wr_data[0:0];
        end
    end

    assign adj_valid_val_out = adj_valid_val_value;

    // Field freq.val @'h18[31:0]

    reg [31:0] freq_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            freq_val_value <= 'h0;
        end else if (int_wr_en && freq_val_strb) begin
            freq_val_value <= int_wr_data[31:0];
        end
    end

    assign freq_val_out = freq_val_value;

    // Field gettime.sh.val @'h20[15:0]

    reg [15:0] gettime_sh_val_value;

    always @(*) begin
        gettime_sh_val_value = gettime_sh_val_in;
    end

    // Field gettime.sl.val @'h24[31:0]

    reg [31:0] gettime_sl_val_value;

    always @(*) begin
        gettime_sl_val_value = gettime_sl_val_in;
    end

    // Field gettime.ns.val @'h28[31:0]

    reg [31:0] gettime_ns_val_value;

    always @(*) begin
        gettime_ns_val_value = gettime_ns_val_in;
    end

    // Field gettime.v.val @'h2c[0:0]

    reg [0:0] gettime_v_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            gettime_v_val_value <= 'h0;
        end else if (int_wr_en && gettime_v_val_strb) begin
            gettime_v_val_value <= int_wr_data[0:0];
        end
    end

    assign gettime_v_val_out = gettime_v_val_value;

    // Field settime.sh.val @'h30[15:0]

    reg [15:0] settime_sh_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            settime_sh_val_value <= 'h0;
        end else if (int_wr_en && settime_sh_val_strb) begin
            settime_sh_val_value <= int_wr_data[15:0];
        end
    end

    assign settime_sh_val_out = settime_sh_val_value;

    // Field settime.sl.val @'h34[31:0]

    reg [31:0] settime_sl_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            settime_sl_val_value <= 'h0;
        end else if (int_wr_en && settime_sl_val_strb) begin
            settime_sl_val_value <= int_wr_data[31:0];
        end
    end

    assign settime_sl_val_out = settime_sl_val_value;

    // Field settime.ns.val @'h38[31:0]

    reg [31:0] settime_ns_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            settime_ns_val_value <= 'h0;
        end else if (int_wr_en && settime_ns_val_strb) begin
            settime_ns_val_value <= int_wr_data[31:0];
        end
    end

    assign settime_ns_val_out = settime_ns_val_value;

    // Field settime.v.val @'h3c[0:0]

    reg [0:0] settime_v_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            settime_v_val_value <= 'h0;
        end else if (int_wr_en && settime_v_val_strb) begin
            settime_v_val_value <= int_wr_data[0:0];
        end
    end

    assign settime_v_val_out = settime_v_val_value;

    // Field pps_offset.val @'h40[31:0]

    reg [31:0] pps_offset_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            pps_offset_val_value <= 'h0;
        end else if (int_wr_en && pps_offset_val_strb) begin
            pps_offset_val_value <= int_wr_data[31:0];
        end else begin
            pps_offset_val_value <= pps_offset_val_in;
        end
    end

    // Field ts_cnt.val @'h50[31:0]

    reg [31:0] ts_cnt_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ts_cnt_val_value <= 'h0;
        end else if (int_wr_en && ts_cnt_val_strb) begin
            ts_cnt_val_value <= int_wr_data[31:0];
        end else begin
            ts_cnt_val_value <= ts_cnt_val_in;
        end
    end

    // Field ts_offset_l.val @'h54[31:0]

    reg [31:0] ts_offset_l_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ts_offset_l_val_value <= 'h0;
        end else if (int_wr_en && ts_offset_l_val_strb) begin
            ts_offset_l_val_value <= int_wr_data[31:0];
        end else begin
            ts_offset_l_val_value <= ts_offset_l_val_in;
        end
    end

    // Field ts_offset_h.val @'h58[15:0]

    reg [15:0] ts_offset_h_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ts_offset_h_val_value <= 'h0;
        end else if (int_wr_en && ts_offset_h_val_strb) begin
            ts_offset_h_val_value <= int_wr_data[15:0];
        end else begin
            ts_offset_h_val_value <= ts_offset_h_val_in;
        end
    end


    //--------------------------------------------------------------------------
    // Memory logic
    //--------------------------------------------------------------------------


    //--------------------------------------------------------------------------
    // Register readback
    //--------------------------------------------------------------------------

    reg [31:0] field_rd_data;
    reg [31:0] field_rd_data_next;

    reg        field_strb;

    always @(*) begin
        field_rd_data_next = '0;
        if (int_rd_en && version_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | version_val_value;
        end
        if (int_rd_en && ctrl_rst_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | ctrl_rst_value;
        end
        if (int_rd_en && adj_ns_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | adj_ns_val_value;
        end
        if (int_rd_en && adj_valid_val_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | adj_valid_val_value;
        end
        if (int_rd_en && freq_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | freq_val_value;
        end
        if (int_rd_en && gettime_sh_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | gettime_sh_val_value;
        end
        if (int_rd_en && gettime_sl_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | gettime_sl_val_value;
        end
        if (int_rd_en && gettime_ns_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | gettime_ns_val_value;
        end
        if (int_rd_en && gettime_v_val_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | gettime_v_val_value;
        end
        if (int_rd_en && settime_sh_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | settime_sh_val_value;
        end
        if (int_rd_en && settime_sl_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | settime_sl_val_value;
        end
        if (int_rd_en && settime_ns_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | settime_ns_val_value;
        end
        if (int_rd_en && settime_v_val_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | settime_v_val_value;
        end
        if (int_rd_en && pps_offset_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | pps_offset_val_value;
        end
        if (int_rd_en && ts_cnt_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ts_cnt_val_value;
        end
        if (int_rd_en && ts_offset_l_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ts_offset_l_val_value;
        end
        if (int_rd_en && ts_offset_h_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | ts_offset_h_val_value;
        end
    end

    always @(posedge aclk) begin
        field_rd_data <= field_rd_data_next;
    end

    always @(posedge aclk) begin
        field_strb <= 1'b0;
        if (int_rd_en && version_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ctrl_rst_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && adj_ns_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && adj_valid_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && freq_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && gettime_sh_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && gettime_sl_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && gettime_ns_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && gettime_v_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && settime_sh_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && settime_sl_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && settime_ns_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && settime_v_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && pps_offset_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ts_cnt_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ts_offset_l_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ts_offset_h_val_strb) begin
            field_strb <= 1'b1;
        end
    end

    always @(*) begin
        int_rd_data = '0;
        if (field_strb) begin
            int_rd_data = int_rd_data | field_rd_data;
        end
    end

endmodule

`default_nettype wire

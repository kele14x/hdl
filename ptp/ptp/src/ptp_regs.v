// File: ptp_regs.v
// Brief: Register block generate for ptp
`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_regs (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    //
    input  wire [ 5:0] s_axi_awaddr,
    input  wire [ 2:0] s_axi_awprot,
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
    input  wire [ 5:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    //
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    // ctrl.rst,
    output wire [ 0:0] ctrl_rst_out,
    // ctrl.enable,
    output wire [ 0:0] ctrl_enable_out,
    // mode.slave,
    output wire [ 0:0] mode_slave_out,
    // rtc_offset_set.set,
    output wire [ 0:0] rtc_offset_set_set_out,
    // rtc_offset_ns.val,
    output wire [31:0] rtc_offset_ns_val_out,
    // rtc_offset_s_l.val,
    output wire [31:0] rtc_offset_s_l_val_out,
    // rtc_offset_s_h.val,
    output wire [15:0] rtc_offset_s_h_val_out,
    // rtc_offset_get.get,
    output wire [ 0:0] rtc_offset_get_get_out,
    // rtc_ns.val,
    input  wire [31:0] rtc_ns_val_in,
    // rtc_s_l.val,
    input  wire [31:0] rtc_s_l_val_in,
    // rtc_s_h.val,
    input  wire [15:0] rtc_s_h_val_in
);

    wire        aclk;
    wire        aresetn;

    reg         init;

    wire        aw_hsk;
    reg  [ 5:0] aw_addr;
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
    reg  [ 5:0] ar_addr;
    reg         ar_ready;
    reg         ar_req;
    reg         ar_ack;

    wire        r_hsk;
    reg  [31:0] r_data;
    reg  [ 1:0] r_resp;
    reg         r_valid;

    // Internal interface signals

    reg  [ 5:0] int_addr;
    reg  [31:0] int_wr_data;
    reg  [ 3:0] int_wr_strb;
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
            aw_addr <= 1'sb0;
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
            w_data <= 1'sb0;
        end else if (w_hsk == 1'b1) begin
            w_data <= s_axi_wdata;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            w_strb <= 1'sb0;
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
            b_resp <= 2'b00;
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
            ar_addr <= 1'sb0;
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
            r_data <= 1'sb0;
        end else if (int_rd_ack) begin
            r_data <= int_rd_data;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            r_resp <= 2'b00;
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

    wire ctrl_rst_strb;

    assign ctrl_rst_strb = (int_addr[5:2] == 'h0);

    wire ctrl_enable_strb;

    assign ctrl_enable_strb = (int_addr[5:2] == 'h0);

    wire mode_slave_strb;

    assign mode_slave_strb = (int_addr[5:2] == 'h1);

    wire rtc_offset_set_set_strb;

    assign rtc_offset_set_set_strb = (int_addr[5:2] == 'h8);

    wire rtc_offset_ns_val_strb;

    assign rtc_offset_ns_val_strb = (int_addr[5:2] == 'h9);

    wire rtc_offset_s_l_val_strb;

    assign rtc_offset_s_l_val_strb = (int_addr[5:2] == 'ha);

    wire rtc_offset_s_h_val_strb;

    assign rtc_offset_s_h_val_strb = (int_addr[5:2] == 'hb);

    wire rtc_offset_get_get_strb;

    assign rtc_offset_get_get_strb = (int_addr[5:2] == 'hc);

    wire rtc_ns_val_strb;

    assign rtc_ns_val_strb = (int_addr[5:2] == 'hd);

    wire rtc_s_l_val_strb;

    assign rtc_s_l_val_strb = (int_addr[5:2] == 'he);

    wire rtc_s_h_val_strb;

    assign rtc_s_h_val_strb = (int_addr[5:2] == 'hf);

    always @(*) begin
        int_wr_ack = int_wr_en;
    end

    always @(*) begin
        int_wr_err = 1'b1;
        if (int_addr[5:2] == 'h0) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[5:2] == 'h1) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[5:2] == 'h8) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[5:2] == 'h9) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[5:2] == 'ha) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[5:2] == 'hb) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[5:2] == 'hc) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[5:2] == 'hd) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[5:2] == 'he) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[5:2] == 'hf) begin
            int_wr_err = 1'b0;
        end
    end

    always @(posedge aclk) begin
        int_rd_ack <= int_rd_en;
    end

    always @(posedge aclk) begin
        int_rd_err <= 1'b1;
        if (int_addr[5:2] == 'h0) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[5:2] == 'h1) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[5:2] == 'h8) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[5:2] == 'h9) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[5:2] == 'ha) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[5:2] == 'hb) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[5:2] == 'hc) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[5:2] == 'hd) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[5:2] == 'he) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[5:2] == 'hf) begin
            int_rd_err <= 1'b0;
        end
    end


    //--------------------------------------------------------------------------
    // Field logic
    //--------------------------------------------------------------------------

    // Field ctrl.rst @'h0[0:0]

    reg [0:0] ctrl_rst_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ctrl_rst_value <= 'h0;
        end else if (int_wr_en && ctrl_rst_strb) begin
            ctrl_rst_value <= int_wr_data[0:0];
        end
    end

    assign ctrl_rst_out = ctrl_rst_value;

    // Field ctrl.enable @'h0[8:8]

    reg [0:0] ctrl_enable_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ctrl_enable_value <= 'h0;
        end else if (int_wr_en && ctrl_enable_strb) begin
            ctrl_enable_value <= int_wr_data[8:8];
        end
    end

    assign ctrl_enable_out = ctrl_enable_value;

    // Field mode.slave @'h4[0:0]

    reg [0:0] mode_slave_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            mode_slave_value <= 'h0;
        end else if (int_wr_en && mode_slave_strb) begin
            mode_slave_value <= int_wr_data[0:0];
        end
    end

    assign mode_slave_out = mode_slave_value;

    // Field rtc_offset_set.set @'h20[0:0]

    reg [0:0] rtc_offset_set_set_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            rtc_offset_set_set_value <= 'h0;
        end else if (int_wr_en && rtc_offset_set_set_strb) begin
            rtc_offset_set_set_value <= int_wr_data[0:0];
        end
    end

    assign rtc_offset_set_set_out = rtc_offset_set_set_value;

    // Field rtc_offset_ns.val @'h24[31:0]

    reg [31:0] rtc_offset_ns_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            rtc_offset_ns_val_value <= 'h0;
        end else if (int_wr_en && rtc_offset_ns_val_strb) begin
            rtc_offset_ns_val_value <= int_wr_data[31:0];
        end
    end

    assign rtc_offset_ns_val_out = rtc_offset_ns_val_value;

    // Field rtc_offset_s_l.val @'h28[31:0]

    reg [31:0] rtc_offset_s_l_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            rtc_offset_s_l_val_value <= 'h0;
        end else if (int_wr_en && rtc_offset_s_l_val_strb) begin
            rtc_offset_s_l_val_value <= int_wr_data[31:0];
        end
    end

    assign rtc_offset_s_l_val_out = rtc_offset_s_l_val_value;

    // Field rtc_offset_s_h.val @'h2c[15:0]

    reg [15:0] rtc_offset_s_h_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            rtc_offset_s_h_val_value <= 'h0;
        end else if (int_wr_en && rtc_offset_s_h_val_strb) begin
            rtc_offset_s_h_val_value <= int_wr_data[15:0];
        end
    end

    assign rtc_offset_s_h_val_out = rtc_offset_s_h_val_value;

    // Field rtc_offset_get.get @'h30[0:0]

    reg [0:0] rtc_offset_get_get_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            rtc_offset_get_get_value <= 'h0;
        end else if (int_wr_en && rtc_offset_get_get_strb) begin
            rtc_offset_get_get_value <= int_wr_data[0:0];
        end
    end

    assign rtc_offset_get_get_out = rtc_offset_get_get_value;

    // Field rtc_ns.val @'h34[31:0]

    reg [31:0] rtc_ns_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            rtc_ns_val_value <= 'h0;
        end else if (int_wr_en && rtc_ns_val_strb) begin
            rtc_ns_val_value <= int_wr_data[31:0];
        end else begin
            rtc_ns_val_value <= rtc_ns_val_in;
        end
    end

    // Field rtc_s_l.val @'h38[31:0]

    reg [31:0] rtc_s_l_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            rtc_s_l_val_value <= 'h0;
        end else if (int_wr_en && rtc_s_l_val_strb) begin
            rtc_s_l_val_value <= int_wr_data[31:0];
        end else begin
            rtc_s_l_val_value <= rtc_s_l_val_in;
        end
    end

    // Field rtc_s_h.val @'h3c[15:0]

    reg [15:0] rtc_s_h_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            rtc_s_h_val_value <= 'h0;
        end else if (int_wr_en && rtc_s_h_val_strb) begin
            rtc_s_h_val_value <= int_wr_data[15:0];
        end else begin
            rtc_s_h_val_value <= rtc_s_h_val_in;
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
        field_rd_data_next = 1'sb0;
        if (int_rd_en && ctrl_rst_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | ctrl_rst_value;
        end
        if (int_rd_en && ctrl_enable_strb) begin
            field_rd_data_next[8:8] = field_rd_data_next[8:8] | ctrl_enable_value;
        end
        if (int_rd_en && mode_slave_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | mode_slave_value;
        end
        if (int_rd_en && rtc_offset_set_set_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | rtc_offset_set_set_value;
        end
        if (int_rd_en && rtc_offset_ns_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | rtc_offset_ns_val_value;
        end
        if (int_rd_en && rtc_offset_s_l_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | rtc_offset_s_l_val_value;
        end
        if (int_rd_en && rtc_offset_s_h_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | rtc_offset_s_h_val_value;
        end
        if (int_rd_en && rtc_offset_get_get_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | rtc_offset_get_get_value;
        end
        if (int_rd_en && rtc_ns_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | rtc_ns_val_value;
        end
        if (int_rd_en && rtc_s_l_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | rtc_s_l_val_value;
        end
        if (int_rd_en && rtc_s_h_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | rtc_s_h_val_value;
        end
    end

    always @(posedge aclk) begin
        field_rd_data <= field_rd_data_next;
    end

    always @(posedge aclk) begin
        field_strb <= 1'b0;
        if (int_rd_en && ctrl_rst_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ctrl_enable_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && mode_slave_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && rtc_offset_set_set_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && rtc_offset_ns_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && rtc_offset_s_l_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && rtc_offset_s_h_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && rtc_offset_get_get_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && rtc_ns_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && rtc_s_l_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && rtc_s_h_val_strb) begin
            field_strb <= 1'b1;
        end
    end

    always @(*) begin
        int_rd_data = 1'sb0;
        if (field_strb) begin
            int_rd_data = int_rd_data | field_rd_data;
        end
    end

endmodule

`default_nettype wire

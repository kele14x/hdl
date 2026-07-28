// File: fh_regs.v
// Brief: Register block generate for fh
`timescale 1 ns / 1 ps
//
`default_nettype none

module fh_regs (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    //
    input  wire [ 9:0] s_axi_awaddr,
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
    input  wire [ 9:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    //
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    // ptp_ctrl.master_en,
    output wire [ 0:0] ptp_ctrl_master_en_out,
    // ptp_src_mac_l.val,
    output wire [31:0] ptp_src_mac_l_val_out,
    // ptp_src_mac_h.val,
    output wire [15:0] ptp_src_mac_h_val_out,
    // ptp_domain_number.val,
    output wire [ 7:0] ptp_domain_number_val_out,
    // ptp_utc_offset.val,
    output wire [15:0] ptp_utc_offset_val_out,
    // ptp_log_announce_interval.val,
    output wire [ 7:0] ptp_log_announce_interval_val_out,
    // ptp_log_sync_interval.val,
    output wire [ 7:0] ptp_log_sync_interval_val_out
);

    wire        aclk;
    wire        aresetn;

    reg         init_n;

    wire        aw_hsk;
    reg  [ 9:0] aw_addr;
    reg         aw_ready;
    reg         aw_req;

    wire        w_hsk;
    reg  [31:0] w_data;
    reg  [ 3:0] w_strb;
    reg         w_ready;
    reg         w_req;

    wire        b_hsk;
    reg  [ 1:0] b_resp;
    reg         b_valid;

    wire        ar_hsk;
    reg  [ 9:0] ar_addr;
    reg         ar_ready;
    reg         ar_req;

    wire        r_hsk;
    reg  [31:0] r_data;
    reg  [ 1:0] r_resp;
    reg         r_valid;

    // Internal interface signals

    reg         int_wr_req;
    reg         int_wr_pend;
    reg         int_wr_err_reg;

    reg         int_rd_req;
    reg         int_rd_pend;
    reg         int_rd_err_reg;
    reg  [31:0] int_rd_data_reg;

    reg  [ 9:0] int_addr;
    reg  [31:0] int_wr_data;
    reg  [ 3:0] int_wr_strb;
    reg         int_wr_en;
    reg         int_rd_en;

    reg         int_wr_ack;
    reg         int_wr_err;

    reg         int_rd_ack;
    reg         int_rd_err;
    reg  [31:0] int_rd_data;

    wire        unused_axi_inputs;

    assign unused_axi_inputs = &{1'b0, s_axi_awprot, s_axi_arprot, int_addr[1:0], int_wr_strb};


    //--------------------------------------------------------------------------
    // AXI4-Lite Interface
    //--------------------------------------------------------------------------

    assign aclk    = s_axi_aclk;
    assign aresetn = s_axi_aresetn;

    // Out of reset initialize

    always @(posedge aclk) begin
        if (!aresetn) begin
            init_n <= 1'b0;
        end else begin
            init_n <= 1'b1;
        end
    end

    // Write address

    assign aw_hsk        = (s_axi_awvalid & s_axi_awready);
    assign s_axi_awready = aw_ready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_addr <= 'd0;
        end else if (aw_hsk) begin
            aw_addr <= s_axi_awaddr;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_req <= 1'b0;
        end else if (aw_hsk) begin
            aw_req <= 1'b1;
        end else if (aw_req && w_req && ~int_wr_req) begin
            aw_req <= 1'b0;
        end else begin
            aw_req <= aw_req;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_ready <= 1'b0;
        end else if (~init_n) begin
            aw_ready <= 1'b1;
        end else if (aw_hsk) begin
            aw_ready <= 1'b0;
        end else if (aw_req && w_req && ~int_wr_req) begin
            aw_ready <= 1'b1;
        end else begin
            aw_ready <= aw_ready;
        end
    end

    // Write data

    assign w_hsk        = (s_axi_wvalid & s_axi_wready);
    assign s_axi_wready = w_ready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            w_data <= 'd0;
        end else if (w_hsk) begin
            w_data <= s_axi_wdata;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            w_strb <= 'd0;
        end else if (w_hsk) begin
            w_strb <= s_axi_wstrb;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            w_req <= 1'b0;
        end else if (w_hsk) begin
            w_req <= 1'b1;
        end else if (aw_req && w_req && ~int_wr_req) begin
            w_req <= 1'b0;
        end else begin
            w_req <= w_req;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            w_ready <= 1'b0;
        end else if (~init_n) begin
            w_ready <= 1'b1;
        end else if (w_hsk) begin
            w_ready <= 1'b0;
        end else if (aw_req && w_req && ~int_wr_req) begin
            w_ready <= 1'b1;
        end else begin
            w_ready <= w_ready;
        end
    end

    // Write response

    assign b_hsk        = (s_axi_bvalid && s_axi_bready);
    assign s_axi_bresp  = b_resp;
    assign s_axi_bvalid = b_valid;

    always @(posedge aclk) begin
        if (!aresetn) begin
            b_resp <= 'd0;
        end else if (~b_valid && int_wr_pend) begin
            b_resp <= {2{int_wr_err_reg}};
        end else if (~b_valid && int_wr_req && int_wr_ack) begin
            b_resp <= {2{int_wr_err}};
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            b_valid <= 1'b0;
        end else if (b_hsk) begin
            b_valid <= 1'b0;
        end else if (int_wr_req && int_wr_ack || int_wr_pend) begin
            b_valid <= 1'b1;
        end else begin
            b_valid <= b_valid;
        end
    end

    // Read address

    assign ar_hsk        = (s_axi_arvalid & s_axi_arready);
    assign s_axi_arready = ar_ready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ar_addr <= 'd0;
        end else if (ar_hsk) begin
            ar_addr <= s_axi_araddr;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            ar_req <= 1'b0;
        end else if (ar_hsk) begin
            ar_req <= 1'b1;
        end else if (~(aw_req && w_req) && ar_req && ~int_rd_req) begin
            ar_req <= 1'b0;
        end else begin
            ar_req <= ar_req;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            ar_ready <= 1'b0;
        end else if (~init_n) begin
            ar_ready <= 1'b1;
        end else if (ar_hsk) begin
            ar_ready <= 1'b0;
        end else if (~(aw_req && w_req) && ar_req && ~int_rd_req) begin
            ar_ready <= 1'b1;
        end else begin
            ar_ready <= ar_ready;
        end
    end

    // Read response

    assign r_hsk        = (s_axi_rvalid && s_axi_rready);
    assign s_axi_rdata  = r_data;
    assign s_axi_rresp  = r_resp;
    assign s_axi_rvalid = r_valid;

    always @(posedge aclk) begin
        if (!aresetn) begin
            r_data <= 'd0;
        end else if (~r_valid && int_rd_pend) begin
            r_data <= int_rd_data_reg;
        end else if (~r_valid && int_rd_req && int_rd_ack) begin
            r_data <= int_rd_data;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            r_resp <= 'd0;
        end else if (int_rd_pend && ~r_valid) begin
            r_resp <= {2{int_rd_err_reg}};
        end else if (int_rd_req && int_rd_ack && ~r_valid) begin
            r_resp <= {2{int_rd_err}};
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            r_valid <= 1'b0;
        end else if (r_hsk) begin
            r_valid <= 1'b0;
        end else if (int_rd_req && int_rd_ack || int_rd_pend) begin
            r_valid <= 1'b1;
        end else begin
            r_valid <= r_valid;
        end
    end


    // Internal interface
    //-------------------

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_addr <= 'd0;
        end else if (aw_req && w_req && ~int_wr_req) begin
            int_addr <= aw_addr;
        end else if (~(aw_req && w_req) && ar_req && ~int_rd_req) begin
            int_addr <= ar_addr;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_wr_data <= 'd0;
        end else if (w_req && aw_req && ~int_wr_req) begin
            int_wr_data <= w_data;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_wr_strb <= 'd0;
        end else if (w_req && aw_req && ~int_wr_req) begin
            int_wr_strb <= w_strb;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (aw_req && w_req && ~int_wr_req) begin
            int_wr_en <= 1'b1;
        end else begin
            int_wr_en <= 1'b0;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (~(aw_req && w_req) && ar_req && ~int_rd_req) begin
            int_rd_en <= 1'b1;
        end else begin
            int_rd_en <= 1'b0;
        end
    end

    // Response

    always @(posedge s_axi_aclk) begin
        if (int_wr_req && ~int_wr_pend && int_wr_ack) begin
            int_wr_err_reg <= int_wr_err;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (int_rd_req && ~int_rd_pend && int_rd_ack) begin
            int_rd_err_reg <= int_rd_err;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (int_rd_req && ~int_rd_pend && int_rd_ack) begin
            int_rd_data_reg <= int_rd_data;
        end
    end

    // Internal state

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_wr_req <= 1'b0;
        end else if (~int_wr_req && aw_req && w_req) begin
            int_wr_req <= 1'b1;
        end else if (int_wr_req && (int_wr_ack || int_wr_pend) && ~b_valid) begin
            int_wr_req <= 1'b0;
        end else begin
            int_wr_req <= int_wr_req;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_wr_pend <= 1'b0;
        end else if (int_wr_req && int_wr_ack && b_valid) begin
            int_wr_pend <= 1'b1;
        end else if (int_wr_pend && ~b_valid) begin
            int_wr_pend <= 1'b0;
        end else begin
            int_wr_pend <= int_wr_pend;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_rd_req <= 1'b0;
        end else if (~int_rd_req && ~(aw_req && w_req) && ar_req) begin
            int_rd_req <= 1'b1;
        end else if (int_rd_req && (int_rd_ack || int_rd_pend) && ~r_valid) begin
            int_rd_req <= 1'b0;
        end else begin
            int_rd_req <= int_rd_req;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_rd_pend <= 1'b0;
        end else if (int_rd_req && int_rd_ack && r_valid) begin
            int_rd_pend <= 1'b1;
        end else if (int_rd_pend && ~r_valid) begin
            int_rd_pend <= 1'b0;
        end else begin
            int_rd_pend <= int_rd_pend;
        end
    end


    //--------------------------------------------------------------------------
    // Address decoder
    //--------------------------------------------------------------------------

    wire version_val_strb;

    assign version_val_strb = (int_addr[9:2] == 'h0);

    wire scratch0_val_strb;

    assign scratch0_val_strb = (int_addr[9:2] == 'h1);

    wire scratch1_val_strb;

    assign scratch1_val_strb = (int_addr[9:2] == 'h2);

    wire ptp_ctrl_master_en_strb;

    assign ptp_ctrl_master_en_strb = (int_addr[9:2] == 'hc4);

    wire ptp_src_mac_l_val_strb;

    assign ptp_src_mac_l_val_strb = (int_addr[9:2] == 'hc5);

    wire ptp_src_mac_h_val_strb;

    assign ptp_src_mac_h_val_strb = (int_addr[9:2] == 'hc6);

    wire ptp_domain_number_val_strb;

    assign ptp_domain_number_val_strb = (int_addr[9:2] == 'hc8);

    wire ptp_utc_offset_val_strb;

    assign ptp_utc_offset_val_strb = (int_addr[9:2] == 'hc9);

    wire ptp_log_announce_interval_val_strb;

    assign ptp_log_announce_interval_val_strb = (int_addr[9:2] == 'hca);

    wire ptp_log_sync_interval_val_strb;

    assign ptp_log_sync_interval_val_strb = (int_addr[9:2] == 'hcb);

    always @(posedge s_axi_aclk) begin
        int_wr_ack <= int_wr_en;
    end

    always @(posedge s_axi_aclk) begin
        int_wr_err <= 1'b1;
        if (version_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (scratch0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (scratch1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ptp_ctrl_master_en_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ptp_src_mac_l_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ptp_src_mac_h_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ptp_domain_number_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ptp_utc_offset_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ptp_log_announce_interval_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ptp_log_sync_interval_val_strb) begin
            int_wr_err <= 1'b0;
        end
    end

    always @(posedge s_axi_aclk) begin
        int_rd_ack <= int_rd_en;
    end

    always @(posedge s_axi_aclk) begin
        int_rd_err <= 1'b1;
        if (version_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (scratch0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (scratch1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ptp_ctrl_master_en_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ptp_src_mac_l_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ptp_src_mac_h_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ptp_domain_number_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ptp_utc_offset_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ptp_log_announce_interval_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ptp_log_sync_interval_val_strb) begin
            int_rd_err <= 1'b0;
        end
    end


    //--------------------------------------------------------------------------
    // Field logic
    //--------------------------------------------------------------------------

    // Field version.val @'h0[31:0]

    reg [31:0] version_val_value;

    initial begin
        version_val_value = 'h20230411;
    end

    // Field scratch0.val @'h4[31:0]

    reg [31:0] scratch0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            scratch0_val_value <= 'h0;
        end else if (int_wr_en && scratch0_val_strb) begin
            scratch0_val_value <= int_wr_data[31:0];
        end
    end

    // Field scratch1.val @'h8[31:0]

    reg [31:0] scratch1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            scratch1_val_value <= 'h0;
        end else if (int_wr_en && scratch1_val_strb) begin
            scratch1_val_value <= int_wr_data[31:0];
        end
    end

    // Field ptp_ctrl.master_en @'h310[0:0]

    reg [0:0] ptp_ctrl_master_en_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ptp_ctrl_master_en_value <= 'h0;
        end else if (int_wr_en && ptp_ctrl_master_en_strb) begin
            ptp_ctrl_master_en_value <= int_wr_data[0:0];
        end
    end

    assign ptp_ctrl_master_en_out = ptp_ctrl_master_en_value;

    // Field ptp_src_mac_l.val @'h314[31:0]

    reg [31:0] ptp_src_mac_l_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ptp_src_mac_l_val_value <= 'h0;
        end else if (int_wr_en && ptp_src_mac_l_val_strb) begin
            ptp_src_mac_l_val_value <= int_wr_data[31:0];
        end
    end

    assign ptp_src_mac_l_val_out = ptp_src_mac_l_val_value;

    // Field ptp_src_mac_h.val @'h318[15:0]

    reg [15:0] ptp_src_mac_h_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ptp_src_mac_h_val_value <= 'h0;
        end else if (int_wr_en && ptp_src_mac_h_val_strb) begin
            ptp_src_mac_h_val_value <= int_wr_data[15:0];
        end
    end

    assign ptp_src_mac_h_val_out = ptp_src_mac_h_val_value;

    // Field ptp_domain_number.val @'h320[7:0]

    reg [7:0] ptp_domain_number_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ptp_domain_number_val_value <= 'h0;
        end else if (int_wr_en && ptp_domain_number_val_strb) begin
            ptp_domain_number_val_value <= int_wr_data[7:0];
        end
    end

    assign ptp_domain_number_val_out = ptp_domain_number_val_value;

    // Field ptp_utc_offset.val @'h324[15:0]

    reg [15:0] ptp_utc_offset_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ptp_utc_offset_val_value <= 'h0;
        end else if (int_wr_en && ptp_utc_offset_val_strb) begin
            ptp_utc_offset_val_value <= int_wr_data[15:0];
        end
    end

    assign ptp_utc_offset_val_out = ptp_utc_offset_val_value;

    // Field ptp_log_announce_interval.val @'h328[7:0]

    reg [7:0] ptp_log_announce_interval_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ptp_log_announce_interval_val_value <= 'h0;
        end else if (int_wr_en && ptp_log_announce_interval_val_strb) begin
            ptp_log_announce_interval_val_value <= int_wr_data[7:0];
        end
    end

    assign ptp_log_announce_interval_val_out = ptp_log_announce_interval_val_value;

    // Field ptp_log_sync_interval.val @'h32c[7:0]

    reg [7:0] ptp_log_sync_interval_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ptp_log_sync_interval_val_value <= 'h0;
        end else if (int_wr_en && ptp_log_sync_interval_val_strb) begin
            ptp_log_sync_interval_val_value <= int_wr_data[7:0];
        end
    end

    assign ptp_log_sync_interval_val_out = ptp_log_sync_interval_val_value;


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
        field_rd_data_next = 'd0;
        if (int_rd_en && version_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | version_val_value;
        end
        if (int_rd_en && scratch0_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | scratch0_val_value;
        end
        if (int_rd_en && scratch1_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | scratch1_val_value;
        end
        if (int_rd_en && ptp_ctrl_master_en_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | ptp_ctrl_master_en_value;
        end
        if (int_rd_en && ptp_src_mac_l_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ptp_src_mac_l_val_value;
        end
        if (int_rd_en && ptp_src_mac_h_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | ptp_src_mac_h_val_value;
        end
        if (int_rd_en && ptp_domain_number_val_strb) begin
            field_rd_data_next[7:0] = field_rd_data_next[7:0] | ptp_domain_number_val_value;
        end
        if (int_rd_en && ptp_utc_offset_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | ptp_utc_offset_val_value;
        end
        if (int_rd_en && ptp_log_announce_interval_val_strb) begin
            field_rd_data_next[7:0] = field_rd_data_next[7:0] | ptp_log_announce_interval_val_value;
        end
        if (int_rd_en && ptp_log_sync_interval_val_strb) begin
            field_rd_data_next[7:0] = field_rd_data_next[7:0] | ptp_log_sync_interval_val_value;
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
        if (int_rd_en && scratch0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && scratch1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ptp_ctrl_master_en_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ptp_src_mac_l_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ptp_src_mac_h_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ptp_domain_number_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ptp_utc_offset_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ptp_log_announce_interval_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ptp_log_sync_interval_val_strb) begin
            field_strb <= 1'b1;
        end
    end

    always @(*) begin
        int_rd_data = 'd0;
        if (field_strb) begin
            int_rd_data = int_rd_data | field_rd_data;
        end
    end

endmodule

`default_nettype wire

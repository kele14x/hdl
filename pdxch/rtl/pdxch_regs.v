// File: pdxch_regs.v
// Brief: Register block generate for pdxch
`timescale 1 ns / 1 ps
//
`default_nettype none

module pdxch_regs (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    //
    input  wire [11:0] s_axi_awaddr,
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
    input  wire [11:0] s_axi_araddr,
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
    // dl_en.cc0,
    output wire [ 3:0] dl_en_cc0_out,
    // dl_en.cc1,
    output wire [ 3:0] dl_en_cc1_out,
    // dl_en.cc2,
    output wire [ 3:0] dl_en_cc2_out,
    // dl_rat.cc0,
    output wire [ 3:0] dl_rat_cc0_out,
    // dl_rat.cc1,
    output wire [ 3:0] dl_rat_cc1_out,
    // dl_rat.cc2,
    output wire [ 3:0] dl_rat_cc2_out,
    // dl_bist.cc0,
    output wire [ 3:0] dl_bist_cc0_out,
    // dl_bist.cc1,
    output wire [ 3:0] dl_bist_cc1_out,
    // dl_bist.cc2,
    output wire [ 3:0] dl_bist_cc2_out,
    // dl_bw.cc0,
    output wire [ 3:0] dl_bw_cc0_out,
    // dl_bw.cc1,
    output wire [ 3:0] dl_bw_cc1_out,
    // dl_bw.cc2,
    output wire [ 3:0] dl_bw_cc2_out,
    // dl_nprb_0.val,
    output wire [ 8:0] dl_nprb_0_val_out,
    // dl_nprb_1.val,
    output wire [ 8:0] dl_nprb_1_val_out,
    // dl_nprb_2.val,
    output wire [ 8:0] dl_nprb_2_val_out,
    // dl_rfs_offset_0.val,
    output wire [22:0] dl_rfs_offset_0_val_out,
    // dl_rfs_offset_1.val,
    output wire [22:0] dl_rfs_offset_1_val_out,
    // dl_rfs_offset_2.val,
    output wire [22:0] dl_rfs_offset_2_val_out,
    // dl_ud.comp_meth,
    output wire [ 3:0] dl_ud_comp_meth_out,
    // dl_ud.iq_width,
    output wire [ 3:0] dl_ud_iq_width_out,
    // dl_ud.fs_offset,
    output wire [ 3:0] dl_ud_fs_offset_out,
    // dl_gain_0_0.val,
    output wire [16:0] dl_gain_0_0_val_out,
    // dl_gain_0_1.val,
    output wire [16:0] dl_gain_0_1_val_out,
    // dl_gain_0_2.val,
    output wire [16:0] dl_gain_0_2_val_out,
    // dl_gain_0_3.val,
    output wire [16:0] dl_gain_0_3_val_out,
    // dl_gain_1_0.val,
    output wire [16:0] dl_gain_1_0_val_out,
    // dl_gain_1_1.val,
    output wire [16:0] dl_gain_1_1_val_out,
    // dl_gain_1_2.val,
    output wire [16:0] dl_gain_1_2_val_out,
    // dl_gain_1_3.val,
    output wire [16:0] dl_gain_1_3_val_out,
    // dl_gain_2_0.val,
    output wire [16:0] dl_gain_2_0_val_out,
    // dl_gain_2_1.val,
    output wire [16:0] dl_gain_2_1_val_out,
    // dl_gain_2_2.val,
    output wire [16:0] dl_gain_2_2_val_out,
    // dl_gain_2_3.val,
    output wire [16:0] dl_gain_2_3_val_out,
    // dl_phase_comp,
    output wire [ 5:0] dl_phase_comp_addr,
    output wire        dl_phase_comp_en,
    output wire        dl_phase_comp_we,
    output wire [31:0] dl_phase_comp_din,
    input  wire [31:0] dl_phase_comp_dout,
    input  wire        dl_phase_comp_valid
);

    wire        aclk;
    wire        aresetn;

    reg         init_n;

    wire        aw_hsk;
    reg  [11:0] aw_addr;
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
    reg  [11:0] ar_addr;
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

    /* verilator lint_off UNUSED */
    reg  [11:0] int_addr;
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
            aw_addr <= 12'b0;
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
            w_data <= 32'b0;
        end else if (w_hsk) begin
            w_data <= s_axi_wdata;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            w_strb <= 4'b0;
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
            b_resp <= 2'b0;
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
            ar_addr <= 12'b0;
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
            r_data <= 32'b0;
        end else if (~r_valid && int_rd_pend) begin
            r_data <= int_rd_data_reg;
        end else if (~r_valid && int_rd_req && int_rd_ack) begin
            r_data <= int_rd_data;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            r_resp <= 2'b0;
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
            int_addr <= 12'b0;
        end else if (aw_req && w_req && ~int_wr_req) begin
            int_addr <= aw_addr;
        end else if (~(aw_req && w_req) && ar_req && ~int_rd_req) begin
            int_addr <= ar_addr;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_wr_data <= 32'b0;
        end else if (w_req && aw_req && ~int_wr_req) begin
            int_wr_data <= w_data;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_wr_strb <= 4'b0;
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

    assign version_val_strb = (int_addr[11:2] == 'h0);

    wire scratch0_val_strb;

    assign scratch0_val_strb = (int_addr[11:2] == 'h1);

    wire scratch1_val_strb;

    assign scratch1_val_strb = (int_addr[11:2] == 'h2);

    wire dl_en_cc0_strb;

    assign dl_en_cc0_strb = (int_addr[11:2] == 'h4);

    wire dl_en_cc1_strb;

    assign dl_en_cc1_strb = (int_addr[11:2] == 'h4);

    wire dl_en_cc2_strb;

    assign dl_en_cc2_strb = (int_addr[11:2] == 'h4);

    wire dl_rat_cc0_strb;

    assign dl_rat_cc0_strb = (int_addr[11:2] == 'h5);

    wire dl_rat_cc1_strb;

    assign dl_rat_cc1_strb = (int_addr[11:2] == 'h5);

    wire dl_rat_cc2_strb;

    assign dl_rat_cc2_strb = (int_addr[11:2] == 'h5);

    wire dl_bist_cc0_strb;

    assign dl_bist_cc0_strb = (int_addr[11:2] == 'h6);

    wire dl_bist_cc1_strb;

    assign dl_bist_cc1_strb = (int_addr[11:2] == 'h6);

    wire dl_bist_cc2_strb;

    assign dl_bist_cc2_strb = (int_addr[11:2] == 'h6);

    wire dl_bw_cc0_strb;

    assign dl_bw_cc0_strb = (int_addr[11:2] == 'h7);

    wire dl_bw_cc1_strb;

    assign dl_bw_cc1_strb = (int_addr[11:2] == 'h7);

    wire dl_bw_cc2_strb;

    assign dl_bw_cc2_strb = (int_addr[11:2] == 'h7);

    wire dl_nprb_0_val_strb;

    assign dl_nprb_0_val_strb = (int_addr[11:2] == 'h8);

    wire dl_nprb_1_val_strb;

    assign dl_nprb_1_val_strb = (int_addr[11:2] == 'h9);

    wire dl_nprb_2_val_strb;

    assign dl_nprb_2_val_strb = (int_addr[11:2] == 'ha);

    wire dl_rfs_offset_0_val_strb;

    assign dl_rfs_offset_0_val_strb = (int_addr[11:2] == 'hc);

    wire dl_rfs_offset_1_val_strb;

    assign dl_rfs_offset_1_val_strb = (int_addr[11:2] == 'hd);

    wire dl_rfs_offset_2_val_strb;

    assign dl_rfs_offset_2_val_strb = (int_addr[11:2] == 'he);

    wire dl_ud_comp_meth_strb;

    assign dl_ud_comp_meth_strb = (int_addr[11:2] == 'h16);

    wire dl_ud_iq_width_strb;

    assign dl_ud_iq_width_strb = (int_addr[11:2] == 'h16);

    wire dl_ud_fs_offset_strb;

    assign dl_ud_fs_offset_strb = (int_addr[11:2] == 'h16);

    wire dl_gain_0_0_val_strb;

    assign dl_gain_0_0_val_strb = (int_addr[11:2] == 'h40);

    wire dl_gain_0_1_val_strb;

    assign dl_gain_0_1_val_strb = (int_addr[11:2] == 'h41);

    wire dl_gain_0_2_val_strb;

    assign dl_gain_0_2_val_strb = (int_addr[11:2] == 'h42);

    wire dl_gain_0_3_val_strb;

    assign dl_gain_0_3_val_strb = (int_addr[11:2] == 'h43);

    wire dl_gain_1_0_val_strb;

    assign dl_gain_1_0_val_strb = (int_addr[11:2] == 'h44);

    wire dl_gain_1_1_val_strb;

    assign dl_gain_1_1_val_strb = (int_addr[11:2] == 'h45);

    wire dl_gain_1_2_val_strb;

    assign dl_gain_1_2_val_strb = (int_addr[11:2] == 'h46);

    wire dl_gain_1_3_val_strb;

    assign dl_gain_1_3_val_strb = (int_addr[11:2] == 'h47);

    wire dl_gain_2_0_val_strb;

    assign dl_gain_2_0_val_strb = (int_addr[11:2] == 'h48);

    wire dl_gain_2_1_val_strb;

    assign dl_gain_2_1_val_strb = (int_addr[11:2] == 'h49);

    wire dl_gain_2_2_val_strb;

    assign dl_gain_2_2_val_strb = (int_addr[11:2] == 'h4a);

    wire dl_gain_2_3_val_strb;

    assign dl_gain_2_3_val_strb = (int_addr[11:2] == 'h4b);

    wire dl_phase_comp_strb;

    assign dl_phase_comp_strb = (int_addr[11:8] == 'h8);

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
        if (dl_en_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_en_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_en_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_rat_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_rat_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_rat_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_bist_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_bist_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_bist_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_bw_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_bw_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_bw_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_nprb_0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_nprb_1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_nprb_2_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_rfs_offset_0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_rfs_offset_1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_rfs_offset_2_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_ud_comp_meth_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_ud_iq_width_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_ud_fs_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_gain_0_0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_gain_0_1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_gain_0_2_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_gain_0_3_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_gain_1_0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_gain_1_1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_gain_1_2_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_gain_1_3_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_gain_2_0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_gain_2_1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_gain_2_2_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_gain_2_3_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_phase_comp_strb) begin
            int_wr_err <= 1'b0;
        end
    end

    always @(posedge s_axi_aclk) begin
        int_rd_ack <= int_rd_en;
        if (dl_phase_comp_strb) begin
            int_rd_ack <= int_rd_req && dl_phase_comp_valid;
        end
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
        if (dl_en_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_en_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_en_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_rat_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_rat_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_rat_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_bist_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_bist_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_bist_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_bw_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_bw_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_bw_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_nprb_0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_nprb_1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_nprb_2_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_rfs_offset_0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_rfs_offset_1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_rfs_offset_2_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_ud_comp_meth_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_ud_iq_width_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_ud_fs_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_gain_0_0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_gain_0_1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_gain_0_2_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_gain_0_3_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_gain_1_0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_gain_1_1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_gain_1_2_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_gain_1_3_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_gain_2_0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_gain_2_1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_gain_2_2_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_gain_2_3_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_phase_comp_strb) begin
            int_rd_err <= 1'b0;
        end
    end


    //--------------------------------------------------------------------------
    // Field logic
    //--------------------------------------------------------------------------

    // Field version.val @'h0[31:0]

    reg [31:0] version_val_value;

    initial begin
        version_val_value = 'h20250106;
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

    // Field dl_en.cc0 @'h10[3:0]

    reg [3:0] dl_en_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_en_cc0_value <= 'h0;
        end else if (int_wr_en && dl_en_cc0_strb) begin
            dl_en_cc0_value <= int_wr_data[3:0];
        end
    end

    assign dl_en_cc0_out = dl_en_cc0_value;

    // Field dl_en.cc1 @'h10[7:4]

    reg [3:0] dl_en_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_en_cc1_value <= 'h0;
        end else if (int_wr_en && dl_en_cc1_strb) begin
            dl_en_cc1_value <= int_wr_data[7:4];
        end
    end

    assign dl_en_cc1_out = dl_en_cc1_value;

    // Field dl_en.cc2 @'h10[11:8]

    reg [3:0] dl_en_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_en_cc2_value <= 'h0;
        end else if (int_wr_en && dl_en_cc2_strb) begin
            dl_en_cc2_value <= int_wr_data[11:8];
        end
    end

    assign dl_en_cc2_out = dl_en_cc2_value;

    // Field dl_rat.cc0 @'h14[3:0]

    reg [3:0] dl_rat_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_rat_cc0_value <= 'h0;
        end else if (int_wr_en && dl_rat_cc0_strb) begin
            dl_rat_cc0_value <= int_wr_data[3:0];
        end
    end

    assign dl_rat_cc0_out = dl_rat_cc0_value;

    // Field dl_rat.cc1 @'h14[7:4]

    reg [3:0] dl_rat_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_rat_cc1_value <= 'h0;
        end else if (int_wr_en && dl_rat_cc1_strb) begin
            dl_rat_cc1_value <= int_wr_data[7:4];
        end
    end

    assign dl_rat_cc1_out = dl_rat_cc1_value;

    // Field dl_rat.cc2 @'h14[11:8]

    reg [3:0] dl_rat_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_rat_cc2_value <= 'h0;
        end else if (int_wr_en && dl_rat_cc2_strb) begin
            dl_rat_cc2_value <= int_wr_data[11:8];
        end
    end

    assign dl_rat_cc2_out = dl_rat_cc2_value;

    // Field dl_bist.cc0 @'h18[3:0]

    reg [3:0] dl_bist_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_bist_cc0_value <= 'h0;
        end else if (int_wr_en && dl_bist_cc0_strb) begin
            dl_bist_cc0_value <= int_wr_data[3:0];
        end
    end

    assign dl_bist_cc0_out = dl_bist_cc0_value;

    // Field dl_bist.cc1 @'h18[7:4]

    reg [3:0] dl_bist_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_bist_cc1_value <= 'h0;
        end else if (int_wr_en && dl_bist_cc1_strb) begin
            dl_bist_cc1_value <= int_wr_data[7:4];
        end
    end

    assign dl_bist_cc1_out = dl_bist_cc1_value;

    // Field dl_bist.cc2 @'h18[11:8]

    reg [3:0] dl_bist_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_bist_cc2_value <= 'h0;
        end else if (int_wr_en && dl_bist_cc2_strb) begin
            dl_bist_cc2_value <= int_wr_data[11:8];
        end
    end

    assign dl_bist_cc2_out = dl_bist_cc2_value;

    // Field dl_bw.cc0 @'h1c[3:0]

    reg [3:0] dl_bw_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_bw_cc0_value <= 'h2;
        end else if (int_wr_en && dl_bw_cc0_strb) begin
            dl_bw_cc0_value <= int_wr_data[3:0];
        end
    end

    assign dl_bw_cc0_out = dl_bw_cc0_value;

    // Field dl_bw.cc1 @'h1c[7:4]

    reg [3:0] dl_bw_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_bw_cc1_value <= 'h2;
        end else if (int_wr_en && dl_bw_cc1_strb) begin
            dl_bw_cc1_value <= int_wr_data[7:4];
        end
    end

    assign dl_bw_cc1_out = dl_bw_cc1_value;

    // Field dl_bw.cc2 @'h1c[11:8]

    reg [3:0] dl_bw_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_bw_cc2_value <= 'h2;
        end else if (int_wr_en && dl_bw_cc2_strb) begin
            dl_bw_cc2_value <= int_wr_data[11:8];
        end
    end

    assign dl_bw_cc2_out = dl_bw_cc2_value;

    // Field dl_nprb_0.val @'h20[8:0]

    reg [8:0] dl_nprb_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_nprb_0_val_value <= 'h64;
        end else if (int_wr_en && dl_nprb_0_val_strb) begin
            dl_nprb_0_val_value <= int_wr_data[8:0];
        end
    end

    assign dl_nprb_0_val_out = dl_nprb_0_val_value;

    // Field dl_nprb_1.val @'h24[8:0]

    reg [8:0] dl_nprb_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_nprb_1_val_value <= 'h64;
        end else if (int_wr_en && dl_nprb_1_val_strb) begin
            dl_nprb_1_val_value <= int_wr_data[8:0];
        end
    end

    assign dl_nprb_1_val_out = dl_nprb_1_val_value;

    // Field dl_nprb_2.val @'h28[8:0]

    reg [8:0] dl_nprb_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_nprb_2_val_value <= 'h64;
        end else if (int_wr_en && dl_nprb_2_val_strb) begin
            dl_nprb_2_val_value <= int_wr_data[8:0];
        end
    end

    assign dl_nprb_2_val_out = dl_nprb_2_val_value;

    // Field dl_rfs_offset_0.val @'h30[22:0]

    reg [22:0] dl_rfs_offset_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_rfs_offset_0_val_value <= 'h0;
        end else if (int_wr_en && dl_rfs_offset_0_val_strb) begin
            dl_rfs_offset_0_val_value <= int_wr_data[22:0];
        end
    end

    assign dl_rfs_offset_0_val_out = dl_rfs_offset_0_val_value;

    // Field dl_rfs_offset_1.val @'h34[22:0]

    reg [22:0] dl_rfs_offset_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_rfs_offset_1_val_value <= 'h0;
        end else if (int_wr_en && dl_rfs_offset_1_val_strb) begin
            dl_rfs_offset_1_val_value <= int_wr_data[22:0];
        end
    end

    assign dl_rfs_offset_1_val_out = dl_rfs_offset_1_val_value;

    // Field dl_rfs_offset_2.val @'h38[22:0]

    reg [22:0] dl_rfs_offset_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_rfs_offset_2_val_value <= 'h0;
        end else if (int_wr_en && dl_rfs_offset_2_val_strb) begin
            dl_rfs_offset_2_val_value <= int_wr_data[22:0];
        end
    end

    assign dl_rfs_offset_2_val_out = dl_rfs_offset_2_val_value;

    // Field dl_ud.comp_meth @'h58[3:0]

    reg [3:0] dl_ud_comp_meth_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_ud_comp_meth_value <= 'h1;
        end else if (int_wr_en && dl_ud_comp_meth_strb) begin
            dl_ud_comp_meth_value <= int_wr_data[3:0];
        end
    end

    assign dl_ud_comp_meth_out = dl_ud_comp_meth_value;

    // Field dl_ud.iq_width @'h58[7:4]

    reg [3:0] dl_ud_iq_width_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_ud_iq_width_value <= 'h9;
        end else if (int_wr_en && dl_ud_iq_width_strb) begin
            dl_ud_iq_width_value <= int_wr_data[7:4];
        end
    end

    assign dl_ud_iq_width_out = dl_ud_iq_width_value;

    // Field dl_ud.fs_offset @'h58[11:8]

    reg [3:0] dl_ud_fs_offset_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_ud_fs_offset_value <= 'h0;
        end else if (int_wr_en && dl_ud_fs_offset_strb) begin
            dl_ud_fs_offset_value <= int_wr_data[11:8];
        end
    end

    assign dl_ud_fs_offset_out = dl_ud_fs_offset_value;

    // Field dl_gain_0_0.val @'h100[16:0]

    reg [16:0] dl_gain_0_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_gain_0_0_val_value <= 'h4000;
        end else if (int_wr_en && dl_gain_0_0_val_strb) begin
            dl_gain_0_0_val_value <= int_wr_data[16:0];
        end
    end

    assign dl_gain_0_0_val_out = dl_gain_0_0_val_value;

    // Field dl_gain_0_1.val @'h104[16:0]

    reg [16:0] dl_gain_0_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_gain_0_1_val_value <= 'h4000;
        end else if (int_wr_en && dl_gain_0_1_val_strb) begin
            dl_gain_0_1_val_value <= int_wr_data[16:0];
        end
    end

    assign dl_gain_0_1_val_out = dl_gain_0_1_val_value;

    // Field dl_gain_0_2.val @'h108[16:0]

    reg [16:0] dl_gain_0_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_gain_0_2_val_value <= 'h4000;
        end else if (int_wr_en && dl_gain_0_2_val_strb) begin
            dl_gain_0_2_val_value <= int_wr_data[16:0];
        end
    end

    assign dl_gain_0_2_val_out = dl_gain_0_2_val_value;

    // Field dl_gain_0_3.val @'h10c[16:0]

    reg [16:0] dl_gain_0_3_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_gain_0_3_val_value <= 'h4000;
        end else if (int_wr_en && dl_gain_0_3_val_strb) begin
            dl_gain_0_3_val_value <= int_wr_data[16:0];
        end
    end

    assign dl_gain_0_3_val_out = dl_gain_0_3_val_value;

    // Field dl_gain_1_0.val @'h110[16:0]

    reg [16:0] dl_gain_1_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_gain_1_0_val_value <= 'h4000;
        end else if (int_wr_en && dl_gain_1_0_val_strb) begin
            dl_gain_1_0_val_value <= int_wr_data[16:0];
        end
    end

    assign dl_gain_1_0_val_out = dl_gain_1_0_val_value;

    // Field dl_gain_1_1.val @'h114[16:0]

    reg [16:0] dl_gain_1_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_gain_1_1_val_value <= 'h4000;
        end else if (int_wr_en && dl_gain_1_1_val_strb) begin
            dl_gain_1_1_val_value <= int_wr_data[16:0];
        end
    end

    assign dl_gain_1_1_val_out = dl_gain_1_1_val_value;

    // Field dl_gain_1_2.val @'h118[16:0]

    reg [16:0] dl_gain_1_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_gain_1_2_val_value <= 'h4000;
        end else if (int_wr_en && dl_gain_1_2_val_strb) begin
            dl_gain_1_2_val_value <= int_wr_data[16:0];
        end
    end

    assign dl_gain_1_2_val_out = dl_gain_1_2_val_value;

    // Field dl_gain_1_3.val @'h11c[16:0]

    reg [16:0] dl_gain_1_3_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_gain_1_3_val_value <= 'h4000;
        end else if (int_wr_en && dl_gain_1_3_val_strb) begin
            dl_gain_1_3_val_value <= int_wr_data[16:0];
        end
    end

    assign dl_gain_1_3_val_out = dl_gain_1_3_val_value;

    // Field dl_gain_2_0.val @'h120[16:0]

    reg [16:0] dl_gain_2_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_gain_2_0_val_value <= 'h4000;
        end else if (int_wr_en && dl_gain_2_0_val_strb) begin
            dl_gain_2_0_val_value <= int_wr_data[16:0];
        end
    end

    assign dl_gain_2_0_val_out = dl_gain_2_0_val_value;

    // Field dl_gain_2_1.val @'h124[16:0]

    reg [16:0] dl_gain_2_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_gain_2_1_val_value <= 'h4000;
        end else if (int_wr_en && dl_gain_2_1_val_strb) begin
            dl_gain_2_1_val_value <= int_wr_data[16:0];
        end
    end

    assign dl_gain_2_1_val_out = dl_gain_2_1_val_value;

    // Field dl_gain_2_2.val @'h128[16:0]

    reg [16:0] dl_gain_2_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_gain_2_2_val_value <= 'h4000;
        end else if (int_wr_en && dl_gain_2_2_val_strb) begin
            dl_gain_2_2_val_value <= int_wr_data[16:0];
        end
    end

    assign dl_gain_2_2_val_out = dl_gain_2_2_val_value;

    // Field dl_gain_2_3.val @'h12c[16:0]

    reg [16:0] dl_gain_2_3_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_gain_2_3_val_value <= 'h4000;
        end else if (int_wr_en && dl_gain_2_3_val_strb) begin
            dl_gain_2_3_val_value <= int_wr_data[16:0];
        end
    end

    assign dl_gain_2_3_val_out = dl_gain_2_3_val_value;


    //--------------------------------------------------------------------------
    // Memory logic
    //--------------------------------------------------------------------------

    // Memory dl_phase_comp @'h800

    assign dl_phase_comp_addr = int_addr[7:2];
    assign dl_phase_comp_en   = ((int_wr_en || int_rd_en) && dl_phase_comp_strb);
    assign dl_phase_comp_we   = (int_wr_en && dl_phase_comp_strb);
    assign dl_phase_comp_din  = int_wr_data[31:0];


    //--------------------------------------------------------------------------
    // Register readback
    //--------------------------------------------------------------------------

    reg [31:0] field_rd_data;
    reg [31:0] field_rd_data_next;

    reg        field_strb;

    always @(*) begin
        field_rd_data_next = 32'b0;
        if (int_rd_en && version_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | version_val_value;
        end
        if (int_rd_en && scratch0_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | scratch0_val_value;
        end
        if (int_rd_en && scratch1_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | scratch1_val_value;
        end
        if (int_rd_en && dl_en_cc0_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | dl_en_cc0_value;
        end
        if (int_rd_en && dl_en_cc1_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | dl_en_cc1_value;
        end
        if (int_rd_en && dl_en_cc2_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | dl_en_cc2_value;
        end
        if (int_rd_en && dl_rat_cc0_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | dl_rat_cc0_value;
        end
        if (int_rd_en && dl_rat_cc1_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | dl_rat_cc1_value;
        end
        if (int_rd_en && dl_rat_cc2_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | dl_rat_cc2_value;
        end
        if (int_rd_en && dl_bist_cc0_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | dl_bist_cc0_value;
        end
        if (int_rd_en && dl_bist_cc1_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | dl_bist_cc1_value;
        end
        if (int_rd_en && dl_bist_cc2_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | dl_bist_cc2_value;
        end
        if (int_rd_en && dl_bw_cc0_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | dl_bw_cc0_value;
        end
        if (int_rd_en && dl_bw_cc1_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | dl_bw_cc1_value;
        end
        if (int_rd_en && dl_bw_cc2_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | dl_bw_cc2_value;
        end
        if (int_rd_en && dl_nprb_0_val_strb) begin
            field_rd_data_next[8:0] = field_rd_data_next[8:0] | dl_nprb_0_val_value;
        end
        if (int_rd_en && dl_nprb_1_val_strb) begin
            field_rd_data_next[8:0] = field_rd_data_next[8:0] | dl_nprb_1_val_value;
        end
        if (int_rd_en && dl_nprb_2_val_strb) begin
            field_rd_data_next[8:0] = field_rd_data_next[8:0] | dl_nprb_2_val_value;
        end
        if (int_rd_en && dl_rfs_offset_0_val_strb) begin
            field_rd_data_next[22:0] = field_rd_data_next[22:0] | dl_rfs_offset_0_val_value;
        end
        if (int_rd_en && dl_rfs_offset_1_val_strb) begin
            field_rd_data_next[22:0] = field_rd_data_next[22:0] | dl_rfs_offset_1_val_value;
        end
        if (int_rd_en && dl_rfs_offset_2_val_strb) begin
            field_rd_data_next[22:0] = field_rd_data_next[22:0] | dl_rfs_offset_2_val_value;
        end
        if (int_rd_en && dl_ud_comp_meth_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | dl_ud_comp_meth_value;
        end
        if (int_rd_en && dl_ud_iq_width_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | dl_ud_iq_width_value;
        end
        if (int_rd_en && dl_ud_fs_offset_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | dl_ud_fs_offset_value;
        end
        if (int_rd_en && dl_gain_0_0_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | dl_gain_0_0_val_value;
        end
        if (int_rd_en && dl_gain_0_1_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | dl_gain_0_1_val_value;
        end
        if (int_rd_en && dl_gain_0_2_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | dl_gain_0_2_val_value;
        end
        if (int_rd_en && dl_gain_0_3_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | dl_gain_0_3_val_value;
        end
        if (int_rd_en && dl_gain_1_0_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | dl_gain_1_0_val_value;
        end
        if (int_rd_en && dl_gain_1_1_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | dl_gain_1_1_val_value;
        end
        if (int_rd_en && dl_gain_1_2_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | dl_gain_1_2_val_value;
        end
        if (int_rd_en && dl_gain_1_3_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | dl_gain_1_3_val_value;
        end
        if (int_rd_en && dl_gain_2_0_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | dl_gain_2_0_val_value;
        end
        if (int_rd_en && dl_gain_2_1_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | dl_gain_2_1_val_value;
        end
        if (int_rd_en && dl_gain_2_2_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | dl_gain_2_2_val_value;
        end
        if (int_rd_en && dl_gain_2_3_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | dl_gain_2_3_val_value;
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
        if (int_rd_en && dl_en_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_en_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_en_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_rat_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_rat_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_rat_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_bist_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_bist_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_bist_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_bw_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_bw_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_bw_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_nprb_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_nprb_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_nprb_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_rfs_offset_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_rfs_offset_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_rfs_offset_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_ud_comp_meth_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_ud_iq_width_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_ud_fs_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_gain_0_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_gain_0_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_gain_0_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_gain_0_3_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_gain_1_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_gain_1_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_gain_1_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_gain_1_3_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_gain_2_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_gain_2_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_gain_2_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && dl_gain_2_3_val_strb) begin
            field_strb <= 1'b1;
        end
    end

    always @(*) begin
        int_rd_data = 32'b0;
        if (field_strb) begin
            int_rd_data = int_rd_data | field_rd_data;
        end
        if (dl_phase_comp_strb) begin
            int_rd_data[31:0] = int_rd_data[31:0] | dl_phase_comp_dout;
        end
    end

endmodule

`default_nettype wire

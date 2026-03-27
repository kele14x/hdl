// File: rts_regs.v
// Brief: Register block generate for rts
`timescale 1 ns / 1 ps
//
`default_nettype none

module rts_regs (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    //
    input  wire [16:0] s_axi_awaddr,
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
    input  wire [16:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    //
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    // src_sel_0.cc0,
    output wire [ 5:0] src_sel_0_cc0_out,
    // src_sel_0.cc1,
    output wire [ 5:0] src_sel_0_cc1_out,
    // src_sel_0.cc2,
    output wire [ 5:0] src_sel_0_cc2_out,
    // src_sel_0.cc3,
    output wire [ 5:0] src_sel_0_cc3_out,
    // src_sel_1.cc0,
    output wire [ 5:0] src_sel_1_cc0_out,
    // src_sel_1.cc1,
    output wire [ 5:0] src_sel_1_cc1_out,
    // src_sel_1.cc2,
    output wire [ 5:0] src_sel_1_cc2_out,
    // src_sel_1.cc3,
    output wire [ 5:0] src_sel_1_cc3_out,
    // src_sel_2.cc0,
    output wire [ 5:0] src_sel_2_cc0_out,
    // src_sel_2.cc1,
    output wire [ 5:0] src_sel_2_cc1_out,
    // src_sel_2.cc2,
    output wire [ 5:0] src_sel_2_cc2_out,
    // src_sel_2.cc3,
    output wire [ 5:0] src_sel_2_cc3_out,
    // src_sel_3.cc0,
    output wire [ 5:0] src_sel_3_cc0_out,
    // src_sel_3.cc1,
    output wire [ 5:0] src_sel_3_cc1_out,
    // src_sel_3.cc2,
    output wire [ 5:0] src_sel_3_cc2_out,
    // src_sel_3.cc3,
    output wire [ 5:0] src_sel_3_cc3_out,
    // src_sel_4.cc0,
    output wire [ 5:0] src_sel_4_cc0_out,
    // src_sel_4.cc1,
    output wire [ 5:0] src_sel_4_cc1_out,
    // src_sel_4.cc2,
    output wire [ 5:0] src_sel_4_cc2_out,
    // src_sel_4.cc3,
    output wire [ 5:0] src_sel_4_cc3_out,
    // src_sel_5.cc0,
    output wire [ 5:0] src_sel_5_cc0_out,
    // src_sel_5.cc1,
    output wire [ 5:0] src_sel_5_cc1_out,
    // src_sel_5.cc2,
    output wire [ 5:0] src_sel_5_cc2_out,
    // src_sel_5.cc3,
    output wire [ 5:0] src_sel_5_cc3_out,
    // ram_mode.val,
    output wire [ 2:0] ram_mode_val_out,
    // cw0_freq.val,
    output wire [19:0] cw0_freq_val_out,
    // cw0_pow.val,
    output wire [15:0] cw0_pow_val_out,
    // cw1_freq.val,
    output wire [19:0] cw1_freq_val_out,
    // cw1_pow.val,
    output wire [15:0] cw1_pow_val_out,
    // injt_ram_addr_msb.val,
    output wire [ 6:0] injt_ram_addr_msb_val_out,
    // ram0_offset.val,
    output wire [19:0] ram0_offset_val_out,
    // ram1_offset.val,
    output wire [19:0] ram1_offset_val_out,
    // ram2_offset.val,
    output wire [19:0] ram2_offset_val_out,
    // cap_sel.cc,
    output wire [ 5:0] cap_sel_cc_out,
    // cap_sel.pos,
    output wire [ 0:0] cap_sel_pos_out,
    // cap_mode.val,
    output wire [ 1:0] cap_mode_val_out,
    // cap_offset.val,
    output wire [18:0] cap_offset_val_out,
    // cap_len.val,
    output wire [ 4:0] cap_len_val_out,
    // cap_ctrl.trigger,
    input  wire [ 0:0] cap_ctrl_trigger_in,
    output wire [ 0:0] cap_ctrl_trigger_out,
    // cap_ctrl.force,
    input  wire [ 0:0] cap_ctrl_force_in,
    output wire [ 0:0] cap_ctrl_force_out,
    // cap_ctrl.status,
    input  wire [ 0:0] cap_ctrl_status_in,
    // cap_ram_addr_msb.val,
    output wire [ 3:0] cap_ram_addr_msb_val_out,
    // injt_ram,
    output wire [12:0] injt_ram_addr,
    output wire        injt_ram_en,
    output wire        injt_ram_we,
    output wire [31:0] injt_ram_din,
    input  wire [31:0] injt_ram_dout,
    input  wire        injt_ram_valid,
    // cap_ram,
    output wire [12:0] cap_ram_addr,
    output wire        cap_ram_en,
    output wire        cap_ram_we,
    output wire [31:0] cap_ram_din,
    input  wire [31:0] cap_ram_dout,
    input  wire        cap_ram_valid
);

    wire        aclk;
    wire        aresetn;

    reg         init_n;

    wire        aw_hsk;
    reg  [16:0] aw_addr;
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
    reg  [16:0] ar_addr;
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

    reg  [16:0] int_addr;
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
            aw_addr <= 1'sb0;
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
            w_data <= 1'sb0;
        end else if (w_hsk) begin
            w_data <= s_axi_wdata;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            w_strb <= 1'sb0;
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
            b_resp <= 2'b00;
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
            ar_addr <= 1'sb0;
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
            r_data <= 1'sb0;
        end else if (~r_valid && int_rd_pend) begin
            r_data <= int_rd_data_reg;
        end else if (~r_valid && int_rd_req && int_rd_ack) begin
            r_data <= int_rd_data;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            r_resp <= 2'b00;
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
            int_addr <= 1'sb0;
        end else if (aw_req && w_req && ~int_wr_req) begin
            int_addr <= aw_addr;
        end else if (~(aw_req && w_req) && ar_req && ~int_rd_req) begin
            int_addr <= ar_addr;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_wr_data <= 1'sb0;
        end else if (w_req && aw_req && ~int_wr_req) begin
            int_wr_data <= w_data;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_wr_strb <= 2'b00;
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

    assign version_val_strb = (int_addr[16:2] == 'h0);

    wire scratch0_val_strb;

    assign scratch0_val_strb = (int_addr[16:2] == 'h1);

    wire scratch1_val_strb;

    assign scratch1_val_strb = (int_addr[16:2] == 'h2);

    wire src_sel_0_cc0_strb;

    assign src_sel_0_cc0_strb = (int_addr[16:2] == 'h5);

    wire src_sel_0_cc1_strb;

    assign src_sel_0_cc1_strb = (int_addr[16:2] == 'h5);

    wire src_sel_0_cc2_strb;

    assign src_sel_0_cc2_strb = (int_addr[16:2] == 'h5);

    wire src_sel_0_cc3_strb;

    assign src_sel_0_cc3_strb = (int_addr[16:2] == 'h5);

    wire src_sel_1_cc0_strb;

    assign src_sel_1_cc0_strb = (int_addr[16:2] == 'h6);

    wire src_sel_1_cc1_strb;

    assign src_sel_1_cc1_strb = (int_addr[16:2] == 'h6);

    wire src_sel_1_cc2_strb;

    assign src_sel_1_cc2_strb = (int_addr[16:2] == 'h6);

    wire src_sel_1_cc3_strb;

    assign src_sel_1_cc3_strb = (int_addr[16:2] == 'h6);

    wire src_sel_2_cc0_strb;

    assign src_sel_2_cc0_strb = (int_addr[16:2] == 'h7);

    wire src_sel_2_cc1_strb;

    assign src_sel_2_cc1_strb = (int_addr[16:2] == 'h7);

    wire src_sel_2_cc2_strb;

    assign src_sel_2_cc2_strb = (int_addr[16:2] == 'h7);

    wire src_sel_2_cc3_strb;

    assign src_sel_2_cc3_strb = (int_addr[16:2] == 'h7);

    wire src_sel_3_cc0_strb;

    assign src_sel_3_cc0_strb = (int_addr[16:2] == 'h8);

    wire src_sel_3_cc1_strb;

    assign src_sel_3_cc1_strb = (int_addr[16:2] == 'h8);

    wire src_sel_3_cc2_strb;

    assign src_sel_3_cc2_strb = (int_addr[16:2] == 'h8);

    wire src_sel_3_cc3_strb;

    assign src_sel_3_cc3_strb = (int_addr[16:2] == 'h8);

    wire src_sel_4_cc0_strb;

    assign src_sel_4_cc0_strb = (int_addr[16:2] == 'h9);

    wire src_sel_4_cc1_strb;

    assign src_sel_4_cc1_strb = (int_addr[16:2] == 'h9);

    wire src_sel_4_cc2_strb;

    assign src_sel_4_cc2_strb = (int_addr[16:2] == 'h9);

    wire src_sel_4_cc3_strb;

    assign src_sel_4_cc3_strb = (int_addr[16:2] == 'h9);

    wire src_sel_5_cc0_strb;

    assign src_sel_5_cc0_strb = (int_addr[16:2] == 'ha);

    wire src_sel_5_cc1_strb;

    assign src_sel_5_cc1_strb = (int_addr[16:2] == 'ha);

    wire src_sel_5_cc2_strb;

    assign src_sel_5_cc2_strb = (int_addr[16:2] == 'ha);

    wire src_sel_5_cc3_strb;

    assign src_sel_5_cc3_strb = (int_addr[16:2] == 'ha);

    wire ram_mode_val_strb;

    assign ram_mode_val_strb = (int_addr[16:2] == 'hc);

    wire cw0_freq_val_strb;

    assign cw0_freq_val_strb = (int_addr[16:2] == 'h10);

    wire cw0_pow_val_strb;

    assign cw0_pow_val_strb = (int_addr[16:2] == 'h11);

    wire cw1_freq_val_strb;

    assign cw1_freq_val_strb = (int_addr[16:2] == 'h12);

    wire cw1_pow_val_strb;

    assign cw1_pow_val_strb = (int_addr[16:2] == 'h13);

    wire injt_ram_addr_msb_val_strb;

    assign injt_ram_addr_msb_val_strb = (int_addr[16:2] == 'h40);

    wire ram0_offset_val_strb;

    assign ram0_offset_val_strb = (int_addr[16:2] == 'h41);

    wire ram1_offset_val_strb;

    assign ram1_offset_val_strb = (int_addr[16:2] == 'h42);

    wire ram2_offset_val_strb;

    assign ram2_offset_val_strb = (int_addr[16:2] == 'h43);

    wire cap_sel_cc_strb;

    assign cap_sel_cc_strb = (int_addr[16:2] == 'h80);

    wire cap_sel_pos_strb;

    assign cap_sel_pos_strb = (int_addr[16:2] == 'h80);

    wire cap_mode_val_strb;

    assign cap_mode_val_strb = (int_addr[16:2] == 'h81);

    wire cap_offset_val_strb;

    assign cap_offset_val_strb = (int_addr[16:2] == 'h82);

    wire cap_len_val_strb;

    assign cap_len_val_strb = (int_addr[16:2] == 'h83);

    wire cap_ctrl_trigger_strb;

    assign cap_ctrl_trigger_strb = (int_addr[16:2] == 'h84);

    wire cap_ctrl_force_strb;

    assign cap_ctrl_force_strb = (int_addr[16:2] == 'h84);

    wire cap_ctrl_status_strb;

    assign cap_ctrl_status_strb = (int_addr[16:2] == 'h84);

    wire cap_ram_addr_msb_val_strb;

    assign cap_ram_addr_msb_val_strb = (int_addr[16:2] == 'h88);

    wire injt_ram_strb;

    assign injt_ram_strb = (int_addr[16:15] == 'h2);

    wire cap_ram_strb;

    assign cap_ram_strb = (int_addr[16:15] == 'h3);

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
        if (src_sel_0_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_0_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_0_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_0_cc3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_1_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_1_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_1_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_1_cc3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_2_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_2_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_2_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_2_cc3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_3_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_3_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_3_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_3_cc3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_4_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_4_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_4_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_4_cc3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_5_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_5_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_5_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (src_sel_5_cc3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ram_mode_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cw0_freq_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cw0_pow_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cw1_freq_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cw1_pow_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (injt_ram_addr_msb_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ram0_offset_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ram1_offset_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ram2_offset_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cap_sel_cc_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cap_sel_pos_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cap_mode_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cap_offset_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cap_len_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cap_ctrl_trigger_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cap_ctrl_force_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cap_ctrl_status_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cap_ram_addr_msb_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (injt_ram_strb) begin
            int_wr_err <= 1'b0;
        end
        if (cap_ram_strb) begin
            int_wr_err <= 1'b0;
        end
    end

    always @(posedge s_axi_aclk) begin
        int_rd_ack <= int_rd_en;
        if (injt_ram_strb) begin
            int_rd_ack <= int_rd_req && injt_ram_valid;
        end
        if (cap_ram_strb) begin
            int_rd_ack <= int_rd_req && cap_ram_valid;
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
        if (src_sel_0_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_0_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_0_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_0_cc3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_1_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_1_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_1_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_1_cc3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_2_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_2_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_2_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_2_cc3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_3_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_3_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_3_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_3_cc3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_4_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_4_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_4_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_4_cc3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_5_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_5_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_5_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (src_sel_5_cc3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ram_mode_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cw0_freq_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cw0_pow_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cw1_freq_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cw1_pow_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (injt_ram_addr_msb_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ram0_offset_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ram1_offset_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ram2_offset_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cap_sel_cc_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cap_sel_pos_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cap_mode_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cap_offset_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cap_len_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cap_ctrl_trigger_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cap_ctrl_force_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cap_ctrl_status_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cap_ram_addr_msb_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (injt_ram_strb) begin
            int_rd_err <= 1'b0;
        end
        if (cap_ram_strb) begin
            int_rd_err <= 1'b0;
        end
    end


    //--------------------------------------------------------------------------
    // Field logic
    //--------------------------------------------------------------------------

    // Field version.val @'h0[31:0]

    reg [31:0] version_val_value;

    initial begin
        version_val_value = 'h20240525;
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

    // Field src_sel_0.cc0 @'h14[5:0]

    reg [5:0] src_sel_0_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_0_cc0_value <= 'h0;
        end else if (int_wr_en && src_sel_0_cc0_strb) begin
            src_sel_0_cc0_value <= int_wr_data[5:0];
        end
    end

    assign src_sel_0_cc0_out = src_sel_0_cc0_value;

    // Field src_sel_0.cc1 @'h14[13:8]

    reg [5:0] src_sel_0_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_0_cc1_value <= 'h0;
        end else if (int_wr_en && src_sel_0_cc1_strb) begin
            src_sel_0_cc1_value <= int_wr_data[13:8];
        end
    end

    assign src_sel_0_cc1_out = src_sel_0_cc1_value;

    // Field src_sel_0.cc2 @'h14[21:16]

    reg [5:0] src_sel_0_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_0_cc2_value <= 'h0;
        end else if (int_wr_en && src_sel_0_cc2_strb) begin
            src_sel_0_cc2_value <= int_wr_data[21:16];
        end
    end

    assign src_sel_0_cc2_out = src_sel_0_cc2_value;

    // Field src_sel_0.cc3 @'h14[29:24]

    reg [5:0] src_sel_0_cc3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_0_cc3_value <= 'h0;
        end else if (int_wr_en && src_sel_0_cc3_strb) begin
            src_sel_0_cc3_value <= int_wr_data[29:24];
        end
    end

    assign src_sel_0_cc3_out = src_sel_0_cc3_value;

    // Field src_sel_1.cc0 @'h18[5:0]

    reg [5:0] src_sel_1_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_1_cc0_value <= 'h0;
        end else if (int_wr_en && src_sel_1_cc0_strb) begin
            src_sel_1_cc0_value <= int_wr_data[5:0];
        end
    end

    assign src_sel_1_cc0_out = src_sel_1_cc0_value;

    // Field src_sel_1.cc1 @'h18[13:8]

    reg [5:0] src_sel_1_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_1_cc1_value <= 'h0;
        end else if (int_wr_en && src_sel_1_cc1_strb) begin
            src_sel_1_cc1_value <= int_wr_data[13:8];
        end
    end

    assign src_sel_1_cc1_out = src_sel_1_cc1_value;

    // Field src_sel_1.cc2 @'h18[21:16]

    reg [5:0] src_sel_1_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_1_cc2_value <= 'h0;
        end else if (int_wr_en && src_sel_1_cc2_strb) begin
            src_sel_1_cc2_value <= int_wr_data[21:16];
        end
    end

    assign src_sel_1_cc2_out = src_sel_1_cc2_value;

    // Field src_sel_1.cc3 @'h18[29:24]

    reg [5:0] src_sel_1_cc3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_1_cc3_value <= 'h0;
        end else if (int_wr_en && src_sel_1_cc3_strb) begin
            src_sel_1_cc3_value <= int_wr_data[29:24];
        end
    end

    assign src_sel_1_cc3_out = src_sel_1_cc3_value;

    // Field src_sel_2.cc0 @'h1c[5:0]

    reg [5:0] src_sel_2_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_2_cc0_value <= 'h0;
        end else if (int_wr_en && src_sel_2_cc0_strb) begin
            src_sel_2_cc0_value <= int_wr_data[5:0];
        end
    end

    assign src_sel_2_cc0_out = src_sel_2_cc0_value;

    // Field src_sel_2.cc1 @'h1c[13:8]

    reg [5:0] src_sel_2_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_2_cc1_value <= 'h0;
        end else if (int_wr_en && src_sel_2_cc1_strb) begin
            src_sel_2_cc1_value <= int_wr_data[13:8];
        end
    end

    assign src_sel_2_cc1_out = src_sel_2_cc1_value;

    // Field src_sel_2.cc2 @'h1c[21:16]

    reg [5:0] src_sel_2_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_2_cc2_value <= 'h0;
        end else if (int_wr_en && src_sel_2_cc2_strb) begin
            src_sel_2_cc2_value <= int_wr_data[21:16];
        end
    end

    assign src_sel_2_cc2_out = src_sel_2_cc2_value;

    // Field src_sel_2.cc3 @'h1c[29:24]

    reg [5:0] src_sel_2_cc3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_2_cc3_value <= 'h0;
        end else if (int_wr_en && src_sel_2_cc3_strb) begin
            src_sel_2_cc3_value <= int_wr_data[29:24];
        end
    end

    assign src_sel_2_cc3_out = src_sel_2_cc3_value;

    // Field src_sel_3.cc0 @'h20[5:0]

    reg [5:0] src_sel_3_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_3_cc0_value <= 'h0;
        end else if (int_wr_en && src_sel_3_cc0_strb) begin
            src_sel_3_cc0_value <= int_wr_data[5:0];
        end
    end

    assign src_sel_3_cc0_out = src_sel_3_cc0_value;

    // Field src_sel_3.cc1 @'h20[13:8]

    reg [5:0] src_sel_3_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_3_cc1_value <= 'h0;
        end else if (int_wr_en && src_sel_3_cc1_strb) begin
            src_sel_3_cc1_value <= int_wr_data[13:8];
        end
    end

    assign src_sel_3_cc1_out = src_sel_3_cc1_value;

    // Field src_sel_3.cc2 @'h20[21:16]

    reg [5:0] src_sel_3_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_3_cc2_value <= 'h0;
        end else if (int_wr_en && src_sel_3_cc2_strb) begin
            src_sel_3_cc2_value <= int_wr_data[21:16];
        end
    end

    assign src_sel_3_cc2_out = src_sel_3_cc2_value;

    // Field src_sel_3.cc3 @'h20[29:24]

    reg [5:0] src_sel_3_cc3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_3_cc3_value <= 'h0;
        end else if (int_wr_en && src_sel_3_cc3_strb) begin
            src_sel_3_cc3_value <= int_wr_data[29:24];
        end
    end

    assign src_sel_3_cc3_out = src_sel_3_cc3_value;

    // Field src_sel_4.cc0 @'h24[5:0]

    reg [5:0] src_sel_4_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_4_cc0_value <= 'h0;
        end else if (int_wr_en && src_sel_4_cc0_strb) begin
            src_sel_4_cc0_value <= int_wr_data[5:0];
        end
    end

    assign src_sel_4_cc0_out = src_sel_4_cc0_value;

    // Field src_sel_4.cc1 @'h24[13:8]

    reg [5:0] src_sel_4_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_4_cc1_value <= 'h0;
        end else if (int_wr_en && src_sel_4_cc1_strb) begin
            src_sel_4_cc1_value <= int_wr_data[13:8];
        end
    end

    assign src_sel_4_cc1_out = src_sel_4_cc1_value;

    // Field src_sel_4.cc2 @'h24[21:16]

    reg [5:0] src_sel_4_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_4_cc2_value <= 'h0;
        end else if (int_wr_en && src_sel_4_cc2_strb) begin
            src_sel_4_cc2_value <= int_wr_data[21:16];
        end
    end

    assign src_sel_4_cc2_out = src_sel_4_cc2_value;

    // Field src_sel_4.cc3 @'h24[29:24]

    reg [5:0] src_sel_4_cc3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_4_cc3_value <= 'h0;
        end else if (int_wr_en && src_sel_4_cc3_strb) begin
            src_sel_4_cc3_value <= int_wr_data[29:24];
        end
    end

    assign src_sel_4_cc3_out = src_sel_4_cc3_value;

    // Field src_sel_5.cc0 @'h28[5:0]

    reg [5:0] src_sel_5_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_5_cc0_value <= 'h0;
        end else if (int_wr_en && src_sel_5_cc0_strb) begin
            src_sel_5_cc0_value <= int_wr_data[5:0];
        end
    end

    assign src_sel_5_cc0_out = src_sel_5_cc0_value;

    // Field src_sel_5.cc1 @'h28[13:8]

    reg [5:0] src_sel_5_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_5_cc1_value <= 'h0;
        end else if (int_wr_en && src_sel_5_cc1_strb) begin
            src_sel_5_cc1_value <= int_wr_data[13:8];
        end
    end

    assign src_sel_5_cc1_out = src_sel_5_cc1_value;

    // Field src_sel_5.cc2 @'h28[21:16]

    reg [5:0] src_sel_5_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_5_cc2_value <= 'h0;
        end else if (int_wr_en && src_sel_5_cc2_strb) begin
            src_sel_5_cc2_value <= int_wr_data[21:16];
        end
    end

    assign src_sel_5_cc2_out = src_sel_5_cc2_value;

    // Field src_sel_5.cc3 @'h28[29:24]

    reg [5:0] src_sel_5_cc3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            src_sel_5_cc3_value <= 'h0;
        end else if (int_wr_en && src_sel_5_cc3_strb) begin
            src_sel_5_cc3_value <= int_wr_data[29:24];
        end
    end

    assign src_sel_5_cc3_out = src_sel_5_cc3_value;

    // Field ram_mode.val @'h30[2:0]

    reg [2:0] ram_mode_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ram_mode_val_value <= 'h0;
        end else if (int_wr_en && ram_mode_val_strb) begin
            ram_mode_val_value <= int_wr_data[2:0];
        end
    end

    assign ram_mode_val_out = ram_mode_val_value;

    // Field cw0_freq.val @'h40[19:0]

    reg [19:0] cw0_freq_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            cw0_freq_val_value <= 'h640;
        end else if (int_wr_en && cw0_freq_val_strb) begin
            cw0_freq_val_value <= int_wr_data[19:0];
        end
    end

    assign cw0_freq_val_out = cw0_freq_val_value;

    // Field cw0_pow.val @'h44[15:0]

    reg [15:0] cw0_pow_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            cw0_pow_val_value <= 'h16c3;
        end else if (int_wr_en && cw0_pow_val_strb) begin
            cw0_pow_val_value <= int_wr_data[15:0];
        end
    end

    assign cw0_pow_val_out = cw0_pow_val_value;

    // Field cw1_freq.val @'h48[19:0]

    reg [19:0] cw1_freq_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            cw1_freq_val_value <= 'hbf9c0;
        end else if (int_wr_en && cw1_freq_val_strb) begin
            cw1_freq_val_value <= int_wr_data[19:0];
        end
    end

    assign cw1_freq_val_out = cw1_freq_val_value;

    // Field cw1_pow.val @'h4c[15:0]

    reg [15:0] cw1_pow_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            cw1_pow_val_value <= 'h0;
        end else if (int_wr_en && cw1_pow_val_strb) begin
            cw1_pow_val_value <= int_wr_data[15:0];
        end
    end

    assign cw1_pow_val_out = cw1_pow_val_value;

    // Field injt_ram_addr_msb.val @'h100[6:0]

    reg [6:0] injt_ram_addr_msb_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            injt_ram_addr_msb_val_value <= 'h0;
        end else if (int_wr_en && injt_ram_addr_msb_val_strb) begin
            injt_ram_addr_msb_val_value <= int_wr_data[6:0];
        end
    end

    assign injt_ram_addr_msb_val_out = injt_ram_addr_msb_val_value;

    // Field ram0_offset.val @'h104[19:0]

    reg [19:0] ram0_offset_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ram0_offset_val_value <= 'h0;
        end else if (int_wr_en && ram0_offset_val_strb) begin
            ram0_offset_val_value <= int_wr_data[19:0];
        end
    end

    assign ram0_offset_val_out = ram0_offset_val_value;

    // Field ram1_offset.val @'h108[19:0]

    reg [19:0] ram1_offset_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ram1_offset_val_value <= 'h50000;
        end else if (int_wr_en && ram1_offset_val_strb) begin
            ram1_offset_val_value <= int_wr_data[19:0];
        end
    end

    assign ram1_offset_val_out = ram1_offset_val_value;

    // Field ram2_offset.val @'h10c[19:0]

    reg [19:0] ram2_offset_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ram2_offset_val_value <= 'ha0000;
        end else if (int_wr_en && ram2_offset_val_strb) begin
            ram2_offset_val_value <= int_wr_data[19:0];
        end
    end

    assign ram2_offset_val_out = ram2_offset_val_value;

    // Field cap_sel.cc @'h200[5:0]

    reg [5:0] cap_sel_cc_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            cap_sel_cc_value <= 'h0;
        end else if (int_wr_en && cap_sel_cc_strb) begin
            cap_sel_cc_value <= int_wr_data[5:0];
        end
    end

    assign cap_sel_cc_out = cap_sel_cc_value;

    // Field cap_sel.pos @'h200[8:8]

    reg [0:0] cap_sel_pos_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            cap_sel_pos_value <= 'h0;
        end else if (int_wr_en && cap_sel_pos_strb) begin
            cap_sel_pos_value <= int_wr_data[8:8];
        end
    end

    assign cap_sel_pos_out = cap_sel_pos_value;

    // Field cap_mode.val @'h204[1:0]

    reg [1:0] cap_mode_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            cap_mode_val_value <= 'h0;
        end else if (int_wr_en && cap_mode_val_strb) begin
            cap_mode_val_value <= int_wr_data[1:0];
        end
    end

    assign cap_mode_val_out = cap_mode_val_value;

    // Field cap_offset.val @'h208[18:0]

    reg [18:0] cap_offset_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            cap_offset_val_value <= 'h0;
        end else if (int_wr_en && cap_offset_val_strb) begin
            cap_offset_val_value <= int_wr_data[18:0];
        end
    end

    assign cap_offset_val_out = cap_offset_val_value;

    // Field cap_len.val @'h20c[4:0]

    reg [4:0] cap_len_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            cap_len_val_value <= 'h1f;
        end else if (int_wr_en && cap_len_val_strb) begin
            cap_len_val_value <= int_wr_data[4:0];
        end
    end

    assign cap_len_val_out = cap_len_val_value;

    // Field cap_ctrl.trigger @'h210[0:0]

    reg [0:0] cap_ctrl_trigger_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            cap_ctrl_trigger_value <= 'h0;
        end else if (int_wr_en && cap_ctrl_trigger_strb) begin
            cap_ctrl_trigger_value <= int_wr_data[0:0];
        end else begin
            cap_ctrl_trigger_value <= cap_ctrl_trigger_in;
        end
    end

    assign cap_ctrl_trigger_out = cap_ctrl_trigger_value;

    // Field cap_ctrl.force @'h210[1:1]

    reg [0:0] cap_ctrl_force_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            cap_ctrl_force_value <= 'h0;
        end else if (int_wr_en && cap_ctrl_force_strb) begin
            cap_ctrl_force_value <= int_wr_data[1:1];
        end else begin
            cap_ctrl_force_value <= cap_ctrl_force_in;
        end
    end

    assign cap_ctrl_force_out = cap_ctrl_force_value;

    // Field cap_ctrl.status @'h210[4:4]

    reg [0:0] cap_ctrl_status_value;

    always @(*) begin
        cap_ctrl_status_value = cap_ctrl_status_in;
    end

    // Field cap_ram_addr_msb.val @'h220[3:0]

    reg [3:0] cap_ram_addr_msb_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            cap_ram_addr_msb_val_value <= 'h0;
        end else if (int_wr_en && cap_ram_addr_msb_val_strb) begin
            cap_ram_addr_msb_val_value <= int_wr_data[3:0];
        end
    end

    assign cap_ram_addr_msb_val_out = cap_ram_addr_msb_val_value;


    //--------------------------------------------------------------------------
    // Memory logic
    //--------------------------------------------------------------------------

    // Memory injt_ram @'h10000

    assign injt_ram_addr = int_addr[14:2];
    assign injt_ram_en   = ((int_wr_en || int_rd_en) && injt_ram_strb);
    assign injt_ram_we   = (int_wr_en && injt_ram_strb);
    assign injt_ram_din  = int_wr_data[31:0];

    // Memory cap_ram @'h18000

    assign cap_ram_addr = int_addr[14:2];
    assign cap_ram_en   = ((int_wr_en || int_rd_en) && cap_ram_strb);
    assign cap_ram_we   = (int_wr_en && cap_ram_strb);
    assign cap_ram_din  = int_wr_data[31:0];


    //--------------------------------------------------------------------------
    // Register readback
    //--------------------------------------------------------------------------

    reg [31:0] field_rd_data;
    reg [31:0] field_rd_data_next;

    reg        field_strb;

    always @(*) begin
        field_rd_data_next = 1'sb0;
        if (int_rd_en && version_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | version_val_value;
        end
        if (int_rd_en && scratch0_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | scratch0_val_value;
        end
        if (int_rd_en && scratch1_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | scratch1_val_value;
        end
        if (int_rd_en && src_sel_0_cc0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | src_sel_0_cc0_value;
        end
        if (int_rd_en && src_sel_0_cc1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | src_sel_0_cc1_value;
        end
        if (int_rd_en && src_sel_0_cc2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | src_sel_0_cc2_value;
        end
        if (int_rd_en && src_sel_0_cc3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | src_sel_0_cc3_value;
        end
        if (int_rd_en && src_sel_1_cc0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | src_sel_1_cc0_value;
        end
        if (int_rd_en && src_sel_1_cc1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | src_sel_1_cc1_value;
        end
        if (int_rd_en && src_sel_1_cc2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | src_sel_1_cc2_value;
        end
        if (int_rd_en && src_sel_1_cc3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | src_sel_1_cc3_value;
        end
        if (int_rd_en && src_sel_2_cc0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | src_sel_2_cc0_value;
        end
        if (int_rd_en && src_sel_2_cc1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | src_sel_2_cc1_value;
        end
        if (int_rd_en && src_sel_2_cc2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | src_sel_2_cc2_value;
        end
        if (int_rd_en && src_sel_2_cc3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | src_sel_2_cc3_value;
        end
        if (int_rd_en && src_sel_3_cc0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | src_sel_3_cc0_value;
        end
        if (int_rd_en && src_sel_3_cc1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | src_sel_3_cc1_value;
        end
        if (int_rd_en && src_sel_3_cc2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | src_sel_3_cc2_value;
        end
        if (int_rd_en && src_sel_3_cc3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | src_sel_3_cc3_value;
        end
        if (int_rd_en && src_sel_4_cc0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | src_sel_4_cc0_value;
        end
        if (int_rd_en && src_sel_4_cc1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | src_sel_4_cc1_value;
        end
        if (int_rd_en && src_sel_4_cc2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | src_sel_4_cc2_value;
        end
        if (int_rd_en && src_sel_4_cc3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | src_sel_4_cc3_value;
        end
        if (int_rd_en && src_sel_5_cc0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | src_sel_5_cc0_value;
        end
        if (int_rd_en && src_sel_5_cc1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | src_sel_5_cc1_value;
        end
        if (int_rd_en && src_sel_5_cc2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | src_sel_5_cc2_value;
        end
        if (int_rd_en && src_sel_5_cc3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | src_sel_5_cc3_value;
        end
        if (int_rd_en && ram_mode_val_strb) begin
            field_rd_data_next[2:0] = field_rd_data_next[2:0] | ram_mode_val_value;
        end
        if (int_rd_en && cw0_freq_val_strb) begin
            field_rd_data_next[19:0] = field_rd_data_next[19:0] | cw0_freq_val_value;
        end
        if (int_rd_en && cw0_pow_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | cw0_pow_val_value;
        end
        if (int_rd_en && cw1_freq_val_strb) begin
            field_rd_data_next[19:0] = field_rd_data_next[19:0] | cw1_freq_val_value;
        end
        if (int_rd_en && cw1_pow_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | cw1_pow_val_value;
        end
        if (int_rd_en && injt_ram_addr_msb_val_strb) begin
            field_rd_data_next[6:0] = field_rd_data_next[6:0] | injt_ram_addr_msb_val_value;
        end
        if (int_rd_en && ram0_offset_val_strb) begin
            field_rd_data_next[19:0] = field_rd_data_next[19:0] | ram0_offset_val_value;
        end
        if (int_rd_en && ram1_offset_val_strb) begin
            field_rd_data_next[19:0] = field_rd_data_next[19:0] | ram1_offset_val_value;
        end
        if (int_rd_en && ram2_offset_val_strb) begin
            field_rd_data_next[19:0] = field_rd_data_next[19:0] | ram2_offset_val_value;
        end
        if (int_rd_en && cap_sel_cc_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | cap_sel_cc_value;
        end
        if (int_rd_en && cap_sel_pos_strb) begin
            field_rd_data_next[8:8] = field_rd_data_next[8:8] | cap_sel_pos_value;
        end
        if (int_rd_en && cap_mode_val_strb) begin
            field_rd_data_next[1:0] = field_rd_data_next[1:0] | cap_mode_val_value;
        end
        if (int_rd_en && cap_offset_val_strb) begin
            field_rd_data_next[18:0] = field_rd_data_next[18:0] | cap_offset_val_value;
        end
        if (int_rd_en && cap_len_val_strb) begin
            field_rd_data_next[4:0] = field_rd_data_next[4:0] | cap_len_val_value;
        end
        if (int_rd_en && cap_ctrl_trigger_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | cap_ctrl_trigger_value;
        end
        if (int_rd_en && cap_ctrl_force_strb) begin
            field_rd_data_next[1:1] = field_rd_data_next[1:1] | cap_ctrl_force_value;
        end
        if (int_rd_en && cap_ctrl_status_strb) begin
            field_rd_data_next[4:4] = field_rd_data_next[4:4] | cap_ctrl_status_value;
        end
        if (int_rd_en && cap_ram_addr_msb_val_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | cap_ram_addr_msb_val_value;
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
        if (int_rd_en && src_sel_0_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_0_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_0_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_0_cc3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_1_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_1_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_1_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_1_cc3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_2_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_2_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_2_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_2_cc3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_3_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_3_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_3_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_3_cc3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_4_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_4_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_4_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_4_cc3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_5_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_5_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_5_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && src_sel_5_cc3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ram_mode_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cw0_freq_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cw0_pow_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cw1_freq_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cw1_pow_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && injt_ram_addr_msb_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ram0_offset_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ram1_offset_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ram2_offset_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cap_sel_cc_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cap_sel_pos_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cap_mode_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cap_offset_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cap_len_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cap_ctrl_trigger_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cap_ctrl_force_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cap_ctrl_status_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && cap_ram_addr_msb_val_strb) begin
            field_strb <= 1'b1;
        end
    end

    always @(*) begin
        int_rd_data = 1'sb0;
        if (field_strb) begin
            int_rd_data = int_rd_data | field_rd_data;
        end
        if (injt_ram_strb) begin
            int_rd_data[31:0] = int_rd_data[31:0] | injt_ram_dout;
        end
        if (cap_ram_strb) begin
            int_rd_data[31:0] = int_rd_data[31:0] | cap_ram_dout;
        end
    end

endmodule

`default_nettype wire

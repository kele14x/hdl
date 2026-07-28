// File: oran_slave_regs.v
// Brief: Register block generate for oran_slave
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_slave_regs (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    //
    input  wire [10:0] s_axi_awaddr,
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
    input  wire [10:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    //
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    // tick.tick,
    output wire [ 0:0] tick_tick_out,
    // tick.clear,
    output wire [ 0:0] tick_clear_out,
    // defm_ctrl.en,
    output wire [ 0:0] defm_ctrl_en_out,
    // defm_ctrl.has_udcomphdr,
    output wire [ 0:0] defm_ctrl_has_udcomphdr_out,
    // defm_ctrl.udcompmeth,
    output wire [ 3:0] defm_ctrl_udcompmeth_out,
    // defm_ctrl.udiqwidth,
    output wire [ 3:0] defm_ctrl_udiqwidth_out,
    // defm_syml_rd_shift.val,
    output wire [11:0] defm_syml_rd_shift_val_out,
    // defm_src_mac_l.val,
    input  wire [31:0] defm_src_mac_l_val_in,
    // defm_src_mac_h.val,
    input  wire [15:0] defm_src_mac_h_val_in,
    // defm_buffer_addr_offset_0.val,
    output wire [15:0] defm_buffer_addr_offset_0_val_out,
    // defm_buffer_addr_offset_1.val,
    output wire [15:0] defm_buffer_addr_offset_1_val_out,
    // defm_buffer_addr_offset_2.val,
    output wire [15:0] defm_buffer_addr_offset_2_val_out,
    // defm_buffer_addr_offset_3.val,
    output wire [15:0] defm_buffer_addr_offset_3_val_out,
    // defm_buffer_addr_offset_4.val,
    output wire [15:0] defm_buffer_addr_offset_4_val_out,
    // defm_buffer_addr_offset_5.val,
    output wire [15:0] defm_buffer_addr_offset_5_val_out,
    // defm_buffer_addr_offset_6.val,
    output wire [15:0] defm_buffer_addr_offset_6_val_out,
    // defm_buffer_addr_offset_7.val,
    output wire [15:0] defm_buffer_addr_offset_7_val_out,
    // defm_buffer_addr_offset_8.val,
    output wire [15:0] defm_buffer_addr_offset_8_val_out,
    // defm_buffer_addr_offset_9.val,
    output wire [15:0] defm_buffer_addr_offset_9_val_out,
    // total_pkt_cnt_lo.val,
    input  wire [31:0] total_pkt_cnt_lo_val_in,
    // total_pkt_cnt_hi.val,
    input  wire [15:0] total_pkt_cnt_hi_val_in,
    // oran_pkt_cnt_lo.val,
    input  wire [31:0] oran_pkt_cnt_lo_val_in,
    // oran_pkt_cnt_hi.val,
    input  wire [15:0] oran_pkt_cnt_hi_val_in,
    // ontime_pkt_cnt_lo.val,
    input  wire [31:0] ontime_pkt_cnt_lo_val_in,
    // ontime_pkt_cnt_hi.val,
    input  wire [15:0] ontime_pkt_cnt_hi_val_in,
    // early_pkt_cnt_lo.val,
    input  wire [31:0] early_pkt_cnt_lo_val_in,
    // early_pkt_cnt_hi.val,
    input  wire [15:0] early_pkt_cnt_hi_val_in,
    // late_pkt_cnt_lo.val,
    input  wire [31:0] late_pkt_cnt_lo_val_in,
    // late_pkt_cnt_hi.val,
    input  wire [15:0] late_pkt_cnt_hi_val_in,
    // earliest_u_pkt.val,
    input  wire [ 8:0] earliest_u_pkt_val_in,
    // latest_u_pkt.val,
    input  wire [ 8:0] latest_u_pkt_val_in,
    // fram_ctrl.en,
    output wire [ 0:0] fram_ctrl_en_out,
    // fram_ctrl.has_udcomphdr,
    output wire [ 0:0] fram_ctrl_has_udcomphdr_out,
    // fram_ctrl.udcompmeth,
    output wire [ 3:0] fram_ctrl_udcompmeth_out,
    // fram_ctrl.udiqwidth,
    output wire [ 3:0] fram_ctrl_udiqwidth_out,
    // fram_syml_rd_shift.val,
    output wire [10:0] fram_syml_rd_shift_val_out,
    // fram_dest_mac_l.val,
    output wire [31:0] fram_dest_mac_l_val_out,
    // fram_dest_mac_h.val,
    output wire [15:0] fram_dest_mac_h_val_out,
    // fram_src_mac_l.val,
    output wire [31:0] fram_src_mac_l_val_out,
    // fram_src_mac_h.val,
    output wire [15:0] fram_src_mac_h_val_out,
    // fram_vlan_ctrl.vlan_tag,
    output wire [15:0] fram_vlan_ctrl_vlan_tag_out,
    // fram_vlan_ctrl.has_vlan,
    output wire [ 0:0] fram_vlan_ctrl_has_vlan_out,
    // fram_ctrl_buf0
    output wire [ 3:0] fram_ctrl_buf0_addr,
    output wire        fram_ctrl_buf0_en,
    output wire        fram_ctrl_buf0_we,
    output wire [31:0] fram_ctrl_buf0_din,
    input  wire [31:0] fram_ctrl_buf0_dout,
    // fram_mask_buf0
    output wire [ 4:0] fram_mask_buf0_addr,
    output wire        fram_mask_buf0_en,
    output wire        fram_mask_buf0_we,
    output wire [31:0] fram_mask_buf0_din,
    input  wire [31:0] fram_mask_buf0_dout,
    // fram_ctrl_buf1
    output wire [ 3:0] fram_ctrl_buf1_addr,
    output wire        fram_ctrl_buf1_en,
    output wire        fram_ctrl_buf1_we,
    output wire [31:0] fram_ctrl_buf1_din,
    input  wire [31:0] fram_ctrl_buf1_dout,
    // fram_mask_buf1
    output wire [ 4:0] fram_mask_buf1_addr,
    output wire        fram_mask_buf1_en,
    output wire        fram_mask_buf1_we,
    output wire [31:0] fram_mask_buf1_din,
    input  wire [31:0] fram_mask_buf1_dout
);

    wire        aclk;
    wire        aresetn;

    reg         init;

    wire        aw_hsk;
    reg  [10:0] aw_addr;
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
    reg  [10:0] ar_addr;
    reg         ar_ready;
    reg         ar_req;
    reg         ar_ack;

    wire        r_hsk;
    reg  [31:0] r_data;
    reg  [ 1:0] r_resp;
    reg         r_valid;

    // Internal interface signals

    reg  [10:0] int_addr;
    reg  [31:0] int_wr_data;
    reg  [ 3:0] int_wr_strb;
    reg         int_wr_en;
    reg         int_rd_en;

    reg         int_wr_ack;
    reg         int_wr_err;

    reg         int_rd_ack;
    reg         int_rd_err;
    reg  [31:0] int_rd_data;

    wire        unused_reg_inputs;

    assign unused_reg_inputs = &{1'b0, s_axi_awprot, s_axi_arprot, int_addr[1:0], int_wr_strb};


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

    wire version_val_strb;

    assign version_val_strb = (int_addr[10:2] == 'h0);

    wire tick_tick_strb;

    assign tick_tick_strb = (int_addr[10:2] == 'h8);

    wire tick_clear_strb;

    assign tick_clear_strb = (int_addr[10:2] == 'h8);

    wire defm_ctrl_en_strb;

    assign defm_ctrl_en_strb = (int_addr[10:2] == 'h40);

    wire defm_ctrl_has_udcomphdr_strb;

    assign defm_ctrl_has_udcomphdr_strb = (int_addr[10:2] == 'h40);

    wire defm_ctrl_udcompmeth_strb;

    assign defm_ctrl_udcompmeth_strb = (int_addr[10:2] == 'h40);

    wire defm_ctrl_udiqwidth_strb;

    assign defm_ctrl_udiqwidth_strb = (int_addr[10:2] == 'h40);

    wire defm_syml_rd_shift_val_strb;

    assign defm_syml_rd_shift_val_strb = (int_addr[10:2] == 'h41);

    wire defm_src_mac_l_val_strb;

    assign defm_src_mac_l_val_strb = (int_addr[10:2] == 'h42);

    wire defm_src_mac_h_val_strb;

    assign defm_src_mac_h_val_strb = (int_addr[10:2] == 'h43);

    wire defm_buffer_addr_offset_0_val_strb;

    assign defm_buffer_addr_offset_0_val_strb = (int_addr[10:2] == 'h44);

    wire defm_buffer_addr_offset_1_val_strb;

    assign defm_buffer_addr_offset_1_val_strb = (int_addr[10:2] == 'h45);

    wire defm_buffer_addr_offset_2_val_strb;

    assign defm_buffer_addr_offset_2_val_strb = (int_addr[10:2] == 'h46);

    wire defm_buffer_addr_offset_3_val_strb;

    assign defm_buffer_addr_offset_3_val_strb = (int_addr[10:2] == 'h47);

    wire defm_buffer_addr_offset_4_val_strb;

    assign defm_buffer_addr_offset_4_val_strb = (int_addr[10:2] == 'h48);

    wire defm_buffer_addr_offset_5_val_strb;

    assign defm_buffer_addr_offset_5_val_strb = (int_addr[10:2] == 'h49);

    wire defm_buffer_addr_offset_6_val_strb;

    assign defm_buffer_addr_offset_6_val_strb = (int_addr[10:2] == 'h4a);

    wire defm_buffer_addr_offset_7_val_strb;

    assign defm_buffer_addr_offset_7_val_strb = (int_addr[10:2] == 'h4b);

    wire defm_buffer_addr_offset_8_val_strb;

    assign defm_buffer_addr_offset_8_val_strb = (int_addr[10:2] == 'h4c);

    wire defm_buffer_addr_offset_9_val_strb;

    assign defm_buffer_addr_offset_9_val_strb = (int_addr[10:2] == 'h4d);

    wire total_pkt_cnt_lo_val_strb;

    assign total_pkt_cnt_lo_val_strb = (int_addr[10:2] == 'h50);

    wire total_pkt_cnt_hi_val_strb;

    assign total_pkt_cnt_hi_val_strb = (int_addr[10:2] == 'h51);

    wire oran_pkt_cnt_lo_val_strb;

    assign oran_pkt_cnt_lo_val_strb = (int_addr[10:2] == 'h52);

    wire oran_pkt_cnt_hi_val_strb;

    assign oran_pkt_cnt_hi_val_strb = (int_addr[10:2] == 'h53);

    wire ontime_pkt_cnt_lo_val_strb;

    assign ontime_pkt_cnt_lo_val_strb = (int_addr[10:2] == 'h54);

    wire ontime_pkt_cnt_hi_val_strb;

    assign ontime_pkt_cnt_hi_val_strb = (int_addr[10:2] == 'h55);

    wire early_pkt_cnt_lo_val_strb;

    assign early_pkt_cnt_lo_val_strb = (int_addr[10:2] == 'h56);

    wire early_pkt_cnt_hi_val_strb;

    assign early_pkt_cnt_hi_val_strb = (int_addr[10:2] == 'h57);

    wire late_pkt_cnt_lo_val_strb;

    assign late_pkt_cnt_lo_val_strb = (int_addr[10:2] == 'h58);

    wire late_pkt_cnt_hi_val_strb;

    assign late_pkt_cnt_hi_val_strb = (int_addr[10:2] == 'h59);

    wire earliest_u_pkt_val_strb;

    assign earliest_u_pkt_val_strb = (int_addr[10:2] == 'h60);

    wire latest_u_pkt_val_strb;

    assign latest_u_pkt_val_strb = (int_addr[10:2] == 'h61);

    wire fram_ctrl_en_strb;

    assign fram_ctrl_en_strb = (int_addr[10:2] == 'h80);

    wire fram_ctrl_has_udcomphdr_strb;

    assign fram_ctrl_has_udcomphdr_strb = (int_addr[10:2] == 'h80);

    wire fram_ctrl_udcompmeth_strb;

    assign fram_ctrl_udcompmeth_strb = (int_addr[10:2] == 'h80);

    wire fram_ctrl_udiqwidth_strb;

    assign fram_ctrl_udiqwidth_strb = (int_addr[10:2] == 'h80);

    wire fram_syml_rd_shift_val_strb;

    assign fram_syml_rd_shift_val_strb = (int_addr[10:2] == 'h81);

    wire fram_dest_mac_l_val_strb;

    assign fram_dest_mac_l_val_strb = (int_addr[10:2] == 'h82);

    wire fram_dest_mac_h_val_strb;

    assign fram_dest_mac_h_val_strb = (int_addr[10:2] == 'h83);

    wire fram_src_mac_l_val_strb;

    assign fram_src_mac_l_val_strb = (int_addr[10:2] == 'h84);

    wire fram_src_mac_h_val_strb;

    assign fram_src_mac_h_val_strb = (int_addr[10:2] == 'h85);

    wire fram_vlan_ctrl_vlan_tag_strb;

    assign fram_vlan_ctrl_vlan_tag_strb = (int_addr[10:2] == 'h86);

    wire fram_vlan_ctrl_has_vlan_strb;

    assign fram_vlan_ctrl_has_vlan_strb = (int_addr[10:2] == 'h86);

    wire fram_ctrl_buf0_strb;

    assign fram_ctrl_buf0_strb = (int_addr[10:6] == 'hc);

    wire fram_mask_buf0_strb;

    assign fram_mask_buf0_strb = (int_addr[10:7] == 'h7);

    wire fram_ctrl_buf1_strb;

    assign fram_ctrl_buf1_strb = (int_addr[10:6] == 'h10);

    wire fram_mask_buf1_strb;

    assign fram_mask_buf1_strb = (int_addr[10:7] == 'h9);

    always @(*) begin
        int_wr_ack = int_wr_en;
    end

    always @(*) begin
        int_wr_err = 1'b1;
        if (int_addr[10:2] == 'h8) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h40) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h41) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h42) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h43) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h44) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h45) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h46) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h47) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h48) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h49) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h4a) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h4b) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h4c) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h4d) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h50) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h51) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h52) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h53) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h54) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h55) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h56) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h57) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h58) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h59) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h60) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h61) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h80) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h81) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h82) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h83) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h84) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h85) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:2] == 'h86) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:6] == 'hc) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:7] == 'h7) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:6] == 'h10) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[10:7] == 'h9) begin
            int_wr_err = 1'b0;
        end
    end

    always @(posedge aclk) begin
        int_rd_ack <= int_rd_en;
    end

    always @(posedge aclk) begin
        int_rd_err <= 1'b1;
        if (int_addr[10:2] == 'h0) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h8) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h40) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h41) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h42) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h43) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h44) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h45) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h46) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h47) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h48) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h49) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h4a) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h4b) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h4c) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h4d) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h50) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h51) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h52) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h53) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h54) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h55) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h56) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h57) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h58) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h59) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h60) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h61) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h80) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h81) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h82) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h83) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h84) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h85) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:2] == 'h86) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:6] == 'hc) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:7] == 'h7) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:6] == 'h10) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[10:7] == 'h9) begin
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

    // Field tick.tick @'h20[0:0]

    reg [0:0] tick_tick_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            tick_tick_value <= 'h0;
        end else if (int_wr_en && tick_tick_strb) begin
            tick_tick_value <= int_wr_data[0:0];
        end
    end

    assign tick_tick_out = tick_tick_value;

    // Field tick.clear @'h20[1:1]

    reg [0:0] tick_clear_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            tick_clear_value <= 'h0;
        end else if (int_wr_en && tick_clear_strb) begin
            tick_clear_value <= int_wr_data[1:1];
        end
    end

    assign tick_clear_out = tick_clear_value;

    // Field defm_ctrl.en @'h100[0:0]

    reg [0:0] defm_ctrl_en_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_ctrl_en_value <= 'h0;
        end else if (int_wr_en && defm_ctrl_en_strb) begin
            defm_ctrl_en_value <= int_wr_data[0:0];
        end
    end

    assign defm_ctrl_en_out = defm_ctrl_en_value;

    // Field defm_ctrl.has_udcomphdr @'h100[8:8]

    reg [0:0] defm_ctrl_has_udcomphdr_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_ctrl_has_udcomphdr_value <= 'h0;
        end else if (int_wr_en && defm_ctrl_has_udcomphdr_strb) begin
            defm_ctrl_has_udcomphdr_value <= int_wr_data[8:8];
        end
    end

    assign defm_ctrl_has_udcomphdr_out = defm_ctrl_has_udcomphdr_value;

    // Field defm_ctrl.udcompmeth @'h100[19:16]

    reg [3:0] defm_ctrl_udcompmeth_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_ctrl_udcompmeth_value <= 'h0;
        end else if (int_wr_en && defm_ctrl_udcompmeth_strb) begin
            defm_ctrl_udcompmeth_value <= int_wr_data[19:16];
        end
    end

    assign defm_ctrl_udcompmeth_out = defm_ctrl_udcompmeth_value;

    // Field defm_ctrl.udiqwidth @'h100[23:20]

    reg [3:0] defm_ctrl_udiqwidth_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_ctrl_udiqwidth_value <= 'h0;
        end else if (int_wr_en && defm_ctrl_udiqwidth_strb) begin
            defm_ctrl_udiqwidth_value <= int_wr_data[23:20];
        end
    end

    assign defm_ctrl_udiqwidth_out = defm_ctrl_udiqwidth_value;

    // Field defm_syml_rd_shift.val @'h104[11:0]

    reg [11:0] defm_syml_rd_shift_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_syml_rd_shift_val_value <= 'h0;
        end else if (int_wr_en && defm_syml_rd_shift_val_strb) begin
            defm_syml_rd_shift_val_value <= int_wr_data[11:0];
        end
    end

    assign defm_syml_rd_shift_val_out = defm_syml_rd_shift_val_value;

    // Field defm_src_mac_l.val @'h108[31:0]

    reg [31:0] defm_src_mac_l_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_src_mac_l_val_value <= 'h0;
        end else if (int_wr_en && defm_src_mac_l_val_strb) begin
            defm_src_mac_l_val_value <= int_wr_data[31:0];
        end else begin
            defm_src_mac_l_val_value <= defm_src_mac_l_val_in;
        end
    end

    // Field defm_src_mac_h.val @'h10c[15:0]

    reg [15:0] defm_src_mac_h_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_src_mac_h_val_value <= 'h0;
        end else if (int_wr_en && defm_src_mac_h_val_strb) begin
            defm_src_mac_h_val_value <= int_wr_data[15:0];
        end else begin
            defm_src_mac_h_val_value <= defm_src_mac_h_val_in;
        end
    end

    // Field defm_buffer_addr_offset_0.val @'h110[15:0]

    reg [15:0] defm_buffer_addr_offset_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_buffer_addr_offset_0_val_value <= 'h0;
        end else if (int_wr_en && defm_buffer_addr_offset_0_val_strb) begin
            defm_buffer_addr_offset_0_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_buffer_addr_offset_0_val_out = defm_buffer_addr_offset_0_val_value;

    // Field defm_buffer_addr_offset_1.val @'h114[15:0]

    reg [15:0] defm_buffer_addr_offset_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_buffer_addr_offset_1_val_value <= 'h0;
        end else if (int_wr_en && defm_buffer_addr_offset_1_val_strb) begin
            defm_buffer_addr_offset_1_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_buffer_addr_offset_1_val_out = defm_buffer_addr_offset_1_val_value;

    // Field defm_buffer_addr_offset_2.val @'h118[15:0]

    reg [15:0] defm_buffer_addr_offset_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_buffer_addr_offset_2_val_value <= 'h0;
        end else if (int_wr_en && defm_buffer_addr_offset_2_val_strb) begin
            defm_buffer_addr_offset_2_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_buffer_addr_offset_2_val_out = defm_buffer_addr_offset_2_val_value;

    // Field defm_buffer_addr_offset_3.val @'h11c[15:0]

    reg [15:0] defm_buffer_addr_offset_3_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_buffer_addr_offset_3_val_value <= 'h0;
        end else if (int_wr_en && defm_buffer_addr_offset_3_val_strb) begin
            defm_buffer_addr_offset_3_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_buffer_addr_offset_3_val_out = defm_buffer_addr_offset_3_val_value;

    // Field defm_buffer_addr_offset_4.val @'h120[15:0]

    reg [15:0] defm_buffer_addr_offset_4_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_buffer_addr_offset_4_val_value <= 'h0;
        end else if (int_wr_en && defm_buffer_addr_offset_4_val_strb) begin
            defm_buffer_addr_offset_4_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_buffer_addr_offset_4_val_out = defm_buffer_addr_offset_4_val_value;

    // Field defm_buffer_addr_offset_5.val @'h124[15:0]

    reg [15:0] defm_buffer_addr_offset_5_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_buffer_addr_offset_5_val_value <= 'h0;
        end else if (int_wr_en && defm_buffer_addr_offset_5_val_strb) begin
            defm_buffer_addr_offset_5_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_buffer_addr_offset_5_val_out = defm_buffer_addr_offset_5_val_value;

    // Field defm_buffer_addr_offset_6.val @'h128[15:0]

    reg [15:0] defm_buffer_addr_offset_6_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_buffer_addr_offset_6_val_value <= 'h0;
        end else if (int_wr_en && defm_buffer_addr_offset_6_val_strb) begin
            defm_buffer_addr_offset_6_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_buffer_addr_offset_6_val_out = defm_buffer_addr_offset_6_val_value;

    // Field defm_buffer_addr_offset_7.val @'h12c[15:0]

    reg [15:0] defm_buffer_addr_offset_7_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_buffer_addr_offset_7_val_value <= 'h0;
        end else if (int_wr_en && defm_buffer_addr_offset_7_val_strb) begin
            defm_buffer_addr_offset_7_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_buffer_addr_offset_7_val_out = defm_buffer_addr_offset_7_val_value;

    // Field defm_buffer_addr_offset_8.val @'h130[15:0]

    reg [15:0] defm_buffer_addr_offset_8_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_buffer_addr_offset_8_val_value <= 'h0;
        end else if (int_wr_en && defm_buffer_addr_offset_8_val_strb) begin
            defm_buffer_addr_offset_8_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_buffer_addr_offset_8_val_out = defm_buffer_addr_offset_8_val_value;

    // Field defm_buffer_addr_offset_9.val @'h134[15:0]

    reg [15:0] defm_buffer_addr_offset_9_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_buffer_addr_offset_9_val_value <= 'h0;
        end else if (int_wr_en && defm_buffer_addr_offset_9_val_strb) begin
            defm_buffer_addr_offset_9_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_buffer_addr_offset_9_val_out = defm_buffer_addr_offset_9_val_value;

    // Field total_pkt_cnt_lo.val @'h140[31:0]

    reg [31:0] total_pkt_cnt_lo_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            total_pkt_cnt_lo_val_value <= 'h0;
        end else if (int_wr_en && total_pkt_cnt_lo_val_strb) begin
            total_pkt_cnt_lo_val_value <= int_wr_data[31:0];
        end else begin
            total_pkt_cnt_lo_val_value <= total_pkt_cnt_lo_val_in;
        end
    end

    // Field total_pkt_cnt_hi.val @'h144[15:0]

    reg [15:0] total_pkt_cnt_hi_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            total_pkt_cnt_hi_val_value <= 'h0;
        end else if (int_wr_en && total_pkt_cnt_hi_val_strb) begin
            total_pkt_cnt_hi_val_value <= int_wr_data[15:0];
        end else begin
            total_pkt_cnt_hi_val_value <= total_pkt_cnt_hi_val_in;
        end
    end

    // Field oran_pkt_cnt_lo.val @'h148[31:0]

    reg [31:0] oran_pkt_cnt_lo_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            oran_pkt_cnt_lo_val_value <= 'h0;
        end else if (int_wr_en && oran_pkt_cnt_lo_val_strb) begin
            oran_pkt_cnt_lo_val_value <= int_wr_data[31:0];
        end else begin
            oran_pkt_cnt_lo_val_value <= oran_pkt_cnt_lo_val_in;
        end
    end

    // Field oran_pkt_cnt_hi.val @'h14c[15:0]

    reg [15:0] oran_pkt_cnt_hi_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            oran_pkt_cnt_hi_val_value <= 'h0;
        end else if (int_wr_en && oran_pkt_cnt_hi_val_strb) begin
            oran_pkt_cnt_hi_val_value <= int_wr_data[15:0];
        end else begin
            oran_pkt_cnt_hi_val_value <= oran_pkt_cnt_hi_val_in;
        end
    end

    // Field ontime_pkt_cnt_lo.val @'h150[31:0]

    reg [31:0] ontime_pkt_cnt_lo_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ontime_pkt_cnt_lo_val_value <= 'h0;
        end else if (int_wr_en && ontime_pkt_cnt_lo_val_strb) begin
            ontime_pkt_cnt_lo_val_value <= int_wr_data[31:0];
        end else begin
            ontime_pkt_cnt_lo_val_value <= ontime_pkt_cnt_lo_val_in;
        end
    end

    // Field ontime_pkt_cnt_hi.val @'h154[15:0]

    reg [15:0] ontime_pkt_cnt_hi_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ontime_pkt_cnt_hi_val_value <= 'h0;
        end else if (int_wr_en && ontime_pkt_cnt_hi_val_strb) begin
            ontime_pkt_cnt_hi_val_value <= int_wr_data[15:0];
        end else begin
            ontime_pkt_cnt_hi_val_value <= ontime_pkt_cnt_hi_val_in;
        end
    end

    // Field early_pkt_cnt_lo.val @'h158[31:0]

    reg [31:0] early_pkt_cnt_lo_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            early_pkt_cnt_lo_val_value <= 'h0;
        end else if (int_wr_en && early_pkt_cnt_lo_val_strb) begin
            early_pkt_cnt_lo_val_value <= int_wr_data[31:0];
        end else begin
            early_pkt_cnt_lo_val_value <= early_pkt_cnt_lo_val_in;
        end
    end

    // Field early_pkt_cnt_hi.val @'h15c[15:0]

    reg [15:0] early_pkt_cnt_hi_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            early_pkt_cnt_hi_val_value <= 'h0;
        end else if (int_wr_en && early_pkt_cnt_hi_val_strb) begin
            early_pkt_cnt_hi_val_value <= int_wr_data[15:0];
        end else begin
            early_pkt_cnt_hi_val_value <= early_pkt_cnt_hi_val_in;
        end
    end

    // Field late_pkt_cnt_lo.val @'h160[31:0]

    reg [31:0] late_pkt_cnt_lo_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            late_pkt_cnt_lo_val_value <= 'h0;
        end else if (int_wr_en && late_pkt_cnt_lo_val_strb) begin
            late_pkt_cnt_lo_val_value <= int_wr_data[31:0];
        end else begin
            late_pkt_cnt_lo_val_value <= late_pkt_cnt_lo_val_in;
        end
    end

    // Field late_pkt_cnt_hi.val @'h164[15:0]

    reg [15:0] late_pkt_cnt_hi_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            late_pkt_cnt_hi_val_value <= 'h0;
        end else if (int_wr_en && late_pkt_cnt_hi_val_strb) begin
            late_pkt_cnt_hi_val_value <= int_wr_data[15:0];
        end else begin
            late_pkt_cnt_hi_val_value <= late_pkt_cnt_hi_val_in;
        end
    end

    // Field earliest_u_pkt.val @'h180[8:0]

    reg [8:0] earliest_u_pkt_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            earliest_u_pkt_val_value <= 'h0;
        end else if (int_wr_en && earliest_u_pkt_val_strb) begin
            earliest_u_pkt_val_value <= int_wr_data[8:0];
        end else begin
            earliest_u_pkt_val_value <= earliest_u_pkt_val_in;
        end
    end

    // Field latest_u_pkt.val @'h184[8:0]

    reg [8:0] latest_u_pkt_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            latest_u_pkt_val_value <= 'h0;
        end else if (int_wr_en && latest_u_pkt_val_strb) begin
            latest_u_pkt_val_value <= int_wr_data[8:0];
        end else begin
            latest_u_pkt_val_value <= latest_u_pkt_val_in;
        end
    end

    // Field fram_ctrl.en @'h200[0:0]

    reg [0:0] fram_ctrl_en_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_ctrl_en_value <= 'h0;
        end else if (int_wr_en && fram_ctrl_en_strb) begin
            fram_ctrl_en_value <= int_wr_data[0:0];
        end
    end

    assign fram_ctrl_en_out = fram_ctrl_en_value;

    // Field fram_ctrl.has_udcomphdr @'h200[8:8]

    reg [0:0] fram_ctrl_has_udcomphdr_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_ctrl_has_udcomphdr_value <= 'h0;
        end else if (int_wr_en && fram_ctrl_has_udcomphdr_strb) begin
            fram_ctrl_has_udcomphdr_value <= int_wr_data[8:8];
        end
    end

    assign fram_ctrl_has_udcomphdr_out = fram_ctrl_has_udcomphdr_value;

    // Field fram_ctrl.udcompmeth @'h200[19:16]

    reg [3:0] fram_ctrl_udcompmeth_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_ctrl_udcompmeth_value <= 'h0;
        end else if (int_wr_en && fram_ctrl_udcompmeth_strb) begin
            fram_ctrl_udcompmeth_value <= int_wr_data[19:16];
        end
    end

    assign fram_ctrl_udcompmeth_out = fram_ctrl_udcompmeth_value;

    // Field fram_ctrl.udiqwidth @'h200[23:20]

    reg [3:0] fram_ctrl_udiqwidth_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_ctrl_udiqwidth_value <= 'h0;
        end else if (int_wr_en && fram_ctrl_udiqwidth_strb) begin
            fram_ctrl_udiqwidth_value <= int_wr_data[23:20];
        end
    end

    assign fram_ctrl_udiqwidth_out = fram_ctrl_udiqwidth_value;

    // Field fram_syml_rd_shift.val @'h204[10:0]

    reg [10:0] fram_syml_rd_shift_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_syml_rd_shift_val_value <= 'h0;
        end else if (int_wr_en && fram_syml_rd_shift_val_strb) begin
            fram_syml_rd_shift_val_value <= int_wr_data[10:0];
        end
    end

    assign fram_syml_rd_shift_val_out = fram_syml_rd_shift_val_value;

    // Field fram_dest_mac_l.val @'h208[31:0]

    reg [31:0] fram_dest_mac_l_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_dest_mac_l_val_value <= 'h22334455;
        end else if (int_wr_en && fram_dest_mac_l_val_strb) begin
            fram_dest_mac_l_val_value <= int_wr_data[31:0];
        end
    end

    assign fram_dest_mac_l_val_out = fram_dest_mac_l_val_value;

    // Field fram_dest_mac_h.val @'h20c[15:0]

    reg [15:0] fram_dest_mac_h_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_dest_mac_h_val_value <= 'h11;
        end else if (int_wr_en && fram_dest_mac_h_val_strb) begin
            fram_dest_mac_h_val_value <= int_wr_data[15:0];
        end
    end

    assign fram_dest_mac_h_val_out = fram_dest_mac_h_val_value;

    // Field fram_src_mac_l.val @'h210[31:0]

    reg [31:0] fram_src_mac_l_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_src_mac_l_val_value <= 'h22334466;
        end else if (int_wr_en && fram_src_mac_l_val_strb) begin
            fram_src_mac_l_val_value <= int_wr_data[31:0];
        end
    end

    assign fram_src_mac_l_val_out = fram_src_mac_l_val_value;

    // Field fram_src_mac_h.val @'h214[15:0]

    reg [15:0] fram_src_mac_h_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_src_mac_h_val_value <= 'h11;
        end else if (int_wr_en && fram_src_mac_h_val_strb) begin
            fram_src_mac_h_val_value <= int_wr_data[15:0];
        end
    end

    assign fram_src_mac_h_val_out = fram_src_mac_h_val_value;

    // Field fram_vlan_ctrl.vlan_tag @'h218[15:0]

    reg [15:0] fram_vlan_ctrl_vlan_tag_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_vlan_ctrl_vlan_tag_value <= 'h7001;
        end else if (int_wr_en && fram_vlan_ctrl_vlan_tag_strb) begin
            fram_vlan_ctrl_vlan_tag_value <= int_wr_data[15:0];
        end
    end

    assign fram_vlan_ctrl_vlan_tag_out = fram_vlan_ctrl_vlan_tag_value;

    // Field fram_vlan_ctrl.has_vlan @'h218[16:16]

    reg [0:0] fram_vlan_ctrl_has_vlan_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_vlan_ctrl_has_vlan_value <= 'h1;
        end else if (int_wr_en && fram_vlan_ctrl_has_vlan_strb) begin
            fram_vlan_ctrl_has_vlan_value <= int_wr_data[16:16];
        end
    end

    assign fram_vlan_ctrl_has_vlan_out = fram_vlan_ctrl_has_vlan_value;


    //--------------------------------------------------------------------------
    // Memory logic
    //--------------------------------------------------------------------------

    // Memory fram_ctrl_buf0 @'h300

    assign fram_ctrl_buf0_addr = int_addr[5:2];
    assign fram_ctrl_buf0_en   = ((int_wr_en || int_rd_en) && fram_ctrl_buf0_strb);
    assign fram_ctrl_buf0_we   = (int_wr_en && fram_ctrl_buf0_strb);
    assign fram_ctrl_buf0_din  = int_wr_data[31:0];

    // Memory fram_mask_buf0 @'h380

    assign fram_mask_buf0_addr = int_addr[6:2];
    assign fram_mask_buf0_en   = ((int_wr_en || int_rd_en) && fram_mask_buf0_strb);
    assign fram_mask_buf0_we   = (int_wr_en && fram_mask_buf0_strb);
    assign fram_mask_buf0_din  = int_wr_data[31:0];

    // Memory fram_ctrl_buf1 @'h400

    assign fram_ctrl_buf1_addr = int_addr[5:2];
    assign fram_ctrl_buf1_en   = ((int_wr_en || int_rd_en) && fram_ctrl_buf1_strb);
    assign fram_ctrl_buf1_we   = (int_wr_en && fram_ctrl_buf1_strb);
    assign fram_ctrl_buf1_din  = int_wr_data[31:0];

    // Memory fram_mask_buf1 @'h480

    assign fram_mask_buf1_addr = int_addr[6:2];
    assign fram_mask_buf1_en   = ((int_wr_en || int_rd_en) && fram_mask_buf1_strb);
    assign fram_mask_buf1_we   = (int_wr_en && fram_mask_buf1_strb);
    assign fram_mask_buf1_din  = int_wr_data[31:0];


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
        if (int_rd_en && tick_tick_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | tick_tick_value;
        end
        if (int_rd_en && tick_clear_strb) begin
            field_rd_data_next[1:1] = field_rd_data_next[1:1] | tick_clear_value;
        end
        if (int_rd_en && defm_ctrl_en_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | defm_ctrl_en_value;
        end
        if (int_rd_en && defm_ctrl_has_udcomphdr_strb) begin
            field_rd_data_next[8:8] = field_rd_data_next[8:8] | defm_ctrl_has_udcomphdr_value;
        end
        if (int_rd_en && defm_ctrl_udcompmeth_strb) begin
            field_rd_data_next[19:16] = field_rd_data_next[19:16] | defm_ctrl_udcompmeth_value;
        end
        if (int_rd_en && defm_ctrl_udiqwidth_strb) begin
            field_rd_data_next[23:20] = field_rd_data_next[23:20] | defm_ctrl_udiqwidth_value;
        end
        if (int_rd_en && defm_syml_rd_shift_val_strb) begin
            field_rd_data_next[11:0] = field_rd_data_next[11:0] | defm_syml_rd_shift_val_value;
        end
        if (int_rd_en && defm_src_mac_l_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | defm_src_mac_l_val_value;
        end
        if (int_rd_en && defm_src_mac_h_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_src_mac_h_val_value;
        end
        if (int_rd_en && defm_buffer_addr_offset_0_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_buffer_addr_offset_0_val_value;
        end
        if (int_rd_en && defm_buffer_addr_offset_1_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_buffer_addr_offset_1_val_value;
        end
        if (int_rd_en && defm_buffer_addr_offset_2_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_buffer_addr_offset_2_val_value;
        end
        if (int_rd_en && defm_buffer_addr_offset_3_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_buffer_addr_offset_3_val_value;
        end
        if (int_rd_en && defm_buffer_addr_offset_4_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_buffer_addr_offset_4_val_value;
        end
        if (int_rd_en && defm_buffer_addr_offset_5_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_buffer_addr_offset_5_val_value;
        end
        if (int_rd_en && defm_buffer_addr_offset_6_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_buffer_addr_offset_6_val_value;
        end
        if (int_rd_en && defm_buffer_addr_offset_7_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_buffer_addr_offset_7_val_value;
        end
        if (int_rd_en && defm_buffer_addr_offset_8_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_buffer_addr_offset_8_val_value;
        end
        if (int_rd_en && defm_buffer_addr_offset_9_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_buffer_addr_offset_9_val_value;
        end
        if (int_rd_en && total_pkt_cnt_lo_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | total_pkt_cnt_lo_val_value;
        end
        if (int_rd_en && total_pkt_cnt_hi_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | total_pkt_cnt_hi_val_value;
        end
        if (int_rd_en && oran_pkt_cnt_lo_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | oran_pkt_cnt_lo_val_value;
        end
        if (int_rd_en && oran_pkt_cnt_hi_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | oran_pkt_cnt_hi_val_value;
        end
        if (int_rd_en && ontime_pkt_cnt_lo_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ontime_pkt_cnt_lo_val_value;
        end
        if (int_rd_en && ontime_pkt_cnt_hi_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | ontime_pkt_cnt_hi_val_value;
        end
        if (int_rd_en && early_pkt_cnt_lo_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | early_pkt_cnt_lo_val_value;
        end
        if (int_rd_en && early_pkt_cnt_hi_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | early_pkt_cnt_hi_val_value;
        end
        if (int_rd_en && late_pkt_cnt_lo_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | late_pkt_cnt_lo_val_value;
        end
        if (int_rd_en && late_pkt_cnt_hi_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | late_pkt_cnt_hi_val_value;
        end
        if (int_rd_en && earliest_u_pkt_val_strb) begin
            field_rd_data_next[8:0] = field_rd_data_next[8:0] | earliest_u_pkt_val_value;
        end
        if (int_rd_en && latest_u_pkt_val_strb) begin
            field_rd_data_next[8:0] = field_rd_data_next[8:0] | latest_u_pkt_val_value;
        end
        if (int_rd_en && fram_ctrl_en_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | fram_ctrl_en_value;
        end
        if (int_rd_en && fram_ctrl_has_udcomphdr_strb) begin
            field_rd_data_next[8:8] = field_rd_data_next[8:8] | fram_ctrl_has_udcomphdr_value;
        end
        if (int_rd_en && fram_ctrl_udcompmeth_strb) begin
            field_rd_data_next[19:16] = field_rd_data_next[19:16] | fram_ctrl_udcompmeth_value;
        end
        if (int_rd_en && fram_ctrl_udiqwidth_strb) begin
            field_rd_data_next[23:20] = field_rd_data_next[23:20] | fram_ctrl_udiqwidth_value;
        end
        if (int_rd_en && fram_syml_rd_shift_val_strb) begin
            field_rd_data_next[10:0] = field_rd_data_next[10:0] | fram_syml_rd_shift_val_value;
        end
        if (int_rd_en && fram_dest_mac_l_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | fram_dest_mac_l_val_value;
        end
        if (int_rd_en && fram_dest_mac_h_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | fram_dest_mac_h_val_value;
        end
        if (int_rd_en && fram_src_mac_l_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | fram_src_mac_l_val_value;
        end
        if (int_rd_en && fram_src_mac_h_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | fram_src_mac_h_val_value;
        end
        if (int_rd_en && fram_vlan_ctrl_vlan_tag_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | fram_vlan_ctrl_vlan_tag_value;
        end
        if (int_rd_en && fram_vlan_ctrl_has_vlan_strb) begin
            field_rd_data_next[16:16] = field_rd_data_next[16:16] | fram_vlan_ctrl_has_vlan_value;
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
        if (int_rd_en && tick_tick_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && tick_clear_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_ctrl_en_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_ctrl_has_udcomphdr_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_ctrl_udcompmeth_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_ctrl_udiqwidth_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_syml_rd_shift_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_src_mac_l_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_src_mac_h_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_buffer_addr_offset_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_buffer_addr_offset_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_buffer_addr_offset_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_buffer_addr_offset_3_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_buffer_addr_offset_4_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_buffer_addr_offset_5_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_buffer_addr_offset_6_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_buffer_addr_offset_7_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_buffer_addr_offset_8_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_buffer_addr_offset_9_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && total_pkt_cnt_lo_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && total_pkt_cnt_hi_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && oran_pkt_cnt_lo_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && oran_pkt_cnt_hi_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ontime_pkt_cnt_lo_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ontime_pkt_cnt_hi_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && early_pkt_cnt_lo_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && early_pkt_cnt_hi_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && late_pkt_cnt_lo_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && late_pkt_cnt_hi_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && earliest_u_pkt_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && latest_u_pkt_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_ctrl_en_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_ctrl_has_udcomphdr_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_ctrl_udcompmeth_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_ctrl_udiqwidth_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_syml_rd_shift_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_dest_mac_l_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_dest_mac_h_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_src_mac_l_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_src_mac_h_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_vlan_ctrl_vlan_tag_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_vlan_ctrl_has_vlan_strb) begin
            field_strb <= 1'b1;
        end
    end

    reg fram_ctrl_buf0_strb_d;

    always @(posedge aclk) begin
        fram_ctrl_buf0_strb_d <= fram_ctrl_buf0_strb;
    end

    reg fram_mask_buf0_strb_d;

    always @(posedge aclk) begin
        fram_mask_buf0_strb_d <= fram_mask_buf0_strb;
    end

    reg fram_ctrl_buf1_strb_d;

    always @(posedge aclk) begin
        fram_ctrl_buf1_strb_d <= fram_ctrl_buf1_strb;
    end

    reg fram_mask_buf1_strb_d;

    always @(posedge aclk) begin
        fram_mask_buf1_strb_d <= fram_mask_buf1_strb;
    end

    always @(*) begin
        int_rd_data = '0;
        if (field_strb) begin
            int_rd_data = int_rd_data | field_rd_data;
        end
        if (fram_ctrl_buf0_strb_d) begin
            int_rd_data[31:0] = int_rd_data[31:0] | fram_ctrl_buf0_dout;
        end
        if (fram_mask_buf0_strb_d) begin
            int_rd_data[31:0] = int_rd_data[31:0] | fram_mask_buf0_dout;
        end
        if (fram_ctrl_buf1_strb_d) begin
            int_rd_data[31:0] = int_rd_data[31:0] | fram_ctrl_buf1_dout;
        end
        if (fram_mask_buf1_strb_d) begin
            int_rd_data[31:0] = int_rd_data[31:0] | fram_mask_buf1_dout;
        end
    end

endmodule

`default_nettype wire

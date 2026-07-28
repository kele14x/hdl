// File: coe_regs.v
// Brief: Register block generate for coe
`timescale 1 ns / 1 ps
//
`default_nettype none

module coe_regs (
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
    // stat.rx_status,
    input  wire [ 0:0] stat_rx_status_in,
    // tick.snap,
    input  wire [ 0:0] tick_snap_in,
    output wire [ 0:0] tick_snap_out,
    // tick.clear,
    input  wire [ 0:0] tick_clear_in,
    output wire [ 0:0] tick_clear_out,
    // defm_ctrl.en,
    output wire [ 0:0] defm_ctrl_en_out,
    // defm_ctrl.src_mac_flt_en,
    output wire [ 0:0] defm_ctrl_src_mac_flt_en_out,
    // defm_ctrl.dest_mac_flt_en,
    output wire [ 0:0] defm_ctrl_dest_mac_flt_en_out,
    // defm_src_mac_l.val,
    output wire [31:0] defm_src_mac_l_val_out,
    // defm_src_mac_h.val,
    output wire [15:0] defm_src_mac_h_val_out,
    // defm_dest_mac_l.val,
    output wire [31:0] defm_dest_mac_l_val_out,
    // defm_dest_mac_h.val,
    output wire [15:0] defm_dest_mac_h_val_out,
    // defm_seq_en.val,
    output wire [15:0] defm_seq_en_val_out,
    // defm_seq_id_0.id0,
    output wire [ 5:0] defm_seq_id_0_id0_out,
    // defm_seq_id_0.id1,
    output wire [ 5:0] defm_seq_id_0_id1_out,
    // defm_seq_id_0.id2,
    output wire [ 5:0] defm_seq_id_0_id2_out,
    // defm_seq_id_0.id3,
    output wire [ 5:0] defm_seq_id_0_id3_out,
    // defm_seq_id_1.id0,
    output wire [ 5:0] defm_seq_id_1_id0_out,
    // defm_seq_id_1.id1,
    output wire [ 5:0] defm_seq_id_1_id1_out,
    // defm_seq_id_1.id2,
    output wire [ 5:0] defm_seq_id_1_id2_out,
    // defm_seq_id_1.id3,
    output wire [ 5:0] defm_seq_id_1_id3_out,
    // defm_seq_id_2.id0,
    output wire [ 5:0] defm_seq_id_2_id0_out,
    // defm_seq_id_2.id1,
    output wire [ 5:0] defm_seq_id_2_id1_out,
    // defm_seq_id_2.id2,
    output wire [ 5:0] defm_seq_id_2_id2_out,
    // defm_seq_id_2.id3,
    output wire [ 5:0] defm_seq_id_2_id3_out,
    // defm_seq_id_3.id0,
    output wire [ 5:0] defm_seq_id_3_id0_out,
    // defm_seq_id_3.id1,
    output wire [ 5:0] defm_seq_id_3_id1_out,
    // defm_seq_id_3.id2,
    output wire [ 5:0] defm_seq_id_3_id2_out,
    // defm_seq_id_3.id3,
    output wire [ 5:0] defm_seq_id_3_id3_out,
    // defm_ts_offset.val,
    output wire [ 8:0] defm_ts_offset_val_out,
    // defm_conflict_cnt.val,
    input  wire [31:0] defm_conflict_cnt_val_in,
    // defm_total_pkt_cnt.val,
    input  wire [31:0] defm_total_pkt_cnt_val_in,
    // defm_ecpri_pkt_cnt.val,
    input  wire [31:0] defm_ecpri_pkt_cnt_val_in,
    // defm_trans_pkt_cnt.val,
    input  wire [31:0] defm_trans_pkt_cnt_val_in,
    // defm_odm_pkt_cnt.val,
    input  wire [31:0] defm_odm_pkt_cnt_val_in,
    // fram_ctrl.en,
    output wire [ 0:0] fram_ctrl_en_out,
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
    // fram_seq_en.val,
    output wire [15:0] fram_seq_en_val_out,
    // fram_seq_id_0.id0,
    output wire [ 5:0] fram_seq_id_0_id0_out,
    // fram_seq_id_0.id1,
    output wire [ 5:0] fram_seq_id_0_id1_out,
    // fram_seq_id_0.id2,
    output wire [ 5:0] fram_seq_id_0_id2_out,
    // fram_seq_id_0.id3,
    output wire [ 5:0] fram_seq_id_0_id3_out,
    // fram_seq_id_1.id0,
    output wire [ 5:0] fram_seq_id_1_id0_out,
    // fram_seq_id_1.id1,
    output wire [ 5:0] fram_seq_id_1_id1_out,
    // fram_seq_id_1.id2,
    output wire [ 5:0] fram_seq_id_1_id2_out,
    // fram_seq_id_1.id3,
    output wire [ 5:0] fram_seq_id_1_id3_out,
    // fram_seq_id_2.id0,
    output wire [ 5:0] fram_seq_id_2_id0_out,
    // fram_seq_id_2.id1,
    output wire [ 5:0] fram_seq_id_2_id1_out,
    // fram_seq_id_2.id2,
    output wire [ 5:0] fram_seq_id_2_id2_out,
    // fram_seq_id_2.id3,
    output wire [ 5:0] fram_seq_id_2_id3_out,
    // fram_seq_id_3.id0,
    output wire [ 5:0] fram_seq_id_3_id0_out,
    // fram_seq_id_3.id1,
    output wire [ 5:0] fram_seq_id_3_id1_out,
    // fram_seq_id_3.id2,
    output wire [ 5:0] fram_seq_id_3_id2_out,
    // fram_seq_id_3.id3,
    output wire [ 5:0] fram_seq_id_3_id3_out,
    // fram_seq_cnt.val,
    output wire [ 7:0] fram_seq_cnt_val_out,
    // odm_ctrl.en,
    output wire [ 0:0] odm_ctrl_en_out,
    // odm_meas_interval.val,
    output wire [31:0] odm_meas_interval_val_out,
    // ts_diff_ingress_ns.val,
    input  wire [31:0] ts_diff_ingress_ns_val_in,
    // ts_diff_ingress_sec_l.val,
    input  wire [31:0] ts_diff_ingress_sec_l_val_in,
    // ts_diff_ingress_sec_h.val,
    input  wire [15:0] ts_diff_ingress_sec_h_val_in,
    // ts_diff_egress_ns.val,
    input  wire [31:0] ts_diff_egress_ns_val_in,
    // ts_diff_egress_sec_l.val,
    input  wire [31:0] ts_diff_egress_sec_l_val_in,
    // ts_diff_egress_sec_h.val,
    input  wire [15:0] ts_diff_egress_sec_h_val_in,
    // rx_resync_cnt.val,
    input  wire [31:0] rx_resync_cnt_val_in,
    // tx_resync_cnt.val,
    input  wire [31:0] tx_resync_cnt_val_in,
    // topology_id.val,
    input  wire [15:0] topology_id_val_in,
    // lp_topology_id.val,
    input  wire [15:0] lp_topology_id_val_in
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

    wire stat_rx_status_strb;

    assign stat_rx_status_strb = (int_addr[9:2] == 'h4);

    wire tick_snap_strb;

    assign tick_snap_strb = (int_addr[9:2] == 'h8);

    wire tick_clear_strb;

    assign tick_clear_strb = (int_addr[9:2] == 'h8);

    wire defm_ctrl_en_strb;

    assign defm_ctrl_en_strb = (int_addr[9:2] == 'h40);

    wire defm_ctrl_src_mac_flt_en_strb;

    assign defm_ctrl_src_mac_flt_en_strb = (int_addr[9:2] == 'h40);

    wire defm_ctrl_dest_mac_flt_en_strb;

    assign defm_ctrl_dest_mac_flt_en_strb = (int_addr[9:2] == 'h40);

    wire defm_src_mac_l_val_strb;

    assign defm_src_mac_l_val_strb = (int_addr[9:2] == 'h42);

    wire defm_src_mac_h_val_strb;

    assign defm_src_mac_h_val_strb = (int_addr[9:2] == 'h43);

    wire defm_dest_mac_l_val_strb;

    assign defm_dest_mac_l_val_strb = (int_addr[9:2] == 'h44);

    wire defm_dest_mac_h_val_strb;

    assign defm_dest_mac_h_val_strb = (int_addr[9:2] == 'h45);

    wire defm_seq_en_val_strb;

    assign defm_seq_en_val_strb = (int_addr[9:2] == 'h48);

    wire defm_seq_id_0_id0_strb;

    assign defm_seq_id_0_id0_strb = (int_addr[9:2] == 'h49);

    wire defm_seq_id_0_id1_strb;

    assign defm_seq_id_0_id1_strb = (int_addr[9:2] == 'h49);

    wire defm_seq_id_0_id2_strb;

    assign defm_seq_id_0_id2_strb = (int_addr[9:2] == 'h49);

    wire defm_seq_id_0_id3_strb;

    assign defm_seq_id_0_id3_strb = (int_addr[9:2] == 'h49);

    wire defm_seq_id_1_id0_strb;

    assign defm_seq_id_1_id0_strb = (int_addr[9:2] == 'h4a);

    wire defm_seq_id_1_id1_strb;

    assign defm_seq_id_1_id1_strb = (int_addr[9:2] == 'h4a);

    wire defm_seq_id_1_id2_strb;

    assign defm_seq_id_1_id2_strb = (int_addr[9:2] == 'h4a);

    wire defm_seq_id_1_id3_strb;

    assign defm_seq_id_1_id3_strb = (int_addr[9:2] == 'h4a);

    wire defm_seq_id_2_id0_strb;

    assign defm_seq_id_2_id0_strb = (int_addr[9:2] == 'h4b);

    wire defm_seq_id_2_id1_strb;

    assign defm_seq_id_2_id1_strb = (int_addr[9:2] == 'h4b);

    wire defm_seq_id_2_id2_strb;

    assign defm_seq_id_2_id2_strb = (int_addr[9:2] == 'h4b);

    wire defm_seq_id_2_id3_strb;

    assign defm_seq_id_2_id3_strb = (int_addr[9:2] == 'h4b);

    wire defm_seq_id_3_id0_strb;

    assign defm_seq_id_3_id0_strb = (int_addr[9:2] == 'h4c);

    wire defm_seq_id_3_id1_strb;

    assign defm_seq_id_3_id1_strb = (int_addr[9:2] == 'h4c);

    wire defm_seq_id_3_id2_strb;

    assign defm_seq_id_3_id2_strb = (int_addr[9:2] == 'h4c);

    wire defm_seq_id_3_id3_strb;

    assign defm_seq_id_3_id3_strb = (int_addr[9:2] == 'h4c);

    wire defm_ts_offset_val_strb;

    assign defm_ts_offset_val_strb = (int_addr[9:2] == 'h4d);

    wire defm_conflict_cnt_val_strb;

    assign defm_conflict_cnt_val_strb = (int_addr[9:2] == 'h4e);

    wire defm_total_pkt_cnt_val_strb;

    assign defm_total_pkt_cnt_val_strb = (int_addr[9:2] == 'h50);

    wire defm_ecpri_pkt_cnt_val_strb;

    assign defm_ecpri_pkt_cnt_val_strb = (int_addr[9:2] == 'h52);

    wire defm_trans_pkt_cnt_val_strb;

    assign defm_trans_pkt_cnt_val_strb = (int_addr[9:2] == 'h54);

    wire defm_odm_pkt_cnt_val_strb;

    assign defm_odm_pkt_cnt_val_strb = (int_addr[9:2] == 'h56);

    wire fram_ctrl_en_strb;

    assign fram_ctrl_en_strb = (int_addr[9:2] == 'h80);

    wire fram_dest_mac_l_val_strb;

    assign fram_dest_mac_l_val_strb = (int_addr[9:2] == 'h82);

    wire fram_dest_mac_h_val_strb;

    assign fram_dest_mac_h_val_strb = (int_addr[9:2] == 'h83);

    wire fram_src_mac_l_val_strb;

    assign fram_src_mac_l_val_strb = (int_addr[9:2] == 'h84);

    wire fram_src_mac_h_val_strb;

    assign fram_src_mac_h_val_strb = (int_addr[9:2] == 'h85);

    wire fram_vlan_ctrl_vlan_tag_strb;

    assign fram_vlan_ctrl_vlan_tag_strb = (int_addr[9:2] == 'h86);

    wire fram_vlan_ctrl_has_vlan_strb;

    assign fram_vlan_ctrl_has_vlan_strb = (int_addr[9:2] == 'h86);

    wire fram_seq_en_val_strb;

    assign fram_seq_en_val_strb = (int_addr[9:2] == 'h88);

    wire fram_seq_id_0_id0_strb;

    assign fram_seq_id_0_id0_strb = (int_addr[9:2] == 'h89);

    wire fram_seq_id_0_id1_strb;

    assign fram_seq_id_0_id1_strb = (int_addr[9:2] == 'h89);

    wire fram_seq_id_0_id2_strb;

    assign fram_seq_id_0_id2_strb = (int_addr[9:2] == 'h89);

    wire fram_seq_id_0_id3_strb;

    assign fram_seq_id_0_id3_strb = (int_addr[9:2] == 'h89);

    wire fram_seq_id_1_id0_strb;

    assign fram_seq_id_1_id0_strb = (int_addr[9:2] == 'h8a);

    wire fram_seq_id_1_id1_strb;

    assign fram_seq_id_1_id1_strb = (int_addr[9:2] == 'h8a);

    wire fram_seq_id_1_id2_strb;

    assign fram_seq_id_1_id2_strb = (int_addr[9:2] == 'h8a);

    wire fram_seq_id_1_id3_strb;

    assign fram_seq_id_1_id3_strb = (int_addr[9:2] == 'h8a);

    wire fram_seq_id_2_id0_strb;

    assign fram_seq_id_2_id0_strb = (int_addr[9:2] == 'h8b);

    wire fram_seq_id_2_id1_strb;

    assign fram_seq_id_2_id1_strb = (int_addr[9:2] == 'h8b);

    wire fram_seq_id_2_id2_strb;

    assign fram_seq_id_2_id2_strb = (int_addr[9:2] == 'h8b);

    wire fram_seq_id_2_id3_strb;

    assign fram_seq_id_2_id3_strb = (int_addr[9:2] == 'h8b);

    wire fram_seq_id_3_id0_strb;

    assign fram_seq_id_3_id0_strb = (int_addr[9:2] == 'h8c);

    wire fram_seq_id_3_id1_strb;

    assign fram_seq_id_3_id1_strb = (int_addr[9:2] == 'h8c);

    wire fram_seq_id_3_id2_strb;

    assign fram_seq_id_3_id2_strb = (int_addr[9:2] == 'h8c);

    wire fram_seq_id_3_id3_strb;

    assign fram_seq_id_3_id3_strb = (int_addr[9:2] == 'h8c);

    wire fram_seq_cnt_val_strb;

    assign fram_seq_cnt_val_strb = (int_addr[9:2] == 'h8d);

    wire odm_ctrl_en_strb;

    assign odm_ctrl_en_strb = (int_addr[9:2] == 'hc0);

    wire odm_meas_interval_val_strb;

    assign odm_meas_interval_val_strb = (int_addr[9:2] == 'hc2);

    wire ts_diff_ingress_ns_val_strb;

    assign ts_diff_ingress_ns_val_strb = (int_addr[9:2] == 'hc4);

    wire ts_diff_ingress_sec_l_val_strb;

    assign ts_diff_ingress_sec_l_val_strb = (int_addr[9:2] == 'hc5);

    wire ts_diff_ingress_sec_h_val_strb;

    assign ts_diff_ingress_sec_h_val_strb = (int_addr[9:2] == 'hc6);

    wire ts_diff_egress_ns_val_strb;

    assign ts_diff_egress_ns_val_strb = (int_addr[9:2] == 'hc8);

    wire ts_diff_egress_sec_l_val_strb;

    assign ts_diff_egress_sec_l_val_strb = (int_addr[9:2] == 'hc9);

    wire ts_diff_egress_sec_h_val_strb;

    assign ts_diff_egress_sec_h_val_strb = (int_addr[9:2] == 'hca);

    wire rx_resync_cnt_val_strb;

    assign rx_resync_cnt_val_strb = (int_addr[9:2] == 'hcc);

    wire tx_resync_cnt_val_strb;

    assign tx_resync_cnt_val_strb = (int_addr[9:2] == 'hcd);

    wire topology_id_val_strb;

    assign topology_id_val_strb = (int_addr[9:2] == 'hd0);

    wire lp_topology_id_val_strb;

    assign lp_topology_id_val_strb = (int_addr[9:2] == 'hd1);

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
        if (stat_rx_status_strb) begin
            int_wr_err <= 1'b0;
        end
        if (tick_snap_strb) begin
            int_wr_err <= 1'b0;
        end
        if (tick_clear_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_ctrl_en_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_ctrl_src_mac_flt_en_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_ctrl_dest_mac_flt_en_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_src_mac_l_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_src_mac_h_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_dest_mac_l_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_dest_mac_h_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_en_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_0_id0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_0_id1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_0_id2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_0_id3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_1_id0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_1_id1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_1_id2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_1_id3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_2_id0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_2_id1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_2_id2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_2_id3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_3_id0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_3_id1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_3_id2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_seq_id_3_id3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_ts_offset_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_conflict_cnt_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_total_pkt_cnt_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_ecpri_pkt_cnt_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_trans_pkt_cnt_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (defm_odm_pkt_cnt_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_ctrl_en_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_dest_mac_l_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_dest_mac_h_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_src_mac_l_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_src_mac_h_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_vlan_ctrl_vlan_tag_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_vlan_ctrl_has_vlan_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_en_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_0_id0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_0_id1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_0_id2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_0_id3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_1_id0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_1_id1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_1_id2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_1_id3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_2_id0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_2_id1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_2_id2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_2_id3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_3_id0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_3_id1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_3_id2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_id_3_id3_strb) begin
            int_wr_err <= 1'b0;
        end
        if (fram_seq_cnt_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (odm_ctrl_en_strb) begin
            int_wr_err <= 1'b0;
        end
        if (odm_meas_interval_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ts_diff_ingress_ns_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ts_diff_ingress_sec_l_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ts_diff_ingress_sec_h_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ts_diff_egress_ns_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ts_diff_egress_sec_l_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ts_diff_egress_sec_h_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (rx_resync_cnt_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (tx_resync_cnt_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (topology_id_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (lp_topology_id_val_strb) begin
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
        if (stat_rx_status_strb) begin
            int_rd_err <= 1'b0;
        end
        if (tick_snap_strb) begin
            int_rd_err <= 1'b0;
        end
        if (tick_clear_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_ctrl_en_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_ctrl_src_mac_flt_en_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_ctrl_dest_mac_flt_en_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_src_mac_l_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_src_mac_h_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_dest_mac_l_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_dest_mac_h_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_en_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_0_id0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_0_id1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_0_id2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_0_id3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_1_id0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_1_id1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_1_id2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_1_id3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_2_id0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_2_id1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_2_id2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_2_id3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_3_id0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_3_id1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_3_id2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_seq_id_3_id3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_ts_offset_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_conflict_cnt_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_total_pkt_cnt_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_ecpri_pkt_cnt_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_trans_pkt_cnt_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (defm_odm_pkt_cnt_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_ctrl_en_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_dest_mac_l_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_dest_mac_h_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_src_mac_l_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_src_mac_h_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_vlan_ctrl_vlan_tag_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_vlan_ctrl_has_vlan_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_en_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_0_id0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_0_id1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_0_id2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_0_id3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_1_id0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_1_id1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_1_id2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_1_id3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_2_id0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_2_id1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_2_id2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_2_id3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_3_id0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_3_id1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_3_id2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_id_3_id3_strb) begin
            int_rd_err <= 1'b0;
        end
        if (fram_seq_cnt_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (odm_ctrl_en_strb) begin
            int_rd_err <= 1'b0;
        end
        if (odm_meas_interval_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ts_diff_ingress_ns_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ts_diff_ingress_sec_l_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ts_diff_ingress_sec_h_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ts_diff_egress_ns_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ts_diff_egress_sec_l_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ts_diff_egress_sec_h_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (rx_resync_cnt_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (tx_resync_cnt_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (topology_id_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (lp_topology_id_val_strb) begin
            int_rd_err <= 1'b0;
        end
    end


    //--------------------------------------------------------------------------
    // Field logic
    //--------------------------------------------------------------------------

    // Field version.val @'h0[31:0]

    reg [31:0] version_val_value;

    initial begin
        version_val_value = 'h20241017;
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

    // Field stat.rx_status @'h10[0:0]

    reg [0:0] stat_rx_status_value;

    always @(*) begin
        stat_rx_status_value = stat_rx_status_in;
    end

    // Field tick.snap @'h20[0:0]

    reg [0:0] tick_snap_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            tick_snap_value <= 'h0;
        end else if (int_wr_en && tick_snap_strb) begin
            tick_snap_value <= int_wr_data[0:0];
        end else begin
            tick_snap_value <= tick_snap_in;
        end
    end

    assign tick_snap_out = tick_snap_value;

    // Field tick.clear @'h20[1:1]

    reg [0:0] tick_clear_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            tick_clear_value <= 'h0;
        end else if (int_wr_en && tick_clear_strb) begin
            tick_clear_value <= int_wr_data[1:1];
        end else begin
            tick_clear_value <= tick_clear_in;
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

    // Field defm_ctrl.src_mac_flt_en @'h100[1:1]

    reg [0:0] defm_ctrl_src_mac_flt_en_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_ctrl_src_mac_flt_en_value <= 'h0;
        end else if (int_wr_en && defm_ctrl_src_mac_flt_en_strb) begin
            defm_ctrl_src_mac_flt_en_value <= int_wr_data[1:1];
        end
    end

    assign defm_ctrl_src_mac_flt_en_out = defm_ctrl_src_mac_flt_en_value;

    // Field defm_ctrl.dest_mac_flt_en @'h100[2:2]

    reg [0:0] defm_ctrl_dest_mac_flt_en_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_ctrl_dest_mac_flt_en_value <= 'h0;
        end else if (int_wr_en && defm_ctrl_dest_mac_flt_en_strb) begin
            defm_ctrl_dest_mac_flt_en_value <= int_wr_data[2:2];
        end
    end

    assign defm_ctrl_dest_mac_flt_en_out = defm_ctrl_dest_mac_flt_en_value;

    // Field defm_src_mac_l.val @'h108[31:0]

    reg [31:0] defm_src_mac_l_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_src_mac_l_val_value <= 'h22334455;
        end else if (int_wr_en && defm_src_mac_l_val_strb) begin
            defm_src_mac_l_val_value <= int_wr_data[31:0];
        end
    end

    assign defm_src_mac_l_val_out = defm_src_mac_l_val_value;

    // Field defm_src_mac_h.val @'h10c[15:0]

    reg [15:0] defm_src_mac_h_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_src_mac_h_val_value <= 'h11;
        end else if (int_wr_en && defm_src_mac_h_val_strb) begin
            defm_src_mac_h_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_src_mac_h_val_out = defm_src_mac_h_val_value;

    // Field defm_dest_mac_l.val @'h110[31:0]

    reg [31:0] defm_dest_mac_l_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_dest_mac_l_val_value <= 'h22334466;
        end else if (int_wr_en && defm_dest_mac_l_val_strb) begin
            defm_dest_mac_l_val_value <= int_wr_data[31:0];
        end
    end

    assign defm_dest_mac_l_val_out = defm_dest_mac_l_val_value;

    // Field defm_dest_mac_h.val @'h114[15:0]

    reg [15:0] defm_dest_mac_h_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_dest_mac_h_val_value <= 'h11;
        end else if (int_wr_en && defm_dest_mac_h_val_strb) begin
            defm_dest_mac_h_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_dest_mac_h_val_out = defm_dest_mac_h_val_value;

    // Field defm_seq_en.val @'h120[15:0]

    reg [15:0] defm_seq_en_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_en_val_value <= 'h0;
        end else if (int_wr_en && defm_seq_en_val_strb) begin
            defm_seq_en_val_value <= int_wr_data[15:0];
        end
    end

    assign defm_seq_en_val_out = defm_seq_en_val_value;

    // Field defm_seq_id_0.id0 @'h124[5:0]

    reg [5:0] defm_seq_id_0_id0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_0_id0_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_0_id0_strb) begin
            defm_seq_id_0_id0_value <= int_wr_data[5:0];
        end
    end

    assign defm_seq_id_0_id0_out = defm_seq_id_0_id0_value;

    // Field defm_seq_id_0.id1 @'h124[13:8]

    reg [5:0] defm_seq_id_0_id1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_0_id1_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_0_id1_strb) begin
            defm_seq_id_0_id1_value <= int_wr_data[13:8];
        end
    end

    assign defm_seq_id_0_id1_out = defm_seq_id_0_id1_value;

    // Field defm_seq_id_0.id2 @'h124[21:16]

    reg [5:0] defm_seq_id_0_id2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_0_id2_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_0_id2_strb) begin
            defm_seq_id_0_id2_value <= int_wr_data[21:16];
        end
    end

    assign defm_seq_id_0_id2_out = defm_seq_id_0_id2_value;

    // Field defm_seq_id_0.id3 @'h124[29:24]

    reg [5:0] defm_seq_id_0_id3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_0_id3_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_0_id3_strb) begin
            defm_seq_id_0_id3_value <= int_wr_data[29:24];
        end
    end

    assign defm_seq_id_0_id3_out = defm_seq_id_0_id3_value;

    // Field defm_seq_id_1.id0 @'h128[5:0]

    reg [5:0] defm_seq_id_1_id0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_1_id0_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_1_id0_strb) begin
            defm_seq_id_1_id0_value <= int_wr_data[5:0];
        end
    end

    assign defm_seq_id_1_id0_out = defm_seq_id_1_id0_value;

    // Field defm_seq_id_1.id1 @'h128[13:8]

    reg [5:0] defm_seq_id_1_id1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_1_id1_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_1_id1_strb) begin
            defm_seq_id_1_id1_value <= int_wr_data[13:8];
        end
    end

    assign defm_seq_id_1_id1_out = defm_seq_id_1_id1_value;

    // Field defm_seq_id_1.id2 @'h128[21:16]

    reg [5:0] defm_seq_id_1_id2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_1_id2_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_1_id2_strb) begin
            defm_seq_id_1_id2_value <= int_wr_data[21:16];
        end
    end

    assign defm_seq_id_1_id2_out = defm_seq_id_1_id2_value;

    // Field defm_seq_id_1.id3 @'h128[29:24]

    reg [5:0] defm_seq_id_1_id3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_1_id3_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_1_id3_strb) begin
            defm_seq_id_1_id3_value <= int_wr_data[29:24];
        end
    end

    assign defm_seq_id_1_id3_out = defm_seq_id_1_id3_value;

    // Field defm_seq_id_2.id0 @'h12c[5:0]

    reg [5:0] defm_seq_id_2_id0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_2_id0_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_2_id0_strb) begin
            defm_seq_id_2_id0_value <= int_wr_data[5:0];
        end
    end

    assign defm_seq_id_2_id0_out = defm_seq_id_2_id0_value;

    // Field defm_seq_id_2.id1 @'h12c[13:8]

    reg [5:0] defm_seq_id_2_id1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_2_id1_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_2_id1_strb) begin
            defm_seq_id_2_id1_value <= int_wr_data[13:8];
        end
    end

    assign defm_seq_id_2_id1_out = defm_seq_id_2_id1_value;

    // Field defm_seq_id_2.id2 @'h12c[21:16]

    reg [5:0] defm_seq_id_2_id2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_2_id2_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_2_id2_strb) begin
            defm_seq_id_2_id2_value <= int_wr_data[21:16];
        end
    end

    assign defm_seq_id_2_id2_out = defm_seq_id_2_id2_value;

    // Field defm_seq_id_2.id3 @'h12c[29:24]

    reg [5:0] defm_seq_id_2_id3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_2_id3_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_2_id3_strb) begin
            defm_seq_id_2_id3_value <= int_wr_data[29:24];
        end
    end

    assign defm_seq_id_2_id3_out = defm_seq_id_2_id3_value;

    // Field defm_seq_id_3.id0 @'h130[5:0]

    reg [5:0] defm_seq_id_3_id0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_3_id0_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_3_id0_strb) begin
            defm_seq_id_3_id0_value <= int_wr_data[5:0];
        end
    end

    assign defm_seq_id_3_id0_out = defm_seq_id_3_id0_value;

    // Field defm_seq_id_3.id1 @'h130[13:8]

    reg [5:0] defm_seq_id_3_id1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_3_id1_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_3_id1_strb) begin
            defm_seq_id_3_id1_value <= int_wr_data[13:8];
        end
    end

    assign defm_seq_id_3_id1_out = defm_seq_id_3_id1_value;

    // Field defm_seq_id_3.id2 @'h130[21:16]

    reg [5:0] defm_seq_id_3_id2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_3_id2_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_3_id2_strb) begin
            defm_seq_id_3_id2_value <= int_wr_data[21:16];
        end
    end

    assign defm_seq_id_3_id2_out = defm_seq_id_3_id2_value;

    // Field defm_seq_id_3.id3 @'h130[29:24]

    reg [5:0] defm_seq_id_3_id3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_seq_id_3_id3_value <= 'h3f;
        end else if (int_wr_en && defm_seq_id_3_id3_strb) begin
            defm_seq_id_3_id3_value <= int_wr_data[29:24];
        end
    end

    assign defm_seq_id_3_id3_out = defm_seq_id_3_id3_value;

    // Field defm_ts_offset.val @'h134[8:0]

    reg [8:0] defm_ts_offset_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_ts_offset_val_value <= 'h40;
        end else if (int_wr_en && defm_ts_offset_val_strb) begin
            defm_ts_offset_val_value <= int_wr_data[8:0];
        end
    end

    assign defm_ts_offset_val_out = defm_ts_offset_val_value;

    // Field defm_conflict_cnt.val @'h138[31:0]

    reg [31:0] defm_conflict_cnt_val_value;

    always @(*) begin
        defm_conflict_cnt_val_value = defm_conflict_cnt_val_in;
    end

    // Field defm_total_pkt_cnt.val @'h140[31:0]

    reg [31:0] defm_total_pkt_cnt_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_total_pkt_cnt_val_value <= 'h0;
        end else if (int_wr_en && defm_total_pkt_cnt_val_strb) begin
            defm_total_pkt_cnt_val_value <= int_wr_data[31:0];
        end else begin
            defm_total_pkt_cnt_val_value <= defm_total_pkt_cnt_val_in;
        end
    end

    // Field defm_ecpri_pkt_cnt.val @'h148[31:0]

    reg [31:0] defm_ecpri_pkt_cnt_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_ecpri_pkt_cnt_val_value <= 'h0;
        end else if (int_wr_en && defm_ecpri_pkt_cnt_val_strb) begin
            defm_ecpri_pkt_cnt_val_value <= int_wr_data[31:0];
        end else begin
            defm_ecpri_pkt_cnt_val_value <= defm_ecpri_pkt_cnt_val_in;
        end
    end

    // Field defm_trans_pkt_cnt.val @'h150[31:0]

    reg [31:0] defm_trans_pkt_cnt_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_trans_pkt_cnt_val_value <= 'h0;
        end else if (int_wr_en && defm_trans_pkt_cnt_val_strb) begin
            defm_trans_pkt_cnt_val_value <= int_wr_data[31:0];
        end else begin
            defm_trans_pkt_cnt_val_value <= defm_trans_pkt_cnt_val_in;
        end
    end

    // Field defm_odm_pkt_cnt.val @'h158[31:0]

    reg [31:0] defm_odm_pkt_cnt_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            defm_odm_pkt_cnt_val_value <= 'h0;
        end else if (int_wr_en && defm_odm_pkt_cnt_val_strb) begin
            defm_odm_pkt_cnt_val_value <= int_wr_data[31:0];
        end else begin
            defm_odm_pkt_cnt_val_value <= defm_odm_pkt_cnt_val_in;
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

    // Field fram_seq_en.val @'h220[15:0]

    reg [15:0] fram_seq_en_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_en_val_value <= 'h0;
        end else if (int_wr_en && fram_seq_en_val_strb) begin
            fram_seq_en_val_value <= int_wr_data[15:0];
        end
    end

    assign fram_seq_en_val_out = fram_seq_en_val_value;

    // Field fram_seq_id_0.id0 @'h224[5:0]

    reg [5:0] fram_seq_id_0_id0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_0_id0_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_0_id0_strb) begin
            fram_seq_id_0_id0_value <= int_wr_data[5:0];
        end
    end

    assign fram_seq_id_0_id0_out = fram_seq_id_0_id0_value;

    // Field fram_seq_id_0.id1 @'h224[13:8]

    reg [5:0] fram_seq_id_0_id1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_0_id1_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_0_id1_strb) begin
            fram_seq_id_0_id1_value <= int_wr_data[13:8];
        end
    end

    assign fram_seq_id_0_id1_out = fram_seq_id_0_id1_value;

    // Field fram_seq_id_0.id2 @'h224[21:16]

    reg [5:0] fram_seq_id_0_id2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_0_id2_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_0_id2_strb) begin
            fram_seq_id_0_id2_value <= int_wr_data[21:16];
        end
    end

    assign fram_seq_id_0_id2_out = fram_seq_id_0_id2_value;

    // Field fram_seq_id_0.id3 @'h224[29:24]

    reg [5:0] fram_seq_id_0_id3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_0_id3_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_0_id3_strb) begin
            fram_seq_id_0_id3_value <= int_wr_data[29:24];
        end
    end

    assign fram_seq_id_0_id3_out = fram_seq_id_0_id3_value;

    // Field fram_seq_id_1.id0 @'h228[5:0]

    reg [5:0] fram_seq_id_1_id0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_1_id0_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_1_id0_strb) begin
            fram_seq_id_1_id0_value <= int_wr_data[5:0];
        end
    end

    assign fram_seq_id_1_id0_out = fram_seq_id_1_id0_value;

    // Field fram_seq_id_1.id1 @'h228[13:8]

    reg [5:0] fram_seq_id_1_id1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_1_id1_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_1_id1_strb) begin
            fram_seq_id_1_id1_value <= int_wr_data[13:8];
        end
    end

    assign fram_seq_id_1_id1_out = fram_seq_id_1_id1_value;

    // Field fram_seq_id_1.id2 @'h228[21:16]

    reg [5:0] fram_seq_id_1_id2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_1_id2_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_1_id2_strb) begin
            fram_seq_id_1_id2_value <= int_wr_data[21:16];
        end
    end

    assign fram_seq_id_1_id2_out = fram_seq_id_1_id2_value;

    // Field fram_seq_id_1.id3 @'h228[29:24]

    reg [5:0] fram_seq_id_1_id3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_1_id3_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_1_id3_strb) begin
            fram_seq_id_1_id3_value <= int_wr_data[29:24];
        end
    end

    assign fram_seq_id_1_id3_out = fram_seq_id_1_id3_value;

    // Field fram_seq_id_2.id0 @'h22c[5:0]

    reg [5:0] fram_seq_id_2_id0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_2_id0_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_2_id0_strb) begin
            fram_seq_id_2_id0_value <= int_wr_data[5:0];
        end
    end

    assign fram_seq_id_2_id0_out = fram_seq_id_2_id0_value;

    // Field fram_seq_id_2.id1 @'h22c[13:8]

    reg [5:0] fram_seq_id_2_id1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_2_id1_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_2_id1_strb) begin
            fram_seq_id_2_id1_value <= int_wr_data[13:8];
        end
    end

    assign fram_seq_id_2_id1_out = fram_seq_id_2_id1_value;

    // Field fram_seq_id_2.id2 @'h22c[21:16]

    reg [5:0] fram_seq_id_2_id2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_2_id2_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_2_id2_strb) begin
            fram_seq_id_2_id2_value <= int_wr_data[21:16];
        end
    end

    assign fram_seq_id_2_id2_out = fram_seq_id_2_id2_value;

    // Field fram_seq_id_2.id3 @'h22c[29:24]

    reg [5:0] fram_seq_id_2_id3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_2_id3_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_2_id3_strb) begin
            fram_seq_id_2_id3_value <= int_wr_data[29:24];
        end
    end

    assign fram_seq_id_2_id3_out = fram_seq_id_2_id3_value;

    // Field fram_seq_id_3.id0 @'h230[5:0]

    reg [5:0] fram_seq_id_3_id0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_3_id0_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_3_id0_strb) begin
            fram_seq_id_3_id0_value <= int_wr_data[5:0];
        end
    end

    assign fram_seq_id_3_id0_out = fram_seq_id_3_id0_value;

    // Field fram_seq_id_3.id1 @'h230[13:8]

    reg [5:0] fram_seq_id_3_id1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_3_id1_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_3_id1_strb) begin
            fram_seq_id_3_id1_value <= int_wr_data[13:8];
        end
    end

    assign fram_seq_id_3_id1_out = fram_seq_id_3_id1_value;

    // Field fram_seq_id_3.id2 @'h230[21:16]

    reg [5:0] fram_seq_id_3_id2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_3_id2_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_3_id2_strb) begin
            fram_seq_id_3_id2_value <= int_wr_data[21:16];
        end
    end

    assign fram_seq_id_3_id2_out = fram_seq_id_3_id2_value;

    // Field fram_seq_id_3.id3 @'h230[29:24]

    reg [5:0] fram_seq_id_3_id3_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_id_3_id3_value <= 'h3f;
        end else if (int_wr_en && fram_seq_id_3_id3_strb) begin
            fram_seq_id_3_id3_value <= int_wr_data[29:24];
        end
    end

    assign fram_seq_id_3_id3_out = fram_seq_id_3_id3_value;

    // Field fram_seq_cnt.val @'h234[7:0]

    reg [7:0] fram_seq_cnt_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            fram_seq_cnt_val_value <= 'h20;
        end else if (int_wr_en && fram_seq_cnt_val_strb) begin
            fram_seq_cnt_val_value <= int_wr_data[7:0];
        end
    end

    assign fram_seq_cnt_val_out = fram_seq_cnt_val_value;

    // Field odm_ctrl.en @'h300[0:0]

    reg [0:0] odm_ctrl_en_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            odm_ctrl_en_value <= 'h1;
        end else if (int_wr_en && odm_ctrl_en_strb) begin
            odm_ctrl_en_value <= int_wr_data[0:0];
        end
    end

    assign odm_ctrl_en_out = odm_ctrl_en_value;

    // Field odm_meas_interval.val @'h308[31:0]

    reg [31:0] odm_meas_interval_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            odm_meas_interval_val_value <= 'h1d4bffff;
        end else if (int_wr_en && odm_meas_interval_val_strb) begin
            odm_meas_interval_val_value <= int_wr_data[31:0];
        end
    end

    assign odm_meas_interval_val_out = odm_meas_interval_val_value;

    // Field ts_diff_ingress_ns.val @'h310[31:0]

    reg [31:0] ts_diff_ingress_ns_val_value;

    always @(*) begin
        ts_diff_ingress_ns_val_value = ts_diff_ingress_ns_val_in;
    end

    // Field ts_diff_ingress_sec_l.val @'h314[31:0]

    reg [31:0] ts_diff_ingress_sec_l_val_value;

    always @(*) begin
        ts_diff_ingress_sec_l_val_value = ts_diff_ingress_sec_l_val_in;
    end

    // Field ts_diff_ingress_sec_h.val @'h318[15:0]

    reg [15:0] ts_diff_ingress_sec_h_val_value;

    always @(*) begin
        ts_diff_ingress_sec_h_val_value = ts_diff_ingress_sec_h_val_in;
    end

    // Field ts_diff_egress_ns.val @'h320[31:0]

    reg [31:0] ts_diff_egress_ns_val_value;

    always @(*) begin
        ts_diff_egress_ns_val_value = ts_diff_egress_ns_val_in;
    end

    // Field ts_diff_egress_sec_l.val @'h324[31:0]

    reg [31:0] ts_diff_egress_sec_l_val_value;

    always @(*) begin
        ts_diff_egress_sec_l_val_value = ts_diff_egress_sec_l_val_in;
    end

    // Field ts_diff_egress_sec_h.val @'h328[15:0]

    reg [15:0] ts_diff_egress_sec_h_val_value;

    always @(*) begin
        ts_diff_egress_sec_h_val_value = ts_diff_egress_sec_h_val_in;
    end

    // Field rx_resync_cnt.val @'h330[31:0]

    reg [31:0] rx_resync_cnt_val_value;

    always @(*) begin
        rx_resync_cnt_val_value = rx_resync_cnt_val_in;
    end

    // Field tx_resync_cnt.val @'h334[31:0]

    reg [31:0] tx_resync_cnt_val_value;

    always @(*) begin
        tx_resync_cnt_val_value = tx_resync_cnt_val_in;
    end

    // Field topology_id.val @'h340[15:0]

    reg [15:0] topology_id_val_value;

    always @(*) begin
        topology_id_val_value = topology_id_val_in;
    end

    // Field lp_topology_id.val @'h344[15:0]

    reg [15:0] lp_topology_id_val_value;

    always @(*) begin
        lp_topology_id_val_value = lp_topology_id_val_in;
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
        if (int_rd_en && stat_rx_status_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | stat_rx_status_value;
        end
        if (int_rd_en && tick_snap_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | tick_snap_value;
        end
        if (int_rd_en && tick_clear_strb) begin
            field_rd_data_next[1:1] = field_rd_data_next[1:1] | tick_clear_value;
        end
        if (int_rd_en && defm_ctrl_en_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | defm_ctrl_en_value;
        end
        if (int_rd_en && defm_ctrl_src_mac_flt_en_strb) begin
            field_rd_data_next[1:1] = field_rd_data_next[1:1] | defm_ctrl_src_mac_flt_en_value;
        end
        if (int_rd_en && defm_ctrl_dest_mac_flt_en_strb) begin
            field_rd_data_next[2:2] = field_rd_data_next[2:2] | defm_ctrl_dest_mac_flt_en_value;
        end
        if (int_rd_en && defm_src_mac_l_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | defm_src_mac_l_val_value;
        end
        if (int_rd_en && defm_src_mac_h_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_src_mac_h_val_value;
        end
        if (int_rd_en && defm_dest_mac_l_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | defm_dest_mac_l_val_value;
        end
        if (int_rd_en && defm_dest_mac_h_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_dest_mac_h_val_value;
        end
        if (int_rd_en && defm_seq_en_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | defm_seq_en_val_value;
        end
        if (int_rd_en && defm_seq_id_0_id0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | defm_seq_id_0_id0_value;
        end
        if (int_rd_en && defm_seq_id_0_id1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | defm_seq_id_0_id1_value;
        end
        if (int_rd_en && defm_seq_id_0_id2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | defm_seq_id_0_id2_value;
        end
        if (int_rd_en && defm_seq_id_0_id3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | defm_seq_id_0_id3_value;
        end
        if (int_rd_en && defm_seq_id_1_id0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | defm_seq_id_1_id0_value;
        end
        if (int_rd_en && defm_seq_id_1_id1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | defm_seq_id_1_id1_value;
        end
        if (int_rd_en && defm_seq_id_1_id2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | defm_seq_id_1_id2_value;
        end
        if (int_rd_en && defm_seq_id_1_id3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | defm_seq_id_1_id3_value;
        end
        if (int_rd_en && defm_seq_id_2_id0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | defm_seq_id_2_id0_value;
        end
        if (int_rd_en && defm_seq_id_2_id1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | defm_seq_id_2_id1_value;
        end
        if (int_rd_en && defm_seq_id_2_id2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | defm_seq_id_2_id2_value;
        end
        if (int_rd_en && defm_seq_id_2_id3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | defm_seq_id_2_id3_value;
        end
        if (int_rd_en && defm_seq_id_3_id0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | defm_seq_id_3_id0_value;
        end
        if (int_rd_en && defm_seq_id_3_id1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | defm_seq_id_3_id1_value;
        end
        if (int_rd_en && defm_seq_id_3_id2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | defm_seq_id_3_id2_value;
        end
        if (int_rd_en && defm_seq_id_3_id3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | defm_seq_id_3_id3_value;
        end
        if (int_rd_en && defm_ts_offset_val_strb) begin
            field_rd_data_next[8:0] = field_rd_data_next[8:0] | defm_ts_offset_val_value;
        end
        if (int_rd_en && defm_conflict_cnt_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | defm_conflict_cnt_val_value;
        end
        if (int_rd_en && defm_total_pkt_cnt_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | defm_total_pkt_cnt_val_value;
        end
        if (int_rd_en && defm_ecpri_pkt_cnt_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | defm_ecpri_pkt_cnt_val_value;
        end
        if (int_rd_en && defm_trans_pkt_cnt_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | defm_trans_pkt_cnt_val_value;
        end
        if (int_rd_en && defm_odm_pkt_cnt_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | defm_odm_pkt_cnt_val_value;
        end
        if (int_rd_en && fram_ctrl_en_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | fram_ctrl_en_value;
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
        if (int_rd_en && fram_seq_en_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | fram_seq_en_val_value;
        end
        if (int_rd_en && fram_seq_id_0_id0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | fram_seq_id_0_id0_value;
        end
        if (int_rd_en && fram_seq_id_0_id1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | fram_seq_id_0_id1_value;
        end
        if (int_rd_en && fram_seq_id_0_id2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | fram_seq_id_0_id2_value;
        end
        if (int_rd_en && fram_seq_id_0_id3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | fram_seq_id_0_id3_value;
        end
        if (int_rd_en && fram_seq_id_1_id0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | fram_seq_id_1_id0_value;
        end
        if (int_rd_en && fram_seq_id_1_id1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | fram_seq_id_1_id1_value;
        end
        if (int_rd_en && fram_seq_id_1_id2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | fram_seq_id_1_id2_value;
        end
        if (int_rd_en && fram_seq_id_1_id3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | fram_seq_id_1_id3_value;
        end
        if (int_rd_en && fram_seq_id_2_id0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | fram_seq_id_2_id0_value;
        end
        if (int_rd_en && fram_seq_id_2_id1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | fram_seq_id_2_id1_value;
        end
        if (int_rd_en && fram_seq_id_2_id2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | fram_seq_id_2_id2_value;
        end
        if (int_rd_en && fram_seq_id_2_id3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | fram_seq_id_2_id3_value;
        end
        if (int_rd_en && fram_seq_id_3_id0_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | fram_seq_id_3_id0_value;
        end
        if (int_rd_en && fram_seq_id_3_id1_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | fram_seq_id_3_id1_value;
        end
        if (int_rd_en && fram_seq_id_3_id2_strb) begin
            field_rd_data_next[21:16] = field_rd_data_next[21:16] | fram_seq_id_3_id2_value;
        end
        if (int_rd_en && fram_seq_id_3_id3_strb) begin
            field_rd_data_next[29:24] = field_rd_data_next[29:24] | fram_seq_id_3_id3_value;
        end
        if (int_rd_en && fram_seq_cnt_val_strb) begin
            field_rd_data_next[7:0] = field_rd_data_next[7:0] | fram_seq_cnt_val_value;
        end
        if (int_rd_en && odm_ctrl_en_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | odm_ctrl_en_value;
        end
        if (int_rd_en && odm_meas_interval_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | odm_meas_interval_val_value;
        end
        if (int_rd_en && ts_diff_ingress_ns_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ts_diff_ingress_ns_val_value;
        end
        if (int_rd_en && ts_diff_ingress_sec_l_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ts_diff_ingress_sec_l_val_value;
        end
        if (int_rd_en && ts_diff_ingress_sec_h_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | ts_diff_ingress_sec_h_val_value;
        end
        if (int_rd_en && ts_diff_egress_ns_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ts_diff_egress_ns_val_value;
        end
        if (int_rd_en && ts_diff_egress_sec_l_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ts_diff_egress_sec_l_val_value;
        end
        if (int_rd_en && ts_diff_egress_sec_h_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | ts_diff_egress_sec_h_val_value;
        end
        if (int_rd_en && rx_resync_cnt_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | rx_resync_cnt_val_value;
        end
        if (int_rd_en && tx_resync_cnt_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | tx_resync_cnt_val_value;
        end
        if (int_rd_en && topology_id_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | topology_id_val_value;
        end
        if (int_rd_en && lp_topology_id_val_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | lp_topology_id_val_value;
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
        if (int_rd_en && stat_rx_status_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && tick_snap_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && tick_clear_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_ctrl_en_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_ctrl_src_mac_flt_en_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_ctrl_dest_mac_flt_en_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_src_mac_l_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_src_mac_h_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_dest_mac_l_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_dest_mac_h_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_en_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_0_id0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_0_id1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_0_id2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_0_id3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_1_id0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_1_id1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_1_id2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_1_id3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_2_id0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_2_id1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_2_id2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_2_id3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_3_id0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_3_id1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_3_id2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_seq_id_3_id3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_ts_offset_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_conflict_cnt_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_total_pkt_cnt_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_ecpri_pkt_cnt_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_trans_pkt_cnt_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && defm_odm_pkt_cnt_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_ctrl_en_strb) begin
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
        if (int_rd_en && fram_seq_en_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_0_id0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_0_id1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_0_id2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_0_id3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_1_id0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_1_id1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_1_id2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_1_id3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_2_id0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_2_id1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_2_id2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_2_id3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_3_id0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_3_id1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_3_id2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_id_3_id3_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && fram_seq_cnt_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && odm_ctrl_en_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && odm_meas_interval_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ts_diff_ingress_ns_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ts_diff_ingress_sec_l_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ts_diff_ingress_sec_h_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ts_diff_egress_ns_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ts_diff_egress_sec_l_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ts_diff_egress_sec_h_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && rx_resync_cnt_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && tx_resync_cnt_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && topology_id_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && lp_topology_id_val_strb) begin
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

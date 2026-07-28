// File: lowphy_regs.v
// Brief: Register block generate for lowphy
`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy_regs (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    //
    input  wire [11:0] s_axi_awaddr,
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
    input  wire [11:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
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
    output wire [ 1:0] dl_rat_cc0_out,
    // dl_rat.cc1,
    output wire [ 1:0] dl_rat_cc1_out,
    // dl_rat.cc2,
    output wire [ 1:0] dl_rat_cc2_out,
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
    // ul_en.cc0,
    output wire [ 3:0] ul_en_cc0_out,
    // ul_en.cc1,
    output wire [ 3:0] ul_en_cc1_out,
    // ul_en.cc2,
    output wire [ 3:0] ul_en_cc2_out,
    // ul_rat.cc0,
    output wire [ 1:0] ul_rat_cc0_out,
    // ul_rat.cc1,
    output wire [ 1:0] ul_rat_cc1_out,
    // ul_rat.cc2,
    output wire [ 1:0] ul_rat_cc2_out,
    // ul_bist.bist_cc0,
    output wire [ 3:0] ul_bist_bist_cc0_out,
    // ul_bist.bist_cc1,
    output wire [ 3:0] ul_bist_bist_cc1_out,
    // ul_bist.bist_cc2,
    output wire [ 3:0] ul_bist_bist_cc2_out,
    // ul_bw.cc0,
    output wire [ 3:0] ul_bw_cc0_out,
    // ul_bw.cc1,
    output wire [ 3:0] ul_bw_cc1_out,
    // ul_bw.cc2,
    output wire [ 3:0] ul_bw_cc2_out,
    // ul_nprb_0.val,
    output wire [ 8:0] ul_nprb_0_val_out,
    // ul_nprb_1.val,
    output wire [ 8:0] ul_nprb_1_val_out,
    // ul_nprb_2.val,
    output wire [ 8:0] ul_nprb_2_val_out,
    // ul_rfs_offset_0.val,
    output wire [22:0] ul_rfs_offset_0_val_out,
    // ul_rfs_offset_1.val,
    output wire [22:0] ul_rfs_offset_1_val_out,
    // ul_rfs_offset_2.val,
    output wire [22:0] ul_rfs_offset_2_val_out,
    // ul_ud.comp_meth,
    output wire [ 3:0] ul_ud_comp_meth_out,
    // ul_ud.iq_width,
    output wire [ 3:0] ul_ud_iq_width_out,
    // ul_ud.fs_offset,
    output wire [ 3:0] ul_ud_fs_offset_out,
    // ul_gain_0_0.val,
    output wire [16:0] ul_gain_0_0_val_out,
    // ul_gain_0_1.val,
    output wire [16:0] ul_gain_0_1_val_out,
    // ul_gain_0_2.val,
    output wire [16:0] ul_gain_0_2_val_out,
    // ul_gain_0_3.val,
    output wire [16:0] ul_gain_0_3_val_out,
    // ul_gain_1_0.val,
    output wire [16:0] ul_gain_1_0_val_out,
    // ul_gain_1_1.val,
    output wire [16:0] ul_gain_1_1_val_out,
    // ul_gain_1_2.val,
    output wire [16:0] ul_gain_1_2_val_out,
    // ul_gain_1_3.val,
    output wire [16:0] ul_gain_1_3_val_out,
    // ul_gain_2_0.val,
    output wire [16:0] ul_gain_2_0_val_out,
    // ul_gain_2_1.val,
    output wire [16:0] ul_gain_2_1_val_out,
    // ul_gain_2_2.val,
    output wire [16:0] ul_gain_2_2_val_out,
    // ul_gain_2_3.val,
    output wire [16:0] ul_gain_2_3_val_out,
    // prach_en.cc0,
    output wire [ 3:0] prach_en_cc0_out,
    // prach_en.cc1,
    output wire [ 3:0] prach_en_cc1_out,
    // prach_en.cc2,
    output wire [ 3:0] prach_en_cc2_out,
    // prach_format.cc0,
    output wire [ 3:0] prach_format_cc0_out,
    // prach_format.cc1,
    output wire [ 3:0] prach_format_cc1_out,
    // prach_format.cc2,
    output wire [ 3:0] prach_format_cc2_out,
    // prach_rat.cc0,
    output wire [ 1:0] prach_rat_cc0_out,
    // prach_rat.cc1,
    output wire [ 1:0] prach_rat_cc1_out,
    // prach_rat.cc2,
    output wire [ 1:0] prach_rat_cc2_out,
    // prach_bist.bist_cc0,
    output wire [ 3:0] prach_bist_bist_cc0_out,
    // prach_bist.bist_cc1,
    output wire [ 3:0] prach_bist_bist_cc1_out,
    // prach_bist.bist_cc2,
    output wire [ 3:0] prach_bist_bist_cc2_out,
    // prach_bist.static_c_cc0,
    output wire [ 3:0] prach_bist_static_c_cc0_out,
    // prach_bist.static_c_cc1,
    output wire [ 3:0] prach_bist_static_c_cc1_out,
    // prach_bist.static_c_cc2,
    output wire [ 3:0] prach_bist_static_c_cc2_out,
    // prach_bw.cc0,
    output wire [ 3:0] prach_bw_cc0_out,
    // prach_bw.cc1,
    output wire [ 3:0] prach_bw_cc1_out,
    // prach_bw.cc2,
    output wire [ 3:0] prach_bw_cc2_out,
    // prach_rfs_offset_0.val,
    output wire [22:0] prach_rfs_offset_0_val_out,
    // prach_rfs_offset_1.val,
    output wire [22:0] prach_rfs_offset_1_val_out,
    // prach_rfs_offset_2.val,
    output wire [22:0] prach_rfs_offset_2_val_out,
    // prach_ta3_offset_0.val,
    output wire [22:0] prach_ta3_offset_0_val_out,
    // prach_ta3_offset_1.val,
    output wire [22:0] prach_ta3_offset_1_val_out,
    // prach_ta3_offset_2.val,
    output wire [22:0] prach_ta3_offset_2_val_out,
    // prach_ud.comp_meth,
    output wire [ 3:0] prach_ud_comp_meth_out,
    // prach_ud.iq_width,
    output wire [ 3:0] prach_ud_iq_width_out,
    // prach_ud.fs_offset,
    output wire [ 3:0] prach_ud_fs_offset_out,
    // prach_cfg0_0.symbol_id,
    output wire [ 5:0] prach_cfg0_0_symbol_id_out,
    // prach_cfg0_0.slot_id,
    output wire [ 5:0] prach_cfg0_0_slot_id_out,
    // prach_cfg0_0.subframe_id,
    output wire [ 3:0] prach_cfg0_0_subframe_id_out,
    // prach_cfg0_0.subframe_inc,
    output wire [ 3:0] prach_cfg0_0_subframe_inc_out,
    // prach_cfg0_1.symbol_id,
    output wire [ 5:0] prach_cfg0_1_symbol_id_out,
    // prach_cfg0_1.slot_id,
    output wire [ 5:0] prach_cfg0_1_slot_id_out,
    // prach_cfg0_1.subframe_id,
    output wire [ 3:0] prach_cfg0_1_subframe_id_out,
    // prach_cfg0_1.subframe_inc,
    output wire [ 3:0] prach_cfg0_1_subframe_inc_out,
    // prach_cfg0_2.symbol_id,
    output wire [ 5:0] prach_cfg0_2_symbol_id_out,
    // prach_cfg0_2.slot_id,
    output wire [ 5:0] prach_cfg0_2_slot_id_out,
    // prach_cfg0_2.subframe_id,
    output wire [ 3:0] prach_cfg0_2_subframe_id_out,
    // prach_cfg0_2.subframe_inc,
    output wire [ 3:0] prach_cfg0_2_subframe_inc_out,
    // prach_cfg1_0.time_offset,
    output wire [15:0] prach_cfg1_0_time_offset_out,
    // prach_cfg1_0.cp_length,
    output wire [15:0] prach_cfg1_0_cp_length_out,
    // prach_cfg1_1.time_offset,
    output wire [15:0] prach_cfg1_1_time_offset_out,
    // prach_cfg1_1.cp_length,
    output wire [15:0] prach_cfg1_1_cp_length_out,
    // prach_cfg1_2.time_offset,
    output wire [15:0] prach_cfg1_2_time_offset_out,
    // prach_cfg1_2.cp_length,
    output wire [15:0] prach_cfg1_2_cp_length_out,
    // prach_cfg2_0.num_symbol,
    output wire [ 3:0] prach_cfg2_0_num_symbol_out,
    // prach_cfg2_0.freq_offset,
    output wire [23:0] prach_cfg2_0_freq_offset_out,
    // prach_cfg2_1.num_symbol,
    output wire [ 3:0] prach_cfg2_1_num_symbol_out,
    // prach_cfg2_1.freq_offset,
    output wire [23:0] prach_cfg2_1_freq_offset_out,
    // prach_cfg2_2.num_symbol,
    output wire [ 3:0] prach_cfg2_2_num_symbol_out,
    // prach_cfg2_2.freq_offset,
    output wire [23:0] prach_cfg2_2_freq_offset_out,
    // prach_cfg3_0.sampling_offset,
    output wire [15:0] prach_cfg3_0_sampling_offset_out,
    // prach_cfg3_1.sampling_offset,
    output wire [15:0] prach_cfg3_1_sampling_offset_out,
    // prach_cfg3_2.sampling_offset,
    output wire [15:0] prach_cfg3_2_sampling_offset_out,
    // prach_msg0_0.symbol_id,
    input  wire [ 5:0] prach_msg0_0_symbol_id_in,
    // prach_msg0_0.slot_id,
    input  wire [ 5:0] prach_msg0_0_slot_id_in,
    // prach_msg0_0.subframe_id,
    input  wire [ 3:0] prach_msg0_0_subframe_id_in,
    // prach_msg0_1.symbol_id,
    input  wire [ 5:0] prach_msg0_1_symbol_id_in,
    // prach_msg0_1.slot_id,
    input  wire [ 5:0] prach_msg0_1_slot_id_in,
    // prach_msg0_1.subframe_id,
    input  wire [ 3:0] prach_msg0_1_subframe_id_in,
    // prach_msg0_2.symbol_id,
    input  wire [ 5:0] prach_msg0_2_symbol_id_in,
    // prach_msg0_2.slot_id,
    input  wire [ 5:0] prach_msg0_2_slot_id_in,
    // prach_msg0_2.subframe_id,
    input  wire [ 3:0] prach_msg0_2_subframe_id_in,
    // prach_msg1_0.time_offset,
    input  wire [15:0] prach_msg1_0_time_offset_in,
    // prach_msg1_0.cp_length,
    input  wire [15:0] prach_msg1_0_cp_length_in,
    // prach_msg1_1.time_offset,
    input  wire [15:0] prach_msg1_1_time_offset_in,
    // prach_msg1_1.cp_length,
    input  wire [15:0] prach_msg1_1_cp_length_in,
    // prach_msg1_2.time_offset,
    input  wire [15:0] prach_msg1_2_time_offset_in,
    // prach_msg1_2.cp_length,
    input  wire [15:0] prach_msg1_2_cp_length_in,
    // prach_msg2_0.num_symbol,
    input  wire [ 3:0] prach_msg2_0_num_symbol_in,
    // prach_msg2_0.freq_offset,
    input  wire [23:0] prach_msg2_0_freq_offset_in,
    // prach_msg2_1.num_symbol,
    input  wire [ 3:0] prach_msg2_1_num_symbol_in,
    // prach_msg2_1.freq_offset,
    input  wire [23:0] prach_msg2_1_freq_offset_in,
    // prach_msg2_2.num_symbol,
    input  wire [ 3:0] prach_msg2_2_num_symbol_in,
    // prach_msg2_2.freq_offset,
    input  wire [23:0] prach_msg2_2_freq_offset_in,
    // dl_phase_comp,
    output wire [ 5:0] dl_phase_comp_addr,
    output wire        dl_phase_comp_en,
    output wire        dl_phase_comp_we,
    output wire [31:0] dl_phase_comp_din,
    input  wire [31:0] dl_phase_comp_dout,
    input  wire        dl_phase_comp_valid,
    // ul_phase_comp,
    output wire [ 5:0] ul_phase_comp_addr,
    output wire        ul_phase_comp_en,
    output wire        ul_phase_comp_we,
    output wire [31:0] ul_phase_comp_din,
    input  wire [31:0] ul_phase_comp_dout,
    input  wire        ul_phase_comp_valid
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

    reg  [11:0] int_addr;
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
            aw_addr <= '0;
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
            w_data <= '0;
        end else if (w_hsk) begin
            w_data <= s_axi_wdata;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            w_strb <= '0;
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
            ar_addr <= '0;
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
            r_data <= '0;
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
            int_addr <= '0;
        end else if (aw_req && w_req && ~int_wr_req) begin
            int_addr <= aw_addr;
        end else if (~(aw_req && w_req) && ar_req && ~int_rd_req) begin
            int_addr <= ar_addr;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_wr_data <= '0;
        end else if (w_req && aw_req && ~int_wr_req) begin
            int_wr_data <= w_data;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            int_wr_strb <= '0;
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

    wire ul_en_cc0_strb;

    assign ul_en_cc0_strb = (int_addr[11:2] == 'h84);

    wire ul_en_cc1_strb;

    assign ul_en_cc1_strb = (int_addr[11:2] == 'h84);

    wire ul_en_cc2_strb;

    assign ul_en_cc2_strb = (int_addr[11:2] == 'h84);

    wire ul_rat_cc0_strb;

    assign ul_rat_cc0_strb = (int_addr[11:2] == 'h85);

    wire ul_rat_cc1_strb;

    assign ul_rat_cc1_strb = (int_addr[11:2] == 'h85);

    wire ul_rat_cc2_strb;

    assign ul_rat_cc2_strb = (int_addr[11:2] == 'h85);

    wire ul_bist_bist_cc0_strb;

    assign ul_bist_bist_cc0_strb = (int_addr[11:2] == 'h86);

    wire ul_bist_bist_cc1_strb;

    assign ul_bist_bist_cc1_strb = (int_addr[11:2] == 'h86);

    wire ul_bist_bist_cc2_strb;

    assign ul_bist_bist_cc2_strb = (int_addr[11:2] == 'h86);

    wire ul_bw_cc0_strb;

    assign ul_bw_cc0_strb = (int_addr[11:2] == 'h87);

    wire ul_bw_cc1_strb;

    assign ul_bw_cc1_strb = (int_addr[11:2] == 'h87);

    wire ul_bw_cc2_strb;

    assign ul_bw_cc2_strb = (int_addr[11:2] == 'h87);

    wire ul_nprb_0_val_strb;

    assign ul_nprb_0_val_strb = (int_addr[11:2] == 'h88);

    wire ul_nprb_1_val_strb;

    assign ul_nprb_1_val_strb = (int_addr[11:2] == 'h89);

    wire ul_nprb_2_val_strb;

    assign ul_nprb_2_val_strb = (int_addr[11:2] == 'h8a);

    wire ul_rfs_offset_0_val_strb;

    assign ul_rfs_offset_0_val_strb = (int_addr[11:2] == 'h8c);

    wire ul_rfs_offset_1_val_strb;

    assign ul_rfs_offset_1_val_strb = (int_addr[11:2] == 'h8d);

    wire ul_rfs_offset_2_val_strb;

    assign ul_rfs_offset_2_val_strb = (int_addr[11:2] == 'h8e);

    wire ul_ud_comp_meth_strb;

    assign ul_ud_comp_meth_strb = (int_addr[11:2] == 'h96);

    wire ul_ud_iq_width_strb;

    assign ul_ud_iq_width_strb = (int_addr[11:2] == 'h96);

    wire ul_ud_fs_offset_strb;

    assign ul_ud_fs_offset_strb = (int_addr[11:2] == 'h96);

    wire ul_gain_0_0_val_strb;

    assign ul_gain_0_0_val_strb = (int_addr[11:2] == 'hc0);

    wire ul_gain_0_1_val_strb;

    assign ul_gain_0_1_val_strb = (int_addr[11:2] == 'hc1);

    wire ul_gain_0_2_val_strb;

    assign ul_gain_0_2_val_strb = (int_addr[11:2] == 'hc2);

    wire ul_gain_0_3_val_strb;

    assign ul_gain_0_3_val_strb = (int_addr[11:2] == 'hc3);

    wire ul_gain_1_0_val_strb;

    assign ul_gain_1_0_val_strb = (int_addr[11:2] == 'hc4);

    wire ul_gain_1_1_val_strb;

    assign ul_gain_1_1_val_strb = (int_addr[11:2] == 'hc5);

    wire ul_gain_1_2_val_strb;

    assign ul_gain_1_2_val_strb = (int_addr[11:2] == 'hc6);

    wire ul_gain_1_3_val_strb;

    assign ul_gain_1_3_val_strb = (int_addr[11:2] == 'hc7);

    wire ul_gain_2_0_val_strb;

    assign ul_gain_2_0_val_strb = (int_addr[11:2] == 'hc8);

    wire ul_gain_2_1_val_strb;

    assign ul_gain_2_1_val_strb = (int_addr[11:2] == 'hc9);

    wire ul_gain_2_2_val_strb;

    assign ul_gain_2_2_val_strb = (int_addr[11:2] == 'hca);

    wire ul_gain_2_3_val_strb;

    assign ul_gain_2_3_val_strb = (int_addr[11:2] == 'hcb);

    wire prach_en_cc0_strb;

    assign prach_en_cc0_strb = (int_addr[11:2] == 'h104);

    wire prach_en_cc1_strb;

    assign prach_en_cc1_strb = (int_addr[11:2] == 'h104);

    wire prach_en_cc2_strb;

    assign prach_en_cc2_strb = (int_addr[11:2] == 'h104);

    wire prach_format_cc0_strb;

    assign prach_format_cc0_strb = (int_addr[11:2] == 'h105);

    wire prach_format_cc1_strb;

    assign prach_format_cc1_strb = (int_addr[11:2] == 'h105);

    wire prach_format_cc2_strb;

    assign prach_format_cc2_strb = (int_addr[11:2] == 'h105);

    wire prach_rat_cc0_strb;

    assign prach_rat_cc0_strb = (int_addr[11:2] == 'h106);

    wire prach_rat_cc1_strb;

    assign prach_rat_cc1_strb = (int_addr[11:2] == 'h106);

    wire prach_rat_cc2_strb;

    assign prach_rat_cc2_strb = (int_addr[11:2] == 'h106);

    wire prach_bist_bist_cc0_strb;

    assign prach_bist_bist_cc0_strb = (int_addr[11:2] == 'h107);

    wire prach_bist_bist_cc1_strb;

    assign prach_bist_bist_cc1_strb = (int_addr[11:2] == 'h107);

    wire prach_bist_bist_cc2_strb;

    assign prach_bist_bist_cc2_strb = (int_addr[11:2] == 'h107);

    wire prach_bist_static_c_cc0_strb;

    assign prach_bist_static_c_cc0_strb = (int_addr[11:2] == 'h107);

    wire prach_bist_static_c_cc1_strb;

    assign prach_bist_static_c_cc1_strb = (int_addr[11:2] == 'h107);

    wire prach_bist_static_c_cc2_strb;

    assign prach_bist_static_c_cc2_strb = (int_addr[11:2] == 'h107);

    wire prach_bw_cc0_strb;

    assign prach_bw_cc0_strb = (int_addr[11:2] == 'h108);

    wire prach_bw_cc1_strb;

    assign prach_bw_cc1_strb = (int_addr[11:2] == 'h108);

    wire prach_bw_cc2_strb;

    assign prach_bw_cc2_strb = (int_addr[11:2] == 'h108);

    wire prach_rfs_offset_0_val_strb;

    assign prach_rfs_offset_0_val_strb = (int_addr[11:2] == 'h10c);

    wire prach_rfs_offset_1_val_strb;

    assign prach_rfs_offset_1_val_strb = (int_addr[11:2] == 'h10d);

    wire prach_rfs_offset_2_val_strb;

    assign prach_rfs_offset_2_val_strb = (int_addr[11:2] == 'h10e);

    wire prach_ta3_offset_0_val_strb;

    assign prach_ta3_offset_0_val_strb = (int_addr[11:2] == 'h110);

    wire prach_ta3_offset_1_val_strb;

    assign prach_ta3_offset_1_val_strb = (int_addr[11:2] == 'h111);

    wire prach_ta3_offset_2_val_strb;

    assign prach_ta3_offset_2_val_strb = (int_addr[11:2] == 'h112);

    wire prach_ud_comp_meth_strb;

    assign prach_ud_comp_meth_strb = (int_addr[11:2] == 'h116);

    wire prach_ud_iq_width_strb;

    assign prach_ud_iq_width_strb = (int_addr[11:2] == 'h116);

    wire prach_ud_fs_offset_strb;

    assign prach_ud_fs_offset_strb = (int_addr[11:2] == 'h116);

    wire prach_cfg0_0_symbol_id_strb;

    assign prach_cfg0_0_symbol_id_strb = (int_addr[11:2] == 'h118);

    wire prach_cfg0_0_slot_id_strb;

    assign prach_cfg0_0_slot_id_strb = (int_addr[11:2] == 'h118);

    wire prach_cfg0_0_subframe_id_strb;

    assign prach_cfg0_0_subframe_id_strb = (int_addr[11:2] == 'h118);

    wire prach_cfg0_0_subframe_inc_strb;

    assign prach_cfg0_0_subframe_inc_strb = (int_addr[11:2] == 'h118);

    wire prach_cfg0_1_symbol_id_strb;

    assign prach_cfg0_1_symbol_id_strb = (int_addr[11:2] == 'h119);

    wire prach_cfg0_1_slot_id_strb;

    assign prach_cfg0_1_slot_id_strb = (int_addr[11:2] == 'h119);

    wire prach_cfg0_1_subframe_id_strb;

    assign prach_cfg0_1_subframe_id_strb = (int_addr[11:2] == 'h119);

    wire prach_cfg0_1_subframe_inc_strb;

    assign prach_cfg0_1_subframe_inc_strb = (int_addr[11:2] == 'h119);

    wire prach_cfg0_2_symbol_id_strb;

    assign prach_cfg0_2_symbol_id_strb = (int_addr[11:2] == 'h11a);

    wire prach_cfg0_2_slot_id_strb;

    assign prach_cfg0_2_slot_id_strb = (int_addr[11:2] == 'h11a);

    wire prach_cfg0_2_subframe_id_strb;

    assign prach_cfg0_2_subframe_id_strb = (int_addr[11:2] == 'h11a);

    wire prach_cfg0_2_subframe_inc_strb;

    assign prach_cfg0_2_subframe_inc_strb = (int_addr[11:2] == 'h11a);

    wire prach_cfg1_0_time_offset_strb;

    assign prach_cfg1_0_time_offset_strb = (int_addr[11:2] == 'h11c);

    wire prach_cfg1_0_cp_length_strb;

    assign prach_cfg1_0_cp_length_strb = (int_addr[11:2] == 'h11c);

    wire prach_cfg1_1_time_offset_strb;

    assign prach_cfg1_1_time_offset_strb = (int_addr[11:2] == 'h11d);

    wire prach_cfg1_1_cp_length_strb;

    assign prach_cfg1_1_cp_length_strb = (int_addr[11:2] == 'h11d);

    wire prach_cfg1_2_time_offset_strb;

    assign prach_cfg1_2_time_offset_strb = (int_addr[11:2] == 'h11e);

    wire prach_cfg1_2_cp_length_strb;

    assign prach_cfg1_2_cp_length_strb = (int_addr[11:2] == 'h11e);

    wire prach_cfg2_0_num_symbol_strb;

    assign prach_cfg2_0_num_symbol_strb = (int_addr[11:2] == 'h120);

    wire prach_cfg2_0_freq_offset_strb;

    assign prach_cfg2_0_freq_offset_strb = (int_addr[11:2] == 'h120);

    wire prach_cfg2_1_num_symbol_strb;

    assign prach_cfg2_1_num_symbol_strb = (int_addr[11:2] == 'h121);

    wire prach_cfg2_1_freq_offset_strb;

    assign prach_cfg2_1_freq_offset_strb = (int_addr[11:2] == 'h121);

    wire prach_cfg2_2_num_symbol_strb;

    assign prach_cfg2_2_num_symbol_strb = (int_addr[11:2] == 'h122);

    wire prach_cfg2_2_freq_offset_strb;

    assign prach_cfg2_2_freq_offset_strb = (int_addr[11:2] == 'h122);

    wire prach_cfg3_0_sampling_offset_strb;

    assign prach_cfg3_0_sampling_offset_strb = (int_addr[11:2] == 'h124);

    wire prach_cfg3_1_sampling_offset_strb;

    assign prach_cfg3_1_sampling_offset_strb = (int_addr[11:2] == 'h125);

    wire prach_cfg3_2_sampling_offset_strb;

    assign prach_cfg3_2_sampling_offset_strb = (int_addr[11:2] == 'h126);

    wire prach_msg0_0_symbol_id_strb;

    assign prach_msg0_0_symbol_id_strb = (int_addr[11:2] == 'h140);

    wire prach_msg0_0_slot_id_strb;

    assign prach_msg0_0_slot_id_strb = (int_addr[11:2] == 'h140);

    wire prach_msg0_0_subframe_id_strb;

    assign prach_msg0_0_subframe_id_strb = (int_addr[11:2] == 'h140);

    wire prach_msg0_1_symbol_id_strb;

    assign prach_msg0_1_symbol_id_strb = (int_addr[11:2] == 'h141);

    wire prach_msg0_1_slot_id_strb;

    assign prach_msg0_1_slot_id_strb = (int_addr[11:2] == 'h141);

    wire prach_msg0_1_subframe_id_strb;

    assign prach_msg0_1_subframe_id_strb = (int_addr[11:2] == 'h141);

    wire prach_msg0_2_symbol_id_strb;

    assign prach_msg0_2_symbol_id_strb = (int_addr[11:2] == 'h142);

    wire prach_msg0_2_slot_id_strb;

    assign prach_msg0_2_slot_id_strb = (int_addr[11:2] == 'h142);

    wire prach_msg0_2_subframe_id_strb;

    assign prach_msg0_2_subframe_id_strb = (int_addr[11:2] == 'h142);

    wire prach_msg1_0_time_offset_strb;

    assign prach_msg1_0_time_offset_strb = (int_addr[11:2] == 'h144);

    wire prach_msg1_0_cp_length_strb;

    assign prach_msg1_0_cp_length_strb = (int_addr[11:2] == 'h144);

    wire prach_msg1_1_time_offset_strb;

    assign prach_msg1_1_time_offset_strb = (int_addr[11:2] == 'h145);

    wire prach_msg1_1_cp_length_strb;

    assign prach_msg1_1_cp_length_strb = (int_addr[11:2] == 'h145);

    wire prach_msg1_2_time_offset_strb;

    assign prach_msg1_2_time_offset_strb = (int_addr[11:2] == 'h146);

    wire prach_msg1_2_cp_length_strb;

    assign prach_msg1_2_cp_length_strb = (int_addr[11:2] == 'h146);

    wire prach_msg2_0_num_symbol_strb;

    assign prach_msg2_0_num_symbol_strb = (int_addr[11:2] == 'h148);

    wire prach_msg2_0_freq_offset_strb;

    assign prach_msg2_0_freq_offset_strb = (int_addr[11:2] == 'h148);

    wire prach_msg2_1_num_symbol_strb;

    assign prach_msg2_1_num_symbol_strb = (int_addr[11:2] == 'h149);

    wire prach_msg2_1_freq_offset_strb;

    assign prach_msg2_1_freq_offset_strb = (int_addr[11:2] == 'h149);

    wire prach_msg2_2_num_symbol_strb;

    assign prach_msg2_2_num_symbol_strb = (int_addr[11:2] == 'h14a);

    wire prach_msg2_2_freq_offset_strb;

    assign prach_msg2_2_freq_offset_strb = (int_addr[11:2] == 'h14a);

    wire dl_phase_comp_strb;

    assign dl_phase_comp_strb = (int_addr[11:8] == 'h8);

    wire ul_phase_comp_strb;

    assign ul_phase_comp_strb = (int_addr[11:8] == 'ha);

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
        if (ul_en_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_en_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_en_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_rat_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_rat_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_rat_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_bist_bist_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_bist_bist_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_bist_bist_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_bw_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_bw_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_bw_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_nprb_0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_nprb_1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_nprb_2_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_rfs_offset_0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_rfs_offset_1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_rfs_offset_2_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_ud_comp_meth_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_ud_iq_width_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_ud_fs_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_gain_0_0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_gain_0_1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_gain_0_2_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_gain_0_3_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_gain_1_0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_gain_1_1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_gain_1_2_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_gain_1_3_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_gain_2_0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_gain_2_1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_gain_2_2_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_gain_2_3_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_en_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_en_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_en_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_format_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_format_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_format_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_rat_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_rat_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_rat_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_bist_bist_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_bist_bist_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_bist_bist_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_bist_static_c_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_bist_static_c_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_bist_static_c_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_bw_cc0_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_bw_cc1_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_bw_cc2_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_rfs_offset_0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_rfs_offset_1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_rfs_offset_2_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_ta3_offset_0_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_ta3_offset_1_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_ta3_offset_2_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_ud_comp_meth_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_ud_iq_width_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_ud_fs_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg0_0_symbol_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg0_0_slot_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg0_0_subframe_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg0_0_subframe_inc_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg0_1_symbol_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg0_1_slot_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg0_1_subframe_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg0_1_subframe_inc_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg0_2_symbol_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg0_2_slot_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg0_2_subframe_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg0_2_subframe_inc_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg1_0_time_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg1_0_cp_length_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg1_1_time_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg1_1_cp_length_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg1_2_time_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg1_2_cp_length_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg2_0_num_symbol_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg2_0_freq_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg2_1_num_symbol_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg2_1_freq_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg2_2_num_symbol_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg2_2_freq_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg3_0_sampling_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg3_1_sampling_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_cfg3_2_sampling_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg0_0_symbol_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg0_0_slot_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg0_0_subframe_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg0_1_symbol_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg0_1_slot_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg0_1_subframe_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg0_2_symbol_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg0_2_slot_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg0_2_subframe_id_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg1_0_time_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg1_0_cp_length_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg1_1_time_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg1_1_cp_length_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg1_2_time_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg1_2_cp_length_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg2_0_num_symbol_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg2_0_freq_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg2_1_num_symbol_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg2_1_freq_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg2_2_num_symbol_strb) begin
            int_wr_err <= 1'b0;
        end
        if (prach_msg2_2_freq_offset_strb) begin
            int_wr_err <= 1'b0;
        end
        if (dl_phase_comp_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ul_phase_comp_strb) begin
            int_wr_err <= 1'b0;
        end
    end

    always @(posedge s_axi_aclk) begin
        int_rd_ack <= int_rd_en;
        if (dl_phase_comp_strb) begin
            int_rd_ack <= int_rd_req && dl_phase_comp_valid;
        end
        if (ul_phase_comp_strb) begin
            int_rd_ack <= int_rd_req && ul_phase_comp_valid;
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
        if (ul_en_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_en_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_en_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_rat_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_rat_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_rat_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_bist_bist_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_bist_bist_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_bist_bist_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_bw_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_bw_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_bw_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_nprb_0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_nprb_1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_nprb_2_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_rfs_offset_0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_rfs_offset_1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_rfs_offset_2_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_ud_comp_meth_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_ud_iq_width_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_ud_fs_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_gain_0_0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_gain_0_1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_gain_0_2_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_gain_0_3_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_gain_1_0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_gain_1_1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_gain_1_2_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_gain_1_3_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_gain_2_0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_gain_2_1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_gain_2_2_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_gain_2_3_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_en_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_en_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_en_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_format_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_format_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_format_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_rat_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_rat_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_rat_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_bist_bist_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_bist_bist_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_bist_bist_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_bist_static_c_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_bist_static_c_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_bist_static_c_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_bw_cc0_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_bw_cc1_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_bw_cc2_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_rfs_offset_0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_rfs_offset_1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_rfs_offset_2_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_ta3_offset_0_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_ta3_offset_1_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_ta3_offset_2_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_ud_comp_meth_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_ud_iq_width_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_ud_fs_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg0_0_symbol_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg0_0_slot_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg0_0_subframe_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg0_0_subframe_inc_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg0_1_symbol_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg0_1_slot_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg0_1_subframe_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg0_1_subframe_inc_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg0_2_symbol_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg0_2_slot_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg0_2_subframe_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg0_2_subframe_inc_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg1_0_time_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg1_0_cp_length_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg1_1_time_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg1_1_cp_length_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg1_2_time_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg1_2_cp_length_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg2_0_num_symbol_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg2_0_freq_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg2_1_num_symbol_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg2_1_freq_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg2_2_num_symbol_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg2_2_freq_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg3_0_sampling_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg3_1_sampling_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_cfg3_2_sampling_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg0_0_symbol_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg0_0_slot_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg0_0_subframe_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg0_1_symbol_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg0_1_slot_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg0_1_subframe_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg0_2_symbol_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg0_2_slot_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg0_2_subframe_id_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg1_0_time_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg1_0_cp_length_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg1_1_time_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg1_1_cp_length_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg1_2_time_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg1_2_cp_length_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg2_0_num_symbol_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg2_0_freq_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg2_1_num_symbol_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg2_1_freq_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg2_2_num_symbol_strb) begin
            int_rd_err <= 1'b0;
        end
        if (prach_msg2_2_freq_offset_strb) begin
            int_rd_err <= 1'b0;
        end
        if (dl_phase_comp_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ul_phase_comp_strb) begin
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

    // Field dl_rat.cc0 @'h14[1:0]

    reg [1:0] dl_rat_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_rat_cc0_value <= 'h0;
        end else if (int_wr_en && dl_rat_cc0_strb) begin
            dl_rat_cc0_value <= int_wr_data[1:0];
        end
    end

    assign dl_rat_cc0_out = dl_rat_cc0_value;

    // Field dl_rat.cc1 @'h14[5:4]

    reg [1:0] dl_rat_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_rat_cc1_value <= 'h0;
        end else if (int_wr_en && dl_rat_cc1_strb) begin
            dl_rat_cc1_value <= int_wr_data[5:4];
        end
    end

    assign dl_rat_cc1_out = dl_rat_cc1_value;

    // Field dl_rat.cc2 @'h14[9:8]

    reg [1:0] dl_rat_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            dl_rat_cc2_value <= 'h0;
        end else if (int_wr_en && dl_rat_cc2_strb) begin
            dl_rat_cc2_value <= int_wr_data[9:8];
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

    // Field ul_en.cc0 @'h210[3:0]

    reg [3:0] ul_en_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_en_cc0_value <= 'h0;
        end else if (int_wr_en && ul_en_cc0_strb) begin
            ul_en_cc0_value <= int_wr_data[3:0];
        end
    end

    assign ul_en_cc0_out = ul_en_cc0_value;

    // Field ul_en.cc1 @'h210[7:4]

    reg [3:0] ul_en_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_en_cc1_value <= 'h0;
        end else if (int_wr_en && ul_en_cc1_strb) begin
            ul_en_cc1_value <= int_wr_data[7:4];
        end
    end

    assign ul_en_cc1_out = ul_en_cc1_value;

    // Field ul_en.cc2 @'h210[11:8]

    reg [3:0] ul_en_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_en_cc2_value <= 'h0;
        end else if (int_wr_en && ul_en_cc2_strb) begin
            ul_en_cc2_value <= int_wr_data[11:8];
        end
    end

    assign ul_en_cc2_out = ul_en_cc2_value;

    // Field ul_rat.cc0 @'h214[1:0]

    reg [1:0] ul_rat_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_rat_cc0_value <= 'h0;
        end else if (int_wr_en && ul_rat_cc0_strb) begin
            ul_rat_cc0_value <= int_wr_data[1:0];
        end
    end

    assign ul_rat_cc0_out = ul_rat_cc0_value;

    // Field ul_rat.cc1 @'h214[5:4]

    reg [1:0] ul_rat_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_rat_cc1_value <= 'h0;
        end else if (int_wr_en && ul_rat_cc1_strb) begin
            ul_rat_cc1_value <= int_wr_data[5:4];
        end
    end

    assign ul_rat_cc1_out = ul_rat_cc1_value;

    // Field ul_rat.cc2 @'h214[9:8]

    reg [1:0] ul_rat_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_rat_cc2_value <= 'h0;
        end else if (int_wr_en && ul_rat_cc2_strb) begin
            ul_rat_cc2_value <= int_wr_data[9:8];
        end
    end

    assign ul_rat_cc2_out = ul_rat_cc2_value;

    // Field ul_bist.bist_cc0 @'h218[3:0]

    reg [3:0] ul_bist_bist_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_bist_bist_cc0_value <= 'h0;
        end else if (int_wr_en && ul_bist_bist_cc0_strb) begin
            ul_bist_bist_cc0_value <= int_wr_data[3:0];
        end
    end

    assign ul_bist_bist_cc0_out = ul_bist_bist_cc0_value;

    // Field ul_bist.bist_cc1 @'h218[7:4]

    reg [3:0] ul_bist_bist_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_bist_bist_cc1_value <= 'h0;
        end else if (int_wr_en && ul_bist_bist_cc1_strb) begin
            ul_bist_bist_cc1_value <= int_wr_data[7:4];
        end
    end

    assign ul_bist_bist_cc1_out = ul_bist_bist_cc1_value;

    // Field ul_bist.bist_cc2 @'h218[11:8]

    reg [3:0] ul_bist_bist_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_bist_bist_cc2_value <= 'h0;
        end else if (int_wr_en && ul_bist_bist_cc2_strb) begin
            ul_bist_bist_cc2_value <= int_wr_data[11:8];
        end
    end

    assign ul_bist_bist_cc2_out = ul_bist_bist_cc2_value;

    // Field ul_bw.cc0 @'h21c[3:0]

    reg [3:0] ul_bw_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_bw_cc0_value <= 'h2;
        end else if (int_wr_en && ul_bw_cc0_strb) begin
            ul_bw_cc0_value <= int_wr_data[3:0];
        end
    end

    assign ul_bw_cc0_out = ul_bw_cc0_value;

    // Field ul_bw.cc1 @'h21c[7:4]

    reg [3:0] ul_bw_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_bw_cc1_value <= 'h2;
        end else if (int_wr_en && ul_bw_cc1_strb) begin
            ul_bw_cc1_value <= int_wr_data[7:4];
        end
    end

    assign ul_bw_cc1_out = ul_bw_cc1_value;

    // Field ul_bw.cc2 @'h21c[11:8]

    reg [3:0] ul_bw_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_bw_cc2_value <= 'h2;
        end else if (int_wr_en && ul_bw_cc2_strb) begin
            ul_bw_cc2_value <= int_wr_data[11:8];
        end
    end

    assign ul_bw_cc2_out = ul_bw_cc2_value;

    // Field ul_nprb_0.val @'h220[8:0]

    reg [8:0] ul_nprb_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_nprb_0_val_value <= 'h64;
        end else if (int_wr_en && ul_nprb_0_val_strb) begin
            ul_nprb_0_val_value <= int_wr_data[8:0];
        end
    end

    assign ul_nprb_0_val_out = ul_nprb_0_val_value;

    // Field ul_nprb_1.val @'h224[8:0]

    reg [8:0] ul_nprb_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_nprb_1_val_value <= 'h64;
        end else if (int_wr_en && ul_nprb_1_val_strb) begin
            ul_nprb_1_val_value <= int_wr_data[8:0];
        end
    end

    assign ul_nprb_1_val_out = ul_nprb_1_val_value;

    // Field ul_nprb_2.val @'h228[8:0]

    reg [8:0] ul_nprb_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_nprb_2_val_value <= 'h64;
        end else if (int_wr_en && ul_nprb_2_val_strb) begin
            ul_nprb_2_val_value <= int_wr_data[8:0];
        end
    end

    assign ul_nprb_2_val_out = ul_nprb_2_val_value;

    // Field ul_rfs_offset_0.val @'h230[22:0]

    reg [22:0] ul_rfs_offset_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_rfs_offset_0_val_value <= 'h0;
        end else if (int_wr_en && ul_rfs_offset_0_val_strb) begin
            ul_rfs_offset_0_val_value <= int_wr_data[22:0];
        end
    end

    assign ul_rfs_offset_0_val_out = ul_rfs_offset_0_val_value;

    // Field ul_rfs_offset_1.val @'h234[22:0]

    reg [22:0] ul_rfs_offset_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_rfs_offset_1_val_value <= 'h0;
        end else if (int_wr_en && ul_rfs_offset_1_val_strb) begin
            ul_rfs_offset_1_val_value <= int_wr_data[22:0];
        end
    end

    assign ul_rfs_offset_1_val_out = ul_rfs_offset_1_val_value;

    // Field ul_rfs_offset_2.val @'h238[22:0]

    reg [22:0] ul_rfs_offset_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_rfs_offset_2_val_value <= 'h0;
        end else if (int_wr_en && ul_rfs_offset_2_val_strb) begin
            ul_rfs_offset_2_val_value <= int_wr_data[22:0];
        end
    end

    assign ul_rfs_offset_2_val_out = ul_rfs_offset_2_val_value;

    // Field ul_ud.comp_meth @'h258[3:0]

    reg [3:0] ul_ud_comp_meth_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_ud_comp_meth_value <= 'h1;
        end else if (int_wr_en && ul_ud_comp_meth_strb) begin
            ul_ud_comp_meth_value <= int_wr_data[3:0];
        end
    end

    assign ul_ud_comp_meth_out = ul_ud_comp_meth_value;

    // Field ul_ud.iq_width @'h258[7:4]

    reg [3:0] ul_ud_iq_width_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_ud_iq_width_value <= 'h9;
        end else if (int_wr_en && ul_ud_iq_width_strb) begin
            ul_ud_iq_width_value <= int_wr_data[7:4];
        end
    end

    assign ul_ud_iq_width_out = ul_ud_iq_width_value;

    // Field ul_ud.fs_offset @'h258[11:8]

    reg [3:0] ul_ud_fs_offset_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_ud_fs_offset_value <= 'h0;
        end else if (int_wr_en && ul_ud_fs_offset_strb) begin
            ul_ud_fs_offset_value <= int_wr_data[11:8];
        end
    end

    assign ul_ud_fs_offset_out = ul_ud_fs_offset_value;

    // Field ul_gain_0_0.val @'h300[16:0]

    reg [16:0] ul_gain_0_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_gain_0_0_val_value <= 'h4000;
        end else if (int_wr_en && ul_gain_0_0_val_strb) begin
            ul_gain_0_0_val_value <= int_wr_data[16:0];
        end
    end

    assign ul_gain_0_0_val_out = ul_gain_0_0_val_value;

    // Field ul_gain_0_1.val @'h304[16:0]

    reg [16:0] ul_gain_0_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_gain_0_1_val_value <= 'h4000;
        end else if (int_wr_en && ul_gain_0_1_val_strb) begin
            ul_gain_0_1_val_value <= int_wr_data[16:0];
        end
    end

    assign ul_gain_0_1_val_out = ul_gain_0_1_val_value;

    // Field ul_gain_0_2.val @'h308[16:0]

    reg [16:0] ul_gain_0_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_gain_0_2_val_value <= 'h4000;
        end else if (int_wr_en && ul_gain_0_2_val_strb) begin
            ul_gain_0_2_val_value <= int_wr_data[16:0];
        end
    end

    assign ul_gain_0_2_val_out = ul_gain_0_2_val_value;

    // Field ul_gain_0_3.val @'h30c[16:0]

    reg [16:0] ul_gain_0_3_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_gain_0_3_val_value <= 'h4000;
        end else if (int_wr_en && ul_gain_0_3_val_strb) begin
            ul_gain_0_3_val_value <= int_wr_data[16:0];
        end
    end

    assign ul_gain_0_3_val_out = ul_gain_0_3_val_value;

    // Field ul_gain_1_0.val @'h310[16:0]

    reg [16:0] ul_gain_1_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_gain_1_0_val_value <= 'h4000;
        end else if (int_wr_en && ul_gain_1_0_val_strb) begin
            ul_gain_1_0_val_value <= int_wr_data[16:0];
        end
    end

    assign ul_gain_1_0_val_out = ul_gain_1_0_val_value;

    // Field ul_gain_1_1.val @'h314[16:0]

    reg [16:0] ul_gain_1_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_gain_1_1_val_value <= 'h4000;
        end else if (int_wr_en && ul_gain_1_1_val_strb) begin
            ul_gain_1_1_val_value <= int_wr_data[16:0];
        end
    end

    assign ul_gain_1_1_val_out = ul_gain_1_1_val_value;

    // Field ul_gain_1_2.val @'h318[16:0]

    reg [16:0] ul_gain_1_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_gain_1_2_val_value <= 'h4000;
        end else if (int_wr_en && ul_gain_1_2_val_strb) begin
            ul_gain_1_2_val_value <= int_wr_data[16:0];
        end
    end

    assign ul_gain_1_2_val_out = ul_gain_1_2_val_value;

    // Field ul_gain_1_3.val @'h31c[16:0]

    reg [16:0] ul_gain_1_3_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_gain_1_3_val_value <= 'h4000;
        end else if (int_wr_en && ul_gain_1_3_val_strb) begin
            ul_gain_1_3_val_value <= int_wr_data[16:0];
        end
    end

    assign ul_gain_1_3_val_out = ul_gain_1_3_val_value;

    // Field ul_gain_2_0.val @'h320[16:0]

    reg [16:0] ul_gain_2_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_gain_2_0_val_value <= 'h4000;
        end else if (int_wr_en && ul_gain_2_0_val_strb) begin
            ul_gain_2_0_val_value <= int_wr_data[16:0];
        end
    end

    assign ul_gain_2_0_val_out = ul_gain_2_0_val_value;

    // Field ul_gain_2_1.val @'h324[16:0]

    reg [16:0] ul_gain_2_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_gain_2_1_val_value <= 'h4000;
        end else if (int_wr_en && ul_gain_2_1_val_strb) begin
            ul_gain_2_1_val_value <= int_wr_data[16:0];
        end
    end

    assign ul_gain_2_1_val_out = ul_gain_2_1_val_value;

    // Field ul_gain_2_2.val @'h328[16:0]

    reg [16:0] ul_gain_2_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_gain_2_2_val_value <= 'h4000;
        end else if (int_wr_en && ul_gain_2_2_val_strb) begin
            ul_gain_2_2_val_value <= int_wr_data[16:0];
        end
    end

    assign ul_gain_2_2_val_out = ul_gain_2_2_val_value;

    // Field ul_gain_2_3.val @'h32c[16:0]

    reg [16:0] ul_gain_2_3_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ul_gain_2_3_val_value <= 'h4000;
        end else if (int_wr_en && ul_gain_2_3_val_strb) begin
            ul_gain_2_3_val_value <= int_wr_data[16:0];
        end
    end

    assign ul_gain_2_3_val_out = ul_gain_2_3_val_value;

    // Field prach_en.cc0 @'h410[3:0]

    reg [3:0] prach_en_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_en_cc0_value <= 'h0;
        end else if (int_wr_en && prach_en_cc0_strb) begin
            prach_en_cc0_value <= int_wr_data[3:0];
        end
    end

    assign prach_en_cc0_out = prach_en_cc0_value;

    // Field prach_en.cc1 @'h410[7:4]

    reg [3:0] prach_en_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_en_cc1_value <= 'h0;
        end else if (int_wr_en && prach_en_cc1_strb) begin
            prach_en_cc1_value <= int_wr_data[7:4];
        end
    end

    assign prach_en_cc1_out = prach_en_cc1_value;

    // Field prach_en.cc2 @'h410[11:8]

    reg [3:0] prach_en_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_en_cc2_value <= 'h0;
        end else if (int_wr_en && prach_en_cc2_strb) begin
            prach_en_cc2_value <= int_wr_data[11:8];
        end
    end

    assign prach_en_cc2_out = prach_en_cc2_value;

    // Field prach_format.cc0 @'h414[3:0]

    reg [3:0] prach_format_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_format_cc0_value <= 'h0;
        end else if (int_wr_en && prach_format_cc0_strb) begin
            prach_format_cc0_value <= int_wr_data[3:0];
        end
    end

    assign prach_format_cc0_out = prach_format_cc0_value;

    // Field prach_format.cc1 @'h414[7:4]

    reg [3:0] prach_format_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_format_cc1_value <= 'h0;
        end else if (int_wr_en && prach_format_cc1_strb) begin
            prach_format_cc1_value <= int_wr_data[7:4];
        end
    end

    assign prach_format_cc1_out = prach_format_cc1_value;

    // Field prach_format.cc2 @'h414[11:8]

    reg [3:0] prach_format_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_format_cc2_value <= 'h0;
        end else if (int_wr_en && prach_format_cc2_strb) begin
            prach_format_cc2_value <= int_wr_data[11:8];
        end
    end

    assign prach_format_cc2_out = prach_format_cc2_value;

    // Field prach_rat.cc0 @'h418[1:0]

    reg [1:0] prach_rat_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_rat_cc0_value <= 'h0;
        end else if (int_wr_en && prach_rat_cc0_strb) begin
            prach_rat_cc0_value <= int_wr_data[1:0];
        end
    end

    assign prach_rat_cc0_out = prach_rat_cc0_value;

    // Field prach_rat.cc1 @'h418[5:4]

    reg [1:0] prach_rat_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_rat_cc1_value <= 'h0;
        end else if (int_wr_en && prach_rat_cc1_strb) begin
            prach_rat_cc1_value <= int_wr_data[5:4];
        end
    end

    assign prach_rat_cc1_out = prach_rat_cc1_value;

    // Field prach_rat.cc2 @'h418[9:8]

    reg [1:0] prach_rat_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_rat_cc2_value <= 'h0;
        end else if (int_wr_en && prach_rat_cc2_strb) begin
            prach_rat_cc2_value <= int_wr_data[9:8];
        end
    end

    assign prach_rat_cc2_out = prach_rat_cc2_value;

    // Field prach_bist.bist_cc0 @'h41c[3:0]

    reg [3:0] prach_bist_bist_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_bist_bist_cc0_value <= 'h0;
        end else if (int_wr_en && prach_bist_bist_cc0_strb) begin
            prach_bist_bist_cc0_value <= int_wr_data[3:0];
        end
    end

    assign prach_bist_bist_cc0_out = prach_bist_bist_cc0_value;

    // Field prach_bist.bist_cc1 @'h41c[7:4]

    reg [3:0] prach_bist_bist_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_bist_bist_cc1_value <= 'h0;
        end else if (int_wr_en && prach_bist_bist_cc1_strb) begin
            prach_bist_bist_cc1_value <= int_wr_data[7:4];
        end
    end

    assign prach_bist_bist_cc1_out = prach_bist_bist_cc1_value;

    // Field prach_bist.bist_cc2 @'h41c[11:8]

    reg [3:0] prach_bist_bist_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_bist_bist_cc2_value <= 'h0;
        end else if (int_wr_en && prach_bist_bist_cc2_strb) begin
            prach_bist_bist_cc2_value <= int_wr_data[11:8];
        end
    end

    assign prach_bist_bist_cc2_out = prach_bist_bist_cc2_value;

    // Field prach_bist.static_c_cc0 @'h41c[19:16]

    reg [3:0] prach_bist_static_c_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_bist_static_c_cc0_value <= 'h0;
        end else if (int_wr_en && prach_bist_static_c_cc0_strb) begin
            prach_bist_static_c_cc0_value <= int_wr_data[19:16];
        end
    end

    assign prach_bist_static_c_cc0_out = prach_bist_static_c_cc0_value;

    // Field prach_bist.static_c_cc1 @'h41c[23:20]

    reg [3:0] prach_bist_static_c_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_bist_static_c_cc1_value <= 'h0;
        end else if (int_wr_en && prach_bist_static_c_cc1_strb) begin
            prach_bist_static_c_cc1_value <= int_wr_data[23:20];
        end
    end

    assign prach_bist_static_c_cc1_out = prach_bist_static_c_cc1_value;

    // Field prach_bist.static_c_cc2 @'h41c[27:24]

    reg [3:0] prach_bist_static_c_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_bist_static_c_cc2_value <= 'h0;
        end else if (int_wr_en && prach_bist_static_c_cc2_strb) begin
            prach_bist_static_c_cc2_value <= int_wr_data[27:24];
        end
    end

    assign prach_bist_static_c_cc2_out = prach_bist_static_c_cc2_value;

    // Field prach_bw.cc0 @'h420[3:0]

    reg [3:0] prach_bw_cc0_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_bw_cc0_value <= 'h2;
        end else if (int_wr_en && prach_bw_cc0_strb) begin
            prach_bw_cc0_value <= int_wr_data[3:0];
        end
    end

    assign prach_bw_cc0_out = prach_bw_cc0_value;

    // Field prach_bw.cc1 @'h420[7:4]

    reg [3:0] prach_bw_cc1_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_bw_cc1_value <= 'h2;
        end else if (int_wr_en && prach_bw_cc1_strb) begin
            prach_bw_cc1_value <= int_wr_data[7:4];
        end
    end

    assign prach_bw_cc1_out = prach_bw_cc1_value;

    // Field prach_bw.cc2 @'h420[11:8]

    reg [3:0] prach_bw_cc2_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_bw_cc2_value <= 'h2;
        end else if (int_wr_en && prach_bw_cc2_strb) begin
            prach_bw_cc2_value <= int_wr_data[11:8];
        end
    end

    assign prach_bw_cc2_out = prach_bw_cc2_value;

    // Field prach_rfs_offset_0.val @'h430[22:0]

    reg [22:0] prach_rfs_offset_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_rfs_offset_0_val_value <= 'h0;
        end else if (int_wr_en && prach_rfs_offset_0_val_strb) begin
            prach_rfs_offset_0_val_value <= int_wr_data[22:0];
        end
    end

    assign prach_rfs_offset_0_val_out = prach_rfs_offset_0_val_value;

    // Field prach_rfs_offset_1.val @'h434[22:0]

    reg [22:0] prach_rfs_offset_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_rfs_offset_1_val_value <= 'h0;
        end else if (int_wr_en && prach_rfs_offset_1_val_strb) begin
            prach_rfs_offset_1_val_value <= int_wr_data[22:0];
        end
    end

    assign prach_rfs_offset_1_val_out = prach_rfs_offset_1_val_value;

    // Field prach_rfs_offset_2.val @'h438[22:0]

    reg [22:0] prach_rfs_offset_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_rfs_offset_2_val_value <= 'h0;
        end else if (int_wr_en && prach_rfs_offset_2_val_strb) begin
            prach_rfs_offset_2_val_value <= int_wr_data[22:0];
        end
    end

    assign prach_rfs_offset_2_val_out = prach_rfs_offset_2_val_value;

    // Field prach_ta3_offset_0.val @'h440[22:0]

    reg [22:0] prach_ta3_offset_0_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_ta3_offset_0_val_value <= 'h0;
        end else if (int_wr_en && prach_ta3_offset_0_val_strb) begin
            prach_ta3_offset_0_val_value <= int_wr_data[22:0];
        end
    end

    assign prach_ta3_offset_0_val_out = prach_ta3_offset_0_val_value;

    // Field prach_ta3_offset_1.val @'h444[22:0]

    reg [22:0] prach_ta3_offset_1_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_ta3_offset_1_val_value <= 'h0;
        end else if (int_wr_en && prach_ta3_offset_1_val_strb) begin
            prach_ta3_offset_1_val_value <= int_wr_data[22:0];
        end
    end

    assign prach_ta3_offset_1_val_out = prach_ta3_offset_1_val_value;

    // Field prach_ta3_offset_2.val @'h448[22:0]

    reg [22:0] prach_ta3_offset_2_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_ta3_offset_2_val_value <= 'h0;
        end else if (int_wr_en && prach_ta3_offset_2_val_strb) begin
            prach_ta3_offset_2_val_value <= int_wr_data[22:0];
        end
    end

    assign prach_ta3_offset_2_val_out = prach_ta3_offset_2_val_value;

    // Field prach_ud.comp_meth @'h458[3:0]

    reg [3:0] prach_ud_comp_meth_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_ud_comp_meth_value <= 'h1;
        end else if (int_wr_en && prach_ud_comp_meth_strb) begin
            prach_ud_comp_meth_value <= int_wr_data[3:0];
        end
    end

    assign prach_ud_comp_meth_out = prach_ud_comp_meth_value;

    // Field prach_ud.iq_width @'h458[7:4]

    reg [3:0] prach_ud_iq_width_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_ud_iq_width_value <= 'h9;
        end else if (int_wr_en && prach_ud_iq_width_strb) begin
            prach_ud_iq_width_value <= int_wr_data[7:4];
        end
    end

    assign prach_ud_iq_width_out = prach_ud_iq_width_value;

    // Field prach_ud.fs_offset @'h458[11:8]

    reg [3:0] prach_ud_fs_offset_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_ud_fs_offset_value <= 'h0;
        end else if (int_wr_en && prach_ud_fs_offset_strb) begin
            prach_ud_fs_offset_value <= int_wr_data[11:8];
        end
    end

    assign prach_ud_fs_offset_out = prach_ud_fs_offset_value;

    // Field prach_cfg0_0.symbol_id @'h460[5:0]

    reg [5:0] prach_cfg0_0_symbol_id_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg0_0_symbol_id_value <= 'h0;
        end else if (int_wr_en && prach_cfg0_0_symbol_id_strb) begin
            prach_cfg0_0_symbol_id_value <= int_wr_data[5:0];
        end
    end

    assign prach_cfg0_0_symbol_id_out = prach_cfg0_0_symbol_id_value;

    // Field prach_cfg0_0.slot_id @'h460[13:8]

    reg [5:0] prach_cfg0_0_slot_id_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg0_0_slot_id_value <= 'h0;
        end else if (int_wr_en && prach_cfg0_0_slot_id_strb) begin
            prach_cfg0_0_slot_id_value <= int_wr_data[13:8];
        end
    end

    assign prach_cfg0_0_slot_id_out = prach_cfg0_0_slot_id_value;

    // Field prach_cfg0_0.subframe_id @'h460[19:16]

    reg [3:0] prach_cfg0_0_subframe_id_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg0_0_subframe_id_value <= 'h0;
        end else if (int_wr_en && prach_cfg0_0_subframe_id_strb) begin
            prach_cfg0_0_subframe_id_value <= int_wr_data[19:16];
        end
    end

    assign prach_cfg0_0_subframe_id_out = prach_cfg0_0_subframe_id_value;

    // Field prach_cfg0_0.subframe_inc @'h460[23:20]

    reg [3:0] prach_cfg0_0_subframe_inc_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg0_0_subframe_inc_value <= 'h0;
        end else if (int_wr_en && prach_cfg0_0_subframe_inc_strb) begin
            prach_cfg0_0_subframe_inc_value <= int_wr_data[23:20];
        end
    end

    assign prach_cfg0_0_subframe_inc_out = prach_cfg0_0_subframe_inc_value;

    // Field prach_cfg0_1.symbol_id @'h464[5:0]

    reg [5:0] prach_cfg0_1_symbol_id_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg0_1_symbol_id_value <= 'h0;
        end else if (int_wr_en && prach_cfg0_1_symbol_id_strb) begin
            prach_cfg0_1_symbol_id_value <= int_wr_data[5:0];
        end
    end

    assign prach_cfg0_1_symbol_id_out = prach_cfg0_1_symbol_id_value;

    // Field prach_cfg0_1.slot_id @'h464[13:8]

    reg [5:0] prach_cfg0_1_slot_id_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg0_1_slot_id_value <= 'h0;
        end else if (int_wr_en && prach_cfg0_1_slot_id_strb) begin
            prach_cfg0_1_slot_id_value <= int_wr_data[13:8];
        end
    end

    assign prach_cfg0_1_slot_id_out = prach_cfg0_1_slot_id_value;

    // Field prach_cfg0_1.subframe_id @'h464[19:16]

    reg [3:0] prach_cfg0_1_subframe_id_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg0_1_subframe_id_value <= 'h0;
        end else if (int_wr_en && prach_cfg0_1_subframe_id_strb) begin
            prach_cfg0_1_subframe_id_value <= int_wr_data[19:16];
        end
    end

    assign prach_cfg0_1_subframe_id_out = prach_cfg0_1_subframe_id_value;

    // Field prach_cfg0_1.subframe_inc @'h464[23:20]

    reg [3:0] prach_cfg0_1_subframe_inc_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg0_1_subframe_inc_value <= 'h0;
        end else if (int_wr_en && prach_cfg0_1_subframe_inc_strb) begin
            prach_cfg0_1_subframe_inc_value <= int_wr_data[23:20];
        end
    end

    assign prach_cfg0_1_subframe_inc_out = prach_cfg0_1_subframe_inc_value;

    // Field prach_cfg0_2.symbol_id @'h468[5:0]

    reg [5:0] prach_cfg0_2_symbol_id_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg0_2_symbol_id_value <= 'h0;
        end else if (int_wr_en && prach_cfg0_2_symbol_id_strb) begin
            prach_cfg0_2_symbol_id_value <= int_wr_data[5:0];
        end
    end

    assign prach_cfg0_2_symbol_id_out = prach_cfg0_2_symbol_id_value;

    // Field prach_cfg0_2.slot_id @'h468[13:8]

    reg [5:0] prach_cfg0_2_slot_id_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg0_2_slot_id_value <= 'h0;
        end else if (int_wr_en && prach_cfg0_2_slot_id_strb) begin
            prach_cfg0_2_slot_id_value <= int_wr_data[13:8];
        end
    end

    assign prach_cfg0_2_slot_id_out = prach_cfg0_2_slot_id_value;

    // Field prach_cfg0_2.subframe_id @'h468[19:16]

    reg [3:0] prach_cfg0_2_subframe_id_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg0_2_subframe_id_value <= 'h0;
        end else if (int_wr_en && prach_cfg0_2_subframe_id_strb) begin
            prach_cfg0_2_subframe_id_value <= int_wr_data[19:16];
        end
    end

    assign prach_cfg0_2_subframe_id_out = prach_cfg0_2_subframe_id_value;

    // Field prach_cfg0_2.subframe_inc @'h468[23:20]

    reg [3:0] prach_cfg0_2_subframe_inc_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg0_2_subframe_inc_value <= 'h0;
        end else if (int_wr_en && prach_cfg0_2_subframe_inc_strb) begin
            prach_cfg0_2_subframe_inc_value <= int_wr_data[23:20];
        end
    end

    assign prach_cfg0_2_subframe_inc_out = prach_cfg0_2_subframe_inc_value;

    // Field prach_cfg1_0.time_offset @'h470[15:0]

    reg [15:0] prach_cfg1_0_time_offset_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg1_0_time_offset_value <= 'h0;
        end else if (int_wr_en && prach_cfg1_0_time_offset_strb) begin
            prach_cfg1_0_time_offset_value <= int_wr_data[15:0];
        end
    end

    assign prach_cfg1_0_time_offset_out = prach_cfg1_0_time_offset_value;

    // Field prach_cfg1_0.cp_length @'h470[31:16]

    reg [15:0] prach_cfg1_0_cp_length_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg1_0_cp_length_value <= 'h0;
        end else if (int_wr_en && prach_cfg1_0_cp_length_strb) begin
            prach_cfg1_0_cp_length_value <= int_wr_data[31:16];
        end
    end

    assign prach_cfg1_0_cp_length_out = prach_cfg1_0_cp_length_value;

    // Field prach_cfg1_1.time_offset @'h474[15:0]

    reg [15:0] prach_cfg1_1_time_offset_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg1_1_time_offset_value <= 'h0;
        end else if (int_wr_en && prach_cfg1_1_time_offset_strb) begin
            prach_cfg1_1_time_offset_value <= int_wr_data[15:0];
        end
    end

    assign prach_cfg1_1_time_offset_out = prach_cfg1_1_time_offset_value;

    // Field prach_cfg1_1.cp_length @'h474[31:16]

    reg [15:0] prach_cfg1_1_cp_length_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg1_1_cp_length_value <= 'h0;
        end else if (int_wr_en && prach_cfg1_1_cp_length_strb) begin
            prach_cfg1_1_cp_length_value <= int_wr_data[31:16];
        end
    end

    assign prach_cfg1_1_cp_length_out = prach_cfg1_1_cp_length_value;

    // Field prach_cfg1_2.time_offset @'h478[15:0]

    reg [15:0] prach_cfg1_2_time_offset_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg1_2_time_offset_value <= 'h0;
        end else if (int_wr_en && prach_cfg1_2_time_offset_strb) begin
            prach_cfg1_2_time_offset_value <= int_wr_data[15:0];
        end
    end

    assign prach_cfg1_2_time_offset_out = prach_cfg1_2_time_offset_value;

    // Field prach_cfg1_2.cp_length @'h478[31:16]

    reg [15:0] prach_cfg1_2_cp_length_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg1_2_cp_length_value <= 'h0;
        end else if (int_wr_en && prach_cfg1_2_cp_length_strb) begin
            prach_cfg1_2_cp_length_value <= int_wr_data[31:16];
        end
    end

    assign prach_cfg1_2_cp_length_out = prach_cfg1_2_cp_length_value;

    // Field prach_cfg2_0.num_symbol @'h480[3:0]

    reg [3:0] prach_cfg2_0_num_symbol_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg2_0_num_symbol_value <= 'h0;
        end else if (int_wr_en && prach_cfg2_0_num_symbol_strb) begin
            prach_cfg2_0_num_symbol_value <= int_wr_data[3:0];
        end
    end

    assign prach_cfg2_0_num_symbol_out = prach_cfg2_0_num_symbol_value;

    // Field prach_cfg2_0.freq_offset @'h480[27:4]

    reg [23:0] prach_cfg2_0_freq_offset_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg2_0_freq_offset_value <= 'h0;
        end else if (int_wr_en && prach_cfg2_0_freq_offset_strb) begin
            prach_cfg2_0_freq_offset_value <= int_wr_data[27:4];
        end
    end

    assign prach_cfg2_0_freq_offset_out = prach_cfg2_0_freq_offset_value;

    // Field prach_cfg2_1.num_symbol @'h484[3:0]

    reg [3:0] prach_cfg2_1_num_symbol_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg2_1_num_symbol_value <= 'h0;
        end else if (int_wr_en && prach_cfg2_1_num_symbol_strb) begin
            prach_cfg2_1_num_symbol_value <= int_wr_data[3:0];
        end
    end

    assign prach_cfg2_1_num_symbol_out = prach_cfg2_1_num_symbol_value;

    // Field prach_cfg2_1.freq_offset @'h484[27:4]

    reg [23:0] prach_cfg2_1_freq_offset_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg2_1_freq_offset_value <= 'h0;
        end else if (int_wr_en && prach_cfg2_1_freq_offset_strb) begin
            prach_cfg2_1_freq_offset_value <= int_wr_data[27:4];
        end
    end

    assign prach_cfg2_1_freq_offset_out = prach_cfg2_1_freq_offset_value;

    // Field prach_cfg2_2.num_symbol @'h488[3:0]

    reg [3:0] prach_cfg2_2_num_symbol_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg2_2_num_symbol_value <= 'h0;
        end else if (int_wr_en && prach_cfg2_2_num_symbol_strb) begin
            prach_cfg2_2_num_symbol_value <= int_wr_data[3:0];
        end
    end

    assign prach_cfg2_2_num_symbol_out = prach_cfg2_2_num_symbol_value;

    // Field prach_cfg2_2.freq_offset @'h488[27:4]

    reg [23:0] prach_cfg2_2_freq_offset_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg2_2_freq_offset_value <= 'h0;
        end else if (int_wr_en && prach_cfg2_2_freq_offset_strb) begin
            prach_cfg2_2_freq_offset_value <= int_wr_data[27:4];
        end
    end

    assign prach_cfg2_2_freq_offset_out = prach_cfg2_2_freq_offset_value;

    // Field prach_cfg3_0.sampling_offset @'h490[15:0]

    reg [15:0] prach_cfg3_0_sampling_offset_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg3_0_sampling_offset_value <= 'h0;
        end else if (int_wr_en && prach_cfg3_0_sampling_offset_strb) begin
            prach_cfg3_0_sampling_offset_value <= int_wr_data[15:0];
        end
    end

    assign prach_cfg3_0_sampling_offset_out = prach_cfg3_0_sampling_offset_value;

    // Field prach_cfg3_1.sampling_offset @'h494[15:0]

    reg [15:0] prach_cfg3_1_sampling_offset_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg3_1_sampling_offset_value <= 'h0;
        end else if (int_wr_en && prach_cfg3_1_sampling_offset_strb) begin
            prach_cfg3_1_sampling_offset_value <= int_wr_data[15:0];
        end
    end

    assign prach_cfg3_1_sampling_offset_out = prach_cfg3_1_sampling_offset_value;

    // Field prach_cfg3_2.sampling_offset @'h498[15:0]

    reg [15:0] prach_cfg3_2_sampling_offset_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            prach_cfg3_2_sampling_offset_value <= 'h0;
        end else if (int_wr_en && prach_cfg3_2_sampling_offset_strb) begin
            prach_cfg3_2_sampling_offset_value <= int_wr_data[15:0];
        end
    end

    assign prach_cfg3_2_sampling_offset_out = prach_cfg3_2_sampling_offset_value;

    // Field prach_msg0_0.symbol_id @'h500[5:0]

    reg [5:0] prach_msg0_0_symbol_id_value;

    always @(*) begin
        prach_msg0_0_symbol_id_value = prach_msg0_0_symbol_id_in;
    end

    // Field prach_msg0_0.slot_id @'h500[13:8]

    reg [5:0] prach_msg0_0_slot_id_value;

    always @(*) begin
        prach_msg0_0_slot_id_value = prach_msg0_0_slot_id_in;
    end

    // Field prach_msg0_0.subframe_id @'h500[19:16]

    reg [3:0] prach_msg0_0_subframe_id_value;

    always @(*) begin
        prach_msg0_0_subframe_id_value = prach_msg0_0_subframe_id_in;
    end

    // Field prach_msg0_1.symbol_id @'h504[5:0]

    reg [5:0] prach_msg0_1_symbol_id_value;

    always @(*) begin
        prach_msg0_1_symbol_id_value = prach_msg0_1_symbol_id_in;
    end

    // Field prach_msg0_1.slot_id @'h504[13:8]

    reg [5:0] prach_msg0_1_slot_id_value;

    always @(*) begin
        prach_msg0_1_slot_id_value = prach_msg0_1_slot_id_in;
    end

    // Field prach_msg0_1.subframe_id @'h504[19:16]

    reg [3:0] prach_msg0_1_subframe_id_value;

    always @(*) begin
        prach_msg0_1_subframe_id_value = prach_msg0_1_subframe_id_in;
    end

    // Field prach_msg0_2.symbol_id @'h508[5:0]

    reg [5:0] prach_msg0_2_symbol_id_value;

    always @(*) begin
        prach_msg0_2_symbol_id_value = prach_msg0_2_symbol_id_in;
    end

    // Field prach_msg0_2.slot_id @'h508[13:8]

    reg [5:0] prach_msg0_2_slot_id_value;

    always @(*) begin
        prach_msg0_2_slot_id_value = prach_msg0_2_slot_id_in;
    end

    // Field prach_msg0_2.subframe_id @'h508[19:16]

    reg [3:0] prach_msg0_2_subframe_id_value;

    always @(*) begin
        prach_msg0_2_subframe_id_value = prach_msg0_2_subframe_id_in;
    end

    // Field prach_msg1_0.time_offset @'h510[15:0]

    reg [15:0] prach_msg1_0_time_offset_value;

    always @(*) begin
        prach_msg1_0_time_offset_value = prach_msg1_0_time_offset_in;
    end

    // Field prach_msg1_0.cp_length @'h510[31:16]

    reg [15:0] prach_msg1_0_cp_length_value;

    always @(*) begin
        prach_msg1_0_cp_length_value = prach_msg1_0_cp_length_in;
    end

    // Field prach_msg1_1.time_offset @'h514[15:0]

    reg [15:0] prach_msg1_1_time_offset_value;

    always @(*) begin
        prach_msg1_1_time_offset_value = prach_msg1_1_time_offset_in;
    end

    // Field prach_msg1_1.cp_length @'h514[31:16]

    reg [15:0] prach_msg1_1_cp_length_value;

    always @(*) begin
        prach_msg1_1_cp_length_value = prach_msg1_1_cp_length_in;
    end

    // Field prach_msg1_2.time_offset @'h518[15:0]

    reg [15:0] prach_msg1_2_time_offset_value;

    always @(*) begin
        prach_msg1_2_time_offset_value = prach_msg1_2_time_offset_in;
    end

    // Field prach_msg1_2.cp_length @'h518[31:16]

    reg [15:0] prach_msg1_2_cp_length_value;

    always @(*) begin
        prach_msg1_2_cp_length_value = prach_msg1_2_cp_length_in;
    end

    // Field prach_msg2_0.num_symbol @'h520[3:0]

    reg [3:0] prach_msg2_0_num_symbol_value;

    always @(*) begin
        prach_msg2_0_num_symbol_value = prach_msg2_0_num_symbol_in;
    end

    // Field prach_msg2_0.freq_offset @'h520[27:4]

    reg [23:0] prach_msg2_0_freq_offset_value;

    always @(*) begin
        prach_msg2_0_freq_offset_value = prach_msg2_0_freq_offset_in;
    end

    // Field prach_msg2_1.num_symbol @'h524[3:0]

    reg [3:0] prach_msg2_1_num_symbol_value;

    always @(*) begin
        prach_msg2_1_num_symbol_value = prach_msg2_1_num_symbol_in;
    end

    // Field prach_msg2_1.freq_offset @'h524[27:4]

    reg [23:0] prach_msg2_1_freq_offset_value;

    always @(*) begin
        prach_msg2_1_freq_offset_value = prach_msg2_1_freq_offset_in;
    end

    // Field prach_msg2_2.num_symbol @'h528[3:0]

    reg [3:0] prach_msg2_2_num_symbol_value;

    always @(*) begin
        prach_msg2_2_num_symbol_value = prach_msg2_2_num_symbol_in;
    end

    // Field prach_msg2_2.freq_offset @'h528[27:4]

    reg [23:0] prach_msg2_2_freq_offset_value;

    always @(*) begin
        prach_msg2_2_freq_offset_value = prach_msg2_2_freq_offset_in;
    end


    //--------------------------------------------------------------------------
    // Memory logic
    //--------------------------------------------------------------------------

    // Memory dl_phase_comp @'h800

    assign dl_phase_comp_addr = int_addr[7:2];
    assign dl_phase_comp_en   = ((int_wr_en || int_rd_en) && dl_phase_comp_strb);
    assign dl_phase_comp_we   = (int_wr_en && dl_phase_comp_strb);
    assign dl_phase_comp_din  = int_wr_data[31:0];

    // Memory ul_phase_comp @'ha00

    assign ul_phase_comp_addr = int_addr[7:2];
    assign ul_phase_comp_en   = ((int_wr_en || int_rd_en) && ul_phase_comp_strb);
    assign ul_phase_comp_we   = (int_wr_en && ul_phase_comp_strb);
    assign ul_phase_comp_din  = int_wr_data[31:0];


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
            field_rd_data_next[1:0] = field_rd_data_next[1:0] | dl_rat_cc0_value;
        end
        if (int_rd_en && dl_rat_cc1_strb) begin
            field_rd_data_next[5:4] = field_rd_data_next[5:4] | dl_rat_cc1_value;
        end
        if (int_rd_en && dl_rat_cc2_strb) begin
            field_rd_data_next[9:8] = field_rd_data_next[9:8] | dl_rat_cc2_value;
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
        if (int_rd_en && ul_en_cc0_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | ul_en_cc0_value;
        end
        if (int_rd_en && ul_en_cc1_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | ul_en_cc1_value;
        end
        if (int_rd_en && ul_en_cc2_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | ul_en_cc2_value;
        end
        if (int_rd_en && ul_rat_cc0_strb) begin
            field_rd_data_next[1:0] = field_rd_data_next[1:0] | ul_rat_cc0_value;
        end
        if (int_rd_en && ul_rat_cc1_strb) begin
            field_rd_data_next[5:4] = field_rd_data_next[5:4] | ul_rat_cc1_value;
        end
        if (int_rd_en && ul_rat_cc2_strb) begin
            field_rd_data_next[9:8] = field_rd_data_next[9:8] | ul_rat_cc2_value;
        end
        if (int_rd_en && ul_bist_bist_cc0_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | ul_bist_bist_cc0_value;
        end
        if (int_rd_en && ul_bist_bist_cc1_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | ul_bist_bist_cc1_value;
        end
        if (int_rd_en && ul_bist_bist_cc2_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | ul_bist_bist_cc2_value;
        end
        if (int_rd_en && ul_bw_cc0_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | ul_bw_cc0_value;
        end
        if (int_rd_en && ul_bw_cc1_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | ul_bw_cc1_value;
        end
        if (int_rd_en && ul_bw_cc2_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | ul_bw_cc2_value;
        end
        if (int_rd_en && ul_nprb_0_val_strb) begin
            field_rd_data_next[8:0] = field_rd_data_next[8:0] | ul_nprb_0_val_value;
        end
        if (int_rd_en && ul_nprb_1_val_strb) begin
            field_rd_data_next[8:0] = field_rd_data_next[8:0] | ul_nprb_1_val_value;
        end
        if (int_rd_en && ul_nprb_2_val_strb) begin
            field_rd_data_next[8:0] = field_rd_data_next[8:0] | ul_nprb_2_val_value;
        end
        if (int_rd_en && ul_rfs_offset_0_val_strb) begin
            field_rd_data_next[22:0] = field_rd_data_next[22:0] | ul_rfs_offset_0_val_value;
        end
        if (int_rd_en && ul_rfs_offset_1_val_strb) begin
            field_rd_data_next[22:0] = field_rd_data_next[22:0] | ul_rfs_offset_1_val_value;
        end
        if (int_rd_en && ul_rfs_offset_2_val_strb) begin
            field_rd_data_next[22:0] = field_rd_data_next[22:0] | ul_rfs_offset_2_val_value;
        end
        if (int_rd_en && ul_ud_comp_meth_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | ul_ud_comp_meth_value;
        end
        if (int_rd_en && ul_ud_iq_width_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | ul_ud_iq_width_value;
        end
        if (int_rd_en && ul_ud_fs_offset_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | ul_ud_fs_offset_value;
        end
        if (int_rd_en && ul_gain_0_0_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | ul_gain_0_0_val_value;
        end
        if (int_rd_en && ul_gain_0_1_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | ul_gain_0_1_val_value;
        end
        if (int_rd_en && ul_gain_0_2_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | ul_gain_0_2_val_value;
        end
        if (int_rd_en && ul_gain_0_3_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | ul_gain_0_3_val_value;
        end
        if (int_rd_en && ul_gain_1_0_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | ul_gain_1_0_val_value;
        end
        if (int_rd_en && ul_gain_1_1_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | ul_gain_1_1_val_value;
        end
        if (int_rd_en && ul_gain_1_2_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | ul_gain_1_2_val_value;
        end
        if (int_rd_en && ul_gain_1_3_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | ul_gain_1_3_val_value;
        end
        if (int_rd_en && ul_gain_2_0_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | ul_gain_2_0_val_value;
        end
        if (int_rd_en && ul_gain_2_1_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | ul_gain_2_1_val_value;
        end
        if (int_rd_en && ul_gain_2_2_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | ul_gain_2_2_val_value;
        end
        if (int_rd_en && ul_gain_2_3_val_strb) begin
            field_rd_data_next[16:0] = field_rd_data_next[16:0] | ul_gain_2_3_val_value;
        end
        if (int_rd_en && prach_en_cc0_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | prach_en_cc0_value;
        end
        if (int_rd_en && prach_en_cc1_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | prach_en_cc1_value;
        end
        if (int_rd_en && prach_en_cc2_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | prach_en_cc2_value;
        end
        if (int_rd_en && prach_format_cc0_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | prach_format_cc0_value;
        end
        if (int_rd_en && prach_format_cc1_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | prach_format_cc1_value;
        end
        if (int_rd_en && prach_format_cc2_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | prach_format_cc2_value;
        end
        if (int_rd_en && prach_rat_cc0_strb) begin
            field_rd_data_next[1:0] = field_rd_data_next[1:0] | prach_rat_cc0_value;
        end
        if (int_rd_en && prach_rat_cc1_strb) begin
            field_rd_data_next[5:4] = field_rd_data_next[5:4] | prach_rat_cc1_value;
        end
        if (int_rd_en && prach_rat_cc2_strb) begin
            field_rd_data_next[9:8] = field_rd_data_next[9:8] | prach_rat_cc2_value;
        end
        if (int_rd_en && prach_bist_bist_cc0_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | prach_bist_bist_cc0_value;
        end
        if (int_rd_en && prach_bist_bist_cc1_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | prach_bist_bist_cc1_value;
        end
        if (int_rd_en && prach_bist_bist_cc2_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | prach_bist_bist_cc2_value;
        end
        if (int_rd_en && prach_bist_static_c_cc0_strb) begin
            field_rd_data_next[19:16] = field_rd_data_next[19:16] | prach_bist_static_c_cc0_value;
        end
        if (int_rd_en && prach_bist_static_c_cc1_strb) begin
            field_rd_data_next[23:20] = field_rd_data_next[23:20] | prach_bist_static_c_cc1_value;
        end
        if (int_rd_en && prach_bist_static_c_cc2_strb) begin
            field_rd_data_next[27:24] = field_rd_data_next[27:24] | prach_bist_static_c_cc2_value;
        end
        if (int_rd_en && prach_bw_cc0_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | prach_bw_cc0_value;
        end
        if (int_rd_en && prach_bw_cc1_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | prach_bw_cc1_value;
        end
        if (int_rd_en && prach_bw_cc2_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | prach_bw_cc2_value;
        end
        if (int_rd_en && prach_rfs_offset_0_val_strb) begin
            field_rd_data_next[22:0] = field_rd_data_next[22:0] | prach_rfs_offset_0_val_value;
        end
        if (int_rd_en && prach_rfs_offset_1_val_strb) begin
            field_rd_data_next[22:0] = field_rd_data_next[22:0] | prach_rfs_offset_1_val_value;
        end
        if (int_rd_en && prach_rfs_offset_2_val_strb) begin
            field_rd_data_next[22:0] = field_rd_data_next[22:0] | prach_rfs_offset_2_val_value;
        end
        if (int_rd_en && prach_ta3_offset_0_val_strb) begin
            field_rd_data_next[22:0] = field_rd_data_next[22:0] | prach_ta3_offset_0_val_value;
        end
        if (int_rd_en && prach_ta3_offset_1_val_strb) begin
            field_rd_data_next[22:0] = field_rd_data_next[22:0] | prach_ta3_offset_1_val_value;
        end
        if (int_rd_en && prach_ta3_offset_2_val_strb) begin
            field_rd_data_next[22:0] = field_rd_data_next[22:0] | prach_ta3_offset_2_val_value;
        end
        if (int_rd_en && prach_ud_comp_meth_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | prach_ud_comp_meth_value;
        end
        if (int_rd_en && prach_ud_iq_width_strb) begin
            field_rd_data_next[7:4] = field_rd_data_next[7:4] | prach_ud_iq_width_value;
        end
        if (int_rd_en && prach_ud_fs_offset_strb) begin
            field_rd_data_next[11:8] = field_rd_data_next[11:8] | prach_ud_fs_offset_value;
        end
        if (int_rd_en && prach_cfg0_0_symbol_id_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | prach_cfg0_0_symbol_id_value;
        end
        if (int_rd_en && prach_cfg0_0_slot_id_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | prach_cfg0_0_slot_id_value;
        end
        if (int_rd_en && prach_cfg0_0_subframe_id_strb) begin
            field_rd_data_next[19:16] = field_rd_data_next[19:16] | prach_cfg0_0_subframe_id_value;
        end
        if (int_rd_en && prach_cfg0_0_subframe_inc_strb) begin
            field_rd_data_next[23:20] = field_rd_data_next[23:20] | prach_cfg0_0_subframe_inc_value;
        end
        if (int_rd_en && prach_cfg0_1_symbol_id_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | prach_cfg0_1_symbol_id_value;
        end
        if (int_rd_en && prach_cfg0_1_slot_id_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | prach_cfg0_1_slot_id_value;
        end
        if (int_rd_en && prach_cfg0_1_subframe_id_strb) begin
            field_rd_data_next[19:16] = field_rd_data_next[19:16] | prach_cfg0_1_subframe_id_value;
        end
        if (int_rd_en && prach_cfg0_1_subframe_inc_strb) begin
            field_rd_data_next[23:20] = field_rd_data_next[23:20] | prach_cfg0_1_subframe_inc_value;
        end
        if (int_rd_en && prach_cfg0_2_symbol_id_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | prach_cfg0_2_symbol_id_value;
        end
        if (int_rd_en && prach_cfg0_2_slot_id_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | prach_cfg0_2_slot_id_value;
        end
        if (int_rd_en && prach_cfg0_2_subframe_id_strb) begin
            field_rd_data_next[19:16] = field_rd_data_next[19:16] | prach_cfg0_2_subframe_id_value;
        end
        if (int_rd_en && prach_cfg0_2_subframe_inc_strb) begin
            field_rd_data_next[23:20] = field_rd_data_next[23:20] | prach_cfg0_2_subframe_inc_value;
        end
        if (int_rd_en && prach_cfg1_0_time_offset_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | prach_cfg1_0_time_offset_value;
        end
        if (int_rd_en && prach_cfg1_0_cp_length_strb) begin
            field_rd_data_next[31:16] = field_rd_data_next[31:16] | prach_cfg1_0_cp_length_value;
        end
        if (int_rd_en && prach_cfg1_1_time_offset_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | prach_cfg1_1_time_offset_value;
        end
        if (int_rd_en && prach_cfg1_1_cp_length_strb) begin
            field_rd_data_next[31:16] = field_rd_data_next[31:16] | prach_cfg1_1_cp_length_value;
        end
        if (int_rd_en && prach_cfg1_2_time_offset_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | prach_cfg1_2_time_offset_value;
        end
        if (int_rd_en && prach_cfg1_2_cp_length_strb) begin
            field_rd_data_next[31:16] = field_rd_data_next[31:16] | prach_cfg1_2_cp_length_value;
        end
        if (int_rd_en && prach_cfg2_0_num_symbol_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | prach_cfg2_0_num_symbol_value;
        end
        if (int_rd_en && prach_cfg2_0_freq_offset_strb) begin
            field_rd_data_next[27:4] = field_rd_data_next[27:4] | prach_cfg2_0_freq_offset_value;
        end
        if (int_rd_en && prach_cfg2_1_num_symbol_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | prach_cfg2_1_num_symbol_value;
        end
        if (int_rd_en && prach_cfg2_1_freq_offset_strb) begin
            field_rd_data_next[27:4] = field_rd_data_next[27:4] | prach_cfg2_1_freq_offset_value;
        end
        if (int_rd_en && prach_cfg2_2_num_symbol_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | prach_cfg2_2_num_symbol_value;
        end
        if (int_rd_en && prach_cfg2_2_freq_offset_strb) begin
            field_rd_data_next[27:4] = field_rd_data_next[27:4] | prach_cfg2_2_freq_offset_value;
        end
        if (int_rd_en && prach_cfg3_0_sampling_offset_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | prach_cfg3_0_sampling_offset_value;
        end
        if (int_rd_en && prach_cfg3_1_sampling_offset_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | prach_cfg3_1_sampling_offset_value;
        end
        if (int_rd_en && prach_cfg3_2_sampling_offset_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | prach_cfg3_2_sampling_offset_value;
        end
        if (int_rd_en && prach_msg0_0_symbol_id_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | prach_msg0_0_symbol_id_value;
        end
        if (int_rd_en && prach_msg0_0_slot_id_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | prach_msg0_0_slot_id_value;
        end
        if (int_rd_en && prach_msg0_0_subframe_id_strb) begin
            field_rd_data_next[19:16] = field_rd_data_next[19:16] | prach_msg0_0_subframe_id_value;
        end
        if (int_rd_en && prach_msg0_1_symbol_id_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | prach_msg0_1_symbol_id_value;
        end
        if (int_rd_en && prach_msg0_1_slot_id_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | prach_msg0_1_slot_id_value;
        end
        if (int_rd_en && prach_msg0_1_subframe_id_strb) begin
            field_rd_data_next[19:16] = field_rd_data_next[19:16] | prach_msg0_1_subframe_id_value;
        end
        if (int_rd_en && prach_msg0_2_symbol_id_strb) begin
            field_rd_data_next[5:0] = field_rd_data_next[5:0] | prach_msg0_2_symbol_id_value;
        end
        if (int_rd_en && prach_msg0_2_slot_id_strb) begin
            field_rd_data_next[13:8] = field_rd_data_next[13:8] | prach_msg0_2_slot_id_value;
        end
        if (int_rd_en && prach_msg0_2_subframe_id_strb) begin
            field_rd_data_next[19:16] = field_rd_data_next[19:16] | prach_msg0_2_subframe_id_value;
        end
        if (int_rd_en && prach_msg1_0_time_offset_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | prach_msg1_0_time_offset_value;
        end
        if (int_rd_en && prach_msg1_0_cp_length_strb) begin
            field_rd_data_next[31:16] = field_rd_data_next[31:16] | prach_msg1_0_cp_length_value;
        end
        if (int_rd_en && prach_msg1_1_time_offset_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | prach_msg1_1_time_offset_value;
        end
        if (int_rd_en && prach_msg1_1_cp_length_strb) begin
            field_rd_data_next[31:16] = field_rd_data_next[31:16] | prach_msg1_1_cp_length_value;
        end
        if (int_rd_en && prach_msg1_2_time_offset_strb) begin
            field_rd_data_next[15:0] = field_rd_data_next[15:0] | prach_msg1_2_time_offset_value;
        end
        if (int_rd_en && prach_msg1_2_cp_length_strb) begin
            field_rd_data_next[31:16] = field_rd_data_next[31:16] | prach_msg1_2_cp_length_value;
        end
        if (int_rd_en && prach_msg2_0_num_symbol_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | prach_msg2_0_num_symbol_value;
        end
        if (int_rd_en && prach_msg2_0_freq_offset_strb) begin
            field_rd_data_next[27:4] = field_rd_data_next[27:4] | prach_msg2_0_freq_offset_value;
        end
        if (int_rd_en && prach_msg2_1_num_symbol_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | prach_msg2_1_num_symbol_value;
        end
        if (int_rd_en && prach_msg2_1_freq_offset_strb) begin
            field_rd_data_next[27:4] = field_rd_data_next[27:4] | prach_msg2_1_freq_offset_value;
        end
        if (int_rd_en && prach_msg2_2_num_symbol_strb) begin
            field_rd_data_next[3:0] = field_rd_data_next[3:0] | prach_msg2_2_num_symbol_value;
        end
        if (int_rd_en && prach_msg2_2_freq_offset_strb) begin
            field_rd_data_next[27:4] = field_rd_data_next[27:4] | prach_msg2_2_freq_offset_value;
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
        if (int_rd_en && ul_en_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_en_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_en_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_rat_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_rat_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_rat_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_bist_bist_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_bist_bist_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_bist_bist_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_bw_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_bw_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_bw_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_nprb_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_nprb_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_nprb_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_rfs_offset_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_rfs_offset_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_rfs_offset_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_ud_comp_meth_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_ud_iq_width_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_ud_fs_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_gain_0_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_gain_0_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_gain_0_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_gain_0_3_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_gain_1_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_gain_1_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_gain_1_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_gain_1_3_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_gain_2_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_gain_2_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_gain_2_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ul_gain_2_3_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_en_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_en_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_en_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_format_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_format_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_format_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_rat_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_rat_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_rat_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_bist_bist_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_bist_bist_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_bist_bist_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_bist_static_c_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_bist_static_c_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_bist_static_c_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_bw_cc0_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_bw_cc1_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_bw_cc2_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_rfs_offset_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_rfs_offset_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_rfs_offset_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_ta3_offset_0_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_ta3_offset_1_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_ta3_offset_2_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_ud_comp_meth_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_ud_iq_width_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_ud_fs_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg0_0_symbol_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg0_0_slot_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg0_0_subframe_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg0_0_subframe_inc_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg0_1_symbol_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg0_1_slot_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg0_1_subframe_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg0_1_subframe_inc_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg0_2_symbol_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg0_2_slot_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg0_2_subframe_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg0_2_subframe_inc_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg1_0_time_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg1_0_cp_length_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg1_1_time_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg1_1_cp_length_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg1_2_time_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg1_2_cp_length_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg2_0_num_symbol_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg2_0_freq_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg2_1_num_symbol_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg2_1_freq_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg2_2_num_symbol_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg2_2_freq_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg3_0_sampling_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg3_1_sampling_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_cfg3_2_sampling_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg0_0_symbol_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg0_0_slot_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg0_0_subframe_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg0_1_symbol_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg0_1_slot_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg0_1_subframe_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg0_2_symbol_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg0_2_slot_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg0_2_subframe_id_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg1_0_time_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg1_0_cp_length_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg1_1_time_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg1_1_cp_length_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg1_2_time_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg1_2_cp_length_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg2_0_num_symbol_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg2_0_freq_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg2_1_num_symbol_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg2_1_freq_offset_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg2_2_num_symbol_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && prach_msg2_2_freq_offset_strb) begin
            field_strb <= 1'b1;
        end
    end

    always @(*) begin
        int_rd_data = '0;
        if (field_strb) begin
            int_rd_data = int_rd_data | field_rd_data;
        end
        if (dl_phase_comp_strb) begin
            int_rd_data[31:0] = int_rd_data[31:0] | dl_phase_comp_dout;
        end
        if (ul_phase_comp_strb) begin
            int_rd_data[31:0] = int_rd_data[31:0] | ul_phase_comp_dout;
        end
    end

endmodule

`default_nettype wire

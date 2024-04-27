// File: lowphy_regs.v
// Brief: Register block generate for lowphy
`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy_regs (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    //
    input  wire [ 8:0] s_axi_awaddr,
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
    input  wire [ 8:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    //
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    // dl_phase_comp
    output wire [ 3:0] dl_phase_comp_addr,
    output wire        dl_phase_comp_en,
    output wire        dl_phase_comp_we,
    output wire [31:0] dl_phase_comp_din,
    input  wire [31:0] dl_phase_comp_dout,
    // ul_phase_comp
    output wire [ 3:0] ul_phase_comp_addr,
    output wire        ul_phase_comp_en,
    output wire        ul_phase_comp_we,
    output wire [31:0] ul_phase_comp_din,
    input  wire [31:0] ul_phase_comp_dout
);

    wire        aclk;
    wire        aresetn;

    reg         init;

    wire        aw_hsk;
    reg  [ 8:0] aw_addr;
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
    reg  [ 8:0] ar_addr;
    reg         ar_ready;
    reg         ar_req;
    reg         ar_ack;

    wire        r_hsk;
    reg  [31:0] r_data;
    reg  [ 1:0] r_resp;
    reg         r_valid;

    // Internal interface signals

    reg  [ 8:0] int_addr;
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

    wire dl_phase_comp_strb;

    assign dl_phase_comp_strb = (int_addr[8:6] == 'h4);

    wire ul_phase_comp_strb;

    assign ul_phase_comp_strb = (int_addr[8:6] == 'h5);

    always @(*) begin
        int_wr_ack = int_wr_en;
    end

    always @(*) begin
        int_wr_err = 1'b1;
        if (int_addr[8:6] == 'h4) begin
            int_wr_err = 1'b0;
        end
        if (int_addr[8:6] == 'h5) begin
            int_wr_err = 1'b0;
        end
    end

    always @(posedge aclk) begin
        int_rd_ack <= int_rd_en;
    end

    always @(posedge aclk) begin
        int_rd_err <= 1'b1;
        if (int_addr[8:6] == 'h4) begin
            int_rd_err <= 1'b0;
        end
        if (int_addr[8:6] == 'h5) begin
            int_rd_err <= 1'b0;
        end
    end


    //--------------------------------------------------------------------------
    // Field logic
    //--------------------------------------------------------------------------


    //--------------------------------------------------------------------------
    // Memory logic
    //--------------------------------------------------------------------------

    // Memory dl_phase_comp @'h100

    assign dl_phase_comp_addr = int_addr[5:2];
    assign dl_phase_comp_en   = ((int_wr_en || int_rd_en) && dl_phase_comp_strb);
    assign dl_phase_comp_we   = (int_wr_en && dl_phase_comp_strb);
    assign dl_phase_comp_din  = int_wr_data[31:0];

    // Memory ul_phase_comp @'h140

    assign ul_phase_comp_addr = int_addr[5:2];
    assign ul_phase_comp_en   = ((int_wr_en || int_rd_en) && ul_phase_comp_strb);
    assign ul_phase_comp_we   = (int_wr_en && ul_phase_comp_strb);
    assign ul_phase_comp_din  = int_wr_data[31:0];


    //--------------------------------------------------------------------------
    // Register readback
    //--------------------------------------------------------------------------

    reg [31:0] field_rd_data;
    reg        field_strb;

    always @(posedge aclk) begin
        field_rd_data <= 1'sb0;
    end

    always @(posedge aclk) begin
        field_strb <= 1'b0;
    end

    reg dl_phase_comp_strb_d;

    always @(posedge aclk) begin
        dl_phase_comp_strb_d <= dl_phase_comp_strb;
    end

    reg ul_phase_comp_strb_d;

    always @(posedge aclk) begin
        ul_phase_comp_strb_d <= ul_phase_comp_strb;
    end

    always @(*) begin
        int_rd_data = 1'sb0;
        if (field_strb) begin
            int_rd_data = int_rd_data | field_rd_data;
        end else begin
            if (dl_phase_comp_strb_d) begin
                int_rd_data[31:0] = int_rd_data[31:0] | dl_phase_comp_dout;
            end
            if (ul_phase_comp_strb_d) begin
                int_rd_data[31:0] = int_rd_data[31:0] | ul_phase_comp_dout;
            end
        end
    end

endmodule

`default_nettype wire

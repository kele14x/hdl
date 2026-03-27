// File: rts2_regs.v
// Brief: Register block generate for rts2
`timescale 1 ns / 1 ps
//
`default_nettype none

module rts2_regs (
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
    // ctrl.en,
    output wire [ 0:0] ctrl_en_out,
    // ram0_offset.val,
    output wire [31:0] ram0_offset_val_out,
    // ram1_offset.val,
    output wire [31:0] ram1_offset_val_out,
    // ram2_offset.val,
    output wire [31:0] ram2_offset_val_out,
    // ram0_size.val,
    output wire [31:0] ram0_size_val_out,
    // ram1_size.val,
    output wire [31:0] ram1_size_val_out,
    // ram2_size.val,
    output wire [31:0] ram2_size_val_out
);

    wire        aclk;
    wire        aresetn;

    reg         init_n;

    wire        aw_hsk;
    reg  [ 8:0] aw_addr;
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
    reg  [ 8:0] ar_addr;
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

    assign version_val_strb = (int_addr[8:2] == 'h0);

    wire scratch0_val_strb;

    assign scratch0_val_strb = (int_addr[8:2] == 'h1);

    wire scratch1_val_strb;

    assign scratch1_val_strb = (int_addr[8:2] == 'h2);

    wire ctrl_en_strb;

    assign ctrl_en_strb = (int_addr[8:2] == 'h40);

    wire ram0_offset_val_strb;

    assign ram0_offset_val_strb = (int_addr[8:2] == 'h41);

    wire ram1_offset_val_strb;

    assign ram1_offset_val_strb = (int_addr[8:2] == 'h42);

    wire ram2_offset_val_strb;

    assign ram2_offset_val_strb = (int_addr[8:2] == 'h43);

    wire ram0_size_val_strb;

    assign ram0_size_val_strb = (int_addr[8:2] == 'h45);

    wire ram1_size_val_strb;

    assign ram1_size_val_strb = (int_addr[8:2] == 'h46);

    wire ram2_size_val_strb;

    assign ram2_size_val_strb = (int_addr[8:2] == 'h47);

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
        if (ctrl_en_strb) begin
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
        if (ram0_size_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ram1_size_val_strb) begin
            int_wr_err <= 1'b0;
        end
        if (ram2_size_val_strb) begin
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
        if (ctrl_en_strb) begin
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
        if (ram0_size_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ram1_size_val_strb) begin
            int_rd_err <= 1'b0;
        end
        if (ram2_size_val_strb) begin
            int_rd_err <= 1'b0;
        end
    end


    //--------------------------------------------------------------------------
    // Field logic
    //--------------------------------------------------------------------------

    // Field version.val @'h0[31:0]

    reg [31:0] version_val_value;

    initial begin
        version_val_value = 'h20250513;
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

    // Field ctrl.en @'h100[0:0]

    reg [0:0] ctrl_en_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ctrl_en_value <= 'h0;
        end else if (int_wr_en && ctrl_en_strb) begin
            ctrl_en_value <= int_wr_data[0:0];
        end
    end

    assign ctrl_en_out = ctrl_en_value;

    // Field ram0_offset.val @'h104[31:0]

    reg [31:0] ram0_offset_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ram0_offset_val_value <= 'h0;
        end else if (int_wr_en && ram0_offset_val_strb) begin
            ram0_offset_val_value <= int_wr_data[31:0];
        end
    end

    assign ram0_offset_val_out = ram0_offset_val_value;

    // Field ram1_offset.val @'h108[31:0]

    reg [31:0] ram1_offset_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ram1_offset_val_value <= 'h0;
        end else if (int_wr_en && ram1_offset_val_strb) begin
            ram1_offset_val_value <= int_wr_data[31:0];
        end
    end

    assign ram1_offset_val_out = ram1_offset_val_value;

    // Field ram2_offset.val @'h10c[31:0]

    reg [31:0] ram2_offset_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ram2_offset_val_value <= 'h0;
        end else if (int_wr_en && ram2_offset_val_strb) begin
            ram2_offset_val_value <= int_wr_data[31:0];
        end
    end

    assign ram2_offset_val_out = ram2_offset_val_value;

    // Field ram0_size.val @'h114[31:0]

    reg [31:0] ram0_size_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ram0_size_val_value <= 'h1000;
        end else if (int_wr_en && ram0_size_val_strb) begin
            ram0_size_val_value <= int_wr_data[31:0];
        end
    end

    assign ram0_size_val_out = ram0_size_val_value;

    // Field ram1_size.val @'h118[31:0]

    reg [31:0] ram1_size_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ram1_size_val_value <= 'h1000;
        end else if (int_wr_en && ram1_size_val_strb) begin
            ram1_size_val_value <= int_wr_data[31:0];
        end
    end

    assign ram1_size_val_out = ram1_size_val_value;

    // Field ram2_size.val @'h11c[31:0]

    reg [31:0] ram2_size_val_value;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ram2_size_val_value <= 'h1000;
        end else if (int_wr_en && ram2_size_val_strb) begin
            ram2_size_val_value <= int_wr_data[31:0];
        end
    end

    assign ram2_size_val_out = ram2_size_val_value;


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
        if (int_rd_en && version_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | version_val_value;
        end
        if (int_rd_en && scratch0_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | scratch0_val_value;
        end
        if (int_rd_en && scratch1_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | scratch1_val_value;
        end
        if (int_rd_en && ctrl_en_strb) begin
            field_rd_data_next[0:0] = field_rd_data_next[0:0] | ctrl_en_value;
        end
        if (int_rd_en && ram0_offset_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ram0_offset_val_value;
        end
        if (int_rd_en && ram1_offset_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ram1_offset_val_value;
        end
        if (int_rd_en && ram2_offset_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ram2_offset_val_value;
        end
        if (int_rd_en && ram0_size_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ram0_size_val_value;
        end
        if (int_rd_en && ram1_size_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ram1_size_val_value;
        end
        if (int_rd_en && ram2_size_val_strb) begin
            field_rd_data_next[31:0] = field_rd_data_next[31:0] | ram2_size_val_value;
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
        if (int_rd_en && ctrl_en_strb) begin
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
        if (int_rd_en && ram0_size_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ram1_size_val_strb) begin
            field_strb <= 1'b1;
        end
        if (int_rd_en && ram2_size_val_strb) begin
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

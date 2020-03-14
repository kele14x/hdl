`timescale 1 ns / 1 ps
`default_nettype none

module fmc_slv_if_top #(
    parameter C_ADDR_WIDTH = 12,
    parameter C_DATA_WIDTH = 16
) (
    input  wire                      clk       ,
    input  wire                      rst       ,
    // FMC SRAM Interface
    //===================
    input  wire [  C_ADDR_WIDTH-1:0] FMC_A     , // Address bus
    input  wire [  C_DATA_WIDTH-1:0] FMC_D_I   , 
    output wire [  C_DATA_WIDTH-1:0] FMC_D_O   , // Write/read data bus
    output wire [  C_DATA_WIDTH-1:0] FMC_D_T   ,
    input  wire [C_DATA_WIDTH/8-1:0] FMC_NBL   , // Write byte enable
    input  wire                      FMC_NE    , // Chip enable
    input  wire                      FMC_NOE   , // Output enable (read enable)
    input  wire                      FMC_NWE   , // Write enable
    output wire                      FMC_NWAIT ,
    // BRAM interface
    //===============
    output wire                      porta_clk ,
    output wire                      porta_rst ,
    //
    output reg  [  C_ADDR_WIDTH-1:0] porta_addr,
    output reg                       porta_en  ,
    output reg  [  C_DATA_WIDTH-1:0] porta_din ,
    output reg  [C_DATA_WIDTH/8-1:0] porta_we  ,
    input  wire [  C_DATA_WIDTH-1:0] porta_dout
);

    assign porta_clk = clk;
    assign porta_rst = rst;

    var logic [C_ADDR_WIDTH-1:0] fmc_a_s;
    var logic [C_DATA_WIDTH-1:0] fmc_d_s;
    var logic [C_DATA_WIDTH/8-1:0] fmc_nbl_s;
    var logic fmc_ne_s, fmc_noe_s, fmc_nwe_s;

    // FMC input signals CDC
    //----------------------
    
    util_cdc_bits # (
        .C_DATA_WIDTH(C_ADDR_WIDTH + C_DATA_WIDTH + C_DATA_WIDTH/8 + 3)
    ) i_fmc_cdc (
        .clk(clk),
        .din({FMC_A, FMC_D_I, FMC_NBL, FMC_NE, FMC_NOE, FMC_NWE}),
        .dout({fmc_a_s, fmc_d_s, fmc_nbl_s, fmc_ne_s, fmc_noe_s, fmc_nwe_s})
    );

    typedef enum {S_RST, S_IDLE, S_WAIT,
        S_ADDR, S_WRITE, S_READ, S_WPOST, S_RPOST} FMC_STATE_T;

    FMC_STATE_T fmc_state, fmc_state_next;

    always_ff @ (posedge clk) begin
        if (rst) begin
            fmc_state <= S_RST;
        end else begin
            fmc_state <= fmc_state_next;
        end
    end

    always_comb begin
        if (fmc_ne_s) begin
            // Chip is not selected
            fmc_state_next = S_IDLE;
        end else begin
            // Chip is selected
            case (fmc_state) 
                S_RST  : fmc_state_next = S_IDLE;
                S_IDLE : fmc_state_next = fmc_ne_s  ? S_IDLE : S_ADDR;
                S_ADDR : fmc_state_next = fmc_noe_s ? S_WAIT : S_READ;
                S_WAIT : fmc_state_next = fmc_nwe_s ? S_WAIT : S_WRITE;
                S_WRITE: fmc_state_next = S_WPOST;
                S_READ : fmc_state_next = S_RPOST;
                S_WPOST: fmc_state_next = fmc_ne_s ? S_IDLE : S_WPOST;
                S_RPOST: fmc_state_next = fmc_ne_s ? S_IDLE : S_RPOST;
                default: fmc_state_next = S_RST;
            endcase
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            porta_addr <= 'd0;
        end else if (fmc_state == S_ADDR) begin
            porta_addr <= fmc_a_s;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            porta_en <= 1'b0;
        end else if (fmc_state == S_WRITE || fmc_state == S_READ) begin
            porta_en <= 1'b1;
        end else begin
            porta_en <= 1'b0;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            porta_din <= 'd0;
        end else if (fmc_state == S_WRITE) begin
            porta_din <= fmc_d_s;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            porta_we <= 'd0;
        end else if (fmc_state == S_WRITE) begin
            porta_we <= ~fmc_nbl_s;
        end
    end

    assign FMC_D_O = porta_dout;

endmodule

`timescale 1 ns / 1 ps
`default_nettype none

module fmc_slv_if #(
    parameter C_ADDR_WIDTH = 12,
    parameter C_DATA_WIDTH = 16
) (
    // FMC PSRAM Interface
    //====================
    input  wire                      FMC_CLK   , // Clock
    input  wire [  C_ADDR_WIDTH-1:0] FMC_A     , // Address bus
    input  wire [  C_DATA_WIDTH-1:0] FMC_D_I   , // Write/read data bus
    output wire [  C_DATA_WIDTH-1:0] FMC_D_O   ,
    output wire [  C_DATA_WIDTH-1:0] FMC_D_T   ,
    input  wire [C_DATA_WIDTH/8-1:0] FMC_NBL   , // Write byte enable
    input  wire                      FMC_NE    , // Chip enable
    input  wire                      FMC_NL    , // Address valid
    input  wire                      FMC_NOE   , // Output enable (read enable)
    input  wire                      FMC_NWE   , // Write enable
    output wire                      FMC_NWAIT ,
    // BRAM interface
    //===============
    output wire                      bram_clk  ,
    output wire                      bram_rst  ,
    //
    output wire [  C_ADDR_WIDTH-1:0] bram_addr ,
    output wire                      bram_en   ,
    output wire [  C_DATA_WIDTH-1:0] bram_din  ,
    output wire [C_DATA_WIDTH/8-1:0] bram_we   ,
    input  wire [  C_DATA_WIDTH-1:0] bram_dout
);

    fmc_slv_if_top inst (
        .FMC_CLK  (FMC_CLK  ),
        .FMC_A    (FMC_A    ),
        .FMC_D_I  (FMC_D_I  ),
        .FMC_D_O  (FMC_D_O  ),
        .FMC_D_T  (FMC_D_T  ),
        .FMC_NBL  (FMC_NBL  ),
        .FMC_NE   (FMC_NE   ),
        .FMC_NL   (FMC_NL   ),
        .FMC_NOE  (FMC_NOE  ),
        .FMC_NWE  (FMC_NWE  ),
        .FMC_NWAIT(FMC_NWAIT),
        //
        .bram_clk (bram_clk ),
        .bram_rst (bram_rst ),
        .bram_addr(bram_addr),
        .bram_en  (bram_en  ),
        .bram_din (bram_din ),
        .bram_we  (bram_we  ),
        .bram_dout(bram_dout)
    );

endmodule

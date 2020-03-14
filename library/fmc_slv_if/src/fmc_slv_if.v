`timescale 1 ps / 1 ns
`default_nettype none

module fmc_slv_if (
    input              clk       ,
    input              rst       ,
    // FMC SRAM Interface
    //===================
    input  wire [11:0] FMC_A     , // Address bus
    inout  wire [15:0] FMC_D     , // Write/read data bus
    input  wire [ 1:0] FMC_NBL   , // Write byte enable
    input  wire        FMC_NE    , // Chip enable
    input  wire        FMC_NOE   , // Output enable (read enable)
    input  wire        FMC_NWE   , // Write enable
    output wire        FMC_NWAIT ,
    // BRAM interface
    //===============
    output wire        porta_clk ,
    output wire        porta_rst ,
    output wire [11:0] porta_addr,
    output wire        porta_en  ,
    output wire [15:0] porta_din ,
    output wire [ 1:0] porta_we
);

    fmc_slv_if_top inst (
        .clk       (clk       ),
        .rst       (rst       ),
        .FMC_A     (FMC_A     ),
        .FMC_D     (FMC_D     ),
        .FMC_NBL   (FMC_NBL   ),
        .FMC_NE    (FMC_NE    ),
        .FMC_NOE   (FMC_NOE   ),
        .FMC_NWE   (FMC_NWE   ),
        .FMC_NWAIT (FMC_NWAIT ),
        .porta_clk (porta_clk ),
        .porta_rst (porta_rst ),
        .porta_addr(porta_addr),
        .porta_en  (porta_en  ),
        .porta_din (porta_din ),
        .porta_we  (porta_we  )
    );

endmodule : fmc_slv_if


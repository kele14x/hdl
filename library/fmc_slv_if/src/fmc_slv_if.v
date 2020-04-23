`timescale 1 ns / 1 ps
`default_nettype none

module fmc_slv_if #(
    parameter C_ADDR_WIDTH = 12,
    parameter C_DATA_WIDTH = 16
) (
    // FMC PSRAM Interface
    //====================
    (* X_INTERFACE_INFO = "xilinx.com:interface:emc:1.0 FMC RD_CLK" *)
    input  wire                      FMC_CLK   , // Clock
    (* X_INTERFACE_INFO = "xilinx.com:interface:emc:1.0 FMC ADDR" *)
    input  wire [  C_ADDR_WIDTH-1:0] FMC_A     , // Address bus
    (* X_INTERFACE_INFO = "xilinx.com:interface:emc:1.0 FMC DQ_I" *)
    input  wire [  C_DATA_WIDTH-1:0] FMC_D_I   , // Write/read data bus
    (* X_INTERFACE_INFO = "xilinx.com:interface:emc:1.0 FMC DQ_O" *)
    output wire [  C_DATA_WIDTH-1:0] FMC_D_O   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:emc:1.0 FMC DQ_T" *)
    output wire [  C_DATA_WIDTH-1:0] FMC_D_T   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:emc:1.0 FMC BEN" *)
    input  wire [C_DATA_WIDTH/8-1:0] FMC_NBL   , // Write byte enable
    (* X_INTERFACE_INFO = "xilinx.com:interface:emc:1.0 FMC CE_N" *)
    input  wire                      FMC_NE    , // Chip enable
    (* X_INTERFACE_INFO = "xilinx.com:interface:emc:1.0 FMC ADV_LDN" *)
    input  wire                      FMC_NL    , // Address valid
    (* X_INTERFACE_INFO = "xilinx.com:interface:emc:1.0 FMC OEN" *)
    input  wire                      FMC_NOE   , // Output enable (read enable)
    (* X_INTERFACE_INFO = "xilinx.com:interface:emc:1.0 FMC WEN" *)
    input  wire                      FMC_NWE   , // Write enable
    (* X_INTERFACE_INFO = "xilinx.com:interface:emc:1.0 FMC WAIT" *)
    output wire                      FMC_NWAIT ,
    // BRAM interface
    //===============
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM CLK" *)
    output wire                      bram_clk  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM RST" *)
    output wire                      bram_rst  ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM ADDR" *)
    output wire [  C_ADDR_WIDTH-1:0] bram_addr ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM EN" *)
    output wire                      bram_en   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM DIN" *)
    output wire [  C_DATA_WIDTH-1:0] bram_din  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM WE" *)
    output wire [C_DATA_WIDTH/8-1:0] bram_we   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM DOUT" *)
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

`default_nettype wire

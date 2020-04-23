`timescale 1 ns / 1 ps
`default_nettype none

// PSRAM interface
//----------------
// FMC clock should be generated at both write and read operation
// NWAIT is sync wait signal with low polarity (avtive low)
// BRAM latency should be 2
module fmc_slv_if_top #(
    parameter C_ADDR_WIDTH = 12,
    parameter C_DATA_WIDTH = 16,
    parameter C_FMC_DATLAT = 2 
) (
    // FMC PSRAM Interface
    //====================
    input  wire                      FMC_CLK   , // Clock
    input  wire [  C_ADDR_WIDTH-1:0] FMC_A     , // Address bus
    input  wire [  C_DATA_WIDTH-1:0] FMC_D_I   , 
    output wire [  C_DATA_WIDTH-1:0] FMC_D_O   , // Write/read data bus
    output wire [  C_DATA_WIDTH-1:0] FMC_D_T   ,
    input  wire [C_DATA_WIDTH/8-1:0] FMC_NBL   , // Write byte enable
    input  wire                      FMC_NE    , // Chip enable
    input  wire                      FMC_NL    , // Address valid
    input  wire                      FMC_NOE   , // Output enable (read enable)
    input  wire                      FMC_NWE   , // Write enable
    output reg                       FMC_NWAIT ,
    // BRAM interface
    //===============
    output wire                      bram_clk  ,
    output wire                      bram_rst  ,
    //
    output reg  [  C_ADDR_WIDTH-1:0] bram_addr ,
    output reg                       bram_en   ,
    output reg  [  C_DATA_WIDTH-1:0] bram_din  ,
    output reg  [C_DATA_WIDTH/8-1:0] bram_we   ,
    input  wire [  C_DATA_WIDTH-1:0] bram_dout
);

    wire FMC_CLK_s;

    // BRAM 
    //======

    // BRAM clcok

    BUFR #(
        .BUFR_DIVIDE("BYPASS"),
        .SIM_DEVICE("7SERIES")
    ) BUFR_inst (
        .O  (FMC_CLK_s),
        .CE (1'b1     ),
        .CLR(1'b0     ),
        .I  (FMC_CLK  )
    );

    assign bram_clk = FMC_CLK;

    // BRAM reset generation

    localparam C_RST_SRL = 16;

    reg [C_RST_SRL-1:0] bram_rst_srl = {C_RST_SRL{1'b1}};

    always_ff @ (posedge FMC_CLK_s) begin
        bram_rst_srl <= {bram_rst_srl[C_RST_SRL-2:0], 1'b0};
    end
    
    assign bram_rst = bram_rst_srl[C_RST_SRL-1];

    // Count for FMC transcation ticks
    // It should be async reset by FMC_NE (Not Enable)

    reg [7:0] fmc_cnt;

    always_ff @ (posedge FMC_CLK_s or posedge FMC_NE) begin
        if (FMC_NE) begin
            fmc_cnt <= {8{1'b0}};
        end else begin // Count how many ticks
            fmc_cnt <= fmc_cnt + 1;
        end
    end

    // BRAM address generation
    
    always_ff @ (posedge FMC_CLK_s) begin
        if (!FMC_NE && !FMC_NL) begin
            bram_addr <= FMC_A;
        end else if (!FMC_NE && FMC_NWE) begin // Reading
            bram_addr <= bram_addr + 1;
        end else if (!FMC_NE && !FMC_NWE) begin // Writing
            // Data will be at bus at 4th tick (fmc_cnt shows 4)
            bram_addr <= (fmc_cnt >= C_FMC_DATLAT + 2) ? bram_addr + 1 : bram_addr;
        end
    end

    // BRAM enable generation (for read & write)
    // Async reset by FMC_NE

    always_ff @ (posedge FMC_CLK_s or posedge FMC_NE) begin
        if (FMC_NE) begin
            bram_en <= 1'b0;
        end else begin
            bram_en <= 1'b1;
        end
    end

    // BRAM write enable 
    
    always_ff @ (posedge FMC_CLK_s or posedge FMC_NE) begin
        if (FMC_NE) begin
            bram_we <= 'd0;
        end else begin
            bram_we <= (!FMC_NWE && fmc_cnt >= C_FMC_DATLAT + 1) ? ~FMC_NBL : 'd0;
        end
    end

    // BRAM write data
    
    always_ff @ (posedge FMC_CLK_s) begin
        if (!FMC_NE && !FMC_NWE && fmc_cnt >= C_FMC_DATLAT + 1) begin
            bram_din <= FMC_D_I;
        end
    end

    // FMC 
    //=====

    // FMC data output

    assign FMC_D_T = {C_DATA_WIDTH{FMC_NOE}};

    assign FMC_D_O = bram_dout;

    // FMC NWAIT
    
    always_ff @ (posedge FMC_CLK_s or posedge FMC_NE) begin
        if (FMC_NE) begin
            FMC_NWAIT <= 1'b0;
        end else begin
            // Compare to write operation, read has 1 clock extra delay
            FMC_NWAIT <= (!FMC_NWE || (FMC_NWE && fmc_cnt >= C_FMC_DATLAT));
        end
    end

endmodule

`default_nettype wire

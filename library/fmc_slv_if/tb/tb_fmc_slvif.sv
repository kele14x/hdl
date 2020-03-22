`timescale 1 ns / 1 ps
`default_nettype none

module tb_fmc_slvif ();

    parameter C_ADDR_WIDTH = 12;
    parameter C_DATA_WIDTH = 16;

    // FMC PSRAM Interface

    var logic                      FMC_CLK   = 0; // Clock
    var logic [  C_ADDR_WIDTH-1:0] FMC_A     = 0; // Address bus
    var logic [  C_DATA_WIDTH-1:0] FMC_D_I   = 0; // Write/read data bus
    var logic [  C_DATA_WIDTH-1:0] FMC_D_O   = 0;
    var logic [  C_DATA_WIDTH-1:0] FMC_D_T   = 0;
    var logic [C_DATA_WIDTH/8-1:0] FMC_NBL   = 0; // Write byte enable
    var logic                      FMC_NE    = 1; // Chip enable
    var logic                      FMC_NL    = 1; // Address valid
    var logic                      FMC_NOE   = 1; // enable (read enable)
    var logic                      FMC_NWE   = 1; // Write enable
    var logic                      FMC_NWAIT    ;

    // BRAM interface

    var logic                      bram_clk     ;
    var logic                      bram_rst     ;
    //
    var logic [  C_ADDR_WIDTH-1:0] bram_addr    ;
    var logic                      bram_en      ;
    var logic [  C_DATA_WIDTH-1:0] bram_din     ;
    var logic [C_DATA_WIDTH/8-1:0] bram_we      ;
    var logic [  C_DATA_WIDTH-1:0] bram_dout = 0;

    var logic fmc_ker_ck = 0;


    task fmc_write (input int nbyte, input [11:0] addr, input [63:0] data, input [7:0] be);
        @(posedge fmc_ker_ck);
        FMC_A   <= addr;
        FMC_NE  <= 0;
        FMC_NOE <= 1'bz;
        FMC_NWE <= 0;
        FMC_NL  <= 0;
        FMC_CLK <= 0;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 1;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 0;
        FMC_NL  <= 1;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 1;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 0;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 1;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 0;
        for (int i = 0; i < (nbyte + 1) / 2; i++) begin
            @(posedge fmc_ker_ck);
            FMC_CLK <= 1;
            FMC_D_I <= data[i*16+15-:16];
            FMC_NBL <= 0;
            @(posedge fmc_ker_ck);
            FMC_CLK <= 0;
        end
        // Last strob
        @(posedge fmc_ker_ck);
        FMC_CLK <= 1;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 0;
        FMC_NE  <= 1;
        FMC_NOE <= 1;
        FMC_NWE <= 1;
    endtask

    task fmc_read(input int nbyte, input [11:0] addr, output [63:0] data);
        @(posedge fmc_ker_ck);
        FMC_A   <= addr;
        FMC_NE  <= 0;
        FMC_NOE <= 1;
        FMC_NWE <= 1;
        FMC_NL  <= 0;
        FMC_CLK <= 0;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 1;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 0;
        FMC_NL  <= 1;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 1;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 0;
        FMC_NOE <= 0;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 1;
        @(posedge fmc_ker_ck);
        FMC_CLK <= 0;
        for (int i = 0; i < (nbyte + 1) / 2; i++) begin
            @(posedge fmc_ker_ck);
            FMC_CLK <= 1;
            data[i*16+15-:16] <= FMC_D_T ? 16'bz : FMC_D_O;
            @(posedge fmc_ker_ck);
            FMC_CLK <= 0;
        end
        FMC_NE  <= 1;
        FMC_NOE <= 1;
        FMC_NWE <= 1;
    endtask

    always begin
        #5 fmc_ker_ck = !fmc_ker_ck;
    end

    initial begin
        reg [63:0] temp;
        $display("Simulation starts");
        #100;
        fmc_write(2, 12'hABC, 16'h1234, 8'h03);
        #100;
        fmc_read(2, 12'hABC, temp);
        $display("Read: %x", temp);
        #1000;
        $display("Simulation ends");
        $finish;
    end

    fmc_slv_if UUT (.*);

endmodule

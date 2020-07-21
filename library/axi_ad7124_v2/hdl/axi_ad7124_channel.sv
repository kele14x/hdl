/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_channel #(
    // ID
    parameter ID                             = 0,
    // Direct
    parameter CMD_FIFO_ADDRESS_WIDTH         = 4,
    parameter SYNC_FIFO_ADDRESS_WIDTH        = 4,
    parameter SDO_FIFO_ADDRESS_WIDTH         = 5,
    parameter SDI_FIFO_ADDRESS_WIDTH         = 5,
    // Offload
    parameter OFFLOAD0_CMD_MEM_ADDRESS_WIDTH = 4,
    parameter OFFLOAD0_SDO_MEM_ADDRESS_WIDTH = 4,
    //
    parameter NUM_OF_CS                      = 1
) (
    // UP interface
    //-------------
    input  wire                   up_clk           ,
    input  wire                   up_rstn          ,
    //
    input  wire                   up_wreq          ,
    input  wire [           13:0] up_waddr         ,
    input  wire [           31:0] up_wdata         ,
    output wire                   up_wack          ,
    input  wire                   up_rreq          ,
    input  wire [           13:0] up_raddr         ,
    output wire [           31:0] up_rdata         ,
    output wire                   up_rack          ,
    //
    output wire                   irq              ,
    // AXIS I/F
    //---------
    output wire                   offload_sdi_valid,
    input  wire                   offload_sdi_ready,
    output wire [            7:0] offload_sdi_data ,
    // SPI I/F
    //--------
    input  wire                   phy_sclk_i       ,
    output wire                   phy_sclk_o       ,
    output wire                   phy_sclk_t       ,
    input  wire [(NUM_OF_CS-1):0] phy_cs_i         ,
    output wire [(NUM_OF_CS-1):0] phy_cs_o         ,
    output wire [(NUM_OF_CS-1):0] phy_cs_t         ,
    input  wire                   phy_mosi_i       ,
    output wire                   phy_mosi_o       ,
    output wire                   phy_mosi_t       ,
    input  wire                   phy_miso_i       ,
    output wire                   phy_miso_o       ,
    output wire                   phy_miso_t
);

    // Common
    localparam NUM_OF_SDI    = 1;
    localparam DATA_WIDTH    = 8;
    localparam ASYNC_SPI_CLK = 0;
    // AXI SPI
    localparam MM_IF_TYPE = 1; // UP_FIFO
    // SPI Offload
    localparam ASYNC_TRIG = 0;
    // SPI Execution
    localparam [7:0] DEFAULT_SPI_CFG = 1    ; // {5'b0, three_wire, CPOL, CPHA}
    localparam [7:0] DEFAULT_CLK_DIV = 0    ; // f_sclk = f_clk / ((div + 1) * 2)
    localparam [0:0] SDO_DEFAULT     = 1'b0 ;
    localparam [1:0] SDI_DELAY       = 2'b00;

    logic spi_clk   ;
    logic spi_resetn;

    logic ctrl_clk;

    // axi_spi_engine <-> spi_engine_offload

    logic                    offload_cmd_wr_en  ;
    logic [            15:0] offload_cmd_wr_data;
    logic                    offload_sdo_wr_en  ;
    logic [(DATA_WIDTH-1):0] offload_sdo_wr_data;
    logic                    offload_mem_reset  ;
    logic                    offload_enable     ;
    logic                    offload_enabled    ;
    logic                    offload_sync_ready ;
    logic                    offload_sync_valid ;
    logic [             7:0] offload_sync_data  ;

    // axi_spi_engine <-> util_pulse_gen

    logic [31:0] pulse_gen_period;
    logic [31:0] pulse_gen_width ;
    logic        pulse_gen_load  ;

    // spi_engine_offload <-> ext

    logic trigger;

    // axi_spi_engine <-> spi_engine_interconnect

    logic                               s0_cmd_valid ;
    logic                               s0_cmd_ready ;
    logic [                       15:0] s0_cmd_data  ;
    logic                               s0_sdo_valid ;
    logic                               s0_sdo_ready ;
    logic [           (DATA_WIDTH-1):0] s0_sdo_data  ;
    logic                               s0_sdi_valid ;
    logic                               s0_sdi_ready ;
    logic [(NUM_OF_SDI*DATA_WIDTH-1):0] s0_sdi_data  ;
    logic                               s0_sync_valid;
    logic                               s0_sync_ready;
    logic [                        7:0] s0_sync      ;

    // spi_engine_offload <-> spi_engine_interconnect

    logic                               s1_cmd_valid ;
    logic                               s1_cmd_ready ;
    logic [                       15:0] s1_cmd_data  ;
    logic                               s1_sdo_valid ;
    logic                               s1_sdo_ready ;
    logic [           (DATA_WIDTH-1):0] s1_sdo_data  ;
    logic                               s1_sdi_valid ;
    logic                               s1_sdi_ready ;
    logic [(NUM_OF_SDI*DATA_WIDTH-1):0] s1_sdi_data  ;
    logic                               s1_sync_valid;
    logic                               s1_sync_ready;
    logic [                        7:0] s1_sync      ;

    // spi_engine_interconnect <-> spi_engine_execution

    logic                               m_cmd_valid ;
    logic                               m_cmd_ready ;
    logic [                       15:0] m_cmd_data  ;
    logic                               m_sdo_valid ;
    logic                               m_sdo_ready ;
    logic [           (DATA_WIDTH-1):0] m_sdo_data  ;
    logic                               m_sdi_valid ;
    logic                               m_sdi_ready ;
    logic [(NUM_OF_SDI*DATA_WIDTH-1):0] m_sdi_data  ;
    logic                               m_sync_valid;
    logic                               m_sync_ready;
    logic [                        7:0] m_sync      ;

    // spi_engine_execution <-> ext

    logic active;

    logic                    spi_sclk  ;
    logic                    spi_sdo   ;
    logic                    spi_sdo_t ;
    logic [(NUM_OF_SDI-1):0] spi_sdi   ;
    logic [ (NUM_OF_CS-1):0] spi_cs    ;
    logic                    three_wire; // 3 wire SPI ?


    //--------------------------------------------------------------------------

    assign ctrl_clk = up_clk;
    assign spi_clk  = up_clk;

    // SPI PHY Ports

    assign phy_sclk_o = spi_sclk;
    assign phy_sclk_t = 1'b0;

    assign phy_cs_o   = spi_cs;
    assign phy_cs_t   = 1'b0;

    assign phy_mosi_o = spi_sdo;
    assign phy_mosi_t = spi_sdo_t;

    assign phy_miso_o = 1'b0;
    assign phy_miso_t = 1'b1;
    assign spi_sdi  = three_wire ? phy_mosi_i : phy_miso_i;

    (* keep_hierarchy="yes" *)
    axi_spi_engine #(
        .CMD_FIFO_ADDRESS_WIDTH        (CMD_FIFO_ADDRESS_WIDTH        ),
        .SYNC_FIFO_ADDRESS_WIDTH       (SYNC_FIFO_ADDRESS_WIDTH       ),
        .SDO_FIFO_ADDRESS_WIDTH        (SDO_FIFO_ADDRESS_WIDTH        ),
        .SDI_FIFO_ADDRESS_WIDTH        (SDI_FIFO_ADDRESS_WIDTH        ),
        .MM_IF_TYPE                    (MM_IF_TYPE                    ),
        .ASYNC_SPI_CLK                 (ASYNC_SPI_CLK                 ),
        .NUM_OFFLOAD                   (0                             ), // Not implemented
        .OFFLOAD0_CMD_MEM_ADDRESS_WIDTH(OFFLOAD0_CMD_MEM_ADDRESS_WIDTH),
        .OFFLOAD0_SDO_MEM_ADDRESS_WIDTH(OFFLOAD0_SDO_MEM_ADDRESS_WIDTH),
        .ID                            (ID                            ),
        .DATA_WIDTH                    (DATA_WIDTH                    ),
        .NUM_OF_SDI                    (NUM_OF_SDI                    )
    ) i_axi_spi_engine (
        // .s_axi_aclk          (s_axi_aclk          ),
        // .s_axi_aresetn       (s_axi_aresetn       ),
        // .s_axi_awvalid       (s_axi_awvalid       ),
        // .s_axi_awaddr        (s_axi_awaddr        ),
        // .s_axi_awready       (s_axi_awready       ),
        // .s_axi_awprot        (s_axi_awprot        ),
        // .s_axi_wvalid        (s_axi_wvalid        ),
        // .s_axi_wdata         (s_axi_wdata         ),
        // .s_axi_wstrb         (s_axi_wstrb         ),
        // .s_axi_wready        (s_axi_wready        ),
        // .s_axi_bvalid        (s_axi_bvalid        ),
        // .s_axi_bresp         (s_axi_bresp         ),
        // .s_axi_bready        (s_axi_bready        ),
        // .s_axi_arvalid       (s_axi_arvalid       ),
        // .s_axi_araddr        (s_axi_araddr        ),
        // .s_axi_arready       (s_axi_arready       ),
        // .s_axi_arprot        (s_axi_arprot        ),
        // .s_axi_rvalid        (s_axi_rvalid        ),
        // .s_axi_rready        (s_axi_rready        ),
        // .s_axi_rresp         (s_axi_rresp         ),
        // .s_axi_rdata         (s_axi_rdata         ),
        //
        .up_clk              (up_clk             ),
        .up_rstn             (up_rstn            ),
        //
        .up_wreq             (up_wreq            ),
        .up_waddr            (up_waddr           ),
        .up_wdata            (up_wdata           ),
        .up_wack             (up_wack            ),
        .up_rreq             (up_rreq            ),
        .up_raddr            (up_raddr           ),
        .up_rdata            (up_rdata           ),
        .up_rack             (up_rack            ),
        //
        .irq                 (irq                ),
        //
        .spi_clk             (spi_clk            ),
        .spi_resetn          (spi_resetn         ),
        //
        .cmd_ready           (s0_cmd_ready       ),
        .cmd_valid           (s0_cmd_valid       ),
        .cmd_data            (s0_cmd_data        ),
        .sdo_data_ready      (s0_sdo_ready       ),
        .sdo_data_valid      (s0_sdo_valid       ),
        .sdo_data            (s0_sdo_data        ),
        .sdi_data_ready      (s0_sdi_ready       ),
        .sdi_data_valid      (s0_sdi_valid       ),
        .sdi_data            (s0_sdi_data        ),
        .sync_ready          (s0_sync_ready      ),
        .sync_valid          (s0_sync_valid      ),
        .sync_data           (s0_sync            ),
        //
        .offload0_cmd_wr_en  (offload_cmd_wr_en  ),
        .offload0_cmd_wr_data(offload_cmd_wr_data),
        .offload0_sdo_wr_en  (offload_sdo_wr_en  ),
        .offload0_sdo_wr_data(offload_sdo_wr_data),
        .offload0_mem_reset  (offload_mem_reset  ),
        .offload0_enable     (offload_enable     ),
        .offload0_enabled    (offload_enabled    ),
        .offload_sync_ready  (offload_sync_ready ),
        .offload_sync_valid  (offload_sync_valid ),
        .offload_sync_data   (offload_sync_data  ),
        //
        .pulse_gen_period    (pulse_gen_period   ),
        .pulse_gen_width     (pulse_gen_width    ),
        .pulse_gen_load      (pulse_gen_load     )
    );

    (* keep_hierarchy="yes" *)
    spi_engine_offload #(
        .ASYNC_SPI_CLK        (ASYNC_SPI_CLK                 ),
        .ASYNC_TRIG           (ASYNC_TRIG                    ),
        .CMD_MEM_ADDRESS_WIDTH(OFFLOAD0_CMD_MEM_ADDRESS_WIDTH),
        .SDO_MEM_ADDRESS_WIDTH(OFFLOAD0_SDO_MEM_ADDRESS_WIDTH),
        .DATA_WIDTH           (DATA_WIDTH                    ),
        .NUM_OF_SDI           (NUM_OF_SDI                    )
    ) i_spi_engine_offload (
        .ctrl_clk         (ctrl_clk           ),
        //
        .ctrl_cmd_wr_en   (offload_cmd_wr_en  ),
        .ctrl_cmd_wr_data (offload_cmd_wr_data),
        .ctrl_sdo_wr_en   (offload_sdo_wr_en  ),
        .ctrl_sdo_wr_data (offload_sdo_wr_data),
        .ctrl_enable      (offload_enable     ),
        .ctrl_enabled     (offload_enabled    ),
        .ctrl_mem_reset   (offload_mem_reset  ),
        .status_sync_valid(offload_sync_valid ),
        .status_sync_ready(offload_sync_ready ),
        .status_sync_data (offload_sync_data  ),
        //
        .spi_clk          (spi_clk            ),
        .spi_resetn       (spi_resetn         ),
        //
        .trigger          (trigger            ),
        //
        .cmd_valid        (s1_cmd_valid       ),
        .cmd_ready        (s1_cmd_ready       ),
        .cmd              (s1_cmd_data        ),
        .sdo_data_valid   (s1_sdo_valid       ),
        .sdo_data_ready   (s1_sdo_ready       ),
        .sdo_data         (s1_sdo_data        ),
        .sdi_data_valid   (s1_sdi_valid       ),
        .sdi_data_ready   (s1_sdi_ready       ),
        .sdi_data         (s1_sdi_data        ),
        .sync_valid       (s1_sync_valid      ),
        .sync_ready       (s1_sync_ready      ),
        .sync_data        (s1_sync            ),
        //
        .offload_sdi_valid(offload_sdi_valid  ),
        .offload_sdi_ready(offload_sdi_ready  ),
        .offload_sdi_data (offload_sdi_data   )
    );

    (* keep_hierarchy="yes" *)
    spi_engine_interconnect #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_OF_SDI(NUM_OF_SDI)
    ) i_spi_engine_interconnect (
        .clk          (ctrl_clk     ),
        .resetn       (spi_resetn   ),
        //
        .m_cmd_valid  (m_cmd_valid  ),
        .m_cmd_ready  (m_cmd_ready  ),
        .m_cmd_data   (m_cmd_data   ),
        .m_sdo_valid  (m_sdo_valid  ),
        .m_sdo_ready  (m_sdo_ready  ),
        .m_sdo_data   (m_sdo_data   ),
        .m_sdi_valid  (m_sdi_valid  ),
        .m_sdi_ready  (m_sdi_ready  ),
        .m_sdi_data   (m_sdi_data   ),
        .m_sync_valid (m_sync_valid ),
        .m_sync_ready (m_sync_ready ),
        .m_sync       (m_sync       ),
        //
        .s0_cmd_valid (s0_cmd_valid ),
        .s0_cmd_ready (s0_cmd_ready ),
        .s0_cmd_data  (s0_cmd_data  ),
        .s0_sdo_valid (s0_sdo_valid ),
        .s0_sdo_ready (s0_sdo_ready ),
        .s0_sdo_data  (s0_sdo_data  ),
        .s0_sdi_valid (s0_sdi_valid ),
        .s0_sdi_ready (s0_sdi_ready ),
        .s0_sdi_data  (s0_sdi_data  ),
        .s0_sync_valid(s0_sync_valid),
        .s0_sync_ready(s0_sync_ready),
        .s0_sync      (s0_sync      ),
        //
        .s1_cmd_valid (s1_cmd_valid ),
        .s1_cmd_ready (s1_cmd_ready ),
        .s1_cmd_data  (s1_cmd_data  ),
        .s1_sdo_valid (s1_sdo_valid ),
        .s1_sdo_ready (s1_sdo_ready ),
        .s1_sdo_data  (s1_sdo_data  ),
        .s1_sdi_valid (s1_sdi_valid ),
        .s1_sdi_ready (s1_sdi_ready ),
        .s1_sdi_data  (s1_sdi_data  ),
        .s1_sync_valid(s1_sync_valid),
        .s1_sync_ready(s1_sync_ready),
        .s1_sync      (s1_sync      )
    );

    (* keep_hierarchy="yes" *)
    spi_engine_execution #(
        .NUM_OF_CS      (NUM_OF_CS      ),
        .DEFAULT_SPI_CFG(DEFAULT_SPI_CFG),
        .DEFAULT_CLK_DIV(DEFAULT_CLK_DIV),
        .DATA_WIDTH     (DATA_WIDTH     ),
        .NUM_OF_SDI     (NUM_OF_SDI     ),
        .SDO_DEFAULT    (SDO_DEFAULT    ),
        .SDI_DELAY      (SDI_DELAY      )
    ) i_spi_engine_execution (
        .clk           (spi_clk     ),
        .resetn        (spi_resetn  ),
        //
        .active        (active      ),
        //
        .cmd_ready     (m_cmd_ready ),
        .cmd_valid     (m_cmd_valid ),
        .cmd           (m_cmd_data  ),
        .sdo_data_valid(m_sdo_valid ),
        .sdo_data_ready(m_sdo_ready ),
        .sdo_data      (m_sdo_data  ),
        .sdi_data_ready(m_sdi_ready ),
        .sdi_data_valid(m_sdi_valid ),
        .sdi_data      (m_sdi_data  ),
        .sync_ready    (m_sync_ready),
        .sync_valid    (m_sync_valid),
        .sync          (m_sync      ),
        //
        .sclk          (spi_sclk    ),
        .sdo           (spi_sdo     ),
        .sdo_t         (spi_sdo_t   ),
        .sdi           (spi_sdi     ),
        .cs            (spi_cs      ),
        .three_wire    (three_wire  )
    );

    (* keep_hierarchy="yes" *)
    util_pulse_gen #(
        .PULSE_WIDTH (1        ),
        .PULSE_PERIOD(100000000)
    ) i_util_pulse_gen (
        .clk          (spi_clk         ),
        .rstn         (spi_resetn      ),
        //
        .pulse_width  (pulse_gen_period),
        .pulse_period (pulse_gen_width ),
        .load_config  (pulse_gen_load  ),
        //
        .pulse        (trigger         ),
        .pulse_counter(/* Not used */  )
    );

endmodule

`default_nettype wire

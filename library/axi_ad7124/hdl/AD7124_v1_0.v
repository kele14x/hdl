
`timescale 1 ns / 1 ps

module AD7124_v1_0 #(
	// Users to add parameters here
	// User parameters ends
	// Do not modify the parameters beyond this line
	// Parameters of Axi Slave Bus Interface S00_AXI
	parameter            integer C_S00_AXI_DATA_WIDTH = 32,
	parameter            integer C_S00_AXI_ADDR_WIDTH = 10
) (
	// Users to add ports here
	// general
	input                                      rst            ,
	output                                     PL_LED_TEST    ,
	//0 AD_Board
	output      [                         7:0] TC_cs_n        ,
	output                                     TC_sclk        ,
	output                                     TC_sdi         ,
	input                                      TC_sdo         ,
	output                                     SYNC           ,
	output                                     G1_ANA_POW_EN  ,
	//1 AD_Board
	output      [                         7:0] TC_cs_n_1      ,
	output                                     TC_sclk_1      ,
	output                                     TC_sdi_1       ,
	input                                      TC_sdo_1       ,
	output                                     SYNC_1         ,
	output                                     G1_ANA_POW_EN_1,
	//2 AD_Board
	output      [                         7:0] TC_cs_n_2      ,
	output                                     TC_sclk_2      ,
	output                                     TC_sdi_2       ,
	input                                      TC_sdo_2       ,
	output                                     SYNC_2         ,
	output                                     G1_ANA_POW_EN_2,
	//3 AD_Board
	output      [                         7:0] TC_cs_n_3      ,
	output                                     TC_sclk_3      ,
	output                                     TC_sdi_3       ,
	input                                      TC_sdo_3       ,
	output                                     SYNC_3         ,
	output                                     G1_ANA_POW_EN_3,
	//4 AD_Board
	output      [                         7:0] TC_cs_n_4      ,
	output                                     TC_sclk_4      ,
	output                                     TC_sdi_4       ,
	input                                      TC_sdo_4       ,
	output                                     SYNC_4         ,
	output                                     G1_ANA_POW_EN_4,
	//5 AD_Board
	output      [                         7:0] TC_cs_n_5      ,
	output                                     TC_sclk_5      ,
	output                                     TC_sdi_5       ,
	input                                      TC_sdo_5       ,
	output                                     SYNC_5         ,
	output                                     G1_ANA_POW_EN_5,
	//校准控制，继电器控制�?�?
	output                                     G0_Relay_Ctrl  ,
	output                                     G1_Relay_Ctrl  ,
	output                                     G2_Relay_Ctrl  ,
	output                                     G3_Relay_Ctrl  ,
	output                                     G4_Relay_Ctrl  ,
	output                                     G5_Relay_Ctrl  ,
	//RTD采集信号
	input                                      RTD_sdo        ,
	output                                     RTD_cs_n       ,
	output                                     RTD_sclk       ,
	output                                     RTD_sdi        ,
	//interrupt
	output                                     interrupt      ,
	
	//RTD_1
	input                                    RTD_sdo_1        ,
	output                                   RTD_cs_n_1       ,
	output                                   RTD_sclk_1       ,
	output                                   RTD_sdi_1        ,  
	//RTD_2
	input                                    RTD_sdo_2        ,
	output                                   RTD_cs_n_2       ,
	output                                   RTD_sclk_2       ,
	output                                   RTD_sdi_2        ,   
	//RTD_3
	input                                    RTD_sdo_3        ,
	output                                   RTD_cs_n_3       ,
	output                                   RTD_sclk_3       ,
	output                                   RTD_sdi_3        ,  
	//RTD_4
	input                                    RTD_sdo_4        ,
	output                                   RTD_cs_n_4       ,
	output                                   RTD_sclk_4       ,
	output                                   RTD_sdi_4        ,   
	//RTD_5
	input                                    RTD_sdo_5        ,
	output                                   RTD_cs_n_5       ,
	output                                   RTD_sclk_5       ,
	output                                   RTD_sdi_5        ,    

	// User ports ends
	// Do not modify the ports beyond this line
	// Ports of Axi Slave Bus Interface S00_AXI
	input  wire                                s00_axi_aclk   ,
	input  wire                                s00_axi_aresetn,
	input  wire [    C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr ,
	input  wire [                         2:0] s00_axi_awprot ,
	input  wire                                s00_axi_awvalid,
	output wire                                s00_axi_awready,
	input  wire [    C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata  ,
	input  wire [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb  ,
	input  wire                                s00_axi_wvalid ,
	output wire                                s00_axi_wready ,
	output wire [                         1:0] s00_axi_bresp  ,
	output wire                                s00_axi_bvalid ,
	input  wire                                s00_axi_bready ,
	input  wire [    C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr ,
	input  wire [                         2:0] s00_axi_arprot ,
	input  wire                                s00_axi_arvalid,
	output wire                                s00_axi_arready,
	output wire [    C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata  ,
	output wire [                         1:0] s00_axi_rresp  ,
	output wire                                s00_axi_rvalid ,
	input  wire                                s00_axi_rready
);
// Instantiation of Axi Bus Interface S00_AXI
	AD7124_v1_0_S00_AXI #(
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) AD7124_v1_0_S00_AXI_inst (
		.S_AXI_ACLK     (s00_axi_aclk   ),
		.S_AXI_ARESETN  (s00_axi_aresetn),
		.S_AXI_AWADDR   (s00_axi_awaddr ),
		.S_AXI_AWPROT   (s00_axi_awprot ),
		.S_AXI_AWVALID  (s00_axi_awvalid),
		.S_AXI_AWREADY  (s00_axi_awready),
		.S_AXI_WDATA    (s00_axi_wdata  ),
		.S_AXI_WSTRB    (s00_axi_wstrb  ),
		.S_AXI_WVALID   (s00_axi_wvalid ),
		.S_AXI_WREADY   (s00_axi_wready ),
		.S_AXI_BRESP    (s00_axi_bresp  ),
		.S_AXI_BVALID   (s00_axi_bvalid ),
		.S_AXI_BREADY   (s00_axi_bready ),
		.S_AXI_ARADDR   (s00_axi_araddr ),
		.S_AXI_ARPROT   (s00_axi_arprot ),
		.S_AXI_ARVALID  (s00_axi_arvalid),
		.S_AXI_ARREADY  (s00_axi_arready),
		.S_AXI_RDATA    (s00_axi_rdata  ),
		.S_AXI_RRESP    (s00_axi_rresp  ),
		.S_AXI_RVALID   (s00_axi_rvalid ),
		.S_AXI_RREADY   (s00_axi_rready ),
		
		.rst            (rst            ),
		.PL_LED_TEST    (PL_LED_TEST    ),
		
		.TC_cs_n        (TC_cs_n        ),
		.TC_sclk        (TC_sclk        ),
		.TC_sdi         (TC_sdi         ),
		.TC_sdo         (TC_sdo         ),
		.SYNC           (SYNC           ),
		.G1_ANA_POW_EN  (G1_ANA_POW_EN  ),
		
		.TC_cs_n_1      (TC_cs_n_1      ),
		.TC_sclk_1      (TC_sclk_1      ),
		.TC_sdi_1       (TC_sdi_1       ),
		.TC_sdo_1       (TC_sdo_1       ),
		.SYNC_1         (SYNC_1         ),
		.G1_ANA_POW_EN_1(G1_ANA_POW_EN_1),
		
		.TC_cs_n_2      (TC_cs_n_2      ),
		.TC_sclk_2      (TC_sclk_2      ),
		.TC_sdi_2       (TC_sdi_2       ),
		.TC_sdo_2       (TC_sdo_2       ),
		.SYNC_2         (SYNC_2         ),
		.G1_ANA_POW_EN_2(G1_ANA_POW_EN_2),
		
		.TC_cs_n_3      (TC_cs_n_3      ),
		.TC_sclk_3      (TC_sclk_3      ),
		.TC_sdi_3       (TC_sdi_3       ),
		.TC_sdo_3       (TC_sdo_3       ),
		.SYNC_3         (SYNC_3         ),
		.G1_ANA_POW_EN_3(G1_ANA_POW_EN_3),
		
		.TC_cs_n_4      (TC_cs_n_4      ),
		.TC_sclk_4      (TC_sclk_4      ),
		.TC_sdi_4       (TC_sdi_4       ),
		.TC_sdo_4       (TC_sdo_4       ),
		.SYNC_4         (SYNC_4         ),
		.G1_ANA_POW_EN_4(G1_ANA_POW_EN_4),
		
		.TC_cs_n_5      (TC_cs_n_5      ),
		.TC_sclk_5      (TC_sclk_5      ),
		.TC_sdi_5       (TC_sdi_5       ),
		.TC_sdo_5       (TC_sdo_5       ),
		.SYNC_5         (SYNC_5         ),
		.G1_ANA_POW_EN_5(G1_ANA_POW_EN_5),
		
		//校准控制，继电器控制�?�?
		.G0_Relay_Ctrl  (G0_Relay_Ctrl  ),
		.G1_Relay_Ctrl  (G1_Relay_Ctrl  ),
		.G2_Relay_Ctrl  (G2_Relay_Ctrl  ),
		.G3_Relay_Ctrl  (G3_Relay_Ctrl  ),
		.G4_Relay_Ctrl  (G4_Relay_Ctrl  ),
		.G5_Relay_Ctrl  (G5_Relay_Ctrl  ),
		.RTD_sdo        (RTD_sdo        ),
		.RTD_cs_n       (RTD_cs_n       ),
		.RTD_sclk       (RTD_sclk       ),
		.RTD_sdi        (RTD_sdi        ),
		//interrupt
		.interrupt      (interrupt      ),
		//RTD_1-5
        .RTD_sdo_1      (RTD_sdo_1      ),
        .RTD_cs_n_1     (RTD_cs_n_1     ),
        .RTD_sclk_1     (RTD_sclk_1     ),
        .RTD_sdi_1      (RTD_sdi_1      ),         
        .RTD_sdo_2      (RTD_sdo_2      ),
        .RTD_cs_n_2     (RTD_cs_n_2     ),
        .RTD_sclk_2     (RTD_sclk_2     ),
        .RTD_sdi_2      (RTD_sdi_2      ),        
        .RTD_sdo_3      (RTD_sdo_3      ),
        .RTD_cs_n_3     (RTD_cs_n_3     ),
        .RTD_sclk_3     (RTD_sclk_3     ),
        .RTD_sdi_3      (RTD_sdi_3      ),         
        .RTD_sdo_4      (RTD_sdo_4      ),
        .RTD_cs_n_4     (RTD_cs_n_4     ),
        .RTD_sclk_4     (RTD_sclk_4     ),
        .RTD_sdi_4      (RTD_sdi_4      ),       
        .RTD_sdo_5      (RTD_sdo_5      ),
        .RTD_cs_n_5     (RTD_cs_n_5     ),
        .RTD_sclk_5     (RTD_sclk_5     ),
        .RTD_sdi_5      (RTD_sdi_5      )
	);

	// Add user logic here

	// User logic ends

endmodule

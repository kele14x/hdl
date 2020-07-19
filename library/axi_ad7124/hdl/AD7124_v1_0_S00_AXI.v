
`timescale 1 ns / 1 ps

module AD7124_v1_0_S00_AXI #(
    // Users to add parameters here
    // User parameters ends
    // Do not modify the parameters beyond this line
    // Width of S_AXI data bus
    parameter          integer C_S_AXI_DATA_WIDTH = 32,
    // Width of S_AXI address bus
    parameter          integer C_S_AXI_ADDR_WIDTH = 10
) (
    // Users to add ports here
    //general
    input                                    rst            ,
    output                                   PL_LED_TEST    ,
    //0 AD_Board
    output      [                       7:0] TC_cs_n        ,
    output                                   TC_sclk        ,
    output                                   TC_sdi         ,
    input                                    TC_sdo         ,
    output                                   SYNC           ,
    output                                   G1_ANA_POW_EN  ,
    //1 AD_Board
    output      [                       7:0] TC_cs_n_1      ,
    output                                   TC_sclk_1      ,
    output                                   TC_sdi_1       ,
    input                                    TC_sdo_1       ,
    output                                   SYNC_1         ,
    output                                   G1_ANA_POW_EN_1,
    //2 AD_Board
    output      [                       7:0] TC_cs_n_2      ,
    output                                   TC_sclk_2      ,
    output                                   TC_sdi_2       ,
    input                                    TC_sdo_2       ,
    output                                   SYNC_2         ,
    output                                   G1_ANA_POW_EN_2,
    //3 AD_Board
    output      [                       7:0] TC_cs_n_3      ,
    output                                   TC_sclk_3      ,
    output                                   TC_sdi_3       ,
    input                                    TC_sdo_3       ,
    output                                   SYNC_3         ,
    output                                   G1_ANA_POW_EN_3,
    //4 AD_Board
    output      [                       7:0] TC_cs_n_4      ,
    output                                   TC_sclk_4      ,
    output                                   TC_sdi_4       ,
    input                                    TC_sdo_4       ,
    output                                   SYNC_4         ,
    output                                   G1_ANA_POW_EN_4,
    //5 AD_Board
    output      [                       7:0] TC_cs_n_5      ,
    output                                   TC_sclk_5      ,
    output                                   TC_sdi_5       ,
    input                                    TC_sdo_5       ,
    output                                   SYNC_5         ,
    output                                   G1_ANA_POW_EN_5,
    //æ ¡å‡†æŽ§åˆ¶ï¼Œç»§ç”µå™¨æŽ§åˆ¶å¼?å…?
    output                                   G0_Relay_Ctrl  ,
    output                                   G1_Relay_Ctrl  ,
    output                                   G2_Relay_Ctrl  ,
    output                                   G3_Relay_Ctrl  ,
    output                                   G4_Relay_Ctrl  ,
    output                                   G5_Relay_Ctrl  ,
    //RTDé‡‡é›†ä¿¡å?·
    input                                    RTD_sdo        ,
    output                                   RTD_cs_n       ,
    output                                   RTD_sclk       ,
    output                                   RTD_sdi        ,
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
    
    //interrupt
    output  interrupt,
    // User ports ends
    // Do not modify the ports beyond this line
    // Global Clock Signal
    input  wire                              S_AXI_ACLK     ,
    // Global Reset Signal. This Signal is Active LOW
    input  wire                              S_AXI_ARESETN  ,
    // Write address (issued by master, acceped by Slave)
    input  wire [    C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR   ,
    // Write channel Protection type. This signal indicates the
                                                              // privilege and security level of the transaction, and whether
                                                              // the transaction is a data access or an instruction access.
    input  wire [                       2:0] S_AXI_AWPROT   ,
    // Write address valid. This signal indicates that the master signaling
                                                              // valid write address and control information.
    input  wire                              S_AXI_AWVALID  ,
    // Write address ready. This signal indicates that the slave is ready
                                                              // to accept an address and associated control signals.
    output wire                              S_AXI_AWREADY  ,
    // Write data (issued by master, acceped by Slave)
    input  wire [    C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA    ,
    // Write strobes. This signal indicates which byte lanes hold
                                                              // valid data. There is one write strobe bit for each eight
                                                              // bits of the write data bus.
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB    ,
    // Write valid. This signal indicates that valid write
                                                              // data and strobes are available.
    input  wire                              S_AXI_WVALID   ,
    // Write ready. This signal indicates that the slave
                                                              // can accept the write data.
    output wire                              S_AXI_WREADY   ,
    // Write response. This signal indicates the status
                                                              // of the write transaction.
    output wire [                       1:0] S_AXI_BRESP    ,
    // Write response valid. This signal indicates that the channel
                                                              // is signaling a valid write response.
    output wire                              S_AXI_BVALID   ,
    // Response ready. This signal indicates that the master
                                                              // can accept a write response.
    input  wire                              S_AXI_BREADY   ,
    // Read address (issued by master, acceped by Slave)
    input  wire [    C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR   ,
    // Protection type. This signal indicates the privilege
                                                              // and security level of the transaction, and whether the
                                                              // transaction is a data access or an instruction access.
    input  wire [                       2:0] S_AXI_ARPROT   ,
    // Read address valid. This signal indicates that the channel
                                                              // is signaling valid read address and control information.
    input  wire                              S_AXI_ARVALID  ,
    // Read address ready. This signal indicates that the slave is
                                                              // ready to accept an address and associated control signals.
    output wire                              S_AXI_ARREADY  ,
    // Read data (issued by slave)
    output wire [    C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA    ,
    // Read response. This signal indicates the status of the
                                                              // read transfer.
    output wire [                       1:0] S_AXI_RRESP    ,
    // Read valid. This signal indicates that the channel is
                                                              // signaling the required read data.
    output wire                              S_AXI_RVALID   ,
    // Read ready. This signal indicates that the master can
                                                              // accept the read data and response information.
    input  wire                              S_AXI_RREADY
);

    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr ;
    reg                            axi_awready;
    reg                            axi_wready ;
    reg [                   1 : 0] axi_bresp  ;
    reg                            axi_bvalid ;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr ;
    reg                            axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata  ;
    reg [                   1 : 0] axi_rresp  ;
    reg                            axi_rvalid ;

    // Example-specific design signals
    // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
    // ADDR_LSB is used for addressing 32/64 bit registers/memories
    // ADDR_LSB = 2 for 32 bits (n downto 2)
    // ADDR_LSB = 3 for 64 bits (n downto 3)
    localparam integer ADDR_LSB          = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 7                          ;
    //----------------------------------------------
    //-- Signals for user logic register space example
    //------------------------------------------------
    //-- Number of Slave Registers 64
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg0  ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg1  ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg2  ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg3  ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg4  ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg5  ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg6  ;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg7  ;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg8  ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg9  ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg10 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg11 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg12 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg13 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg14 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg15 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg16 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg17 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg18 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg19 ;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg20 ;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg21 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg22 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg23 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg24 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg25 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg26 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg27 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg28 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg29 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg30 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg31 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg32 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg33 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg34 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg35 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg36 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg37 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg38 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg39 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg40 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg41 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg42 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg43 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg44 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg45 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg46 ;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg47 ;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg48 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg49 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg50 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg51 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg52 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg53 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg54 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg55 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg56 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg57 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg58 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg59 ;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg60 ;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg61 ;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg62 ;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg63 ;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg64 ;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg65 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg66 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg67 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg68 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg69 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg70 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg71 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg72 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg73 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg74 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg75 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg76 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg77 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg78 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg79 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg80 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg81 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg82 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg83 ;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg84 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg85 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg86 ;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg87 ;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg88 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg89 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg90 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg91 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg92 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg93 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg94 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg95 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg96 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg97 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg98 ;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg99 ;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg100;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg101;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg102;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg103;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg104;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg105;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg106;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg107;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg108;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg109;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg110;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg111;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg112;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg113;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg114;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg115;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg116;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg117;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg118;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg119;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg120;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg121;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg122;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg123;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg124;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg125;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg126;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg127;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg128;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg129;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg130;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg131;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg132;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg133;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg134;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg135;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg136;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg137;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg138;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg139;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg140;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg141;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg142;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg143;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg144;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg145;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg146;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg147;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg148;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg149;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg150;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg151;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg152;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg153;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg154;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg155;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg156;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg157;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg158;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg159;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg160;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg161;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg162;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg163;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg164;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg165;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg166;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg167;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg168;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg169;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg170;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg171;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg172;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg173;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg174;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg175;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg176;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg177;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg178;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg179;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg180;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg181;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg182;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg183;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg184;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg185;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg186;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg187;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg188;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg189;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg190;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg191;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg192;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg193;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg194;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg195;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg196;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg197;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg198;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg199;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg200;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg201;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg202;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg203;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg204;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg205;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg206;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg207;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg208;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg209;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg210;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg211;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg212;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg213;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg214;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg215;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg216;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg217;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg218;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg219;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg220;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg221;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg222;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg223;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg224;
    wire  [C_S_AXI_DATA_WIDTH-1:0] slv_reg225;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg226;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg227;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg228;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg229;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg230;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg231;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg232;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg233;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg234;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg235;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg236;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg237;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg238;
    reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg239;

    //æ ¡å‡†æŽ§åˆ¶ï¼Œç»§ç”µå™¨æŽ§åˆ¶å¼?å…?
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg240;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg241;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg242;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg243;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg244;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg245;
    //SYNCå?Œæ­¥ä¿¡å?·
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg246 = 32'b0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg247 = 32'b0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg248 = 32'b0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg249 = 32'b0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg250 = 32'b0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg251 = 32'b0;
    
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg253;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_reg254;    

    wire                             slv_reg_rden;
    wire                             slv_reg_wren;
    reg     [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer                          byte_index  ;
    reg                              aw_en       ;
    
    reg [1:0] axi_rresp_dy ;
    reg       axi_rvalid_dy;
    reg slv_reg_rden_dy;
    reg axi_rvalid_dy_2;
    reg axi_rresp_dy_2;
    
    // I/O Connections assignments

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp_dy_2;
    assign S_AXI_RVALID  = axi_rvalid_dy_2;
    // Implement axi_awready generation
    // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
    // de-asserted when reset is low.

    always @( posedge S_AXI_ACLK ) begin
     axi_rresp_dy  <= axi_rresp;  
     axi_rvalid_dy <= axi_rvalid; 
     axi_rresp_dy_2  <= axi_rresp_dy;  
     axi_rvalid_dy_2 <= axi_rvalid_dy; 
     end
     
    always @( posedge S_AXI_ACLK ) begin
    slv_reg_rden_dy <= slv_reg_rden;
    end

    always @( posedge S_AXI_ACLK )
        begin
            if ( S_AXI_ARESETN == 1'b0 )
                begin
                    axi_awready <= 1'b0;
                    aw_en       <= 1'b1;
                end
            else
                begin
                    if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
                        begin
                            // slave is ready to accept write address when
                            // there is a valid write address and write data
                            // on the write address and data bus. This design
                            // expects no outstanding transactions.
                            axi_awready <= 1'b1;
                            aw_en       <= 1'b0;
                        end
                    else if (S_AXI_BREADY && axi_bvalid)
                        begin
                            aw_en       <= 1'b1;
                            axi_awready <= 1'b0;
                        end
                    else
                        begin
                            axi_awready <= 1'b0;
                        end
                end
        end

    // Implement axi_awaddr latching
    // This process is used to latch the address when both
    // S_AXI_AWVALID and S_AXI_WVALID are valid.

    always @( posedge S_AXI_ACLK )
        begin
            if ( S_AXI_ARESETN == 1'b0 )
                begin
                    axi_awaddr <= 0;
                end
            else
                begin
                    if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
                        begin
                            // Write Address latching
                            axi_awaddr <= S_AXI_AWADDR;
                        end
                end
        end

    // Implement axi_wready generation
    // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
    // de-asserted when reset is low.

    always @( posedge S_AXI_ACLK )
        begin
            if ( S_AXI_ARESETN == 1'b0 )
                begin
                    axi_wready <= 1'b0;
                end
            else
                begin
                    if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
                        begin
                            // slave is ready to accept write data when
                            // there is a valid write address and write data
                            // on the write address and data bus. This design
                            // expects no outstanding transactions.
                            axi_wready <= 1'b1;
                        end
                    else
                        begin
                            axi_wready <= 1'b0;
                        end
                end
        end

    // Implement memory mapped register select and write logic generation
    // The write data is accepted and written to memory mapped registers when
    // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    // select byte enables of slave registers while writing.
    // These registers are cleared when reset (active low) is applied.
    // Slave register write enable is asserted when valid address and data are available
    // and the slave is ready to accept the write address and write data.
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @( posedge S_AXI_ACLK )
        begin
            if ( S_AXI_ARESETN == 1'b0 )
                begin
                    slv_reg0   <= 0;
                    slv_reg1   <= 0;
                    // slv_reg2  <= 0;
                    slv_reg3   <= 0;
                    slv_reg4   <= 0;
                    // slv_reg5  <= 0;
                    // slv_reg6  <= 0;
                     slv_reg7  <= 0;
                     slv_reg8  <= 0;
                    // slv_reg9  <= 0;
                    // slv_reg10 <= 0;
                    // slv_reg11 <= 0;
                    // slv_reg12 <= 0;
                    // slv_reg13 <= 0;
                    // slv_reg14 <= 0;
                    // slv_reg15 <= 0;
                    // slv_reg16 <= 0;
                    // slv_reg17 <= 0;
                    // slv_reg18 <= 0;
                    // slv_reg19 <= 0;
                     slv_reg20 <= 0;
                     slv_reg21 <= 0;
//                    slv_reg22  <= 0;
                    // slv_reg23  <= 0;
                    // slv_reg24  <= 0;
                    // slv_reg25  <= 0;
                    // slv_reg26  <= 0;
                    // slv_reg27  <= 0;
                    // slv_reg28  <= 0;
                    // slv_reg29  <= 0;
                    // slv_reg30  <= 0;
                    // slv_reg31  <= 0;
                    // slv_reg32  <= 0;
                    // slv_reg33  <= 0;
                    slv_reg34  <= 0;
                    slv_reg35  <= 0;
                    slv_reg36  <= 0;
                    slv_reg37  <= 0;
                    slv_reg38  <= 0;
                    slv_reg39  <= 0;
                    slv_reg40  <= 0;
                    slv_reg41  <= 0;
                    // slv_reg42 <= 0;
                    slv_reg43  <= 0;
                    slv_reg44  <= 0;
                    // slv_reg45 <= 0;
                    // slv_reg46 <= 0;
                     slv_reg47 <= 0;
                     slv_reg48 <= 0;
                    // slv_reg49 <= 0;
                    // slv_reg50 <= 0;
                    // slv_reg51 <= 0;
                    // slv_reg52 <= 0;
                    // slv_reg53 <= 0;
                    // slv_reg54 <= 0;
                    // slv_reg55 <= 0;
                    // slv_reg56 <= 0;
                    // slv_reg57 <= 0;
                    // slv_reg58 <= 0;
                    // slv_reg59 <= 0;
                     slv_reg60 <= 0;
                     slv_reg61 <= 0;
//                    slv_reg62  <= 0;
//                    slv_reg63  <= 0;
//                    slv_reg64  <= 0;
//                    slv_reg65  <= 0;
                    slv_reg66  <= 0;
                    slv_reg67  <= 0;
                    slv_reg68  <= 0;
                    slv_reg69  <= 0;
                    slv_reg70  <= 0;
                    slv_reg71  <= 0;
                    slv_reg72  <= 0;
                    slv_reg73  <= 0;
                    slv_reg74  <= 0;
                    slv_reg75  <= 0;
                    slv_reg76  <= 0;
                    slv_reg77  <= 0;
                    slv_reg78  <= 0;
                    slv_reg79  <= 0;
                    slv_reg80  <= 0;
                    slv_reg81  <= 0;
                    // slv_reg82 <= 0;
                    slv_reg83  <= 0;
                    slv_reg84  <= 0;
                    // slv_reg85 <= 0;
                    // slv_reg86 <= 0;
                     slv_reg87 <= 0;
                     slv_reg88 <= 0;
                    // slv_reg89 <= 0;
                    // slv_reg90 <= 0;
                    // slv_reg91 <= 0;
                    // slv_reg92 <= 0;
                    // slv_reg93 <= 0;
                    // slv_reg94 <= 0;
                    // slv_reg95 <= 0;
                    // slv_reg96 <= 0;
                    // slv_reg97 <= 0;
                    // slv_reg98 <= 0;
                    // slv_reg99 <= 0;
                     slv_reg100 <= 0;
                     slv_reg101 <= 0;
//                    slv_reg102 <= 0;
//                    slv_reg103 <= 0;
//                    slv_reg104 <= 0;
//                    slv_reg105 <= 0;
                    slv_reg106 <= 0;
                    slv_reg107 <= 0;
                    slv_reg108 <= 0;
                    slv_reg109 <= 0;
                    slv_reg110 <= 0;
                    slv_reg111 <= 0;
                    slv_reg112 <= 0;
                    slv_reg113 <= 0;
                    slv_reg114 <= 0;
                    slv_reg115 <= 0;
                    slv_reg116 <= 0;
                    slv_reg117 <= 0;
                    slv_reg118 <= 0;
                    slv_reg119 <= 0;
                    slv_reg120 <= 0;
                    slv_reg121 <= 0;
                    // slv_reg122 <= 0;
                    slv_reg123 <= 0;
                    slv_reg124 <= 0;
                    // slv_reg125 <= 0;
                    // slv_reg126 <= 0;
                     slv_reg127 <= 0;
                     slv_reg128 <= 0;
                    // slv_reg129 <= 0;
                    // slv_reg130 <= 0;
                    // slv_reg131 <= 0;
                    // slv_reg132 <= 0;
                    // slv_reg133 <= 0;
                    // slv_reg134 <= 0;
                    // slv_reg135 <= 0;
                    // slv_reg136 <= 0;
                    // slv_reg137 <= 0;
                    // slv_reg138 <= 0;
                    // slv_reg139 <= 0;
                     slv_reg140 <= 0;
                     slv_reg141 <= 0;
//                    slv_reg142 <= 0;
//                    slv_reg143 <= 0;
//                    slv_reg144 <= 0;
//                    slv_reg145 <= 0;
                    slv_reg146 <= 0;
                    slv_reg147 <= 0;
                    slv_reg148 <= 0;
                    slv_reg149 <= 0;
                    slv_reg150 <= 0;
                    slv_reg151 <= 0;
                    slv_reg152 <= 0;
                    slv_reg153 <= 0;
                    slv_reg154 <= 0;
                    slv_reg155 <= 0;
                    slv_reg156 <= 0;
                    slv_reg157 <= 0;
                    slv_reg158 <= 0;
                    slv_reg159 <= 0;
                    slv_reg160 <= 0;
                    slv_reg161 <= 0;
                    // slv_reg162 <= 0;
                    slv_reg163 <= 0;
                    slv_reg164 <= 0;
                    // slv_reg165 <= 0;
                    // slv_reg166 <= 0;
                     slv_reg167 <= 0;
                     slv_reg168 <= 0;
                    // slv_reg169 <= 0;
                    // slv_reg170 <= 0;
                    // slv_reg171 <= 0;
                    // slv_reg172 <= 0;
                    // slv_reg173 <= 0;
                    // slv_reg174 <= 0;
                    // slv_reg175 <= 0;
                    // slv_reg176 <= 0;
                    // slv_reg177 <= 0;
                    // slv_reg178 <= 0;
                    // slv_reg179 <= 0;
                     slv_reg180 <= 0;
                     slv_reg181 <= 0;
//                    slv_reg182 <= 0;
//                    slv_reg183 <= 0;
//                    slv_reg184 <= 0;
//                    slv_reg185 <= 0;
                    slv_reg186 <= 0;
                    slv_reg187 <= 0;
                    slv_reg188 <= 0;
                    slv_reg189 <= 0;
                    slv_reg190 <= 0;
                    slv_reg191 <= 0;
                    slv_reg192 <= 0;
                    slv_reg193 <= 0;
                    slv_reg194 <= 0;
                    slv_reg195 <= 0;
                    slv_reg196 <= 0;
                    slv_reg197 <= 0;
                    slv_reg198 <= 0;
                    slv_reg199 <= 0;
                    slv_reg200 <= 0;
                    slv_reg201 <= 0;
                    // slv_reg202 <= 0;
                    slv_reg203 <= 0;
                    slv_reg204 <= 0;
                    // slv_reg205 <= 0;
                    // slv_reg206 <= 0;
                     slv_reg207 <= 0;
                     slv_reg208 <= 0;
                    // slv_reg209 <= 0;
                    // slv_reg210 <= 0;
                    // slv_reg211 <= 0;
                    // slv_reg212 <= 0;
                    // slv_reg213 <= 0;
                    // slv_reg214 <= 0;
                    // slv_reg215 <= 0;
                    // slv_reg216 <= 0;
                    // slv_reg217 <= 0;
                    // slv_reg218 <= 0;
                    // slv_reg219 <= 0;
                     slv_reg220 <= 0;
                     slv_reg221 <= 0;
//                    slv_reg222 <= 0;
//                    slv_reg223 <= 0;
//                    slv_reg224 <= 0;
//                    slv_reg225 <= 0;
                    slv_reg226 <= 0;
                    slv_reg227 <= 0;
                    slv_reg228 <= 0;
                    slv_reg229 <= 0;
                    slv_reg230 <= 0;
                    slv_reg231 <= 0;
                    slv_reg232 <= 0;
                    slv_reg233 <= 0;
                    slv_reg234 <= 0;
                    slv_reg235 <= 0;
                    slv_reg236 <= 0;
                    slv_reg237 <= 0;
                    slv_reg238 <= 0;
                    slv_reg239 <= 0;

                    //æ ¡å‡†æŽ§åˆ¶ï¼Œç»§ç”µå™¨æŽ§åˆ¶å¼?å…?
                    slv_reg240 <= 0;
                    slv_reg241 <= 0;
                    slv_reg242 <= 0;
                    slv_reg243 <= 0;
                    slv_reg244 <= 0;
                    slv_reg245 <= 0;
                    //SYNCå?Œæ­¥ä¿¡å?·
                    slv_reg246 <= 0;
                    slv_reg247 <= 0;
                    slv_reg248 <= 0;
                    slv_reg249 <= 0;
                    slv_reg250 <= 0;
                    slv_reg251 <= 0;
                end
            else begin
                if (slv_reg_wren)
                    begin
                        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
                            8'h00 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 0
                                        slv_reg0[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h01 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 1
                                        slv_reg1[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            // 6'h02 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 2
                            //          slv_reg2[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            8'h03 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 3
                                        slv_reg3[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h04 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 4
                                        slv_reg4[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            // 6'h05 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 5
                            //          slv_reg5[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 6'h06 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 6
                            //          slv_reg6[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                             8'h07 :
                              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                      // Respective byte enables are asserted as per write strobes
                                      // Slave register 7
                                      slv_reg7[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                  end
                             8'h08 :
                              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                      // Respective byte enables are asserted as per write strobes
                                      // Slave register 8
                                      slv_reg8[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                  end
                            // 6'h09 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 9
                            //          slv_reg9[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 6'h0A :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 10
                            //          slv_reg10[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 6'h0B :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 11
                            //          slv_reg11[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 6'h0C :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 12
                            //          slv_reg12[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 6'h0D :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 13
                            //          slv_reg13[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 6'h0E :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 14
                            //          slv_reg14[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 6'h0F :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 15
                            //          slv_reg15[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 6'h10 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 16
                            //          slv_reg16[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 6'h11 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 17
                            //          slv_reg17[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 6'h12 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 18
                            //          slv_reg18[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 6'h13 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 19
                            //          slv_reg19[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                             6'h14 :
                              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                      // Respective byte enables are asserted as per write strobes
                                      // Slave register 20
                                      slv_reg20[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                  end
                             6'h15 :
                              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                      // Respective byte enables are asserted as per write strobes
                                      // Slave register 21
                                      slv_reg21[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                  end
//                            8'h16 :
//                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
//                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
//                                        // Respective byte enables are asserted as per write strobes
//                                        // Slave register 22
//                                        slv_reg22[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
//                                    end
                            // 8'h17 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 23
                            //          slv_reg23[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h18 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 24
                            //          slv_reg24[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h19 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 25
                            //          slv_reg25[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h1A :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 26
                            //          slv_reg26[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h1B :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 27
                            //          slv_reg27[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h1C :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 28
                            //          slv_reg28[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h1D :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 29
                            //          slv_reg29[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h1E :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 30
                            //          slv_reg30[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h1F :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 31
                            //          slv_reg31[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h20 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 32
                            //          slv_reg32[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h21 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 33
                            //          slv_reg33[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            8'h22 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 34
                                        slv_reg34[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h23 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 35
                                        slv_reg35[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h24 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 36
                                        slv_reg36[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h25 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 37
                                        slv_reg37[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h26 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 38
                                        slv_reg38[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h27 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 39
                                        slv_reg39[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h28 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 40
                                        slv_reg40[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h29 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 41
                                        slv_reg41[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            // 6'h2A :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 42
                            //          slv_reg42[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            // end
                            8'h2B :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 43
                                        slv_reg43[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h2C :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 44
                                        slv_reg44[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            // 8'h2D :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 45
                            //          slv_reg45[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h2E :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 46
                            //          slv_reg46[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                             8'h2F :
                              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                      // Respective byte enables are asserted as per write strobes
                                      // Slave register 47
                                      slv_reg47[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                  end
                             8'h30 :
                              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                      // Respective byte enables are asserted as per write strobes
                                      // Slave register 48
                                      slv_reg48[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                  end
                            // 8'h31 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 49
                            //          slv_reg49[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h32 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 50
                            //          slv_reg50[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h33 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 51
                            //          slv_reg51[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h34 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 52
                            //          slv_reg52[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h35 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 53
                            //          slv_reg53[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h36 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 54
                            //          slv_reg54[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h37 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 55
                            //          slv_reg55[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h38 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 56
                            //          slv_reg56[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h39 :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 57
                            //          slv_reg57[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h3A :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 58
                            //          slv_reg58[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                            // 8'h3B :
                            //  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                            //      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            //          // Respective byte enables are asserted as per write strobes
                            //          // Slave register 59
                            //          slv_reg59[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            //      end
                             8'h3C :
                              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                      // Respective byte enables are asserted as per write strobes
                                      // Slave register 60
                                      slv_reg60[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                  end
                             8'h3D :
                              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                      // Respective byte enables are asserted as per write strobes
                                      // Slave register 61
                                      slv_reg61[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                  end
//                            8'h3E :
//                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
//                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
//                                        // Respective byte enables are asserted as per write strobes
//                                        // Slave register 62
//                                        slv_reg62[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
//                                    end
//                            8'h3F :
//                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
//                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
//                                        // Respective byte enables are asserted as per write strobes
//                                        // Slave register 63
//                                        slv_reg63[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
//                                    end
                            8'h50 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg80[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h51 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg81[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h53 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg83[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h54 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg84[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                             8'h57 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg87[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                             8'h58 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg88[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end    
                             8'h64 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg100[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                             8'h65 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg101[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end                                                                                                   
                            8'h78 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg120[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h79 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg121[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h7B :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg123[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h7C :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg124[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'h7F :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg127[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                             8'h80 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg128[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end    
                             8'h8C :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg140[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                             8'h8D :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg141[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end                                                                                                             
                            8'hA0 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg160[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hA1 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg161[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hA3 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg163[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hA4 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg164[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                             8'hA7 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg167[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                              8'hA8 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg168[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                              8'hB4 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg180[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                              8'hB5 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg181[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end                                                                                                          
                            8'hC8 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg200[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hC9 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg201[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hCB :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg203[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hCC :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg204[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                             8'hCF :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg207[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end                                   
                            8'hD0 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg208[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                              8'hDC :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg220[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end                                   
                             8'hDD :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg221[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end                                   
                            //æ ¡å‡†æŽ§åˆ¶ï¼Œç»§ç”µå™¨æŽ§åˆ¶å¼?å…?
                            8'hF0 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg240[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end

                            8'hF1 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg241[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hF2 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg242[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hF3 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg243[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hF4 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg244[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hF5 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg245[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            //SYNCå?Œæ­¥ä¿¡å?·
                            8'hF6 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg246[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hF7 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg247[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hF8 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg248[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hF9 :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg249[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hFA :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg250[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            8'hFB :
                                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                        // Respective byte enables are asserted as per write strobes
                                        // Slave register 63
                                        slv_reg251[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                    end
                            default : begin
                                slv_reg0   <= slv_reg0;
                                slv_reg1   <= slv_reg1;
                                // slv_reg2  <= slv_reg2;
                                slv_reg3   <= slv_reg3;
                                slv_reg4   <= slv_reg4;
                                // slv_reg5  <= slv_reg5 ;
                                // slv_reg6  <= slv_reg6 ;
                                 slv_reg7  <= slv_reg7 ;
                                 slv_reg8  <= slv_reg8 ;
                                // slv_reg9  <= slv_reg9 ;
                                // slv_reg10 <= slv_reg10;
                                // slv_reg11 <= slv_reg11;
                                // slv_reg12 <= slv_reg12;
                                // slv_reg13 <= slv_reg13;
                                // slv_reg14 <= slv_reg14;
                                // slv_reg15 <= slv_reg15;
                                // slv_reg16 <= slv_reg16;
                                // slv_reg17 <= slv_reg17;
                                // slv_reg18 <= slv_reg18;
                                // slv_reg19 <= slv_reg19;
                                 slv_reg20 <= slv_reg20;
                                 slv_reg21 <= slv_reg21;
//                                slv_reg22  <= slv_reg22;
                                // slv_reg23  <= slv_reg23;
                                // slv_reg24  <= slv_reg24;
                                // slv_reg25  <= slv_reg25;
                                // slv_reg26  <= slv_reg26;
                                // slv_reg27  <= slv_reg27;
                                // slv_reg28  <= slv_reg28;
                                // slv_reg29  <= slv_reg29;
                                // slv_reg30  <= slv_reg30;
                                // slv_reg31  <= slv_reg31;
                                // slv_reg32  <= slv_reg32;
                                // slv_reg33  <= slv_reg33;
                                slv_reg34  <= slv_reg34;
                                slv_reg35  <= slv_reg35;
                                slv_reg36  <= slv_reg36;
                                slv_reg37  <= slv_reg37;
                                slv_reg38  <= slv_reg38;
                                slv_reg39  <= slv_reg39;
                                slv_reg40  <= slv_reg40;
                                slv_reg41  <= slv_reg41;
                                // slv_reg42 <= slv_reg42;
                                slv_reg43  <= slv_reg43;
                                slv_reg44  <= slv_reg44;
                                // slv_reg45 <= slv_reg45;
                                // slv_reg46 <= slv_reg46;
                                 slv_reg47 <= slv_reg47;
                                 slv_reg48 <= slv_reg48;
                                // slv_reg49 <= slv_reg49;
                                // slv_reg50 <= slv_reg50;
                                // slv_reg51 <= slv_reg51;
                                // slv_reg52 <= slv_reg52;
                                // slv_reg53 <= slv_reg53;
                                // slv_reg54 <= slv_reg54;
                                // slv_reg55 <= slv_reg55;
                                // slv_reg56 <= slv_reg56;
                                // slv_reg57 <= slv_reg57;
                                // slv_reg58 <= slv_reg58;
                                // slv_reg59 <= slv_reg59;
                                 slv_reg60 <= slv_reg60;
                                 slv_reg61 <= slv_reg61;
//                                slv_reg62  <= slv_reg62;
//                                slv_reg63  <= slv_reg63;
//                                slv_reg64  <= slv_reg64;
//                                slv_reg65  <= slv_reg65;
                                slv_reg66  <= slv_reg66;
                                slv_reg67  <= slv_reg67;
                                slv_reg68  <= slv_reg68;
                                slv_reg69  <= slv_reg69;
                                slv_reg70  <= slv_reg70;
                                slv_reg71  <= slv_reg71;
                                slv_reg72  <= slv_reg72;
                                slv_reg73  <= slv_reg73;
                                slv_reg74  <= slv_reg74;
                                slv_reg75  <= slv_reg75;
                                slv_reg76  <= slv_reg76;
                                slv_reg77  <= slv_reg77;
                                slv_reg78  <= slv_reg78;
                                slv_reg79  <= slv_reg79;
                                slv_reg80  <= slv_reg80;
                                slv_reg81  <= slv_reg81;
                                // slv_reg82 <= slv_reg82;
                                slv_reg83  <= slv_reg83;
                                slv_reg84  <= slv_reg84;
                                // slv_reg85 <= slv_reg85 ;
                                // slv_reg86 <= slv_reg86 ;
                                 slv_reg87 <= slv_reg87 ;
                                 slv_reg88 <= slv_reg88 ;
                                // slv_reg89 <= slv_reg89 ;
                                // slv_reg90 <= slv_reg90 ;
                                // slv_reg91 <= slv_reg91 ;
                                // slv_reg92 <= slv_reg92 ;
                                // slv_reg93 <= slv_reg93 ;
                                // slv_reg94 <= slv_reg94 ;
                                // slv_reg95 <= slv_reg95 ;
                                // slv_reg96 <= slv_reg96 ;
                                // slv_reg97 <= slv_reg97 ;
                                // slv_reg98 <= slv_reg98 ;
                                // slv_reg99 <= slv_reg99 ;
                                 slv_reg100 <= slv_reg100;
                                 slv_reg101 <= slv_reg101;
//                                slv_reg102 <= slv_reg102;
//                                slv_reg103 <= slv_reg103;
//                                slv_reg104 <= slv_reg104;
//                                slv_reg105 <= slv_reg105;
                                slv_reg106 <= slv_reg106;
                                slv_reg107 <= slv_reg107;
                                slv_reg108 <= slv_reg108;
                                slv_reg109 <= slv_reg109;
                                slv_reg110 <= slv_reg110;
                                slv_reg111 <= slv_reg111;
                                slv_reg112 <= slv_reg112;
                                slv_reg113 <= slv_reg113;
                                slv_reg114 <= slv_reg114;
                                slv_reg115 <= slv_reg115;
                                slv_reg116 <= slv_reg116;
                                slv_reg117 <= slv_reg117;
                                slv_reg118 <= slv_reg118;
                                slv_reg119 <= slv_reg119;
                                slv_reg120 <= slv_reg120;
                                slv_reg121 <= slv_reg121;
                                // slv_reg122 <= slv_reg122;
                                slv_reg123 <= slv_reg123;
                                slv_reg124 <= slv_reg124;
                                // slv_reg125 <= slv_reg125;
                                // slv_reg126 <= slv_reg126;
                                 slv_reg127 <= slv_reg127;
                                 slv_reg128 <= slv_reg128;
                                // slv_reg129 <= slv_reg129;
                                // slv_reg130 <= slv_reg130;
                                // slv_reg131 <= slv_reg131;
                                // slv_reg132 <= slv_reg132;
                                // slv_reg133 <= slv_reg133;
                                // slv_reg134 <= slv_reg134;
                                // slv_reg135 <= slv_reg135;
                                // slv_reg136 <= slv_reg136;
                                // slv_reg137 <= slv_reg137;
                                // slv_reg138 <= slv_reg138;
                                // slv_reg139 <= slv_reg139;
                                 slv_reg140 <= slv_reg140;
                                 slv_reg141 <= slv_reg141;
//                                slv_reg142 <= slv_reg142;
//                                slv_reg143 <= slv_reg143;
//                                slv_reg144 <= slv_reg144;
//                                slv_reg145 <= slv_reg145;
                                slv_reg146 <= slv_reg146;
                                slv_reg147 <= slv_reg147;
                                slv_reg148 <= slv_reg148;
                                slv_reg149 <= slv_reg149;
                                slv_reg150 <= slv_reg150;
                                slv_reg151 <= slv_reg151;
                                slv_reg152 <= slv_reg152;
                                slv_reg153 <= slv_reg153;
                                slv_reg154 <= slv_reg154;
                                slv_reg155 <= slv_reg155;
                                slv_reg156 <= slv_reg156;
                                slv_reg157 <= slv_reg157;
                                slv_reg158 <= slv_reg158;
                                slv_reg159 <= slv_reg159;
                                slv_reg160 <= slv_reg160;
                                slv_reg161 <= slv_reg161;
                                // slv_reg162 <= slv_reg162;
                                slv_reg163 <= slv_reg163;
                                slv_reg164 <= slv_reg164;
                                // slv_reg165 <= slv_reg165;
                                // slv_reg166 <= slv_reg166;
                                 slv_reg167 <= slv_reg167;
                                 slv_reg168 <= slv_reg168;
                                // slv_reg169 <= slv_reg169;
                                // slv_reg170 <= slv_reg170;
                                // slv_reg171 <= slv_reg171;
                                // slv_reg172 <= slv_reg172;
                                // slv_reg173 <= slv_reg173;
                                // slv_reg174 <= slv_reg174;
                                // slv_reg175 <= slv_reg175;
                                // slv_reg176 <= slv_reg176;
                                // slv_reg177 <= slv_reg177;
                                // slv_reg178 <= slv_reg178;
                                // slv_reg179 <= slv_reg179;
                                 slv_reg180 <= slv_reg180;
                                 slv_reg181 <= slv_reg181;
//                                slv_reg182 <= slv_reg182;
//                                slv_reg183 <= slv_reg183;
//                                slv_reg184 <= slv_reg184;
//                                slv_reg185 <= slv_reg185;
                                slv_reg186 <= slv_reg186;
                                slv_reg187 <= slv_reg187;
                                slv_reg188 <= slv_reg188;
                                slv_reg189 <= slv_reg189;
                                slv_reg190 <= slv_reg190;
                                slv_reg191 <= slv_reg191;
                                slv_reg192 <= slv_reg192;
                                slv_reg193 <= slv_reg193;
                                slv_reg194 <= slv_reg194;
                                slv_reg195 <= slv_reg195;
                                slv_reg196 <= slv_reg196;
                                slv_reg197 <= slv_reg197;
                                slv_reg198 <= slv_reg198;
                                slv_reg199 <= slv_reg199;
                                slv_reg200 <= slv_reg200;
                                slv_reg201 <= slv_reg201;
                                // slv_reg202 <= slv_reg202;
                                slv_reg203 <= slv_reg203;
                                slv_reg204 <= slv_reg204;
                                // slv_reg205 <= slv_reg205;
                                // slv_reg206 <= slv_reg206;
                                 slv_reg207 <= slv_reg207;
                                 slv_reg208 <= slv_reg208;
                                // slv_reg209 <= slv_reg209;
                                // slv_reg210 <= slv_reg210;
                                // slv_reg211 <= slv_reg211;
                                // slv_reg212 <= slv_reg212;
                                // slv_reg213 <= slv_reg213;
                                // slv_reg214 <= slv_reg214;
                                // slv_reg215 <= slv_reg215;
                                // slv_reg216 <= slv_reg216;
                                // slv_reg217 <= slv_reg217;
                                // slv_reg218 <= slv_reg218;
                                // slv_reg219 <= slv_reg219;
                                 slv_reg220 <= slv_reg220;
                                 slv_reg221 <= slv_reg221;
//                                slv_reg222 <= slv_reg222;
//                                slv_reg223 <= slv_reg223;
//                                slv_reg224 <= slv_reg224;
//                                slv_reg225 <= slv_reg225;
                                slv_reg226 <= slv_reg226;
                                slv_reg227 <= slv_reg227;
                                slv_reg228 <= slv_reg228;
                                slv_reg229 <= slv_reg229;
                                slv_reg230 <= slv_reg230;
                                slv_reg231 <= slv_reg231;
                                slv_reg232 <= slv_reg232;
                                slv_reg233 <= slv_reg233;
                                slv_reg234 <= slv_reg234;
                                slv_reg235 <= slv_reg235;
                                slv_reg236 <= slv_reg236;
                                slv_reg237 <= slv_reg237;
                                slv_reg238 <= slv_reg238;
                                slv_reg239 <= slv_reg239;
                                //æ ¡å‡†æŽ§åˆ¶ï¼Œç»§ç”µå™¨æŽ§åˆ¶å¼?å…?
                                slv_reg240 <= slv_reg240;
                                slv_reg241 <= slv_reg241;
                                slv_reg242 <= slv_reg242;
                                slv_reg243 <= slv_reg243;
                                slv_reg244 <= slv_reg244;
                                slv_reg245 <= slv_reg245;
                                //SYNCå?Œæ­¥ä¿¡å?·
                                slv_reg246 <= slv_reg246;
                                slv_reg247 <= slv_reg247;
                                slv_reg248 <= slv_reg248;
                                slv_reg249 <= slv_reg249;
                                slv_reg250 <= slv_reg250;
                                slv_reg251 <= slv_reg251;
                            end
                        endcase
                    end
            end
        end

    // Implement write response logic generation
    // The write response and response valid signals are asserted by the slave
    // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
    // This marks the acceptance of address and indicates the status of
    // write transaction.

    always @( posedge S_AXI_ACLK )
        begin
            if ( S_AXI_ARESETN == 1'b0 )
                begin
                    axi_bvalid <= 0;
                    axi_bresp  <= 2'b0;
                end
            else
                begin
                    if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
                        begin
                            // indicates a valid write response is available
                            axi_bvalid <= 1'b1;
                            axi_bresp  <= 2'b0; // 'OKAY' response
                        end                   // work error responses in future
                    else
                        begin
                            if (S_AXI_BREADY && axi_bvalid)
                                //check if bready is asserted while bvalid is high)
                                //(there is a possibility that bready is always asserted high)
                                begin
                                    axi_bvalid <= 1'b0;
                                end
                        end
                end
        end

    // Implement axi_arready generation
    // axi_arready is asserted for one S_AXI_ACLK clock cycle when
    // S_AXI_ARVALID is asserted. axi_awready is
    // de-asserted when reset (active low) is asserted.
    // The read address is also latched when S_AXI_ARVALID is
    // asserted. axi_araddr is reset to zero on reset assertion.

    always @( posedge S_AXI_ACLK )
        begin
            if ( S_AXI_ARESETN == 1'b0 )
                begin
                    axi_arready <= 1'b0;
                    axi_araddr  <= 32'b0;
                end
            else
                begin
                    if (~axi_arready && S_AXI_ARVALID)
                        begin
                            // indicates that the slave has acceped the valid read address
                            axi_arready <= 1'b1;
                            // Read address latching
                            axi_araddr  <= S_AXI_ARADDR;
                        end
                    else
                        begin
                            axi_arready <= 1'b0;
                        end
                end
        end

    // Implement axi_arvalid generation
    // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_ARVALID and axi_arready are asserted. The slave registers
    // data are available on the axi_rdata bus at this instance. The
    // assertion of axi_rvalid marks the validity of read data on the
    // bus and axi_rresp indicates the status of read transaction.axi_rvalid
    // is deasserted on reset (active low). axi_rresp and axi_rdata are
    // cleared to zero on reset (active low).
    always @( posedge S_AXI_ACLK )
        begin
            if ( S_AXI_ARESETN == 1'b0 )
                begin
                    axi_rvalid <= 0;
                    axi_rresp  <= 0;
                end
            else
                begin
                    if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
                        begin
                            // Valid read data is available at the read data bus
                            axi_rvalid <= 1'b1;
                            axi_rresp  <= 2'b0; // 'OKAY' response
                        end
                    else if (axi_rvalid && S_AXI_RREADY)
                        begin
                            // Read data is accepted by the master
                            axi_rvalid <= 1'b0;
                        end
                end
        end

    // Implement memory mapped register select and read logic generation
    // Slave register read enable is asserted when valid address is available
    // and the slave is ready to accept the read address.
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
    always @(*)
        begin
            // Address decoding for reading registers
            case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
                //0 AD_Board
                // 6'h00   : reg_data_out <= slv_reg0;
                // 6'h01   : reg_data_out <= slv_reg1;
                8'h02 : reg_data_out <= slv_reg2;
                // 6'h03   : reg_data_out <= slv_reg3;
                // 6'h04   : reg_data_out <= slv_reg4;
                8'h05 : reg_data_out <= slv_reg5;
                8'h06 : reg_data_out <= slv_reg6;
//                8'h07 : reg_data_out <= slv_reg7;
//                8'h08 : reg_data_out <= slv_reg8;
                8'h09 : reg_data_out <= slv_reg9;
                8'h0A : reg_data_out <= slv_reg10;
                8'h0B : reg_data_out <= slv_reg11;
                8'h0C : reg_data_out <= slv_reg12;
                8'h0D : reg_data_out <= slv_reg13;
                8'h0E : reg_data_out <= slv_reg14;
                8'h0F : reg_data_out <= slv_reg15;
                8'h10 : reg_data_out <= slv_reg16;
                8'h11 : reg_data_out <= slv_reg17;
                8'h12 : reg_data_out <= slv_reg18;
                8'h13 : reg_data_out <= slv_reg19;
//                8'h14 : reg_data_out <= slv_reg20;
//                8'h15 : reg_data_out <= slv_reg21;
                 //RTD data 
                 8'h16   : reg_data_out <= slv_reg22;
                 8'h17   : reg_data_out <= slv_reg23;
                 8'h18   : reg_data_out <= slv_reg24;
                 8'h19   : reg_data_out <= slv_reg25;
                 8'h1A   : reg_data_out <= slv_reg26;
                 8'h1B   : reg_data_out <= slv_reg27;
                 8'h1C   : reg_data_out <= slv_reg28;
                 8'h1D   : reg_data_out <= slv_reg29;
                 8'h1E   : reg_data_out <= slv_reg30;
                 8'h1F   : reg_data_out <= slv_reg31;
                 8'h20   : reg_data_out <= slv_reg32;
                 8'h21   : reg_data_out <= slv_reg33;
                // 6'h22   : reg_data_out <= slv_reg34;
                // 6'h23   : reg_data_out <= slv_reg35;
                // 6'h24   : reg_data_out <= slv_reg36;
                // 6'h25   : reg_data_out <= slv_reg37;
                // 6'h26   : reg_data_out <= slv_reg38;
                // 6'h27   : reg_data_out <= slv_reg39;
                // 6'h28   : reg_data_out <= slv_reg40;
                // 6'h29   : reg_data_out <= slv_reg41;

                // 1 AD_Board
                8'h2A : reg_data_out <= slv_reg42;
                // 6'h2B   : reg_data_out <= slv_reg43;
                // 6'h2C   : reg_data_out <= slv_reg44;
                8'h2D : reg_data_out <= slv_reg45;
                8'h2E : reg_data_out <= slv_reg46;
//                8'h2F : reg_data_out <= slv_reg47;
//                8'h30 : reg_data_out <= slv_reg48;
                8'h31 : reg_data_out <= slv_reg49;
                8'h32 : reg_data_out <= slv_reg50;
                8'h33 : reg_data_out <= slv_reg51;
                8'h34 : reg_data_out <= slv_reg52;
                8'h35 : reg_data_out <= slv_reg53;
                8'h36 : reg_data_out <= slv_reg54;
                8'h37 : reg_data_out <= slv_reg55;
                8'h38 : reg_data_out <= slv_reg56;
                8'h39 : reg_data_out <= slv_reg57;
                8'h3A : reg_data_out <= slv_reg58;
                8'h3B : reg_data_out <= slv_reg59;
//                8'h3C : reg_data_out <= slv_reg60;
//                8'h3D : reg_data_out <= slv_reg61;
                 8'h3E   : reg_data_out <= slv_reg62;
                 8'h3F   : reg_data_out <= slv_reg63;               
                 8'h40   : reg_data_out <= slv_reg64;                 
                 8'h41   : reg_data_out <= slv_reg65;

                // 2 AD_Board
                8'h52 : reg_data_out <= slv_reg82;
                8'h55 : reg_data_out <= slv_reg85;
                8'h56 : reg_data_out <= slv_reg86;
//                8'h57 : reg_data_out <= slv_reg87;
//                8'h58 : reg_data_out <= slv_reg88;
                8'h59 : reg_data_out <= slv_reg89;
                8'h5A : reg_data_out <= slv_reg90;
                8'h5B : reg_data_out <= slv_reg91;
                8'h5C : reg_data_out <= slv_reg92;
                8'h5D : reg_data_out <= slv_reg93;
                8'h5E : reg_data_out <= slv_reg94;
                8'h5F : reg_data_out <= slv_reg95;
                8'h60 : reg_data_out <= slv_reg96;
                8'h61 : reg_data_out <= slv_reg97;
                8'h62 : reg_data_out <= slv_reg98;
                8'h63 : reg_data_out <= slv_reg99;
//                8'h64 : reg_data_out <= slv_reg100;
//                8'h65 : reg_data_out <= slv_reg101;
                8'h66 : reg_data_out <= slv_reg102;
                8'h67 : reg_data_out <= slv_reg103;                
                8'h68 : reg_data_out <= slv_reg104;
                8'h69 : reg_data_out <= slv_reg105;
                
                // 3 AD_Board
                8'h7A : reg_data_out <= slv_reg122;
                8'h7D : reg_data_out <= slv_reg125;
                8'h7E : reg_data_out <= slv_reg126;
//                8'h7F : reg_data_out <= slv_reg127;
//                8'h80 : reg_data_out <= slv_reg128;
                8'h81 : reg_data_out <= slv_reg129;
                8'h82 : reg_data_out <= slv_reg130;
                8'h83 : reg_data_out <= slv_reg131;
                8'h84 : reg_data_out <= slv_reg132;
                8'h85 : reg_data_out <= slv_reg133;
                8'h86 : reg_data_out <= slv_reg134;
                8'h87 : reg_data_out <= slv_reg135;
                8'h88 : reg_data_out <= slv_reg136;
                8'h89 : reg_data_out <= slv_reg137;
                8'h8A : reg_data_out <= slv_reg138;
                8'h8B : reg_data_out <= slv_reg139;
//                8'h8C : reg_data_out <= slv_reg140;
//                8'h8D : reg_data_out <= slv_reg141;
                8'h8E : reg_data_out <= slv_reg142;
                8'h8F : reg_data_out <= slv_reg143;
                8'h90 : reg_data_out <= slv_reg144;
                8'h91 : reg_data_out <= slv_reg145;               
                
                // 4 AD_Board
                8'hA2 : reg_data_out <= slv_reg162;
                8'hA5 : reg_data_out <= slv_reg165;
                8'hA6 : reg_data_out <= slv_reg166;
//                8'hA7 : reg_data_out <= slv_reg167;
//                8'hA8 : reg_data_out <= slv_reg168;
                8'hA9 : reg_data_out <= slv_reg169;
                8'hAA : reg_data_out <= slv_reg170;
                8'hAB : reg_data_out <= slv_reg171;
                8'hAC : reg_data_out <= slv_reg172;
                8'hAD : reg_data_out <= slv_reg173;
                8'hAE : reg_data_out <= slv_reg174;
                8'hAF : reg_data_out <= slv_reg175;
                8'hB0 : reg_data_out <= slv_reg176;
                8'hB1 : reg_data_out <= slv_reg177;
                8'hB2 : reg_data_out <= slv_reg178;
                8'hB3 : reg_data_out <= slv_reg179;
//                8'hB4 : reg_data_out <= slv_reg180;
//                8'hB5 : reg_data_out <= slv_reg181;
                8'hB6 : reg_data_out <= slv_reg182;
                8'hB7 : reg_data_out <= slv_reg183;
                8'hB8 : reg_data_out <= slv_reg184;
                8'hB9 : reg_data_out <= slv_reg185;

                // 5 AD_Board
                8'hCA : reg_data_out <= slv_reg202;
                8'hCD : reg_data_out <= slv_reg205;
                8'hCE : reg_data_out <= slv_reg206;
//                8'hCF : reg_data_out <= slv_reg207;
//                8'hD0 : reg_data_out <= slv_reg208;
                8'hD1 : reg_data_out <= slv_reg209;
                8'hD2 : reg_data_out <= slv_reg210;
                8'hD3 : reg_data_out <= slv_reg211;
                8'hD4 : reg_data_out <= slv_reg212;
                8'hD5 : reg_data_out <= slv_reg213;
                8'hD6 : reg_data_out <= slv_reg214;
                8'hD7 : reg_data_out <= slv_reg215;
                8'hD8 : reg_data_out <= slv_reg216;
                8'hD9 : reg_data_out <= slv_reg217;
                8'hDA : reg_data_out <= slv_reg218;
                8'hDB : reg_data_out <= slv_reg219;
//                8'hDC : reg_data_out <= slv_reg220;
//                8'hDD : reg_data_out <= slv_reg221;
                8'hDE : reg_data_out <= slv_reg222;
                8'hDF : reg_data_out <= slv_reg223;
                8'hE0 : reg_data_out <= slv_reg224;
                8'hE1 : reg_data_out <= slv_reg225;              
                                
                8'hFD : reg_data_out <= slv_reg253;
                8'hFE : reg_data_out <= slv_reg254;
                
               

                default : reg_data_out <= 0;
            endcase
        end

    // Output register or memory read data
    always @( posedge S_AXI_ACLK )
        begin
            if ( S_AXI_ARESETN == 1'b0 )
                begin
                    axi_rdata <= 0;
                end
            else
                begin
                    // When there is a valid read address (S_AXI_ARVALID) with
                    // acceptance of read address by the slave (axi_arready),
                    // output the read dada
                    if (slv_reg_rden_dy)
                        begin
                            axi_rdata <= reg_data_out;     // register read data
                        end
                end
        end

    // Add user logic here
    //general
    wire rst_1;

    assign rst_1       = (S_AXI_ARESETN && rst);
    assign PL_LED_TEST = 1'b0;

    assign G0_Relay_Ctrl = slv_reg240[0];
    assign G1_Relay_Ctrl = slv_reg241[0];
    assign G2_Relay_Ctrl = slv_reg242[0];
    assign G3_Relay_Ctrl = slv_reg243[0];
    assign G4_Relay_Ctrl = slv_reg244[0];
    assign G5_Relay_Ctrl = slv_reg245[0];

//    assign SYNC   = slv_reg246[0];
//    assign SYNC_1 = slv_reg246[1];
//    assign SYNC_2 = slv_reg246[2];
//    assign SYNC_3 = slv_reg246[3];
//    assign SYNC_4 = slv_reg246[4];
//    assign SYNC_5 = slv_reg246[5];


    //0 AD_Board

    //TC_configure
    wire [3:0] configure_select = slv_reg0[3:0];
    wire [7:0] start_configure  = slv_reg1[7:0];
    wire [7:0] F_configure_stop;
    assign G1_ANA_POW_EN = 1'b1;                
    assign slv_reg2 = {24'd0,F_configure_stop};
    
    //TC_read
    wire start_TC_read = slv_reg4[0];
    wire [31:0] TC_data_count;
    wire [31:0] TC_data;
    wire TC_prog_full;
    wire TC_full;
    wire fifo_TC_rst = slv_reg7[0];
    wire SYNC = slv_reg8[0];
    assign slv_reg9 = {31'd0,TC_prog_full};  
    assign slv_reg10 = {31'd0,TC_full};
    
    wire wr_en_TC;
    
TC_top TC_top_0(
 .PL_clk          (S_AXI_ACLK      ),
 .rst             ( rst_1          ),
 .TC_sdo          (TC_sdo          ),
 .TC_cs_n         (TC_cs_n         ),
 .TC_sclk         (TC_sclk         ), 
 .TC_sdi          (TC_sdi          ), 
 .wr_en           (wr_en_TC        ),
 .TC_data         (TC_data         ),
 .start_rd        (start_TC_read   ),
 .configure_select(configure_select),
 .start_configure (start_configure ),
 .F_configure_stop(F_configure_stop)
);
wire rd_TC;
assign rd_TC = slv_reg_rden && (axi_araddr ==  10'h018);

fifo_generator_1 TC_fifo_0(
.clk          (S_AXI_ACLK  ),
.srst         (fifo_TC_rst ),
.din          (TC_data     ),
.wr_en        (wr_en_TC    ),
.rd_en        (rd_TC       ),
.dout         (slv_reg6    ),        
.full         (TC_full     ),
.almost_full  (),  
.empty        (),
.almost_empty (),  
.data_count   (slv_reg5    ),
.prog_full    (TC_prog_full)
);
    //1 AD_Board

    //é…?ç½®æ?¡ä»¶
    wire [3:0] configure_select_1 = slv_reg40[3:0];
    wire [7:0] start_configure_1  = slv_reg41[7:0];
    wire [7:0] F_configure_stop_1                 ;
    assign G1_ANA_POW_EN_1 = 1'b1;
    assign slv_reg42 = {24'd0,F_configure_stop_1};
    
    //TC_read
    wire start_TC_read_1 = slv_reg44[0];
    wire [31:0] TC_data_count_1;
    wire [31:0] TC_data_1;
    wire TC_prog_full_1;
    wire TC_full_1;
    wire fifo_TC_rst_1 = slv_reg47[0];
    wire SYNC_1 = slv_reg48[0];
    assign slv_reg49 = {31'd0,TC_prog_full_1};  
    assign slv_reg50 = {31'd0,TC_full_1};
    
    wire wr_en_TC_1;
    
TC_top TC_top_1(
 .PL_clk          (S_AXI_ACLK      ),
 .rst             ( rst_1          ),
 .TC_sdo          (TC_sdo_1          ),
 .TC_cs_n         (TC_cs_n_1         ),
 .TC_sclk         (TC_sclk_1         ), 
 .TC_sdi          (TC_sdi_1          ), 
 .wr_en           (wr_en_TC_1        ),
 .TC_data         (TC_data_1         ),
 .start_rd        (start_TC_read_1   ),
 .configure_select(configure_select_1),
 .start_configure (start_configure_1 ),
 .F_configure_stop(F_configure_stop_1)
);
wire rd_TC_1;
assign rd_TC_1 = slv_reg_rden && (axi_araddr ==  10'h0B8);

fifo_generator_1 TC_fifo_1(
.clk          (S_AXI_ACLK  ),
.srst         (fifo_TC_rst_1 ),
.din          (TC_data_1     ),
.wr_en        (wr_en_TC_1    ),
.rd_en        (rd_TC_1       ),
.dout         (slv_reg46    ),        
.full         (TC_full_1     ),
.almost_full  (),  
.empty        (),
.almost_empty (),  
.data_count   (slv_reg45    ),
.prog_full    (TC_prog_full_1)
);

    //2 AD_Board

    //é…?ç½®æ?¡ä»¶
    wire [3:0] configure_select_2 = slv_reg80[3:0];
    wire [7:0] start_configure_2  = slv_reg81[7:0];
    wire [7:0] F_configure_stop_2                 ;
    assign G1_ANA_POW_EN_2 = 1'b1;
    assign slv_reg82 = {24'd0,F_configure_stop_2};
    
    //TC_read
    wire start_TC_read_2 = slv_reg84[0];
    wire [31:0] TC_data_count_2;
    wire [31:0] TC_data_2;
    wire TC_prog_full_2;
    wire TC_full_2;
    wire fifo_TC_rst_2 = slv_reg87[0];
    wire SYNC_2 = slv_reg88[0];
    assign slv_reg89 = {31'd0,TC_prog_full_2};  
    assign slv_reg90 = {31'd0,TC_full_2};
    
    wire wr_en_TC_2;
    
TC_top TC_top_2(
 .PL_clk          (S_AXI_ACLK      ),
 .rst             ( rst_1          ),
 .TC_sdo          (TC_sdo_2          ),
 .TC_cs_n         (TC_cs_n_2         ),
 .TC_sclk         (TC_sclk_2         ), 
 .TC_sdi          (TC_sdi_2          ), 
 .wr_en           (wr_en_TC_2        ),
 .TC_data         (TC_data_2         ),
 .start_rd        (start_TC_read_2   ),
 .configure_select(configure_select_2),
 .start_configure (start_configure_2 ),
 .F_configure_stop(F_configure_stop_2)
);
wire rd_TC_2;
assign rd_TC_2 = slv_reg_rden && (axi_araddr ==  10'h158);

fifo_generator_1 TC_fifo_2(
.clk          (S_AXI_ACLK  ),
.srst         (fifo_TC_rst_2 ),
.din          (TC_data_2     ),
.wr_en        (wr_en_TC_2    ),
.rd_en        (rd_TC_2       ),
.dout         (slv_reg86    ),        
.full         (TC_full_2     ),
.almost_full  (),  
.empty        (),
.almost_empty (),  
.data_count   (slv_reg85    ),
.prog_full    (TC_prog_full_2)
);


    //3 AD_Board

    //é…?ç½®æ?¡ä»¶
    wire [3:0] configure_select_3 = slv_reg120[3:0];
    wire [7:0] start_configure_3  = slv_reg121[7:0];
    wire [7:0] F_configure_stop_3                  ;
    assign G1_ANA_POW_EN_3 = 1'b1;
    assign slv_reg122 = {24'd0,F_configure_stop_3};

    //TC_read
    wire start_TC_read_3 = slv_reg124[0];
    wire [31:0] TC_data_count_3;
    wire [31:0] TC_data_3;
    wire TC_prog_full_3;
    wire TC_full_3;
    wire fifo_TC_rst_3 = slv_reg127[0];
    wire SYNC_3 = slv_reg128[0];
    assign slv_reg129 = {31'd0,TC_prog_full_3};  
    assign slv_reg130 = {31'd0,TC_full_3};
    
    wire wr_en_TC_3;
    
TC_top TC_top_3(
 .PL_clk          (S_AXI_ACLK      ),
 .rst             ( rst_1          ),
 .TC_sdo          (TC_sdo_3          ),
 .TC_cs_n         (TC_cs_n_3         ),
 .TC_sclk         (TC_sclk_3         ), 
 .TC_sdi          (TC_sdi_3          ), 
 .wr_en           (wr_en_TC_3        ),
 .TC_data         (TC_data_3         ),
 .start_rd        (start_TC_read_3   ),
 .configure_select(configure_select_3),
 .start_configure (start_configure_3 ),
 .F_configure_stop(F_configure_stop_3)
);
wire rd_TC_3;
assign rd_TC_3 = slv_reg_rden && (axi_araddr ==  10'h1F8);

fifo_generator_1 TC_fifo_3(
.clk          (S_AXI_ACLK  ),
.srst         (fifo_TC_rst_3 ),
.din          (TC_data_3     ),
.wr_en        (wr_en_TC_3    ),
.rd_en        (rd_TC_3       ),
.dout         (slv_reg126    ),        
.full         (TC_full_3     ),
.almost_full  (),  
.empty        (),
.almost_empty (),  
.data_count   (slv_reg125    ),
.prog_full    (TC_prog_full_3)
);

    //4 AD_Board

    //é…?ç½®æ?¡ä»¶
    wire [3:0] configure_select_4 = slv_reg160[3:0];
    wire [7:0] start_configure_4  = slv_reg161[7:0];
    wire [7:0] F_configure_stop_4                  ;
    assign G1_ANA_POW_EN_4 = 1'b1;
    assign slv_reg162 = {24'd0,F_configure_stop_4};

    //TC_read
    wire start_TC_read_4 = slv_reg164[0];
    wire [31:0] TC_data_count_4;
    wire [31:0] TC_data_4;
    wire TC_prog_full_4;
    wire TC_full_4;
    wire fifo_TC_rst_4 = slv_reg167[0];
    wire SYNC_4 = slv_reg168[0];
    assign slv_reg169 = {31'd0,TC_prog_full_4};  
    assign slv_reg170 = {31'd0,TC_full_4};
    
    wire wr_en_TC_4;
    
TC_top TC_top_4(
 .PL_clk          (S_AXI_ACLK      ),
 .rst             ( rst_1          ),
 .TC_sdo          (TC_sdo_4          ),
 .TC_cs_n         (TC_cs_n_4         ),
 .TC_sclk         (TC_sclk_4         ), 
 .TC_sdi          (TC_sdi_4          ), 
 .wr_en           (wr_en_TC_4        ),
 .TC_data         (TC_data_4         ),
 .start_rd        (start_TC_read_4   ),
 .configure_select(configure_select_4),
 .start_configure (start_configure_4 ),
 .F_configure_stop(F_configure_stop_4)
);
wire rd_TC_4;
assign rd_TC_4 = slv_reg_rden && (axi_araddr ==  10'h298);

fifo_generator_1 TC_fifo_4(
.clk          (S_AXI_ACLK  ),
.srst         (fifo_TC_rst_4 ),
.din          (TC_data_4     ),
.wr_en        (wr_en_TC_4    ),
.rd_en        (rd_TC_4       ),
.dout         (slv_reg166    ),        
.full         (TC_full_4     ),
.almost_full  (),  
.empty        (),
.almost_empty (),  
.data_count   (slv_reg165    ),
.prog_full    (TC_prog_full_4)
);

    //5 AD_Board

    wire [3:0] configure_select_5 = slv_reg200[3:0];
    wire [7:0] start_configure_5  = slv_reg201[7:0];
    wire [7:0] F_configure_stop_5                  ;
    assign G1_ANA_POW_EN_5 = 1'b1;
    assign slv_reg202 = {24'd0,F_configure_stop_5};

    //TC_read
    wire start_TC_read_5= slv_reg204[0];
    wire [31:0] TC_data_count_5;
    wire [31:0] TC_data_5;
    wire TC_prog_full_5;
    wire TC_full_5;
    wire fifo_TC_rst_5 = slv_reg207[0];
    wire SYNC_5 = slv_reg208[0];
    assign slv_reg209 = {31'd0,TC_prog_full_5};  
    assign slv_reg210 = {31'd0,TC_full_5};
    
    wire wr_en_TC_5;
    
TC_top TC_top_5(
 .PL_clk          (S_AXI_ACLK      ),
 .rst             ( rst_1          ),
 .TC_sdo          (TC_sdo_5          ),
 .TC_cs_n         (TC_cs_n_5         ),
 .TC_sclk         (TC_sclk_5         ), 
 .TC_sdi          (TC_sdi_5          ), 
 .wr_en           (wr_en_TC_5        ),
 .TC_data         (TC_data_5         ),
 .start_rd        (start_TC_read_5   ),
 .configure_select(configure_select_5),
 .start_configure (start_configure_5 ),
 .F_configure_stop(F_configure_stop_5)
);
wire rd_TC_5;
assign rd_TC_5 = slv_reg_rden && (axi_araddr ==  10'h338);

fifo_generator_1 TC_fifo_5(
.clk          (S_AXI_ACLK  ),
.srst         (fifo_TC_rst_5 ),
.din          (TC_data_5     ),
.wr_en        (wr_en_TC_5    ),
.rd_en        (rd_TC_5       ),
.dout         (slv_reg206    ),        
.full         (TC_full_5     ),
.almost_full  (),  
.empty        (),
.almost_empty (),  
.data_count   (slv_reg205    ),
.prog_full    (TC_prog_full_5)
);


    //RTD read

    //RTD_0
 
    wire start_RTD = slv_reg20[0];    
    wire fifo_RTD_rst_0 = slv_reg21[0];
    wire [31:0] RTD_data_count_0;
    wire [31:0] RTD_data_0;
    wire RTD_prog_full_0;
    wire RTD_full_0;
    
    assign slv_reg24 = {31'd0,RTD_prog_full_0};  
    assign slv_reg25 = {31'd0,RTD_full_0};
    
    wire wr_en_RTD_0;
    
    RTD_top RTD_top_0 (
        .PL_clk     (S_AXI_ACLK ),
        .rst        (rst_1      ),
        .start      (start_RTD  ),
        .stop_single(stop_single),
        .RTD_sdo    (RTD_sdo    ),
        .RTD_cs_n   (RTD_cs_n   ),
        .RTD_sclk   (RTD_sclk   ),
        .RTD_sdi    (RTD_sdi    ),
        .rdata_0    (RTD_rdata_0),
        .rdata_1    (RTD_rdata_1),
        .rdata_2    (RTD_rdata_2),
        .rdata_3    (RTD_rdata_3),
        .rdata_4    (RTD_rdata_4),
        .rdata_5    (RTD_rdata_5),
        .rdata_6    (RTD_rdata_6),
        .rdata_7    (RTD_rdata_7),
        .rdata_8    (RTD_rdata_8),
        .rdata_9    (RTD_rdata_9),
        .wr_en_RTD  (wr_en_RTD_0),
        .RTD_data   (RTD_data_0 )
    );
    
    wire rd_RTD_0;
    assign rd_RTD_0 = slv_reg_rden && (axi_araddr ==  10'h058);
    
fifo_generator_1 RTD_fifo_0(
.clk          (S_AXI_ACLK  ),
.srst         (fifo_RTD_rst_0 ),
.din          (RTD_data_0     ),
.wr_en        (wr_en_RTD_0   ),
.rd_en        (rd_RTD_0      ),
.dout         (slv_reg22     ),        
.full         (RTD_full_0    ),
.almost_full  (),  
.empty        (),
.almost_empty (),  
.data_count   (slv_reg23    ),
.prog_full    (RTD_prog_full_0)
);

    //RTD_1
 
    wire start_RTD_1 = slv_reg60[0];    
    wire fifo_RTD_rst_1 = slv_reg61[0];
    wire [31:0] RTD_data_count_1;
    wire [31:0] RTD_data_1;
    wire RTD_prog_full_1;
    wire RTD_full_1;
    
    assign slv_reg64 = {31'd0,RTD_prog_full_1};  
    assign slv_reg65 = {31'd0,RTD_full_1};
    
    wire wr_en_RTD_1;
    
    RTD_top RTD_top_1 (
        .PL_clk     (S_AXI_ACLK ),
        .rst        (rst_1      ),
        .start      (start_RTD_1  ),
        .RTD_sdo    (RTD_sdo_1    ),
        .RTD_cs_n   (RTD_cs_n_1   ),
        .RTD_sclk   (RTD_sclk_1   ),
        .RTD_sdi    (RTD_sdi_1    ),
        .wr_en_RTD  (wr_en_RTD_1),
        .RTD_data   (RTD_data_1 )
    );
    
    wire rd_RTD_1;
    assign rd_RTD_1 = slv_reg_rden && (axi_araddr ==  10'h0F8);
    
fifo_generator_1 RTD_fifo_1(
.clk          (S_AXI_ACLK  ),
.srst         (fifo_RTD_rst_1 ),
.din          (RTD_data_1     ),
.wr_en        (wr_en_RTD_1   ),
.rd_en        (rd_RTD_1       ),
.dout         (slv_reg62     ),        
.full         (RTD_full_1    ),
.almost_full  (),  
.empty        (),
.almost_empty (),  
.data_count   (slv_reg63    ),
.prog_full    (RTD_prog_full_1)
);

    //RTD_2
 
    wire start_RTD_2 = slv_reg100[0];    
    wire fifo_RTD_rst_2 = slv_reg101[0];
    wire [31:0] RTD_data_count_2;
    wire [31:0] RTD_data_2;
    wire RTD_prog_full_2;
    wire RTD_full_2;
    
    assign slv_reg104 = {31'd0,RTD_prog_full_2};  
    assign slv_reg105 = {31'd0,RTD_full_2};
    
    wire wr_en_RTD_2;
    
    RTD_top RTD_top_2 (
        .PL_clk     (S_AXI_ACLK ),
        .rst        (rst_1      ),
        .start      (start_RTD_2  ),
        .RTD_sdo    (RTD_sdo_2   ),
        .RTD_cs_n   (RTD_cs_n_2   ),
        .RTD_sclk   (RTD_sclk_2   ),
        .RTD_sdi    (RTD_sdi_2    ),
        .wr_en_RTD  (wr_en_RTD_2),
        .RTD_data   (RTD_data_2 )
    );
    
    wire rd_RTD_2;
    assign rd_RTD_2 = slv_reg_rden && (axi_araddr ==  10'h198);
    
fifo_generator_1 RTD_fifo_2(
.clk          (S_AXI_ACLK  ),
.srst         (fifo_RTD_rst_2 ),
.din          (RTD_data_2     ),
.wr_en        (wr_en_RTD_2   ),
.rd_en        (rd_RTD_2       ),
.dout         (slv_reg102     ),        
.full         (RTD_full_2    ),
.almost_full  (),  
.empty        (),
.almost_empty (),  
.data_count   (slv_reg103    ),
.prog_full    (RTD_prog_full_2)
);
 
    //RTD_3
 
    wire start_RTD_3 = slv_reg140[0];    
    wire fifo_RTD_rst_3 = slv_reg141[0];
    wire [31:0] RTD_data_count_3;
    wire [31:0] RTD_data_3;
    wire RTD_prog_full_3;
    wire RTD_full_3;
    
    assign slv_reg144 = {31'd0,RTD_prog_full_3};  
    assign slv_reg145 = {31'd0,RTD_full_3};
    
    wire wr_en_RTD_3;
    
    RTD_top RTD_top_3 (
        .PL_clk     (S_AXI_ACLK ),
        .rst        (rst_1      ),
        .start      (start_RTD_3  ),
        .RTD_sdo    (RTD_sdo_3   ),
        .RTD_cs_n   (RTD_cs_n_3   ),
        .RTD_sclk   (RTD_sclk_3   ),
        .RTD_sdi    (RTD_sdi_3    ),
        .wr_en_RTD  (wr_en_RTD_3),
        .RTD_data   (RTD_data_3 )
    );
    
    wire rd_RTD_3;
    assign rd_RTD_3 = slv_reg_rden && (axi_araddr ==  10'h238);
    
fifo_generator_1 RTD_fifo_3(
.clk          (S_AXI_ACLK  ),
.srst         (fifo_RTD_rst_3 ),
.din          (RTD_data_3     ),
.wr_en        (wr_en_RTD_3   ),
.rd_en        (rd_RTD_3       ),
.dout         (slv_reg142     ),        
.full         (RTD_full_3    ),
.almost_full  (),  
.empty        (),
.almost_empty (),  
.data_count   (slv_reg143    ),
.prog_full    (RTD_prog_full_3)
); 
   
    //RTD_4
 
    wire start_RTD_4 = slv_reg180[0];    
    wire fifo_RTD_rst_4 = slv_reg181[0];
    wire [31:0] RTD_data_count_4;
    wire [31:0] RTD_data_4;
    wire RTD_prog_full_4;
    wire RTD_full_4;
    
    assign slv_reg184 = {31'd0,RTD_prog_full_4};  
    assign slv_reg185 = {31'd0,RTD_full_4};
    
    wire wr_en_RTD_4;
    
    RTD_top RTD_top_4 (
        .PL_clk     (S_AXI_ACLK ),
        .rst        (rst_1      ),
        .start      (start_RTD_4  ),
        .RTD_sdo    (RTD_sdo_4   ),
        .RTD_cs_n   (RTD_cs_n_4   ),
        .RTD_sclk   (RTD_sclk_4   ),
        .RTD_sdi    (RTD_sdi_4    ),
        .wr_en_RTD  (wr_en_RTD_4),
        .RTD_data   (RTD_data_4 )
    );
    
    wire rd_RTD_4;
    assign rd_RTD_4 = slv_reg_rden && (axi_araddr ==  10'h2D8);
    
fifo_generator_1 RTD_fifo_4(
.clk          (S_AXI_ACLK  ),
.srst         (fifo_RTD_rst_4 ),
.din          (RTD_data_4     ),
.wr_en        (wr_en_RTD_4   ),
.rd_en        (rd_RTD_4       ),
.dout         (slv_reg182     ),        
.full         (RTD_full_4    ),
.almost_full  (),  
.empty        (),
.almost_empty (),  
.data_count   (slv_reg183    ),
.prog_full    (RTD_prog_full_4)
);     

    //RTD_5
 
    wire start_RTD_5 = slv_reg220[0];    
    wire fifo_RTD_rst_5 = slv_reg221[0];
    wire [31:0] RTD_data_count_5;
    wire [31:0] RTD_data_5;
    wire RTD_prog_full_5;
    wire RTD_full_5;
    
    assign slv_reg224 = {31'd0,RTD_prog_full_5};  
    assign slv_reg225 = {31'd0,RTD_full_5};
    
    wire wr_en_RTD_5;
    
    RTD_top RTD_top_5 (
        .PL_clk     (S_AXI_ACLK ),
        .rst        (rst_1      ),
        .start      (start_RTD_5  ),
        .RTD_sdo    (RTD_sdo_5   ),
        .RTD_cs_n   (RTD_cs_n_5   ),
        .RTD_sclk   (RTD_sclk_5   ),
        .RTD_sdi    (RTD_sdi_5    ),
        .wr_en_RTD  (wr_en_RTD_5),
        .RTD_data   (RTD_data_5 )
    );
    
    wire rd_RTD_5;
    assign rd_RTD_5 = slv_reg_rden && (axi_araddr ==  10'h378);
    
fifo_generator_1 RTD_fifo_5(
.clk          (S_AXI_ACLK  ),
.srst         (fifo_RTD_rst_5 ),
.din          (RTD_data_5     ),
.wr_en        (wr_en_RTD_5   ),
.rd_en        (rd_RTD_5       ),
.dout         (slv_reg222     ),        
.full         (RTD_full_5    ),
.almost_full  (),  
.empty        (),
.almost_empty (),  
.data_count   (slv_reg223    ),
.prog_full    (RTD_prog_full_5)
);     


//fifo_0

wire full;
wire almost_full;
wire empty;
wire almost_empty;
wire [31:0] fifo_0_dout;
wire prog_full;
wire rd_RTD;
reg [3:0] rd_cnt = 4'd0;


assign rd_RTD = slv_reg_rden && (axi_araddr ==  10'h3F8);

  always @( posedge S_AXI_ACLK )
    begin
    if (rst_1 == 1'b0 )
     rd_cnt <= 0;
    else if(rd_RTD)
    rd_cnt <= rd_cnt + 1'b1;
    else
    rd_cnt <= rd_cnt;
end

//fifo_generator_0 fifo_0(
//.clk          (S_AXI_ACLK  ),
//.srst         (~rst_1      ),
//.din          (RTD_rdata_0 ),
//.wr_en        (wr_en_0     ),
//.rd_en        (rd_RTD      ),
//.dout         (slv_reg254  ),        
//.full         (full        ),
//.almost_full  (almost_full ),  
//.empty        (empty       ),
//.almost_empty (almost_empty),  
//.data_count   (slv_reg253  ),
//.prog_full    (prog_full   )
//);

//assign interrupt = prog_full;

//    always @( posedge S_AXI_ACLK )
//        begin
//            if ( rst_1 == 1'b0 )
//            interrupt <= 1'b0;
//            else if(slv_reg253 >= 4)
//            interrupt <= 1'b1;
//            else 
//            interrupt <= 1'b0;
//            end
         
            
 
//    ila_0 ila_0 (
//        .clk    (S_AXI_ACLK      ),
//        .probe0 (fifo_RTD_rst_5  ),
//        .probe1 (wr_en_RTD_5     ),
//        .probe2 (start_RTD_5     ),
//        .probe3 (RTD_cs_n_5      ),
//        .probe4 (RTD_sdo_5       ),
//        .probe5 (RTD_sclk_5      ),
//        .probe6 (RTD_sdi_5       ),
//        .probe7 (RTD_data_5      ),
//        .probe8 (slv_reg_rden    ),
//        .probe9 (rd_RTD_5        ),
//        .probe10(RTD_full_5      ),
//        .probe11(RTD_prog_full_5 ),
//        .probe12(slv_reg222      ),
//        .probe13(slv_reg223      )
//    );           

    // User logic ends

endmodule

// File: axi4l_ipif_if.sv
// Brief: Virtual interface for axi4l_ipif module

interface axi4l_ipif_if #(
    parameter int ADDR_WIDTH = 12,
    parameter int DATA_WIDTH = 32
);

  logic                    aclk;
  logic                    aresetn;
  //
  logic [  ADDR_WIDTH-1:0] s_axi_awaddr;
  logic [             2:0] s_axi_awprot;
  logic                    s_axi_awvalid;
  logic                    s_axi_awready;
  //
  logic [  DATA_WIDTH-1:0] s_axi_wdata;
  logic [DATA_WIDTH/8-1:0] s_axi_wstrb;
  logic                    s_axi_wvalid;
  logic                    s_axi_wready;
  //
  logic [             1:0] s_axi_bresp;
  logic                    s_axi_bvalid;
  logic                    s_axi_bready;
  //
  logic [  ADDR_WIDTH-1:0] s_axi_araddr;
  logic [             2:0] s_axi_arprot;
  logic                    s_axi_arvalid;
  logic                    s_axi_arready;
  //
  logic [  DATA_WIDTH-1:0] s_axi_rdata;
  logic [             1:0] s_axi_rresp;
  logic                    s_axi_rvalid;
  logic                    s_axi_rready;
  // IP i/f
  //=======
  logic [  ADDR_WIDTH-1:0] ipif_addr;
  logic                    ipif_req;
  logic                    ipif_req_is_wr;
  //
  logic [DATA_WIDTH/8-1:0] ipif_wr_be;
  logic [  DATA_WIDTH-1:0] ipif_wr_data;
  logic                    ipif_wr_ack;
  logic                    ipif_wr_err;
  //
  logic [  DATA_WIDTH-1:0] ipif_rd_data;
  logic                    ipif_rd_ack;
  logic                    ipif_rd_err;

endinterface

// File: axi4l_ipif_if.sv
// Brief: Virtual interface for axi4l_ipif module

interface axi4l_ipif_if #(
    parameter int ADDR_WIDTH = 12,
    parameter int DATA_WIDTH = 32
) (
    input var aclk,
    input var aresetn
);

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

  clocking dr_cb @(posedge aclk);
    output s_axi_awaddr;
    output s_axi_awprot;
    output s_axi_awvalid;
    input s_axi_awready;
    //
    output s_axi_wdata;
    output s_axi_wstrb;
    output s_axi_wvalid;
    input s_axi_wready;
    //
    input s_axi_bresp;
    input s_axi_bvalid;
    output s_axi_bready;
    //
    output s_axi_araddr;
    output s_axi_arprot;
    output s_axi_arvalid;
    input s_axi_arready;
    //
    input s_axi_rdata;
    input s_axi_rresp;
    input s_axi_rvalid;
    output s_axi_rready;
    // IP i/f
    //=======
    input ipif_addr;
    input ipif_req;
    input ipif_req_is_wr;
    //
    input ipif_wr_be;
    input ipif_wr_data;
    output ipif_wr_ack;
    output ipif_wr_err;
    //
    output ipif_rd_data;
    output ipif_rd_ack;
    output ipif_rd_err;
  endclocking

  modport DRV(clocking dr_cb, input aclk, input aresetn);

  clocking rc_cb @(posedge aclk);
    input s_axi_awaddr;
    input s_axi_awprot;
    input s_axi_awvalid;
    input s_axi_awready;
    //
    input s_axi_wdata;
    input s_axi_wstrb;
    input s_axi_wvalid;
    input s_axi_wready;
    //
    input s_axi_bresp;
    input s_axi_bvalid;
    input s_axi_bready;
    //
    input s_axi_araddr;
    input s_axi_arprot;
    input s_axi_arvalid;
    input s_axi_arready;
    //
    input s_axi_rdata;
    input s_axi_rresp;
    input s_axi_rvalid;
    input s_axi_rready;
    // IP i/f
    //=======
    input ipif_addr;
    input ipif_req;
    input ipif_req_is_wr;
    //
    input ipif_wr_be;
    input ipif_wr_data;
    input ipif_wr_ack;
    input ipif_wr_err;
    //
    input ipif_rd_data;
    input ipif_rd_ack;
    input ipif_rd_err;
  endclocking

  modport RCV(clocking rc_cb, input aclk, input aresetn);

endinterface

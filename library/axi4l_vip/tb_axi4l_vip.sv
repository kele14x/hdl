// File: tb_axi4l_vip.sv
// Brief: Test bench for module axi4l_vip
`timescale 1 ns / 1 ps `default_nettype none

module tb_axi4l_vip ();

  parameter int C_ADDR_WIDTH = 32;
  parameter int C_DATA_WIDTH = 32;

  logic                      aclk;
  logic                      aresetn;
  //
  logic [  C_ADDR_WIDTH-1:0] s_axi_awaddr;
  logic [               2:0] s_axi_awprot;
  logic                      s_axi_awvalid;
  logic                      s_axi_awready;
  //
  logic [  C_DATA_WIDTH-1:0] s_axi_wdata;
  logic [C_DATA_WIDTH/8-1:0] s_axi_wstrb;
  logic                      s_axi_wvalid;
  logic                      s_axi_wready;
  //
  logic [               1:0] s_axi_bresp;
  logic                      s_axi_bvalid;
  logic                      s_axi_bready;
  //
  logic [  C_ADDR_WIDTH-1:0] s_axi_araddr;
  logic [               2:0] s_axi_arprot;
  logic                      s_axi_arvalid;
  logic                      s_axi_arready;
  //
  logic [  C_DATA_WIDTH-1:0] s_axi_rdata;
  logic [               1:0] s_axi_rresp;
  logic                      s_axi_rvalid;
  logic                      s_axi_rready;
  //
  logic [  C_ADDR_WIDTH-1:0] m_axi_awaddr;
  logic [               2:0] m_axi_awprot;
  logic                      m_axi_awvalid;
  logic                      m_axi_awready;
  //
  logic [  C_DATA_WIDTH-1:0] m_axi_wdata;
  logic [C_DATA_WIDTH/8-1:0] m_axi_wstrb;
  logic                      m_axi_wvalid;
  logic                      m_axi_wready;
  //
  logic [               1:0] m_axi_bresp;
  logic                      m_axi_bvalid;
  logic                      m_axi_bready;
  //
  logic [  C_ADDR_WIDTH-1:0] m_axi_araddr;
  logic [               2:0] m_axi_arprot;
  logic                      m_axi_arvalid;
  logic                      m_axi_arready;
  //
  logic [  C_DATA_WIDTH-1:0] m_axi_rdata;
  logic [               1:0] m_axi_rresp;
  logic                      m_axi_rvalid;
  logic                      m_axi_rready;


  initial begin
    aclk = 0;
    forever begin
      aclk = ~aclk;
      #5;
    end
  end

  initial begin
    aresetn = 0;
    #100;
    aresetn = 1;
  end

  //  logic [31:0] data;

  initial begin
    tb_axi4l_vip.DUT.IF.set_intf_master();
    @(posedge aclk);
    tb_axi4l_vip.DUT.IF.reset();

    wait(aresetn);
    @(posedge aclk);
    tb_axi4l_vip.DUT.IF.master_write(32'h1, 32'h2);
    // tb_axi4l_vip.DUT.IF.master_read(32'h1, data);
    #1000 $finish();
  end

  axi4l_vip #(
      .C_ADDR_WIDTH(C_ADDR_WIDTH),
      .C_DATA_WIDTH(C_DATA_WIDTH)
  ) DUT (
      .aclk         (aclk),
      .aresetn      (aresetn),
      //
      .s_axi_awaddr (s_axi_awaddr),
      .s_axi_awprot (s_axi_awprot),
      .s_axi_awvalid(s_axi_awvalid),
      .s_axi_awready(s_axi_awready),
      //
      .s_axi_wdata  (s_axi_wdata),
      .s_axi_wstrb  (s_axi_wstrb),
      .s_axi_wvalid (s_axi_wvalid),
      .s_axi_wready (s_axi_wready),
      //
      .s_axi_bresp  (s_axi_bresp),
      .s_axi_bvalid (s_axi_bvalid),
      .s_axi_bready (s_axi_bready),
      //
      .s_axi_araddr (s_axi_araddr),
      .s_axi_arprot (s_axi_arprot),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arready(s_axi_arready),

      .s_axi_rdata  (s_axi_rdata),
      .s_axi_rresp  (s_axi_rresp),
      .s_axi_rvalid (s_axi_rvalid),
      .s_axi_rready (s_axi_rready),
      //
      .m_axi_awaddr (m_axi_awaddr),
      .m_axi_awprot (m_axi_awprot),
      .m_axi_awvalid(m_axi_awvalid),
      .m_axi_awready(m_axi_awready),
      //
      .m_axi_wdata  (m_axi_wdata),
      .m_axi_wstrb  (m_axi_wstrb),
      .m_axi_wvalid (m_axi_wvalid),
      .m_axi_wready (m_axi_wready),
      //
      .m_axi_bresp  (m_axi_bresp),
      .m_axi_bvalid (m_axi_bvalid),
      .m_axi_bready (m_axi_bready),
      //
      .m_axi_araddr (m_axi_araddr),
      .m_axi_arprot (m_axi_arprot),
      .m_axi_arvalid(m_axi_arvalid),
      .m_axi_arready(m_axi_arready),
      //
      .m_axi_rdata  (m_axi_rdata),
      .m_axi_rresp  (m_axi_rresp),
      .m_axi_rvalid (m_axi_rvalid),
      .m_axi_rready (m_axi_rready)
  );

endmodule

`default_nettype wire

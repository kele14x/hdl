`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy_top #(
    parameter integer CH_NUM = 2
) (
    // AXI
    //----
    input var         s_axi_aclk,
    input var         s_axi_aresetn,
    //
    input var  [ 8:0] s_axi_awaddr,
    input var  [ 2:0] s_axi_awprot,
    input var         s_axi_awvalid,
    output var        s_axi_awready,
    //
    input var  [31:0] s_axi_wdata,
    input var  [ 3:0] s_axi_wstrb,
    input var         s_axi_wvalid,
    output var        s_axi_wready,
    //
    output var [ 1:0] s_axi_bresp,
    output var        s_axi_bvalid,
    input var         s_axi_bready,
    //
    input var  [ 8:0] s_axi_araddr,
    input var  [ 2:0] s_axi_arprot,
    input var         s_axi_arvalid,
    output var        s_axi_arready,
    //
    output var [31:0] s_axi_rdata,
    output var [ 1:0] s_axi_rresp,
    output var        s_axi_rvalid,
    input var         s_axi_rready,
    //
    input var         clk,
    input var         rst,
    //
    input var  [ 7:0] lowphy_dl_frame[CH_NUM],
    input var         lowphy_dl_sof  [CH_NUM],
    input var         lowphy_dl_sos  [CH_NUM],
    input var  [32:0] lowphy_dl_frac [CH_NUM],
    input var  [31:0] lowphy_dl_data [CH_NUM],
    input var         lowphy_dl_valid[CH_NUM],
    //
    output var [ 7:0] lowphy_ul_frame[CH_NUM],
    output var        lowphy_ul_sof  [CH_NUM],
    output var        lowphy_ul_sos  [CH_NUM],
    output var [31:0] lowphy_ul_data [CH_NUM],
    output var        lowphy_ul_valid[CH_NUM],
    //
    output var [ 7:0] dl_frame       [CH_NUM],
    output var        dl_sof         [CH_NUM],
    output var        dl_sos         [CH_NUM],
    output var [31:0] dl_data        [CH_NUM],
    output var        dl_valid       [CH_NUM],
    //
    input var  [ 7:0] ul_frame       [CH_NUM],
    input var         ul_sof         [CH_NUM],
    input var         ul_sos         [CH_NUM],
    input var  [32:0] ul_frac        [CH_NUM],
    input var  [31:0] ul_data        [CH_NUM],
    input var         ul_valid       [CH_NUM]
);

  logic [ 3:0] dl_phase_comp_addr;
  logic        dl_phase_comp_en;
  logic        dl_phase_comp_we;
  logic [31:0] dl_phase_comp_din;
  logic [31:0] dl_phase_comp_dout;
  logic [31:0] dl_phase_comp_dout_s  [CH_NUM];

  logic [ 3:0] ul_phase_comp_addr;
  logic        ul_phase_comp_en;
  logic        ul_phase_comp_we;
  logic [31:0] ul_phase_comp_din;
  logic [31:0] ul_phase_comp_dout;
  logic [31:0] ul_phase_comp_dout_s  [CH_NUM];


  lowphy_regs u_regs (
      .s_axi_aclk        (s_axi_aclk),
      .s_axi_aresetn     (s_axi_aresetn),
      //
      .s_axi_awaddr      (s_axi_awaddr),
      .s_axi_awprot      (s_axi_awprot),
      .s_axi_awvalid     (s_axi_awvalid),
      .s_axi_awready     (s_axi_awready),
      //
      .s_axi_wdata       (s_axi_wdata),
      .s_axi_wstrb       (s_axi_wstrb),
      .s_axi_wvalid      (s_axi_wvalid),
      .s_axi_wready      (s_axi_wready),
      //
      .s_axi_bresp       (s_axi_bresp),
      .s_axi_bvalid      (s_axi_bvalid),
      .s_axi_bready      (s_axi_bready),
      //
      .s_axi_araddr      (s_axi_araddr),
      .s_axi_arprot      (s_axi_arprot),
      .s_axi_arvalid     (s_axi_arvalid),
      .s_axi_arready     (s_axi_arready),
      //
      .s_axi_rdata       (s_axi_rdata),
      .s_axi_rresp       (s_axi_rresp),
      .s_axi_rvalid      (s_axi_rvalid),
      .s_axi_rready      (s_axi_rready),
      // dl_phase_comp
      .dl_phase_comp_addr(dl_phase_comp_addr),
      .dl_phase_comp_en  (dl_phase_comp_en),
      .dl_phase_comp_we  (dl_phase_comp_we),
      .dl_phase_comp_din (dl_phase_comp_din),
      .dl_phase_comp_dout(dl_phase_comp_dout),
      // ul_phase_comp
      .ul_phase_comp_addr(ul_phase_comp_addr),
      .ul_phase_comp_en  (ul_phase_comp_en),
      .ul_phase_comp_we  (ul_phase_comp_we),
      .ul_phase_comp_din (ul_phase_comp_din),
      .ul_phase_comp_dout(ul_phase_comp_dout)
  );

  assign dl_phase_comp_dout = dl_phase_comp_dout_s[0];
  assign ul_phase_comp_dout = ul_phase_comp_dout_s[0];

  generate
    for (genvar i = 0; i < CH_NUM; i++) begin : g_ch

      lowphy_ifft #(
          .INIT_GAIN(10'b0101010101)
      ) u_ifft (
          .clk               (clk),
          .rst               (rst),
          //
          .lowphy_dl_frame   (lowphy_dl_frame[i]),
          .lowphy_dl_sof     (lowphy_dl_sof[i]),
          .lowphy_dl_sos     (lowphy_dl_sos[i]),
          .lowphy_dl_frac    (lowphy_dl_frac[i]),
          .lowphy_dl_data    (lowphy_dl_data[i]),
          .lowphy_dl_valid   (lowphy_dl_valid[i]),
          //
          .dl_frame          (dl_frame[i]),
          .dl_sof            (dl_sof[i]),
          .dl_sos            (dl_sos[i]),
          .dl_data           (dl_data[i]),
          .dl_valid          (dl_valid[i]),
          //
          .ctrl_clk          (s_axi_aclk),
          .ctrl_rst          (~s_axi_aresetn),
          //
          .dl_phase_comp_addr(dl_phase_comp_addr),
          .dl_phase_comp_en  (dl_phase_comp_en),
          .dl_phase_comp_we  (dl_phase_comp_we),
          .dl_phase_comp_din (dl_phase_comp_din),
          .dl_phase_comp_dout(dl_phase_comp_dout_s[i])
      );

      lowphy_fft u_fft (
          .clk               (clk),
          .rst               (rst),
          //
          .lowphy_ul_frame   (lowphy_ul_frame[i]),
          .lowphy_ul_sof     (lowphy_ul_sof[i]),
          .lowphy_ul_sos     (lowphy_ul_sos[i]),
          .lowphy_ul_data    (lowphy_ul_data[i]),
          .lowphy_ul_valid   (lowphy_ul_valid[i]),
          //
          .ul_frame          (ul_frame[i]),
          .ul_sof            (ul_sof[i]),
          .ul_sos            (ul_sos[i]),
          .ul_frac           (ul_frac[i]),
          .ul_data           (ul_data[i]),
          .ul_valid          (ul_valid[i]),
          //
          .ctrl_clk          (s_axi_aclk),
          .ctrl_rst          (~s_axi_aresetn),
          //
          .ul_phase_comp_addr(ul_phase_comp_addr),
          .ul_phase_comp_en  (ul_phase_comp_en),
          .ul_phase_comp_we  (ul_phase_comp_we),
          .ul_phase_comp_din (ul_phase_comp_din),
          .ul_phase_comp_dout(ul_phase_comp_dout_s[i])
      );

    end
  endgenerate

endmodule

`default_nettype wire

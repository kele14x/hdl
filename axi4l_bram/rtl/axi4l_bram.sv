`timescale 1 ns / 1 ps
//
`default_nettype none

// AXI4-Lite to BRAM adapter top with a selectable BRAM port structure.
// USE_DUAL_PORT = 0 uses the shared read/write adapter, which issues one
// command at a time; USE_DUAL_PORT = 1 uses independent read and write
// adapters. The BRAM side always appears as separate read and write ports:
// in shared mode the single command stream is split by its write enable, so
// at most one port enable is asserted per cycle.
module axi4l_bram #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int USE_DUAL_PORT = 0
) (
    input  wire                    aclk,
    input  wire                    aresetn,
    //
    input  wire [  ADDR_WIDTH-1:0] awaddr,
    input  wire                    awvalid,
    output wire                    awready,
    //
    input  wire [  DATA_WIDTH-1:0] wdata,
    input  wire [DATA_WIDTH/8-1:0] wstrb,
    input  wire                    wvalid,
    output wire                    wready,
    //
    output wire [             1:0] bresp,
    output wire                    bvalid,
    input  wire                    bready,
    //
    input  wire [  ADDR_WIDTH-1:0] araddr,
    input  wire                    arvalid,
    output wire                    arready,
    //
    output wire [  DATA_WIDTH-1:0] rdata,
    output wire [             1:0] rresp,
    output wire                    rvalid,
    input  wire                    rready,
    //
    output wire [  ADDR_WIDTH-1:0] bram_rd_addr,
    output wire                    bram_rd_en,
    //
    input  wire [  DATA_WIDTH-1:0] bram_rd_data,
    input  wire                    bram_rd_ack,
    input  wire                    bram_rd_err,
    //
    output wire [  ADDR_WIDTH-1:0] bram_wr_addr,
    output wire [  DATA_WIDTH-1:0] bram_wr_data,
    output wire [DATA_WIDTH/8-1:0] bram_wr_strb,
    output wire                    bram_wr_we,
    //
    input  wire                    bram_wr_ack,
    input  wire                    bram_wr_err
);

  initial begin : drc_check
    assert (ADDR_WIDTH > 0)
    else $error("ADDR_WIDTH must be positive");
    assert (DATA_WIDTH > 0 && DATA_WIDTH % 8 == 0)
    else $error("DATA_WIDTH must be a positive multiple of 8");
    assert (USE_DUAL_PORT == 0 || USE_DUAL_PORT == 1)
    else $error("USE_DUAL_PORT must be 0 or 1");
  end

  generate
    if (USE_DUAL_PORT == 0) begin : gen_single_port
      axi4l_bram_wr #(
          .ADDR_WIDTH(ADDR_WIDTH),
          .DATA_WIDTH(DATA_WIDTH)
      ) u_axi4l_bram_wr (
          .aclk        (aclk),
          .aresetn     (aresetn),
          .awaddr      (awaddr),
          .awvalid     (awvalid),
          .awready     (awready),
          .wdata       (wdata),
          .wstrb       (wstrb),
          .wvalid      (wvalid),
          .wready      (wready),
          .bresp       (bresp),
          .bvalid      (bvalid),
          .bready      (bready),
          .araddr      (araddr),
          .arvalid     (arvalid),
          .arready     (arready),
          .rdata       (rdata),
          .rresp       (rresp),
          .rvalid      (rvalid),
          .rready      (rready),
          .bram_rd_addr(bram_rd_addr),
          .bram_rd_en  (bram_rd_en),
          .bram_wr_addr(bram_wr_addr),
          .bram_wr_data(bram_wr_data),
          .bram_wr_strb(bram_wr_strb),
          .bram_wr_we  (bram_wr_we),
          .bram_wr_ack (bram_wr_ack),
          .bram_wr_err (bram_wr_err),
          .bram_rd_data(bram_rd_data),
          .bram_rd_ack (bram_rd_ack),
          .bram_rd_err (bram_rd_err)
      );
    end else begin : gen_dual_port
      axi4l_bram_r #(
          .ADDR_WIDTH(ADDR_WIDTH),
          .DATA_WIDTH(DATA_WIDTH)
      ) u_axi4l_bram_r (
          .aclk     (aclk),
          .aresetn  (aresetn),
          .araddr   (araddr),
          .arvalid  (arvalid),
          .arready  (arready),
          .rdata    (rdata),
          .rresp    (rresp),
          .rvalid   (rvalid),
          .rready   (rready),
          .bram_addr(bram_rd_addr),
          .bram_en  (bram_rd_en),
          .bram_data(bram_rd_data),
          .bram_ack (bram_rd_ack),
          .bram_err (bram_rd_err)
      );

      axi4l_bram_w #(
          .ADDR_WIDTH(ADDR_WIDTH),
          .DATA_WIDTH(DATA_WIDTH)
      ) u_axi4l_bram_w (
          .aclk     (aclk),
          .aresetn  (aresetn),
          .awaddr   (awaddr),
          .awvalid  (awvalid),
          .awready  (awready),
          .wdata    (wdata),
          .wstrb    (wstrb),
          .wvalid   (wvalid),
          .wready   (wready),
          .bresp    (bresp),
          .bvalid   (bvalid),
          .bready   (bready),
          .bram_addr(bram_wr_addr),
          .bram_data(bram_wr_data),
          .bram_strb(bram_wr_strb),
          .bram_we  (bram_wr_we),
          .bram_ack (bram_wr_ack),
          .bram_err (bram_wr_err)
      );
    end
  endgenerate

endmodule

`default_nettype wire

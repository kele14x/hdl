// File: axi4l_ipif.sv
// Brief: AXI4-Lite to IP interface. This module is used to connect a AXI4-Lite
//        master, and helps to do:
//
//        1. Combine the write and read operation into one port. This help the
//           later module to use one address decoder for both write and read.
//           Also this ensures there will not be conflict between the write and
//           read operation.
//        2. Buffer the response data, so later module does not need to care
//           about the back pressure.
//
// Note: AxPROT not supported (not connected)
`timescale 1 ns / 1 ps
//
`default_nettype none

module axi4l_int #(
    parameter integer ADDR_WIDTH = 10,
    parameter integer DATA_WIDTH = 32
) (
    input  wire                    s_axi_aclk,
    input  wire                    s_axi_aresetn,
    //
    input  wire [  ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire [             2:0] s_axi_awprot,
    input  wire                    s_axi_awvalid,
    output wire                    s_axi_awready,
    //
    input  wire [  DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                    s_axi_wvalid,
    output wire                    s_axi_wready,
    //
    output wire [             1:0] s_axi_bresp,
    output wire                    s_axi_bvalid,
    input  wire                    s_axi_bready,
    //
    input  wire [  ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire [             2:0] s_axi_arprot,
    input  wire                    s_axi_arvalid,
    output wire                    s_axi_arready,
    //
    output wire [  DATA_WIDTH-1:0] s_axi_rdata,
    output wire [             1:0] s_axi_rresp,
    output wire                    s_axi_rvalid,
    input  wire                    s_axi_rready,
    // IP I/F
    output reg  [  ADDR_WIDTH-1:0] ipif_addr,
    output reg  [  DATA_WIDTH-1:0] ipif_wr_data,
    output reg  [DATA_WIDTH/8-1:0] ipif_wr_be,
    output reg                     ipif_wr_en,
    output reg                     ipif_rd_en,
    //
    input  wire                    ipif_wr_ack,
    input  wire                    ipif_wr_err,
    //
    input  wire [  DATA_WIDTH-1:0] ipif_rd_data,
    input  wire                    ipif_rd_ack,
    input  wire                    ipif_rd_err
);

  initial begin
    assert ((DATA_WIDTH == 32) || (DATA_WIDTH == 64))
    else
      $error(
          "[%m]: AXI4-Lite interface data width (DATA_WIDTH) should be 32 or 64, got %0d",
          DATA_WIDTH
      );
  end

  // Local parameters

  localparam logic [1:0] RespOkey = 2'b00;  // OKAY, normal access success
  localparam logic [1:0] RespExokay = 2'b01;  // EXOKAY, exclusive access success
  localparam logic [1:0] RespSlverr = 2'b10;  // SLVERR, slave error
  localparam logic [1:0] RespDecerr = 2'b11;  // DECERR, decoder error

  // Signals

  wire                    aclk;
  wire                    aresetn;

  reg                     init_n;

  // AXI Signals

  wire                    aw_hsk;
  reg  [  ADDR_WIDTH-1:0] aw_addr;
  reg                     aw_ready;
  reg                     aw_req;

  wire                    w_hsk;
  reg  [  DATA_WIDTH-1:0] w_data;
  reg  [DATA_WIDTH/8-1:0] w_strb;
  reg                     w_ready;
  reg                     w_req;

  wire                    b_hsk;
  reg  [             1:0] b_resp;
  reg                     b_valid;

  wire                    ar_hsk;
  reg  [  ADDR_WIDTH-1:0] ar_addr;
  reg                     ar_ready;
  reg                     ar_req;

  wire                    r_hsk;
  reg  [  DATA_WIDTH-1:0] r_data;
  reg  [             1:0] r_resp;
  reg                     r_valid;

  // Internal signals

  wire                    wr_valid;
  wire                    rd_valid;

  reg                     int_wr_req;
  reg                     int_wr_pend;
  reg                     ipif_wr_err_reg;

  reg                     int_rd_req;
  reg                     int_rd_pend;
  reg                     ipif_rd_err_reg;
  reg  [  DATA_WIDTH-1:0] ipif_rd_data_reg;


  // AXI4-Lite Interface
  //--------------------

  assign aclk    = s_axi_aclk;
  assign aresetn = s_axi_aresetn;

  // Out of reset initialize

  always @(posedge aclk) begin
    if (!aresetn) begin
      init_n <= 1'b0;
    end else begin
      init_n <= 1'b1;
    end
  end

  // Write address

  assign aw_hsk        = (s_axi_awvalid & s_axi_awready);
  assign s_axi_awready = aw_ready;

  always @(posedge aclk) begin
    if (!aresetn) begin
      aw_addr <= 1'sb0;
    end else if (aw_hsk) begin
      aw_addr <= s_axi_awaddr;
    end
  end

  // aw_req aw_valid (w_hsk || w_req) int_wr_req aw_req_next
  //      0        0                0          0           0
  //      0        0                0          1           0
  //      0        0                1          0           0
  //      0        0                1          1           0
  //      0        1                0          0           1 *
  //      0        1                0          1           1 *
  //      0        1                1          0           0
  //      0        1                1          1           1 *
  //      1        0                0          0           1
  //      1        0                0          1           1
  //      1        0                1          0           0 *
  //      1        0                1          1           1
  //      1        1                0          0           1
  //      1        1                0          1           1
  //      1        1                1          0           0 *
  //      1        1                1          1           1
  always @(posedge aclk) begin
    if (!aresetn) begin
      aw_req <= 1'b0;
    end else if (aw_hsk && (~(w_hsk || w_req) || int_wr_req)) begin
      aw_req <= 1'b1;
    end else if (aw_req && (w_hsk || w_req) && ~int_wr_req) begin
      aw_req <= 1'b0;
    end else begin
      aw_req <= aw_req;
    end
  end

  // aw_ready = ~aw_req, unless under reset
  always @(posedge aclk) begin
    if (!aresetn) begin
      aw_ready <= 1'b0;
    end else if (~init_n) begin
      aw_ready <= 1'b1;
    end else if (aw_hsk && (~(w_hsk || w_req) || int_wr_req)) begin
      aw_ready <= 1'b0;
    end else if (aw_req && (w_hsk || w_req) && ~int_wr_req) begin
      aw_ready <= 1'b1;
    end else begin
      aw_ready <= aw_ready;
    end
  end

  // Write data

  assign w_hsk        = (s_axi_wvalid & s_axi_wready);
  assign s_axi_wready = w_ready;

  always @(posedge aclk) begin
    if (!aresetn) begin
      w_data <= 1'sb0;
    end else if (w_hsk) begin
      w_data <= s_axi_wdata;
    end
  end

  always @(posedge aclk) begin
    if (!aresetn) begin
      w_strb <= 1'sb0;
    end else if (w_hsk) begin
      w_strb <= s_axi_wstrb;
    end
  end

  // w_req w_valid (aw_hsk || aw_req) int_wr_req w_req_next
  //     0       0                  0          0          0
  //     0       0                  0          1          0
  //     0       0                  1          0          0
  //     0       0                  1          1          0
  //     0       1                  0          0          1 *
  //     0       1                  0          1          1 *
  //     0       1                  1          0          0
  //     0       1                  1          1          1 *
  //     1       0                  0          0          1
  //     1       0                  0          1          1
  //     1       0                  1          0          0 *
  //     1       0                  1          1          1
  //     1       1                  0          0          1
  //     1       1                  0          1          1
  //     1       1                  1          0          0 *
  //     1       1                  1          1          1
  always @(posedge aclk) begin
    if (!aresetn) begin
      w_req <= 1'b0;
    end else if (w_hsk && (~(aw_hsk || aw_req) || int_wr_req)) begin
      w_req <= 1'b1;
    end else if (w_req && (aw_hsk || aw_req) && ~int_wr_req) begin
      w_req <= 1'b0;
    end else begin
      w_req <= w_req;
    end
  end

  // w_ready = ~w_req, unless under reset
  always @(posedge aclk) begin
    if (!aresetn) begin
      w_ready <= 1'b0;
    end else if (~init_n) begin
      w_ready <= 1'b1;
    end else if (w_hsk && (~(aw_hsk || aw_req) || int_wr_req)) begin
      w_ready <= 1'b0;
    end else if (w_req && (aw_hsk || aw_req) && ~int_wr_req) begin
      w_ready <= 1'b1;
    end else begin
      w_ready <= w_ready;
    end
  end

  // Write response

  assign b_hsk        = (s_axi_bvalid && s_axi_bready);
  assign s_axi_bresp  = b_resp;
  assign s_axi_bvalid = b_valid;

  always @(posedge aclk) begin
    if (!aresetn) begin
      b_resp <= 2'b00;
    end else if (~(b_valid && ~s_axi_bready) && int_wr_pend) begin
      b_resp <= {2{ipif_wr_err_reg}};
    end else if (~(b_valid && ~s_axi_bready) && (int_wr_req && ipif_wr_ack)) begin
      b_resp <= {2{ipif_wr_err}};
    end
  end

  // b_valid s_axi_bready (int_wr_req && ipif_wr_ack) int_wr_pend b_valid_next
  //       0            0                          0           0            0
  //       0            0                          0           1            1 *
  //       0            0                          1           0            1 *
  //       0            0                          1           1            1 *
  //       0            1                          0           0            0
  //       0            1                          0           1            1 *
  //       0            1                          1           0            1 *
  //       0            1                          1           1            1 *
  //       1            0                          0           0            1
  //       1            0                          0           1            1
  //       1            0                          1           0            1
  //       1            0                          1           1            1
  //       1            1                          0           0            0 *
  //       1            1                          0           1            1
  //       1            1                          1           0            1
  //       1            1                          1           1            1
  always @(posedge aclk) begin
    if (!aresetn) begin
      b_valid <= 1'b0;
    end else if (b_hsk && ~(int_wr_req && ipif_wr_ack) && ~int_wr_pend) begin
      b_valid <= 1'b0;
    end else if ((int_wr_req && ipif_wr_ack) || int_wr_pend) begin
      b_valid <= 1'b1;
    end else begin
      b_valid <= b_valid;
    end
  end

  // Read address

  assign ar_hsk        = (s_axi_arvalid & s_axi_arready);
  assign s_axi_arready = ar_ready;

  always @(posedge aclk) begin
    if (!aresetn) begin
      ar_addr <= 1'sb0;
    end else if (ar_hsk) begin
      ar_addr <= s_axi_araddr;
    end
  end

  // ar_req ar_valid wr_valid int_rd_req ar_req_next
  //      0        0        0          0           0
  //      0        0        0          1           0
  //      0        0        1          0           0
  //      0        0        1          1           0
  //      0        1        0          0           0
  //      0        1        0          1           1 *
  //      0        1        1          0           1 *
  //      0        1        1          1           1 *
  //      1        0        0          0           0 *
  //      1        0        0          1           1
  //      1        0        1          0           1
  //      1        0        1          1           1
  //      1        1        0          0           0 *
  //      1        1        0          1           1
  //      1        1        1          0           1
  //      1        1        1          1           1
  always @(posedge aclk) begin
    if (!aresetn) begin
      ar_req <= 1'b0;
    end else if (ar_hsk && (wr_valid || int_rd_req)) begin
      ar_req <= 1'b1;
    end else if (ar_req && ~wr_valid && ~int_rd_req) begin
      ar_req <= 1'b0;
    end else begin
      ar_req <= ar_req;
    end
  end

  // ar_ready = ~ar_req, unless under reset
  always @(posedge aclk) begin
    if (!aresetn) begin
      ar_ready <= 1'b0;
    end else if (~init_n) begin
      ar_ready <= 1'b1;
    end else if (ar_hsk && (wr_valid || int_rd_req)) begin
      ar_ready <= 1'b0;
    end else if (ar_req && ~wr_valid && ~int_rd_req) begin
      ar_ready <= 1'b1;
    end else begin
      ar_ready <= ar_ready;
    end
  end

  // Read response

  assign r_hsk        = (s_axi_rvalid && s_axi_rready);
  assign s_axi_rdata  = r_data;
  assign s_axi_rresp  = r_resp;
  assign s_axi_rvalid = r_valid;

  always @(posedge aclk) begin
    if (!aresetn) begin
      r_data <= 1'sb0;
    end else if (~(r_valid && ~s_axi_rready) && int_rd_pend) begin
      r_data <= ipif_rd_data_reg;
    end else if (~(r_valid && ~s_axi_rready) && (int_rd_req && ipif_rd_ack)) begin
      r_data <= ipif_rd_data;
    end
  end

  always @(posedge aclk) begin
    if (!aresetn) begin
      r_resp <= 2'b00;
    end else if (~(r_valid && ~s_axi_rready) && int_rd_pend) begin
      r_resp <= {2{ipif_rd_err_reg}};
    end else if (~(r_valid && ~s_axi_rready) && (int_rd_req && ipif_rd_ack)) begin
      r_resp <= {2{ipif_rd_err}};
    end
  end

  // r_valid s_axi_rready (int_rd_req && ipif_rd_ack) int_rd_pend r_valid_next
  //       0            0                          0           0            0
  //       0            0                          0           1            1 *
  //       0            0                          1           0            1 *
  //       0            0                          1           1            1 *
  //       0            1                          0           0            0
  //       0            1                          0           1            1 *
  //       0            1                          1           0            1 *
  //       0            1                          1           1            1 *
  //       1            0                          0           0            1
  //       1            0                          0           1            1
  //       1            0                          1           0            1
  //       1            0                          1           1            1
  //       1            1                          0           0            0 *
  //       1            1                          0           1            1
  //       1            1                          1           0            1
  //       1            1                          1           1            1
  always @(posedge aclk) begin
    if (!aresetn) begin
      r_valid <= 1'b0;
    end else if (r_hsk && ~(int_rd_req && ipif_rd_ack) && ~int_rd_pend) begin
      r_valid <= 1'b0;
    end else if ((int_rd_req && ipif_rd_ack) || int_rd_pend) begin
      r_valid <= 1'b1;
    end else begin
      r_valid <= r_valid;
    end
  end

  // Internal interface
  //-------------------

  assign wr_valid = (aw_hsk || aw_req) && (w_hsk || w_req);

  assign rd_valid = ~wr_valid && (ar_hsk || ar_req);

  // Write / read arbitration

  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      ipif_addr <= 1'sb0;
    end else if (aw_req && (w_hsk || w_req) && ~int_wr_req) begin
      ipif_addr <= aw_addr;
    end else if (aw_hsk && (w_hsk || w_req) && ~int_wr_req) begin
      ipif_addr <= s_axi_awaddr;
    end else if (~wr_valid && ar_req && ~int_rd_req) begin
      ipif_addr <= ar_addr;
    end else if (~wr_valid && ar_hsk && ~int_rd_req) begin
      ipif_addr <= s_axi_araddr;
    end
  end

  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      ipif_wr_data <= 1'sb0;
    end else if (w_req && (aw_hsk || aw_req) && ~int_wr_req) begin
      ipif_wr_data <= w_data;
    end else if (w_hsk && (aw_hsk || aw_req) && ~int_wr_req) begin
      ipif_wr_data <= s_axi_wdata;
    end
  end

  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      ipif_wr_be <= 2'b00;
    end else if (w_req && (aw_hsk || aw_req) && ~int_wr_req) begin
      ipif_wr_be <= w_strb;
    end else if (w_hsk && (aw_hsk || aw_req) && ~int_wr_req) begin
      ipif_wr_be <= s_axi_wstrb;
    end
  end

  always @(posedge s_axi_aclk) begin
    if (wr_valid && ~int_wr_req) begin
      ipif_wr_en <= 1'b1;
    end else begin
      ipif_wr_en <= 1'b0;
    end
  end

  always @(posedge s_axi_aclk) begin
    if (rd_valid && ~int_rd_req) begin
      ipif_rd_en <= 1'b1;
    end else begin
      ipif_rd_en <= 1'b0;
    end
  end

  // Response

  always @(posedge s_axi_aclk) begin
    if (int_wr_req && ipif_wr_ack) begin
      ipif_wr_err_reg <= ipif_wr_err;
    end
  end

  always @(posedge s_axi_aclk) begin
    if (int_rd_req && ipif_rd_ack) begin
      ipif_rd_err_reg <= ipif_rd_err;
    end
  end

  always @(posedge s_axi_aclk) begin
    if (int_rd_req && ipif_rd_ack) begin
      ipif_rd_data_reg <= ipif_rd_data;
    end
  end

  // Internal state

  // int_wr_req wr_valid (ipif_wr_ack || int_wr_pend) (b_valid && ~s_axi_bready) int_wr_req_next
  //          0        0                           0                          0               0
  //          0        0                           0                          1               0
  //          0        0                           1                          0               0
  //          0        0                           1                          1               0
  //          0        1                           0                          0               1 *
  //          0        1                           0                          1               1 *
  //          0        1                           1                          0               1 *
  //          0        1                           1                          1               1 *
  //          1        0                           0                          0               1
  //          1        0                           0                          1               1
  //          1        0                           1                          0               0 *
  //          1        0                           1                          1               1
  //          1        1                           0                          0               1
  //          1        1                           0                          1               1
  //          1        1                           1                          0               0 *
  //          1        1                           1                          1               1
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      int_wr_req <= 1'b0;
    end else if (~int_wr_req && wr_valid) begin
      int_wr_req <= 1'b1;
    end else if (int_wr_req && (ipif_wr_ack || int_wr_pend) && ~(b_valid && ~s_axi_bready)) begin
      int_wr_req <= 1'b0;
    end else begin
      int_wr_req <= int_wr_req;
    end
  end

  // int_wr_pend int_wr_req ipif_wr_ack (b_valid && ~s_axi_bready) int_wr_pend_next
  //           0          0          0                          0                0
  //           0          0          0                          1                0
  //           0          0          1                          0                0
  //           0          0          1                          1                0
  //           0          1          0                          0                0
  //           0          1          0                          1                0
  //           0          1          1                          0                0
  //           0          1          1                          1                1 *
  //           1          0          0                          0                -
  //           1          0          0                          1                -
  //           1          0          1                          0                -
  //           1          0          1                          1                -
  //           1          1          0                          0                0 *
  //           1          1          0                          1                1
  //           1          1          1                          0                0 *
  //           1          1          1                          1                1
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      int_wr_pend <= 1'b0;
    end else if (int_wr_req && ipif_wr_ack && (b_valid && ~s_axi_bready)) begin
      int_wr_pend <= 1'b1;
    end else if (int_wr_pend && ~(b_valid && ~s_axi_bready)) begin
      int_wr_pend <= 1'b0;
    end else begin
      int_wr_pend <= int_wr_pend;
    end
  end

  // int_rd_req rd_valid (ipif_rd_ack || int_rd_pend) (r_valid && ~s_axi_rready) int_rd_req_next
  //          0        0                           0                          0               0
  //          0        0                           0                          1               0
  //          0        0                           1                          0               0
  //          0        0                           1                          1               0
  //          0        1                           0                          0               1 *
  //          0        1                           0                          1               1 *
  //          0        1                           1                          0               1 *
  //          0        1                           1                          1               1 *
  //          1        0                           0                          0               1
  //          1        0                           0                          1               1
  //          1        0                           1                          0               0 *
  //          1        0                           1                          1               1
  //          1        1                           0                          0               1
  //          1        1                           0                          1               1
  //          1        1                           1                          0               0 *
  //          1        1                           1                          1               1
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      int_rd_req <= 1'b0;
    end else if (~int_rd_req && rd_valid) begin
      int_rd_req <= 1'b1;
    end else if (int_rd_req && (ipif_rd_ack || int_rd_pend) && ~(r_valid && ~s_axi_rready)) begin
      int_rd_req <= 1'b0;
    end else begin
      int_rd_req <= int_rd_req;
    end
  end

  // int_rd_pend int_rd_req ipif_rd_ack (r_valid && ~s_axi_rready) int_rd_pend_next
  //           0          0          0                          0                0
  //           0          0          0                          1                0
  //           0          0          1                          0                0
  //           0          0          1                          1                0
  //           0          1          0                          0                0
  //           0          1          0                          1                0
  //           0          1          1                          0                0
  //           0          1          1                          1                1 *
  //           1          0          0                          0                -
  //           1          0          0                          1                -
  //           1          0          1                          0                -
  //           1          0          1                          1                -
  //           1          1          0                          0                0 *
  //           1          1          0                          1                1
  //           1          1          1                          0                0 *
  //           1          1          1                          1                1
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      int_rd_pend <= 1'b0;
    end else if (int_rd_req && ipif_rd_ack && (r_valid && ~s_axi_rready)) begin
      int_rd_pend <= 1'b1;
    end else if (int_rd_pend && ~(r_valid && ~s_axi_rready)) begin
      int_rd_pend <= 1'b0;
    end else begin
      int_rd_pend <= int_rd_pend;
    end
  end

endmodule

`default_nettype wire

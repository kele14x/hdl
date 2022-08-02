// File: axi4l_ipif.sv
// Brief: AXI4-Lite to IP interface. This module is used to connect a AXI4-Lite
//        master, and helps to do:
//
//        1. Combine the write and read operation into one port. This help the
//           later module to use one address decoder for both write and read.
//           Also this ensures there will not be conflict between the write and
//           read operation.
//        2. Buffer the response data, so later module does not need to care
//           about the if AXI4-Lite master does not accept the response data.
//
// Note: AxPROT not supported (not connected)
//
`timescale 1 ns / 1 ps
//
`default_nettype none

module axi4l_ipif #(
    parameter int ADDR_WIDTH = 12,
    parameter int DATA_WIDTH = 32
) (
    // AXI4-Lite Slave
    //=================
    input var                     aclk,
    input var                     aresetn,
    //
    input var  [  ADDR_WIDTH-1:0] s_axi_awaddr,
    input var  [             2:0] s_axi_awprot,
    input var                     s_axi_awvalid,
    output var                    s_axi_awready,
    //
    input var  [  DATA_WIDTH-1:0] s_axi_wdata,
    input var  [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input var                     s_axi_wvalid,
    output var                    s_axi_wready,
    //
    output var [             1:0] s_axi_bresp,
    output var                    s_axi_bvalid,
    input var                     s_axi_bready,
    //
    input var  [  ADDR_WIDTH-1:0] s_axi_araddr,
    input var  [             2:0] s_axi_arprot,
    input var                     s_axi_arvalid,
    output var                    s_axi_arready,
    //
    output var [  DATA_WIDTH-1:0] s_axi_rdata,
    output var [             1:0] s_axi_rresp,
    output var                    s_axi_rvalid,
    input var                     s_axi_rready,
    // IP i/f
    //=======
    output var [  ADDR_WIDTH-1:0] ipif_addr,
    output var                    ipif_req,
    output var                    ipif_req_is_wr,
    //
    output var [DATA_WIDTH/8-1:0] ipif_wr_be,
    output var [  DATA_WIDTH-1:0] ipif_wr_data,
    input var                     ipif_wr_ack,
    input var                     ipif_wr_err,
    //
    input var  [  DATA_WIDTH-1:0] ipif_rd_data,
    input var                     ipif_rd_ack,
    input var                     ipif_rd_err
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
  //=================

  // RRESP/BRESP
  localparam logic [1:0] RespOkey = 2'b00;  // OKAY, normal access success
  localparam logic [1:0] RespExokay = 2'b01;  // EXOKAY, exclusive access success
  localparam logic [1:0] RespSlverr = 2'b10;  // SLVERR, slave error
  localparam logic [1:0] RespDecerr = 2'b11;  // DECERR, decoder error


  // // FSM

  // typedef enum int {
  //   S_RST,
  //   S_IDLE,
  //   S_VALID,
  //   S_RESP
  // } state_t;

  // state_t state, state_next;

  // always_ff @(posedge aclk) begin
  //   if (!aresetn) begin
  //     state <= S_RST;
  //   end else begin
  //     state <= state_next;
  //   end
  // end

  // always_comb begin
  //   case(state)
  //     S_RST: begin
  //       state_next = S_IDLE;
  //     end
  //     S_IDLE: begin
  //       if (rd_addr_valid || (wr_addr_valid && wr_data_valid)) begin
  //         state_next = S_VALID;
  //       end else begin
  //         state_next = S_IDLE;
  //       end
  //     end
  //     S_VALID: begin
  //       if (rd_ack || wr_ack) begin
  //         state_next = S_RESP;
  //       end else begin
  //         state_next = S_VALID;
  //       end
  //     end
  //     S_RESP: begin
  //       if (s_axi_bready) begin
  //         if (rd_addr_valid || (wr_addr_valid && wr_data_valid)) begin
  //           state_next = S_VALID;
  //         end else begin
  //           state_next = S_IDLE;
  //         end
  //       end else begin
  //         state_next = S_RSSP;
  //       end
  //     end
  //     default: begin
  //       state_next = S_RST;
  //     end
  //   endcase
  // end

  // Accept AXI4-Lite AW/W/AR
  //=========================

  var logic [  ADDR_WIDTH-1:0] wr_addr;
  var logic [DATA_WIDTH/8-1:0] wr_be;
  var logic [  DATA_WIDTH-1:0] wr_data;
  var logic                    wr_addr_valid;
  var logic                    wr_data_valid;
  var logic                    wr_accept;
  var logic                    wr_in_flight;

  var logic [  ADDR_WIDTH-1:0] rd_addr;
  var logic                    rd_addr_valid;
  var logic                    rd_accept;
  var logic                    rd_in_flight;


  // AW
  //---

  // If write address is provided, register it for later use.
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      wr_addr <= '0;
      wr_addr_valid <= 1'b0;
    end else if (s_axi_awvalid && s_axi_awready) begin
      wr_addr <= s_axi_awaddr[ADDR_WIDTH-1:0];
      wr_addr_valid <= 1'b1;
    end else if (wr_accept) begin
      wr_addr_valid <= 1'b0;
    end
  end

  // Slave can accept write address if registered address is not valid (previous
  // transaction done), or if current transaction is about to be accept.
  assign s_axi_awready = (!wr_addr_valid || wr_accept);

  // W
  //--

  // If write data is provided, register it for later use.
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      wr_data <= 'd0;
      wr_be <= 'd0;
      wr_data_valid <= 1'b0;
    end else if (s_axi_wvalid && s_axi_wready) begin
      wr_data <= s_axi_wdata;
      wr_be <= s_axi_wstrb;
      wr_data_valid <= 1'b1;
    end else if (wr_accept) begin
      wr_data_valid <= 1'b0;
    end
  end

  // Slave can accept write data if registered data is not valid (previous
  // transaction done), or if current transaction is about to be accept.
  assign s_axi_wready = (!wr_data_valid || wr_accept);

  // AR
  //---

  // If read address is provided, register it for later use.
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      rd_addr       <= 'd0;
      rd_addr_valid <= 1'b0;
    end else if (s_axi_arvalid && s_axi_arready) begin
      rd_addr       <= s_axi_araddr[ADDR_WIDTH-1:2];
      rd_addr_valid <= 1'b1;
    end else if (rd_accept) begin
      rd_addr_valid <= 1'b0;
    end
  end

  // Slave can accept read address if registered address is not valid (previous
  // transaction done), or if current transaction is about to be accept.
  assign s_axi_arready = (!rd_addr_valid || rd_accept);


  // Send request to next
  //======================

  // Read has higher priority than
  always_comb begin
    ipif_addr = '0;
    ipif_req = 1'b0;
    ipif_req_is_wr = 1'b0;
    ipif_wr_be = '0;
    ipif_wr_data = '0;
    wr_accept = 1'b0;
    rd_accept = 1'b0;
    if (rd_addr_valid && !rd_in_flight && (!s_axi_rvalid || s_axi_rready)) begin
      ipif_addr = rd_addr;
      ipif_req = 1'b1;
      ipif_req_is_wr = 1'b0;
      ipif_wr_be = '0;
      ipif_wr_data = '0;
      rd_accept = 1'b1;
    end else if (wr_addr_valid && wr_data_valid && !wr_in_flight && (!s_axi_bvalid || s_axi_bready)) begin
      ipif_addr = wr_addr;
      ipif_req = 1'b1;
      ipif_req_is_wr = 1'b1;
      ipif_wr_be = wr_be;
      ipif_wr_data = wr_data;
      wr_accept = 1'b1;
    end
  end

  // Keep track if current transaction is in flight.
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      wr_in_flight <= 1'b0;
    end else if (ipif_req && ipif_req_is_wr && !ipif_wr_ack) begin
      wr_in_flight <= 1'b1;
    end else if (ipif_wr_ack) begin
      wr_in_flight <= 1'b0;
    end
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      rd_in_flight <= 1'b0;
    end else if (ipif_req && !ipif_req_is_wr && !ipif_rd_ack) begin
      rd_in_flight <= 1'b1;
    end else if (ipif_rd_ack) begin
      rd_in_flight <= 1'b0;
    end
  end

  // AXI4-Lite B/R responses
  //========================

  // B (Write response)

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      s_axi_bvalid <= 1'b0;
    end else if (ipif_wr_ack) begin
      s_axi_bvalid <= 1'b1;
    end else if (s_axi_bready) begin
      s_axi_bvalid <= 1'b0;
    end
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      s_axi_bresp <= 0;
    end else if (ipif_wr_ack && ipif_wr_err) begin
      s_axi_bresp <= RespSlverr;
    end else if (ipif_wr_ack) begin
      s_axi_bresp <= RespOkey;
    end
  end

  // R (Read response)

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      s_axi_rvalid <= 1'b0;
    end else if (ipif_rd_ack) begin
      s_axi_rvalid <= 1'b1;
    end else if (s_axi_rready) begin
      s_axi_rvalid <= 1'b0;
    end
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      s_axi_rdata <= 0;
    end else if (ipif_rd_ack) begin
      s_axi_rdata <= ipif_rd_data;
    end
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      s_axi_rresp <= 0;
    end else if (ipif_rd_ack && ipif_rd_err) begin
      s_axi_rresp <= RespSlverr;
    end else if (ipif_rd_ack) begin
      s_axi_rresp <= RespOkey;
    end
  end

endmodule

`default_nettype wire

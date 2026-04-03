// File: axi4l_ipif.sv
// Brief: AXI4-Lite to Internal Interface
`timescale 1 ns / 1 ps
//
`default_nettype none

module axi4l_ipif #(
    parameter int ADDR_WIDTH = 10,
    parameter int DATA_WIDTH = 32
) (
    // AXI4-Lite Slave Interface
    input  wire                    s_axi_aclk,
    input  wire                    s_axi_aresetn,
    //
    input  wire [  ADDR_WIDTH-1:0] s_axi_awaddr,
    /* verilator lint_off UNUSEDSIGNAL */
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
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [             2:0] s_axi_arprot,
    input  wire                    s_axi_arvalid,
    output wire                    s_axi_arready,
    //
    output wire [  DATA_WIDTH-1:0] s_axi_rdata,
    output wire [             1:0] s_axi_rresp,
    output wire                    s_axi_rvalid,
    input  wire                    s_axi_rready,
    // Internal Interface
    output wire [  ADDR_WIDTH-1:0] int_addr,
    output wire [  DATA_WIDTH-1:0] int_wr_data,
    output wire [DATA_WIDTH/8-1:0] int_wr_strb,
    output wire                    int_wr_en,
    output wire                    int_rd_en,
    //
    input  wire                    int_wr_ack,
    input  wire                    int_wr_err,
    //
    input  wire                    int_rd_ack,
    input  wire                    int_rd_err,
    input  wire [  DATA_WIDTH-1:0] int_rd_data
);

  typedef enum {
    WR_RST,
    WR_IDLE,
    WR_ADDR,
    WR_DATA,
    WR_WAIT,
    WR_RESP
  } wr_state_t;

  typedef enum {
    RD_RST,
    RD_IDLE,
    RD_WAIT,
    RD_RESP
  } rd_state_t;

  // Signals

  // AXI signals

  logic                    awready;
  logic                    wready;
  logic [             1:0] bresp;
  logic                    arready;
  logic [  DATA_WIDTH-1:0] rdata;
  logic [             1:0] rresp;
  logic                    rvalid;

  // Internal signals

  logic [  ADDR_WIDTH-1:0] addr;
  logic [  DATA_WIDTH-1:0] wr_data;
  logic [DATA_WIDTH/8-1:0] wr_strb;
  logic                    wr_en;
  logic                    rd_en;

  // Arbiter

  logic                    rr_state;
  logic                    rr_pending;

  // FSM

  wr_state_t wr_state, wr_state_next;
  rd_state_t rd_state, rd_state_next;

  // Main

  // Write FSM

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      wr_state <= WR_RST;
    end else begin
      wr_state <= wr_state_next;
    end
  end

  always_comb begin
    wr_state_next = wr_state;
    case (wr_state)
      WR_RST: begin
        wr_state_next = WR_IDLE;
      end

      WR_IDLE: begin
        if (s_axi_awvalid && s_axi_wvalid && !rr_pending && (!rr_state || !s_axi_rvalid)) begin
          wr_state_next = WR_WAIT;
        end else if (s_axi_awvalid && !rr_pending && (!rr_state || !s_axi_rvalid)) begin
          wr_state_next = WR_ADDR;
        end else if (s_axi_wvalid && !rr_pending && (!rr_state || !s_axi_rvalid)) begin
          wr_state_next = WR_DATA;
        end
      end

      WR_ADDR: begin
        if (s_axi_wvalid) begin
          wr_state_next = WR_WAIT;
        end
      end

      WR_DATA: begin
        if (s_axi_awvalid) begin
          wr_state_next = WR_WAIT;
        end
      end

      WR_WAIT: begin
        if (int_wr_ack) begin
          wr_state_next = WR_RESP;
        end
      end

      WR_RESP: begin
        if (s_axi_bready) begin
          wr_state_next = WR_IDLE;
        end
      end

      default: begin
        wr_state_next = WR_RST;
      end
    endcase
  end

  // Read FSM

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      rd_state <= RD_RST;
    end else begin
      rd_state <= rd_state_next;
    end
  end

  always_comb begin
    rd_state_next = rd_state;
    case (rd_state)
      RD_RST: begin
        rd_state_next = RD_IDLE;
      end

      RD_IDLE: begin
        if (s_axi_arvalid && !rr_pending && (rr_state || (!s_axi_awvalid && !s_axi_wvalid))) begin
          rd_state_next = RD_WAIT;
        end
      end

      RD_WAIT: begin
        if (int_rd_ack) begin
          rd_state_next = RD_RESP;
        end
      end

      RD_RESP: begin
        if (s_axi_rready) begin
          rd_state_next = RD_IDLE;
        end
      end

      default: begin
        rd_state_next = RD_RST;
      end
    endcase
  end

  // Write / read arbiter

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      rr_state <= 1'b0;
    end else begin
      if (s_axi_awvalid && s_axi_wvalid && !rr_pending && (!rr_state || !s_axi_rvalid)) begin
        rr_state <= 1'b1;
      end else if (s_axi_arvalid && !rr_pending && (rr_state || (!s_axi_awvalid && !s_axi_wvalid))) begin
        rr_state <= 1'b0;
      end
    end
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      rr_pending <= 1'b0;
    end else begin
      if (s_axi_awvalid || s_axi_wvalid || s_axi_arvalid) begin
        rr_pending <= 1'b1;
      end else if ((rr_state && int_wr_ack) || (!rr_state && int_rd_ack)) begin
        rr_pending <= 1'b0;
      end
    end
  end

  // Address write channel

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      awready <= 1'b0;
    end else begin
      awready <= ((wr_state == WR_IDLE) && s_axi_awvalid && !rr_pending && (!rr_state || !s_axi_rvalid)) ||
                 ((wr_state == WR_DATA) && s_axi_awvalid);
    end
  end

  assign s_axi_awready = awready;

  // Write channel

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      wready <= 1'b0;
    end else begin
      wready <= ((wr_state == WR_IDLE) && s_axi_wvalid && !rr_pending && (!rr_state || !s_axi_rvalid)) ||
                ((wr_state == WR_ADDR) && s_axi_wvalid);
    end
  end

  assign s_axi_wready = wready;

  // Write response channel

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      bresp <= 2'b00;
    end else begin
      if ((wr_state == WR_WAIT) && int_wr_ack) begin
        bresp <= int_wr_err ? 2'b10 : 2'b00;
      end
    end
  end

  assign s_axi_bresp  = bresp;

  assign s_axi_bvalid = (wr_state == WR_RESP);

  // Read channel

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      arready <= 1'b0;
    end else begin
      arready <= ((rd_state == RD_IDLE) && s_axi_arvalid && !rr_pending && (rr_state || (!s_axi_awvalid && !s_axi_wvalid)));
    end
  end

  assign s_axi_arready = arready;

  // Read response channel

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      rdata <= {DATA_WIDTH{1'b0}};
      rresp <= 2'b00;
    end else begin
      if ((rd_state == RD_WAIT) && int_rd_ack) begin
        rdata <= int_rd_data;
        rresp <= int_rd_err ? 2'b10 : 2'b00;
      end
    end
  end

  assign s_axi_rdata  = rdata;
  assign s_axi_rresp  = rresp;

  assign s_axi_rvalid = (rd_state == RD_RESP);

  // Internal interface

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      addr <= {ADDR_WIDTH{1'b0}};
    end else begin
      if (s_axi_awvalid && !rr_pending && (!rr_state || !s_axi_rvalid)) begin
        addr <= s_axi_awaddr;
      end else if (s_axi_arvalid && !rr_pending && (rr_state || (!s_axi_awvalid && !s_axi_wvalid))) begin
        addr <= s_axi_araddr;
      end
    end
  end

  assign int_addr = addr;

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      wr_data <= {DATA_WIDTH{1'b0}};
      wr_strb <= {DATA_WIDTH / 8{1'b0}};
    end else begin
      if (s_axi_wvalid && !rr_pending && (!rr_state || !s_axi_rvalid)) begin
        wr_data <= s_axi_wdata;
        wr_strb <= s_axi_wstrb;
      end
    end
  end

  assign int_wr_data = wr_data;
  assign int_wr_strb = wr_strb;

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      wr_en <= 1'b0;
    end else begin
      wr_en <= (wr_state == WR_IDLE) && s_axi_awvalid && s_axi_wvalid && !rr_pending && (!rr_state || !s_axi_rvalid) ||
               (wr_state == WR_ADDR) && s_axi_wvalid ||
               (wr_state == WR_DATA) && s_axi_awvalid;
    end
  end

  assign int_wr_en = wr_en;

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      rd_en <= 1'b0;
    end else begin
      rd_en <= (rd_state == RD_IDLE) && s_axi_arvalid && !rr_pending && (rr_state || (!s_axi_awvalid && !s_axi_wvalid));
    end
  end

  assign int_rd_en = rd_en;

endmodule

`default_nettype wire

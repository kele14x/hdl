`timescale 1 ns / 1 ps
`default_nettype none

// AXI4-Lite adapter for a single command BRAM port. Read and write requests
// each have two entries of response credit and complete independently. Each
// acknowledgement channel must preserve the issue order for its command type.
module axi4l_bram_wr #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
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
    output wire [  ADDR_WIDTH-1:0] bram_addr,
    output wire [  DATA_WIDTH-1:0] bram_wr_data,
    output wire [DATA_WIDTH/8-1:0] bram_wr_strb,
    output wire                    bram_we,
    output wire                    bram_en,
    //
    input  wire                    bram_wr_ack,
    input  wire                    bram_wr_err,
    //
    input  wire [  DATA_WIDTH-1:0] bram_rd_data,
    input  wire                    bram_rd_ack,
    input  wire                    bram_rd_err
);

  localparam integer STRB_WIDTH = DATA_WIDTH / 8;

  logic head_valid;
  logic head_write;
  logic [ADDR_WIDTH-1:0] head_addr;
  logic [DATA_WIDTH-1:0] head_wdata;
  logic [STRB_WIDTH-1:0] head_wstrb;
  logic ar_back_valid;
  logic [ADDR_WIDTH-1:0] ar_back_addr;
  logic aw_back_valid;
  logic [ADDR_WIDTH-1:0] aw_back_addr;
  logic w_back_valid;
  logic [DATA_WIDTH-1:0] w_back_data;
  logic [STRB_WIDTH-1:0] w_back_strb;
  logic priority_read;

  logic [1:0] b_outstanding;
  logic [1:0] r_outstanding;
  logic [1:0] b_wait_ack;
  logic [1:0] r_wait_ack;
  logic [1:0] b_pending;
  logic [1:0] r_pending;
  logic b_err_slot0;
  logic b_err_slot1;
  logic [DATA_WIDTH-1:0] r_slot0;
  logic [DATA_WIDTH-1:0] r_slot1;
  logic r_err_slot0;
  logic r_err_slot1;
  logic [ADDR_WIDTH-1:0] bram_addr_r;
  logic [DATA_WIDTH-1:0] bram_wr_data_r;
  logic [STRB_WIDTH-1:0] bram_wr_strb_r;
  logic bram_we_r;
  logic bram_en_r;

  wire b_hs = bvalid && bready;
  wire r_hs = rvalid && rready;
  wire wr_ack_fire = bram_wr_ack && (b_wait_ack != 2'd0);
  wire rd_ack_fire = bram_rd_ack && (r_wait_ack != 2'd0);
  wire b_credit = (b_outstanding != 2'd2) || b_hs;
  wire r_credit = (r_outstanding != 2'd2) || r_hs;
  wire issue = head_valid && (head_write ? b_credit : r_credit);
  wire issue_write = issue && head_write;
  wire issue_read = issue && !head_write;
  wire head_available = !head_valid || issue;
  wire read_waiting = ar_back_valid || arvalid;
  wire write_waiting = aw_back_valid && w_back_valid;
  wire grant_read = head_available && read_waiting && (!write_waiting || priority_read);
  wire grant_write = head_available && write_waiting && (!read_waiting || !priority_read);
  wire load_read_back = grant_read && ar_back_valid;
  wire load_read_direct = grant_read && !ar_back_valid && arvalid;
  wire load_write_back = grant_write;
  wire ar_hs = arvalid && arready;
  wire aw_hs = awvalid && awready;
  wire w_hs = wvalid && wready;

  assign bvalid = b_pending != 2'd0;
  assign bresp = b_err_slot0 ? 2'b10 : 2'b00;
  assign rvalid = r_pending != 2'd0;
  assign rdata = r_slot0;
  assign rresp = r_err_slot0 ? 2'b10 : 2'b00;
  assign arready = !ar_back_valid || load_read_back;
  assign awready = !aw_back_valid || load_write_back;
  assign wready = !w_back_valid || load_write_back;
  assign bram_addr = bram_addr_r;
  assign bram_wr_data = bram_wr_data_r;
  assign bram_wr_strb = bram_wr_strb_r;
  assign bram_we = bram_we_r;
  assign bram_en = bram_en_r;

  initial begin : drc_check
    assert (ADDR_WIDTH > 0)
    else $error("ADDR_WIDTH must be positive");
    assert (DATA_WIDTH > 0 && DATA_WIDTH % 8 == 0)
    else $error("DATA_WIDTH must be a positive multiple of 8");
  end

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) priority_read <= 1'b1;
    else if (grant_read) priority_read <= 1'b0;
    else if (grant_write) priority_read <= 1'b1;
  end

  // Keep one head command plus one independent backup for AR, AW and W.
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      head_valid <= 1'b0;
      head_write <= 1'b0;
      head_addr <= {ADDR_WIDTH{1'b0}};
      head_wdata <= {DATA_WIDTH{1'b0}};
      head_wstrb <= {STRB_WIDTH{1'b0}};
      ar_back_valid <= 1'b0;
      ar_back_addr <= {ADDR_WIDTH{1'b0}};
      aw_back_valid <= 1'b0;
      aw_back_addr <= {ADDR_WIDTH{1'b0}};
      w_back_valid <= 1'b0;
      w_back_data <= {DATA_WIDTH{1'b0}};
      w_back_strb <= {STRB_WIDTH{1'b0}};
    end else begin
      if (load_read_back) begin
        head_valid <= 1'b1;
        head_write <= 1'b0;
        head_addr  <= ar_back_addr;
      end else if (load_read_direct) begin
        head_valid <= 1'b1;
        head_write <= 1'b0;
        head_addr  <= araddr;
      end else if (load_write_back) begin
        head_valid <= 1'b1;
        head_write <= 1'b1;
        head_addr  <= aw_back_addr;
        head_wdata <= w_back_data;
        head_wstrb <= w_back_strb;
      end else if (issue) begin
        head_valid <= 1'b0;
      end

      if (ar_hs && !load_read_direct) begin
        ar_back_valid <= 1'b1;
        ar_back_addr  <= araddr;
      end else if (load_read_back) begin
        ar_back_valid <= 1'b0;
      end
      if (aw_hs) begin
        aw_back_valid <= 1'b1;
        aw_back_addr  <= awaddr;
      end else if (load_write_back) begin
        aw_back_valid <= 1'b0;
      end
      if (w_hs) begin
        w_back_valid <= 1'b1;
        w_back_data  <= wdata;
        w_back_strb  <= wstrb;
      end else if (load_write_back) begin
        w_back_valid <= 1'b0;
      end
    end
  end

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      bram_addr_r <= {ADDR_WIDTH{1'b0}};
      bram_wr_data_r <= {DATA_WIDTH{1'b0}};
      bram_wr_strb_r <= {STRB_WIDTH{1'b0}};
      bram_we_r <= 1'b0;
      bram_en_r <= 1'b0;
    end else begin
      bram_en_r <= issue;
      if (issue) begin
        bram_addr_r <= head_addr;
        bram_wr_data_r <= head_wdata;
        bram_wr_strb_r <= head_wstrb;
        bram_we_r <= head_write;
      end
    end
  end

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      b_outstanding <= 2'd0;
      r_outstanding <= 2'd0;
      b_wait_ack <= 2'd0;
      r_wait_ack <= 2'd0;
      b_pending <= 2'd0;
      r_pending <= 2'd0;
      b_err_slot0 <= 1'b0;
      b_err_slot1 <= 1'b0;
      r_slot0 <= {DATA_WIDTH{1'b0}};
      r_slot1 <= {DATA_WIDTH{1'b0}};
      r_err_slot0 <= 1'b0;
      r_err_slot1 <= 1'b0;
    end else begin
      case ({
        issue_write, b_hs
      })
        2'b10:   b_outstanding <= b_outstanding + 2'd1;
        2'b01:   b_outstanding <= b_outstanding - 2'd1;
        default: b_outstanding <= b_outstanding;
      endcase
      case ({
        issue_read, r_hs
      })
        2'b10:   r_outstanding <= r_outstanding + 2'd1;
        2'b01:   r_outstanding <= r_outstanding - 2'd1;
        default: r_outstanding <= r_outstanding;
      endcase

      case ({
        issue_write, wr_ack_fire
      })
        2'b10:   b_wait_ack <= b_wait_ack + 2'd1;
        2'b01:   b_wait_ack <= b_wait_ack - 2'd1;
        default: b_wait_ack <= b_wait_ack;
      endcase
      case ({
        issue_read, rd_ack_fire
      })
        2'b10:   r_wait_ack <= r_wait_ack + 2'd1;
        2'b01:   r_wait_ack <= r_wait_ack - 2'd1;
        default: r_wait_ack <= r_wait_ack;
      endcase

      case ({
        wr_ack_fire, b_hs
      })
        2'b10: begin
          if (b_pending == 2'd0) b_err_slot0 <= bram_wr_err;
          else b_err_slot1 <= bram_wr_err;
          b_pending <= b_pending + 2'd1;
        end
        2'b01: begin
          if (b_pending == 2'd2) b_err_slot0 <= b_err_slot1;
          b_pending <= b_pending - 2'd1;
        end
        2'b11: begin
          if (b_pending == 2'd1) b_err_slot0 <= bram_wr_err;
          else begin
            b_err_slot0 <= b_err_slot1;
            b_err_slot1 <= bram_wr_err;
          end
        end
        default: b_pending <= b_pending;
      endcase

      case ({
        rd_ack_fire, r_hs
      })
        2'b10: begin
          if (r_pending == 2'd0) begin
            r_slot0 <= bram_rd_data;
            r_err_slot0 <= bram_rd_err;
          end else begin
            r_slot1 <= bram_rd_data;
            r_err_slot1 <= bram_rd_err;
          end
          r_pending <= r_pending + 2'd1;
        end
        2'b01: begin
          if (r_pending == 2'd2) begin
            r_slot0 <= r_slot1;
            r_err_slot0 <= r_err_slot1;
          end
          r_pending <= r_pending - 2'd1;
        end
        2'b11: begin
          if (r_pending == 2'd1) begin
            r_slot0 <= bram_rd_data;
            r_err_slot0 <= bram_rd_err;
          end else begin
            r_slot0 <= r_slot1;
            r_err_slot0 <= r_err_slot1;
            r_slot1 <= bram_rd_data;
            r_err_slot1 <= bram_rd_err;
          end
        end
        default: r_pending <= r_pending;
      endcase
    end
  end
endmodule

`default_nettype wire

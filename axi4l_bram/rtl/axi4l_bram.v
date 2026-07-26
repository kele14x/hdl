`timescale 1 ns / 1 ps
`default_nettype none

// AXI4-Lite adapter for a single command/response BRAM port.  Read and write
// requests each have two entries of response credit; BRAM acknowledgements
// must arrive in the same order as bram_en commands.
module axi4l_bram #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input wire aclk,
    input wire aresetn,
    input wire [ADDR_WIDTH-1:0] awaddr,
    input wire awvalid,
    output wire awready,
    input wire [DATA_WIDTH-1:0] wdata,
    input wire [DATA_WIDTH/8-1:0] wstrb,
    input wire wvalid,
    output wire wready,
    output wire [1:0] bresp,
    output wire bvalid,
    input wire bready,
    input wire [ADDR_WIDTH-1:0] araddr,
    input wire arvalid,
    output wire arready,
    output wire [DATA_WIDTH-1:0] rdata,
    output wire [1:0] rresp,
    output wire rvalid,
    input wire rready,
    output wire [ADDR_WIDTH-1:0] bram_addr,
    output wire [DATA_WIDTH-1:0] bram_wdata,
    output wire [DATA_WIDTH/8-1:0] bram_wstrb,
    output wire bram_we,
    output wire bram_en,
    input wire [DATA_WIDTH-1:0] bram_rdata,
    input wire bram_ack
);

  localparam integer STRB_WIDTH = DATA_WIDTH / 8;

  reg head_valid;
  reg head_write;
  reg [ADDR_WIDTH-1:0] head_addr;
  reg [DATA_WIDTH-1:0] head_wdata;
  reg [STRB_WIDTH-1:0] head_wstrb;
  reg ar_back_valid;
  reg [ADDR_WIDTH-1:0] ar_back_addr;
  reg aw_back_valid;
  reg [ADDR_WIDTH-1:0] aw_back_addr;
  reg w_back_valid;
  reg [DATA_WIDTH-1:0] w_back_data;
  reg [STRB_WIDTH-1:0] w_back_strb;
  reg priority_read;

  // tag0 is the oldest unacknowledged BRAM command.
  reg [2:0] tag_count;
  reg tag0_write;
  reg tag1_write;
  reg tag2_write;
  reg tag3_write;
  reg [1:0] b_outstanding;
  reg [1:0] r_outstanding;
  reg [1:0] b_pending;
  reg [1:0] r_pending;
  reg [DATA_WIDTH-1:0] r_slot0;
  reg [DATA_WIDTH-1:0] r_slot1;
  reg [ADDR_WIDTH-1:0] bram_addr_r;
  reg [DATA_WIDTH-1:0] bram_wdata_r;
  reg [STRB_WIDTH-1:0] bram_wstrb_r;
  reg bram_we_r;
  reg bram_en_r;

  wire b_hs = bvalid && bready;
  wire r_hs = rvalid && rready;
  wire ack_fire = bram_ack && (tag_count != 3'd0);
  wire ack_write = ack_fire && tag0_write;
  wire ack_read = ack_fire && !tag0_write;
  wire b_credit = (b_outstanding != 2'd2) || b_hs;
  wire r_credit = (r_outstanding != 2'd2) || r_hs;
  wire tag_credit = (tag_count != 3'd4) || ack_fire;
  wire issue = head_valid && tag_credit && (head_write ? b_credit : r_credit);
  wire issue_write = issue && head_write;
  wire head_available = !head_valid || issue;
  wire read_waiting = ar_back_valid || arvalid;
  wire write_waiting = aw_back_valid && w_back_valid;
  wire grant_read = head_available && read_waiting &&
                    (!write_waiting || priority_read);
  wire grant_write = head_available && write_waiting &&
                     (!read_waiting || !priority_read);
  wire load_read_back = grant_read && ar_back_valid;
  wire load_read_direct = grant_read && !ar_back_valid && arvalid;
  wire load_write_back = grant_write;
  wire ar_hs = arvalid && arready;
  wire aw_hs = awvalid && awready;
  wire w_hs = wvalid && wready;

  assign bvalid = b_pending != 2'd0;
  assign bresp = 2'b00;
  assign rvalid = r_pending != 2'd0;
  assign rdata = r_slot0;
  assign rresp = 2'b00;
  assign arready = !ar_back_valid || load_read_back;
  assign awready = !aw_back_valid || load_write_back;
  assign wready = !w_back_valid || load_write_back;
  assign bram_addr = bram_addr_r;
  assign bram_wdata = bram_wdata_r;
  assign bram_wstrb = bram_wstrb_r;
  assign bram_we = bram_we_r;
  assign bram_en = bram_en_r;

  initial begin : drc_check
    assert (ADDR_WIDTH > 0) else $error("ADDR_WIDTH must be positive");
    assert (DATA_WIDTH > 0 && DATA_WIDTH % 8 == 0)
        else $error("DATA_WIDTH must be a positive multiple of 8");
  end

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) priority_read <= 1'b1;
    else if (grant_read) priority_read <= 1'b0;
    else if (grant_write) priority_read <= 1'b1;
  end

  // Keep one head command plus one independent backup for AR, AW and W.
  always @(posedge aclk or negedge aresetn) begin
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
        head_addr <= ar_back_addr;
      end else if (load_read_direct) begin
        head_valid <= 1'b1;
        head_write <= 1'b0;
        head_addr <= araddr;
      end else if (load_write_back) begin
        head_valid <= 1'b1;
        head_write <= 1'b1;
        head_addr <= aw_back_addr;
        head_wdata <= w_back_data;
        head_wstrb <= w_back_strb;
      end else if (issue) begin
        head_valid <= 1'b0;
      end

      if (ar_hs && !load_read_direct) begin
        ar_back_valid <= 1'b1;
        ar_back_addr <= araddr;
      end else if (load_read_back) begin
        ar_back_valid <= 1'b0;
      end
      if (aw_hs) begin
        aw_back_valid <= 1'b1;
        aw_back_addr <= awaddr;
      end else if (load_write_back) begin
        aw_back_valid <= 1'b0;
      end
      if (w_hs) begin
        w_back_valid <= 1'b1;
        w_back_data <= wdata;
        w_back_strb <= wstrb;
      end else if (load_write_back) begin
        w_back_valid <= 1'b0;
      end
    end
  end

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      bram_addr_r <= {ADDR_WIDTH{1'b0}};
      bram_wdata_r <= {DATA_WIDTH{1'b0}};
      bram_wstrb_r <= {STRB_WIDTH{1'b0}};
      bram_we_r <= 1'b0;
      bram_en_r <= 1'b0;
    end else begin
      bram_en_r <= issue;
      if (issue) begin
        bram_addr_r <= head_addr;
        bram_wdata_r <= head_wdata;
        bram_wstrb_r <= head_wstrb;
        bram_we_r <= head_write;
      end
    end
  end

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      tag_count <= 3'd0;
      tag0_write <= 1'b0;
      tag1_write <= 1'b0;
      tag2_write <= 1'b0;
      tag3_write <= 1'b0;
    end else begin
      case ({issue, ack_fire})
        2'b10: begin
          case (tag_count)
            3'd0: tag0_write <= head_write;
            3'd1: tag1_write <= head_write;
            3'd2: tag2_write <= head_write;
            default: tag3_write <= head_write;
          endcase
          tag_count <= tag_count + 3'd1;
        end
        2'b01: begin
          tag0_write <= tag1_write;
          tag1_write <= tag2_write;
          tag2_write <= tag3_write;
          tag_count <= tag_count - 3'd1;
        end
        2'b11: begin
          case (tag_count)
            3'd1: tag0_write <= head_write;
            3'd2: begin tag0_write <= tag1_write; tag1_write <= head_write; end
            3'd3: begin
              tag0_write <= tag1_write;
              tag1_write <= tag2_write;
              tag2_write <= head_write;
            end
            default: begin
              tag0_write <= tag1_write;
              tag1_write <= tag2_write;
              tag2_write <= tag3_write;
              tag3_write <= head_write;
            end
          endcase
        end
        default: tag_count <= tag_count;
      endcase
    end
  end

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      b_outstanding <= 2'd0;
      r_outstanding <= 2'd0;
      b_pending <= 2'd0;
      r_pending <= 2'd0;
      r_slot0 <= {DATA_WIDTH{1'b0}};
      r_slot1 <= {DATA_WIDTH{1'b0}};
    end else begin
      case ({issue_write, b_hs})
        2'b10: b_outstanding <= b_outstanding + 2'd1;
        2'b01: b_outstanding <= b_outstanding - 2'd1;
        default: b_outstanding <= b_outstanding;
      endcase
      case ({issue && !head_write, r_hs})
        2'b10: r_outstanding <= r_outstanding + 2'd1;
        2'b01: r_outstanding <= r_outstanding - 2'd1;
        default: r_outstanding <= r_outstanding;
      endcase
      case ({ack_write, b_hs})
        2'b10: b_pending <= b_pending + 2'd1;
        2'b01: b_pending <= b_pending - 2'd1;
        default: b_pending <= b_pending;
      endcase
      case ({ack_read, r_hs})
        2'b10: begin
          if (r_pending == 2'd0) r_slot0 <= bram_rdata;
          else r_slot1 <= bram_rdata;
          r_pending <= r_pending + 2'd1;
        end
        2'b01: begin
          if (r_pending == 2'd2) r_slot0 <= r_slot1;
          r_pending <= r_pending - 2'd1;
        end
        2'b11: begin
          if (r_pending == 2'd1) r_slot0 <= bram_rdata;
          else begin r_slot0 <= r_slot1; r_slot1 <= bram_rdata; end
        end
        default: r_pending <= r_pending;
      endcase
    end
  end
endmodule

`default_nettype wire

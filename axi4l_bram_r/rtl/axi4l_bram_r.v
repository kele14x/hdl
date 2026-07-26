`timescale 1 ns / 1 ps
//
`default_nettype none

module axi4l_bram_r #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 32
) (
    input  wire                  aclk,
    input  wire                  aresetn,
    //
    input  wire [ADDR_WIDTH-1:0] araddr,
    input  wire                  arvalid,
    output wire                  arready,
    //
    output wire [DATA_WIDTH-1:0] rdata,
    output wire [           1:0] rresp,
    output wire                  rvalid,
    input  wire                  rready,
    //
    output wire [ADDR_WIDTH-1:0] bram_addr,
    output wire                  bram_en,
    //
    input  wire [DATA_WIDTH-1:0] bram_rdata,
    input  wire                  bram_ack,
    input  wire                  bram_err
);

  // 3'b000: under reset
  // 3'b100: no addr is buffered
  // 3'b101: 1 addr slot0 is buffered
  // 3'b011: 2 addr slot0 & slot1 is buffered
  // Note: other states are illegal
  reg  [           2:0] ar_state;
  reg  [           2:0] ar_state_next;

  reg  [ADDR_WIDTH-1:0] ar_slot0;
  reg  [ADDR_WIDTH-1:0] ar_slot1;
  reg  [ADDR_WIDTH-1:0] ar_slot0_next;
  reg  [ADDR_WIDTH-1:0] ar_slot1_next;

  reg                   bram_en_r;

  reg  [           1:0] r_count;
  reg  [           1:0] r_count_next;

  wire                  r_rdy;

  // 2'b00: no read data is buffered
  // 2'b01: 1 read data is buffered at slot0
  // 2'b11: 2 read data is buffered at slot0 & slot1
  // Note: 2'b10 is illegal state
  reg  [           1:0] r_state;
  reg  [           1:0] r_state_next;

  reg  [DATA_WIDTH-1:0] r_slot0;
  reg  [DATA_WIDTH-1:0] r_slot1;
  reg  [DATA_WIDTH-1:0] r_slot0_next;
  reg  [DATA_WIDTH-1:0] r_slot1_next;
  reg                   r_err_slot0;
  reg                   r_err_slot1;
  reg                   r_err_slot0_next;
  reg                   r_err_slot1_next;

  // AR state

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      ar_state <= 3'b000;
    end else begin
      ar_state <= ar_state_next;
    end
  end

  always @(*) begin
    ar_state_next = ar_state;
    case (ar_state)
      3'b000: begin
        ar_state_next = 3'b100;
      end

      3'b100: begin
        if (arvalid) begin
          ar_state_next = 3'b101;
        end
      end

      3'b101: begin
        if (arvalid && r_rdy) begin
          ar_state_next = 3'b101;
        end else if (arvalid) begin
          ar_state_next = 3'b011;
        end else if (r_rdy) begin
          ar_state_next = 3'b100;
        end
      end

      3'b011: begin
        if (r_rdy) begin
          ar_state_next = 3'b101;
        end
      end

      default: begin
        ar_state_next = 3'b000;
      end
    endcase
  end

  // AR channel

  assign arready = ar_state[2];

  // ar_slot0

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      ar_slot0 <= {ADDR_WIDTH{1'b0}};
    end else begin
      ar_slot0 <= ar_slot0_next;
    end
  end

  always @(*) begin
    ar_slot0_next = ar_slot0;
    case (ar_state)
      3'b100: begin
        if (arvalid) begin
          ar_slot0_next = araddr;
        end
      end

      3'b101: begin
        if (arvalid && r_rdy) begin
          ar_slot0_next = araddr;
        end
      end

      3'b011: begin
        if (r_rdy) begin
          ar_slot0_next = ar_slot1;
        end
      end

      default: begin
        ar_slot0_next = ar_slot0;
      end
    endcase
  end

  // ar_slot1

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      ar_slot1 <= {ADDR_WIDTH{1'b0}};
    end else begin
      ar_slot1 <= ar_slot1_next;
    end
  end

  always @(*) begin
    ar_slot1_next = ar_slot1;
    case (ar_state)
      3'b101: begin
        if (arvalid && !r_rdy) begin
          ar_slot1_next = araddr;
        end
      end

      default: begin
        ar_slot1_next = ar_slot1;
      end
    endcase
  end

  // R occupied slots count

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      r_count <= 2'b00;
    end else begin
      r_count <= r_count_next;
    end
  end

  always @(*) begin
    r_count_next = r_count;
    case (r_count)
      2'b00: begin
        if (ar_state[0]) begin
          r_count_next = 2'b01;
        end
      end

      2'b01: begin
        if (ar_state[0] && rvalid && rready) begin
          r_count_next = 2'b01;
        end else if (ar_state[0]) begin
          r_count_next = 2'b10;
        end else if (rvalid && rready) begin
          r_count_next = 2'b00;
        end
      end

      2'b10: begin
        if (rvalid && rready) begin
          r_count_next = 2'b01;
        end
      end

      default: begin
        r_count_next = r_count;
      end
    endcase
  end

  assign r_rdy = ~r_count[1];

  // BRAM

  assign bram_addr = ar_slot0;

  // assign bram_en = ar_state[0] && r_rdy;

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      bram_en_r <= 1'b0;
    end else begin
      bram_en_r <= ar_state_next[0] && ~r_count_next[1];
    end
  end

  assign bram_en = bram_en_r;

  // R state

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      r_state <= 2'b00;
    end else begin
      r_state <= r_state_next;
    end
  end

  always @(*) begin
    r_state_next = r_state;
    case (r_state)
      2'b00: begin
        if (bram_ack) begin
          r_state_next = 2'b01;
        end
      end

      2'b01: begin
        if (bram_ack && rready) begin
          r_state_next = 2'b01;
        end else if (bram_ack) begin
          r_state_next = 2'b11;
        end else if (rready) begin
          r_state_next = 2'b00;
        end
      end

      2'b11: begin
        if (rready) begin
          r_state_next = 2'b01;
        end
      end

      default: begin
        r_state_next = 2'b00;
      end
    endcase
  end

  // r_slot0

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      r_slot0 <= {DATA_WIDTH{1'b0}};
    end else begin
      r_slot0 <= r_slot0_next;
    end
  end

  always @(*) begin
    r_slot0_next = r_slot0;
    case (r_state)
      2'b00: begin
        if (bram_ack) begin
          r_slot0_next = bram_rdata;
        end
      end

      2'b01: begin
        if (bram_ack && rready) begin
          r_slot0_next = bram_rdata;
        end
      end

      2'b11: begin
        if (rready) begin
          r_slot0_next = r_slot1;
        end
      end

      default: begin
        r_slot0_next = r_slot0;
      end
    endcase
  end

  // r_slot1

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      r_slot1 <= {DATA_WIDTH{1'b0}};
    end else begin
      r_slot1 <= r_slot1_next;
    end
  end

  always @(*) begin
    r_slot1_next = r_slot1;
    case (r_state)
      2'b01: begin
        if (bram_ack && !rready) begin
          r_slot1_next = bram_rdata;
        end
      end

      default: begin
        r_slot1_next = r_slot1;
      end
    endcase
  end

  // r_err_slot0

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      r_err_slot0 <= 1'b0;
    end else begin
      r_err_slot0 <= r_err_slot0_next;
    end
  end

  always @(*) begin
    r_err_slot0_next = r_err_slot0;
    case (r_state)
      2'b00: begin
        if (bram_ack) begin
          r_err_slot0_next = bram_err;
        end
      end

      2'b01: begin
        if (bram_ack && rready) begin
          r_err_slot0_next = bram_err;
        end
      end

      2'b11: begin
        if (rready) begin
          r_err_slot0_next = r_err_slot1;
        end
      end

      default: begin
        r_err_slot0_next = r_err_slot0;
      end
    endcase
  end

  // r_err_slot1

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      r_err_slot1 <= 1'b0;
    end else begin
      r_err_slot1 <= r_err_slot1_next;
    end
  end

  always @(*) begin
    r_err_slot1_next = r_err_slot1;
    case (r_state)
      2'b01: begin
        if (bram_ack && !rready) begin
          r_err_slot1_next = bram_err;
        end
      end

      default: begin
        r_err_slot1_next = r_err_slot1;
      end
    endcase
  end

  // R channel

  assign rdata  = r_slot0;
  assign rresp  = r_err_slot0 ? 2'b10 : 2'b00;
  assign rvalid = r_state[0];

endmodule

`default_nettype wire

`timescale 1 ns / 1 ps
//
`default_nettype none

module axi4l_bram_w #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input var                     aclk,
    input var                     aresetn,
    //
    input var  [  ADDR_WIDTH-1:0] awaddr,
    input var                     awvalid,
    output var                    awready,
    //
    input var  [  DATA_WIDTH-1:0] wdata,
    input var  [DATA_WIDTH/8-1:0] wstrb,
    input var                     wvalid,
    output var                    wready,
    //
    output var [             1:0] bresp,
    output var                    bvalid,
    input var                     bready,
    //
    output var [  ADDR_WIDTH-1:0] bram_addr,
    output var [  DATA_WIDTH-1:0] bram_data,
    output var [DATA_WIDTH/8-1:0] bram_strb,
    output var                    bram_we,
    //
    input var                     bram_ack,
    input var                     bram_err
);

  // 3'b000: under reset
  // 3'b100: no addr is buffered
  // 3'b101: 1 addr slot0 is buffered
  // 3'b011: 2 addr slot0 & slot1 is buffered
  // Note: other states are illegal
  logic [                        2:0] aw_state;
  logic [                        2:0] aw_state_next;

  logic [             ADDR_WIDTH-1:0] aw_slot0;
  logic [             ADDR_WIDTH-1:0] aw_slot1;
  logic [             ADDR_WIDTH-1:0] aw_slot0_next;
  logic [             ADDR_WIDTH-1:0] aw_slot1_next;

  // 3'b000: under reset
  // 3'b100: no write data is buffered
  // 3'b101: 1 write data slot0 is buffered
  // 3'b011: 2 write data slot0 & slot1 is buffered
  // Note: other states are illegal
  logic [                        2:0] w_state;
  logic [                        2:0] w_state_next;

  logic [DATA_WIDTH+DATA_WIDTH/8-1:0] w_slot0;
  logic [DATA_WIDTH+DATA_WIDTH/8-1:0] w_slot1;
  logic [DATA_WIDTH+DATA_WIDTH/8-1:0] w_slot0_next;
  logic [DATA_WIDTH+DATA_WIDTH/8-1:0] w_slot1_next;

  logic                               bram_we_r;

  // 2'b00: no write is outstanding
  // 2'b01: 1 write is outstanding
  // 2'b10: 2 writes are outstanding
  logic [                        1:0] b_count;
  logic [                        1:0] b_count_next;

  // 2'b00: no B response is pending
  // 2'b01: 1 B response is pending
  // 2'b10: 2 B responses are pending
  logic [                        1:0] b_pend;
  logic [                        1:0] b_pend_next;
  logic                               b_err_slot0;
  logic                               b_err_slot1;
  logic                               b_err_slot0_next;
  logic                               b_err_slot1_next;

  wire                                b_rdy;
  wire                                b_hs;
  wire                                wr_issue;
  wire                                aw_go;
  wire                                w_go;

  // AW state

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      aw_state <= 3'b000;
    end else begin
      aw_state <= aw_state_next;
    end
  end

  always_comb begin
    aw_state_next = aw_state;
    case (aw_state)
      3'b000: begin
        aw_state_next = 3'b100;
      end

      3'b100: begin
        if (awvalid) begin
          aw_state_next = 3'b101;
        end
      end

      3'b101: begin
        if (awvalid && aw_go) begin
          aw_state_next = 3'b101;
        end else if (awvalid) begin
          aw_state_next = 3'b011;
        end else if (aw_go) begin
          aw_state_next = 3'b100;
        end
      end

      3'b011: begin
        if (aw_go) begin
          aw_state_next = 3'b101;
        end
      end

      default: begin
        aw_state_next = 3'b000;
      end
    endcase
  end

  // AW channel

  assign awready = aw_state[2];

  // aw_slot0

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      aw_slot0 <= {ADDR_WIDTH{1'b0}};
    end else begin
      aw_slot0 <= aw_slot0_next;
    end
  end

  always_comb begin
    aw_slot0_next = aw_slot0;
    case (aw_state)
      3'b100: begin
        if (awvalid) begin
          aw_slot0_next = awaddr;
        end
      end

      3'b101: begin
        if (awvalid && aw_go) begin
          aw_slot0_next = awaddr;
        end
      end

      3'b011: begin
        if (aw_go) begin
          aw_slot0_next = aw_slot1;
        end
      end

      default: begin
        aw_slot0_next = aw_slot0;
      end
    endcase
  end

  // aw_slot1

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      aw_slot1 <= {ADDR_WIDTH{1'b0}};
    end else begin
      aw_slot1 <= aw_slot1_next;
    end
  end

  always_comb begin
    aw_slot1_next = aw_slot1;
    case (aw_state)
      3'b101: begin
        if (awvalid && !aw_go) begin
          aw_slot1_next = awaddr;
        end
      end

      default: begin
        aw_slot1_next = aw_slot1;
      end
    endcase
  end

  // W state

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      w_state <= 3'b000;
    end else begin
      w_state <= w_state_next;
    end
  end

  always_comb begin
    w_state_next = w_state;
    case (w_state)
      3'b000: begin
        w_state_next = 3'b100;
      end

      3'b100: begin
        if (wvalid) begin
          w_state_next = 3'b101;
        end
      end

      3'b101: begin
        if (wvalid && w_go) begin
          w_state_next = 3'b101;
        end else if (wvalid) begin
          w_state_next = 3'b011;
        end else if (w_go) begin
          w_state_next = 3'b100;
        end
      end

      3'b011: begin
        if (w_go) begin
          w_state_next = 3'b101;
        end
      end

      default: begin
        w_state_next = 3'b000;
      end
    endcase
  end

  // W channel

  assign wready = w_state[2];

  // w_slot0

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      w_slot0 <= {(DATA_WIDTH + DATA_WIDTH / 8) {1'b0}};
    end else begin
      w_slot0 <= w_slot0_next;
    end
  end

  always_comb begin
    w_slot0_next = w_slot0;
    case (w_state)
      3'b100: begin
        if (wvalid) begin
          w_slot0_next = {wdata, wstrb};
        end
      end

      3'b101: begin
        if (wvalid && w_go) begin
          w_slot0_next = {wdata, wstrb};
        end
      end

      3'b011: begin
        if (w_go) begin
          w_slot0_next = w_slot1;
        end
      end

      default: begin
        w_slot0_next = w_slot0;
      end
    endcase
  end

  // w_slot1

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      w_slot1 <= {(DATA_WIDTH + DATA_WIDTH / 8) {1'b0}};
    end else begin
      w_slot1 <= w_slot1_next;
    end
  end

  always_comb begin
    w_slot1_next = w_slot1;
    case (w_state)
      3'b101: begin
        if (wvalid && !w_go) begin
          w_slot1_next = {wdata, wstrb};
        end
      end

      default: begin
        w_slot1_next = w_slot1;
      end
    endcase
  end

  // B outstanding writes count

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      b_count <= 2'b00;
    end else begin
      b_count <= b_count_next;
    end
  end

  always_comb begin
    b_count_next = b_count;
    case (b_count)
      2'b00: begin
        if (wr_issue) begin
          b_count_next = 2'b01;
        end
      end

      2'b01: begin
        if (wr_issue && b_hs) begin
          b_count_next = 2'b01;
        end else if (wr_issue) begin
          b_count_next = 2'b10;
        end else if (b_hs) begin
          b_count_next = 2'b00;
        end
      end

      2'b10: begin
        if (b_hs) begin
          b_count_next = 2'b01;
        end
      end

      default: begin
        b_count_next = b_count;
      end
    endcase
  end

  assign b_rdy = ~b_count[1];

  // B pending responses count

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      b_pend <= 2'b00;
    end else begin
      b_pend <= b_pend_next;
    end
  end

  always_comb begin
    b_pend_next = b_pend;
    case (b_pend)
      2'b00: begin
        if (bram_ack) begin
          b_pend_next = 2'b01;
        end
      end

      2'b01: begin
        if (bram_ack && b_hs) begin
          b_pend_next = 2'b01;
        end else if (bram_ack) begin
          b_pend_next = 2'b10;
        end else if (b_hs) begin
          b_pend_next = 2'b00;
        end
      end

      2'b10: begin
        if (b_hs) begin
          b_pend_next = 2'b01;
        end
      end

      default: begin
        b_pend_next = b_pend;
      end
    endcase
  end

  // B response errors

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      b_err_slot0 <= 1'b0;
      b_err_slot1 <= 1'b0;
    end else begin
      b_err_slot0 <= b_err_slot0_next;
      b_err_slot1 <= b_err_slot1_next;
    end
  end

  always_comb begin
    b_err_slot0_next = b_err_slot0;
    b_err_slot1_next = b_err_slot1;
    case (b_pend)
      2'b00: begin
        if (bram_ack) begin
          b_err_slot0_next = bram_err;
        end
      end

      2'b01: begin
        if (bram_ack && b_hs) begin
          b_err_slot0_next = bram_err;
        end else if (bram_ack) begin
          b_err_slot1_next = bram_err;
        end
      end

      2'b10: begin
        if (b_hs) begin
          b_err_slot0_next = b_err_slot1;
        end
      end

      default: begin
        b_err_slot0_next = b_err_slot0;
        b_err_slot1_next = b_err_slot1;
      end
    endcase
  end

  assign b_hs = bvalid && bready;

  assign wr_issue = aw_state[0] && w_state[0] && b_rdy;
  assign aw_go = w_state[0] && b_rdy;
  assign w_go = aw_state[0] && b_rdy;

  // BRAM

  assign bram_addr = aw_slot0;
  assign bram_data = w_slot0[DATA_WIDTH+DATA_WIDTH/8-1:DATA_WIDTH/8];
  assign bram_strb = w_slot0[DATA_WIDTH/8-1:0];

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      bram_we_r <= 1'b0;
    end else begin
      bram_we_r <= aw_state_next[0] && w_state_next[0] && ~b_count_next[1];
    end
  end

  assign bram_we = bram_we_r;

  // B channel

  assign bresp   = b_err_slot0 ? 2'b10 : 2'b00;
  assign bvalid  = |b_pend;

endmodule

`default_nettype wire

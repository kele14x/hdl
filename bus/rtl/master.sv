`timescale 1 ns / 1 ps
//
`default_nettype none

module master #(
    parameter int NUM_REQ = 16,
    parameter int MAX_GAP = 3
) (
    input  logic       clk,
    input  logic       rst_n,
    //
    output logic       req,
    output logic [7:0] addr,
    input  logic       gnt,
    //
    input  logic       ack,
    input  logic [7:0] data,
    //
    output logic       done
);

  typedef struct {
    logic [7:0] addr;
    int         gap;   // pre-req gap in clock ticks; 0 = back-to-back
    logic       vld;
  } req_t;

  req_t req_array[NUM_REQ];
  req_t zero_req = '{addr: 8'h00, gap: 0, vld: 1'b0};

  req_t current_req;
  req_t next_req;

  logic ostd;

  int rd_ptr;
  int gap_cnt;

  /* verilator lint_off UNUSEDSIGNAL */
  logic [7:0] data_reg;

  // Build random request array at init

  initial begin
    req_t r;
    for (int i = 0; i < NUM_REQ; i++) begin
      r.addr       = 8'($urandom_range(0, 255));
      r.gap        = (i == 0) ? 0 : $urandom_range(0, MAX_GAP);
      r.vld        = 1'b1;
      req_array[i] = r;
    end
  end

  // Outstanding counter

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ostd <= 1'b0;
    end else if (req && gnt) begin
      ostd <= 1'b1;
    end else if (ack) begin
      ostd <= 1'b0;
    end
  end

  // Gap counter: counts cycles since the last req & gnt; resets on a
  // successful request so it is aligned with the next request's gap.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      gap_cnt <= '0;
    end else if (req && gnt) begin
      gap_cnt <= '0;
    end else begin
      gap_cnt <= gap_cnt + 1;
    end
  end

  // Output MUX

  assign req  = current_req.vld && (!ostd || ack) && (gap_cnt >= current_req.gap);
  assign addr = current_req.addr;

  // Move the next req to current req if current req is empty or about to empty

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_req <= '{addr: '0, gap: 0, vld: 1'b0};
    end else if (!current_req.vld || (req && gnt)) begin
      current_req <= next_req;
    end
  end

  // Read pointer

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
    end else begin
      if (!current_req.vld || (req && gnt)) begin
        rd_ptr <= (rd_ptr < NUM_REQ) ? rd_ptr + 1 : rd_ptr;
      end
    end
  end

  assign next_req = rd_ptr < NUM_REQ ? req_array[rd_ptr] : zero_req;

  // Done

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_reg <= '0;
    end else begin
      if (ack) begin
        data_reg <= data;
      end
    end
  end

  assign done = (rd_ptr >= NUM_REQ) && !ostd;

endmodule

`default_nettype wire

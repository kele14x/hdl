`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_top #(
    parameter int NUM_REQ     = 16,
    parameter int MAX_GAP     = 3,
    parameter int MAX_LATENCY = 4
);

  localparam int ClockPeriod = 10;

  logic       clk;
  logic       rst_n;
  //
  logic       req;
  logic [7:0] addr;
  logic       gnt;
  //
  logic       ack;
  logic [7:0] data;
  //
  logic       done;

  int         addr_cnt;
  int         data_cnt;

  logic       addr_chk_active;
  logic [7:0] addr_at_req;
  //
  logic       rsp_pending;
  logic [7:0] addr_at_gnt;
  //
  int         ostd_chk;

  // Clock generation
  initial begin
    clk = 0;
    forever #(ClockPeriod / 2) clk = ~clk;
  end

  // Reset generation
  initial begin
    rst_n = 0;
    #(ClockPeriod * 10);
    rst_n = 1;
  end

  // Master instance
  master #(
      .NUM_REQ(NUM_REQ),
      .MAX_GAP(MAX_GAP)
  ) mst (
      .clk  (clk),
      .rst_n(rst_n),
      //
      .req  (req),
      .addr (addr),
      .gnt  (gnt),
      //
      .ack  (ack),
      .data (data),
      //
      .done (done)
  );

  // Slave instance
  slave #(
      .MAX_LATENCY(MAX_LATENCY)
  ) slv (
      .clk  (clk),
      .rst_n(rst_n),
      //
      .req  (req),
      .addr (addr),
      .gnt  (gnt),
      //
      .ack  (ack),
      .data (data)
  );

  initial begin
    repeat (2000) begin
      @(posedge clk);
      if (done) begin
        repeat (10) @(posedge clk);
        $finish;
      end
    end
    // Bug workaround of verilator
    if (!done) begin
      $error("[TB] Simulation timeout!");
      $finish;
    end
  end

`ifdef FWAVE
  initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
  end
`endif

  initial begin
    forever begin
      @(posedge clk);
      if (req && gnt) begin
        $display("[%d]: addr = %x", addr_cnt, addr);
        addr_cnt += 1;
      end
    end
  end

  initial begin
    forever begin
      @(posedge clk);
      if (ack) begin
        $display("[%d]: data = %x", data_cnt, data);
        data_cnt += 1;
      end
    end
  end

  // addr must stay stable from req assertion until gnt, and req must not
  // be withdrawn before gnt (no cancel).
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_chk_active <= 1'b0;
      addr_at_req     <= '0;
    end else if (!addr_chk_active) begin
      if (req && !gnt) begin
        addr_chk_active <= 1'b1;
        addr_at_req     <= addr;
      end
    end else begin
      if (req && gnt) begin
        addr_chk_active <= 1'b0;
        if (addr != addr_at_req) begin
          #1;
          $error("[TB] addr changed while req pending: expected %h, got %h", addr_at_req, addr);
        end
      end else if (req) begin
        if (addr != addr_at_req) begin
          #1;
          $error("[TB] addr changed while req pending: expected %h, got %h", addr_at_req, addr);
        end
      end else begin
        addr_chk_active <= 1'b0;
        #1;
        $error("[TB] req withdrawn before gnt (cancel not allowed)");
      end
    end
  end

  // At most 1 outstanding transfer (req&gnt raises count, ack lowers it;
  // same-cycle ack + req&gnt nets to zero).
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ostd_chk <= '0;
    end else begin
      if (req && gnt && !ack) begin
        ostd_chk <= ostd_chk + 1;
        if (ostd_chk >= 1) begin
          #1;
          $error("[TB] outstanding count would exceed 1");
        end
      end else if (ack && !(req && gnt)) begin
        ostd_chk <= (ostd_chk > 0) ? ostd_chk - 1 : 0;
      end
    end
  end

  // On ack, response data must equal the addr captured at req&gnt.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rsp_pending <= 1'b0;
      addr_at_gnt <= '0;
    end else begin
      if (ack && rsp_pending) begin
        rsp_pending <= 1'b0;
      end
      if (req && gnt) begin
        addr_at_gnt <= addr;
        rsp_pending <= 1'b1;
      end
      if (ack && rsp_pending && (data != addr_at_gnt)) begin
        #1;
        $error("[TB] data != addr: expected %h, got %h", addr_at_gnt, data);
      end
    end
  end

endmodule

`default_nettype wire

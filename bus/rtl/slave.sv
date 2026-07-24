`timescale 1 ns / 1 ps
//
`default_nettype none

module slave #(
    parameter int MAX_LATENCY = 4
) (
    input  logic       clk,
    input  logic       rst_n,
    //
    input  logic       req,
    input  logic [7:0] addr,
    output logic       gnt,
    //
    output logic       ack,
    output logic [7:0] data
);

  // FSM: S_RESET -> S_IDLE <-> S_WAIT
  // S_RESET: entered on reset, transitions to S_IDLE on first clock.
  // S_IDLE: ready to accept a request.
  //         latency=1 -> ack in next cycle, stay S_IDLE.
  //         latency>=2 -> go S_WAIT for (latency-2) cycles.
  // S_WAIT: count down; when counter reaches (latency-2) return ack and go
  //         back to S_IDLE.
  // ack/data are registered outputs, so they change on the clock edge.
  typedef enum {
    S_RESET,
    S_IDLE,
    S_WAIT
  } state_t;

  state_t state, state_next;

  logic       ack_pre;
  logic [7:0] addr_reg;
  int         delay_cnt;
  int         latency;

  assign gnt = (state == S_IDLE) && req;

  // FSM

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S_RESET;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    state_next = state;
    case (state)
      S_RESET: begin
        state_next = S_IDLE;
      end

      S_IDLE: begin
        if (req && (latency >= 2)) begin
          state_next = S_WAIT;
        end
      end

      S_WAIT: begin
        if (delay_cnt >= latency - 2) begin
          state_next = S_IDLE;
        end
      end

      default: begin
        state_next = S_RESET;
      end
    endcase
  end

  // Delay counter

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      delay_cnt <= 0;
    end else begin
      if ((state == S_WAIT) && (delay_cnt < latency - 2)) begin
        delay_cnt <= delay_cnt + 1;
      end else begin
        delay_cnt <= 0;
      end
    end
  end

  // Latency

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      latency <= $urandom_range(1, MAX_LATENCY);
    end else begin
      if (ack_pre) begin
        latency <= $urandom_range(1, MAX_LATENCY);
      end
    end
  end

  // Ack

  assign ack_pre = ((state == S_IDLE) && req && (latency < 2)) ||
                   ((state == S_WAIT) && (delay_cnt >= latency - 2));

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ack <= 1'b0;
    end else begin
      ack <= ack_pre;
    end
  end

  // Data

  // For ack with > 1 latency, we need to register the data so that we no longer lost it
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_reg <= '0;
    end else begin
      if ((state == S_IDLE) && req && (latency >= 2)) begin
        addr_reg <= addr;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data <= '0;
    end else begin
      if ((state == S_IDLE) && req && (latency < 2)) begin
        data <= addr;
      end else if ((state == S_WAIT) && (delay_cnt >= latency - 2)) begin
        data <= addr_reg;
      end
    end
  end

endmodule

`default_nettype wire

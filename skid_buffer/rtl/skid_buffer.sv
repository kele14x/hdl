`timescale 1 ns / 1 ps
//
`default_nettype none

module skid_buffer #(
    parameter integer DATA_WIDTH = 8
) (
    input  wire                  clk,
    input  wire                  rst_n,
    //
    input  wire [DATA_WIDTH-1:0] s_data_i,
    input  wire                  s_vld_i,
    output wire                  s_rdy_o,
    //
    output wire [DATA_WIDTH-1:0] m_data_o,
    output wire                  m_vld_o,
    input  wire                  m_rdy_i
);

  // 2'b00: no data is buffered
  // 2'b01: 1 data is buffered at slot0
  // 2'b11: 2 data is buffered at slot0 & slot1
  // Note: 2'b10 is illegal state
  logic [           1:0] state;
  logic [           1:0] state_next;

  logic [DATA_WIDTH-1:0] slot0;
  logic [DATA_WIDTH-1:0] slot1;
  logic [DATA_WIDTH-1:0] slot0_next;
  logic [DATA_WIDTH-1:0] slot1_next;

  // state

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= 2'b00;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    state_next = state;
    case (state)
      2'b00: begin
        if (s_vld_i) begin
          state_next = 2'b01;
        end
      end

      2'b01: begin
        if (s_vld_i && m_rdy_i) begin
          state_next = 2'b01;
        end else if (s_vld_i) begin
          state_next = 2'b11;
        end else if (m_rdy_i) begin
          state_next = 2'b00;
        end
      end

      2'b11: begin
        if (m_rdy_i) begin
          state_next = 2'b01;
        end
      end

      default: begin
        state_next = 2'b00;
      end
    endcase
  end

  // slot0

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      slot0 <= {DATA_WIDTH{1'b0}};
    end else begin
      slot0 <= slot0_next;
    end
  end

  always_comb begin
    slot0_next = slot0;
    case (state)
      2'b00: begin
        if (s_vld_i) begin
          slot0_next = s_data_i;
        end
      end

      2'b01: begin
        if (s_vld_i && m_rdy_i) begin
          slot0_next = s_data_i;
        end
      end

      2'b11: begin
        if (m_rdy_i) begin
          slot0_next = slot1;
        end
      end

      default: begin
        slot0_next = slot0;
      end
    endcase
  end

  // slot1

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      slot1 <= {DATA_WIDTH{1'b0}};
    end else begin
      slot1 <= slot1_next;
    end
  end

  always_comb begin
    slot1_next = slot1;
    case (state)
      2'b01: begin
        if (s_vld_i && !m_rdy_i) begin
          slot1_next = s_data_i;
        end
      end

      default: begin
        slot1_next = slot1;
      end
    endcase
  end

  // slave / master channels

  assign s_rdy_o  = ~state[1];
  assign m_data_o = slot0;
  assign m_vld_o  = state[0];

endmodule

`default_nettype wire

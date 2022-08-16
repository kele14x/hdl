// File: dummy_source.sv
// Brief: Generate random bits to test downlink.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dummy_source #(
    parameter int DATA_WIDTH = 16
) (
    input var                   clk,
    input var                   rst,
    // Data input
    input var  [           7:0] data_sync_in,
    // Data output
    output var [DATA_WIDTH-1:0] data_out,
    output var [           7:0] data_sync_out,
    // Control interface
    //==================
    input var  [           2:0] ctrl_numerology,  // 0 ~ 4
    input var  [           1:0] ctrl_iq_width,    // 0 ~ 3,
    input var                   ctrl_shift,
    input var  [          15:0] ctrl_scalar
);

  // Local parameters
  //=================

  localparam int Latency = 7;
  localparam int LfsrBitWidth = 24;


  // Signals
  //========

  logic                    symbol_start;

  logic [            15:0] counter;
  logic [            15:0] counter_max;

  logic                    lfsr_rst;
  logic                    lfsr_en;
  logic                    lfsr_en_d;
  logic [LfsrBitWidth-1:0] lfsr_dout;

  logic [             4:0] mod_s;


  // Main
  //=====

  assign symbol_start = data_sync_in[4];

  // The counter

  always_ff @(posedge clk) begin
    if (rst || symbol_start) begin
      counter <= 0;
    end else if (counter != counter_max) begin
      counter <= counter + 1;
    end
  end

  always_ff @(posedge clk) begin
    case (ctrl_numerology)
      0:       counter_max <= 32768 - 1;
      1:       counter_max <= 16384 - 1;
      2:       counter_max <= 8192 - 1;
      3:       counter_max <= 4096 - 1;
      default: counter_max <= 2048 - 1;
    endcase
  end

  always_ff @(posedge clk) begin
    lfsr_rst <= (rst || symbol_start);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      lfsr_en <= 1'b0;
    end else if (symbol_start) begin
      lfsr_en <= 1'b1;
    end else if (counter == counter_max) begin
      lfsr_en <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    lfsr_en_d  <= lfsr_en;
  end

  lfsr #(
      .BIT_WIDTH      (LfsrBitWidth),
      .INITIAL        (24'b111111111111111111111111),
      .POLYNOMIAL     (24'b000000000000000010000111),
      .STRUCTURE      ("FIBONACCI"),
      .GATE_TYPE      ("XOR"),
      .PARALLEL_OUTPUT(1'b1)
  ) i_lfsr (
      .clk (clk),
      .rst (lfsr_rst),
      .en  (lfsr_en),
      .load(1'b0),
      .din ('0),
      .dout(lfsr_dout)
  );


  // Modulation

  always_ff @(posedge clk) begin
    if (lfsr_en_d == 0) begin
      mod_s <= '0;
    end else begin
      case (ctrl_iq_width)
        0:       mod_s <= {lfsr_dout[0], ctrl_shift, 3'b0};
        1:       mod_s <= {lfsr_dout[1:0], ctrl_shift, 2'b0};
        2:       mod_s <= {lfsr_dout[2:0], ctrl_shift, 1'b0};
        default: mod_s <= {lfsr_dout[3:0], ctrl_shift};
      endcase
    end
  end

  mult #(
      .A_WIDTH (5),
      .B_WIDTH (16),
      .P_WIDTH (21),
      .SRA_BITS(4)
  ) i_mult (
      .clk(clk),
      .rst(rst),
      .a  (mod_s),
      .b  ({1'b0, ctrl_scalar}),
      .p  (data_out),
      .ovf(  /* not used */)
  );


  // Output

  shift_regs #(
      .DATA_WIDTH(8),
      .DEPTH     (Latency)
  ) i_delay_sync (
      .clk (clk),
      .cen (1'b1),
      //
      .din (data_sync_in),
      .dout(data_sync_out)
  );

endmodule

`default_nettype wire

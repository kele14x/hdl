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
    input var  [          14:0] ctrl_scalar
);

  // Local parameters
  //=================

  localparam int Latency = 8;
  localparam int LfsrBitWidth = 24;


  // Signals
  //========

  logic                    symbol_start;
  logic                    symbol_start_d;

  logic [             3:0] channel_counter;
  logic [             3:0] channel_counter_max;

  logic [            12:0] sample_counter;
  logic [            12:0] sample_counter_max;

  logic                    counter_valid;

  logic                    lfsr_rst;
  logic                    lfsr_en;
  logic                    lfsr_valid;
  logic [LfsrBitWidth-1:0] lfsr_dout;
  logic                    mult_ovf;
  logic                    unused_lfsr_dout;

  logic [             4:0] mod_s;


  // Main
  //=====

  assign symbol_start = data_sync_in[4];

  // The counter

  always_ff @(posedge clk) begin
    if (rst || symbol_start) begin
      channel_counter <= '0;
    end else if (counter_valid) begin
      if (channel_counter == channel_counter_max) begin
        channel_counter <= '0;
      end else begin
        channel_counter <= channel_counter + 1;
      end
    end
  end

  always_comb begin
    case (ctrl_numerology)
      0:       channel_counter_max = 7;
      1:       channel_counter_max = 3;
      2:       channel_counter_max = 3;
      3:       channel_counter_max = 3;
      default: channel_counter_max = 3;
    endcase
  end


  always_ff @(posedge clk) begin
    if (rst || symbol_start) begin
      sample_counter <= 0;
    end else if (counter_valid) begin
      if (channel_counter == channel_counter_max) begin
        if (sample_counter == sample_counter_max) begin
          sample_counter <= '0;
        end else begin
          sample_counter <= sample_counter + 1;
        end
      end
    end
  end

  always_comb begin
    case (ctrl_numerology)
      0:       sample_counter_max = 4096 - 1;
      1:       sample_counter_max = 4096 - 1;
      2:       sample_counter_max = 2048 - 1;
      3:       sample_counter_max = 1024 - 1;
      default: sample_counter_max = 512 - 1;
    endcase
  end

  always_ff @(posedge clk) begin
    symbol_start_d <= symbol_start;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      counter_valid <= 1'b0;
    end else if (symbol_start) begin
      counter_valid <= 1'b1;
    end else if (sample_counter == sample_counter_max && channel_counter == channel_counter_max) begin
      counter_valid <= 1'b0;
    end
  end


  // lfsr_*

  always_ff @(posedge clk) begin
    lfsr_rst <= symbol_start_d;
  end

  always_ff @(posedge clk) begin
    if (sample_counter < 1638 || (2458 <= sample_counter && sample_counter <= 4096)) begin
      lfsr_en <= counter_valid;
    end else begin
      lfsr_en <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    lfsr_valid <= lfsr_en;
  end


  // Use LFSR as produsue sequence generator

  lfsr #(
      .BIT_WIDTH      (LfsrBitWidth),
      .INITIAL        (24'b111111111111111111111111),
      .POLYNOMIAL     (25'b1000000000000000010000111),
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
  assign unused_lfsr_dout = |lfsr_dout[LfsrBitWidth-1:4];


  // Modulation

  always_ff @(posedge clk) begin
    if (lfsr_valid == 0) begin
      mod_s <= '0;
    end else begin
      case (ctrl_iq_width)
        0:       mod_s <= {lfsr_dout[0], ctrl_shift, 3'b0} ^ {5{unused_lfsr_dout & 1'b0}};
        1:       mod_s <= {lfsr_dout[1:0], ctrl_shift, 2'b0} ^ {5{unused_lfsr_dout & 1'b0}};
        2:       mod_s <= {lfsr_dout[2:0], ctrl_shift, 1'b0} ^ {5{unused_lfsr_dout & 1'b0}};
        default: mod_s <= {lfsr_dout[3:0], ctrl_shift} ^ {5{unused_lfsr_dout & 1'b0}};
      endcase
    end
  end

  mult #(
      .A_WIDTH(5),
      .B_WIDTH(16),
      .P_WIDTH(DATA_WIDTH),
      .SHIFT  (4)
  ) i_mult (
      .clk(clk),
      .rst(rst),
      .a  (mod_s),
      .b  ({1'b0, ctrl_scalar}),
      .p  (data_out),
      .ovf(mult_ovf)
  );


  // Output

  delay #(
      .WIDTH(8),
      .DEPTH(Latency)
  ) i_delay_sync (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      //
      .din (data_sync_in ^ {8{mult_ovf & 1'b0}}),
      .dout(data_sync_out)
  );

endmodule

`default_nettype wire

// File: pps_counter.sv
// Brief: Frequency adjustable sample counter. The precision is 1/2^32. Output
//        is 2-bit carry (as integer part) and 32-bit fractional part.
//        Also, internal reset and sync is generated here.
//        Latency is 1 clock tick (from reset to output).
`timescale 1 ns / 1 ps
//
`default_nettype none

module pps_counter (
    // System
    //-------
    input var         clk,
    input var         rst,
    //
    output var        rst_int,
    output var        sync_int,
    //
    output var [ 1:0] sample_inc,
    output var [32:0] sample_frac,
    // CSR
    //----
    input var         ctrl_clk,
    input var         ctrl_rst,
    //
    input var  [31:0] ctrl_freq
);

  logic        rst_int_d;

  logic        ctrl_freq_send;
  logic        ctrl_freq_rcv;
  logic [31:0] ctrl_freq_cdc;
  /* verilator lint_off UNUSED */
  wire         unused_ctrl_freq_req;
  /* verilator lint_on UNUSED */

  logic [31:0] sample_cnt;
  logic [32:0] sample_cnt_adder;
  logic [33:0] sample_cnt_next;

  logic        sample_carry1;
  logic        sample_carry2;


  // Init
  //-----

  always_ff @(posedge clk) begin
    rst_int <= rst;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rst_int_d <= 1'b1;
    end else begin
      rst_int_d <= rst_int;
    end
  end

  // First clock tick after reset
  assign sync_int = (~rst_int && rst_int_d);


  // CDC
  //----

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_rst) begin
      ctrl_freq_send <= 1'b0;
    end else begin
      ctrl_freq_send <= ~ctrl_freq_rcv;
    end
  end

`ifdef XILINX
  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (32)
  ) xpm_cdc_handshake_inst (
      .src_clk (ctrl_clk),
      .src_in  (ctrl_freq),
      .src_send(ctrl_freq_send),
      .src_rcv (ctrl_freq_rcv),
      //
      .dest_clk(clk),
      .dest_out(ctrl_freq_cdc),
      .dest_req(unused_ctrl_freq_req),
      .dest_ack(1'b1)
  );
`else
  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(2),
      .INIT_SYNC_FF(0),
      .SRC_SYNC_FF (2),
      .WIDTH       (32)
  ) i_cdc_handshake_freq (
      .src_clk   (ctrl_clk),
      .src_in    (ctrl_freq),
      .src_valid (ctrl_freq_send),
      .src_ready (ctrl_freq_rcv),
      .dest_clk  (clk),
      .dest_out  (ctrl_freq_cdc),
      .dest_valid(unused_ctrl_freq_req),
      .dest_ready(1'b1)
  );
`endif


  // Sample Counter
  //---------------

  // inc controls the frequency of counter, the FCW is `0x100000000 + ctrl_freq`
  always_comb begin
    if (ctrl_freq_cdc[31] == 1'b0) begin
      sample_cnt_adder = {1'b1, ctrl_freq_cdc};
    end else begin
      sample_cnt_adder = {1'h0, ctrl_freq_cdc};
    end
  end

  assign sample_cnt_next = {2'b0, sample_cnt} + sample_cnt_adder;

  always_ff @(posedge clk) begin
    if (rst_int) begin
      sample_cnt <= '0;
    end else begin
      sample_cnt <= sample_cnt_next[31:0];
    end
  end

  // Carry output to next level counter
  assign sample_carry1 = |sample_cnt_next[33:32];
  assign sample_carry2 = sample_cnt_next[33:32] == 2'b10;

  assign sample_frac   = {sample_inc[1], sample_cnt};

  // inc = 0 (2'b00), 1 (2'b01) or 2 (2'b11)
  always_ff @(posedge clk) begin
    if (rst_int) begin
      sample_inc <= '0;
    end else begin
      sample_inc <= {sample_carry2, sample_carry1};
    end
  end

  // Possible output combination
  //   sync_int, inc1, inc0
  //          0     0     0  -> count does not increase
  //          0     0     1  -> count increase by 1
  //          0     1     0  -> not valid
  //          0     1     1  -> count increase by 2
  //          1     0     0  -> count reset to 0
  //          1     0     1  -> count reset to 0
  //          1     1     0  -> not valid
  //          1     1     1  -> count reset to 1

`ifdef DEBUG

  logic [20:0] debug_cnt;
  logic        debug_sof;

  always_ff @(posedge clk) begin
    if (rst_int) begin
      debug_cnt <= '0;
    end else if (debug_cnt + sample_cnt_next[33:32] >= 21'h12C000) begin
      debug_cnt <= debug_cnt + sample_cnt_next[33:32] - 21'h12C000;
    end else begin
      debug_cnt <= debug_cnt + sample_cnt_next[33:32];
    end
  end

  always_ff @(posedge clk) begin
    debug_sof <= (debug_cnt + sample_cnt_next[33:32] >= 21'h12C000);
  end

`endif

endmodule

`default_nettype wire

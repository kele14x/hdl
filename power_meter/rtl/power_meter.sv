`timescale 1 ns / 1 ps
//
`default_nettype none

module power_meter #(
    parameter int NUM_CC   = 3,
    parameter int NUM_BAND = 2
) (
    input var         clk,
    input var         rst_n,
    //
    input var  [15:0] din0_dr      [NUM_CC][NUM_BAND],
    input var  [15:0] din0_di      [NUM_CC][NUM_BAND],
    input var  [ 1:0] din0_chn     [NUM_CC][NUM_BAND],
    input var  [ 8:0] din0_sym     [NUM_CC][NUM_BAND],
    input var         din0_dv      [NUM_CC][NUM_BAND],
    input var         din0_sync    [NUM_CC][NUM_BAND],
    //
    input var  [15:0] din1_dr      [NUM_CC][NUM_BAND],
    input var  [15:0] din1_di      [NUM_CC][NUM_BAND],
    input var  [ 1:0] din1_chn     [NUM_CC][NUM_BAND],
    input var  [ 8:0] din1_sym     [NUM_CC][NUM_BAND],
    input var         din1_dv      [NUM_CC][NUM_BAND],
    input var         din1_sync    [NUM_CC][NUM_BAND],
    //----
    input var         clk_csr,
    input var         rst_csr_n,
    //
    input var         ctrl_mu      [NUM_CC][NUM_BAND],
    //
    input var  [ 1:0] ctrl_cc_sel,
    input var         ctrl_band_sel,
    input var  [ 1:0] ctrl_ant_sel,
    input var         ctrl_pos_sel,
    //
    output var [31:0] stat_power   [    20]
);

  logic               ctrl_mu_sel;
  logic               ctrl_mu_s;

  logic        [ 1:0] ctrl_cc_sel_s;
  logic               ctrl_band_sel_s;
  logic        [ 1:0] ctrl_ant_sel_s;
  logic               ctrl_pos_sel_s;

  logic        [15:0] data_dr;
  logic        [15:0] data_di;
  logic        [ 1:0] data_chn;
  logic        [ 8:0] data_sym;
  logic               data_dv;
  logic               unused_data_sync;

  logic        [ 4:0] data_slot;
  logic        [ 4:0] data_slot_d;
  logic        [ 4:0] data_slot_dd;
  logic        [ 4:0] data_slot_ddd;

  logic               clear;

  logic signed [15:0] data_dr_d1;
  logic signed [15:0] data_dr_d2;
  logic signed [15:0] data_dr_d3;
  logic signed [15:0] data_di_d1;
  logic signed [15:0] data_di_d2;
  logic signed [15:0] data_di_d3;

  logic signed [31:0] data_dr_sqrt;
  logic signed [31:0] data_di_sqrt;

  logic signed [63:0] data_sum;

  logic        [31:0] stat_power_r     [20];

  always_ff @(posedge clk_csr) begin
    if (~rst_csr_n) begin
      ctrl_mu_sel <= 1'b0;
    end else begin
      ctrl_mu_sel <= ctrl_mu[ctrl_cc_sel][ctrl_band_sel];
    end
  end

  // verilog_format: off
  cdc_array_single #(
      .WIDTH        ($bits({ctrl_mu_sel, ctrl_pos_sel, ctrl_ant_sel, ctrl_band_sel, ctrl_cc_sel})),
      .DEST_SYNC_FF (3),
      .INIT_SYNC_FF (1),
      .SRC_INPUT_REG(0)
  ) i_cdc_ctrl (
      .src_clk (1'b0),
      .src_in  ({ctrl_mu_sel, ctrl_pos_sel, ctrl_ant_sel, ctrl_band_sel, ctrl_cc_sel}),
      .dest_clk(clk),
      .dest_out({ctrl_mu_s, ctrl_pos_sel_s, ctrl_ant_sel_s, ctrl_band_sel_s, ctrl_cc_sel_s})
  );
  // verilog_format: on

  generate
    for (genvar i = 0; i < 20; i++) begin : g_stat

      cdc_array_single #(
          .WIDTH        (32),
          .DEST_SYNC_FF (3),
          .INIT_SYNC_FF (1),
          .SRC_INPUT_REG(0)
      ) i_cdc_stat (
          .src_clk (1'b0),
          .src_in  (stat_power_r[i]),
          .dest_clk(clk_csr),
          .dest_out(stat_power[i])
      );
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (ctrl_pos_sel_s == 1'b0) begin
      data_dr <= din0_dr[ctrl_cc_sel_s][ctrl_band_sel_s];
    end else begin
      data_dr <= din1_dr[ctrl_cc_sel_s][ctrl_band_sel_s];
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_pos_sel_s == 1'b0) begin
      data_di <= din0_di[ctrl_cc_sel_s][ctrl_band_sel_s];
    end else begin
      data_di <= din1_di[ctrl_cc_sel_s][ctrl_band_sel_s];
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_pos_sel_s == 1'b0) begin
      data_chn <= din0_chn[ctrl_cc_sel_s][ctrl_band_sel_s];
    end else begin
      data_chn <= din1_chn[ctrl_cc_sel_s][ctrl_band_sel_s];
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_pos_sel_s == 1'b0) begin
      data_sym <= din0_sym[ctrl_cc_sel_s][ctrl_band_sel_s];
    end else begin
      data_sym <= din1_sym[ctrl_cc_sel_s][ctrl_band_sel_s];
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_pos_sel_s == 1'b0) begin
      data_dv <= din0_dv[ctrl_cc_sel_s][ctrl_band_sel_s];
    end else begin
      data_dv <= din1_dv[ctrl_cc_sel_s][ctrl_band_sel_s];
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_pos_sel_s == 1'b0) begin
      unused_data_sync <= din0_sync[ctrl_cc_sel_s][ctrl_band_sel_s];
    end else begin
      unused_data_sync <= din1_sync[ctrl_cc_sel_s][ctrl_band_sel_s];
    end
  end

  // Accumulator

  always_ff @(posedge clk) begin
    if (data_dv && data_chn == ctrl_ant_sel_s) begin
      data_dr_d1 <= data_dr;
    end else begin
      data_dr_d1 <= '0;
    end
    data_dr_d2 <= data_dr_d1;
    data_dr_d3 <= data_dr_d2;
  end

  always_ff @(posedge clk) begin
    if (data_dv && data_chn == ctrl_ant_sel_s) begin
      data_di_d1 <= data_di;
    end else begin
      data_di_d1 <= '0;
    end
    data_di_d2 <= data_di_d1;
    data_di_d3 <= data_di_d2;
  end

  always_ff @(posedge clk) begin
    data_dr_sqrt <= data_dr_d3 * data_dr_d3;
  end

  always_ff @(posedge clk) begin
    data_di_sqrt <= data_di_d3 * data_di_d3;
  end

  always_ff @(posedge clk) begin
    if (clear) begin
      data_sum <= '0;
    end else begin
      data_sum <= data_sum + {{32{data_dr_sqrt[31]}}, data_dr_sqrt}
                  + {{32{data_di_sqrt[31]}}, data_di_sqrt};
    end
  end

  // Control

  always_comb begin
    if (ctrl_mu_s == 1'b0) begin
      data_slot = 5'(data_sym / 9'd7);
    end else begin
      data_slot = 5'(data_sym / 9'd14);
    end
  end

  delay #(
      .WIDTH($bits(data_slot)),
      .DEPTH(3)
  ) u_delay (
      .clk (clk),
      .rst (~rst_n),
      .cen (1'b1),
      .din (data_slot),
      .dout(data_slot_d)
  );

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      data_slot_dd <= '1;
    end else begin
      data_slot_dd <= data_slot_d;
    end
  end

  always_ff @(posedge clk) begin
    data_slot_ddd <= data_slot_dd;
  end

  always_ff @(posedge clk) begin
    clear <= data_slot_dd != data_slot_d;
  end

  always_ff @(posedge clk) begin
    if (clear) begin
      stat_power_r[data_slot_ddd] <= data_sum[44:13];
    end
  end

endmodule

`default_nettype wire

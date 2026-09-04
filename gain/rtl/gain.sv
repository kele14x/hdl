`timescale 1 ns / 1 ps
//
`default_nettype none

module gain #(
    parameter int HAS_CDC    = 0,
    parameter int NUM_ANT    = 4,
    parameter int COMPLEX    = 1,
    parameter int GAIN_WIDTH = 16
) (
    input var                   clk,
    input var                   rst,
    //
    input var  [          15:0] din_dr,
    input var  [          15:0] din_di,
    input var                   din_sf,
    input var                   din_sl,
    input var                   din_sy,
    input var  [           3:0] din_chn,
    input var                   din_dv,
    input var                   din_last,
    //
    output var [          15:0] dout_dr,
    output var [          15:0] dout_di,
    output var                  dout_sf,
    output var                  dout_sl,
    output var                  dout_sy,
    output var [           3:0] dout_chn,
    output var                  dout_dv,
    output var                  dout_last,
    // CSR
    //----
    input var  [GAIN_WIDTH-1:0] ctrl_gain_dr[NUM_ANT],
    input var  [GAIN_WIDTH-1:0] ctrl_gain_di[NUM_ANT]
);

  logic [GAIN_WIDTH-1:0] ctrl_gain_dr_s[NUM_ANT];
  logic [GAIN_WIDTH-1:0] ctrl_gain_di_s[NUM_ANT];

  localparam int Latency = (COMPLEX != 0) ? 6 : 5;
  localparam int AntAddrWidth = $clog2(NUM_ANT);

  logic [          15:0] din_dr_d;
  logic [          15:0] din_di_d;

  logic [GAIN_WIDTH-1:0] ctrl_gain_dr_ch;
  logic [GAIN_WIDTH-1:0] ctrl_gain_di_ch;

  logic                  unused_cmult_ovf;
  logic                  unused_mult_dr_ovf;
  logic                  unused_mult_di_ovf;

  generate
    if (COMPLEX == 0) begin : g_unused_real_gain_di
      for (genvar i = 0; i < NUM_ANT; i++) begin : g_ant
        wire unused = &{1'b0, ctrl_gain_di[i], ctrl_gain_di_s[i], ctrl_gain_di_ch};
      end
    end
  endgenerate

  generate
    if (HAS_CDC != 0) begin : g_dr_cdc

      for (genvar i = 0; i < NUM_ANT; i++) begin : g_ch
        cdc_array_single #(
            .DEST_SYNC_FF (2),
            .INIT_SYNC_FF (0),
            .SRC_INPUT_REG(0),
            .WIDTH        (GAIN_WIDTH)
        ) i_cdc_gain_dr (
            .src_clk (1'b1),
            .src_in  (ctrl_gain_dr[i]),
            //
            .dest_clk(clk),
            .dest_out(ctrl_gain_dr_s[i])
        );
      end

    end else begin : g_no_cdc

      assign ctrl_gain_dr_s = ctrl_gain_dr;

    end
  endgenerate

  generate
    if ((HAS_CDC != 0) && (COMPLEX != 0)) begin : g_di_cdc

      for (genvar i = 0; i < NUM_ANT; i++) begin : g_ch
        cdc_array_single #(
            .DEST_SYNC_FF (2),
            .INIT_SYNC_FF (0),
            .SRC_INPUT_REG(0),
            .WIDTH        (GAIN_WIDTH)
        ) i_cdc_gain_di (
            .src_clk (1'b1),
            .src_in  (ctrl_gain_di[i]),
            //
            .dest_clk(clk),
            .dest_out(ctrl_gain_di_s[i])
        );
      end

    end else if (COMPLEX != 0) begin : g_di

      assign ctrl_gain_di_s = ctrl_gain_di;

    end else begin : g_no_di

      assign ctrl_gain_di_s = '{NUM_ANT{'0}};

    end
  endgenerate

  always_ff @(posedge clk) begin
    if (din_dv) begin
      ctrl_gain_dr_ch <= ctrl_gain_dr_s[din_chn[AntAddrWidth-1:0]];
    end else begin
      ctrl_gain_dr_ch <= '0;
    end
  end

  always_ff @(posedge clk) begin
    din_dr_d <= din_dr;
    din_di_d <= din_di;
  end

  generate
    if (COMPLEX != 0) begin : g_complex

      always_ff @(posedge clk) begin
        if (din_dv) begin
          ctrl_gain_di_ch <= ctrl_gain_di_s[din_chn[AntAddrWidth-1:0]];
        end else begin
          ctrl_gain_di_ch <= '0;
        end
      end

      cmult #(
          .USE_3_MULT(0),
          .A_WIDTH (16),
          .B_WIDTH (GAIN_WIDTH),
          .P_WIDTH (16),
          .SHIFT   (14),
          .ROUND   (1),
          .SATURATE(1)
      ) i_cmult (
          .clk(clk),
          .rst(rst),
          //
          .ar (din_dr_d),
          .ai (din_di_d),
          //
          .br (ctrl_gain_dr_ch),
          .bi (ctrl_gain_di_ch),
          //
          .pr (dout_dr),
          .pi (dout_di),
          //
          .ovf(unused_cmult_ovf)
      );

    end else begin : g_real

      assign ctrl_gain_di_ch = '0;

      mult #(
          .A_WIDTH (16),
          .B_WIDTH (GAIN_WIDTH),
          .P_WIDTH (16),
          .SHIFT   (14),
          .ROUND   (1),
          .SATURATE(1)
      ) i_mult_dr (
          .clk(clk),
          .rst(rst),
          //
          .a  (din_dr_d),
          .b  (ctrl_gain_dr_ch),
          .p  (dout_dr),
          //
          .ovf(unused_mult_dr_ovf)
      );

      mult #(
          .A_WIDTH (16),
          .B_WIDTH (GAIN_WIDTH),
          .P_WIDTH (16),
          .SHIFT   (14),
          .ROUND   (1),
          .SATURATE(1)
      ) i_mult_di (
          .clk(clk),
          .rst(rst),
          //
          .a  (din_di_d),
          .b  (ctrl_gain_dr_ch),
          .p  (dout_di),
          //
          .ovf(unused_mult_di_ovf)
      );

    end
  endgenerate

  delay #(
      .WIDTH(9),
      .DEPTH(Latency)
  ) i_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({din_last, din_dv, din_chn, din_sy, din_sl, din_sf}),
      .dout({dout_last, dout_dv, dout_chn, dout_sy, dout_sl, dout_sf})
  );

endmodule

`default_nettype wire

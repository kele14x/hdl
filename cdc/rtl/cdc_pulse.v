`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY="yes" *)
module cdc_pulse #(
    parameter integer DEST_SYNC_FF = 4,
    parameter reg     INIT_SYNC_FF = 1'b0,
    parameter reg     REG_OUTPUT   = 1'b0,
    parameter reg     RST_USED     = 1'b1
) (
    input  wire src_clk,
    input  wire src_rst,
    input  wire src_pulse,
    //
    input  wire dest_clk,
    input  wire dest_rst,
    output wire dest_pulse
);

  reg  src_in_ff;
  wire src_edge_det;

  reg  src_level_ff;
  wire src_level_nxt;

  wire src_sync_in;

  wire dest_sync_out;

  reg  dest_event_ff;
  wire dest_event_nxt;

  wire dest_pulse_int;
  reg  dest_pulse_ff;

  // verilog_format: off
  initial begin
    if (DEST_SYNC_FF < 2 || DEST_SYNC_FF > 10) begin
      $display("ERROR: DEST_SYNC_FF (%0d) value is outside of valid range 2-10. [%m]", DEST_SYNC_FF);
      #1 $finish();
    end
  end
  // verilog_format: on

  initial begin
    if (INIT_SYNC_FF) begin
      src_level_ff = 1'b0;
      src_in_ff = 1'b0;
      dest_event_ff = 1'b0;
      dest_pulse_ff = 1'b0;
    end
  end

  assign src_edge_det   = src_pulse & ~src_in_ff;
  assign src_level_nxt  = src_level_ff ^ src_edge_det;
  assign src_sync_in    = src_level_ff;

  assign dest_event_nxt = dest_sync_out;
  assign dest_pulse_int = dest_event_nxt ^ dest_event_ff;

  generate
    if (RST_USED) begin : g_rst_used

      always @(posedge src_clk) begin
        if (src_rst) begin
          src_in_ff <= 1'b0;
        end else begin
          src_in_ff <= src_pulse;
        end
      end

      always @(posedge src_clk) begin
        if (src_rst) begin
          src_level_ff <= 1'b0;
        end else begin
          src_level_ff <= src_level_nxt;
        end
      end

      always @(posedge dest_clk) begin
        if (dest_rst) begin
          dest_event_ff <= 1'b0;
        end else begin
          dest_event_ff <= dest_event_nxt;
        end
      end

      always @(posedge dest_clk) begin
        if (dest_rst) begin
          dest_pulse_ff <= 1'b0;
        end else begin
          dest_pulse_ff <= dest_pulse_int;
        end
      end

    end else begin : g_rst_no_used

      always @(posedge src_clk) begin
        src_in_ff <= src_pulse;
      end

      always @(posedge src_clk) begin
        src_level_ff <= src_level_nxt;
      end

      always @(posedge dest_clk) begin
        dest_event_ff <= dest_event_nxt;
      end

      always @(posedge dest_clk) begin
        dest_pulse_ff <= dest_pulse_int;
      end

    end
  endgenerate

  generate
    if (REG_OUTPUT) begin : g_reg_out
      assign dest_pulse = dest_pulse_ff;
    end else begin : g_comb_out
      assign dest_pulse = dest_pulse_int;
    end
  endgenerate

  cdc_single #(
      .DEST_SYNC_FF (DEST_SYNC_FF),
      .INIT_SYNC_FF (INIT_SYNC_FF),
      .SRC_INPUT_REG(0)
  ) cdc_single_inst (
      .src_clk (src_clk),
      .src_in  (src_sync_in),
      .dest_clk(dest_clk),
      .dest_out(dest_sync_out)
  );

endmodule

`default_nettype wire

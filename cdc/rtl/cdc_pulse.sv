`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY = "yes" *)
module cdc_pulse #(
    parameter int DEST_SYNC_FF = 4,
    parameter int INIT_SYNC_FF = 0,
    parameter int REG_OUTPUT   = 0,
    parameter int RST_USED     = 1
) (
    input  logic src_clk,
    input  logic src_rst,
    input  logic src_pulse,
    //
    input  logic dest_clk,
    input  logic dest_rst,
    output logic dest_pulse
);

  logic src_in_ff;
  logic src_edge_det;
  logic src_level_ff;
  logic src_level_nxt;
  logic src_sync_in;
  logic dest_sync_out;
  logic dest_event_ff;
  logic dest_event_nxt;
  logic dest_pulse_int;
  /* verilator lint_off UNUSEDSIGNAL */
  logic dest_pulse_ff;

  initial begin : drc_check
    assert (DEST_SYNC_FF >= 2 && DEST_SYNC_FF <= 10)
    else begin
      $error("[%m]: DEST_SYNC_FF (%0d) value is outside of valid range 2-10.", DEST_SYNC_FF);
    end

    assert (INIT_SYNC_FF == 0 || INIT_SYNC_FF == 1)
    else begin
      $error("[%m]: INIT_SYNC_FF (%0d) value is outside of valid range.", INIT_SYNC_FF);
    end

    assert (REG_OUTPUT == 0 || REG_OUTPUT == 1)
    else begin
      $error("[%m]: REG_OUTPUT (%0d) value is outside of valid range.", REG_OUTPUT);
    end

    assert (RST_USED == 0 || RST_USED == 1)
    else begin
      $error("[%m]: RST_USED (%0d) value is outside of valid range.", RST_USED);
    end
  end

  initial begin : p_init
    if (INIT_SYNC_FF != 0) begin
      src_level_ff  = 1'b0;
      src_in_ff     = 1'b0;
      dest_event_ff = 1'b0;
      dest_pulse_ff = 1'b0;
    end
  end

  assign src_edge_det = src_pulse & ~src_in_ff;
  assign src_level_nxt = src_level_ff ^ src_edge_det;
  assign src_sync_in = src_level_ff;
  assign dest_event_nxt = dest_sync_out;
  assign dest_pulse_int = dest_event_nxt ^ dest_event_ff;

  generate
    if (RST_USED != 0) begin : g_rst_used
      always_ff @(posedge src_clk) begin
        if (src_rst) begin
          src_in_ff <= 1'b0;
        end else begin
          src_in_ff <= src_pulse;
        end
      end

      always_ff @(posedge src_clk) begin
        if (src_rst) begin
          src_level_ff <= 1'b0;
        end else begin
          src_level_ff <= src_level_nxt;
        end
      end

      always_ff @(posedge dest_clk) begin
        if (dest_rst) begin
          dest_event_ff <= 1'b0;
        end else begin
          dest_event_ff <= dest_event_nxt;
        end
      end

      always_ff @(posedge dest_clk) begin
        if (dest_rst) begin
          dest_pulse_ff <= 1'b0;
        end else begin
          dest_pulse_ff <= dest_pulse_int;
        end
      end
    end else begin : g_rst_no_used
      always_ff @(posedge src_clk) begin
        src_in_ff <= src_pulse;
      end

      always_ff @(posedge src_clk) begin
        src_level_ff <= src_level_nxt;
      end

      always_ff @(posedge dest_clk) begin
        dest_event_ff <= dest_event_nxt;
      end

      always_ff @(posedge dest_clk) begin
        dest_pulse_ff <= dest_pulse_int;
      end
    end
  endgenerate

  generate
    if (REG_OUTPUT != 0) begin : g_reg_out
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

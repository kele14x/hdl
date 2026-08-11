`timescale 1 ns / 1 ps
//
`default_nettype none (* KEEP_HIERARCHY = "yes" *)
module cdc_array_single #(
    parameter int DEST_SYNC_FF  = 4,
    parameter int INIT_SYNC_FF  = 0,
    parameter int SRC_INPUT_REG = 1,
    parameter int WIDTH         = 2
) (
    input  wire             src_clk,
    input  wire [WIDTH-1:0] src_in,
    //
    input  wire             dest_clk,
    output wire [WIDTH-1:0] dest_out
);

  initial begin : drc_check
    assert (DEST_SYNC_FF >= 2 && DEST_SYNC_FF <= 10)
    else begin
      $error("[%m]: DEST_SYNC_FF (%0d) is outside of valid range of 2-10.", DEST_SYNC_FF);
    end

    assert (INIT_SYNC_FF == 0 || INIT_SYNC_FF == 1)
    else begin
      $error("[%m]: INIT_SYNC_FF (%0d) is outside of valid range.", INIT_SYNC_FF);
    end

    assert (SRC_INPUT_REG == 0 || SRC_INPUT_REG == 1)
    else begin
      $error("[%m]: SRC_INPUT_REG (%0d) value is outside of valid range.", SRC_INPUT_REG);
    end

    assert (WIDTH >= 1 && WIDTH <= 1024)
    else begin
      $error("[%m]: WIDTH (%0d) is outside of valid range of 1-1024.", WIDTH);
    end
  end

  logic [WIDTH-1:0] src_inqual;
  logic [WIDTH-1:0] async_path_bit;

  (* ASYNC_REG = "true" *)
  logic [WIDTH-1:0] syncstages_ff  [DEST_SYNC_FF];

  initial begin : p_init
    if (INIT_SYNC_FF != 0) begin
      for (int i = 0; i < DEST_SYNC_FF; i++) begin
        syncstages_ff[i] = '0;
      end
    end
  end

  generate
    if (SRC_INPUT_REG != 0) begin : g_inreg
      logic [WIDTH-1:0] src_ff;

      always_ff @(posedge src_clk) begin
        src_ff <= src_in;
      end

      assign src_inqual = src_ff;
    end else begin : g_no_inreg
      assign src_inqual = src_in ^ {WIDTH{src_clk & 1'b0}};
    end
  endgenerate

  assign async_path_bit = src_inqual;

  always @(posedge dest_clk) begin : p_syncstages_ff
    syncstages_ff[0] <= async_path_bit;
    for (int i = 1; i < DEST_SYNC_FF; i++) begin
      syncstages_ff[i] <= syncstages_ff[i-1];
    end
  end

  assign dest_out = syncstages_ff[DEST_SYNC_FF-1];

endmodule

`default_nettype wire

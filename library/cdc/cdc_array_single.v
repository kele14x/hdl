// File: cdc_array_single.sv
// Brief: Simple array CDC, each bit is treat as separate and has no constrained
//        relationship.
`timescale 1 ns / 1 ps 
//
`default_nettype none

module cdc_array_single #(
    parameter integer DEST_SYNC_FF  = 2,
    parameter integer INIT_SYNC_FF  = 0,
    parameter integer SRC_INPUT_REG = 1,
    parameter integer WIDTH         = 1
) (
    input wire              src_clk,
    input wire  [WIDTH-1:0] src_in,
    input wire              dest_clk,
    output wire [WIDTH-1:0] dest_out
);

  initial begin : drc_check

    if (!(DEST_SYNC_FF >= 2 && DEST_SYNC_FF <= 10)) begin
      $error("[%m]: DEST_SYNC_FF (%0d) is outside of valid range of 2-10.", DEST_SYNC_FF);
      #1 $finish();
    end

    if (!(INIT_SYNC_FF == 0 || INIT_SYNC_FF == 1)) begin
      $error("[%m]: INIT_SYNC_FF (%0d) is outside of valid range.", INIT_SYNC_FF);
      #1 $finish();
    end

    if (!(SRC_INPUT_REG == 0 || SRC_INPUT_REG == 1)) begin
      $error("[%m]: SRC_INPUT_REG (%0d) value is outside of valid range.", SRC_INPUT_REG);
      #1 $finish();
    end

    if (!(WIDTH >= 1 && WIDTH <= 1024)) begin
      $error("[%m]: WIDTH (%0d) is outside of valid range of 1-1024.", WIDTH);
      #1 $finish();
    end

  end


  reg [WIDTH-1:0] src_ff;

  (* ASYNC_REG = "TRUE" *)
  reg [WIDTH-1:0] sync_ff[0:DEST_SYNC_FF-1];


  generate

    if (SRC_INPUT_REG) begin : src_input_reg

      initial begin
        if (INIT_SYNC_FF) begin
          src_ff = 'b0;
        end
      end

      always @(posedge src_clk) begin
        src_ff <= src_in;
      end

    end else begin : no_input_reg

      always @(*) begin
        src_ff <= src_in;
      end

    end

  endgenerate

  initial begin : p_init
    integer i;
    if (INIT_SYNC_FF) begin
      for (i = 0; i < DEST_SYNC_FF; i = i + 1) begin
        sync_ff[i] = 'b0;
      end
    end
  end

  always @(posedge dest_clk) begin : p_sync
    integer i;
    sync_ff[0] <= src_ff;
    for (i = 1; i < DEST_SYNC_FF; i = i + 1) begin
      sync_ff[i] <= sync_ff[i-1];
    end
  end

  assign dest_out = sync_ff[DEST_SYNC_FF-1];

endmodule

`default_nettype wire

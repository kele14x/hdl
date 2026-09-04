`timescale 1 ns / 1 ps
//
`default_nettype none

module delay #(
    parameter int WIDTH   = 8,
    parameter int DEPTH   = 8,
    parameter int INIT    = 0,
    parameter int USE_REG = 0
) (
    input var              clk,
    input var              rst,
    input var              cen,
    //
    input var  [WIDTH-1:0] din,
    output var [WIDTH-1:0] dout
);

  // Check parameters

  initial begin : drc_check
    assert (DEPTH >= 0 && DEPTH <= 16384)
    else $error("[%m]: DEPTH (%d) must be within the range 0 to 16384.", DEPTH);

    assert (WIDTH >= 1 && WIDTH <= 1024)
    else $error("[%m]: WIDTH (%d) must be within the range 1 to 1024.", WIDTH);

    assert (USE_REG == 0 || USE_REG == 1)
    else $error("[%m]: USE_REG (%d) must be 0 or 1.", USE_REG);
  end

  generate
    if (DEPTH == 0) begin : g_no_reg

      wire unused = &{1'b0, clk, rst, cen};

      assign dout = din;

    end else if (USE_REG != 0) begin : g_register

      // Keep this pipeline as ordinary flip-flops. Without this attribute,
      // Vivado may extract the regular shift pattern back into SRLs.
      (* shreg_extract = "no" *) logic [WIDTH-1:0] dregs[0:DEPTH-1];

      initial begin : p_init
        integer i;
        if (INIT != 0) begin
          for (i = 0; i < DEPTH; i = i + 1) begin
            dregs[i] = 'b0;
          end
        end
      end

      // Plain always, not always_ff: dregs is also driven by p_init above,
      // which Questa rejects for always_ff (vopt-7061).
      always @(posedge clk) begin : p_shift
        integer i;
        if (rst) begin
          for (i = 0; i < DEPTH; i = i + 1) begin
            dregs[i] <= 'b0;
          end
        end else if (cen) begin
          dregs[0] <= din;
          for (i = 1; i < DEPTH; i = i + 1) begin
            dregs[i] <= dregs[i-1];
          end
        end
      end

      assign dout = dregs[DEPTH-1];

    end else begin : g_srl

      // SRL primitives have no reset input. Initialization is controlled by
      // INIT; rst is intentionally unused in this implementation.
      wire unused = &{1'b0, rst};

      (* shreg_extract = "yes" *)
      logic [WIDTH-1:0] dregs[0:DEPTH-1];

      initial begin : p_init
        integer i;
        if (INIT != 0) begin
          for (i = 0; i < DEPTH; i = i + 1) begin
            dregs[i] = 'b0;
          end
        end
      end

      // Plain always, not always_ff: dregs is also driven by p_init above,
      // which Questa rejects for always_ff (vopt-7061).
      always @(posedge clk) begin : p_shift
        integer i;
        if (cen) begin
          dregs[0] <= din;
          for (i = 1; i < DEPTH; i = i + 1) begin
            dregs[i] <= dregs[i-1];
          end
        end
      end

      assign dout = dregs[DEPTH-1];

    end
  endgenerate

endmodule

`default_nettype wire

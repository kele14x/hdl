// File: ram_sdp_asym.sv
// Brief: Simple Dual Port (SDP) memory with asymmetric port width.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sdp_asym #(
    parameter int    ADDR_WIDTH_A   = 11,
    parameter int    DATA_WIDTH_A   = 16,
    parameter int    ADDR_WIDTH_B   = 9,
    parameter int    DATA_WIDTH_B   = 64,
    parameter int    READ_LATENCY_B = 2,
    parameter string INIT_FILE      = ""
) (
    // Port A, write port
    input var                       clka,
    input var                       wea,
    input var  [  ADDR_WIDTH_A-1:0] addra,
    input var  [  DATA_WIDTH_A-1:0] dina,
    // Port B, read port
    input var                       clkb,
    input var  [READ_LATENCY_B-1:0] rstb,
    input var  [READ_LATENCY_B-1:0] enb,
    input var  [  ADDR_WIDTH_B-1:0] addrb,
    output var [  DATA_WIDTH_B-1:0] doutb
);

  localparam int SizeA = 2 ** ADDR_WIDTH_A;
  localparam int SizeB = 2 ** ADDR_WIDTH_B;

  localparam int MaxSize = (SizeA > SizeB) ? SizeA : SizeB;

  localparam int MaxWidth = (DATA_WIDTH_A > DATA_WIDTH_B) ? DATA_WIDTH_A : DATA_WIDTH_B;
  localparam int MinWidth = (DATA_WIDTH_A < DATA_WIDTH_B) ? DATA_WIDTH_A : DATA_WIDTH_B;

  localparam int Ratio = MaxWidth / MinWidth;
  localparam int Log2Ratio = $clog2(Ratio);

  initial begin
    assert (1 <= READ_LATENCY_B && READ_LATENCY_B <= 3)
    else begin
      $error("READ_LATENCY_B should be within range 1 to 3.");
      #1 $finish;
    end

    assert (MaxWidth % MinWidth == 0)
    else begin
      $error("The wider RAM port width should be an integer multiple of the narrower port width.");
      #1 $finish;
    end
  end

  logic [MinWidth-1:0] MEM [MaxSize];
  logic [DATA_WIDTH_B-1:0] regb[READ_LATENCY_B];

  initial begin
    for (int i = 0; i < MaxSize; i++) begin
      MEM[i] = '0;
    end
    if (INIT_FILE != "") begin : g_file_init
      $readmemh(INIT_FILE, MEM, 0, MaxSize - 1);
    end
  end

  generate
    if (DATA_WIDTH_A <= DATA_WIDTH_B) begin : g_n_wr
      always_ff @(posedge clka) begin
        if (wea) begin
          MEM[addra] <= dina;
        end
      end
    end else begin : g_s_wr
      always_ff @(posedge clka) begin
        if (wea) begin
          for (int i = 0; i < Ratio; i++) begin
            MEM[{addra, Log2Ratio'(i)}] <= dina[(i+1)*MinWidth-1-:MinWidth];
          end
        end
      end
    end
  endgenerate

  generate
    if (DATA_WIDTH_B <= DATA_WIDTH_A) begin : g_n_rd
      always_ff @(posedge clkb) begin
        if (rstb[0]) begin
          regb[0] <= '0;
        end else if (enb[0]) begin
          regb[0] <= MEM[addrb];
        end
      end
    end else begin : g_s_rd
      always_ff @(posedge clkb) begin
        if (rstb[0]) begin
          regb[0] <= '0;
        end else if (enb[0]) begin
          for (int i = 0; i < Ratio; i++) begin
            regb[0][(i+1)*MinWidth-1-:MinWidth] <= MEM[{addrb, Log2Ratio'(i)}];
          end
        end
      end
    end

    for (genvar i = 1; i < READ_LATENCY_B; i++) begin : g_output_reg
      always_ff @(posedge clkb) begin
        if (rstb[i]) begin
          regb[i] <= '0;
        end else if (enb[i]) begin
          regb[i] <= regb[i-1];
        end
      end
    end
  endgenerate

  assign doutb = regb[READ_LATENCY_B-1];

endmodule

`default_nettype wire

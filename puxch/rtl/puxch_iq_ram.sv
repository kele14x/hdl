`timescale 1 ns / 1 ps
//
`default_nettype none

// Full-block compressed PUXCH IQ memory.
//
// The logical memory has an 18-bit write port for one complex RE and a
// 36-bit read port for two consecutive REs. Splitting the 3584-word read
// depth into three full BRAM36-sized segments and one BRAM18-sized tail
// prevents Vivado from rounding the memory up to four BRAM36 tiles.
module puxch_iq_ram #(
    parameter int READ_LATENCY = 2
) (
    input var                     clka,
    input var                     wea,
    input var  [            12:0] addra,
    input var  [            17:0] dina,
    //
    input var                     clkb,
    input var                     rstb,
    input var  [READ_LATENCY-1:0] enb,
    input var  [            11:0] addrb,
    output var [            35:0] doutb
);

  localparam int NumFullSegments = 3;
  localparam int NumSegments = NumFullSegments + 1;
  localparam int FullWriteDepth = 2048;
  localparam int FullReadDepth = 1024;
  localparam int TailWriteDepth = 1024;
  localparam int TailReadDepth = 512;
  localparam int TotalWriteDepth = NumFullSegments * FullWriteDepth + TailWriteDepth;
  localparam int TotalReadDepth = NumFullSegments * FullReadDepth + TailReadDepth;

  logic [NumSegments-1:0] rd_sel;
  logic [NumSegments-1:0] rd_sel_pipe[READ_LATENCY];
  logic [           35:0] rd_data    [ NumSegments];

  initial begin : drc_check
    assert (READ_LATENCY >= 1 && READ_LATENCY <= 3)
    else $error("[%m]: READ_LATENCY (%0d) must be in the range 1 to 3.", READ_LATENCY);

    assert (TotalWriteDepth == 7168 && TotalReadDepth == 3584)
    else $error("[%m]: invalid segmented IQ RAM capacity.");
  end

  assert property (@(posedge clka) wea |-> (addra < 13'(TotalWriteDepth)))
  else $error("[%m]: write address %0d exceeds segmented IQ RAM depth.", addra);

  assert property (@(posedge clkb) disable iff (rstb) enb[0] |-> (addrb < 12'(TotalReadDepth)))
  else $error("[%m]: read address %0d exceeds segmented IQ RAM depth.", addrb);

  always_comb begin
    rd_sel = '0;
    if (addrb < 12'(TotalReadDepth)) begin
      rd_sel[addrb[11:10]] = 1'b1;
    end
  end

  always_ff @(posedge clkb) begin
    if (rstb) begin
      for (int stage = 0; stage < READ_LATENCY; stage++) begin
        rd_sel_pipe[stage] <= '0;
      end
    end else begin
      if (enb[0]) begin
        rd_sel_pipe[0] <= rd_sel;
      end
      for (int stage = 1; stage < READ_LATENCY; stage++) begin
        if (enb[stage]) begin
          rd_sel_pipe[stage] <= rd_sel_pipe[stage-1];
        end
      end
    end
  end

  generate
    for (genvar segment = 0; segment < NumFullSegments; segment++) begin : g_full
      logic [READ_LATENCY-1:0] rd_en;

      always_comb begin
        rd_en[0] = enb[0] && rd_sel[segment];
        for (int stage = 1; stage < READ_LATENCY; stage++) begin
          rd_en[stage] = enb[stage] && rd_sel_pipe[stage-1][segment];
        end
      end

      ram_sdp_asym #(
          .ADDR_WIDTH_A  (11),
          .DATA_WIDTH_A  (18),
          .ADDR_WIDTH_B  (10),
          .DATA_WIDTH_B  (36),
          .READ_LATENCY_B(READ_LATENCY),
          .DEPTH         (FullWriteDepth),
          .INIT_FILE     ("NONE"),
          .RAM_STYLE     ("BLOCK")
      ) u_ram (
          .clka (clka),
          .wea  (wea && (addra[12:11] == 2'(segment))),
          .addra(addra[10:0]),
          .dina (dina),
          //
          .clkb (clkb),
          .rstb (rstb),
          .enb  (rd_en),
          .addrb(addrb[9:0]),
          .doutb(rd_data[segment])
      );
    end
  endgenerate

  logic [READ_LATENCY-1:0] tail_rd_en;

  always_comb begin
    tail_rd_en[0] = enb[0] && rd_sel[NumFullSegments];
    for (int stage = 1; stage < READ_LATENCY; stage++) begin
      tail_rd_en[stage] = enb[stage] && rd_sel_pipe[stage-1][NumFullSegments];
    end
  end

  ram_sdp_asym #(
      .ADDR_WIDTH_A  (10),
      .DATA_WIDTH_A  (18),
      .ADDR_WIDTH_B  (9),
      .DATA_WIDTH_B  (36),
      .READ_LATENCY_B(READ_LATENCY),
      .DEPTH         (TailWriteDepth),
      .INIT_FILE     ("NONE"),
      .RAM_STYLE     ("BLOCK")
  ) u_tail_ram (
      .clka (clka),
      .wea  (wea && (addra[12:11] == 2'd3) && (addra < 13'(TotalWriteDepth))),
      .addra(addra[9:0]),
      .dina (dina),
      //
      .clkb (clkb),
      .rstb (rstb),
      .enb  (tail_rd_en),
      .addrb(addrb[8:0]),
      .doutb(rd_data[NumFullSegments])
  );

  always_comb begin
    doutb = '0;
    for (int segment = 0; segment < NumSegments; segment++) begin
      if (rd_sel_pipe[READ_LATENCY-1][segment]) begin
        doutb = rd_data[segment];
      end
    end
  end

endmodule

`default_nettype wire

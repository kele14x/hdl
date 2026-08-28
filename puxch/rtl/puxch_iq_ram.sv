`timescale 1 ns / 1 ps
//
`default_nettype none

// Compressed PUXCH IQ memory.
//
// The logical memory has an 18-bit write port for one complex RE and a
// 36-bit read port for two consecutive REs. Full block uses three RAMB36
// segments and one RAMB18 tail. Half block uses one 1920 x 18 RAMB36 for
// each ping/pong bank.
module puxch_iq_ram #(
    parameter int HALF_BLOCK   = 0,
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

  localparam int TotalWriteDepth = (HALF_BLOCK != 0) ? 3840 : 7168;
  localparam int TotalReadDepth = TotalWriteDepth / 2;

  initial begin : drc_check
    assert (HALF_BLOCK == 0 || HALF_BLOCK == 1)
    else $error("[%m]: HALF_BLOCK (%0d) must be 0 or 1.", HALF_BLOCK);

    assert (READ_LATENCY >= 1 && READ_LATENCY <= 3)
    else $error("[%m]: READ_LATENCY (%0d) must be in the range 1 to 3.", READ_LATENCY);
  end

  assert property (@(posedge clka) wea |-> (addra < 13'(TotalWriteDepth)))
  else $error("[%m]: write address %0d exceeds IQ RAM depth.", addra);

  assert property (@(posedge clkb) disable iff (rstb) enb[0] |-> (addrb < 12'(TotalReadDepth)))
  else $error("[%m]: read address %0d exceeds IQ RAM depth.", addrb);

  generate
    if (HALF_BLOCK != 0) begin : g_half
      localparam int NumBanks = 2;
      localparam int BankWriteDepth = 1920;
      localparam int BankReadDepth = BankWriteDepth / 2;

      logic        wr_bank;
      logic [10:0] wr_addr;
      logic        rd_bank;
      logic [ 9:0] rd_addr;
      logic        rd_sel_pipe[READ_LATENCY];
      logic [35:0] rd_data    [    NumBanks];

      assign wr_bank = addra >= 13'(BankWriteDepth);
      assign wr_addr = 11'(addra - (wr_bank ? 13'(BankWriteDepth) : 13'd0));
      assign rd_bank = addrb >= 12'(BankReadDepth);
      assign rd_addr = 10'(addrb - (rd_bank ? 12'(BankReadDepth) : 12'd0));

      always_ff @(posedge clkb) begin
        if (rstb) begin
          for (int stage = 0; stage < READ_LATENCY; stage++) begin
            rd_sel_pipe[stage] <= 1'b0;
          end
        end else begin
          if (enb[0]) begin
            rd_sel_pipe[0] <= rd_bank;
          end
          for (int stage = 1; stage < READ_LATENCY; stage++) begin
            if (enb[stage]) begin
              rd_sel_pipe[stage] <= rd_sel_pipe[stage-1];
            end
          end
        end
      end

      for (genvar bank = 0; bank < NumBanks; bank++) begin : g_bank
        logic [READ_LATENCY-1:0] rd_en;

        always_comb begin
          rd_en[0] = enb[0] && (rd_bank == 1'(bank));
          for (int stage = 1; stage < READ_LATENCY; stage++) begin
            rd_en[stage] = enb[stage] && (rd_sel_pipe[stage-1] == 1'(bank));
          end
        end

        ram_sdp_asym #(
            .ADDR_WIDTH_A  (11),
            .DATA_WIDTH_A  (18),
            .ADDR_WIDTH_B  (10),
            .DATA_WIDTH_B  (36),
            .READ_LATENCY_B(READ_LATENCY),
            .DEPTH         (BankWriteDepth),
            .INIT_FILE     ("NONE"),
            .RAM_STYLE     ("BLOCK")
        ) u_ram (
            .clka (clka),
            .wea  (wea && (wr_bank == 1'(bank))),
            .addra(wr_addr),
            .dina (dina),
            //
            .clkb (clkb),
            .rstb (rstb),
            .enb  (rd_en),
            .addrb(rd_addr),
            .doutb(rd_data[bank])
        );
      end

      assign doutb = rd_data[rd_sel_pipe[READ_LATENCY-1]];
    end else begin : g_full
      localparam int NumFullSegments = 3;
      localparam int NumSegments = NumFullSegments + 1;
      localparam int FullWriteDepth = 2048;
      localparam int TailWriteDepth = 1024;

      logic [NumSegments-1:0] rd_sel;
      logic [NumSegments-1:0] rd_sel_pipe[READ_LATENCY];
      logic [           35:0] rd_data    [ NumSegments];

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

      for (genvar segment = 0; segment < NumFullSegments; segment++) begin : g_segment
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
    end
  endgenerate

endmodule

`default_nettype wire

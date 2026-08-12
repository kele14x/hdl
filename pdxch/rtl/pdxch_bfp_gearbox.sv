`timescale 1 ns / 1 ps
//
`default_nettype none

// Convert the 64-bit O-RAN BFP9 byte stream into two-IQ (36-bit) words.
//
// One PRB contains an 8-bit header and 24 x 9-bit IQ values, for a total of
// 28 bytes.  Two PRBs therefore occupy seven 64-bit input beats.  The write
// side normalizes both PRB alignments into two ping-pong 4 x 64 distributed
// RAM banks.  The read side then uses only fixed slices to emit six words.
module pdxch_bfp_gearbox #(
    parameter int BYTE_REVERSE = 1,
    parameter int USER_WIDTH   = 91
) (
    input var                   clk,
    input var                   rst,
    //
    input var  [          63:0] s_axis_tdata,
    input var  [           7:0] s_axis_tkeep,
    input var                   s_axis_tlast,
    input var  [USER_WIDTH-1:0] s_axis_tuser,
    input var                   s_axis_tvalid,
    output var                  s_axis_tready,
    //
    output var [          35:0] m_axis_tdata,
    output var [           3:0] m_axis_exp,
    output var                  m_axis_tlast,
    output var [USER_WIDTH-1:0] m_axis_tuser,
    output var                  m_axis_tvalid
);

  // The address MSB selects one of two logical 4-row ping-pong banks.  A
  // synchronous write plus asynchronous read infers simple dual-port LUTRAM.
  (* ram_style = "distributed" *)logic [          63:0] prb_ram            [0:7];

  logic [           1:0] bank_full;
  logic [           1:0] bank_full_next;
  logic [           1:0] bank_last;

  logic [          63:0] input_data_ordered;
  logic                  input_fire;
  logic                  final_half_beat;
  logic                  input_ready;
  logic                  rd_finishing;
  logic                  wr_pair_bank_ready;
  logic                  wr_other_bank_ready;

  // beat_phase describes a pair of PRBs:
  //   0..2 : aligned PRB rows 0..2
  //   3    : aligned PRB row 3 and the next PRB's first 32 bits
  //   4..6 : unaligned PRB, joined through odd_residue
  logic [           2:0] beat_phase;
  logic                  wr_pair_bank;
  logic                  packet_open;
  logic                  packet_end_pending;
  logic [USER_WIDTH-1:0] packet_user;
  logic [          31:0] odd_residue;

  // The unaligned PRB's final 32 bits are written on the cycle after phase 6.
  // Input is paused for that cycle so the 8 x 64 RAM needs only one write port.
  logic                  tail_pending;
  logic                  tail_bank;

  logic                  ram_we;
  logic [           2:0] ram_waddr;
  logic [          63:0] ram_wdata;
  logic                  input_write_bank;
  logic [           1:0] input_write_addr;
  logic [          63:0] input_write_data;

  logic                  rd_active;
  logic                  rd_bank;
  logic [           2:0] rd_word;
  logic [           1:0] rd_addr;
  logic [          63:0] rd_ram_data;
  logic [           3:0] rd_next_bank_exp;
  logic [          19:0] rd_residue;
  logic [           3:0] rd_exp;
  logic [          35:0] output_data;

  initial begin : drc_check
    assert (USER_WIDTH >= 1)
    else $error("[%m]: USER_WIDTH (%0d) must be at least 1.", USER_WIDTH);
  end

  function automatic logic [63:0] byte_reverse64(input logic [63:0] din);
    for (int i = 0; i < 8; i++) begin
      byte_reverse64[63-8*i-:8] = din[8*i+7-:8];
    end
  endfunction

  assign input_data_ordered = (BYTE_REVERSE != 0) ? byte_reverse64(s_axis_tdata) : s_axis_tdata;
  assign final_half_beat = s_axis_tlast && (s_axis_tkeep == 8'h0F);
  assign rd_finishing = rd_active && (rd_word == 5);
  assign wr_pair_bank_ready =
      !bank_full[wr_pair_bank] || (rd_finishing && (rd_bank == wr_pair_bank));
  assign wr_other_bank_ready =
      !bank_full[~wr_pair_bank] || (rd_finishing && (rd_bank == ~wr_pair_bank));

  // A PRB that begins on a beat boundary owns wr_pair_bank.  Phase 3 may
  // also begin the unaligned PRB in the other bank, so both banks must be
  // available unless the beat is the four-byte end of an odd-PRB packet.
  always_comb begin
    if (packet_end_pending || tail_pending) begin
      input_ready = 1'b0;
    end else begin
      case (beat_phase)
        3'd0: input_ready = wr_pair_bank_ready;
        3'd3: input_ready = final_half_beat || wr_other_bank_ready;
        default: input_ready = 1'b1;
      endcase
    end
  end

  assign s_axis_tready = input_ready;
  assign input_fire = s_axis_tvalid && input_ready;

  // Normalize the current input beat into one RAM write.
  always_comb begin
    input_write_bank = wr_pair_bank;
    input_write_addr = '0;
    input_write_data = input_data_ordered;
    case (beat_phase)
      3'd0, 3'd1, 3'd2: begin
        input_write_addr = beat_phase[1:0];
      end
      3'd3: begin
        input_write_addr = 2'd3;
        input_write_data = {input_data_ordered[63:32], 32'b0};
      end
      3'd4, 3'd5, 3'd6: begin
        input_write_bank = ~wr_pair_bank;
        input_write_addr = beat_phase[1:0];
        input_write_data = {odd_residue, input_data_ordered[63:32]};
      end
      default: begin
        input_write_bank = wr_pair_bank;
        input_write_addr = '0;
        input_write_data = input_data_ordered;
      end
    endcase
  end

  always_comb begin
    ram_we    = 1'b0;
    ram_waddr = '0;
    ram_wdata = '0;

    if (tail_pending) begin
      ram_we    = 1'b1;
      ram_waddr = {tail_bank, 2'd3};
      ram_wdata = {odd_residue, 32'b0};
    end else if (input_fire) begin
      ram_we    = 1'b1;
      ram_waddr = {input_write_bank, input_write_addr};
      ram_wdata = input_write_data;
    end
  end

  always_ff @(posedge clk) begin
    if (ram_we) begin
      prb_ram[ram_waddr] <= ram_wdata;
    end
  end

  // Write-side sequencing and packet metadata.
  always_ff @(posedge clk) begin
    if (rst) begin
      beat_phase         <= '0;
      wr_pair_bank       <= 1'b0;
      packet_open        <= 1'b0;
      packet_end_pending <= 1'b0;
      packet_user        <= '0;
      odd_residue        <= '0;
      tail_pending       <= 1'b0;
      tail_bank          <= 1'b0;
      bank_last          <= '0;
    end else begin
      if (tail_pending) begin
        tail_pending <= 1'b0;
      end

      if (rd_active && (rd_word == 5) && bank_last[rd_bank]) begin
        packet_end_pending <= 1'b0;
      end

      if (input_fire) begin
        if ((beat_phase == 0) && !packet_open) begin
          packet_open <= 1'b1;
          packet_user <= s_axis_tuser;
        end

        case (beat_phase)
          3'd0:    beat_phase <= 3'd1;
          3'd1:    beat_phase <= 3'd2;
          3'd2:    beat_phase <= 3'd3;
          3'd3: begin
            bank_last[wr_pair_bank] <= s_axis_tlast;
            if (s_axis_tlast) begin
              beat_phase <= 3'd0;
              wr_pair_bank <= ~wr_pair_bank;
              packet_open <= 1'b0;
              packet_end_pending <= 1'b1;
            end else begin
              beat_phase  <= 3'd4;
              odd_residue <= input_data_ordered[31:0];
            end
          end
          3'd4: begin
            beat_phase  <= 3'd5;
            odd_residue <= input_data_ordered[31:0];
          end
          3'd5: begin
            beat_phase  <= 3'd6;
            odd_residue <= input_data_ordered[31:0];
          end
          3'd6: begin
            beat_phase   <= 3'd0;
            odd_residue  <= input_data_ordered[31:0];
            tail_pending <= 1'b1;
            tail_bank    <= ~wr_pair_bank;
            bank_last[~wr_pair_bank] <= s_axis_tlast;
            if (s_axis_tlast) begin
              packet_open        <= 1'b0;
              packet_end_pending <= 1'b1;
            end
          end
          default: beat_phase <= '0;
        endcase
      end

`ifndef SYNTHESIS
      if (input_fire) begin
        case (beat_phase)
          3'd0, 3'd1, 3'd2, 3'd4, 3'd5: begin
            assert (s_axis_tkeep == 8'hFF && !s_axis_tlast)
            else $error("[%m]: invalid TKEEP/TLAST in input phase %0d.", beat_phase);
          end
          3'd3: begin
            assert ((!s_axis_tlast && (s_axis_tkeep == 8'hFF)) ||
                    (s_axis_tlast && (s_axis_tkeep == 8'h0F)))
            else $error("[%m]: phase 3 must be a full cross-PRB beat or a four-byte EOP.");
          end
          3'd6: begin
            assert (s_axis_tkeep == 8'hFF)
            else $error("[%m]: phase 6 must contain eight valid bytes.");
          end
          default: begin
          end
        endcase
      end
`endif
    end
  end

  // A bank becomes visible only after all four rows have been written.  The
  // reader always consumes banks in the same alternating order as the writer.
  always_comb begin
    bank_full_next = bank_full;
    if (rd_active && (rd_word == 5)) begin
      bank_full_next[rd_bank] = 1'b0;
    end
    if (tail_pending) begin
      bank_full_next[tail_bank] = 1'b1;
    end
    if (input_fire && (beat_phase == 3)) begin
      bank_full_next[wr_pair_bank] = 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      bank_full <= '0;
    end else begin
      bank_full <= bank_full_next;
    end
  end

  // Distributed RAM has an asynchronous read.  Repeating rows 1 and 2 lets
  // the six output words be formed from fixed slices and a 20-bit residue.
  always_comb begin
    case (rd_word)
      3'd0: rd_addr = 2'd0;
      3'd1, 3'd2: rd_addr = 2'd1;
      3'd3, 3'd4: rd_addr = 2'd2;
      default: rd_addr = 2'd3;
    endcase
  end

  assign rd_ram_data = prb_ram[{rd_bank, rd_addr}];
  assign rd_next_bank_exp = prb_ram[{~rd_bank, 2'd0}][59:56];

  assign m_axis_tvalid = rd_active;
  assign m_axis_tdata  = output_data;
  assign m_axis_exp    = rd_exp;
  assign m_axis_tlast  = rd_active && (rd_word == 5) && bank_last[rd_bank];
  assign m_axis_tuser  = packet_user;

  always_comb begin
    output_data = '0;
    case (rd_word)
      3'd0: output_data = rd_ram_data[55:20];
      3'd1: output_data = {rd_residue[19:0], rd_ram_data[63:48]};
      3'd2: output_data = rd_ram_data[47:12];
      3'd3: output_data = {rd_residue[11:0], rd_ram_data[63:40]};
      3'd4: output_data = rd_ram_data[39:4];
      3'd5: output_data = {rd_residue[3:0], rd_ram_data[63:32]};
      default: output_data = '0;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_active  <= 1'b0;
      rd_bank    <= 1'b0;
      rd_word    <= '0;
      rd_residue <= '0;
      rd_exp     <= '0;
    end else if (!rd_active) begin
      if (bank_full_next[rd_bank]) begin
        rd_active <= 1'b1;
        rd_word   <= '0;
        rd_exp    <= rd_ram_data[59:56];
      end
    end else begin
      case (rd_word)
        3'd0: rd_residue[19:0] <= rd_ram_data[19:0];
        3'd2: rd_residue[11:0] <= rd_ram_data[11:0];
        3'd4: rd_residue[3:0] <= rd_ram_data[3:0];
        default: rd_residue <= rd_residue;
      endcase

      if (rd_word == 5) begin
        rd_bank   <= ~rd_bank;
        rd_word   <= '0;
        if (bank_full_next[~rd_bank]) begin
          // The asynchronous RAM read lets the reader switch directly to a
          // completed bank. Keep TVALID asserted between adjacent PRBs.
          rd_active <= 1'b1;
          rd_exp    <= rd_next_bank_exp;
        end else begin
          rd_active <= 1'b0;
        end
      end else begin
        rd_word <= rd_word + 1'b1;
      end
    end
  end

endmodule

`default_nettype wire

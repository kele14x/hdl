// File: oran_deframer_eth_parser.sv
// Brief: This module parse eCPRI packets (assume MAC header removed), write
//        parsed filed to scalar ports, then forward the packet to next stage.
//        Transport (eCPRI IQ) header (4) is removed here.
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_deframer_eth_parser #(
    parameter int NUM_DEST = 2
) (
    input var                 clk,
    input var                 rst,
    //
    input var  [        63:0] s_axis_tdata,
    input var  [         7:0] s_axis_tkeep,
    input var                 s_axis_tvalid,
    input var                 s_axis_tlast,
    //
    output var [        63:0] m_axis_tdata,
    output var [         7:0] m_axis_tkeep,
    output var                m_axis_tvalid,
    output var                m_axis_tlast,
    output var [NUM_DEST-1:0] m_axis_tdest,
    // O-RAN parse ports
    //------------------
    // eCPRI IQ Header
    output var                m_trans_header_valid,
    output var [        15:0] m_trans_rtc_pc_id,
    output var [         7:0] m_trans_seqid,
    output var                m_trans_ebit,
    output var [         6:0] m_trans_subseqid
);


  import oran_pkg::*;

  // FSM

  typedef enum int {
    S_RST,      // Under reset
    S_TRANS,    // Wait for transport header (4)
    S_PAYLOAD,  // Wait for U-Plane payload
    S_DISCARD   // Discard (non U-Plane payload)
  } state_t;

  state_t state, state_next;

  logic [63:0] s_axis_tdata_reversed;
  logic [63:0] s_axis_tdata_d;
  logic [ 7:0] s_axis_tkeep_d;

  wire unused_parser_delayed_axis = &{1'b0, s_axis_tdata_d[63:32], s_axis_tkeep_d[3:0]};

  logic        extra_last;

  // U-Plane Header

  // Transport Header (64-bit)
  logic [15:0] ecpri_rtc_pc_id;
  logic [ 7:0] ecpri_seqid;
  logic        ecpri_ebit;  // eCPRI Layer Fragmentation
  logic [ 6:0] ecpri_subseqid;

  logic [31:0] ecpri_header;


  // Main
  //-----

  // Header mapping

  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      s_axis_tdata_d <= s_axis_tdata_reversed;
      s_axis_tkeep_d <= s_axis_tkeep;
    end
  end

  assign {
    ecpri_rtc_pc_id,
    ecpri_seqid,
    ecpri_ebit,
    ecpri_subseqid
  } = ecpri_header;

  assign ecpri_header = s_axis_tdata_reversed[63:32];

  // Checks eCPRI header fields, the payload size is not check here since we
  // need to go though the whole packet before the know if the packet size is
  // correct.
  // TODO: eCPRI seqid is not checked
  // TODO: eCPRI Ebit is not support but not checked

  // FSM

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    // Stay at current state by default
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_TRANS;
      end

      S_TRANS: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_TRANS;
        end else if (s_axis_tvalid) begin
          state_next = S_PAYLOAD;
        end
      end

      S_PAYLOAD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_TRANS;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end


  // O-RAN Parse ports output

  // Transport header

  always_ff @(posedge clk) begin
    if (state == S_TRANS && s_axis_tvalid) begin
      m_trans_rtc_pc_id   <= ecpri_rtc_pc_id;
      m_trans_seqid       <= ecpri_seqid;
      m_trans_ebit        <= ecpri_ebit;
      m_trans_subseqid    <= ecpri_subseqid;
    end
  end

  always_ff @(posedge clk) begin
    m_trans_header_valid <= (state == S_TRANS && s_axis_tvalid);
  end

  // Output

  always_ff @(posedge clk) begin
    if (state == S_PAYLOAD && s_axis_tvalid && s_axis_tlast && s_axis_tkeep[4]) begin
      extra_last <= 1'b1;
    end else begin
      extra_last <= 1'b0;
    end
  end 
    

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tdata <= byte_reverse({s_axis_tdata_d[31:0], 32'b0});
    end else if ((state == S_PAYLOAD) && s_axis_tvalid) begin
      m_axis_tdata <= byte_reverse({s_axis_tdata_d[31:0], s_axis_tdata_reversed[63:32]});
    end
  end

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tkeep <= {4'b0, s_axis_tkeep_d[7:4]};
    end else if ((state == S_PAYLOAD) && s_axis_tvalid) begin
      m_axis_tkeep <= {s_axis_tkeep[3:0], s_axis_tkeep_d[7:4]};
    end
  end

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tvalid <= 1'b1;
    end else if ((state == S_PAYLOAD) && s_axis_tvalid) begin
      m_axis_tvalid <= 1'b1;
    end else begin
      m_axis_tvalid <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tlast <= 1'b1;
    end else if ((state == S_PAYLOAD) && s_axis_tvalid) begin
      m_axis_tlast <= s_axis_tlast && !s_axis_tkeep[4];
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_TRANS) && s_axis_tvalid) begin
      if (ecpri_rtc_pc_id[3:0] == 4'd0) begin
        m_axis_tdest <= 2'b01;
      end else if (ecpri_rtc_pc_id[3:0] == 4'd1) begin
        m_axis_tdest <= 2'b10;
      end else begin
        m_axis_tdest <= 2'b00;
      end
    end
  end

endmodule

`default_nettype wire

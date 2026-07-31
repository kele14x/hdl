// File: oran_deframer_dl_ss_readout.sv
// Brief: Readout section data from DL Symbol buffer, possible multi CC
//        and multi section. The read out process starts from Start of Symbol
//        (sos) signal. Assume it will complete before this symbol ends.
//        TODO: If decompress is need, we can add it here
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_deframer_dl_ss_readout (
    input var         clk,
    input var         rst,
    //
    input var         timer_sos,
    // BRAM
    // Readout latency is 4
    output var [10:0] buffer_rd_addr,      // 2k
    output var        buffer_rd_en,
    input var  [65:0] buffer_rd_dout,
    //
    output var [ 3:0] hdr_buffer_rd_addr,  // 16
    output var        hdr_buffer_rd_en,
    input var  [40:0] hdr_buffer_rd_dout,
    // DEFM data
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    input var         m_axis_tready,
    output var        m_axis_tlast,
    output var [39:0] m_axis_tuser,
    //
    input var  [ 3:0] ctrl_ud_comp_meth,
    input var  [ 3:0] ctrl_ud_iq_width
);

  // Signals
  //--------

  logic buffer_rd_en_d;
  logic buffer_rd_en_dd;
  logic buffer_rd_en_d3;
  logic buffer_rd_en_d4;

  logic m_axis_tvalid_s;

  wire  unused_m_axis_tready = &{1'b0, m_axis_tready};

  typedef enum int {
    S_RST,     // Under reset
    S_IDLE,    // Wait for start of symbol
    S_RD_HDR,  // Read section header
    S_CHK_HDR, // Check section header
    S_RD_DATA  // Output section data
  } state_t;

  state_t state, state_next;

  logic        section_valid;

  logic [ 7:0] section_udcomphdr;
  //
  logic [11:0] section_sectionid;
  logic        section_rb;
  logic        section_syminc;
  logic [ 9:0] section_startprbu;
  logic [ 7:0] section_numprbu;

  logic [13:0] section_size;
  logic [13:0] section_count;
  logic [ 2:0] section_re2;
  logic [ 3:0] section_hbyte;

  logic [ 4:0] iq_width;


  // BRAM data mapping
  //------------------

  // Section header
  assign {
    section_valid,
    section_udcomphdr,
    section_sectionid,
    section_rb,
    section_syminc,
    section_startprbu,
    section_numprbu
  } = hdr_buffer_rd_dout;

  assign iq_width = ctrl_ud_comp_meth == 0 ? 5'd16 : {1'b0, ctrl_ud_iq_width};


  // FSM
  //----
  // Section read out FSM
  // The state machine does the following:
  //   1. Wait the starting of a symbol (pulse of sos signal)
  //   2. Read out section header from the header buffer
  //   3. Check the section header valid flag (data[32]), if it is valid (1) then
  //      the following bytes are section body. If it is not valid (0) then
  //      we know that there is no valid section in buffer, so we can goes to
  //      idle and wait until next symbol time
  //   4. At the same time, calculates the section size from `numprbu` field
  //   5. Readout the section body, forward it to AXIS interface
  //   6. Goes to 2
  // Assume that all sections will be readout within the symbol time

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    // By default stay at current state
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_IDLE;
      end

      S_IDLE: begin
        if (timer_sos) begin
          state_next = S_RD_HDR;
        end
      end

      S_RD_HDR: begin
        state_next = S_CHK_HDR;
      end

      S_CHK_HDR: begin
        if (section_valid) begin
          state_next = S_RD_DATA;
        end else begin
          state_next = S_IDLE;
        end
      end

      S_RD_DATA: begin
        if (section_count + 1 >= section_size && section_re2 == 5) begin
          state_next = S_RD_HDR;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end


  // BRAM I/F

  always_ff @(posedge clk) begin
    if (rst | timer_sos) begin
      buffer_rd_addr <= '0;
    end else if (buffer_rd_en) begin
      buffer_rd_addr <= buffer_rd_addr + 11'd1;
    end
  end

  always_ff @(posedge clk) begin
    if (state_next == S_RD_DATA) begin
      if (section_hbyte == 0) begin
        buffer_rd_en <= 1'b1;
      end else if (section_re2 == 5 && {1'b0, section_hbyte} + ((iq_width == 5'd16) ? iq_width : iq_width + 5'd2) > 5'd16) begin
        buffer_rd_en <= 1'b1;
      end else if ({1'b0, section_hbyte} + iq_width > 5'd16) begin
        buffer_rd_en <= 1'b1;
      end else begin
        buffer_rd_en <= 1'b0;
      end
    end else begin
      buffer_rd_en <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    buffer_rd_en_d  <= buffer_rd_en;
    buffer_rd_en_dd <= buffer_rd_en_d;
    buffer_rd_en_d3 <= buffer_rd_en_dd;
    buffer_rd_en_d4 <= buffer_rd_en_d3;
  end


  // Header read BRAM I/F

  always_ff @(posedge clk) begin
    if (rst | timer_sos) begin
      hdr_buffer_rd_addr <= '0;
    end else if (state == S_RD_HDR) begin
      hdr_buffer_rd_addr <= hdr_buffer_rd_addr + 4'd1;
    end
  end

  always_ff @(posedge clk) begin
    if (state_next == S_RD_HDR) begin
      hdr_buffer_rd_en <= 1'b1;
    end else begin
      hdr_buffer_rd_en <= 1'b0;
    end
  end

  //
  always_ff @(posedge clk) begin
    if (state == S_CHK_HDR && section_valid) begin
      section_size <= {6'b0, section_numprbu};
    end
  end

  // Count for the words (bytes) already send
  always_ff @(posedge clk) begin
    if (state == S_CHK_HDR) begin
      section_count <= '0;
    end else if (state == S_RD_DATA && section_re2 == 5) begin
      section_count <= section_count + 14'd1;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_CHK_HDR) begin
      section_re2 <= '0;
    end else if (state == S_RD_DATA && section_re2 == 5) begin
      section_re2 <= 3'd0;
    end else if (state == S_RD_DATA) begin
      section_re2 <= section_re2 + 3'd1;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_CHK_HDR) begin
      section_hbyte <= 4'((iq_width == 5'd16) ? iq_width : iq_width + 5'd2);
    end else if (state == S_RD_DATA && section_re2 == 5) begin
      section_hbyte <= 4'({1'b0, section_hbyte} + ((iq_width == 5'd16) ? iq_width : iq_width + 5'd2));
    end else if (state == S_RD_DATA) begin
      section_hbyte <= 4'({1'b0, section_hbyte} + iq_width);
    end
  end


  // Output
  //-------

  assign {m_axis_tlast, m_axis_tvalid_s, m_axis_tdata} = buffer_rd_dout;

  assign m_axis_tvalid = m_axis_tvalid_s && buffer_rd_en_d4;

  assign m_axis_tkeep = '1;

  always_ff @(posedge clk) begin
    if (state == S_CHK_HDR && section_valid) begin
      m_axis_tuser <= {
        section_udcomphdr,
        section_sectionid,
        section_rb,
        section_syminc,
        section_startprbu,
        section_numprbu
      };
    end
  end

endmodule

`default_nettype wire

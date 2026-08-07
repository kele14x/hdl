//-----------------------------------------------------------------------------
// File: eth_pkt_fifo.sv
// Brief: Ethernet packet FIFO. This module buffers the incoming Ethernet
//        packets from Ethernet MAC and ensures that full packets are forwarded
//        to next module. For this, this FIFO works at AXIS packet store and
//        forward mode and causes one packet latency. The buffer should be
//        large enough to hold at least one (largest) packet.
//-----------------------------------------------------------------------------
`timescale 1 ns / 1 ps
`default_nettype none

module eth_pkt_fifo #(
    parameter int ADDR_WIDTH = 10
) (
    input var         aclk,
    input var         aresetn,
    // Input
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    output var        s_axis_tready,
    input var         s_axis_tuser,
    //
    input var  [79:0] s_axis_tstamp_out,
    input var         s_axis_tstamp_valid,
    // Output
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    input var         m_axis_tready,
    //
    output var [79:0] m_axis_tstamp_out,
    output var        m_axis_tstamp_valid
);

  // tdata + tkeep + tlast + tstamp + tstamp_valid
  localparam int DATA_WIDTH = (64 + 8 + 1 + 80 + 1);

  typedef enum int {
    S_WR_RST,  // Under reset
    S_WR_WORD0,  // Wait first AXIS Stream transaction
    S_WR_PASS,  // Writing packet to buffer
    S_WR_DISCARD  // Discarded left words in packet
  } wr_state_t;

  wr_state_t wr_state, wr_state_next;

  // Writer
  logic [ADDR_WIDTH-1:0] wr_addr, wr_addr_next, wr_addr_last;
  logic                  wr_we;
  logic [DATA_WIDTH-1:0] wr_data;

  logic                  wr_full;

  // Reader
  logic [ADDR_WIDTH-1:0] rd_addr;
  logic [           2:0] rd_en;
  logic [           2:0] rd_vld;
  logic [           2:0] rd_rdy;
  logic [DATA_WIDTH-1:0] rd_data;

  logic                  rd_empty;

  // Read/Writ shared
  logic [ADDR_WIDTH-1:0] tail_addr;


  // Writer FSM
  //===========

  // wr_state Machine
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      wr_state <= S_WR_RST;
    end else begin
      wr_state <= wr_state_next;
    end
  end

  always_comb begin
    // by default stay at current state
    wr_state_next = wr_state;

    // state transfer
    case (wr_state)
      S_WR_RST: begin
        wr_state_next = S_WR_WORD0;
      end

      S_WR_WORD0: begin
        if (s_axis_tvalid) begin
          if (s_axis_tlast) begin
            wr_state_next = S_WR_WORD0;
          end else if (wr_full) begin
            wr_state_next = S_WR_DISCARD;
          end else begin
            wr_state_next = S_WR_PASS;
          end
        end
      end

      S_WR_PASS: begin
        if (s_axis_tvalid) begin
          if (s_axis_tlast) begin
            wr_state_next = S_WR_WORD0;
          end else if (wr_full) begin
            wr_state_next = S_WR_DISCARD;
          end
        end
      end

      S_WR_DISCARD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          wr_state_next = S_WR_WORD0;
        end
      end

      default: begin
        wr_state_next = S_WR_RST;
      end
    endcase
  end

  // This buffer will mostly be ready
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      s_axis_tready <= 1'b0;
    end else begin
      s_axis_tready <= (wr_state_next == S_WR_WORD0 || wr_state_next == S_WR_PASS ||
        wr_state_next == S_WR_DISCARD);
    end
  end

  // When first word of packet is received, temporarily save current writing
  // address to `wr_addr_last`. We may fall back to this address if the packet
  // looks not good or the buffer is full.
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      wr_addr_last <= '0;
    end else if (wr_state == S_WR_WORD0 && s_axis_tvalid) begin
      wr_addr_last <= wr_addr;
    end
  end

  // Writing address increases based on whether the packet is good, and whether
  // the buffer is full
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      wr_addr <= '0;
    end else begin
      wr_addr <= wr_addr_next;
    end
  end

  always_comb begin
    // by default `wr_addr` is not changed
    wr_addr_next = wr_addr;

    // wr_addr change
    case (wr_state)
      S_WR_WORD0: begin
        if (s_axis_tvalid && !wr_full && !(s_axis_tlast && s_axis_tuser)) begin
          wr_addr_next = wr_addr + 1;
        end
      end

      S_WR_PASS: begin
        if (s_axis_tvalid) begin
          if (wr_full || (s_axis_tlast && s_axis_tuser)) begin
            wr_addr_next = wr_addr_last;
          end else begin
            wr_addr_next = wr_addr + 1;
          end
        end
      end

      default: begin
        wr_addr_next = wr_addr;
      end
    endcase
  end

  assign wr_we = s_axis_tvalid && (wr_state == S_WR_WORD0 || wr_state == S_WR_PASS) &&
    !wr_full && !(s_axis_tlast && s_axis_tuser);

  // We does not need to write tvalid and tready, tuser and bad_fcs flag
  assign wr_data = {
    s_axis_tstamp_valid, s_axis_tstamp_out, s_axis_tlast, s_axis_tkeep, s_axis_tdata
  };

  assign wr_full = (wr_addr == rd_addr - 1);


  // Shared
  //=======

  // tail_addr points to the end address of last received packet
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      tail_addr <= '0;
    end else if ((wr_state == S_WR_PASS || wr_state == S_WR_WORD0)
      && s_axis_tvalid && s_axis_tlast && !wr_full && !s_axis_tuser) begin
      tail_addr <= wr_addr + 1;
    end
  end


  // Reader Pipeline
  //================
  // rd_en[0]  -> rd_en[1]   -> rd_en[2]
  //           -> rd_vld[0]  -> rd_vld[1]  -> rd_vld[2]  (m_axis_tvalid)
  //           -> rd_data[0] -> rd_data[1] -> rd_data[2] (m_axis_tdata)
  //                                          m_axis_tready

  assign rd_empty  = (rd_addr == tail_addr);

  assign rd_en[0]  = !rd_empty && rd_rdy[0];
  assign rd_en[1]  = rd_vld[0] && rd_rdy[1];
  assign rd_en[2]  = rd_vld[1] && rd_rdy[2];

  assign rd_rdy[0] = (!rd_vld[0] || !rd_vld[1] || !rd_vld[2] || m_axis_tready);
  assign rd_rdy[1] = (!rd_vld[1] || !rd_vld[2] || m_axis_tready);
  assign rd_rdy[2] = (!rd_vld[2] || m_axis_tready);

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      rd_vld <= '0;
    end else begin
      if (rd_en[0]) begin
        rd_vld[0] <= 1'b1;
      end else if (rd_en[1]) begin
        rd_vld[0] <= 1'b0;
      end

      if (rd_en[1]) begin
        rd_vld[1] <= 1'b1;
      end else if (rd_en[2]) begin
        rd_vld[1] <= 1'b0;
      end

      if (rd_en[2]) begin
        rd_vld[2] <= 1'b1;
      end else if (m_axis_tready) begin
        rd_vld[2] <= 1'b0;
      end
    end
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      rd_addr <= '0;
    end else if (rd_en[0]) begin
      rd_addr <= rd_addr + 1;
    end else begin
      rd_addr <= rd_addr;
    end
  end

  // Output AXIS interface

  assign {m_axis_tstamp_valid, m_axis_tstamp_out, m_axis_tlast, m_axis_tkeep, m_axis_tdata} = rd_data;

  assign m_axis_tvalid = rd_vld[2];


  // The Buffer
  //===========

  ram_sdp #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(3),
      .INIT_FILE   ("NONE")
  ) i_buffer (
      // Port A
      .clka (aclk),
      .wea  (wr_we),
      .addra(wr_addr),
      .dina (wr_data),
      // Port B
      .clkb (aclk),
      .rstb (1'b0),
      .enb  (rd_en),
      .addrb(rd_addr),
      .doutb(rd_data)
  );

endmodule

`default_nettype none

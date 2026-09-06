// File: oran_framer_eth.sv
// Brief: Per Ethernet channel for framer. This module does:
//        - CDC UL packet from internal_bus_clk domain to Ethernet TX clock domain
//        - Add MAC header, including VLAN is enabled
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_framer_eth #(
    parameter int FIFO_DEPTH = 1024
) (
    // Tx Ethernet ports
    //------------------
    input var         tx_eth_clk,
    /* verilator lint_off UNUSED */
    input var         tx_eth_rst,
    /* verilator lint_on UNUSED */
    // Tx data
    output var [63:0] m_eth_fram_tdata,
    output var [ 7:0] m_eth_fram_tkeep,
    output var        m_eth_fram_tvalid,
    output var        m_eth_fram_tlast,
    input var         m_eth_fram_tready,
    // Internal clock domain
    //----------------------
    input var         internal_bus_clk,
    input var         fram_reset,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    output var        s_axis_tready,
    //
    input var  [47:0] ctrl_dest_mac,
    input var  [47:0] ctrl_src_mac,
    input var         ctrl_has_vlan,
    input var  [15:0] ctrl_vlan_tag
);

  import oran_pkg::*;

  // Signals
  //--------

  logic [63:0] s_axis_tdata_reversed;

  /* verilator lint_off UNUSED */
  logic [63:0] s_axis_tdata_d;
  logic [7:0] s_axis_tkeep_d;
  /* verilator lint_on UNUSED */

  typedef enum int {
    S_RST,          // Under reset
    S_DMAC_SMAC0,   // Write Destination MAC [47:0] (6) and Source MAC [47:32] (2)
    S_SMAC1_VLAN,   // Write Source MAC [31:0] (4), VLAN EtherType [15:0] (2)
                    // and VLAN tag [15:0] (2)
    S_SMAC1_ETYPE,  // Write Source MAC [31:0] (4) and EtherType [15:0] (2)
                    //   and possible Payload (2)
    S_ETYPE,        // If VLAN Type, so this is EtherType (2) and Payload (6)
    S_PAYLOAD6,     // with VLAN, so this is previous (2) and new (6)
    S_PAYLOAD2,     // w/o VLAN, so this is previous (6) and new (2)
    S_LAST6,        // Last word of payload
    S_LAST2         // Last word of payload
  } state_t;

  state_t state, state_next;

  logic [63:0] m0_axis_tdata;
  logic [7:0] m0_axis_tkeep;
  logic m0_axis_tvalid;
  logic m0_axis_tlast;
  logic m0_axis_tready;

  /* verilator lint_off UNUSED */
  logic [$clog2(FIFO_DEPTH):0] fifo_wr_data_count;
  logic [$clog2(FIFO_DEPTH):0] fifo_rd_data_count;
  logic fifo_almost_full;
  logic fifo_prog_full;
  logic fifo_m_axis_tdest;
  logic fifo_m_axis_tid;
  logic [7:0] fifo_m_axis_tstrb;
  logic fifo_m_axis_tuser;
  logic fifo_almost_empty;
  logic fifo_prog_empty;
  logic fifo_sbiterr;
  logic fifo_dbiterr;
  /* verilator lint_on UNUSED */

  logic [15:0] mac_vlan_type = 16'h8100;
  logic [15:0] mac_ethertype = 16'hAEFE;


  // Main
  //-----

  always_ff @(posedge internal_bus_clk) begin
    if (fram_reset) begin
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
        state_next = S_DMAC_SMAC0;
      end

      S_DMAC_SMAC0: begin
        if (s_axis_tvalid) begin
          if (ctrl_has_vlan) begin
            state_next = S_SMAC1_VLAN;
          end else begin
            state_next = S_SMAC1_ETYPE;
          end
        end
      end

      // with VLAN path

      S_SMAC1_VLAN: begin
        if (s_axis_tvalid) begin
          state_next = S_ETYPE;
        end
      end

      S_ETYPE: begin
        if (s_axis_tvalid) begin
          state_next = S_PAYLOAD6;
        end
      end

      S_PAYLOAD6: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          if (s_axis_tkeep[6]) begin
            state_next = S_LAST6;
          end else begin
            state_next = S_DMAC_SMAC0;
          end
        end
      end

      S_LAST6: begin
        state_next = S_DMAC_SMAC0;
      end

      // wi/o VLAN path

      S_SMAC1_ETYPE: begin
        state_next = S_PAYLOAD2;
      end

      S_PAYLOAD2: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          if (s_axis_tkeep[2]) begin
            state_next = S_LAST2;
          end else begin
            state_next = S_DMAC_SMAC0;
          end
        end
      end

      S_LAST2: begin
        if (m0_axis_tready) begin
          state_next = S_DMAC_SMAC0;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end


  // Master AXIS

  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  always_ff @(posedge internal_bus_clk) begin
    if (s_axis_tvalid && s_axis_tready) begin
      s_axis_tdata_d <= s_axis_tdata_reversed;
      s_axis_tkeep_d <= s_axis_tkeep;
    end
  end

  always_ff @(posedge internal_bus_clk) begin
    if (state == S_DMAC_SMAC0) begin
      m0_axis_tdata <= byte_reverse({ctrl_dest_mac, ctrl_src_mac[47:32]});
    end else if (state == S_SMAC1_VLAN) begin
      m0_axis_tdata <= byte_reverse({ctrl_src_mac[31:0], mac_vlan_type, ctrl_vlan_tag});
    end else if (state == S_SMAC1_ETYPE) begin
      m0_axis_tdata <=
          byte_reverse({ctrl_src_mac[31:0], mac_ethertype, s_axis_tdata_reversed[63:48]});
    end else if (state == S_ETYPE) begin
      m0_axis_tdata <= byte_reverse({mac_ethertype, s_axis_tdata_reversed[63:16]});
    end else if (state == S_PAYLOAD6) begin
      m0_axis_tdata <= byte_reverse({s_axis_tdata_d[15:0], s_axis_tdata_reversed[63:16]});
    end else if (state == S_LAST6) begin
      m0_axis_tdata <= byte_reverse({s_axis_tdata_d[15:0], 48'b0});
    end else if (state == S_PAYLOAD2) begin
      m0_axis_tdata <= byte_reverse({s_axis_tdata_d[47:0], s_axis_tdata_reversed[63:48]});
    end else if (state == S_LAST2) begin
      m0_axis_tdata <= byte_reverse({s_axis_tdata_d[47:0], 16'b0});
    end
  end

  always_ff @(posedge internal_bus_clk) begin
    if (state == S_DMAC_SMAC0) begin
      m0_axis_tkeep <= '1;
    end else if (state == S_SMAC1_VLAN) begin
      m0_axis_tkeep <= '1;
    end else if (state == S_SMAC1_ETYPE) begin
      m0_axis_tkeep <= {s_axis_tkeep[1:0], 6'b111111};
    end else if (state == S_ETYPE) begin
      m0_axis_tkeep <= {s_axis_tkeep[5:0], 2'b11};
    end else if (state == S_PAYLOAD6) begin
      m0_axis_tkeep <= {s_axis_tkeep[5:0], s_axis_tkeep_d[7:6]};
    end else if (state == S_LAST6) begin
      m0_axis_tkeep <= {6'b0, s_axis_tkeep_d[7:6]};
    end else if (state == S_PAYLOAD2) begin
      m0_axis_tkeep <= {s_axis_tkeep[1:0], s_axis_tkeep_d[7:2]};
    end else if (state == S_LAST2) begin
      m0_axis_tkeep <= {2'b0, s_axis_tkeep_d[7:2]};
    end
  end

  always_ff @(posedge internal_bus_clk) begin
    m0_axis_tvalid <= (((state == S_DMAC_SMAC0 || state == S_SMAC1_VLAN || state == S_SMAC1_ETYPE ||
                         state == S_ETYPE || state == S_PAYLOAD6 || state == S_PAYLOAD2) && s_axis_tvalid) ||
                         state == S_LAST6 || state == S_LAST2);
  end

  always_ff @(posedge internal_bus_clk) begin
    m0_axis_tlast <= (state == S_LAST6 || state == S_LAST2) ||
                     (state == S_PAYLOAD2 && s_axis_tlast && !s_axis_tkeep[2]) ||
                     (state == S_PAYLOAD6 && s_axis_tlast && !s_axis_tkeep[6]);
  end


  // Slave AXIS

  always_ff @(posedge internal_bus_clk) begin
    if (state_next == S_SMAC1_ETYPE || state_next == S_ETYPE || state_next == S_PAYLOAD6 ||
      state_next == S_PAYLOAD2) begin
      s_axis_tready <= 1'b1;
    end else begin
      s_axis_tready <= 1'b0;
    end
  end


  // Ethernet CDC FIFO
  //------------------
  // Assume this FIFO is never full

`ifdef XILINX
  xpm_fifo_axis #(
      .CASCADE_HEIGHT     (0),
      .CDC_SYNC_STAGES    (2),
      .CLOCKING_MODE      ("independent_clock"),
      .ECC_MODE           ("no_ecc"),
      .FIFO_DEPTH         (FIFO_DEPTH),
      .FIFO_MEMORY_TYPE   ("block"),
      .PACKET_FIFO        ("true"),
      .PROG_EMPTY_THRESH  (10),
      .PROG_FULL_THRESH   (10),
      .RD_DATA_COUNT_WIDTH($clog2(FIFO_DEPTH) + 1),
      .RELATED_CLOCKS     (0),
      .SIM_ASSERT_CHK     (0),
      .TDATA_WIDTH        (64),
      .TDEST_WIDTH        (1),
      .TID_WIDTH          (1),
      .TUSER_WIDTH        (1),
      .USE_ADV_FEATURES   ("0808"),                  // required by packet FIFO
      .WR_DATA_COUNT_WIDTH($clog2(FIFO_DEPTH) + 1)
  ) xpm_fifo_axis_inst (
      .s_aclk            (internal_bus_clk),
      .s_aresetn         (!fram_reset),
      //
      .s_axis_tdata      (m0_axis_tdata),
      .s_axis_tdest      ('0),
      .s_axis_tid        ('0),
      .s_axis_tkeep      (m0_axis_tkeep),
      .s_axis_tlast      (m0_axis_tlast),
      .s_axis_tready     (m0_axis_tready),
      .s_axis_tstrb      (m0_axis_tkeep),
      .s_axis_tuser      ('0),
      .s_axis_tvalid     (m0_axis_tvalid),
      //
      .injectdbiterr_axis(1'b0),
      .injectsbiterr_axis(1'b0),
      .wr_data_count_axis(fifo_wr_data_count),
      .almost_full_axis  (fifo_almost_full),
      .prog_full_axis    (fifo_prog_full),
      //
      .m_aclk            (tx_eth_clk),
      //
      .m_axis_tdata      (m_eth_fram_tdata),
      .m_axis_tdest      (fifo_m_axis_tdest),
      .m_axis_tid        (fifo_m_axis_tid),
      .m_axis_tkeep      (m_eth_fram_tkeep),
      .m_axis_tlast      (m_eth_fram_tlast),
      .m_axis_tready     (m_eth_fram_tready),
      .m_axis_tstrb      (fifo_m_axis_tstrb),
      .m_axis_tuser      (fifo_m_axis_tuser),
      .m_axis_tvalid     (m_eth_fram_tvalid),
      .rd_data_count_axis(fifo_rd_data_count),
      .almost_empty_axis (fifo_almost_empty),
      .prog_empty_axis   (fifo_prog_empty),
      .sbiterr_axis      (fifo_sbiterr),
      .dbiterr_axis      (fifo_dbiterr)
      //
  );
`else
  axis_fifo #(
      .ASYNC_MODE  (1),
      .PACKET_MODE (1),
      .FIFO_DEPTH  (FIFO_DEPTH),
      .FIFO_LATENCY(3),
      .DATA_WIDTH  (64),
      .USER_WIDTH  (0)
  ) axis_fifo_inst (
      .s_axis_aclk   (internal_bus_clk),
      .s_axis_aresetn(!fram_reset),
      .s_axis_tdata  (m0_axis_tdata),
      .s_axis_tkeep  (m0_axis_tkeep),
      .s_axis_tlast  (m0_axis_tlast),
      .s_axis_tuser  ('0),
      .s_axis_tvalid (m0_axis_tvalid),
      .s_axis_tready (m0_axis_tready),
      .m_axis_aclk   (tx_eth_clk),
      .m_axis_tdata  (m_eth_fram_tdata),
      .m_axis_tkeep  (m_eth_fram_tkeep),
      .m_axis_tlast  (m_eth_fram_tlast),
      .m_axis_tuser  (fifo_m_axis_tuser),
      .m_axis_tvalid (m_eth_fram_tvalid),
      .m_axis_tready (m_eth_fram_tready)
  );

  assign fifo_wr_data_count = '0;
  assign fifo_rd_data_count = '0;
  assign fifo_almost_full   = 1'b0;
  assign fifo_prog_full     = 1'b0;
  assign fifo_m_axis_tdest  = 1'b0;
  assign fifo_m_axis_tid    = 1'b0;
  assign fifo_m_axis_tstrb  = '0;
  assign fifo_almost_empty  = 1'b1;
  assign fifo_prog_empty    = 1'b1;
  assign fifo_sbiterr       = 1'b0;
  assign fifo_dbiterr       = 1'b0;
`endif


endmodule

`default_nettype wire

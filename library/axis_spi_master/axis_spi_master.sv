//=============================================================================
//
// Copyright (C) 2019 Kele
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
//=============================================================================
//
// Filename: axis_spi_master.sv
//
// Purpose: SPI master core with AXI4-Stream interface, this core was designed
//   to interface other cores easily.
//
// Note:
//   SPI Interface timing:
//
//                             ___     ___     ___     ___     ___
//      SCK   CPOL=0  ________/   \___/   \___/   \___/   \___/   \____________
//                    ________     ___     ___     ___     ___     ____________
//            CPOL=1          \___/   \___/   \___/   \___/   \___/
//
//                    ____                                             ________
//      SS                \___________________________________________/
//
//                         _______ _______ _______ _______ _______
//      MOSI/ CPHA=0  zzzzX___0___X___1___X__...__X___6___X___7___X---Xzzzzzzzz
//      MISO                   _______ _______ _______ _______ _______
//            CPHA=1  zzzz----X___0___X___1___X__...__X___6___X___7___Xzzzzzzzz
//
// Limitation:
//   This core is fixed CPOL = 0 and CPHA = 1. That means both master and salve
//   (this core) will drive MOSI/MISO at rising edge of SCK, and should sample
//   MISO/MOSI at falling edge.
//
//=============================================================================

`timescale 1 ns / 1 ps
`default_nettype none

module axis_spi_master #(parameter CLK_RATIO   = 8) (
    // SPI
    //====
    output reg        SCK             ,
    output reg        SS_N            ,
    output reg        MOSI_Z          ,
    input  wire       MISO            ,
    // Fabric
    //=======
    input  wire       aclk            ,
    input  wire       aresetn         ,
    // AXIS TX Data
    //-------------
    input  wire [7:0] s_axis_tdata    ,
    input  wire       s_axis_tvalid   ,
    output reg        s_axis_tready   ,
    // AXIS RX Data
    //-------------
    output reg  [7:0] m_axis_tdata    ,
    output reg        m_axis_tvalid   ,
    input  wire       m_axis_tready   ,
    // Status
    //-------
    output reg        stat_rx_overflow
);

    initial begin
        assert (CLK_RATIO / 2 == 0 && CLK_RATIO >= 2)
            else $error("CLK_RATIO must be an positive even number.");
    end


    // SCK edge generator
    //===================

    reg [$clog2(CLK_RATIO)-1:0] edge_counter = 0;
    reg                         rising_edge, falling_edge;


    // edge_counter runs freely
    always_ff @ (posedge aclk) begin : p_edge_counter
        if (!aresetn) begin
            edge_counter <= 0;
        end else begin
            edge_counter <= (edge_counter == CLK_RATIO - 1) ? 0 : edge_counter + 1;
        end
    end

    always_ff @ (posedge aclk) begin
        rising_edge  <= edge_counter == 0;
        falling_edge <= edge_counter == CLK_RATIO / 2;
    end


    // TX State Machine
    //==================

    typedef enum {S_RST, S_SYNC, S_IDLE, S_PRE, S_BITX} STATE_T;
    STATE_T state_next, state;

    reg [3:0] state_cnt;
    reg tx_cache_v;

    // `stat_cnt` state machine
    always_ff @ (posedge aclk) begin : p_state
        if (!aresetn) begin
            state <= S_RST;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin : c_state_next
        case(state)
            S_RST  : state_next = S_IDLE;
            S_IDLE : state_next = !tx_cache_v   ? S_IDLE :         // Wait for tx data at axis i/f
                                  !falling_edge ? S_SYNC : S_PRE;  // if at falling edge, skip S_SYNC stage
            S_SYNC : state_next = !falling_edge ? S_SYNC : S_PRE;
            S_PRE  : state_next = !rising_edge  ? S_PRE  : S_BITX;
            S_BITX : state_next = !rising_edge  ? S_BITX :
                                  (state_cnt != 15) ? S_BITX :     // This is not last bit of a byte
                                   tx_cache_v   ? S_BITX : S_IDLE; // When last bit is send, see if we have more byte
            default: state_next = S_RST;
        endcase
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            state_cnt <= 0;
        end else if (state == S_BITX && (rising_edge || falling_edge)) begin
            state_cnt <= state_cnt + 1;
        end else if (state == S_BITX) begin
            state_cnt <= state_cnt;
        end else begin // other states
            state_cnt <= 0;
        end
    end


    // Slave (TX) AXIS Interface
    //==========================

    reg [7:0] tx_data, tx_cache, rx_data;
    wire tx_load;
    reg rx_valid;

    // When the core try to load a byte from tx_cache to tx_data
    assign tx_load = (state == S_IDLE || (state == S_BITX && state_cnt == 15 && rising_edge))
        && tx_cache_v;

    always_ff @ (posedge aclk) begin
        if (tx_load) begin
            tx_data <= tx_cache;
        end
    end

    // s_axis_tready state machine
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axis_tready <= 1'b0;
        end else if (s_axis_tready && s_axis_tvalid) begin
            s_axis_tready <= 1'b0;
        end else if (tx_load) begin
            s_axis_tready <= 1'b1;
        end else begin
            s_axis_tready <= !tx_cache_v;
        end
    end

    // When there is a valid transfer on s_axis_* bus, move the data into
    // tx_cache
    always_ff @ (posedge aclk) begin
        if (s_axis_tready && s_axis_tvalid) begin
            tx_cache <= s_axis_tdata;
        end
    end

    // tx_cache_v indicate tx_cache is valid, it will keep valid until core
    // load it into tx_data
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            tx_cache_v <= 1'b0;
        end else if (s_axis_tready && s_axis_tvalid) begin
            tx_cache_v <= 1'b1;
        end else if (tx_load) begin
            tx_cache_v <= 1'b0;
        end
    end


    // Master (RX) AXIS I/F
    //=====================

    always_ff @ (posedge aclk) begin : p_rx_axis_tvalid
        if (!aresetn) begin
            m_axis_tvalid <= 1'b0;
        end else if (rx_valid) begin
            m_axis_tvalid <= 1'b1;
        end if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tvalid <= 1'b0;
        end
    end

    always_ff @ (posedge aclk) begin : p_rx_axis_tdata
        if (rx_valid && (!m_axis_tvalid || m_axis_tready)) begin
            m_axis_tdata <= rx_data;
        end
    end


    // SPI RX Side
    //============

    always_ff @ (posedge aclk) begin
        SS_N <= !(state == S_BITX || state == S_PRE);
    end

    always_ff @ (posedge aclk) begin
        SCK <= !state_cnt[0] && state == S_BITX;
    end

    always_ff @ (posedge aclk) begin
        MOSI_Z <= (state == S_PRE)  ? 1'b0 : 
                  (state == S_BITX) ? (tx_data[state_cnt[3:1]]) : 1'bZ;
    end


    // SPI Tx Side
    //============
    
    reg rx_sample_edge;

    always_ff @ (posedge aclk) begin
        rx_sample_edge <= (state == S_BITX) && falling_edge;
    end

    always_ff @ (posedge aclk) begin
        if (rx_sample_edge) begin
            rx_data[state_cnt[3:1]] <= MISO;
        end
    end

    always_ff @ (posedge aclk) begin
        rx_valid <= (rx_sample_edge && (state_cnt == 15));
    end


    // Status
    //=========

    always_ff @ (posedge aclk) begin
        if (rx_valid && m_axis_tvalid && !m_axis_tready) begin
            stat_rx_overflow <= 1'b1;
        end else begin
            stat_rx_overflow <= 1'b0;
        end
    end

`ifdef SIMULATION

    //
    assert property (
        @(posedge aclk) !aresetn ##1 aresetn |-> !m_axis_tvalid
    ) else
        $error("TVALID should be LOW for the first cycle after ARESETn goes HIGH");

    //
    assert property (
        @(posedge aclk)
        aresetn & m_axis_tvalid & !m_axis_tready ##1 aresetn
        |-> $stable(m_axis_tdata)
    ) else
        $error("TDATA should remains stable when TVALID is asserted, and TREADY is LOW");

    //
    assert property (
        @(posedge aclk)
        aresetn & m_axis_tvalid |-> ! $isunknown(m_axis_tdata)
    ) else
        $error("A value of X on TDATA is not permitted when TVALID is HIGH");

`endif

endmodule

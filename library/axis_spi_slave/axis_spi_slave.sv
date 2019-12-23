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
// Filename: axis_spi_slave.sv
//
// Purpose: SPI slave core with AXI4-Stream interface, this core was designed
//   to be SPI slave which SCK's frequency is close to core clock frequency
//   (as 50% fast as core clock).
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
//   Data to be send to SPI master by core should be present on AXIS slave
//   interface. However, to avoid metastability on CDC, this core will not
//   response to first 8-bit in each frame (SS_N active period). Even on second
//   8-bit, data should be load into AXIS before the start of second byte on
//   SPI bus for some time.
//
//=============================================================================

`timescale 1 ns / 1 ps
`default_nettype none

module axis_spi_slave (
    // SPI
    //=====
    // SPI salve interface, 4-wire
    input  wire       SCK              ,
    input  wire       SS_N             ,
    input  wire       MOSI             ,
    output reg        MISO_Z           ,
    // AXIS
    //======
    input  wire       aclk             ,
    input  wire       aresetn          ,
    // RX
    output reg  [7:0] m_axis_tdata     ,
    output reg        m_axis_tvalid    ,
    input  wire       m_axis_tready    ,
    // TX
    input  wire [7:0] s_axis_tdata     ,
    input  wire       s_axis_tvalid    ,
    output reg        s_axis_tready    ,
    // Status
    //========
    // `stat_rx_overflow` - Indicate one new byte is received on SPI bus, but
    //     previous byte still stuck up at m_axis_* interface. So the newly
    //     received byte is not accepted, and thus be discarded by core.
    output reg        stat_rx_overflow ,
    // `stat_tx_underflow` - Indicate there is no byte on TX buffer, but core
    //     needs to start transaction of one byte. So a byte of zero will be
    //     send.
    output reg        stat_tx_underflow
);

    // Internal signals
    //=================

    // SPI Clock Domain
    //------------------

    reg [6:0] rx_shifter;
    reg [2:0] rx_cnt    ;
    reg       rx_dv     ;
    reg [7:0] rx_data   ;

    reg [7:0] tx_data;
    reg       tx_load_en;
    reg       tx_load;
    reg [2:0] tx_cnt ;
    reg       tx_underflow;

    (* ASYNC_REG="true" *)
    reg tx_cache_v_cdc, tx_cache_v_cdc_d;

    // AXI Clock Domain
    //------------------

    reg [7:0] tx_cache;
    reg tx_cache_v;

    (* ASYNC_REG="true" *)
    reg rx_dv_cdc, rx_dv_cdc_d;
    reg rx_dv_sync;

    (* ASYNC_REG="true" *)
    reg tx_load_cdc, tx_load_cdc_d;
    reg tx_load_sync;

    (* ASYNC_REG="true" *)
    reg tx_underflow_cdc, tx_underflow_cdc_d;
    reg tx_underflow_sync;

    wire rx_dv_rise, tx_load_rise, tx_underflow_rise;

    // MOSI -> rx_shifter
    //      -> rx_cnt
    //      -> rx_data                   ==> m_axis_tdata
    //      -> rx_dv       ==> rx_dv_cdc  -> rx_dv_d

    // MISO <- tx_data                    <== tx_cache
    //      <- tx_cnt
    //                    <== tx_cache_vd <-  tx_cache_v
    //         tx_load    -> tx_load_cdc  ->  tx_load_d

    // SPI Clock Domain
    //==================

    // RX
    //----

    // At falling edge of SCK, shift MOSI into LSB of rx_shifter
    // This assume MSB is transfered firstly by master.
    always_ff @ (negedge SCK) begin
        rx_shifter <= {rx_shifter[5:0], MOSI};
    end

    // Also, count how many bits we received.
    always_ff @ (posedge SS_N, negedge SCK) begin
        if (SS_N) begin
            rx_cnt <= 0;
        end else begin
            rx_cnt <= rx_cnt + 1;
        end
    end

    // If received 8-bit, rise valid flag at same time
    always_ff @ (posedge SS_N, negedge SCK) begin
        if (SS_N) begin
            rx_dv <= 1'b0;
        end else begin
            rx_dv <= (rx_cnt == 7);
        end
    end

    // Register 1 byte, let it be stable
    always_ff @ (negedge SCK) begin
        if (rx_cnt == 7) begin
            rx_data <= {rx_shifter, MOSI};
        end
    end

    // TX
    //----

    // Count how many rising edge we see
    always_ff @ (posedge SS_N or posedge SCK) begin
        if (SS_N) begin
            tx_cnt <= 4'd0;
        end else begin
            tx_cnt <= tx_cnt + 1;
        end
    end

    // When one byte is past, rise a flag
    always_ff @ (posedge SS_N, posedge SCK) begin : p_tx_load_en
        if (SS_N) begin
            tx_load_en <= 1'b0;
        end else begin
            tx_load_en <= (tx_cnt == 7);
        end
    end

    // tx_load = 1 means we already load one byte to tx_data
    always_ff @ (posedge SCK) begin
        tx_load <= (tx_load_en && tx_cache_v_cdc_d);
    end

    always_ff @ (posedge SS_N, posedge SCK) begin
        if (SS_N) begin
            tx_data <= 0;
        end else if (tx_load_en && tx_cache_v_cdc_d) begin
            tx_data <= tx_cache;
        end else if (tx_load_en) begin
            tx_data <= 8'h00;
        end else begin
            tx_data <= tx_data << 1;
        end
    end

    always_ff @ (posedge SCK) begin
        tx_underflow <= (tx_load_en && !tx_cache_v_cdc_d);
    end

    always_comb begin
        if (SS_N) begin
            MISO_Z = 1'bz;
        end else begin
            MISO_Z = tx_data[7];
        end
    end

    // CDC
    //=====

    // Apply max_delay constrains at path:
    //
    // rx_dv   -> rx_dv_cdc
    // rx_data -> m_axis_tdata
    //
    // tx_loaded -> tx_load_cdc

    // 4 taps delay line
    always_ff @ (posedge aclk) begin
        rx_dv_cdc    <= rx_dv;
        rx_dv_cdc_d  <= rx_dv_cdc;
        rx_dv_sync   <= rx_dv_cdc_d;
    end

    always_ff @ (posedge aclk) begin
        tx_load_cdc    <= tx_load;
        tx_load_cdc_d  <= tx_load_cdc;
        tx_load_sync   <= tx_load_cdc_d;
    end

    always_ff @ (posedge aclk) begin
        tx_underflow_cdc   <= tx_underflow;
        tx_underflow_cdc_d <= tx_underflow_cdc;
        tx_underflow_sync  <= tx_underflow_cdc_d;
    end

    always_ff @ (posedge SCK) begin
        tx_cache_v_cdc   <= tx_cache_v;
        tx_cache_v_cdc_d <= tx_cache_v_cdc;
    end


    assign rx_dv_rise = {rx_dv_cdc_d, rx_dv_sync} == 2'b10;

    assign tx_load_rise = {tx_load_cdc_d, tx_load_sync} == 2'b10;

    assign tx_underflow_rise = {tx_underflow_cdc_d, tx_underflow_sync} == 2'b10;

    // AXI Clock Domain
    //=================

    // AXIS Master
    //------------

    // We already captured 1 byte data, try move it to axis i/f, if previous
    // data is still stuck there (m_axis_tvalid && !m_axis_tready), discard
    // the new data.
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axis_tdata <= 'b0;
        end else if (rx_dv_rise && (!m_axis_tvalid || m_axis_tready)) begin
            m_axis_tdata <= rx_data;
        end
    end

    // When 1 byte is moved to axis i/f, assert valid at same time
    always_ff @ (posedge aclk) begin : p_m_axis_tvalid
        if (~aresetn)
            m_axis_tvalid <= 1'b0;
        else if (rx_dv_rise) begin
            m_axis_tvalid <= 1'b1;
        end else if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tvalid <= 1'b0;
        end
    end


    // AXIS Slave
    //-----------

    always_ff @ (posedge aclk) begin : p_tx_cache
        if (s_axis_tready && s_axis_tvalid) begin
            tx_cache <= s_axis_tdata;
        end
    end

    always_ff @ (posedge aclk) begin : p_tx_cache_v
        if (!aresetn) begin
            tx_cache_v <= 1'b0;
        end else if (s_axis_tready && s_axis_tvalid) begin
            tx_cache_v <= 1'b1;
        end else if (tx_load_rise) begin
            tx_cache_v <= 1'b0;
        end
    end

    always_ff @ (posedge aclk) begin : p_s_axis_tready
        if (~aresetn) begin
            s_axis_tready <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            s_axis_tready <= 1'b0;
        end else if (tx_load_rise) begin
            s_axis_tready <= 1'b1;
        end else begin
            s_axis_tready <= !tx_cache_v;
        end
    end

    // Status
    //========

    always_ff @ (posedge aclk) begin : p_stat_rx_overflow
        if (!aresetn) begin
            stat_rx_overflow <= 1'b0;
        end else begin
            stat_rx_overflow <= (rx_dv_rise && m_axis_tvalid);
        end
    end

    always_ff @ (posedge aclk) begin : p_stat_tx_underflow
        if (!aresetn) begin
            stat_tx_underflow <= 1'b0;
        end else begin
            stat_tx_underflow <= tx_underflow_rise;
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

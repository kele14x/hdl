/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axis_spi_master_top #(
    parameter CLK_RATIO   = 8, // Number of clock ticks per one SCK period
    parameter PRE_PERIOD  = 4, // Number of clock ticks after SS goes low and first MISO/MOSI bit
    parameter POST_PERIOD = 4  // Number of clock ticks after last MISO/MISO bit and before SS goes high
)(
    // SPI
    //=====
    input  var logic       SCK_I       ,
    output var logic       SCK_O       ,
    output var logic       SCK_T       ,
    input  var logic       SS_I        ,
    output var logic       SS_O        ,
    output var logic       SS_T        ,
    input  var logic       IO0_I       ,
    output var logic       IO0_O       , // MO
    output var logic       IO0_T       ,
    input  var logic       IO1_I       , // MI
    output var logic       IO1_O       ,
    output var logic       IO1_T       ,
    // Fabric
    //=======
    input  var logic       aclk        ,
    input  var logic       aresetn     ,
    // Tx interface
    //--------------
    input  var logic [7:0] s_axis_tdata ,
    input  var logic       s_axis_tvalid,
    output var logic       s_axis_tready,
    // Rx interface
    //--------------
    output var logic [7:0] m_axis_tdata ,
    output var logic       m_axis_tvalid,
    input  var logic       m_axis_tready
);


    // Parameter Check
    //------------------

    initial begin
        assert (CLK_RATIO / 2 == 0 && CLK_RATIO >= 2)
            else $error("CLK_RATIO must be an positive even number.");
    end

    localparam C_STATE_MAX   = CLK_RATIO / 2 * 17;

    localparam C_STATE_WIDTH = $clog2(C_STATE_MAX);


    // Variables
    //-----------

    var logic SCK, SS, MOSI, MISO;

    typedef enum {S_RST, S_IDLE, S_PRE, S_SCK0, S_SCK1, S_LOAD, S_POST} STATE_T;

    STATE_T state, state_next;

    var logic [C_STATE_WIDTH-1:0] tick_cnt;
    var logic [3:0] bit_cnt;

    var logic [7:0] tx_buffer;

    var logic [6:0] rx_buffer;

    // SPI Interface
    //---------------

    assign SCK_T = SS;
    assign SCK_O = SCK;

    assign SS_T = 0;
    assign SS_O = SS;

    assign IO0_T = SS;
    assign IO0_O = MOSI;

    assign IO1_T = 1;
    assign IO1_O = 0;
    assign MISO = IO1_I;


    // TX State Machine
    //==================

    // `stat_cnt` state machine
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            state <= S_RST;
        end else begin
            state <= state_next;
        end
    end

    // next state combination
    // TODO: make S_LOAD at last tick of S_SCK1
    always_comb begin
        case(state)
            S_RST   : state_next =                                S_IDLE;
            S_IDLE  : state_next = !s_axis_tvalid               ? S_IDLE :
                                   (PRE_PERIOD == 0)            ? S_SCK0 : S_PRE;
            S_PRE   : state_next = !(tick_cnt == PRE_PERIOD-1)  ? S_PRE  : S_SCK0;
            S_SCK0  : state_next = !(tick_cnt == CLK_RATIO/2-1) ? S_SCK0 : S_SCK1;
            S_SCK1  : state_next = !(tick_cnt == CLK_RATIO/2-1) ? S_SCK1 :
                                   !(bit_cnt == 8)              ? S_SCK0 : S_LOAD;
            S_LOAD  : state_next = s_axis_tvalid                ? S_SCK0 :
                                   (POST_PERIOD == 0)           ? S_IDLE : S_POST;
            S_POST  : state_next = !(tick_cnt == POST_PERIOD-1) ? S_POST : S_IDLE;
            default : state_next = S_IDLE;
        endcase // state
    end

    // tick_cnt
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            tick_cnt <= 0;
        end else if ((state_next == S_PRE || state_next == S_SCK0 || state_next == S_SCK1 || state_next == S_POST) && state != state_next) begin
            // When newly switch to S_PRE, S_SCK0, S_SCK1, S_POST
            tick_cnt <= 0;
        end else if (state_next == S_PRE || state_next == S_SCK0 || state_next == S_SCK1 || state_next == S_POST) begin
            // When we stay at S_PRE, S_SCK0, S_SCK1, S_POST
            tick_cnt <= tick_cnt + 1;
        end else begin
            tick_cnt <= 0;
        end
    end

    // bit_cnt
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            bit_cnt <= 0;
        end else if (state_next == S_SCK0 && state != S_SCK0) begin
            // When newly switch to S_SCK0
            bit_cnt <= bit_cnt + 1;
        end else if (state_next == S_SCK0 || state_next == S_SCK1) begin
            // When stay at S_SCK0, S_SCK1
            bit_cnt <= bit_cnt;
        end else begin
            bit_cnt <= 0;
        end
    end



    // TX Interface
    //==============

    // assert `spi_tx_ready` at the same time with S_IDLE and S_LOAD
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axis_tready <= 1'b0;
        end else begin
            s_axis_tready <= (state_next == S_IDLE || state_next == S_LOAD);
        end
    end

    // When there is a valid transfer on tx interface, move the data into tx_data
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            tx_buffer <= 0;
        end else if ((state == S_IDLE || state == S_LOAD) && s_axis_tvalid) begin
            tx_buffer <= s_axis_tdata;
        end else if (state_next == S_SCK0 && state == S_SCK1) begin
            tx_buffer <= {tx_buffer[6:0], 1'b0};
        end else if (state_next == S_SCK0 || state_next == S_SCK1 || state_next == S_LOAD || state_next == S_PRE) begin
            tx_buffer <= tx_buffer;
        end else begin
            tx_buffer <= 0;
        end
    end


    // RX Interface
    //==============

    wire s_rxv;

    assign s_rxv = (state_next == S_SCK1 && state == S_SCK0 && bit_cnt == 8);

    always_ff @ (posedge aclk) begin
        if (state_next == S_SCK1 && state == S_SCK0) begin
            // falling edge of SCK
            rx_buffer <= {rx_buffer[5:0], MISO};
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axis_tvalid <= 1'b0;
        end else if (s_rxv) begin
            m_axis_tvalid <= 1'b1;
        end else if (m_axis_tready) begin
            m_axis_tvalid <= 1'b0;
        end else begin
            m_axis_tvalid <= m_axis_tvalid;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axis_tdata <= 'd0;
        end else if (s_rxv && !(m_axis_tvalid && !m_axis_tready)) begin
            m_axis_tdata <= {rx_buffer, MISO};
        end
    end


    // SPI SS & SCK
    //==============

    assign SS = !(state == S_PRE || state == S_SCK0 || state == S_SCK0 || 
        state == S_SCK1 || state == S_LOAD || state == S_POST);

    assign SCK = (state == S_SCK0);

    assign MOSI = tx_buffer[7];

endmodule

`default_nettype wire

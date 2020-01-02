/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

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

module spi_master #(parameter CLK_RATIO   = 8) (
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
    input  var logic       clk         ,
    input  var logic       rst         ,
    // AXIS TX Data
    //-------------
    input  var logic [7:0] spi_tx_data ,
    input  var logic       spi_tx_valid,
    output var logic       spi_tx_ready,
    // AXIS RX Data
    //-------------
    output var logic [7:0] spi_rx_data ,
    output var logic       spi_rx_valid
);

    initial begin
        assert (CLK_RATIO / 2 == 0 && CLK_RATIO >= 2)
            else $error("CLK_RATIO must be an positive even number.");
    end

    var logic SCK, SS, MOSI;
    var logic MISO;

    assign SCK_T = 0;
    assign SCK_O = SCK;

    assign SS_T = 0;
    assign SS_O = SS;

    assign IO0_T = SS;
    assign IO0_O = MOSI;

    assign IO1_T = 1;
    assign IO1_O = 0;
    assign MISO = IO1_I;

    // SCK edge generator
    //===================

    var logic [$clog2(CLK_RATIO)-1:0] edge_counter = 0;
    var logic                         rising_edge, falling_edge;


    // edge_counter runs freely
    always_ff @ (posedge clk) begin : p_edge_counter
        if (rst) begin
            edge_counter <= 0;
        end else begin
            edge_counter <= (edge_counter == CLK_RATIO - 1) ? 0 : edge_counter + 1;
        end
    end

    always_ff @ (posedge clk) begin
        rising_edge  <= edge_counter == 0;
        falling_edge <= edge_counter == CLK_RATIO / 2;
    end


    // TX State Machine
    //==================

    typedef enum {S_RST, S_SYNC, S_IDLE, S_PRE, S_BITX, S_LOAD} STATE_T;
    STATE_T state_next, state;

    var logic [3:0] state_cnt;

    // `stat_cnt` state machine
    always_ff @ (posedge clk) begin : p_state
        if (rst) begin
            state <= S_RST;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin : c_state_next
        case(state)
            S_RST  : state_next = S_IDLE;
            S_IDLE : state_next = !spi_tx_valid? S_IDLE :         // Wait for tx data at axis i/f
                                  !falling_edge ? S_SYNC : S_PRE;  // if at falling edge, skip S_SYNC stage
            S_SYNC : state_next = !falling_edge ? S_SYNC : S_PRE;
            S_PRE  : state_next = !rising_edge  ? S_PRE  : S_BITX;
            S_BITX : state_next = !rising_edge  ? S_BITX :
                                  (state_cnt != 15) ? S_BITX : S_LOAD;    // This is not last bit of a byte
            S_LOAD : state_next = spi_tx_valid   ? S_BITX : S_IDLE; // When last bit is send, see if we have more byte
            default: state_next = S_RST;
        endcase
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            state_cnt <= 0;
        end else if (state == S_BITX && (rising_edge || falling_edge)) begin
            state_cnt <= state_cnt + 1;
        end else if (state == S_BITX) begin
            state_cnt <= state_cnt;
        end else begin // other states
            state_cnt <= 0;
        end
    end


    // TX Interface
    //==============

    // rising_edge -> rising_edge_d -> MOSI
    // state_next  -> state         ->

    var logic [7:0] tx_buffer;
    var logic rising_edge_d;

    always_ff @ (posedge clk) begin
        rising_edge_d <= rising_edge;
    end

    // spi_tx_ready combine
    always_ff @ (posedge clk) begin
        if (rst) begin
            spi_tx_ready <= 1'b0;
        end else begin
            spi_tx_ready <= (state_next == S_IDLE || state_next == S_LOAD);
        end
    end

    // When there is a valid transfer on tx interface, move the data into tx_data
    always_ff @ (posedge clk) begin
        if ((state == S_IDLE) && spi_tx_valid) begin
            {MOSI, tx_buffer} <= {1'b0, spi_tx_data};
        end else if (state == S_LOAD && spi_tx_valid) begin
            {MOSI, tx_buffer} <= {spi_tx_data, 1'b0};
        end else if (rising_edge_d) begin
            {MOSI, tx_buffer}  <= {tx_buffer, 1'b0};
        end
    end


    // RX Interface
    //==============

    var logic [6:0] rx_buffer;
    var logic falling_edge_d;

    always_ff @ (posedge clk) begin
        falling_edge_d <= falling_edge;
    end

    always_ff @ (posedge clk) begin
        if (falling_edge_d) begin
            rx_buffer <= {rx_buffer[5:0], MISO};
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            spi_rx_valid <= 1'b0;
        end else begin
            spi_rx_valid <= (falling_edge_d && (state_cnt == 15));
        end
    end

    always_ff @ (posedge clk) begin
        if (falling_edge_d && (state_cnt == 15)) begin
            spi_rx_data <= {rx_buffer, MISO};
        end
    end


    // SPI SS & SCK
    //==============

    always_ff @ (posedge clk) begin
        SS <= !(state == S_BITX || state == S_PRE);
    end

    always_ff @ (posedge clk) begin
        SCK <= !state_cnt[0] && state == S_BITX;
    end

endmodule

`default_nettype wire

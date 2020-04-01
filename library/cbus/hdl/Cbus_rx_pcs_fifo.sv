/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_rx_pcs_fifo (
      input  wire        wr_clk  ,
      input  wire        wr_rst  ,
      input  wire [10:0] wr_din  ,
      input  wire        wr_en   ,
      //
      input  wire        rd_clk  ,
      output wire [10:0] rd_dout ,
      output wire        rd_valid
);

      wire overflow;

      xpm_fifo_async #(
            .CDC_SYNC_STAGES    (2       ), // DECIMAL
            .DOUT_RESET_VALUE   ("0"     ), // String
            .ECC_MODE           ("no_ecc"), // String
            .FIFO_MEMORY_TYPE   ("auto"  ), // String
            .FIFO_READ_LATENCY  (0       ), // DECIMAL
            .FIFO_WRITE_DEPTH   (16      ), // DECIMAL
            .FULL_RESET_VALUE   (0       ), // DECIMAL
            .PROG_EMPTY_THRESH  (10      ), // DECIMAL
            .PROG_FULL_THRESH   (10      ), // DECIMAL
            .RD_DATA_COUNT_WIDTH(5       ), // DECIMAL
            .READ_DATA_WIDTH    (11      ), // DECIMAL
            .READ_MODE          ("fwft"  ), // String
            .RELATED_CLOCKS     (0       ), // DECIMAL
            .SIM_ASSERT_CHK     (0       ), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
            .USE_ADV_FEATURES   ("1001"  ), // String
            .WAKEUP_TIME        (0       ), // DECIMAL
            .WR_DATA_COUNT_WIDTH(5       ), // DECIMAL
            .WRITE_DATA_WIDTH   (11      )  // DECIMAL
      ) xpm_fifo_async_inst (
            // Write Domain
            .almost_full  (        ),
            .din          (wr_din  ),
            .full         (        ),
            .injectdbiterr(1'b0    ),
            .injectsbiterr(1'b0    ),
            .overflow     (overflow),
            .prog_full    (        ),
            .rst          (wr_rst  ),
            .wr_ack       (        ),
            .wr_clk       (wr_clk  ),
            .wr_data_count(        ),
            .wr_en        (wr_en   ),
            .wr_rst_busy  (        ),

            // Read Domain
            .almost_empty (        ),
            .data_valid   (rd_valid),
            .dbiterr      (        ),
            .dout         (rd_dout ),
            .empty        (        ),
            .prog_empty   (        ),
            .rd_clk       (rd_clk  ),
            .rd_data_count(        ),
            .rd_en        (1'b1    ),
            .rd_rst_busy  (        ),
            .sbiterr      (        ),
            .underflow    (        ),
            // NA
            .sleep        (1'b0    )
      );

endmodule

`default_nettype none
//
`timescale 1 ns / 1 ps

module bit_reverse #(
    parameter NUM_INLV     = 4,
    parameter LOG_FFT_SIZE = 11,
    parameter DATA_WIDTH   = 16
) (
    input var                                               clk,
    input var                                               rst,
    // Data input
    input var  [                            DATA_WIDTH-1:0] din_dr,
    input var  [                            DATA_WIDTH-1:0] din_di,
    input var  [(NUM_INLV <= 1 ? 1 : $clog2(NUM_INLV))-1:0] din_id,
    input var                                               din_valid,
    input var                                               din_last,
    // Data output
    output var [                            DATA_WIDTH-1:0] dout_dr,
    output var [                            DATA_WIDTH-1:0] dout_di,
    output var [(NUM_INLV <= 1 ? 1 : $clog2(NUM_INLV))-1:0] dout_id,
    output var                                              dout_valid,
    output var                                              dout_last
);

  localparam int NumStage = LOG_FFT_SIZE / 2;

  localparam int IdWidth = NUM_INLV <= 1 ? 1 : $clog2(NUM_INLV);

  wire [DATA_WIDTH-1:0] data_dr_s   [0:NumStage];
  wire [DATA_WIDTH-1:0] data_di_s   [0:NumStage];
  wire [   IdWidth-1:0] data_id_s   [0:NumStage];
  wire                  data_valid_s[0:NumStage];
  wire                  data_last_s [0:NumStage];

  // Main

  // Connect input and output

  assign data_dr_s[0]    = din_dr;
  assign data_di_s[0]    = din_di;
  assign data_id_s[0]    = din_id;
  assign data_valid_s[0] = din_valid;
  assign data_last_s[0]  = din_last;

  assign dout_dr         = data_dr_s[NumStage];
  assign dout_di         = data_di_s[NumStage];
  assign dout_id         = data_id_s[NumStage];
  assign dout_valid      = data_valid_s[NumStage];
  assign dout_last       = data_last_s[NumStage];

  // Loop generate every stage

  generate
    genvar i;
    for (i = 0; i <= NumStage - 1; i = i + 1) begin : g_stage

      bit_reverse_stage #(
          .NUM_INLV    (NUM_INLV),
          .IDX_STAGE   (i),
          .LOG_FFT_SIZE(LOG_FFT_SIZE),
          .DATA_WIDTH  (DATA_WIDTH)
      ) i_stage (
          .clk       (clk),
          .rst       (rst),
          // Data input
          .din_dr    (data_dr_s[i]),
          .din_di    (data_di_s[i]),
          .din_id    (data_id_s[i]),
          .din_valid (data_valid_s[i]),
          .din_last  (data_last_s[i]),
          // Data output
          .dout_dr   (data_dr_s[i+1]),
          .dout_di   (data_di_s[i+1]),
          .dout_id   (data_id_s[i+1]),
          .dout_valid(data_valid_s[i+1]),
          .dout_last (data_last_s[i+1])
      );

    end
  endgenerate

endmodule

`default_nettype wire

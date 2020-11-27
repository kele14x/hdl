`timescale 1ns / 1ps

module cordiccart2pol #(
    parameter DATA_WIDTH = 16,
    parameter ITERATIONS = 7
) (
    input  logic                  clk  ,
    input  logic                  rst  ,
    //
    input  logic [DATA_WIDTH-1:0] xin  ,
    input  logic [DATA_WIDTH-1:0] yin  ,
    //
    output logic [ITERATIONS+1:0] theta,
    output logic [  DATA_WIDTH:0] r
);


    logic signed [  DATA_WIDTH:0] x[  0:ITERATIONS];
    logic signed [DATA_WIDTH-1:0] y[  0:ITERATIONS];
    logic        [ITERATIONS+1:0] z[  0:ITERATIONS];
    logic                         d[0:ITERATIONS-1];

    // Iteration Initialization
    assign x[0] = {xin[DATA_WIDTH-1], xin};
    assign y[0] = yin;
    assign z[0] = {{ITERATIONS{1'b0}}, y[0][DATA_WIDTH-1], x[0][DATA_WIDTH]};

    // Pseudo Rotation
    generate
        for (genvar i = 0; i < ITERATIONS; i++) begin : g_pseudo_rotation

            // Rotation direction, 0 = clockwise, 1 = counterclockwise
            assign d[i] = y[i][DATA_WIDTH-1]^x[i][DATA_WIDTH];

            always_ff @ (posedge clk) begin
                x[i+1] <= x[i] - (d[i] ? (y[i] >>> i) : (-y[i] >>> i));
                y[i+1] <= y[i] + (d[i] ? (x[i] >>> i) : (-x[i] >>> i));
                z[i+1] <= {z[i], ~d[i]};
            end

        end
    endgenerate

    always_ff @ (posedge clk) begin
        r     <= z[ITERATIONS][ITERATIONS] ? -x[ITERATIONS] : x[ITERATIONS];
        theta <= z[ITERATIONS];
    end

endmodule

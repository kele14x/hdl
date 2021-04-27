`timescale 1 ns / 1 ps `default_nettype none

module tb_ul_adaptor_gearbox_bfp9 ();

  parameter int NUM_CC = 2;

  logic        clk;
  logic        rst;
  //
  logic        ul_radio_start_10ms = 0;
  logic        ul_update           [NUM_CC] = '{NUM_CC{1'b0}};
  // AXIS
  logic [63:0] m_axis_tdata;
  logic [ 7:0] m_axis_tkeep;
  logic        m_axis_tvalid;
  logic        m_axis_tlast;
  logic        m_axis_tready = 1;
  // FIFO
  logic [23:0] fram_req_data = 0;
  logic        fram_req_empty = 1;
  logic        fram_req_rden;
  // URAM
  logic        uram_bank           [NUM_CC];
  logic [11:0] uram_addr           [NUM_CC];
  logic        uram_rden           [NUM_CC];
  logic [63:0] uram_data           [NUM_CC] = '{NUM_CC{'0}};

  logic [63:0] uram_data_r         [NUM_CC] = '{NUM_CC{'0}};
  logic [63:0] uram_data_rr        [NUM_CC] = '{NUM_CC{'0}};

  ul_adaptor_gearbox_bfp9 #(.NUM_CC(NUM_CC)) UUT (.*);

  logic [63:0] URAM [NUM_CC][4096];
  
  initial begin: init_uram
    logic [2:0] exp;
    logic [8:0] mantissa;
    for (int cc = 0; cc < NUM_CC; cc++) begin
      for (int addr = 0; addr < 4096; addr++) begin
        exp = $urandom();
        for (int i = 0; i < 4; i++) begin
          mantissa = $urandom();
          URAM[cc][addr][i*16+15-:16] = (mantissa << exp);
        end
      end
    end
  end

  generate 
    for (genvar i = 0; i < NUM_CC; i++) begin: g_uram

      always_ff @ (posedge clk) begin
        if (rst) begin
          uram_data_r[i] <= '0;
        end else if (uram_rden[i]) begin
          uram_data_r[i] <= URAM[i][uram_addr[i]];
        end else begin
          uram_data_r[i] <= '0;
        end
      end

      always_ff @ (posedge clk) begin
        uram_data_rr[i] <= uram_data_r[i];
        uram_data[i] <= uram_data_rr[i];
      end

    end
  endgenerate

  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst = 0;
  end

  initial begin
    wait(rst == 0);
    #100;

    // Set 10 ms start for 1 tick
    @(posedge clk);
    ul_radio_start_10ms = 1;
    ul_update[0] = 1;
    @(posedge clk);
    ul_radio_start_10ms = 0;
    ul_update[0] = 0;
    #20;

    // Set 
    @(posedge clk);
    ul_update[1] = 1;
    @(posedge clk);
    ul_update[1] = 0;
    #100;

    // Set fram_req
    @(posedge clk);
    fram_req_data <= {9'd0, 8'd119, 3'd1, 4'd0};
    fram_req_empty <= 1'b0;
    // Wait it be accepted
    forever begin
      @(posedge clk);
      if (fram_req_rden) break;
    end
    fram_req_empty <= 1'b1;
    #10000;
    $finish();
  end

endmodule

`default_nettype wire

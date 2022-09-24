// File: tb_fifo_srl.sv
// Brief: Testbench for module fifo_srl
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_fifo_srl;

  // Parameters

  parameter int FIFO_DEPTH = 16;
  parameter int DATA_WIDTH = 16;


  // Signals

  bit clk;
  bit rst;

  bit wren;
  bit [DATA_WIDTH-1:0] din;
  bit full;

  bit rden;
  bit [DATA_WIDTH-1:0] dout;
  bit empty;

  mailbox #(bit [DATA_WIDTH-1:0]) wr_queue = new;
  mailbox #(bit [DATA_WIDTH-1:0]) rd_queue = new;

  // Driver

  task automatic write_fifo();
    forever begin
      bit [DATA_WIDTH-1:0] data;
      int pause;

      // Generate random transaction
      std::randomize(data);
      assert (std::randomize(pause) with { pause >=0; pause < 3; });

      // Wait for pause ticks
      repeat (pause) @(posedge clk);

      // Put data on line
      din  <= data;
      wren <= 1'b1;

      // Wait DUT accept it
      @(posedge clk);
      while (full) begin
        @(posedge clk);
      end
      wren <= 1'b0;
    end
  endtask

  task automatic read_fifo();
    forever begin
      int pause;

      // Generate random transaction
      assert (std::randomize(pause) with { pause >=0; pause < 3; });

      // Wait for pause ticks
      repeat (pause) @(posedge clk);

      // Put data on line
      rden <= 1'b1;

      // Wait DUT accept it
      @(posedge clk);
      while (empty) begin
        @(posedge clk);
      end
      rden <= 1'b0;
    end
  endtask


  // Monitors

  task automatic input_monitor();
    forever begin
      @(posedge clk);
      if (wren && !full) begin
        wr_queue.put(din);
      end
    end
  endtask

  task automatic output_monitor();
    forever begin
      @(posedge clk);
      if (rden && !empty) begin
        wr_queue.put(dout);
      end
    end
  endtask

  // Scoreboard

  task automatic scoreboard();
    forever begin
      bit [DATA_WIDTH-1:0] wr_data;
      bit [DATA_WIDTH-1:0] rd_data;
      wr_queue.get(wr_data);
      rd_queue.get(rd_data);
      assert (wr_data == rd_data);
    end
  endtask


  // Stimulation
  //============

  always #5 clk = ~clk;

  initial begin
    rst = 1;
    @(posedge clk);
    repeat (16) @(posedge clk);
    rst <= 0;

    fork
      begin
        write_fifo();
      end
      begin
        read_fifo();
      end
      begin
        input_monitor();
      end
      begin
        output_monitor();
      end
      begin
        scoreboard();
      end
      begin
        #10000;
      end
    join_any

    #100;
    $finish;
  end


  // UUT
  //====

  fifo_srl #(
      .FIFO_DEPTH(FIFO_DEPTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) DUT (
      .clk  (clk),
      .rst  (rst),
      //
      .wren (wren),
      .din  (din),
      .full (full),
      //
      .rden (rden),
      .dout (dout),
      .empty(empty)
  );

endmodule

`default_nettype wire

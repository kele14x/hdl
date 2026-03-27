`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_axis_reg;

  // Parameters
  localparam int DATA_WIDTH = 8;
  localparam int USER_WIDTH = 1;

  // Signals
  logic                    aclk = 0;
  logic                    aresetn = 0;

  logic [  DATA_WIDTH-1:0] s_axis_tdata;
  logic [DATA_WIDTH/8-1:0] s_axis_tkeep;
  logic                    s_axis_tlast;
  logic [  USER_WIDTH-1:0] s_axis_tuser;
  logic                    s_axis_tvalid;
  logic                    s_axis_tready;

  logic [  DATA_WIDTH-1:0] m_axis_tdata;
  logic [DATA_WIDTH/8-1:0] m_axis_tkeep;
  logic                    m_axis_tlast;
  logic [  USER_WIDTH-1:0] m_axis_tuser;
  logic                    m_axis_tvalid;
  logic                    m_axis_tready;

  logic [  DATA_WIDTH-1:0] input_queue   [$];
  logic [  DATA_WIDTH-1:0] output_queue  [$];

  event done;

  // Clock generation
  initial begin
    aclk = 0;
    forever begin
      #5 aclk = ~aclk;
    end
  end

  initial begin
    aresetn = 0;
    repeat (10) @(posedge aclk);
    aresetn <= 1;
  end

  // DUT
  axis_reg #(
      .DATA_WIDTH(DATA_WIDTH),
      .USER_WIDTH(USER_WIDTH)
  ) dut (
      .*
  );

  // Test stimulus

  // Input driver
  initial begin
    // Initialize signals
    s_axis_tdata  = 0;
    s_axis_tkeep  = 0;
    s_axis_tlast  = 0;
    s_axis_tuser  = 0;
    s_axis_tvalid = 0;
    wait (aresetn);

    forever begin
      @(posedge aclk);
      s_axis_tdata  <= $urandom_range(0, 2 ** DATA_WIDTH - 1);
      s_axis_tkeep  <= $urandom_range(0, 2 ** (DATA_WIDTH / 8) - 1);
      s_axis_tlast  <= $urandom_range(0, 1);
      s_axis_tuser  <= $urandom_range(0, 2 ** USER_WIDTH - 1);
      s_axis_tvalid <= $urandom_range(0, 1);
    end
  end

  // Output driver
  initial begin
    m_axis_tready = 0;
    wait (aresetn);

    forever begin
      @(posedge aclk);
      m_axis_tready <= $urandom_range(0, 1);
    end
  end

  // Input monitor
  initial begin
    wait (aresetn);

    forever begin
      @(posedge aclk);
      if (s_axis_tvalid && s_axis_tready) begin
        input_queue.push_back(s_axis_tdata);
      end
    end
  end

  // Output monitor
  initial begin
    wait (aresetn);

    forever begin
      @(posedge aclk);
      if (m_axis_tvalid && m_axis_tready) begin
        output_queue.push_back(m_axis_tdata);
      end
    end
  end

  // Checker
  initial begin
    logic [DATA_WIDTH-1:0] input_data;
    logic [DATA_WIDTH-1:0] output_data;
    wait (aresetn);

    forever begin
      @(posedge aclk);
      if (input_queue.size() > 0 && output_queue.size() > 0) begin
        input_data  = input_queue.pop_front();
        output_data = output_queue.pop_front();
        if (input_data !== output_data) begin
          $error("Data mismatch at time %t", $time);
          $display("Input: %h", input_data);
          $display("Output: %h", output_data);
          #1 $finish();
        end
      end
    end
  end

  // Test stimulus
  initial begin
    $display("*** Test started ***");
    #10000;
    $finish;
  end

  final begin
    $display("*** Test finished ***");
  end

endmodule

`default_nettype wire

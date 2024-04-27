`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_bfp_comp;

  parameter int TC = 100;

  // DUT signals

  logic        clk;
  logic        rst;

  logic [63:0] s_axis_tdata;
  logic [ 7:0] s_axis_tkeep;
  logic        s_axis_tvalid;
  logic        s_axis_tlast;
  logic [31:0] s_axis_tuser;

  logic [63:0] m_axis_tdata;
  logic [ 7:0] m_axis_tkeep;
  logic        m_axis_tvalid;
  logic        m_axis_tlast;
  logic [31:0] m_axis_tuser;

  logic [ 3:0] ctrl_ud_comp_meth = 1;
  logic [ 3:0] ctrl_ud_iq_width = 9;

  // Test signals

  int          error = 0;

  logic [63:0] test_in               [1024];
  logic [63:0] test_ref_out          [1024];


  //
  // Reset the AXIS Master interface
  //
  task static reset();
    s_axis_tdata  <= 0;
    s_axis_tkeep  <= 0;
    s_axis_tvalid <= 0;
    s_axis_tlast  <= 0;
    s_axis_tuser  <= 0;
  endtask

  //
  // Send a packet
  //
  task static send_packet(input int w);
    int gap;

    for (int i = 0; i < w; i++) begin
      s_axis_tdata  <= test_in[i];
      s_axis_tkeep  <= '1;
      s_axis_tvalid <= 1'b1;
      s_axis_tlast  <= i == w - 1;
      s_axis_tuser  <= '1;
      @(posedge clk);

      // Insert some bubble at data
      gap = $urandom_range(0, 2);
      repeat (gap) begin
        s_axis_tvalid <= 1'b0;
        @(posedge clk);
      end
    end
    // Reset interface
    reset();
  endtask

  initial begin
    $readmemh("test_bfp_comp_in.txt", test_in, 0, 306);
    $readmemh("test_bfp_comp_out.txt", test_ref_out, 0, 179);
  end


  // Main
  //-----

  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    #100;
    rst = 0;
  end

  initial begin
    static int n;
    $display("*** Simulation started");
    reset();
    wait (rst == 0);
    #100;

    @(posedge clk);

    case (TC)
      0: begin
        send_packet(6);
      end

      1: begin
        send_packet(12);
      end

      2: begin
        send_packet(51 * 6);
      end

      100: begin
        send_packet(7);
      end

      101: begin
        send_packet(4);
        send_packet(6);
      end

      200: begin
        repeat (10) begin
          n = $urandom_range(1, 5);
          $display("Send %d PRBs data", n);
          send_packet(n * 6);
        end
      end

      default: begin
        $fatal(0, "Unknown Test Case (TC = %d)", TC);
      end
    endcase

    #1000;
    if (error) $warning(0, "Test failed with %0d", error);
    $display("*** Simulation ends");
    $finish();
  end

  initial begin
    static int k = 0;
    wait (rst == 0);

    forever begin
      @(posedge clk);
      if (m_axis_tvalid) begin
        $display("%x, %x, %x", m_axis_tdata, m_axis_tkeep, test_ref_out[k]);
        // Check output
        for (int i = 0; i < 8; i++) begin
          if (m_axis_tkeep[i] && (m_axis_tdata[i*8+7-:8] != test_ref_out[k][i*8+7-:8])) begin
            $warning("Result mismatch");
            error = 1;
          end
        end
        k = m_axis_tlast ? 0 : k + 1;
      end
    end  // forever
  end

  bfp_comp DUT (.*);

endmodule

`default_nettype wire

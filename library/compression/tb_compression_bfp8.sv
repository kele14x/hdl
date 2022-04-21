// File: tb_compression_bfp8
// Brief: Test bench for module compression_bfp8
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_compression_bfp8 ();

  localparam TEST_LENGTH = 3275;

  logic        aclk;
  logic        aresetn;

  logic [63:0] s_axis_tdata;
  logic [ 7:0] s_axis_tkeep;
  logic        s_axis_tlast;
  logic        s_axis_tready;
  logic        s_axis_tvalid;

  logic [63:0] m_axis_tdata;
  logic [ 7:0] m_axis_tkeep;
  logic        m_axis_tlast;
  logic        m_axis_tready;
  logic        m_axis_tvalid;

  logic [15:0] data_i_mem [TEST_LENGTH];
  logic [15:0] data_q_mem [TEST_LENGTH];

  task static send_axis_packet(input int number_prb);
    begin
      // Sync with posedge of `aclk`
      @(posedge aclk);

      // Send `cnt` AXIS words
      for (int c = 0; c < number_prb * 6; c++) begin
        // TDATA
        s_axis_tdata[ 7: 0] <= data_i_mem[2*c+0][15:8];
        s_axis_tdata[15: 8] <= data_i_mem[2*c+0][ 7:0];
        s_axis_tdata[23:16] <= data_q_mem[2*c+0][15:8];
        s_axis_tdata[31:24] <= data_q_mem[2*c+0][ 7:0];
        s_axis_tdata[39:32] <= data_i_mem[2*c+1][15:8];
        s_axis_tdata[47:40] <= data_i_mem[2*c+1][ 7:0];
        s_axis_tdata[55:48] <= data_q_mem[2*c+1][15:8];
        s_axis_tdata[63:56] <= data_q_mem[2*c+1][ 7:0];
        // TKEEP
        s_axis_tkeep <= '1;
        // TLAST
        if (c == number_prb * 6 - 1) begin
          s_axis_tlast <= 1;
        end else begin
          s_axis_tlast <= 0;
        end
        // TVALID
        s_axis_tvalid <= 1;
        forever begin
          @(posedge aclk);
          // Check if previous word in accept by slave
          if (s_axis_tready) begin
            break;
          end
        end
      end

      // Reset interface
      s_axis_tdata  <= 0;
      s_axis_tkeep  <= 0;
      s_axis_tlast  <= 0;
      s_axis_tvalid <= 0;
    end
  endtask

  compression_bfp8 UUT (
      .aclk         (aclk),
      .aresetn      (aresetn),
      //
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tkeep (s_axis_tkeep),
      .s_axis_tlast (s_axis_tlast),
      .s_axis_tready(s_axis_tready),
      .s_axis_tvalid(s_axis_tvalid),
      //
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tkeep (m_axis_tkeep),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tready(m_axis_tready),
      .m_axis_tvalid(m_axis_tvalid)
  );

  initial begin
    aclk = 0;
    forever begin
      #5;
      aclk = ~aclk;
    end
  end

  initial begin
    aresetn = 0;
    #100;
    aresetn = 1;
  end

  initial begin
    $readmemh("test_compression_bfp8_data_i_in.txt", data_i_mem, 0, TEST_LENGTH-1);
    $readmemh("test_compression_bfp8_data_q_in.txt", data_q_mem, 0, TEST_LENGTH-1);
  end

  initial begin
    s_axis_tdata  = 0;
    s_axis_tkeep  = 0;
    s_axis_tlast  = 0;
    s_axis_tvalid = 0;
    //
    m_axis_tready = 1;
    wait (aresetn == 1);

    for (int i = 2; i <= 2; i++) begin
      send_axis_packet(i);
      #100;
    end

  end

endmodule  // tb_compression_bfp8

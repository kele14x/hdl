// File: tb_compression_bfp8
// Brief: Test bench for module compression_bfp8
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_compression_bfp8 ();

  localparam TEST_IN_LENGTH = 1638;
  localparam TEST_OUT_LENGTH = 854;

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
  logic        m_axis_tvalid;

  logic [63:0] data_in_mem [TEST_IN_LENGTH];
  logic [63:0] data_out_mem [TEST_OUT_LENGTH];

  task static send_axis_packet(input int number_prb);
    begin
      // Sync with posedge of `aclk`
      @(posedge aclk);

      // Send `cnt` AXIS words
      for (int c = 0; c < number_prb * 6; c++) begin
        // TDATA
        s_axis_tdata <= data_in_mem[c];
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

  task static check_axis_packet(input int nbytes);
    begin
      for (int w = 0; w < ((nbytes + 7) / 8); w++) begin
        // Only check valid data
        forever begin
          // Sync with posedge of `aclk`
          @(posedge aclk);
          if (m_axis_tvalid) break;
        end

        for (int i = 0; i < nbytes - 8 * w && i < 8; i++) begin
          assert (m_axis_tdata[i * 8 + 7 -: 8] == data_out_mem[w][i * 8 + 7 -: 8]) else begin
            $warning("%d: m_axis_tdata = %x, data_out_mem = %x", w, m_axis_tdata, data_out_mem[w]);
          end
          assert (m_axis_tkeep[i] == 1'b1) else begin
            $warning("%d: m_axis_tkeep = %x", w, m_axis_tkeep);
          end
        end
        
        for (int i = nbytes - 8 * w; i < 8; i++) begin
          assert (m_axis_tkeep[i] == 1'b0) else begin
            $warning("%d: m_axis_tkeep = %x", w, m_axis_tkeep);
          end
        end
        
        $display("%d: %x", w, m_axis_tdata);
      end
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
    $readmemh("test_compression_bfp8_data_in.txt", data_in_mem, 0, TEST_IN_LENGTH - 1);
    $readmemh("test_compression_bfp8_data_out.txt", data_out_mem, 0, TEST_OUT_LENGTH - 1);
  end

  initial begin
    s_axis_tdata  = 0;
    s_axis_tkeep  = 0;
    s_axis_tlast  = 0;
    s_axis_tvalid = 0;
    //
    wait (aresetn == 1);

    for (int i = 1; i <= 8; i++) begin
      fork
        begin
          send_axis_packet(i);
        end

        begin
          check_axis_packet(25*i);
        end
        
        #1000;
      join;
    end

    #1000;
    $finish();
  end

endmodule  // tb_compression_bfp8

`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_oran_deframer_dl_ss_decomp;

  import oran_pkg::*;

  logic        clk;
  logic        rst;

  logic [63:0] s_axis_tdata;
  logic [ 7:0] s_axis_tkeep;
  logic        s_axis_tvalid;
  logic        s_axis_tlast;
  logic        s_axis_tready;
  logic [39:0] s_axis_tuser;

  logic [63:0] m_axis_tdata;
  logic [ 7:0] m_axis_tkeep;
  logic        m_axis_tvalid;
  logic        m_axis_tlast;
  logic [31:0] m_axis_tuser;

  logic [ 3:0] ctrl_extra_shift = 0;

  logic        err_unexpected_tlast;


  //
  // This function performs BFP compress and pack the IQ data into byte stream
  //
  function automatic void bfp_comp(input int n, input bit signed [15:0] iqdata[24],
                              ref bit [7:0] bytes[]);
    bit signed [15:0] max;
    int msb;
    bit [7:0] exp;
    bit [7:0] temp[];

    // Find max
    max = 0;
    for (int i = 0; i < 24; i++) begin
      if ($signed(iqdata[i]) > max) max = iqdata[i];
      if ($signed(~iqdata[i]) > max) max = ~iqdata[i];
    end

    // Find MSB
    for (msb = 15; msb >= n; msb--) begin
      if (max[msb] ^ max[msb-1]) break;
    end

    // Exponent
    exp = msb - n + 1;

    // Compress and pack
    if (n == 6) begin
      bit [5:0] buffer[24];
      for (int i = 0; i < 24; i++) begin
        buffer[i] = iqdata[i] >> exp;
      end
      temp = {>>{buffer}};
    end else if (n == 7) begin
      bit [6:0] buffer[24];
      for (int i = 0; i < 24; i++) begin
        buffer[i] = iqdata[i] >> exp;
      end
      temp = {>>{buffer}};
    end else if (n == 8) begin
      bit [7:0] buffer[24];
      for (int i = 0; i < 24; i++) begin
        buffer[i] = iqdata[i] >> exp;
      end
      temp = {>>{buffer}};
    end else if (n == 9) begin
      bit [8:0] buffer[24];
      for (int i = 0; i < 24; i++) begin
        buffer[i] = iqdata[i] >> exp;
      end
      temp = {>>{buffer}};
    end else begin
      $error("Not supported");
      $finish;
    end
    bytes = {bytes, exp, temp};
  endfunction

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
  task static send_packet(input bit [3:0] udIqWidth, input bit [3:0] udIqCompMeth, input int nPRBu);
    int               nBytes;
    bit signed [15:0] iqdata [];
    bit        [ 7:0] buffer [];

    buffer = new[0];
    for (int i = 0; i < nPRBu; i++) begin
      iqdata = new[24];
      for (int i = 0; i < 12; i++) begin
        iqdata[2*i]   = 16'h7FFF;
        iqdata[2*i+1] = 16'h8000;
      end
      bfp_comp(udIqWidth, iqdata, buffer);
    end

    // Send packet
    nBytes = buffer.size();
    for (int i = 0; i < ((nBytes + 7) / 8); i++) begin
      for (int j = 0; j < 8; j++) begin
        if (i * 8 + j < nBytes) begin
          s_axis_tdata[j*8+7-:8] <= buffer[i*8+j];
          s_axis_tkeep[j] <= 1'b1;
        end else begin
          s_axis_tdata[j*8+7-:8] <= 8'd0;
          s_axis_tkeep[j] <= 1'b0;
        end
      end
      s_axis_tvalid <= 1'b1;
      s_axis_tlast  <= (i == ((nBytes + 7) / 8) - 1);
      s_axis_tuser  <= {udIqWidth, udIqCompMeth, 32'b0};
      // Wait data is accept
      forever begin
        @(posedge clk);
        if (s_axis_tready) begin
          break;
        end
      end
    end
    // Reset interface
    reset();
  endtask


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
    reset();
    wait (rst == 0);
    #100;

    @(posedge clk);
    send_packet(9, 1, 3);
    send_packet(9, 1, 2);
    #1000;
    $finish();
  end

  oran_deframer_dl_ss_decomp DUT (.*);

endmodule

`default_nettype wire

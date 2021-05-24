`timescale 1 ns / 1 ps `default_nettype none

module tb_srs_adaptor ();

  logic        clk_491m52;
  logic        rst_491m52;

  logic [23:0] srs_data = 0;
  logic        srs_eop = 0;
  logic        srs_valid = 0;

  logic [ 2:0] fram_req_eth_port = 0;
  logic [63:0] fram_header = 0;
  logic [ 8:0] fram_req_start_rb = 0;
  logic [ 7:0] fram_req_num_rb = 0;
  logic        fram_req_valid = 0;
  logic        fram_req_ready;

  logic        clk_400m;
  logic        rst_400m;

  logic [63:0] m_fram_unsol_tdata;
  logic [ 7:0] m_fram_unsol_tkeep;
  logic        m_fram_unsol_tvalid;
  logic        m_fram_unsol_tlast;
  logic        m_fram_unsol_tready = 1;
  logic [31:0] m_fram_unsol_tuser;

  srs_adaptor_gearbox UUT (.*);


  initial begin
    clk_400m = 0;
    forever begin
      #(1.25) clk_400m = ~clk_400m;
    end
  end

  initial begin
    clk_491m52 = 0;
    forever begin
      #(1.017) clk_491m52 = ~clk_491m52;
    end
  end

  initial begin
    rst_400m = 1;
    repeat (100) @(posedge clk_400m);
    rst_400m <= 0;
  end

  initial begin
    rst_491m52 = 1;
    repeat (100) @(posedge clk_491m52);
    rst_491m52 <= 0;
  end


  initial begin
    wait(rst_400m == 0);
    wait(rst_491m52 == 0);

    for (int i = 0; i < 3276; i++) begin
      @(posedge clk_491m52);
      srs_valid <= 1;
      srs_data  <= i % 12 == 0 ? 24'h0001FF : 0;
      srs_eop   <= i == 3275;
    end
    @(posedge clk_491m52);
    srs_valid <= 0;
    srs_eop   <= 0;
    srs_data  <= 0;

    #1000;
    @(posedge clk_400m);
    fram_req_eth_port <= 0;
    fram_header <= 64'hABCD1234DEADBEEF;
    fram_req_start_rb <= 0;
    fram_req_num_rb <= 136;
    fram_req_valid <= 1;
    forever begin
      @(posedge clk_400m);
      if (fram_req_ready) begin
        fram_req_valid <= 0;
        break;
      end
    end

    repeat (300) begin
      @(posedge clk_400m);
      m_fram_unsol_tready <= 1;
      @(posedge clk_400m);
      m_fram_unsol_tready <= 1;
      @(posedge clk_400m);
      m_fram_unsol_tready <= 1;
      @(posedge clk_400m);
      m_fram_unsol_tready <= 1;
    end

    #10000;
    $finish();
  end


endmodule

`default_nettype wire

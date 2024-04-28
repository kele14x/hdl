// File: tb_axi4l_int.v
// Brief: Test bench for module tb_axi4l_int.
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_axi4l_int;

  parameter int ADDR_WIDTH = 10;
  parameter int DATA_WIDTH = 32;

  parameter int NUM_WR_TRANS = 100;
  parameter int NUM_RD_TRANS = 100;

  logic                    s_axi_aclk;
  logic                    s_axi_aresetn;
  //
  logic [  ADDR_WIDTH-1:0] s_axi_awaddr;
  logic [             2:0] s_axi_awprot;
  logic                    s_axi_awvalid;
  logic                    s_axi_awready;
  //
  logic [  DATA_WIDTH-1:0] s_axi_wdata;
  logic [DATA_WIDTH/8-1:0] s_axi_wstrb;
  logic                    s_axi_wvalid;
  logic                    s_axi_wready;
  //
  logic [             1:0] s_axi_bresp;
  logic                    s_axi_bvalid;
  logic                    s_axi_bready;
  //
  logic [  ADDR_WIDTH-1:0] s_axi_araddr;
  logic [             2:0] s_axi_arprot;
  logic                    s_axi_arvalid;
  logic                    s_axi_arready;
  //
  logic [  DATA_WIDTH-1:0] s_axi_rdata;
  logic [             1:0] s_axi_rresp;
  logic                    s_axi_rvalid;
  logic                    s_axi_rready;
  //
  logic [  ADDR_WIDTH-1:0] int_addr;
  logic [  DATA_WIDTH-1:0] int_wr_data;
  logic [DATA_WIDTH/8-1:0] int_wr_strb;
  logic                    int_wr_en;
  logic                    int_rd_en;
  //
  logic                    int_wr_ack;
  logic                    int_wr_err;
  //
  logic                    int_rd_ack;
  logic                    int_rd_err;
  logic [  DATA_WIDTH-1:0] int_rd_data;

  typedef struct {
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] data;
    logic [1:0]            resp;
  } transaction_t;

  transaction_t axi_write_queue[$];
  transaction_t axi_read_queue [$];
  transaction_t int_write_queue[$];
  transaction_t int_read_queue [$];

  // Helpers

  task automatic axi_reset;
    begin
      s_axi_awaddr  <= 0;
      s_axi_awprot  <= 0;
      s_axi_awvalid <= 0;
      //
      s_axi_wdata   <= 0;
      s_axi_wstrb   <= 0;
      s_axi_wvalid  <= 0;
      //
      s_axi_bready  <= 0;
      //
      s_axi_araddr  <= 0;
      s_axi_arprot  <= 0;
      s_axi_arvalid <= 0;
      //
      s_axi_rready  <= 0;
    end
  endtask

  task automatic int_reset;
    begin
      int_wr_ack  <= 0;
      int_wr_err  <= 0;
      //
      int_rd_ack  <= 0;
      int_rd_err  <= 0;
      int_rd_data <= 0;
    end
  endtask

  task automatic dut_reset;
    begin
      s_axi_aresetn = 0;
      axi_reset();
      int_reset();
      repeat (16) @(posedge s_axi_aclk);
      s_axi_aresetn <= 1;
      repeat (16) @(posedge s_axi_aclk);
    end
  endtask

  // Driver helper

  task automatic axi_aw(input logic [ADDR_WIDTH-1:0] addr, input int d);
    begin
      repeat (d) @(posedge s_axi_aclk);
      s_axi_awaddr  <= addr;
      s_axi_awprot  <= 0;
      s_axi_awvalid <= 1;
      @(posedge s_axi_aclk);
      while (s_axi_awready == 0) begin
        @(posedge s_axi_aclk);
      end
      s_axi_awvalid <= 0;
    end
  endtask

  task automatic axi_w(input logic [31:0] data, input logic [3:0] strb, input int d);
    begin
      repeat (d) @(posedge s_axi_aclk);
      s_axi_wdata  <= data;
      s_axi_wstrb  <= strb;
      s_axi_wvalid <= 1;
      @(posedge s_axi_aclk);
      while (s_axi_wready == 0) begin
        @(posedge s_axi_aclk);
      end
      s_axi_wvalid <= 0;
    end
  endtask

  task automatic axi_b(output logic [1:0] resp, input int d);
    begin
      repeat (d) @(posedge s_axi_aclk);
      s_axi_bready <= 1;
      @(posedge s_axi_aclk);
      while (s_axi_bvalid == 0) begin
        @(posedge s_axi_aclk);
      end
      resp = s_axi_bresp;
      s_axi_bready <= 0;
    end
  endtask

  task automatic axi_ar(input logic [8:0] addr, input int d);
    begin
      repeat (d) @(posedge s_axi_aclk);
      s_axi_araddr  <= addr;
      s_axi_arprot  <= 0;
      s_axi_arvalid <= 1;
      @(posedge s_axi_aclk);
      while (s_axi_arready == 0) begin
        @(posedge s_axi_aclk);
      end
      s_axi_arvalid <= 0;
    end
  endtask

  task automatic axi_r(output logic [31:0] data, output logic [1:0] resp, input int d);
    begin
      repeat (d) @(posedge s_axi_aclk);
      s_axi_rready <= 1;
      @(posedge s_axi_aclk);
      while (s_axi_rvalid == 0) begin
        @(posedge s_axi_aclk);
      end
      data = s_axi_rdata;
      resp = s_axi_rresp;
      s_axi_rready <= 0;
    end
  endtask

  task automatic int_write(input logic err, output logic [ADDR_WIDTH-1:0] addr,
                           output logic [DATA_WIDTH-1:0] data, input int d);
    begin
      while (~int_wr_en) @(posedge s_axi_aclk);
      addr = int_addr;
      data = int_wr_data;
      repeat (d) @(posedge s_axi_aclk);
      int_wr_err <= err;
      int_wr_ack <= 1;
      @(posedge s_axi_aclk);
      int_wr_ack <= 0;
    end
  endtask

  task automatic int_read(input logic err, input logic [DATA_WIDTH-1:0] data,
                          output logic [ADDR_WIDTH-1:0] addr, input int d);
    begin
      while (~int_rd_en) @(posedge s_axi_aclk);
      addr = int_addr;
      repeat (d) @(posedge s_axi_aclk);
      int_rd_err  <= err;
      int_rd_data <= data;
      int_rd_ack  <= 1;
      @(posedge s_axi_aclk);
      int_rd_ack <= 0;
    end
  endtask

  // Drivers

  task automatic axi_driver(input int num_wr_transaction, input int num_rd_transaction);
    begin
      fork
        // AW channel
        begin
          logic [ADDR_WIDTH-1:0] addr;
          int                    d;
          repeat (num_wr_transaction) begin
            addr = $urandom();
            d = $urandom_range(0, 5);
            axi_aw(addr, d);
          end
        end

        // W channel
        begin
          logic [DATA_WIDTH-1:0] data;
          int                    d;
          repeat (num_wr_transaction) begin
            data = $urandom();
            d = $urandom_range(0, 5);
            axi_w(data, 4'hF, d);
          end
        end

        // B channel
        begin
          logic [1:0] resp;
          int         d;
          repeat (num_wr_transaction) begin
            d = $urandom_range(0, 10);
            axi_b(resp, d);
          end
        end

        // AR channel
        begin
          logic [ADDR_WIDTH-1:0] addr;
          int                    d;
          repeat (num_rd_transaction) begin
            addr = $urandom();
            d = $urandom_range(0, 5);
            axi_ar(addr, d);
          end
        end

        // R channel
        begin
          logic [DATA_WIDTH-1:0] data;
          logic [           1:0] resp;
          int                    d;
          repeat (num_rd_transaction) begin
            d = $urandom_range(0, 10);
            axi_r(data, resp, d);
          end
        end
      join
      $display("AXI Driver done");
    end
  endtask

  task automatic int_driver(input int num_wr_transaction, input int num_rd_transaction);
    fork
      // Response to write
      begin
        logic                  err;
        logic [ADDR_WIDTH-1:0] addr;
        logic [DATA_WIDTH-1:0] data;
        int                    d;

        repeat (num_wr_transaction) begin
          err = $urandom();
          d   = $urandom_range(0, 5);
          int_write(err, addr, data, d);
        end
      end

      // Response to read
      begin
        logic                  err;
        logic [ADDR_WIDTH-1:0] addr;
        logic [DATA_WIDTH-1:0] data;
        int                    d;

        repeat (num_rd_transaction) begin
          err = $urandom();
          data = $urandom();
          d = $urandom_range(0, 5);
          int_read(err, data, addr, d);
        end
      end
    join
    $display("Int Driver done");
  endtask

  // Monitor

  task automatic axi_monitor();
    logic         [ADDR_WIDTH-1:0] aw_queue[$];
    logic         [DATA_WIDTH-1:0] w_queue [$];
    logic         [           1:0] b_queue [$];

    logic         [ADDR_WIDTH-1:0] ar_queue[$];
    logic         [DATA_WIDTH+1:0] r_queue [$];

    logic         [ADDR_WIDTH-1:0] addr;
    logic         [DATA_WIDTH-1:0] data;
    logic         [           1:0] resp;

    transaction_t                  trans;

    forever begin
      // Monitor 5 AXI channels
      @(posedge s_axi_aclk);
      if (s_axi_awvalid && s_axi_awready) begin
        aw_queue.push_front(s_axi_awaddr);
      end
      if (s_axi_wvalid && s_axi_wready) begin
        w_queue.push_front(s_axi_wdata);
      end
      if (s_axi_bvalid && s_axi_bready) begin
        b_queue.push_front(s_axi_bresp);
      end
      if (s_axi_arvalid && s_axi_arready) begin
        ar_queue.push_front(s_axi_araddr);
      end
      if (s_axi_rvalid && s_axi_rready) begin
        r_queue.push_front({s_axi_rresp, s_axi_rdata});
      end

      // AXI write transaction
      if (aw_queue.size() > 0 && w_queue.size() > 0 && b_queue.size() > 0) begin
        addr  = aw_queue.pop_back();
        data  = w_queue.pop_back();
        resp  = b_queue.pop_back();
        // $display("[%t] AXI write transaction: addr = %x, data = %x, resp = %x", $realtime, addr,
        //          data, resp);
        trans = '{addr, data, resp};
        axi_write_queue.push_front(trans);
      end

      // AXI read transaction
      if (ar_queue.size() > 0 && r_queue.size() > 0) begin
        addr = ar_queue.pop_back();
        {resp, data} = r_queue.pop_back();
        // $display("[%t] AXI read transaction: addr = %x, data = %x, resp = %x", $realtime, addr,
        //          data, resp);
        trans = '{addr, data, resp};
        axi_read_queue.push_front(trans);
      end
    end  // forever
  endtask

  task automatic int_monitor();
    logic         [ADDR_WIDTH-1:0] wr_addr_queue          [$];
    logic         [DATA_WIDTH-1:0] wr_data_queue          [$];
    logic                          wr_err_queue           [$];

    logic         [ADDR_WIDTH-1:0] rd_addr_queue          [$];
    logic         [DATA_WIDTH-1:0] rd_data_queue          [$];
    logic                          rd_err_queue           [$];

    int                            num_wr_outstanding = 0;
    int                            num_rd_outstanding = 0;

    logic         [ADDR_WIDTH-1:0] addr;
    logic         [DATA_WIDTH-1:0] data;
    logic                          err;

    transaction_t                  trans;

    forever begin
      // Monitor interface signals
      @(posedge s_axi_aclk);
      if (int_wr_en) begin
        num_wr_outstanding++;
        wr_addr_queue.push_front(int_addr);
        wr_data_queue.push_front(int_wr_data);
      end
      if (int_wr_ack && num_wr_outstanding > 0) begin
        num_wr_outstanding--;
        wr_err_queue.push_front(int_wr_err);
      end
      if (int_rd_en) begin
        num_rd_outstanding++;
        rd_addr_queue.push_front(int_addr);
      end
      if (int_rd_ack && num_rd_outstanding > 0) begin
        num_rd_outstanding--;
        rd_data_queue.push_front(int_rd_data);
        rd_err_queue.push_front(int_rd_err);
      end

      // Internal write transaction
      if (wr_addr_queue.size() > 0 && wr_data_queue.size() > 0 && wr_err_queue.size() > 0) begin
        addr  = wr_addr_queue.pop_back();
        data  = wr_data_queue.pop_back();
        err   = wr_err_queue.pop_back();
        // $display("[%t] Int write transaction: addr = %x, data = %x, err = %x", $realtime, addr,
        //          data, err);
        trans = '{addr, data, {2{err}}};
        int_write_queue.push_front(trans);
      end

      // Internal read transaction
      if (rd_addr_queue.size() > 0 && rd_data_queue.size() > 0 && rd_err_queue.size() > 0) begin
        addr  = rd_addr_queue.pop_back();
        data  = rd_data_queue.pop_back();
        err   = rd_err_queue.pop_back();
        // $display("[%t] Int read transaction: addr = %x, data = %x, err = %x", $realtime, addr,
        //          data, err);
        trans = '{addr, data, {2{err}}};
        int_read_queue.push_front(trans);
      end
    end  // forever
  endtask

  // Scoreboard

  task automatic scoreboard();
    transaction_t trans1, trans2;
    forever begin
      @(posedge s_axi_aclk);
      // Check write transaction
      if (axi_write_queue.size() > 1 && int_write_queue.size() > 1) begin
        trans1 = axi_write_queue.pop_back();
        trans2 = int_write_queue.pop_back();
        if (trans1 != trans2) begin
          $error("[%t] Write transaction mismatch", $realtime);
          $display("AXI: '{%x, %x, %x}", trans1.addr, trans1.data, trans1.resp);
          $display("Int: '{%x, %x, %x}", trans2.addr, trans2.data, trans2.resp);
        end
      end
      // Check read transaction
      if (axi_read_queue.size() > 1 && int_read_queue.size() > 1) begin
        trans1 = axi_read_queue.pop_back();
        trans2 = int_read_queue.pop_back();
        if (trans1 != trans2) begin
          $error("[%t] Read transaction mismatch", $realtime);
          $display("AXI: '{%x, %x, %x}", trans1.addr, trans1.data, trans1.resp);
          $display("Int: '{%x, %x, %x}", trans2.addr, trans2.data, trans2.resp);
        end
      end
    end
  endtask


  // DUT

  axi4l_int dut (
      .s_axi_aclk   (s_axi_aclk),
      .s_axi_aresetn(s_axi_aresetn),
      //
      .s_axi_awaddr (s_axi_awaddr),
      .s_axi_awprot (s_axi_awprot),
      .s_axi_awvalid(s_axi_awvalid),
      .s_axi_awready(s_axi_awready),
      //
      .s_axi_wdata  (s_axi_wdata),
      .s_axi_wstrb  (s_axi_wstrb),
      .s_axi_wvalid (s_axi_wvalid),
      .s_axi_wready (s_axi_wready),
      //
      .s_axi_bresp  (s_axi_bresp),
      .s_axi_bvalid (s_axi_bvalid),
      .s_axi_bready (s_axi_bready),
      //
      .s_axi_araddr (s_axi_araddr),
      .s_axi_arprot (s_axi_arprot),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arready(s_axi_arready),
      //
      .s_axi_rdata  (s_axi_rdata),
      .s_axi_rresp  (s_axi_rresp),
      .s_axi_rvalid (s_axi_rvalid),
      .s_axi_rready (s_axi_rready),
      //
      .int_addr     (int_addr),
      .int_wr_data  (int_wr_data),
      .int_wr_strb  (int_wr_strb),
      .int_wr_en    (int_wr_en),
      .int_rd_en    (int_rd_en),
      //
      .int_wr_ack   (int_wr_ack),
      .int_wr_err   (int_wr_err),
      //
      .int_rd_ack   (int_rd_ack),
      .int_rd_err   (int_rd_err),
      .int_rd_data  (int_rd_data)
  );


  // Stimulation
  //------------

  initial begin
    s_axi_aclk = 0;
    forever begin
      #5 s_axi_aclk = ~s_axi_aclk;
    end
  end

  initial begin
    $display("*** Simulation started");
    $timeformat(-9, 2, " ns", 20);
    dut_reset();
    fork
      axi_driver(NUM_WR_TRANS, NUM_RD_TRANS);
      int_driver(NUM_WR_TRANS, NUM_RD_TRANS);
    join

    #1000;
    $finish;
  end

  final begin
    $display("*** Simulation ended");
  end

  initial begin
    axi_monitor();
  end

  initial begin
    int_monitor();
  end

  initial begin
    scoreboard();
  end

endmodule

`default_nettype wire

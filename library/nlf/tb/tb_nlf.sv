// File: tb_nlf.sv
// Brief: Test bench for module nlf

`timescale 1 ns / 1 ps `default_nettype none

module tb_nlf #();

  localparam int TestVectorLength = 4096;

  localparam int DataPathLatency = 26;

  localparam int NumUnits = 16;
  localparam int DataWidth = 16;
  localparam int IndexWidth = 8;
  localparam int LutDataWidth = 16;
  localparam int SraBits = 14;

  // DUT signals

  logic                                        clk;
  logic                                        rst;
  //
  logic signed [                DataWidth-1:0] data_i_in;
  logic signed [                DataWidth-1:0] data_q_in;
  //
  logic        [               IndexWidth-1:0] index_in;
  //
  logic signed [                DataWidth-1:0] data_i_out;
  logic signed [                DataWidth-1:0] data_q_out;
  // Overflow indicator
  logic                                        ovf;
  // Control Interface
  logic                                        ctrl_clk;
  logic                                        ctrl_rst;
  //
  logic                                        ctrl_bank;
  //
  logic        [         $clog2(NumUnits)-1:0] ctrl_index_delay [                NumUnits];
  logic        [         $clog2(NumUnits)-1:0] ctrl_signal_delay[                NumUnits];

  logic        [$clog2(NumUnits)+IndexWidth:0] ctrl_lut_addr;
  logic                                        ctrl_lut_en;
  logic                                        ctrl_lut_we;
  logic        [           LutDataWidth*2-1:0] ctrl_lut_din;
  logic        [           LutDataWidth*2-1:0] ctrl_lut_dout;

  // Testbench signals

  logic signed [                DataWidth-1:0] data_i_out_ref;
  logic signed [                DataWidth-1:0] data_q_out_ref;

  logic                                        ovf_ref;

  logic        [             LutDataWidth-1:0] lut_i_mem        [2**IndexWidth * NumUnits];
  logic        [             LutDataWidth-1:0] lut_q_mem        [2**IndexWidth * NumUnits];
  //
  logic        [         $clog2(NumUnits)-1:0] index_delay_mem  [                NumUnits];
  logic        [         $clog2(NumUnits)-1:0] signal_delay_mem [                NumUnits];
  //
  logic signed [                DataWidth-1:0] data_i_mem       [        TestVectorLength];
  logic signed [                DataWidth-1:0] data_q_mem       [        TestVectorLength];
  //
  logic        [               IndexWidth-1:0] index_mem        [        TestVectorLength];
  //
  logic        [                DataWidth-1:0] yout_i_mem       [        TestVectorLength];
  logic        [                DataWidth-1:0] yout_q_mem       [        TestVectorLength];
  //
  logic                                        ovf_mem          [        TestVectorLength];

  logic lut_check_done, datapath_check_done;


  initial begin
    $readmemh("test_nlf_lut_i.txt", lut_i_mem);
    $readmemh("test_nlf_lut_q.txt", lut_q_mem);
    //
    $readmemh("test_nlf_index_delay.txt", index_delay_mem);
    $readmemh("test_nlf_signal_delay.txt", signal_delay_mem);
    //
    $readmemh("test_nlf_signal_i.txt", data_i_mem);
    $readmemh("test_nlf_signal_q.txt", data_q_mem);
    //
    $readmemh("test_nlf_index.txt", index_mem);
    //
    $readmemh("test_nlf_yout_i.txt", yout_i_mem);
    $readmemh("test_nlf_yout_q.txt", yout_q_mem);
    //
    $readmemh("test_nlf_ovf.txt", ovf_mem);
  end


  // Clock and reset stimulation
  //============================

  initial begin
    forever begin
      #1 clk = 1'b0;
      #1 clk = 1'b1;
    end
  end

  initial begin
    forever begin
      #5 ctrl_clk = 1'b0;
      #5 ctrl_clk = 1'b1;
    end
  end

  initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst <= 0;
  end

  initial begin
    ctrl_rst = 1;
    repeat (10) @(posedge ctrl_clk);
    ctrl_rst <= 0;
  end


  // Simulation
  //===========

  initial begin
    $timeformat(-9, 3, " ns", 8);
    $display("*** Simulation starts ***");
  end

  // LUT write/read test
  initial begin
    lut_check_done = 0;

    // Reset interface
    ctrl_lut_addr <= '0;
    ctrl_lut_en   <= '0;
    ctrl_lut_we   <= '0;
    ctrl_lut_din  <= '0;

    wait (rst == 0);
    wait (ctrl_rst == 0);

    // Set LUT memory
    begin : p_write_lut
      logic [$clog2(NumUnits)+IndexWidth:0] addr;
      logic [LutDataWidth*2-1:0] data;

      for (int unit = 0; unit < NumUnits; unit++) begin
        for (int bank = 0; bank < 2; bank++) begin
          for (int i = 0; i < (2 ** IndexWidth); i++) begin
            addr = {unit[$clog2(NumUnits)-1:0], bank[0], i[IndexWidth-1:0]};
            data = {lut_q_mem[unit*(2**IndexWidth)+i], lut_i_mem[unit*(2**IndexWidth)+i]};

            @(posedge ctrl_clk);
            ctrl_lut_addr <= addr;
            ctrl_lut_en   <= 1;
            ctrl_lut_we   <= 1;
            ctrl_lut_din  <= data;

          end  // for
        end  // for
      end  // for
    end  // p_write_lut

    // Reset interface
    @(posedge ctrl_clk);
    ctrl_lut_addr <= '0;
    ctrl_lut_en   <= '0;
    ctrl_lut_we   <= '0;
    ctrl_lut_din  <= '0;

    // Check LUT memory
    fork
      begin : p_set_lut_rd_address
        logic [$clog2(NumUnits)+IndexWidth:0] addr;

        for (int unit = 0; unit < NumUnits; unit++) begin
          for (int bank = 0; bank < 2; bank++) begin
            for (int i = 0; i < (2 ** IndexWidth); i++) begin
              addr = {unit[$clog2(NumUnits)-1:0], bank[0], i[IndexWidth-1:0]};
              @(posedge ctrl_clk);
              ctrl_lut_addr <= addr;
              ctrl_lut_en   <= 1;
            end
          end
        end

        @(posedge ctrl_clk);
        ctrl_lut_addr <= '0;
        ctrl_lut_en   <= '0;
      end  // p_set_lut_rd_address

      begin : p_check_lut_rd_data
        logic [$clog2(NumUnits)+IndexWidth:0] addr;
        logic [LutDataWidth*2-1:0] data;

        @(posedge ctrl_clk);
        @(posedge ctrl_clk);

        for (int unit = 0; unit < NumUnits; unit++) begin
          for (int bank = 0; bank < 2; bank++) begin
            for (int i = 0; i < (2 ** IndexWidth); i++) begin
              addr = {unit[$clog2(NumUnits)-1:0], bank[0], i[IndexWidth-1:0]};
              data = {lut_q_mem[unit*(2**IndexWidth)+i], lut_i_mem[unit*(2**IndexWidth)+i]};

              @(posedge ctrl_clk);
              if (ctrl_lut_dout != data) begin
                $display(
                    "WARNING: time: %t, LUT memory check error at address %d. Expect: %x, got %x",
                    $realtime, addr, data, ctrl_lut_dout);
              end  // if

            end  // for
          end  // for
        end  // for
      end  // p_check_lut_rd_data

    join

    lut_check_done = 1;
  end


  // Datapath test
  initial begin
    ctrl_bank = 0;
    datapath_check_done = 0;
    for (int i = 0; i < NumUnits; i++) begin
      ctrl_index_delay[i]  <= index_delay_mem[i];
      ctrl_signal_delay[i] <= signal_delay_mem[i];
    end
    data_i_in <= '0;
    data_q_in <= '0;
    index_in  <= '0;

    wait (lut_check_done == 1);

    @(posedge clk);
    fork
      begin : p_feed_signal
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          data_i_in <= data_i_mem[i];
          data_q_in <= data_q_mem[i];
        end
      end

      begin : p_feed_index
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          index_in <= index_mem[i];
        end
      end

      begin : p_ref_signal
        repeat (DataPathLatency) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          data_i_out_ref <= yout_i_mem[i];
          data_q_out_ref <= yout_q_mem[i];
        end
      end

      begin : p_ref_ovf
        repeat (DataPathLatency) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          ovf_ref <= ovf_mem[i];
        end
      end

      begin : p_chk_signal
        repeat (DataPathLatency + 1) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          if (data_i_out_ref != data_i_out) begin
            $display(
                "ERROR: time: %t, data mismatch at tick %d. data_i_out_ref: %d, data_i_out: %d",
                $realtime, i, data_i_out_ref, data_i_out);
          end
          if (data_q_out_ref != data_q_out) begin
            $display(
                "ERROR: time: %t, data mismatch at tick %d. data_q_out_ref: %d, data_q_out: %d",
                $realtime, i, data_q_out_ref, data_q_out);
          end
        end
      end

      begin : p_chk_ovf
        repeat (DataPathLatency + 1) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          if (ovf_ref != ovf) begin
            $display(
                "ERROR: time: %t, ovf mismatch at tick %d. ovf_ref: %d, ovf: %d",
                $realtime, i, ovf_ref, ovf);
          end
        end
      end

    join

    datapath_check_done = 1;
  end


  initial begin
    wait (datapath_check_done == 1);
    #100;
    $display("*** Simulation ends ***");
    $finish();
  end


  // UUT
  //====

  nlf #(
      .NUM_UNITS     (NumUnits),
      .DATA_WIDTH    (DataWidth),
      .INDEX_WIDTH   (IndexWidth),
      .LUT_DATA_WIDTH(LutDataWidth),
      .SRA_BITS      (SraBits)
  ) UUT (
      .*
  );


endmodule

`default_nettype wire

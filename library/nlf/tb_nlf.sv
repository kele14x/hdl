// File: tb_nlf.sv
// Brief: Test bench for module nlf

`timescale 1 ns / 1 ps `default_nettype none

module tb_nlf #();

  localparam int TestVectorLength = 4096;

  localparam int NumUnits = 16;
  localparam int DataWidth = 16;
  localparam int IndexWidth = 8;
  localparam int LutDataWidth = 16;
  localparam int SraBits = 15;

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
  logic        [         $clog2(NumUnits)-1:0] ctrl_index_delay [                    NumUnits];
  logic        [         $clog2(NumUnits)-1:0] ctrl_signal_delay[                    NumUnits];

  logic        [$clog2(NumUnits)+IndexWidth:0] ctrl_lut_addr;
  logic                                        ctrl_lut_en;
  logic                                        ctrl_lut_we;
  logic        [           LutDataWidth*2-1:0] ctrl_lut_din;
  logic        [           LutDataWidth*2-1:0] ctrl_lut_dout;

  logic signed [                DataWidth-1:0] data_i_out_ref;
  logic signed [                DataWidth-1:0] data_q_out_ref;

  logic        [                DataWidth-1:0] data_mem         [          TestVectorLength*2];
  logic        [               IndexWidth-1:0] index_mem        [            TestVectorLength];
  logic        [                DataWidth-1:0] yout_mem         [          TestVectorLength*2];
  logic                                        ovf_mem          [            TestVectorLength];
  logic        [             LutDataWidth-1:0] lut_mem          [2**IndexWidth * NumUnits * 2];


  initial begin
    $readmemh("test_nlf_signal.txt", data_mem, 0, TestVectorLength * 2 - 1);
    $readmemh("test_nlf_index.txt", index_mem, 0, TestVectorLength - 1);
    $readmemh("test_nlf_yout.txt", yout_mem, 0, TestVectorLength * 2 - 1);
    $readmemh("test_nlf_ovf.txt", ovf_mem, 0, TestVectorLength - 1);
    $readmemh("test_nlf_lut.txt", lut_mem, 0, 2 ** IndexWidth * NumUnits * 2 - 1);
  end


  // Clock and reset stimulation
  //============================

  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  initial begin
    ctrl_clk = 0;
    forever begin
      #5 ctrl_clk = ~ctrl_clk;
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
    wait (rst == 0);
    wait (ctrl_rst == 0);

    //
    ctrl_bank = 0;

    // Set LUT memory
    @(posedge ctrl_clk);
    for (int i = 0; i < 2 ** IndexWidth * NumUnits; i++) begin
      @(posedge ctrl_clk);
      ctrl_lut_addr <= {1'b0, i[$clog2(NumUnits)+IndexWidth-1:0]};
      ctrl_lut_en   <= 1;
      ctrl_lut_we   <= 1;
      ctrl_lut_din  <= {lut_mem[2*i+1], lut_mem[2*i]};
    end
    @(posedge ctrl_clk);
    ctrl_lut_addr <= '0;
    ctrl_lut_en   <= '0;
    ctrl_lut_we   <= '0;
    ctrl_lut_din  <= '0;

    // Check LUT memory
    fork
      begin : p_set_address
        for (int i = 0; i < 2 ** IndexWidth * NumUnits; i++) begin
          @(posedge ctrl_clk);
          ctrl_lut_addr <= {1'b0, i[$clog2(NumUnits)+IndexWidth-1:0]};
          ctrl_lut_en   <= 1;
        end
        @(posedge ctrl_clk);
        ctrl_lut_addr <= '0;
        ctrl_lut_en   <= '0;
      end

      begin : p_check_data
        @(posedge ctrl_clk);
        @(posedge ctrl_clk);
        for (int i = 0; i < 2 ** IndexWidth * NumUnits; i++) begin
          @(posedge ctrl_clk);
          if (ctrl_lut_dout != {lut_mem[2*i+1], lut_mem[2*i]}) begin
            $warning("%t: ", $time, "LUT memory error at index %d", i, " expect: %x", {
                     lut_mem[2*i+1], lut_mem[2*i]}, " got: ", ctrl_lut_dout);
          end
        end
      end

    join

    // Check data path
    fork
      begin : p_feed_signal
        @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          data_i_in <= data_mem[2*i];
          data_q_in <= data_mem[2*i+1];
        end
      end

      begin : p_feed_index
        @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          index_in <= index_mem[i];
        end
      end

      begin : p_ref_signal
        @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          data_i_out_ref <= yout_mem[2*i];
          data_q_out_ref <= yout_mem[2*i+1];
        end
      end

      begin : p_ref_ovf
        @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          data_i_out_ref <= ovf_mem[i];
        end
      end

    join

    #1000;
    $finish(2);
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

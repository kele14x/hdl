// File: lowphy_fft_conv.sv
// Brief: Convolution with input data with a DDS waveform, could be either time
//        domain or frequency domain. Latency is 17 clock ticks.
`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy_conv #(
    parameter POFF_INIT_PARAM = "0",
    parameter PINC_INIT_PARAM = "0"
) (
    input var         clk,
    input var         rst,
    //
    input var         din_sof,
    input var         din_sos,
    input var  [31:0] din_data,
    input var         din_valid,
    //
    output var        dout_sof,
    output var        dout_sos,
    output var [31:0] dout_data,
    output var        dout_valid,
    // Control & Status
    input var         ctrl_clk,
    input var         ctrl_rst,
    // Poff memory
    input var         ctrl_poff_mem_en,
    input var         ctrl_poff_mem_we,
    input var  [ 3:0] ctrl_poff_mem_addr,
    input var  [31:0] ctrl_poff_mem_din,
    output var [31:0] ctrl_poff_mem_dout,
    // Pinc memory
    input var         ctrl_pinc_mem_en,
    input var         ctrl_pinc_mem_we,
    input var  [ 3:0] ctrl_pinc_mem_addr,
    input var  [31:0] ctrl_pinc_mem_din,
    output var [31:0] ctrl_pinc_mem_dout
);

  logic [ 4:0] current_symbol;  // 0 ~ 13

  logic [31:0] din_data_d;
  logic        din_sos_d;

  logic        dds_resync;
  logic [31:0] dds_poff;
  logic [31:0] dds_pinc;
  logic [71:0] dds_config;
  logic        dds_config_valid;

  logic [31:0] dds_data;


  // din_sof/sos -> current_symbol ->  dds_poff/pinc -> dds_data(9)

  // Current Symbol counter

  // Make a counter to get current symbol in slot
  // TODO: This is only for mu = 1

  always_ff @(posedge clk) begin
    if (rst) begin
      current_symbol <= '0;
    end else if (din_sof) begin
      current_symbol <= '0;
    end else if (din_sos) begin
      if (current_symbol == 13) begin
        current_symbol <= '0;
      end else begin
        current_symbol <= current_symbol + 1;
      end
    end
  end

  // Phase compensation data RAM
  // The current symbol number will be used to lookup the phase compensation
  // value. Which is stored in a DRAM

  xpm_memory_dpdistram #(
      .ADDR_WIDTH_A           (4),
      .ADDR_WIDTH_B           (4),
      .BYTE_WRITE_WIDTH_A     (32),
      .CLOCKING_MODE          ("independent_clock"),
      .MEMORY_INIT_FILE       ("none"),
      .MEMORY_INIT_PARAM      (POFF_INIT_PARAM),
      .MEMORY_OPTIMIZATION    ("true"),
      .MEMORY_SIZE            (32 * 14),
      .MESSAGE_CONTROL        (0),
      .READ_DATA_WIDTH_A      (32),
      .READ_DATA_WIDTH_B      (32),
      .READ_LATENCY_A         (1),
      .READ_LATENCY_B         (1),
      .READ_RESET_VALUE_A     ("0"),
      .READ_RESET_VALUE_B     ("0"),
      .RST_MODE_A             ("SYNC"),
      .RST_MODE_B             ("SYNC"),
      .SIM_ASSERT_CHK         (0),
      .USE_EMBEDDED_CONSTRAINT(0),
      .USE_MEM_INIT           (1),
      .USE_MEM_INIT_MMI       (0),
      .WRITE_DATA_WIDTH_A     (32)
  ) i_poff_ram (
      .clka  (ctrl_clk),
      .rsta  (ctrl_rst),
      .ena   (ctrl_poff_mem_en),
      .wea   (ctrl_poff_mem_we),
      .addra (ctrl_poff_mem_addr),
      .dina  (ctrl_poff_mem_din),
      .douta (ctrl_poff_mem_dout),
      .regcea(1'b1),
      //
      .clkb  (clk),
      .rstb  (1'b0),
      .enb   (1'b1),
      .addrb (current_symbol),
      .regceb(1'b1),
      .doutb (dds_poff)
  );

  // Time shift param RAM
  // PINC is used to do time shift for CP insertion

  xpm_memory_dpdistram #(
      .ADDR_WIDTH_A           (4),
      .ADDR_WIDTH_B           (4),
      .BYTE_WRITE_WIDTH_A     (32),
      .CLOCKING_MODE          ("independent_clock"),
      .MEMORY_INIT_FILE       ("none"),
      .MEMORY_INIT_PARAM      (PINC_INIT_PARAM),
      .MEMORY_OPTIMIZATION    ("true"),
      .MEMORY_SIZE            (32 * 14),
      .MESSAGE_CONTROL        (0),
      .READ_DATA_WIDTH_A      (32),
      .READ_DATA_WIDTH_B      (32),
      .READ_LATENCY_A         (1),
      .READ_LATENCY_B         (1),
      .READ_RESET_VALUE_A     ("0"),
      .READ_RESET_VALUE_B     ("0"),
      .RST_MODE_A             ("SYNC"),
      .RST_MODE_B             ("SYNC"),
      .SIM_ASSERT_CHK         (0),
      .USE_EMBEDDED_CONSTRAINT(0),
      .USE_MEM_INIT           (1),
      .USE_MEM_INIT_MMI       (0),
      .WRITE_DATA_WIDTH_A     (32)
  ) i_pinc_ram (
      .clka  (ctrl_clk),
      .rsta  (ctrl_rst),
      .ena   (ctrl_pinc_mem_en),
      .wea   (ctrl_pinc_mem_we),
      .addra (ctrl_pinc_mem_addr),
      .dina  (ctrl_pinc_mem_din),
      .douta (ctrl_pinc_mem_dout),
      .regcea(1'b1),
      //
      .clkb  (clk),
      .rstb  (din_sos_d),
      .enb   (1'b1),
      .addrb (current_symbol),
      .regceb(1'b1),
      .doutb (dds_pinc)
  );


  // DDS
  // The phase initial value and phase increment value should be reset (resync)
  // at every symbol's beginning

  always_ff @(posedge clk) begin
    if (rst) begin
      dds_config_valid <= 1'b0;
    end else begin
      dds_config_valid <= 1'b1;
    end
  end

  assign dds_config = {7'b0, dds_resync, dds_poff, dds_pinc};

  always_ff @(posedge clk) begin
    din_sos_d  <= din_sos;
    dds_resync <= din_sos_d;
  end

  // The latency of DDS is 9 clock ticks
  // (dds_config_valid to m_axis_data_tvalid, or resync to m_axis_data_tvalid)
  // Unity circle mode, output has amplitude of 16384
  dds_compiler u_dds (
      .aclk               (clk),
      .aresetn            (~rst),
      //
      .s_axis_phase_tdata (dds_config),
      .s_axis_phase_tvalid(dds_config_valid),
      //
      .m_axis_data_tdata  (dds_data),
      .m_axis_data_tvalid ()
  );


  // Complex multiplier

  delay #(
      .WIDTH(32),
      .DEPTH(11)
  ) i_data_delay (
      .clk (clk),
      .din (din_data),
      .dout(din_data_d)
  );

  // The latency of cmult is 7 clock ticks
  cmult #(
      .A_WIDTH(16),
      .B_WIDTH(16),
      .P_WIDTH(16),
      .SHIFT  (14)
  ) u_complex_mult (
      .clk(clk),
      //
      .ar (din_data_d[15:0]),
      .ai (din_data_d[31:16]),
      //
      .br (dds_data[15:0]),
      .bi (dds_data[31:16]),
      //
      .pr (dout_data[15:0]),
      .pi (dout_data[31:16])
  );

  delay #(
      .WIDTH(3),
      .DEPTH(18)
  ) i_sof_delay (
      .clk (clk),
      .din ({din_valid, din_sos, din_sof}),
      .dout({dout_valid, dout_sos, dout_sof})
  );

endmodule

`default_nettype wire

`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy_phase_comp (
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
    //
    input var         ctrl_clk,
    input var         ctrl_rst,
    //
    input var  [ 3:0] ctrl_phase_comp_addr,
    input var         ctrl_phase_comp_en,
    input var         ctrl_phase_comp_we,
    input var  [31:0] ctrl_phase_comp_din,
    output var [31:0] ctrl_phase_comp_dout
);


  logic [ 4:0] current_symbol;

  logic [31:0] din_data_d;

  logic [31:0] phase_comp_data;


  // Current Symbol counter

  always_ff @(posedge clk) begin
    if (rst | din_sof) begin
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
  xpm_memory_dpdistram #(
      .ADDR_WIDTH_A           (4),
      .ADDR_WIDTH_B           (4),
      .BYTE_WRITE_WIDTH_A     (32),
      .CLOCKING_MODE          ("independent_clock"),
      .MEMORY_INIT_FILE       ("none"),
      .MEMORY_INIT_PARAM      ("00007FFF,00007FFF,00007FFF,00007FFF,00007FFF,00007FFF,00007FFF,00007FFF,00007FFF,00007FFF,00007FFF,00007FFF,00007FFF,00007FFF"),
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
  ) xpm_memory_dpdistram_inst (
      .clka  (ctrl_clk),
      .rsta  (ctrl_rst),
      .ena   (ctrl_phase_comp_en),
      .wea   (ctrl_phase_comp_we),
      .addra (ctrl_phase_comp_addr),
      .dina  (ctrl_phase_comp_din),
      .douta (ctrl_phase_comp_dout),
      .regcea(1'b1),
      //
      .clkb  (clk),
      .rstb  (1'b0),
      .enb   (1'b1),
      .addrb (current_symbol),
      .regceb(1'b1),
      .doutb (phase_comp_data)
  );

  // Complex multiplier

  // Match phase_comp_data latency: 2 clcok
  delay #(
    .WIDTH(32),
    .DEPTH(2)
  ) i_data_delay (
    .clk (clk),
    .din (din_data),
    .dout(din_data_d)
  );

  cmult #(
      .A_WIDTH(16),
      .B_WIDTH(16),
      .P_WIDTH(16),
      .SHIFT  (15)
  ) u_complex_mult (
      .clk(clk),
      //
      .ar (din_data_d[15:0]),
      .ai (din_data_d[31:16]),
      //
      .br (phase_comp_data[15:0]),
      .bi (phase_comp_data[31:16]),
      //
      .pr (dout_data[15:0]),
      .pi (dout_data[31:16])
  );

  delay #(
    .WIDTH(3),
    .DEPTH(2+7)
  ) i_sof_delay (
    .clk (clk),
    .din ({din_valid, din_sos, din_sof}),
    .dout({dout_valid, dout_sos, dout_sof})
  );

endmodule

`default_nettype wire

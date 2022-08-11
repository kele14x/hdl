// File: ch_fir.sv
// Brief: Channel filter
`timescale 1 ns / 1 ps
//
`default_nettype none

module ch_fir #(
    parameter int CSR_SUPPORT       = 4,
    parameter int NUM_STAGES        = 16,
    //
    parameter int INPUT_DATA_WIDTH  = 16,
    parameter int OUTPUT_DATA_WIDTH = 16,
    //
    parameter int COE_ADDR_WIDTH    = 6,
    parameter int COE_DATA_WIDTH    = 16,
    //
    parameter int SRA_BITS          = 15
) (
    input var                                 clk,
    input var                                 rst,
    //
    input var  signed [ INPUT_DATA_WIDTH-1:0] data_i_in,
    input var  signed [ INPUT_DATA_WIDTH-1:0] data_q_in,
    input var                                 data_valid_in,
    //
    output var signed [OUTPUT_DATA_WIDTH-1:0] data_i_out,
    output var signed [OUTPUT_DATA_WIDTH-1:0] data_q_out,
    output var                                data_valid_out,
    // Control signals
    //----------------
    input var                                 ctrl_clk,
    input var                                 ctrl_rst,
    // Coefficient memory
    input var                                 ctrl_coe_en,
    input var                                 ctrl_coe_we,
    input var         [   COE_ADDR_WIDTH-1:0] ctrl_coe_addr,
    input var         [   COE_DATA_WIDTH-1:0] ctrl_coe_data_in,
    output var        [   COE_DATA_WIDTH-1:0] ctrl_coe_data_out
);

  // Local parameters
  //=================

  localparam int BufferAddrWidth = $clog2(NUM_STAGES * CSR_SUPPORT * 2);
  localparam int BufferDataWidth = INPUT_DATA_WIDTH * 2;

  localparam int CascadeDataWidth = INPUT_DATA_WIDTH + COE_DATA_WIDTH + $clog2(NUM_STAGES);


  // State
  //======

  logic [$clog2(CSR_SUPPORT)-1:0] state;

  always_ff @(posedge clk) begin
    if (rst || data_valid_in) begin
      state <= 0;
    end else begin
      state <= state + 1;
    end
  end


  // Coefficients Store
  //===================
  
  // Coefficients are stored in a register array
  (* ram_style="register" *)
  logic [COE_DATA_WIDTH-1:0] coe_array[2**COE_ADDR_WIDTH];

  logic [COE_DATA_WIDTH-1:0] coe_b    [NUM_STAGES];

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_coe_we && ctrl_coe_we) begin
      coe_array[ctrl_coe_addr] <= ctrl_coe_data_in;
    end
  end

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_coe_en) begin
      ctrl_coe_data_out <= coe_array[ctrl_coe_addr];
    end
  end

  generate
    for (genvar i = 0; i < NUM_STAGES; i = i + 1) begin: g_coe_b
      always_ff @(posedge clk) begin
        coe_b[i] <= coe_array[i*CSR_SUPPORT + state];
      end
    end
  endgenerate


  // Write data buffer
  //==================

  logic                       wr_en;
  logic [BufferAddrWidth-1:0] wr_addr;
  logic [BufferDataWidth-1:0] wr_data;

  always_ff @(posedge clk) begin
    wr_en   <= data_valid_in;
    wr_data <= {data_q_in, data_i_in};
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_addr <= 0;
    end else if (wr_en) begin
      wr_addr <= wr_addr + 1;
    end
  end


  // Read data buffer
  //=================

  logic                       rd_en;
  logic [BufferAddrWidth-1:0] rd_addr_a[NUM_STAGES];
  logic [BufferAddrWidth-1:0] rd_addr_d[NUM_STAGES];
  logic [BufferDataWidth-1:0] rd_data_a[NUM_STAGES];
  logic [BufferDataWidth-1:0] rd_data_d[NUM_STAGES];

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_en <= 0;
    end else begin
      rd_en <= 1;
    end
  end

  generate
    for (genvar i = 0; i < NUM_STAGES; i++) begin : g_rd_addr

      always_ff @(posedge clk) begin
        if (rst) begin
          rd_addr_a[i] <= 0;
        end else begin
          rd_addr_a[i] <= wr_addr + state + i * 4;
        end
      end

      always_ff @(posedge clk) begin
        if (rst) begin
          rd_addr_d[i] <= 0;
        end else begin
          rd_addr_d[i] <= wr_addr - state + i * 4;
        end
      end

    end
  endgenerate


  // OP
  //===

  logic op [NUM_STAGES];

  generate
    for(genvar i = 0; i < NUM_STAGES; i++) begin : g_op
      always_ff @(posedge clk) begin
        op[i] <= state == 3;
      end
    end
  endgenerate


  // Stages
  //=======

  logic signed [CascadeDataWidth-1:0] cascade_i_s[NUM_STAGES+1];
  logic signed [CascadeDataWidth-1:0] cascade_q_s[NUM_STAGES+1];

  assign cascade_i_s[0] = (1 <<< (SRA_BITS - 1));
  assign cascade_q_s[0] = (1 <<< (SRA_BITS - 1));

  generate
    for (genvar i = 0; i < NUM_STAGES; i = i + 1) begin : g_stage

      ram_sdp_pipe #(
          .ADDR_WIDTH  (BufferAddrWidth),
          .DATA_WIDTH  (BufferDataWidth),
          .READ_LATENCY(1),
          .INIT_WORD   ('0)
      ) i_data_a_buf (
          // Port A
          .clka (clk),
          .ena  (wr_en),
          .wea  (wr_en),
          .addra(wr_addr),
          .dina (wr_data),
          // Port B
          .clkb (clk),
          .rstb (1'b0),
          .enb  (rd_en),
          .addrb(rd_addr_a[i]),
          .doutb(rd_data_a[i])
      );

      ram_sdp_pipe #(
          .ADDR_WIDTH  (BufferAddrWidth),
          .DATA_WIDTH  (BufferDataWidth),
          .READ_LATENCY(1),
          .INIT_WORD   ('0)
      ) i_data_d_buf (
          // Port A
          .clka (clk),
          .ena  (wr_en),
          .wea  (wr_en),
          .addra(wr_addr),
          .dina (wr_data),
          // Port B
          .clkb (clk),
          .rstb (1'b0),
          .enb  (rd_en),
          .addrb(rd_addr_d[i]),
          .doutb(rd_data_d[i])
      );

      mac #(
          .A_WIDTH  (INPUT_DATA_WIDTH),
          .B_WIDTH  (COE_DATA_WIDTH),
          .C_WIDTH  (CascadeDataWidth),
          .D_WIDTH  (INPUT_DATA_WIDTH),
          .P_WIDTH  (CascadeDataWidth),
          .A_REG    (1),
          .AD_REG   (1),
          .B_REG    (1),
          .C_REG    (0),
          .D_REG    (1),
          .M_REG    (1),
          .OP_REG   (1),
          .P_REG    (1),
          .USE_DPORT(1)
      ) i_i_mac (
          .clk(clk),
          .a  (rd_data_a[i][INPUT_DATA_WIDTH-1:0]),
          .b  (coe_b[i]),
          .c  (cascade_i_s[i]),
          .d  (rd_data_d[i][INPUT_DATA_WIDTH-1:0]),
          .op (op[i]),
          .p  (cascade_i_s[i+1])
      );

      mac #(
          .A_WIDTH  (INPUT_DATA_WIDTH),
          .B_WIDTH  (COE_DATA_WIDTH),
          .C_WIDTH  (CascadeDataWidth),
          .D_WIDTH  (INPUT_DATA_WIDTH),
          .P_WIDTH  (CascadeDataWidth),
          .A_REG    (1),
          .AD_REG   (1),
          .B_REG    (1),
          .C_REG    (0),
          .D_REG    (1),
          .M_REG    (1),
          .OP_REG   (1),
          .P_REG    (1),
          .USE_DPORT(1)
      ) i_q_mac (
          .clk(clk),
          .a  (rd_data_a[i][2*INPUT_DATA_WIDTH-1:INPUT_DATA_WIDTH]),
          .b  (coe_b[i]),
          .c  (cascade_q_s[i]),
          .d  (rd_data_d[i][2*INPUT_DATA_WIDTH-1:INPUT_DATA_WIDTH]),
          .op (op[i]),
          .p  (cascade_q_s[i+1])
      );

    end
  endgenerate

  always_ff @(posedge clk) begin
    data_i_out <= cascade_i_s[NUM_STAGES][OUTPUT_DATA_WIDTH+SRA_BITS-1:SRA_BITS];
    data_q_out <= cascade_q_s[NUM_STAGES][OUTPUT_DATA_WIDTH+SRA_BITS-1:SRA_BITS];
  end

endmodule

`default_nettype wire

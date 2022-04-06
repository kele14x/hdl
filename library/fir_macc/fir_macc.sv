// File: fir_macc.sv
// Brief: FIR using MACC (Multiply and accumulation) architecture.
//        Supports max 16 channel, 8 coefficient sets, 128 coefficient length
`timescale 1 ns / 1 ps
//
`default_nettype none

module fir_macc #(
    parameter int XIN_WIDTH  = 24,
    parameter int COE_WIDTH  = 16,
    parameter int YOUT_WIDTH = 24,
    parameter int SRA_BITS   = 15
) (
    input var  logic                  aclk,
    input var  logic                  aresetn,
    // Data input
    input var  logic [ XIN_WIDTH-1:0] s_axis_tdata,
    input var  logic                  s_axis_tvalid,
    output var logic                  s_axis_tready,
    input var  logic [           3:0] s_axis_tuser,             // channel number
    // Data output
    output var logic [YOUT_WIDTH-1:0] m_axis_tdata,
    output var logic                  m_axis_tvalid,
    input var  logic                  m_axis_tready,
    output var logic [           3:0] m_axis_tuser,             // channel number
    // Control interface
    input var  logic [           9:0] ctrl_coe_wr_addr,
    input var  logic                  ctrl_coe_wr_en,
    input var  logic [ COE_WIDTH-1:0] ctrl_coe_wr_din,
    //
    input var  logic [           6:0] ctrl_coefficient_length,
    input var  logic [           2:0] ctrl_coefficient_set,
    // Status
    output var logic                  err_ovf
);

  typedef enum int {
    S_RST,
    S_IDLE,
    S_ACC,
    S_WAIT0,
    S_WAIT1,
    S_WAIT2,
    S_WAIT3,
    S_WAIT4,
    S_OUT
  } state_t;

  state_t state, state_next;

  logic [6:0] acc_cnt;  // Accumulation counter
  logic       acc_done;

  // FSM
  //====
  // This state machine controls the data processing, it accepts one data
  // (one sample) from input AXIS interface. Then it will multiply samples (
  // including newly got one the pass samples) with coefficients, accumulate
  // the result together. After it accumulates across required samples (maximum
  // 128), it puts the result to output AXIS interface.

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    // By default, stay at current state
    state_next = state;
    // State tranfer
    case (state)
      S_RST:   state_next = S_IDLE;
      S_IDLE: begin
        if (s_axis_tvalid) begin
          state_next = S_ACC;
        end
      end
      S_ACC: begin
        if (acc_done) begin
          state_next = S_WAIT0;
        end
      end
      S_WAIT0: state_next = S_WAIT1;
      S_WAIT1: state_next = S_WAIT2;
      S_WAIT2: state_next = S_WAIT3;
      S_WAIT3: state_next = S_WAIT4;
      S_WAIT4: state_next = S_OUT;
      S_OUT: begin
        if (m_axis_tready) begin
          state_next = S_IDLE;
        end
      end
      default: state_next = S_RST;
    endcase
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      acc_cnt <= 0;
    end else if (state == S_ACC) begin
      acc_cnt <= acc_cnt + 1;
    end else begin
      acc_cnt <= 0;
    end
  end

  assign acc_done = (acc_cnt == ctrl_coefficient_length);


  // Input AXIS Interface
  //=====================

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      s_axis_tready <= 1'b0;
    end else begin
      s_axis_tready <= (state_next == S_IDLE);
    end
  end


  // Data Storage RAM
  //=================

  logic [          3:0] ch_num;
  logic [          6:0] data_cnt     [16];

  logic [         10:0] data_wr_addr;
  logic                 data_wr_en;
  logic [XIN_WIDTH-1:0] data_wr_din;

  logic [         10:0] data_rd_addr;
  logic                 data_rd_en;
  logic [XIN_WIDTH-1:0] data_rd_dout;

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      data_cnt <= '{16{7'b0}};
    end else if (state == S_IDLE && s_axis_tvalid) begin
      data_cnt[s_axis_tuser] <= data_cnt[s_axis_tuser] + 1;
    end
  end

  // Data write address is built by {channel_number, data_cnt[channel_number]}
  always_ff @(posedge aclk) begin
    if (state == S_IDLE && s_axis_tvalid) begin
      ch_num <= s_axis_tuser;
    end
  end

  // Data write address is built by {channel_number, data_cnt[channel_number]}

  assign data_wr_addr[10:7] = ch_num;

  always_ff @(posedge aclk) begin
    if (state == S_IDLE && s_axis_tvalid) begin
      data_wr_addr[6:0] <= data_cnt[s_axis_tuser];
    end
  end


  always_ff @(posedge aclk) begin
    data_wr_en <= (state == S_IDLE) && s_axis_tvalid;
  end

  always_ff @(posedge aclk) begin
    if (state == S_IDLE && s_axis_tvalid) begin
      data_wr_din <= s_axis_tdata;
    end
  end


  always_ff @(posedge aclk) begin
    data_rd_en <= (state == S_ACC);
  end

  assign data_rd_addr[10:7] = ch_num;

  always_ff @(posedge aclk) begin
    data_rd_addr[6:0] <= data_wr_addr[6:0] - acc_cnt;
  end


  bram_sdp_pipe #(
      .ADDR_WIDTH(11),  // 128 * 16 = 2048
      .DATA_WIDTH(XIN_WIDTH),
      .READ_LATENCY(2)
  ) i_data_ram (
      // Port A
      .clka (aclk),
      .ena  (data_wr_en),
      .wea  (data_wr_en),
      .addra(data_wr_addr),
      .dina (data_wr_din),
      // Port B
      .clkb (aclk),
      .rstb (1'b0),
      .enb  (data_rd_en),
      .addrb(data_rd_addr),
      .doutb(data_rd_dout)
  );


  // Coefficients Store RAM
  //=======================

  logic [          9:0] coe_rd_addr;
  logic                 coe_rd_en;
  logic [COE_WIDTH-1:0] coe_rd_dout;

  // Coefficients read address is built by {coefficient_set, coefficient_number}

  assign coe_rd_addr[9:7] = ctrl_coefficient_set;

  always_ff @(posedge aclk) begin
    if (state == S_ACC) begin
      coe_rd_addr[6:0] <= acc_cnt;
    end else begin
      coe_rd_addr[6:0] <= 0;
    end
  end

  always_ff @(posedge aclk) begin
    coe_rd_en <= (state == S_ACC);
  end


  bram_sdp_pipe #(
      .ADDR_WIDTH(10),  // 128 * 8 = 1024
      .DATA_WIDTH(COE_WIDTH),
      .READ_LATENCY(2)
  ) i_coe_ram (
      // Port A
      .clka (aclk),
      .ena  (ctrl_coe_wr_en),
      .wea  (ctrl_coe_wr_en),
      .addra(ctrl_coe_wr_addr),
      .dina (ctrl_coe_wr_din),
      // Port B
      .clkb (aclk),
      .rstb (1'b0),
      .enb  (coe_rd_en),
      .addrb(coe_rd_addr),
      .doutb(coe_rd_dout)
  );


  // MAC
  //====

  logic        op_in_pre1, op_in_pre2, op_in_pre3;
  logic        op_in;
  logic [47:0] pout;

  always_ff @(posedge aclk) begin
    op_in_pre1 <= (state == S_IDLE) && s_axis_tvalid;
    op_in_pre2 <= op_in_pre1;
    op_in_pre3 <= op_in_pre2;
    op_in      <= op_in_pre3;
  end

  fir_macc_mac #(
      .A_WIDTH(XIN_WIDTH),
      .B_WIDTH(COE_WIDTH),
      .P_WIDTH(48)
  ) i_mac (
      .clk  (aclk),
      //
      .ain  (data_rd_dout),
      .bin  (coe_rd_dout),
      .op_in(op_in),  // 0 = multiply, 1 = MACC
      .pout (pout)
  );


  // Output AXIS
  //============

  always_ff @(posedge aclk) begin
    if (state_next == S_OUT) begin
      m_axis_tdata <= pout[YOUT_WIDTH+SRA_BITS-1:SRA_BITS];
    end
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      m_axis_tvalid <= 1'b0;
    end else begin
      m_axis_tvalid <= (state_next == S_OUT);
    end
  end

  always_ff @(posedge aclk) begin
    if (state_next == S_OUT) begin
      m_axis_tuser <= ch_num;
    end
  end

endmodule

`default_nettype wire

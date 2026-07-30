`timescale 1 ns / 1 ps
//
`default_nettype none

module pdxch_fdv_buffer_readout #(
    parameter int NUM_ANT = 4
) (
    input  wire        clk,
    input  wire        rst,
    // Timer
    input  wire        start_of_frame,
    input  wire        start_of_slot,
    input  wire [ 1:0] start_of_symbol,
    //
    output wire [12:0] rd_addr        [NUM_ANT],
    output wire        rd_en          [NUM_ANT],
    input  wire [31:0] rd_data        [NUM_ANT],
    // Block data output
    output logic  [15:0] dout_dr,
    output logic  [15:0] dout_di,
    output wire        dout_sf,
    output wire        dout_sl,
    output wire        dout_sy,
    output wire [ 3:0] dout_chn,
    output wire        dout_dv,
    output wire        dout_last,
    //
    input  wire [ 3:0] ctrl_en,
    input  wire [ 1:0] ctrl_rat,
    input  wire [ 3:0] ctrl_bist,
    input  wire [ 3:0] ctrl_bw,
    input  wire [ 8:0] ctrl_nprb
);

  // Control signals

  wire  [ 3:0] ctrl_en_s;
  wire  [ 1:0] ctrl_rat_s;
  wire  [ 3:0] ctrl_bist_s;
  wire  [ 3:0] ctrl_bw_s;
  wire  [ 8:0] ctrl_nprb_s;

  wire         unused_ctrl_bist = &{1'b0, ctrl_bist_s[3:2]};

  // Internal signals

  logic        init_n;

  // Count the clock ticks in symbol
  logic [15:0] counter;

  logic        run;
  logic        done;

  logic [ 3:0] phase;
  logic [11:0] index;
  logic [11:0] index_rev;

  logic [11:0] mask;
  logic [11:0] mask_rev;

  logic        last;

  logic        bank;

  logic [11:0] index_mapped;

  // BIST data

  logic [23:0] lfsr;
  wire unused_lfsr = &{1'b0, lfsr[23:2]};

  logic        bist_en_c           [NUM_ANT];
  logic        bist_en_r           [NUM_ANT];
  logic        bist_en_any;
  logic        bist_en_any_d;

  logic [15:0] bist_data_dr;
  logic [15:0] bist_data_di;

  logic        rd_dv;

  logic [12:0] rd_addr_r;
  logic        rd_en_c             [NUM_ANT];
  logic        rd_en_r             [NUM_ANT];
  logic        rd_en_d             [NUM_ANT];
  logic        rd_en_dd            [NUM_ANT];

  logic [31:0] rd_data_c;
  logic [31:0] rd_data_r;

  logic        start_of_symbol_sel;

  logic        dout_sf_req;
  logic        dout_sl_req;
  logic        dout_sy_req;

  logic        dout_sf_r;
  logic        dout_sl_r;
  logic        dout_sy_r;

  //  Control CDC

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (4)
  ) i_cdc_ctrl_en (
      .src_clk (1'b1),
      .src_in  (ctrl_en),
      //
      .dest_clk(clk),
      .dest_out(ctrl_en_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (2)
  ) i_cdc_ctrl_rat (
      .src_clk (1'b1),
      .src_in  (ctrl_rat),
      //
      .dest_clk(clk),
      .dest_out(ctrl_rat_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (4)
  ) i_cdc_ctrl_bist (
      .src_clk (1'b1),
      .src_in  (ctrl_bist),
      //
      .dest_clk(clk),
      .dest_out(ctrl_bist_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (4)
  ) i_cdc_ctrl_bw (
      .src_clk (1'b1),
      .src_in  (ctrl_bw),
      //
      .dest_clk(clk),
      .dest_out(ctrl_bw_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (9)
  ) i_cdc_ctrl_nprb (
      .src_clk (1'b1),
      .src_in  (ctrl_nprb),
      //
      .dest_clk(clk),
      .dest_out(ctrl_nprb_s)
  );

  // Main

  always_comb begin
    if (ctrl_rat_s < 2) begin  // 15 kHz
      start_of_symbol_sel = start_of_symbol[0];
    end else begin  // 30 kHz
      start_of_symbol_sel = start_of_symbol[1];
    end
  end

  // start_of_symbol -> counter
  //                 -> run
  //                 -> phase
  //                 -> index
  //                 -> rd_dv     -> rd_en_c      -> rd_en_r
  //                 -> index_rev -> index_mapped -> rd_addr_r  ->  ... -> rd_data_c -> rd_data_r
  //                              -> bank

  always_ff @(posedge clk) begin
    if (rst) begin
      init_n <= 1'b0;
    end else if (start_of_symbol_sel) begin
      init_n <= 1'b1;
    end
  end

  // Start the counter from first start_of_symbol
  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= '0;
    end else if (start_of_symbol_sel) begin
      counter <= '0;
    end else if (init_n) begin
      counter <= counter + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      run <= 1'b0;
    end else if (start_of_symbol_sel) begin
      run <= 1'b1;
    end else if (done) begin
      run <= 1'b0;
    end
  end

  always_comb begin
    if (ctrl_rat_s < 2) begin  // 15 kHz, 66.667us
      done = &counter[14:0];
    end else begin  // 30 kHz, 33.333us
      done = &counter[13:0];
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      bank <= 1'b0;
    end else if (start_of_frame) begin
      bank <= 1'b0;
    end else if (start_of_symbol_sel) begin
      bank <= ~bank;
    end
  end

  always_comb begin
    case (ctrl_bw_s)
      4'b0000: phase = counter[3:0];  // 7.68 MHz (30.72 MHz)
      4'b0001: phase = counter[3:0];  // 15.36 MHz (30.72 MHz)
      4'b0010: phase = counter[3:0];  // 30.72 MHz
      4'b0011: phase = counter[3:0] & 4'b0111;  // 61.44 MHz
      default: phase = counter[3:0] & 4'b0011;  // 122.88 MHz
    endcase
  end

  always_comb begin
    if (ctrl_rat_s < 2) begin  // 15 kHz
      case (ctrl_bw_s)
        4'b0000: mask = 12'hFFE;  // 7.68 MHz (30.72 MHz) 2k
        4'b0001: mask = 12'hFFE;  // 15.36 MHz (30.72 MHz) 2k
        4'b0010: mask = 12'hFFE;  // 30.72 MHz 2k
        default: mask = 12'hFFF;  // 61.44 MHz 4k
      endcase
    end else begin  // 30 kHz
      case (ctrl_bw_s)
        4'b0000: mask = 12'hFFC;  // 7.68 MHz (30.72 MHz), 1k
        4'b0001: mask = 12'hFFC;  // 15.36 MHz (30.72 MHz), 1k
        4'b0010: mask = 12'hFFC;  // 30.72 MHz, 1k
        4'b0011: mask = 12'hFFE;  // 61.44 MHz, 2k
        default: mask = 12'hFFF;  // 122.88 MHz, 4k
      endcase
    end
  end

  always_comb begin
    for (int i = 0; i < 12; i = i + 1) begin
      mask_rev[i] = mask[11-i];
    end
  end

  always_comb begin
    if (ctrl_rat_s < 2) begin  // 15 kHz
      index = counter[14:3] & mask;
    end else begin  // 30 kHz
      index = counter[13:2] & mask;
    end
  end

  always_comb begin
    for (int i = 0; i < 12; i = i + 1) begin
      index_rev[i] = index[11-i];
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_rat_s == 0 && (index_rev <= ctrl_nprb_s * 6)) begin
      // For LTE, insert DC null on right half of spectrum
      index_mapped <= (index_rev + ctrl_nprb_s * 6 - 1) & mask_rev;
    end else begin
      index_mapped <= (index_rev + ctrl_nprb_s * 6) & mask_rev;
    end
  end

  assign last = (index == mask);

  // BIST data

  generate
    for (genvar ant = 0; ant < NUM_ANT; ant = ant + 1) begin : g_bist

      always_ff @(posedge clk) begin
        bist_en_c[ant] <= run && ctrl_en_s[ant] && ctrl_bist_s[ant] && (phase == 4'(ant))
            && ~(ctrl_rat_s == 0 && (index_rev == 0));
      end

      always_ff @(posedge clk) begin
        bist_en_r[ant] <= bist_en_c[ant] && (index_mapped < ctrl_nprb_s * 12);
      end

    end
  endgenerate

  always_comb begin
    bist_en_any = 1'b0;
    for (int ant = 0; ant < NUM_ANT; ant++) begin
      bist_en_any = bist_en_any | bist_en_r[ant];
    end
  end

  always_ff @(posedge clk) begin
    bist_en_any_d <= bist_en_any;
  end

  lfsr #(
      .BIT_WIDTH      (24),
      .INITIAL        (24'hFFFFFF),
      .POLYNOMIAL     (25'h1C20001),
      .STRUCTURE      ("FIBONACCI"),
      .GATE_TYPE      ("XOR"),
      .PARALLEL_OUTPUT(1'b1)
  ) i_lfsr (
      .clk (clk),
      .rst (rst),
      .en  (bist_en_any),
      .load(1'b0),
      .din (24'b0),
      .dout(lfsr)
  );

  always_ff @(posedge clk) begin
    if (bist_en_any_d) begin
      case (lfsr[1:0])
        2'b00: begin
          bist_data_dr <= 16'sd4210;
          bist_data_di <= 16'sd4210;
        end

        2'b01: begin
          bist_data_dr <= -16'sd4210;
          bist_data_di <= 16'sd4210;
        end

        2'b10: begin
          bist_data_dr <= 16'sd4210;
          bist_data_di <= -16'sd4210;
        end

        default: begin
          bist_data_dr <= -16'sd4210;
          bist_data_di <= -16'sd4210;
        end
      endcase
    end else begin
      bist_data_dr <= 16'sd0;
      bist_data_di <= 16'sd0;
    end
  end

  // RAM data

  always_comb begin
    rd_dv = 1'b0;
    for (int ant = 0; ant < NUM_ANT; ant++) begin
      rd_dv = rd_dv | (run & ctrl_en_s[ant] & (phase == 4'(ant)));
    end
  end

  always_ff @(posedge clk) begin
    rd_addr_r <= {bank, index_mapped};
  end

  generate
    for (genvar ant = 0; ant < NUM_ANT; ant = ant + 1) begin : g_ant

      assign rd_addr[ant] = rd_addr_r;

      always_ff @(posedge clk) begin
        rd_en_c[ant] <= run && ctrl_en_s[ant] && ~ctrl_bist_s[ant] && (phase == 4'(ant))
            && ~(ctrl_rat_s == 0 && (index_rev == 0));
        //        rd_en_c[ant] <= run && ctrl_en[ant] && (phase == 4'(ant))
        //            && ~(ctrl_rat_s == 0 && (index_rev == 0));
      end

      always_ff @(posedge clk) begin
        rd_en_r[ant] <= rd_en_c[ant] && (index_mapped < ctrl_nprb_s * 12);
      end

      always_ff @(posedge clk) begin
        rd_en_d[ant]  <= rd_en_r[ant];
        rd_en_dd[ant] <= rd_en_d[ant];
      end

      assign rd_en[ant] = rd_en_r[ant];

    end
  endgenerate

  // OR them together to get data from correct channel
  always_comb begin
    rd_data_c = '0;
    for (int ant = 0; ant < NUM_ANT; ant++) begin
      rd_data_c = rd_data_c | (rd_en_dd[ant] ? rd_data[ant] : 32'b0);
    end
  end

  always_ff @(posedge clk) begin
    rd_data_r <= rd_data_c | {bist_data_di, bist_data_dr};
  end

  //! Vivado simulator has strange bug here that display 'X'
  always_comb begin
    dout_dr = rd_data_r[15:0];
    dout_di = rd_data_r[31:16];
  end

  // OOB signals

  delay #(
      .WIDTH(3),
      .DEPTH(5)
  ) u_delay_sf (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({start_of_frame, start_of_slot, start_of_symbol_sel}),
      .dout({dout_sf_req, dout_sl_req, dout_sy_req})
  );

  always_ff @(posedge clk) begin
    if (rst) begin
      dout_sy_r <= 1'b0;
    end else if (dout_sy_req) begin
      dout_sy_r <= 1'b1;
    end else if (dout_chn == 4'(NUM_ANT - 1)) begin
      dout_sy_r <= 1'b0;
    end
  end

  assign dout_sy = dout_sy_r;

  always_ff @(posedge clk) begin
    if (rst) begin
      dout_sl_r <= 1'b0;
    end else if (dout_sl_req) begin
      dout_sl_r <= 1'b1;
    end else if (dout_chn == 4'(NUM_ANT - 1)) begin
      dout_sl_r <= 1'b0;
    end
  end

  assign dout_sl = dout_sl_r;

  always_ff @(posedge clk) begin
    if (rst) begin
      dout_sf_r <= 1'b0;
    end else if (dout_sf_req) begin
      dout_sf_r <= 1'b1;
    end else if (dout_chn == 4'(NUM_ANT - 1)) begin
      dout_sf_r <= 1'b0;
    end
  end

  assign dout_sf = dout_sf_r;

  delay #(
      .WIDTH(4),
      .DEPTH(5),
      .INIT (1'b0)
  ) u_delay_chn (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (phase),
      .dout(dout_chn)
  );

  delay #(
      .WIDTH(1),
      .DEPTH(5),
      .INIT (1'b0)
  ) u_delay_dv (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (rd_dv),
      .dout(dout_dv)
  );

  delay #(
      .WIDTH(1),
      .DEPTH(5),
      .INIT (1'b0)
  ) u_delay_last (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (last),
      .dout(dout_last)
  );

endmodule

`default_nettype wire

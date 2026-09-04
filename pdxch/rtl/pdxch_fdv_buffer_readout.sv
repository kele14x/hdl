`timescale 1 ns / 1 ps
//
`default_nettype none

module pdxch_fdv_buffer_readout #(
    parameter int NUM_ANT    = 4,
    parameter int HALF_BLOCK = 0
) (
    input var         clk,
    input var         rst,
    // Timer
    input var         start_of_frame,
    input var         start_of_slot,
    input var  [ 1:0] start_of_symbol,
    //
    output var [11:0] rd_iq_addr     [NUM_ANT],
    output var [11:0] rd_exp_addr    [NUM_ANT],
    output var        rd_en          [NUM_ANT],
    input var  [35:0] rd_iq_data     [NUM_ANT],
    input var  [ 3:0] rd_exp_data    [NUM_ANT],
    // Block data output
    output var [15:0] dout_dr,
    output var [15:0] dout_di,
    output var        dout_sf,
    output var        dout_sl,
    output var        dout_sy,
    output var [ 3:0] dout_chn,
    output var        dout_dv,
    output var        dout_last,
    //
    input var  [ 3:0] ctrl_en,
    input var  [ 1:0] ctrl_rat,
    input var  [ 3:0] ctrl_bist,
    input var  [ 3:0] ctrl_bw,
    input var  [ 8:0] ctrl_nprb,
    input var  [ 3:0] ctrl_fs_offset
);

  localparam int MAX_PRB = (HALF_BLOCK != 0) ? 160 : 275;

  // Control signals

  wire  [ 3:0] ctrl_en_s;
  wire  [ 1:0] ctrl_rat_s;
  wire  [ 3:0] ctrl_bist_s;
  wire  [ 3:0] ctrl_bw_s;
  wire  [ 8:0] ctrl_nprb_s;

  wire  [ 3:0] ctrl_fs_offset_s;
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
  wire         unused_lfsr = &{1'b0, lfsr[23:2]};

  logic        bist_en_c                                    [NUM_ANT];
  logic        bist_en_r                                    [NUM_ANT];
  logic        bist_en_any;
  logic        bist_en_any_d;
  logic        bist_en_any_dd;

  logic [15:0] bist_data_dr;
  logic [15:0] bist_data_di;

  logic        rd_dv;

  logic [11:0] rd_iq_addr_r;
  logic [11:0] rd_exp_addr_r;
  logic        rd_half_r;
  logic        rd_half_d;
  logic        rd_half_dd;
  logic        rd_en_c                                      [NUM_ANT];
  logic        rd_en_r                                      [NUM_ANT];
  logic        rd_en_d                                      [NUM_ANT];
  logic        rd_en_dd                                     [NUM_ANT];

  logic [35:0] rd_iq_data_c;
  logic [ 3:0] rd_exp_data_c;
  logic [17:0] rd_pair_c;
  logic [30:0] rd_expanded_dr_c;
  logic [30:0] rd_expanded_di_c;
  logic [30:0] rd_expanded_dr_r;
  logic [30:0] rd_expanded_di_r;
  logic [15:0] rd_decoded_dr_c;
  logic [15:0] rd_decoded_di_c;
  logic [31:0] rd_data_r;

  logic [11:0] iq_addr_mapped;
  logic [11:0] exp_addr_mapped;
  logic        iq_half_mapped;

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
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
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
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
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
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
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
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
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
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (9)
  ) i_cdc_ctrl_nprb (
      .src_clk (1'b1),
      .src_in  (ctrl_nprb),
      //
      .dest_clk(clk),
      .dest_out(ctrl_nprb_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (4)
  ) i_cdc_ctrl_fs_offset (
      .src_clk (1'b1),
      .src_in  (ctrl_fs_offset),
      //
      .dest_clk(clk),
      .dest_out(ctrl_fs_offset_s)
  );

  function automatic logic [30:0] bfp9_decompress_s1(input logic [8:0] data, input logic [3:0] exp);
    logic signed [30:0] expanded;

    expanded = $signed({data, 22'b0});
    expanded = expanded >>> (15 - int'(exp));
    bfp9_decompress_s1 = expanded;
  endfunction

  function automatic logic [15:0] bfp9_decompress_s2(input logic [30:0] expanded,
                                                     input logic [3:0] fs_offset);
    logic        sign;
    logic [16:0] temp;
    logic [31:0] expanded_g;

    // Full-scale alignment and saturation are the same as the former
    // bfp_decomp implementation, but only the BFP9 path remains here.
    expanded_g = {expanded, 1'b0};
    sign       = expanded[30];
    temp       = expanded_g[31-fs_offset-:17];
    for (int i = 0; i < 15; i++) begin
      if (i < fs_offset && (sign ^ expanded[29-i])) begin
        temp = sign ? 17'h10000 : 17'h0FFFF;
      end
    end
    temp = temp == 17'h0FFFF ? temp : temp + 1'b1;
    bfp9_decompress_s2 = temp[16:1];
  endfunction

  pdxch_fdv_buffer_map #(
      .HALF_BLOCK(HALF_BLOCK)
  ) u_fdv_buffer_map (
      .bank      (bank),
      .logical_re(index_mapped),
      .iq_addr   (iq_addr_mapped),
      .exp_addr  (exp_addr_mapped),
      .iq_half   (iq_half_mapped)
  );

  // Main

  assert property (@(posedge clk) disable iff (rst) (ctrl_nprb_s <= 9'(MAX_PRB)))
  else $error("[%m]: ctrl_nprb (%0d) exceeds MAX_PRB (%0d).", ctrl_nprb_s, MAX_PRB);

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
    bist_en_any_d  <= bist_en_any;
    bist_en_any_dd <= bist_en_any_d;
  end

  lfsr #(
      .BIT_WIDTH      (24),
      .INITIAL        (24'hFFFFFF),
      .POLYNOMIAL     (25'h1C20001),
      .STRUCTURE      ("FIBONACCI"),
      .GATE_TYPE      ("XOR"),
      .PARALLEL_OUTPUT(1)
  ) i_lfsr (
      .clk (clk),
      .rst (rst),
      .en  (bist_en_any),
      .load(1'b0),
      .din (24'b0),
      .dout(lfsr)
  );

  always_ff @(posedge clk) begin
    if (bist_en_any_dd) begin
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
    if (rst) begin
      rd_iq_addr_r  <= '0;
      rd_exp_addr_r <= '0;
      rd_half_r     <= 1'b0;
    end else begin
      rd_iq_addr_r  <= iq_addr_mapped;
      rd_exp_addr_r <= exp_addr_mapped;
      rd_half_r     <= iq_half_mapped;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_half_d  <= 1'b0;
      rd_half_dd <= 1'b0;
    end else begin
      rd_half_d  <= rd_half_r;
      rd_half_dd <= rd_half_d;
    end
  end

  generate
    for (genvar ant = 0; ant < NUM_ANT; ant = ant + 1) begin : g_ant

      assign rd_iq_addr[ant]  = rd_iq_addr_r;
      assign rd_exp_addr[ant] = rd_exp_addr_r;

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
    rd_iq_data_c  = '0;
    rd_exp_data_c = '0;
    for (int ant = 0; ant < NUM_ANT; ant++) begin
      rd_iq_data_c  = rd_iq_data_c | (rd_en_dd[ant] ? rd_iq_data[ant] : 36'b0);
      rd_exp_data_c = rd_exp_data_c | (rd_en_dd[ant] ? rd_exp_data[ant] : 4'b0);
    end
  end

  always_comb begin
    rd_pair_c = rd_half_dd ? rd_iq_data_c[17:0] : rd_iq_data_c[35:18];
    rd_expanded_dr_c = bfp9_decompress_s1(rd_pair_c[17:9], rd_exp_data_c);
    rd_expanded_di_c = bfp9_decompress_s1(rd_pair_c[8:0], rd_exp_data_c);
  end

  always_ff @(posedge clk) begin
    rd_expanded_dr_r <= rd_expanded_dr_c;
    rd_expanded_di_r <= rd_expanded_di_c;
  end

  always_comb begin
    rd_decoded_dr_c = bfp9_decompress_s2(rd_expanded_dr_r, ctrl_fs_offset_s);
    rd_decoded_di_c = bfp9_decompress_s2(rd_expanded_di_r, ctrl_fs_offset_s);
  end

  always_ff @(posedge clk) begin
    rd_data_r <= {rd_decoded_di_c, rd_decoded_dr_c} | {bist_data_di, bist_data_dr};
  end

  //! Vivado simulator has strange bug here that display 'X'
  always_comb begin
    dout_dr = rd_data_r[15:0];
    dout_di = rd_data_r[31:16];
  end

  // OOB signals

  delay #(
      .WIDTH(3),
      .DEPTH(6)
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
      .DEPTH(6)
  ) u_delay_chn (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (phase),
      .dout(dout_chn)
  );

  delay #(
      .WIDTH(1),
      .DEPTH(6)
  ) u_delay_dv (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (rd_dv),
      .dout(dout_dv)
  );

  delay #(
      .WIDTH(1),
      .DEPTH(6)
  ) u_delay_last (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (last),
      .dout(dout_last)
  );

endmodule

`default_nettype wire

`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_mux (
    // Data from JESD
    //---------------
    input var          clk_jesd,
    input var          rst_jesd_n,
    //
    input var  [255:0] avst_sink_data,
    input var          avst_sink_valid,
    input var  [  7:0] avst_sink_channel,
    // Output
    //-------
    input var          clk_dsp,
    input var          rst_dsp_n,
    // Sync
    input var          sync_in,
    //
    output var [ 15:0] dout_dr          [3],
    output var [ 15:0] dout_di          [3],
    output var         dout_dv,
    output var [  7:0] dout_chn,
    output var         sync_out,
    // CSR
    //----
    input var          clk_csr,
    input var          rst_csr_n,
    //
    input var  [  3:0] ctrl_bwby10      [8][3]
);


  // Data from JESD:
  //
  // Lane0: [255:192]
  // Lane1: [191:128]
  // Lane2: [127: 64]
  // Lane3: [ 63:  0]

  logic [255:0] mem           [3] [16];

  logic [  3:0] wr_addr       [3];
  logic [255:0] wr_data;
  logic         wr_en         [3];

  logic [  3:0] rd_addr       [3];
  logic [255:0] rd_data       [3];
  logic         rd_en         [3];

  logic         rst_jesd_n_d1;
  logic         rst_jesd_n_d2;
  logic         rst_jesd_n_d3;

  // Both JESD reset and avst valid should be CDC to DSP clock domain for
  // proper sync handlding

  logic         rst_jesd_n_s1;
  logic         rst_jesd_n_s2;
  logic         rst_jesd_n_s3;
  logic         rst_jesd_n_s4;

  logic         avst_sink_valid_s1;
  logic         avst_sink_valid_s2;
  logic         avst_sink_valid_s3;
  logic         avst_sink_valid_s4;

  logic [  3:0] cnt;
  logic [  3:0] cnt_d;

  logic         dout_dv_pre1;

  logic         sync_req;
  logic         sync_pre1;


  // Write side

  always_ff @(posedge clk_jesd) begin
    rst_jesd_n_d1 <= rst_jesd_n;
    rst_jesd_n_d2 <= rst_jesd_n_d1;
    rst_jesd_n_d3 <= rst_jesd_n_d2;
  end

  // TODO: JESD lane/ant/cc/iq/byte mapping
  assign wr_data = avst_sink_data;

  generate
    for (genvar i = 0; i < 3; i++) begin : g_wr

      always_ff @(posedge clk_jesd) begin
        if (~rst_jesd_n_d3) begin
          wr_addr[i] <= 4'b1000;
        end else if (wr_en[i]) begin
          wr_addr[i] <= wr_addr[i] + 1;
        end
      end

      assign wr_en[i] = avst_sink_valid && (avst_sink_channel == i);

    end
  endgenerate

  // mem

  generate
    for (genvar i = 0; i < 3; i++) begin : g_ram

      initial begin
        for (int j = 0; j < 16; j++) begin
          mem[i][j] = '0;
        end
      end

      always_ff @(posedge clk_jesd) begin
        if (wr_en[i]) begin
          mem[i][wr_addr[i]] <= wr_data;
        end
      end

      always_ff @(posedge clk_dsp) begin
        if (rd_en[i]) begin
          rd_data[i] <= mem[i][rd_addr[i]];
        end
      end

    end
  endgenerate

  // Read side

  always_ff @(posedge clk_dsp) begin
    rst_jesd_n_s1 <= rst_jesd_n_d2;
    rst_jesd_n_s2 <= rst_jesd_n_s1;
    rst_jesd_n_s3 <= rst_jesd_n_s2;
    rst_jesd_n_s4 <= rst_jesd_n_s3;
  end

  always_ff @(posedge clk_dsp) begin
    if (~rst_jesd_n_s4) begin
      avst_sink_valid_s1 <= 1'b0;
      avst_sink_valid_s2 <= 1'b0;
      avst_sink_valid_s3 <= 1'b0;
      avst_sink_valid_s3 <= 1'b0;
    end else begin
      avst_sink_valid_s1 <= avst_sink_valid;
      avst_sink_valid_s2 <= avst_sink_valid_s1;
      avst_sink_valid_s3 <= avst_sink_valid_s2;
      avst_sink_valid_s4 <= avst_sink_valid_s3;
    end
  end

  generate
    for (genvar i = 0; i < 3; i++) begin : g_rd

      always_ff @(posedge clk_dsp) begin
        if (~rst_jesd_n_s4) begin
          rd_addr[i] <= 4'b0000;
        end else if (rd_en[i]) begin
          rd_addr[i] <= rd_addr[i] + 1;
        end
      end

      assign rd_en[i] = avst_sink_valid_s4 && (cnt == 0);

    end
  endgenerate

  generate
    for (genvar i = 0; i < 3; i++) begin : g_dout

      always_ff @(posedge clk_dsp) begin
        if (cnt_d == 0) begin
          {dout_di[i], dout_dr[i]} <= rd_data[i][255:224];
        end else if (cnt_d == 1) begin
          {dout_di[i], dout_dr[i]} <= rd_data[i][223:192];
        end else if (cnt_d == 2) begin
          {dout_di[i], dout_dr[i]} <= rd_data[i][191:160];
        end else if (cnt_d == 3) begin
          {dout_di[i], dout_dr[i]} <= rd_data[i][159:128];
        end else if (cnt_d == 4) begin
          {dout_di[i], dout_dr[i]} <= rd_data[i][127:96];
        end else if (cnt_d == 5) begin
          {dout_di[i], dout_dr[i]} <= rd_data[i][95:64];
        end else if (cnt_d == 6) begin
          {dout_di[i], dout_dr[i]} <= rd_data[i][63:32];
        end else if (cnt_d == 7) begin
          {dout_di[i], dout_dr[i]} <= rd_data[i][31:0];
        end else begin
          {dout_di[i], dout_dr[i]} <= '0;
        end
      end

    end
  endgenerate

  // Output sync & chn

  // Output sampling rate is 61.44, 8 antennas' data are time interleaved
  always_ff @(posedge clk_dsp) begin
    if (~rst_jesd_n_s4) begin
      cnt <= '0;
    end else if (avst_sink_valid_s4) begin
      cnt <= cnt + 1;
    end
  end

  always_ff @(posedge clk_dsp) begin
    cnt_d <= cnt;
  end

  // Sync pulse to be align with first tick of frame

  always_ff @(posedge clk_dsp) begin
    if (sync_in && cnt != 0) begin
      sync_req <= 1'b1;
    end else if (cnt == 0) begin
      sync_req <= 1'b0;
    end
  end

  always_ff @(posedge clk_dsp) begin
    if (sync_in && cnt == 0) begin
      sync_pre1 <= 1'b1;
    end else if (sync_req && cnt == 0) begin
      sync_pre1 <= 1'b1;
    end else begin
      sync_pre1 <= 1'b0;
    end
    sync_out <= sync_pre1;
  end

  always_ff @(posedge clk_dsp) begin
    dout_dv_pre1 <= avst_sink_valid_s4;
    dout_dv      <= dout_dv_pre1;
  end

  always_ff @(posedge clk_dsp) begin
    dout_chn <= {5'b0, cnt_d[2:0]};
  end

endmodule

`default_nettype wire

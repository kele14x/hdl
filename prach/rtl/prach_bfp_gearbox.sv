`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_bfp_gearbox #(
    parameter int USER_WIDTH = 32
) (
    input var                   clk,
    input var                   rst,
    // A start pulse launches one packet containing num_prb PRBs.
    input var                   start,
    input var  [           6:0] num_prb,
    input var  [USER_WIDTH-1:0] start_tuser,
    output var                  busy,
    output var                  done,
    // READ_LATENCY=2 ram_sdp interfaces. en[0] samples the address and
    // en[1] flushes the RAM output register one clock later.
    output var [           1:0] data_rd_en,
    output var [           8:0] data_rd_addr,
    input var  [          35:0] data_rd_data,
    output var [           1:0] exp_rd_en,
    output var [           6:0] exp_rd_addr,
    input var  [           3:0] exp_rd_data,
    // Packed BFP9 stream.
    output var [          63:0] m_axis_tdata,
    output var [           7:0] m_axis_tkeep,
    output var                  m_axis_tlast,
    output var [USER_WIDTH-1:0] m_axis_tuser,
    output var                  m_axis_tvalid
);

  initial begin : drc_check
    assert (USER_WIDTH >= 1)
    else $error("[%m]: USER_WIDTH (%0d) must be at least 1.", USER_WIDTH);
  end

  logic [           9:0] total_words;
  logic [           9:0] request_count;
  logic [           9:0] consume_count;
  logic [           2:0] request_word_in_prb;
  logic [           6:0] request_prb;
  logic                  read_active;
  logic                  data_req;
  logic                  data_req_d1;
  logic                  data_req_d2;
  logic                  exp_req;
  logic                  exp_req_d1;
  logic                  exp_req_d2;
  logic                  input_eop;

  logic [           3:0] t6_cnt;
  logic [          63:0] t6_data;
  logic [          63:0] t6_data_f;
  logic [USER_WIDTH-1:0] t6_user;
  logic                  t6_valid;
  logic                  t6_eop;
  logic                  t6_eop_ext;
  logic [          63:0] t6_eop_data;
  logic [USER_WIDTH-1:0] t6_eop_user;
  logic                  t6_eop_ext_out;

  function automatic logic [63:0] byte_reverse(input logic [63:0] din);
    for (int i = 0; i < 8; i++) begin
      byte_reverse[63-8*i-:8] = din[8*i+7-:8];
    end
  endfunction

  always_comb begin
    data_req = read_active && (request_count < total_words);
    exp_req = data_req && (request_word_in_prb == 0);
    data_rd_en = {data_req_d1, data_req};
    exp_rd_en = {exp_req_d1, exp_req};
    data_rd_addr = request_count[8:0];
    exp_rd_addr = request_prb;
    input_eop = data_req_d2 && (consume_count == total_words - 1'b1);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      total_words         <= '0;
      request_count       <= '0;
      consume_count       <= '0;
      request_word_in_prb <= '0;
      request_prb         <= '0;
      read_active         <= 1'b0;
      data_req_d1         <= 1'b0;
      data_req_d2         <= 1'b0;
      exp_req_d1          <= 1'b0;
      exp_req_d2          <= 1'b0;
    end else begin
      data_req_d1 <= data_req;
      data_req_d2 <= data_req_d1;
      exp_req_d1  <= exp_req;
      exp_req_d2  <= exp_req_d1;

      if (start) begin
        total_words         <= num_prb * 6;
        request_count       <= '0;
        consume_count       <= '0;
        request_word_in_prb <= '0;
        request_prb         <= '0;
        read_active         <= 1'b1;
        data_req_d1         <= 1'b0;
        data_req_d2         <= 1'b0;
        exp_req_d1          <= 1'b0;
        exp_req_d2          <= 1'b0;
      end else begin
        if (data_req) begin
          request_count <= request_count + 1'b1;
          if (request_word_in_prb == 5) begin
            request_word_in_prb <= '0;
            request_prb <= request_prb + 1'b1;
          end else begin
            request_word_in_prb <= request_word_in_prb + 1'b1;
          end
          if (request_count == total_words - 1'b1) begin
            read_active <= 1'b0;
          end
        end
        if (data_req_d2) begin
          consume_count <= consume_count + 1'b1;
        end
      end

`ifndef SYNTHESIS
      if (start) begin
        assert (!busy)
        else $error("[%m]: start asserted while the gearbox is busy.");
        assert (num_prb >= 1 && num_prb <= 72)
        else $error("[%m]: num_prb %0d must be between 1 and 72.", num_prb);
      end
      if (data_req) begin
        assert (data_rd_addr <= 431)
        else $error("[%m]: data RAM address %0d is out of range.", data_rd_addr);
      end
      if (exp_req) begin
        assert (exp_rd_addr <= 71)
        else $error("[%m]: exponent RAM address %0d is out of range.", exp_rd_addr);
      end
      if (data_req_d2 && ((t6_cnt == 0) || (t6_cnt == 6))) begin
        assert (exp_req_d2)
        else $error("[%m]: exponent and D0 did not return together.");
      end
`endif
    end
  end

  // The input words use the same 0..11 count and residue handling as the r6
  // stage in bfp_comp. The seven output words therefore match W0..W6 exactly.
  always_ff @(posedge clk) begin
    if (rst || start) begin
      t6_cnt <= '0;
    end else if (data_req_d2 && input_eop) begin
      t6_cnt <= '0;
    end else if (data_req_d2) begin
      t6_cnt <= (t6_cnt == 11) ? '0 : t6_cnt + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      t6_user <= '0;
    end else if (start) begin
      t6_user <= start_tuser;
    end
  end

  always_ff @(posedge clk) begin
    if (rst || start) begin
      t6_eop_ext <= 1'b0;
    end else begin
      t6_eop_ext <= data_req_d2 && input_eop && (t6_cnt == 5);
    end
  end

  always_ff @(posedge clk) begin
    if (rst || start) begin
      t6_eop_data    <= '0;
      t6_eop_user    <= '0;
      t6_eop_ext_out <= 1'b0;
    end else begin
      t6_eop_ext_out <= t6_eop_ext;
      if (t6_eop_ext) begin
        t6_eop_data <= {t6_data_f[63:32], 32'b0};
        t6_eop_user <= t6_user;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rst || start) begin
      t6_data <= '0;
    end else if (data_req_d2) begin
      case (t6_cnt)
        0:       t6_data[63:20] <= {4'b0, exp_rd_data, data_rd_data};
        1:       t6_data[19:0] <= data_rd_data[35:16];
        2:       t6_data[63:12] <= {t6_data_f[63:48], data_rd_data};
        3:       t6_data[11:0] <= data_rd_data[35:24];
        4:       t6_data[63:4] <= {t6_data_f[63:40], data_rd_data};
        5:       t6_data[3:0] <= data_rd_data[35:32];
        6:       t6_data <= {t6_data_f[63:32], 4'b0, exp_rd_data, data_rd_data[35:12]};
        7:       t6_data[63:16] <= {t6_data_f[63:52], data_rd_data};
        8:       t6_data[15:0] <= data_rd_data[35:20];
        9:       t6_data[63:8] <= {t6_data_f[63:44], data_rd_data};
        10:      t6_data[7:0] <= data_rd_data[35:28];
        11:      t6_data <= {t6_data_f[63:36], data_rd_data};
        default: t6_data <= t6_data;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (rst || start) begin
      t6_data_f <= '0;
    end else if (data_req_d2) begin
      case (t6_cnt)
        1:       t6_data_f[63:48] <= data_rd_data[15:0];
        3:       t6_data_f[63:40] <= data_rd_data[23:0];
        5:       t6_data_f[63:32] <= data_rd_data[31:0];
        6:       t6_data_f[63:52] <= data_rd_data[11:0];
        8:       t6_data_f[63:44] <= data_rd_data[19:0];
        10:      t6_data_f[63:36] <= data_rd_data[27:0];
        default: t6_data_f <= t6_data_f;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (rst || start) begin
      t6_valid <= 1'b0;
      t6_eop   <= 1'b0;
    end else begin
      t6_valid <= (data_req_d2 && input_eop && (t6_cnt != 5)) ||
        (data_req_d2 && (t6_cnt == 1 || t6_cnt == 3 || t6_cnt == 5 || t6_cnt == 6 ||
                         t6_cnt == 8 || t6_cnt == 10 || t6_cnt == 11));
      t6_eop <= data_req_d2 && input_eop && (t6_cnt != 5);
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      busy          <= 1'b0;
      done          <= 1'b0;
      m_axis_tdata  <= '0;
      m_axis_tkeep  <= '0;
      m_axis_tlast  <= 1'b0;
      m_axis_tuser  <= '0;
      m_axis_tvalid <= 1'b0;
    end else begin
      done <= 1'b0;
      if (start) begin
        busy <= 1'b1;
      end
      if (t6_eop_ext_out) begin
        m_axis_tdata  <= byte_reverse(t6_eop_data);
        m_axis_tkeep  <= 8'h0F;
        m_axis_tlast  <= 1'b1;
        m_axis_tuser  <= t6_eop_user;
        m_axis_tvalid <= 1'b1;
        busy          <= 1'b0;
        done          <= 1'b1;
      end else if (t6_valid) begin
        m_axis_tdata  <= byte_reverse(t6_data);
        m_axis_tkeep  <= 8'hFF;
        m_axis_tlast  <= t6_eop;
        m_axis_tuser  <= t6_user;
        m_axis_tvalid <= 1'b1;
        if (t6_eop) begin
          busy <= 1'b0;
          done <= 1'b1;
        end
      end else begin
        m_axis_tvalid <= 1'b0;
      end
    end
  end

endmodule

`default_nettype wire

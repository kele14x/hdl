// File: dl_adaptor_buffer.sv
// Brief: Downlink PDxCH (DL U-Plane data) adaptor buffer.
`timescale 1 ns / 1 ps `default_nettype none

module dl_adaptor_writer (
    // Interface with DFE
    //===================
    input var         clk,
    input var         rst,
    // Separated CCs
    output var        gb_sof,
    output var        gb_sos,
    output var [63:0] gb_data,
    output var        gb_valid,
    output var [11:0] gb_re,  // 0 ~
    //
    output var [63:0] wr_data,
    output var [11:0] wr_addr,
    output var        wr_en
);

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_addr[11] <= 0;
    end else if (gb_sof) begin
      wr_addr[11] <= 0;
    end else if (gb_sos) begin
      wr_addr[11] <= ~wr_addr[11];
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_addr[10:0] <= 0;
    end else if (gb_valid) begin
      wr_addr[10:0] <= gb_re[11:1];  // lsb is assumed to be 0 and ignored
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_en <= '0;
    end else begin
      wr_en <= gb_valid;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_data <= '0;
    end else if (gb_valid) begin
      wr_data <= gb_data;
    end
  end

endmodule

`default_nettype wire

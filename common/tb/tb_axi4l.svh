// AXI Helpers for test bench

`define ADDR_WIDTH 32
`define DATA_WIDTH 32

`define ACLK s_axi_aclk
`define ARESETN s_axi_aresetn
//
`define AWADDR s_axi_awaddr
`define AWPROT s_axi_awprot
`define AWVALID s_axi_awvalid
`define AWREADY s_axi_awready
//
`define WDATA s_axi_wdata
`define WSTRB s_axi_wstrb
`define WVALID s_axi_wvalid
`define WREADY s_axi_wready
//
`define BRESP s_axi_bresp
`define BVALID s_axi_bvalid
`define BREADY s_axi_bready
//
`define ARADDR s_axi_araddr
`define ARPROT s_axi_arprot
`define ARVALID s_axi_arvalid
`define ARREADY s_axi_arready
//
`define RDATA s_axi_rdata
`define RRESP s_axi_rresp
`define RVALID s_axi_rvalid
`define RREADY s_axi_rready


function static void axi_reset();
  `AWADDR  = 0;
  `AWPROT  = 0;
  `AWVALID = 0;

  `WDATA   = 0;
  `WSTRB   = 0;
  `WVALID  = 0;

  `BREADY  = 0;

  `ARADDR  = 0;
  `ARPROT  = 0;
  `ARVALID = 0;

  `RREADY  = 0;
endfunction

task static axi_write(input logic [`ADDR_WIDTH-1:0] addr, input logic [`DATA_WIDTH-1:0] data);
  fork
    begin
      `AWADDR  <= addr;
      `AWPROT  <= 0;
      `AWVALID <= 1;
      forever @(posedge `ACLK) if (`AWREADY) break;
      `AWVALID <= 0;
    end

    begin
      `WDATA  <= data;
      `WSTRB  <= '1;
      `WVALID <= 1;
      forever @(posedge `ACLK) if (`WREADY) break;
      `WVALID <= 0;
    end

    begin
      `BREADY <= 1;
      forever @(posedge `ACLK) if (`BVALID) break;
      `BREADY <= 0;
      if (`BRESP != 0) $warning("AXI write error %x", `BRESP);
    end
  join
  $display("AXI write: address = 0x%x, data = 0x%x", addr, data);
endtask

task static axi_read(input logic [`ADDR_WIDTH-1:0] addr, output logic [`DATA_WIDTH-1:0] data);
  fork
    begin
      `ARADDR  <= addr;
      `ARPROT  <= 0;
      `ARVALID <= 1;
      forever @(posedge `ACLK) if (`ARREADY) break;
      `ARVALID <= 0;
    end

    begin
      `RREADY <= 1;
      forever @(posedge `ACLK) if (`RVALID) break;
      `RREADY <= 0;
      data = `RDATA;
      if (`RRESP != 0) $warning("AXI read error %x", `RRESP);
    end
  join
  $display("AXI read: address = 0x%x, data = 0x%x", addr, data);
endtask

// File: axi4l_if.sv
// Brief: Interface of AXI4-Lite interface. Beside signal's declaration, it
//        provides some simulation only function for easy operation this
//        interface. Note the virtual part of interface is not synthesizable.
`timescale 1 ns / 1 ps `default_nettype none

interface axi4l_if #(
    parameter int C_ADDR_WIDTH = 32,
    parameter int C_DATA_WIDTH = 32
) (
    input var aclk,
    input var aresetn
);

  localparam int MAX_WAIT = 16;

  logic [  C_ADDR_WIDTH-1:0] awaddr;
  logic [               2:0] awprot;
  logic                      awvalid;
  logic                      awready;
  //
  logic [  C_DATA_WIDTH-1:0] wdata;
  logic [C_DATA_WIDTH/8-1:0] wstrb;
  logic                      wvalid;
  logic                      wready;
  //
  logic [               1:0] bresp;
  logic                      bvalid;
  logic                      bready;
  //
  logic [  C_ADDR_WIDTH-1:0] araddr;
  logic [               2:0] arprot;
  logic                      arvalid;
  logic                      arready;
  //
  logic [  C_DATA_WIDTH-1:0] rdata;
  logic [               1:0] rresp;
  logic                      rvalid;
  logic                      rready;

  modport master(
      input aclk, aresetn, awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid,
      output awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready, araddr, arprot, arvalid, rready
  );

  modport slave(
      input aclk, aresetn, awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready, araddr, arprot, arvalid, rready,
      output awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid
  );


  // Interface function mode
  //------------------------
  //
  // Master mode: `intf_is_master` = 1 and `intf_is_slave` = 0
  //   In this mode, the interface will behave like a AXI4-Lite master. Which
  //   means it will drive the signal such as `awaddr` `awprot` and `awvalid`,
  //   and will listen to `awready` (same goes to other AXI4 sub channel).
  //   Since the interface itself is a master, you can't use it to connect two
  //   module instance, or connect it to another AXI4 master. If do so,
  //   multi-driven condition is issued and the final value is determined by
  //   the language standard itself. Note that multi-driven is only possible in
  //   simulation. It does not match real hardware behavior and will produce a
  //   critical error when during tool's implementation stage.
  //
  // Slave mode: `intf_is_master` = 0 and `intf_is_slave` = 1
  //   In this mode, the interface will behave like a AXI4-Lite slave. Which
  //   means it will listen to `awaddr` `awprot` and `awvalid`, and will drive
  //   `awready` (same goes to other AXI4 sub channel). Like master mode, you
  //   can use it to connect two module instance, or connect it to another AXI4
  //   slave.
  //
  // Monitor mode: `intf_is_master` = 0 and `intf_is_slave` = 0
  //   In this mode, the interface will try to listen to all the signals (drive
  //   all signals to 'z'). In result, it will not affect the signal's value if
  //   there is another driver drives the signal. It can be used to connect two
  //   module instance.

  logic                      intf_is_master = 0;
  logic                      intf_is_slave = 0;

  // AXI4-Lite internal signals
  //---------------------------

  logic [  C_ADDR_WIDTH-1:0] awaddr_s;
  logic [               2:0] awprot_s;
  logic                      awvalid_s;
  logic                      awready_s;
  //
  logic [  C_DATA_WIDTH-1:0] wdata_s;
  logic [C_DATA_WIDTH/8-1:0] wstrb_s;
  logic                      wvalid_s;
  logic                      wready_s;
  //
  logic [               1:0] bresp_s;
  logic                      bvalid_s;
  logic                      bready_s;
  //
  logic [  C_ADDR_WIDTH-1:0] araddr_s;
  logic [               2:0] arprot_s;
  logic                      arvalid_s;
  logic                      arready_s;
  //
  logic [  C_DATA_WIDTH-1:0] rdata_s;
  logic [               1:0] rresp_s;
  logic                      rvalid_s;
  logic                      rready_s;

  assign awaddr  = intf_is_master ? awaddr_s : 'z;
  assign awprot  = intf_is_master ? awprot_s : 'z;
  assign awvalid = intf_is_master ? awvalid_s : 'z;
  assign awready = intf_is_slave ? awready_s : 'z;
  //
  assign wdata   = intf_is_master ? wdata_s : 'z;
  assign wstrb   = intf_is_master ? wstrb_s : 'z;
  assign wvalid  = intf_is_master ? wvalid_s : 'z;
  assign wready  = intf_is_slave ? wready_s : 'z;
  //
  assign bresp   = intf_is_slave ? bresp_s : 'z;
  assign bvalid  = intf_is_slave ? bvalid_s : 'z;
  assign bready  = intf_is_master ? bready_s : 'z;
  //
  assign araddr  = intf_is_master ? araddr_s : 'z;
  assign arprot  = intf_is_master ? arprot_s : 'z;
  assign arvalid = intf_is_master ? arvalid_s : 'z;
  assign arready = intf_is_slave ? arready_s : 'z;
  //
  assign rdata   = intf_is_slave ? rdata_s : 'z;
  assign rresp   = intf_is_slave ? rresp_s : 'z;
  assign rvalid  = intf_is_slave ? rvalid_s : 'z;
  assign rready  = intf_is_master ? rready_s : 'z;

  // Public APIs
  //------------

  function automatic void set_intf_master();
    intf_is_master = 1;
    intf_is_slave  = 0;
  endfunction

  function automatic void set_intf_slave();
    intf_is_master = 0;
    intf_is_slave  = 1;
  endfunction

  function automatic void set_intf_monitor();
    intf_is_master = 0;
    intf_is_slave  = 0;
  endfunction

  function automatic void reset();
    awaddr_s  <= 0;
    awprot_s  <= 0;
    awvalid_s <= 0;
    awready_s <= 0;
    //
    wdata_s   <= 0;
    wstrb_s   <= 0;
    wvalid_s  <= 0;
    wready_s  <= 0;
    //
    bresp_s   <= 0;
    bvalid_s  <= 0;
    bready_s  <= 0;
    //
    araddr_s  <= 0;
    arprot_s  <= 0;
    arvalid_s <= 0;
    arready_s <= 0;
    //
    rdata_s   <= 0;
    rresp_s   <= 0;
    rvalid_s  <= 0;
    rready_s  <= 0;
  endfunction

  task master_write(input logic [C_ADDR_WIDTH-1:0] addr, input logic [C_DATA_WIDTH-1:0] data);
    @(posedge aclk);
    awaddr_s  <= addr;
    awprot_s  <= 0;
    awvalid_s <= 1;
    //
    wdata_s   <= data;
    wstrb_s   <= 1;
    wvalid_s  <= 1;
    //
    bready    <= 1;
    //
    araddr_s  <= 0;
    arprot_s  <= 0;
    arvalid_s <= 0;
    //
    rready_s  <= 0;
    //
    fork
      begin : p_wait_awready
        repeat (16)
          @(posedge aclk) begin
            if (awready) begin
              awaddr_s  <= 0;
              awprot_s  <= 0;
              awvalid_s <= 0;
              break;
            end
          end
      end

      begin : p_wait_wready
        repeat (16)
          @(posedge aclk) begin
            if (wready) begin
              wdata_s  <= 0;
              wstrb_s  <= 0;
              wvalid_s <= 0;
              break;
            end
          end
      end

      begin : p_wait_bresp
        repeat (16)
          @(posedge aclk) begin
            if (bvalid) begin
              bready_s <= 0;
              break;
            end
          end
      end
    join
  endtask

 task master_read(input logic [C_ADDR_WIDTH-1:0] addr, output logic [C_DATA_WIDTH-1:0] data);
   @(posedge aclk);
   awaddr_s  <= 0;
   awprot_s  <= 0;
   awvalid_s <= 0;
   //
   wdata_s   <= 0;
   wstrb_s   <= 1;
   wvalid_s  <= 0;
   //
   bready    <= 0;
   //
   araddr_s  <= addr;
   arprot_s  <= 0;
   arvalid_s <= 1;
   //
   rready_s  <= 1;
   //
   fork
     begin : p_wait_arready
       repeat (16)
         @(posedge aclk) begin
           if (arready) begin
             araddr_s  <= 0;
             arprot_s  <= 0;
             arvalid_s <= 0;
             break;
           end
         end
     end

     begin : p_wait_rdata
       repeat (16)
         @(posedge aclk) begin
           if (rvalid) begin
             // data      = rdata;
             rready_s <= 0;
             break;
           end
         end
     end
   join
 endtask

endinterface  // axi4l_if

`default_nettype wire

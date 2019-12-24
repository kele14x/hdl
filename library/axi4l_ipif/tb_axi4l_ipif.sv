`timescale 1 ns / 100 ps

module tb_axi4l_ipif ();

    logic aclk    = 0;
    logic aresetn = 0;
    //
    logic [31:0] s_axi_awaddr  = 0;
    logic [ 2:0] s_axi_awprot  = 0;
    logic        s_axi_awvalid = 0;
    logic        s_axi_awready = 0;
    //
    logic [31:0] s_axi_wdata  = 0;
    logic [ 3:0] s_axi_wstrb  = 0;
    logic        s_axi_wvalid = 0;
    logic        s_axi_wready = 0;
    //
    logic [1:0] s_axi_bresp  = 0;
    logic       s_axi_bvalid = 0;
    logic       s_axi_bready = 0;
    //
    logic [31:0] s_axi_araddr  = 0;
    logic [ 2:0] s_axi_arprot  = 0;
    logic        s_axi_arvalid = 0;
    logic        s_axi_arready = 0;
    //
    logic [31:0] s_axi_rdata  = 0;
    logic [ 1:0] s_axi_rresp  = 0;
    logic        s_axi_rvalid = 0;
    logic        s_axi_rready = 0;

    always #5 aclk = ~aclk;


    //-------------------------------------------------------------------------
    // Task: reset_slave_and_interface
    // Brief: Reset the DUT and all input signal to DUT
    //-------------------------------------------------------------------------

    task reset_slave_and_interface();
        @(posedge aclk);
        aresetn <= 0;
        s_axi_awaddr  <= 0;
        s_axi_awprot  <= 0;
        s_axi_awvalid <= 0;
        s_axi_wdata   <= 0;
        s_axi_wstrb   <= 0;
        s_axi_wvalid  <= 0;
        s_axi_bready  <= 0;
        s_axi_araddr  <= 0;
        s_axi_arprot  <= 0;
        s_axi_arvalid <= 0;
        s_axi_rready  <= 0;
        repeat(16) @(posedge aclk);
        @(posedge aclk) aresetn <= 1;
    endtask;


    //-------------------------------------------------------------------------
    // Task: test_single_write_same_time
    // Brief: Test if DUT can accept signal AXI write. Only write response is
    //        checked. No write effect is checked.
    //-------------------------------------------------------------------------

    task test_single_write_same_time();
        reg awok, wok, bok;
        awok = 0;
        wok = 0;
        bok = 0;
        reset_slave_and_interface();

        @(posedge aclk);
        s_axi_awaddr  <= 32'h0000_0004;
        s_axi_awvalid <= 1'b1;
        s_axi_wdata   <= 32'hABCD_EF01;
        s_axi_wstrb   <= 4'b1111;
        s_axi_wvalid  <= 1'b1;
        s_axi_bready  <= 1'b1;

        repeat (16) begin
            @(posedge aclk);
            if (s_axi_awready) begin
                awok = 1;
                s_axi_awvalid <= 1'b0;
            end
            if (s_axi_wready) begin
                wok = 1;
                s_axi_wvalid <= 1'b0;
            end
            if (s_axi_bvalid) begin
                bok = 1;
                s_axi_bready <= 1'b0;
            end
            if (awok && wok && bok) begin
                $info("%t, Test \"test_single_write_sampe_time\" success.", $time);
                return;
            end
        end
        $warning("%t, Test \"test_single_write_sampe_time\" fail.", $time());
    endtask;


    //-------------------------------------------------------------------------
    // Task: test_single_write_address_before_data
    // Brief: Test if DUT can accept signal AXI write. Write address is assert
    //        before data. Only write response is checked. No write effect is
    //        checked.
    //-------------------------------------------------------------------------

    task test_single_write_address_before_data();
        reg awok, wok, bok;
        awok = 0;
        wok = 0;
        bok = 0;

        reset_slave_and_interface();
        
        fork
            begin
                @(posedge aclk);
                s_axi_awaddr  <= 32'h0000_0004;
                s_axi_awvalid <= 1'b1;
                repeat (16) begin
                    @(posedge aclk);
                    if (s_axi_awready) begin
                        awok = 1;
                        s_axi_awvalid <= 1'b0;
                        break;
                    end
                end
            end
            
            begin
                @(posedge aclk);
                @(posedge aclk);
                s_axi_wdata   <= 32'hABCD_EF01;
                s_axi_wstrb   <= 4'b1111;
                s_axi_wvalid  <= 1'b1;
                repeat (16) begin
                    @(posedge aclk);
                    if (s_axi_wready) begin
                        wok = 1;
                        s_axi_wvalid <= 1'b0;
                        break;
                    end
                end
            end
            
            begin
                @(posedge aclk);
                s_axi_bready  <= 1'b1;
                repeat (16) begin
                    @(posedge aclk);
                    if (s_axi_bvalid) begin
                        bok = 1;
                        s_axi_bready <= 1'b0;
                        break;
                    end
                end
            end
        join

        if (awok && wok && bok) begin
            $info("%t, Test \"test_single_write_address_before_data\" success.", $time());
        end else begin
            $warning("%t, Test \"test_single_write_address_before_data\" fail.", $time());
        end
    endtask;


    initial begin
        $display("%t, simulation ends.", $time());

        #1000;
        test_single_write_same_time();
        #1000;
        test_single_write_address_before_data();
        #1000;

        $finish();
    end

    final begin
        $display("%t, simulation ends.", $time());
    end

    axi4l_ipif UUT (.*);

endmodule

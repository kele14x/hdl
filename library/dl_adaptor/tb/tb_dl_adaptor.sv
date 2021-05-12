`timescale 1 ns / 1 ps `default_nettype none

module tb_dl_adaptor ();

    parameter int NUM_CC = 1;
    parameter int NUM_DL_LAYER = 1;

    // DUT Signals

    logic          clk_400m;
    logic          rst_400m;

    // Timing ports
    logic          s_dl_update          [      NUM_CC] = '{NUM_CC{0}};

    // 4 branch/layer stream; CC shared
    logic   [63:0] s_defm_data_tdata    [NUM_DL_LAYER];
    logic   [ 7:0] s_defm_data_tkeep    [NUM_DL_LAYER];
    logic          s_defm_data_tvalid   [NUM_DL_LAYER];
    logic          s_defm_data_tlast    [NUM_DL_LAYER];
    logic          s_defm_data_tready   [NUM_DL_LAYER];
    logic   [30:0] s_defm_data_tuser    [NUM_DL_LAYER];

    // Interface with DFE
    logic          clk_491m52;
    logic          rst_491m52;

    // DL symbol timing
    logic          dl_radio_start_10ms = 0;

    // 2 CC port; each will have interleaved 4 layer data
    logic        dl_sof               [      NUM_CC];
    logic        dl_sop               [      NUM_CC];
    logic        dl_sof_ahead_7       [      NUM_CC];
    logic        dl_sop_ahead_7       [      NUM_CC];
    logic [15:0] dl_data_i            [      NUM_CC][NUM_DL_LAYER];
    logic [15:0] dl_data_q            [      NUM_CC][NUM_DL_LAYER];
    logic        dl_valid             [      NUM_CC];

    // Control Interface
    logic   [ 3:0] ctrl_bandwidth       [      NUM_CC] = '{NUM_CC{0}};
    logic   [ 1:0] ctrl_numerology      [      NUM_CC] = '{NUM_CC{0}};
    logic   [ 1:0] ctrl_compression_mode[      NUM_CC] = '{NUM_CC{1}};

    logic [ 1:0] buffer_mem_ctrl_en   [      NUM_CC]               = '{NUM_CC {2'b00} };
    logic [11:0] buffer_mem_addr_i    [      NUM_CC][NUM_DL_LAYER];
    logic [31:0] buffer_mem_data_i    [      NUM_CC][NUM_DL_LAYER];
    logic        buffer_mem_we        [      NUM_CC][NUM_DL_LAYER];
    logic [31:0] buffer_mem_data_o    [      NUM_CC][NUM_DL_LAYER];

    // Simulation signals

    int fin;

    logic [63:0] TDATA  [1000];
    logic [ 7:0] TKEEP  [1000];
    logic        TVALID [1000];
    logic        TLAST  [1000];
    logic        TREADY [1000];
    logic [30:0] TUSER  [1000];


    // DUT
    //====

    int len;

    function automatic int load_packet();
        int n = 0;
        forever begin
            $fscanf(fin, "%x, %x, %x, %x, %x, %x", TDATA[n], TKEEP[n],
                TVALID[n], TLAST[n], TREADY[n], TUSER[n]);
            if (TLAST[n]) break;
            n++;
        end
        $display("%0d words loaded from file", n+1);
        return n+1;
    endfunction


    axi4s_vip #(
        .HAS_TKEEP(1),
        .HAS_TLAST(1),
        .TDATA_WIDTH(64),
        .TUSER_WIDTH(31)
    ) i_axi4s_vip (
        .aclk         (clk_400m),
        .aresetn      (~rst_400m),
        //
        .m_axis_tdata (s_defm_data_tdata[0]),
        .m_axis_tkeep (s_defm_data_tkeep[0]),
        .m_axis_tlast (s_defm_data_tlast[0]),
        .m_axis_tvalid(s_defm_data_tvalid[0]),
        .m_axis_tuser (s_defm_data_tuser[0]),
        .m_axis_tready(s_defm_data_tready[0])
    );

    dl_adaptor #(
        .NUM_CC      (NUM_CC),
        .NUM_DL_LAYER(NUM_DL_LAYER)
    ) UUT (
        .*
    );


    // Stimulation
    //============

    // Clock Generation
    //-----------------

    initial begin
        clk_400m = 0;
        forever begin
            #(1.25) clk_400m = ~clk_400m;
        end
    end

    initial begin
        clk_491m52 = 0;
        forever begin
            #(1.017) clk_491m52 = ~clk_491m52;
        end
    end


    // Reset Generation
    //-----------------

    initial begin
        rst_400m = 1;
        repeat(100) @(posedge clk_400m);
        rst_400m <= 0;
    end

    initial begin
        rst_491m52 = 1;
        repeat(100) @(posedge clk_491m52);
        rst_491m52 <= 0;
    end


    // Main Process
    //-------------

    initial begin
        string line;
        fin = $fopen("s_defm_data.txt", "r");
        if (fin == 0) begin
            $error("Error open file");
        end
        // Skip first line which is table header
        $fgets(line, fin);
        
        i_axi4s_vip.set_master_mode();
        i_axi4s_vip.IF.reset();

        wait(rst_400m == 0);
        #1000;

        fork 

          begin : set_sof
            @(posedge clk_491m52);
            dl_radio_start_10ms <= 1;
            @(posedge clk_491m52);
            dl_radio_start_10ms <= 0;
            #10;
          end

          begin : set_sop
              #100;
              repeat(10) begin
                @(posedge clk_400m);
                s_dl_update <= '{NUM_CC{1}};
                @(posedge clk_400m);
                s_dl_update <= '{NUM_CC{0}};
                repeat(14685 - 2) @(posedge clk_400m);
              end
          end

          begin : set_dl_data
            #200;
            repeat(3) begin
                len = load_packet();
                i_axi4s_vip.IF.master_send(len, TDATA, TKEEP, TUSER);
                #100;
            end
            $display("Send 1 symbol OK");
          end

        join

        #(1000);
        $finish(2);
    end

endmodule

`default_nettype wire


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    14:59:06 05/10/2013
// Design Name:
// Module Name:    spi_master
// Project Name:
// Target Devices:
// Tool versions:
// Description:
// sclk_neg data sample,sclk_pos data change
//	spi:CPHA  0      ÔÚÃ¿¸öÊ±ÖÓÖÜÆÚµÚÒ»¸öÊ±ÖÓÑÓ²ÉÑù£¬µÚ¶þ¸öÊ±ÖÓÑÓÊä³ö       //ÕâÀï¾ÍÊÇ×ÖÃæÒâË¼
//				 1   ÔÚÃ¿¸öÊ±ÖÓÖÜÆÚµÚ¶þ¸öÊ±ÖÓÑÓ²ÉÑù£¬µÚÒ»¸öÊ±ÖÓÑÓÊä³ö//
//		 CPOL  0	  Ê±ÖÓ¿ÕÏÐÊ±ÎªµÍµçÆ½
//				 1   Ê±ÖÓ¿ÕÏÐÊ±Îª¸ßµçÆ½
// Dependencies:
//	±ê×¼	SPI-MASTER ¼Ä´æÆ÷¶ÁÐ´
//	¿ÉÅäÖÃCPOL, CPHA, DIV,WIDTH
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module spi_master_transmit_TC_data #(parameter CPOL=1'b1, CPHA=1'b0, DIVF=3,WIDTH = 8,DATA_WD = 24) (
	input                    clk    ,
	input                    rst    ,
	(* KEEP="TRUE" *)input      [  WIDTH-1:0] data_i,
	input                    data_ie,
	output reg [DATA_WD-1:0] data_o = 24'hffffff,
	output                   wr_en  ,
	//spi
	output reg               sclk   ,
	output reg               cs     ,
	input                    miso   ,
	output reg               mosi
);

	wire start      ;
	wire write_cycle;
(* KEEP="TRUE" *)	wire read_cycle ;
    wire read_cycle_1;
	wire pos_edge   ;
	wire neg_edge   ;



	reg            F          ;
	reg [DIVF-1:0] count      ;
	reg [     7:0] cnt        ;
	reg [     7:0] cnt_rd     ;
	reg [     7:0] cnt_rd1    ;
	reg            gclk       ;
	reg            gclk_dly1  ;
	reg            gclk_dly2  ;
	reg            launch_edge;
(* KEEP="TRUE" *)	reg            latch_edge ;

	reg [WIDTH-1:0] tx_data_buf ;
	reg [WIDTH-1:0] data_i_latch;
	reg [DATA_WD-1:0] rd_data_buf ;
	reg             chipselect  ;
	reg             out         ;
	reg             clk_en      ;

	reg F_read;
	reg F_write;

	reg wr_en_f;
	localparam para = 2;

    reg [7:0] cntrd_dy;
	
// 	 ila_1 ila_1(
// .clk   (clk       ),    
// .probe0(start      ),
// .probe1(write_cycle      ),
// .probe2(read_cycle       ),
// .probe3(pos_edge    ),
// .probe4(neg_edge),
// .probe5(F        ),
// .probe6(cnt ),
// .probe7(cntrd      ),
// .probe8(gclk   ),
// .probe9(gclk_dly1   ),
// .probe10(launch_edge         ),
// .probe11(latch_edge    ),
// .probe12(tx_data_buf     ),
// .probe13(data_i_latch    ),
// .probe14(rd_data_buf         ),
// .probe15(chipselect         ),
// .probe16(out         ),
// .probe17(clk_en         ),
// .probe18(data_ie          ), 
// .probe19(wr_en_f   ), 
// .probe20(sclk     ), 
// .probe21(cs         ),
// .probe22(miso),
// .probe23(mosi),
// .probe24(data_o)
//     );
/////////////SCLK////////////////////////////////////
	// always@(posedge clk,negedge rst)
	// 	if(~rst)
	// 		count	<=	0;
	// 	else if(count==2'd2) begin
	// 	gclk	<=	~gclk;
	// 	count <= 0;
	// 	end
	// 	else
	// 		count	<=	count + 1'b1;

	 always@(posedge clk,negedge rst)
	 	if(~rst)
	 		count <= 0;
	 	else
	 		count <= count + 1'b1;
	 //40M/16 = 2.5M
	 always@(posedge clk,negedge rst)
	 	if(~rst)
	 		gclk <= 1'b0;
	 	else if(&count)
	 		gclk <= ~gclk;


	always@(posedge clk)begin
		gclk_dly1 <= gclk;		
		gclk_dly2 <= gclk_dly1;
	end

	assign pos_edge = ~gclk_dly1 & gclk ; 
	assign neg_edge = gclk_dly1 & ~gclk ; 

	always @(*)
		case({CPOL,CPHA})		
		   2'b00 : begin
				launch_edge <= neg_edge	;
				latch_edge  <= pos_edge	;
			end
			2'b01 : begin
				launch_edge <= pos_edge	;
				latch_edge  <= neg_edge	;
			end
			2'b10 : begin
				launch_edge <= pos_edge	;
				latch_edge  <= neg_edge	;
			end
			2'b11 : begin
				launch_edge <= neg_edge	;
				latch_edge  <= pos_edge	;
			end
		endcase
///////////////SPI SYNC OUT//////////////////////////////////////

		always @(posedge clk)begin
			mosi <= out ;
			cs   <= chipselect ;
			begin
				if(clk_en)
					sclk <= gclk_dly1;
				else begin
					if(CPOL)	sclk <= 1'b1;
					else 		sclk <= 1'b0;
				end
			end
		end


/////////////////////WRITE///////////////////////////////////
	always@(posedge clk,negedge rst)
		if(~rst)
			data_i_latch <= 0;
		else	if(data_ie)
			data_i_latch <= data_i;

	always@(posedge clk,negedge rst)
		if(~rst)
			F_read <= 1'b0	;        // flag
		else if(data_ie)
			F_read <= 1'b1	;
		else if( (cntrd == para + WIDTH + DATA_WD) && launch_edge )
			F_read <= 1'b0	;

	always@(posedge clk,negedge rst)
		if(~rst)
			F_write <= 1'b0	;        // flag
		else if(data_ie)
			F_write <= 1'b1	;
		else if( (cnt == para + WIDTH ) && launch_edge )
			F_write <= 1'b0	;

	always@(posedge clk,negedge rst)
		if(~rst)
			cnt <= 0	;
		else if(launch_edge & F_write)begin
			if (cnt == para + WIDTH)
				cnt <= 0	;
			else
				cnt <= cnt+1'b1;
		end

    reg [7:0] cntrd;
	always@(posedge clk,negedge rst)
		if(~rst)
			cntrd <= 0	;
		else if(launch_edge & F_read)begin
			if (cntrd == para + WIDTH + DATA_WD)
				cntrd <= 0	;
			else
				cntrd <= cntrd + 1'b1;
		end

	assign start       = (cnt== para)  ?  1'b1:1'b0	;
	assign write_cycle = (cnt>= (para+1'd1))  ?  1'b1:1'b0	;


	always @(posedge clk,negedge rst)
		if(~rst)begin
			chipselect  <= 1'b1 ;
			clk_en      <= 1'b0 ;
			out         <= 1'b0 ;
			tx_data_buf <= 0	;
		end
		else if(launch_edge)begin
			if(start)begin	//start	 half cycle chipselect
				out         <= 1'b0;
				tx_data_buf <= data_i_latch;
				chipselect  <= 1'b0;
				clk_en      <= 1'b0;
			end
			else if(write_cycle)begin 
				out         <= tx_data_buf[WIDTH-1];//
				tx_data_buf <= tx_data_buf<<1;
				chipselect  <= 1'b0;
				clk_en      <= 1'b1;
			end
			else begin if(read_cycle_1)begin	// stop  and idle
				out        <= 1'b0;
				chipselect <= 1'b0;
				clk_en     <= 1'b1;
			end
			else begin
				out        <= 1'b0;
				chipselect <= 1'b1;
				clk_en     <= 1'b0;	
				end
				end			
		end

///////////////////read/////////////////////////////////////////
reg [7:0] cntrd_dy2;
	always @(posedge clk)
		if(launch_edge) begin
			cnt_rd <= cnt ;
			cnt_rd1 <= cnt_rd;
            cntrd_dy <= cntrd;
            cntrd_dy2 <= cntrd_dy;
		end

    assign read_cycle_1 = (cntrd    >= (para+1'd1+WIDTH))? 1'b1:1'b0  ;
    assign read_cycle   = (cntrd_dy2 >= (para+1'd1+WIDTH))? 1'b1:1'b0  ;


	always @(posedge clk,negedge rst)
		if(~rst)begin
			rd_data_buf <= 0;
			data_o      <= 24'hffffff;
		end else if(read_cycle & latch_edge)begin		
		rd_data_buf <= {rd_data_buf[DATA_WD-2:0],miso};
			if(cntrd_dy2 == para + WIDTH + DATA_WD)           //
				data_o <= {rd_data_buf[DATA_WD-2:0],miso};
		end


	always @(posedge clk,negedge rst)		
	if(~rst)
			wr_en_f <= 1'b0;
		else if(cntrd_dy2 == para + WIDTH + DATA_WD)
			wr_en_f <= 1'b1;
		else
			wr_en_f <= 1'b0;

	assign wr_en = (wr_en_f && cntrd_dy2 == 0 ) ? 1'b1:1'b0;


endmodule





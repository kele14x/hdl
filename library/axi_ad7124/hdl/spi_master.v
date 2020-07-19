
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
//	spi:CPHA  0      在每个时钟周期第一个时钟延采样，第二个时钟延输出       //这里就是字面意思
//				 1   在每个时钟周期第二个时钟延采样，第一个时钟延输出//
//		 CPOL  0	  时钟空闲时为低电平
//				 1   时钟空闲时为高电平
// Dependencies:
//	标准	SPI-MASTER 寄存器读写
//	可配置CPOL, CPHA, DIV,WIDTH
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module spi_master #(parameter CPOL=1'b1, CPHA=1'b0, DIVF=3,WIDTH = 32,DATA_WD = 16) (
	input                    clk    ,
	input                    rst    ,
	(* KEEP="TRUE" *)input      [  WIDTH-1:0] data_i , //发送数据
	input                    data_ie, //启动信号
	output reg [DATA_WD-1:0] data_o ,
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
	reg [WIDTH-1:0] rd_data_buf ;
	reg             chipselect  ;
	reg             out         ;
	reg             clk_en      ;

	reg wr_en_f;
	localparam para = 2;
	
	
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

	 always@(posedge clk,negedge rst)//这里决定了fpga采样的频率和输出数据的速率
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


	always@(posedge clk)begin//这里不光俏送绞敝有藕牛ê竺姘裧clk_dly1赋给了sclk），而且为后面的pos_edge和neg_edge所准备
		gclk_dly1 <= gclk;//一般像这种时序，gclk_dly1领先gclk一鯿lk时钟周期，或者说gclk_dly1说gclk一个clk敝又芷谇暗男藕?		
		gclk_dly2 <= gclk_dly1;
	end
//可以磄clk(包括gclk_dly1、gclk_dly2和sclk)与pos_edge和neg_edge之间的时序关系
	assign pos_edge = ~gclk_dly1 & gclk ;   //gclk pos edge，一个clk时钟周期的脉冲，不仅用于配置CPOL和CPHA，还用于控制信号的时序逻辑（例如F和cnt）
	assign neg_edge = gclk_dly1 & ~gclk ; //gclk neg edge，一个clk时钟周期的脉冲，不仅用于配置CPOL和CPHA，还用控制信号的时序逻辑，每两个neg或pos藕畔喔粢桓鰃clk周期

	always @(*)
		case({CPOL,CPHA})//synthesis full_case  //synthesis parallel_case，配置SPI总线协议的传输时序，一共有四种模式，用launch_edge和latch_edge硎?			
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

		always @(posedge clk)begin//这里把输出信殴槐榧拇嫫鞑⑶胰范⊿CLK信号的初始极性
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
	always@(posedge clk,negedge rst)//把输入的data_i值交给寄存器data_i_latch，并且建立标志位F和计数器cnt（这里的时序逻辑由launch_edge掌控），一个cnt=n的周期为一个glck周期
		if(~rst)
			data_i_latch <= 0;
		else	if(data_ie)
			data_i_latch <= data_i;

	always@(posedge clk,negedge rst)
		if(~rst)
			F <= 1'b0	;        // flag
		else if(data_ie)
			F <= 1'b1	;
		else if( (cnt == para + WIDTH) && launch_edge )
			F <= 1'b0	;
	always@(posedge clk,negedge rst)
		if(~rst)
			cnt <= 0	;
		else if(launch_edge & F)begin
			if (cnt == para + WIDTH)
				cnt <= 0	;
			else
				cnt <= cnt+1'b1;
		end

	assign start       = (cnt== para)  ?  1'b1:1'b0	;//前十位不是数据位，可以随意设置，只是相当于延时了10个gclk的
	assign write_cycle = (cnt>= (para+1'd1))  ?  1'b1:1'b0	;//10-41为32位的向AD发出的数据位


	always @(posedge clk,negedge rst)
		if(~rst)begin
			chipselect  <= 1'b1 ;
			clk_en      <= 1'b0 ;
			out         <= 1'b0 ;
			tx_data_buf <= 0	;
		end
		else if(launch_edge)begin//试过直接把data_i_latch放到循环里，就是相当于去掉tx_data_buf饣寄存器变量，但是有一条语句导致了综合错误（应该是这一条）tx_data_buf <= tx_data_buf<<1;
			if(start)begin	//start	 half cycle chipselect
				out         <= 1'b0;
				tx_data_buf <= data_i_latch;
				chipselect  <= 1'b0;
				clk_en      <= 1'b0;
			end
			else if(write_cycle)begin //由于序的逻辑?其实就是由于launch_edge=1与write_cycle=1的不同步)，导致write_cycle会延后一个周期这里的if判断语句才会生效，这也导致了clk_en=1与write_cycle=1的持续时间会相差一个gclk_dly1周?
				out         <= tx_data_buf[WIDTH-1];//
				tx_data_buf <= tx_data_buf<<1;
				chipselect  <= 1'b0;
				clk_en      <= 1'b1;//clk_en领先sclk 1个clk周期（为什么领先是由于clk_en与sclk时序逻辑性质决定的，本身用clk_en控制sclk是时序逻辑语句，所以本身就会有一个clk周期的延迟导致了这种结果）
			end
			else begin	// stop  and idle
				out        <= 1'b0;
				chipselect <= 1'b1;
				clk_en     <= 1'b0;
			end
		end

///////////////////read/////////////////////////////////////////
	always @(posedge clk)//这里为什么要建立一个寄存器cnt_rd，蚴为了让read操作中的read_cycle与clk_en对上，换句话说就是cnt_rd与sclk对上（相差一个clk周期），因为launch_edge的原因cnt_rd嵩赾nt的时序基础上向移一个gclk周期
		if(launch_edge) begin
			cnt_rd <= cnt ;
			cnt_rd1 <= cnt_rd;
		end

	assign read_cycle = (cnt_rd >= (para+1'd1))? 1'b1:1'b0	;


	always @(posedge clk,negedge rst)
		if(~rst)begin
			rd_data_buf <= 0;
			data_o      <= 0;
		end else if(read_cycle & latch_edge)begin//这里锁存的数据是在cnt_rd的屑洌鼙Ｖな莸奈榷ㄐ浴?			
		rd_data_buf <= {rd_data_buf[WIDTH-2:0],miso};
			if(cnt_rd==para + WIDTH)           //
				data_o <= {rd_data_buf[WIDTH-2:0],miso};
		end


	always @(posedge clk,negedge rst)//如果在调试过程中出现时序问题，这里也可以改为assign组合逻辑（这里主要用时序逻辑的原蚴fpga编程中最好使用时序逻辑？?		
	if(~rst)
			wr_en_f <= 1'b0;
		else if(cnt_rd==para+WIDTH)
			wr_en_f <= 1'b1;
		else
			wr_en_f <= 1'b0;

	assign wr_en = (wr_en_f && cnt_rd==0 ) ? 1'b1:1'b0;


endmodule





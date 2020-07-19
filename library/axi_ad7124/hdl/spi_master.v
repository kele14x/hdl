
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
//	spi:CPHA  0      ��ÿ��ʱ�����ڵ�һ��ʱ���Ӳ������ڶ���ʱ�������       //�������������˼
//				 1   ��ÿ��ʱ�����ڵڶ���ʱ���Ӳ�������һ��ʱ�������//
//		 CPOL  0	  ʱ�ӿ���ʱΪ�͵�ƽ
//				 1   ʱ�ӿ���ʱΪ�ߵ�ƽ
// Dependencies:
//	��׼	SPI-MASTER �Ĵ�����д
//	������CPOL, CPHA, DIV,WIDTH
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module spi_master #(parameter CPOL=1'b1, CPHA=1'b0, DIVF=3,WIDTH = 32,DATA_WD = 16) (
	input                    clk    ,
	input                    rst    ,
	(* KEEP="TRUE" *)input      [  WIDTH-1:0] data_i , //��������
	input                    data_ie, //�����ź�
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

	 always@(posedge clk,negedge rst)//���������fpga������Ƶ�ʺ�������ݵ�����
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


	always@(posedge clk)begin//���ﲻ���Ϊ��ͬ��ʱ���źţ������gclk_dly1������sclk��������Ϊ�����pos_edge��neg_edge��׼��
		gclk_dly1 <= gclk;//һ��������ʱ��gclk_dly1����gclkһ�clkʱ�����ڣ�����˵gclk_dly1˵gclkһ��clk�������ǰ���ź?		
		gclk_dly2 <= gclk_dly1;
	end
//���Դgclk(����gclk_dly1��gclk_dly2��sclk)��pos_edge��neg_edge֮���ʱ���ϵ
	assign pos_edge = ~gclk_dly1 & gclk ;   //gclk pos edge��һ��clkʱ�����ڵ����壬������������CPOL��CPHA�������ڿ����źŵ�ʱ���߼�������F��cnt��
	assign neg_edge = gclk_dly1 & ~gclk ; //gclk neg edge��һ��clkʱ�����ڵ����壬������������CPOL��CPHA�����ÿ����źŵ�ʱ���߼���ÿ����neg��posź����һ��gclk����

	always @(*)
		case({CPOL,CPHA})//synthesis full_case  //synthesis parallel_case������SPI����Э��Ĵ���ʱ��һ��������ģʽ����launch_edge��latch_edge��?			
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

		always @(posedge clk)begin//����������Ź�һ��Ĵ�������ȷ��SCLK�źŵĳ�ʼ����
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
	always@(posedge clk,negedge rst)//�������data_iֵ�����Ĵ���data_i_latch�����ҽ�����־λF�ͼ�����cnt�������ʱ���߼���launch_edge�ƿأ���һ��cnt=n������Ϊһ��glck����
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

	assign start       = (cnt== para)  ?  1'b1:1'b0	;//ǰʮλ��������λ�������������ã�ֻ���൱����ʱ��10��gclk��
	assign write_cycle = (cnt>= (para+1'd1))  ?  1'b1:1'b0	;//10-41Ϊ32λ����AD����������λ


	always @(posedge clk,negedge rst)
		if(~rst)begin
			chipselect  <= 1'b1 ;
			clk_en      <= 1'b0 ;
			out         <= 1'b0 ;
			tx_data_buf <= 0	;
		end
		else if(launch_edge)begin//�Թ�ֱ�Ӱ�data_i_latch�ŵ�ѭ��������൱��ȥ��tx_data_buf⻼Ĵ���������������һ����䵼�����ۺϴ���Ӧ������һ����tx_data_buf <= tx_data_buf<<1;
			if(start)begin	//start	 half cycle chipselect
				out         <= 1'b0;
				tx_data_buf <= data_i_latch;
				chipselect  <= 1'b0;
				clk_en      <= 1'b0;
			end
			else if(write_cycle)begin //��������߼�?��ʵ��������launch_edge=1��write_cycle=1�Ĳ�ͬ��)������write_cycle���Ӻ�һ�����������if�ж����Ż���Ч����Ҳ������clk_en=1��write_cycle=1�ĳ���ʱ������һ��gclk_dly1��?
				out         <= tx_data_buf[WIDTH-1];//
				tx_data_buf <= tx_data_buf<<1;
				chipselect  <= 1'b0;
				clk_en      <= 1'b1;//clk_en����sclk 1��clk���ڣ�Ϊʲô����������clk_en��sclkʱ���߼����ʾ����ģ�������clk_en����sclk��ʱ���߼���䣬���Ա���ͻ���һ��clk���ڵ��ӳٵ��������ֽ����
			end
			else begin	// stop  and idle
				out        <= 1'b0;
				chipselect <= 1'b1;
				clk_en     <= 1'b0;
			end
		end

///////////////////read/////////////////////////////////////////
	always @(posedge clk)//����ΪʲôҪ����һ���Ĵ���cnt_rd������Ϊ����read�����е�read_cycle��clk_en���ϣ����仰˵����cnt_rd��sclk���ϣ����һ��clk���ڣ�����Ϊlaunch_edge��ԭ��cnt_rd���cnt��ʱ�����������һ��gclk����
		if(launch_edge) begin
			cnt_rd <= cnt ;
			cnt_rd1 <= cnt_rd;
		end

	assign read_cycle = (cnt_rd >= (para+1'd1))? 1'b1:1'b0	;


	always @(posedge clk,negedge rst)
		if(~rst)begin
			rd_data_buf <= 0;
			data_o      <= 0;
		end else if(read_cycle & latch_edge)begin//�����������������cnt_rd��м䣬�ܱ�֤���ݵ��ȶ��ԡ?			
		rd_data_buf <= {rd_data_buf[WIDTH-2:0],miso};
			if(cnt_rd==para + WIDTH)           //
				data_o <= {rd_data_buf[WIDTH-2:0],miso};
		end


	always @(posedge clk,negedge rst)//����ڵ��Թ����г���ʱ�����⣬����Ҳ���Ը�Ϊassign����߼���������Ҫ��ʱ���߼���ԭ��fpga��������ʹ��ʱ���߼���?		
	if(~rst)
			wr_en_f <= 1'b0;
		else if(cnt_rd==para+WIDTH)
			wr_en_f <= 1'b1;
		else
			wr_en_f <= 1'b0;

	assign wr_en = (wr_en_f && cnt_rd==0 ) ? 1'b1:1'b0;


endmodule





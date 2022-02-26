
module camera_driver (	//	Host Side
						iCLK,
						iRST_N,
						//	I2C Side
						I2C_SCLK,
						I2C_SDAT,
						RST, TRIG, STR, SBY, count, xclock1
						);
						
//	Host Side
input			iCLK;
input			iRST_N;
output reg [9:0]count = 10'd0;
output RST, TRIG, SBY ;
inout STR;
assign TRIG = 1'b0;

assign SBY = 1'b0;

assign RST = 1'b1;

assign STR = 1'bz;

output xclock1;

//assign xclock = count[1];

// xclock  dut1(
//					.inclk0(iCLK),
//					.c0(xclock1)
//				);

//	I2C Side
output		I2C_SCLK;
inout		I2C_SDAT;

//`define ENABLE_TEST_PATTERN

always@(posedge iCLK)
begin
if(!iRST_N)
	count = 10'd0;
	else
   count = count +1;
end


//	Internal Registers/Wires
reg	[15:0]	mI2C_CLK_DIV;
reg	[31:0]	mI2C_DATA;
reg			mI2C_CTRL_CLK;
reg			mI2C_GO;
wire		mI2C_END;
wire		mI2C_ACK;
reg	[23:0]	LUT_DATA;
reg	[5:0]	LUT_INDEX;
reg	[3:0]	mSetup_ST;

wire [23:0] sensor_start_row;
wire [23:0] sensor_start_column;
wire [23:0] sensor_row_size;
wire [23:0] sensor_column_size; 
wire [23:0] sensor_row_mode;
wire [23:0] sensor_column_mode;

assign sensor_start_row 		=   24'h010000+16'd500  ;
assign sensor_start_column 	=   24'h020000+16'd650  ;
assign sensor_row_size	 		=   24'h030000+16'd1023;
assign sensor_column_size 		=   24'h040000+16'd1279;
assign sensor_row_mode 			=   24'h220000  ;
assign sensor_column_mode		=   24'h230000  ;

//	Clock Setting
parameter	CLK_Freq	=	50000000;	//	50	MHz
parameter	I2C_Freq	=	100000;		//	20	KHz
//	LUT Data Number
parameter	LUT_SIZE	=	40;

/////////////////////	I2C Control Clock	////////////////////////
always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		mI2C_CTRL_CLK	<=	0;
		mI2C_CLK_DIV	<=	0;
	end
	else
	begin
		if( mI2C_CLK_DIV	< (CLK_Freq/I2C_Freq) )
		mI2C_CLK_DIV	<=	mI2C_CLK_DIV+1;
		else
		begin
			mI2C_CLK_DIV	<=	0;
			mI2C_CTRL_CLK	<=	~mI2C_CTRL_CLK;
		end
	end
end
////////////////////////////////////////////////////////////////////
I2C_Controller 	u0	(	.CLOCK(mI2C_CTRL_CLK),		//	Controller Work Clock
						.I2C_SCLK(I2C_SCLK),		//	I2C CLOCK
 	 	 	 	 	 	.I2C_SDAT(I2C_SDAT),		//	I2C DATA
						.I2C_DATA(mI2C_DATA),		//	DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
						.GO(mI2C_GO),      			//	GO transfor
						.END(mI2C_END),				//	END transfor 
						.ACK(mI2C_ACK),				//	ACK
						.RESET(iRST_N)
					);
////////////////////////////////////////////////////////////////////
//////////////////////	Config Control	////////////////////////////
//always@(posedge mI2C_CTRL_CLK or negedge iRST_N)
always@(posedge mI2C_CTRL_CLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		LUT_INDEX	<=	0;
		mSetup_ST	<=	0;
		mI2C_GO		<=	0;

	end

	else if(LUT_INDEX<LUT_SIZE)
		begin
			case(mSetup_ST)
			0:	begin
					mI2C_DATA	<=	{8'hA0,LUT_DATA};
					mI2C_GO		<=	1;
					mSetup_ST	<=	1;
				end
			1:	begin
					if(mI2C_END)
					begin
						if(!mI2C_ACK)
						mSetup_ST	<=	2;
						else
						mSetup_ST	<=	0;							
						mI2C_GO		<=	0;
					end
				end
			2:	begin
					LUT_INDEX	<=	LUT_INDEX+1;
					mSetup_ST	<=	0;
				end
			endcase
		end
end
////////////////////////////////////////////////////////////////////
/////////////////////	Config Data LUT	  //////////////////////////		
always@(*)
begin
	case(LUT_INDEX)
	
	//MT9P031                                                                                                                                                                                                               
	0	:	LUT_DATA	<=	24'h000001;
	1	:	LUT_DATA	<=	24'h000102;				//	Mirror Row and Columns
	2	:	LUT_DATA	<=	24'h000203;		//	Exposure 
	3	:	LUT_DATA	<=	24'h000304;				//	H_Blanking
	4	:	LUT_DATA	<=	24'h000405;				//	V_Blanking	
	5	:	LUT_DATA	<=	24'h0A8000;				//	change latch
	6	:	LUT_DATA	<=	24'h2B0010;				//	Green 1 Gain
	7	:	LUT_DATA	<=	24'h2C0018;				//	Blue Gain
	8	:	LUT_DATA	<=	24'h2D0018;				//	Red Gain
	9	:	LUT_DATA	<=	24'h2E0010;				//	Green 2 Gain
	10	:	LUT_DATA	<=	24'h100051;				//	set up PLL power on
	11	:	LUT_DATA	<=	24'h111807;				//	PLL_m_Factor<<8+PLL_n_Divider
	12	:	LUT_DATA	<=	24'h120002;				//	PLL_p1_Divider
	13	:	LUT_DATA	<=	24'h100053;				//	set USE PLL	 
	14	:	LUT_DATA	<=	24'h980000;				//	disble calibration 	
	15	:	LUT_DATA	<=	24'hA00001;				//	Test pattern control 	
	16	:	LUT_DATA	<=	24'hA10123;				//	Test green pattern value
	17	:	LUT_DATA	<=	24'hA20456;				//	Test red pattern value
	15	:	LUT_DATA	<=	24'hA00000;				//	Test pattern control 
	16	:	LUT_DATA	<=	24'hA10000;				//	Test green pattern value
	17	:	LUT_DATA	<=	24'hA20FFF;				//	Test red pattern value
	18	:	LUT_DATA	<=	sensor_start_row 	;	//	set start row	
	19	:	LUT_DATA	<=	sensor_start_column ;	//	set start column 	
	20	:	LUT_DATA	<=	sensor_row_size;		//	set row size	
	21	:	LUT_DATA	<=	sensor_column_size;		//	set column size
	22	:	LUT_DATA	<=	sensor_row_mode;		//	set row mode in bin mode
	23	:	LUT_DATA	<=	sensor_column_mode;		//	set column mode	 in bin mode
	24	:	LUT_DATA	<=	24'h4901A8;				//	row black target	
	
	default:LUT_DATA	<=	24'h000000;
	endcase
end

endmodule


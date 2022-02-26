`timescale 1ns / 1ps 
////////////////////////////////////////////////////////////////////////////////// 
// Company:  
// Engineer:  
//  
// Create Date:    19:11:16 05/29/2016  
// Design Name:  
// Module Name:    top_pro  
// Project Name:  
// Target Devices:  
// Tool versions:  
// Description:  
// 
// Dependencies:  
// 
// Revision:  
// Revision 0.01 - File Created 
// Additional Comments:  
// 
 
////////////////////////////////////////////////////////////////////////////////// 
module top_pro( 
			input					clk_50M, 
			input					reset_n, 
			output[3:0]			led, 
			 
			//Camera�ӿ��ź� 
			output 					xclk,             //cmos externl clock 
			output 					I2C_SCLK,                //cmos i2c clock 
			output 					I2C_SDAT,	              //cmos i2c data 
			input 					camera_pclk,              //cmos pxiel clock 
			input						camera_href,              //cmos hsync refrence 
			input 					camera_vsync,             //cmos vsync 
			input 					[9:0] camera_data,        //cmos data 
			 
			//DDR�Ľӿ��ź� 
		    inout  [15:0]            mcb3_dram_dq, 
		    output [12:0]            mcb3_dram_a, 
		    output [2:0]             mcb3_dram_ba, 
		    output                   mcb3_dram_ras_n, 
		    output                   mcb3_dram_cas_n, 
		    output                   mcb3_dram_we_n, 
		    output                   mcb3_dram_odt, 
		    output                   mcb3_dram_reset_n, 
		    output                   mcb3_dram_cke, 
		    output                   mcb3_dram_dm, 
		    inout                    mcb3_dram_udqs, 
		    inout                    mcb3_dram_udqs_n, 
		    inout                    mcb3_rzq, 
		    inout                    mcb3_zio, 
		    output                   mcb3_dram_udm, 
		    inout                    mcb3_dram_dqs, 
		    inout                    mcb3_dram_dqs_n, 
		    output                   mcb3_dram_ck, 
		    output                   mcb3_dram_ck_n, 
			 
			 //LCD�Ľӿ��ź� 
			output [7:0]            lcd_r, 
			output [7:0]            lcd_g, 
			output [7:0]            lcd_b, 
			output                  lcd_dclk, 
			output                  lcd_hsync, 
			output                  lcd_vsync, 
			output                  lcd_de	  
 
    ); 
 
	 
wire [3:0]led;	 
wire c3_clk0; 
wire lcd_clk; 
wire camera_clk; 
 
wire ddr_wren; 
wire [63:0] ddr_data_camera; 
wire ddr_addr_wr_set; 
wire frame_switch; 
 
wire ddr_rden; 
wire ddr_rd_cmd; 
wire [63:0] ddr_data_vga; 
wire ddr_addr_rd_set; 
	 
wire camera_drive_ok; 
wire [8:0]INDEX; 
  
assign xclk=camera_clk; 
/*  BUFG 
   BUFG_pclk
   (
       .O (xclk), 
       .I (camera_clk)
   );*/ 
assign lcd_dclk=lcd_clk; 
 
assign led[0]=c3_rst0?1'b1:1'b0;                   //led0Ϊddr calibrate���ָʾ�ź�,��˵����ʼ����� 
assign led[1]=camera_drive_ok?1'b0:1'b1;           //led1Ϊͼ���Ѵ���DDR�����ָʾ�ź�,��˵���洢����� 
assign led[2]=c3_p0_wr_full?1'b0:1'b1;             //led2Ϊд���ݲ���ָʾ�ź�,��˵������ 
assign led[3]=c3_p0_cmd_full?1'b0:1'b1;            //led2Ϊ������overָʾ�ź�,��˵������ 
 
camera_drive u1	(	 
					.camera_clk(camera_clk),//25M 
					.reset_n(reset_n),						 
					.INDEX(INDEX), 
					.I2C_SCLK(I2C_SCLK), 
					.I2C_SDAT(I2C_SDAT), 
					.camera_drive_ok(camera_drive_ok) 
				); 
				 
camera_capture u2( 
					.reg_conf_done(camera_drive_ok),	 
					.camera_pclk(camera_pclk), 
					.camera_href(camera_href), 
					.camera_vsync(camera_vsync), 
					.camera_data(camera_data),	 
					.ddr_wren(ddr_wren),                              
					.ddr_data_camera(ddr_data_camera),               
					.ddr_addr_wr_set(ddr_addr_wr_set),               
					.frame_switch(frame_switch) 
	 
					); 
 
//VGA��ʾ���Ʋ��� 
lcd_disp	lcd_disp_inst( 
					.lcd_clk                 (lcd_clk), 
					.lcd_rst                 (c3_rst0),		 
					.ddr_data_lcd            (ddr_data_vga),	 
					.lcd_hsync               (lcd_hsync),	 
					.lcd_vsync               (lcd_vsync), 
					.lcd_r                   (lcd_r), 
					.lcd_g                   (lcd_g), 
					.lcd_b                   (lcd_b), 
					.lcd_de                  (lcd_de), 
					.ddr_addr_rd_set         (ddr_addr_rd_set), 
					.ddr_rden                (ddr_rden), 
					.ddr_rd_cmd              (ddr_rd_cmd)	 
					); 
 
 
//DDR��д���Ʋ��� 
ddr_rw ddr_rw_inst( 
	.camera_clk              (camera_clk),               //camera 25MHz  
   .lcd_clk                 (lcd_clk),                  //lcd 9MHz  
   .c3_clk0                 (c3_clk0),                   
 
	.frame_switch            (frame_switch),  	         //camera�����lcd���ƹ���л� 
//camera_captureģ��ӿ��ź�	 
	.ddr_data_camera         (ddr_data_camera), 
	.ddr_addr_wr_set         (ddr_addr_wr_set),	 
	.ddr_wren                (ddr_wren),	 
 
//vga_displyģ��ӿ��ź� 
	.ddr_data_vga            (ddr_data_vga), 
	.ddr_addr_rd_set         (ddr_addr_rd_set), 
	.ddr_rden                (ddr_rden), 
	.ddr_rd_cmd              (ddr_rd_cmd), 
	 
	.c3_p0_wr_underrun       (c3_p0_wr_underrun), 
	.c3_p0_wr_full           (c3_p0_wr_full), 
	.c3_p0_cmd_full          (c3_p0_cmd_full), 
	.c3_p1_rd_overflow       (c3_p1_rd_overflow),	 
	.c3_p1_rd_empty          (c3_p1_rd_empty),	 
	.c3_p1_cmd_full          (c3_p1_cmd_full),	 
	.mcb3_dram_dq            (mcb3_dram_dq),	 
	.mcb3_dram_a             (mcb3_dram_a),	 
	.mcb3_dram_ba            (mcb3_dram_ba),	 
	.mcb3_dram_ras_n         (mcb3_dram_ras_n),	 
	.mcb3_dram_cas_n         (mcb3_dram_cas_n),	 
	.mcb3_dram_we_n          (mcb3_dram_we_n), 
	.mcb3_dram_odt           (mcb3_dram_odt), 
	.mcb3_dram_reset_n       (mcb3_dram_reset_n),	 
	.mcb3_dram_cke           (mcb3_dram_cke),	 
	.mcb3_dram_dm            (mcb3_dram_dm),	 
	.mcb3_dram_udqs          (mcb3_dram_udqs),	 
	.mcb3_dram_udqs_n        (mcb3_dram_udqs_n),	 
	.mcb3_rzq                (mcb3_rzq),	 
	.mcb3_zio                (mcb3_zio),	 
	.mcb3_dram_udm           (mcb3_dram_udm), 
	.c3_sys_clk              (clk_50M),	 
	.c3_sys_rst_n            (reset_n), 
	.c3_rst0                 (c3_rst0), 
	.mcb3_dram_dqs           (mcb3_dram_dqs), 
	.mcb3_dram_dqs_n         (mcb3_dram_dqs_n), 
	.mcb3_dram_ck            (mcb3_dram_ck), 
	.mcb3_dram_ck_n          (mcb3_dram_ck_n) 
 
);				 
 
endmodule 
//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���?
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           video_display
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        ��Ƶ��ʾģ�飬��ʾ����
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module  video_display(
    input                pixel_clk,
    input                sys_rst_n,
    
    input        [10:0]  pixel_xpos,  //���ص������?
    input        [10:0]  pixel_ypos,  //���ص�������
    output  reg  [23:0]  pixel_data_load,
    input        [23:0]  pixel_data_update,
    input                rd_rst,
    input                rd_en,
    input                wt_rst,
    input                wt_en,
    output  reg  [23:0]  pixel_data,
    output  reg          pixel_data_vld   
);

//parameter define
//parameter  H_DISP = 11'd1280;                       //�ֱ��ʡ�����
//parameter  V_DISP = 11'd720;                        //�ֱ��ʡ�����
parameter  H_DISP = 11'd128;    
parameter  V_DISP = 11'd72;     

localparam WHITE  = 24'b11111111_11111111_11111111;  //RGB888 ��ɫ
localparam BLACK  = 24'b00000000_00000000_00000000;  //RGB888 ��ɫ
localparam RED    = 24'b11111111_00001100_00000000;  //RGB888 ��ɫ
localparam GREEN  = 24'b00000000_11111111_00000000;  //RGB888 ��ɫ
localparam BLUE   = 24'b00000000_00000000_11111111;  //RGB888 ��ɫ
    
//*****************************************************
//**                    main code
//*****************************************************
reg [15:0] mem [0:9215];
reg [12:0] mem_addr;
reg [12:0] mem_addr_ff1;

assign mem_addr = (pixel_ypos==0)?  pixel_xpos : (pixel_xpos)+(pixel_ypos-1)*H_DISP;
initial begin
`ifdef FPGA
    $readmemb("D:/Learn/2-DESIGN/ISP/ISP/model/img_bayer_bin.txt",mem);
`else
    $readmemb("/ext3/home/wangyufei/Projects/6-ISP/model/img_bayer_bin.txt",mem);
`endif
end
//���ݵ�ǰ���ص�����ָ����ǰ���ص���ɫ���ݣ�����Ļ����ʾ����
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        pixel_data <= 24'd0;
    else begin
        //if((pixel_xpos >= 0) && (pixel_xpos < (H_DISP/5)*1))
        //    pixel_data <= WHITE;
        //else if((pixel_xpos >= (H_DISP/5)*1) && (pixel_xpos < (H_DISP/5)*2))
        //    pixel_data <= BLACK;  
        //else if((pixel_xpos >= (H_DISP/5)*2) && (pixel_xpos < (H_DISP/5)*3))
        //    pixel_data <= RED;  
        //else if((pixel_xpos >= (H_DISP/5)*3) && (pixel_xpos < (H_DISP/5)*4))
        //    pixel_data <= GREEN;
        //else 
        //    pixel_data <= BLUE;
        if(mem_addr < 9215 && (mem_addr_ff1 != mem_addr))
            pixel_data <= {8'd0,mem[mem_addr_ff1]};
        else 
            pixel_data <= BLACK;
    end
end

always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        pixel_data_vld <= 1'b0;
    else begin
        if(mem_addr < 9215 && (mem_addr_ff1 != mem_addr) && (mem_addr!=0))
            pixel_data_vld <= 1'b1;
        else 
            pixel_data_vld <= 1'b0;
    end
end

always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        mem_addr_ff1 <= 'd0;
    else
        mem_addr_ff1 <= mem_addr;
end

// TODO
reg [13:0] rd_addr;
reg [13:0] wt_addr;

always@(posedge pixel_clk or negedge sys_rst_n) begin
    if(~sys_rst_n)
        rd_addr <= 14'd0;
    else if(rd_rst)
        rd_addr <= 14'd0;
    else if(rd_en)
        rd_addr <= (rd_addr==14'd9215)?   14'd0 : rd_addr+1'b1;
end

always@(posedge pixel_clk or negedge sys_rst_n) begin
    if(~sys_rst_n)
        pixel_data_load <= 24'd0;
    else 
        pixel_data_load <= mem[rd_addr];
end

always@(posedge pixel_clk) begin
    if(wt_en)   
        mem[wt_addr] <= pixel_data_update;
end
always@(posedge pixel_clk or negedge sys_rst_n) begin
    if(~sys_rst_n)
        wt_addr <= 14'd0;
    else if(wt_rst)
        wt_addr <= 14'd0;
    else if(wt_en)
        wt_addr <= (wt_addr==14'd9215)?   14'd0 : wt_addr+1'b1;
end
endmodule
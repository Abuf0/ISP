//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           video_driver
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        ��Ƶ��ʾ����ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module video_driver#(
    parameter H_DISP = 1280 ,
    parameter V_DISP = 720
)(
    input           pixel_clk,
    input           sys_rst_n,
    
    //RGB�ӿ�
    output          video_hs,     //��ͬ���ź�
    output          video_vs,     //��ͬ���ź�
    output          video_de,     //����ʹ��
    output  [23:0]  video_rgb,    //RGB888��ɫ����
    
    input   [23:0]  pixel_data,   //���ص�����
    output  [10:0]  pixel_xpos,   //���ص������
    output  [10:0]  pixel_ypos    //���ص�������
);

parameter LEN = $clog2(H_DISP*V_DISP);
//parameter define

//1280*720 �ֱ���ʱ�����
//parameter  H_SYNC   =  11'd40;   //��ͬ��
//parameter  H_BACK   =  11'd220;  //����ʾ����
//parameter  H_DISP   =  11'd1280; //����Ч����
//parameter  H_FRONT  =  11'd110;  //����ʾǰ��
//parameter  H_TOTAL  =  11'd1650; //��ɨ������
//
//parameter  V_SYNC   =  11'd5;    //��ͬ��
//parameter  V_BACK   =  11'd20;   //����ʾ����
//parameter  V_DISP   =  11'd720;  //����Ч����
//parameter  V_FRONT  =  11'd5;    //����ʾǰ��
//parameter  V_TOTAL  =  11'd750;  //��ɨ������

parameter  H_SYNC   =  40  * H_DISP / 1280  ;   
parameter  H_BACK   =  220 * H_DISP / 1280  ;  
//parameter  H_DISP   =  11'd128; 
parameter  H_FRONT  =  110  * H_DISP / 1280 ;  
parameter  H_TOTAL  =  H_SYNC+H_BACK+H_FRONT+H_DISP  ; 

parameter  V_SYNC   =  5   * V_DISP /720  ;   
parameter  V_BACK   =  20  * V_DISP /720  ;   
//parameter  V_DISP   =  11'd72 ;
parameter  V_FRONT  =  5   * V_DISP /720 ;   
parameter  V_TOTAL  =  V_SYNC+V_BACK+V_FRONT+V_DISP   ;  

//reg define
reg  [LEN-1:0] cnt_h;
reg  [LEN-1:0] cnt_v;

//wire define
wire       video_en;
wire       data_req;

//*****************************************************
//**                    main code
//*****************************************************

assign video_de  = video_en;

assign video_hs  = ( cnt_h < H_SYNC ) ? 1'b0 : 1'b1;  //��ͬ���źŸ�ֵ
assign video_vs  = ( cnt_v < V_SYNC ) ? 1'b0 : 1'b1;  //��ͬ���źŸ�ֵ

//ʹ��RGB�������
assign video_en  = (((cnt_h >= H_SYNC+H_BACK) && (cnt_h < H_SYNC+H_BACK+H_DISP))
                 &&((cnt_v >= V_SYNC+V_BACK) && (cnt_v < V_SYNC+V_BACK+V_DISP)))
                 ?  1'b1 : 1'b0;

//RGB888�������
assign video_rgb = video_en ? pixel_data : 24'd0;

//�������ص���ɫ��������
assign data_req = (((cnt_h >= H_SYNC+H_BACK-1'b1) && 
                    (cnt_h < H_SYNC+H_BACK+H_DISP-1'b1))
                  && ((cnt_v >= V_SYNC+V_BACK) && (cnt_v < V_SYNC+V_BACK+V_DISP)))
                  ?  1'b1 : 1'b0;

//���ص�����
assign pixel_xpos = data_req ? (cnt_h - (H_SYNC + H_BACK - 1'b1)) : 11'd0;
assign pixel_ypos = data_req ? (cnt_v - (V_SYNC + V_BACK - 1'b1)) : 11'd0;

//�м�����������ʱ�Ӽ���
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_h <= 'd0;
    else begin
        if(cnt_h < H_TOTAL - 1'b1)
            cnt_h <= cnt_h + 1'b1;
        else 
            cnt_h <= 'd0;
    end
end

//�����������м���
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_v <= 'd0;
    else if(cnt_h == H_TOTAL - 1'b1) begin
        if(cnt_v < V_TOTAL - 1'b1)
            cnt_v <= cnt_v + 1'b1;
        else 
            cnt_v <= 'd0;
    end
end

endmodule
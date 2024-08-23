//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           hdmi_colorbar_top
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        HDMI������ʾʵ�鶥��ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module  hdmi_colorbar_top(
    input        sys_clk,
    input        sys_rst_n, 
    output       tmds_clk_p,    // TMDS ʱ��ͨ��
    output       tmds_clk_n,
    output [2:0] tmds_data_p,   // TMDS ����ͨ��
    output [2:0] tmds_data_n
   
);

//wire define
wire          pixel_clk;
wire          pixel_clk_5x;
wire          clk_locked;

wire  [10:0]  pixel_xpos_w;
wire  [10:0]  pixel_ypos_w;
wire  [23:0]  pixel_data_rgb[0:15];
wire          pixel_data_vld[0:15];
wire  [23:0]  pixel_data_w;

wire          video_hs;
wire          video_vs;
wire          video_de;
wire  [23:0]  video_rgb;

wire  [23:0]  pixel_data_rgb[0:15];

parameter DPC = 0   ;
parameter BLC = 1   ;
parameter AAF = 2   ;
parameter AWB = 3   ;
parameter CNF = 4   ;
parameter CFA = 5   ;
parameter CCM = 6   ;
parameter GAC = 7   ;
parameter CSC = 8   ;
parameter NLM = 9   ;
parameter BNF = 10  ;
parameter EEH = 11  ;
parameter FCS = 12  ;
parameter HSC = 13  ;
parameter BBC = 14  ;
//*****************************************************
//**                    main code
//*****************************************************

//����MMCM/PLL IP��
clk_wiz_0  clk_wiz_0(
    .clk_in1        (sys_clk),
    .clk_out1       (pixel_clk),        //����ʱ��
    .clk_out2       (pixel_clk_5x),     //5������ʱ��
    
    .reset          (~sys_rst_n), 
    .locked         (clk_locked)
);

//������Ƶ��ʾ����ģ��
video_driver u_video_driver(
    .pixel_clk      (pixel_clk),
    .sys_rst_n      (sys_rst_n),

    .video_hs       (video_hs),
    .video_vs       (video_vs),
    .video_de       (video_de),
    .video_rgb      (video_rgb),

    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    //.pixel_data     (pixel_data_w)    // show raw img
    .pixel_data     (pixel_data_dpc)    // show dpc img

    );

//������Ƶ��ʾģ��
video_display  u_video_display(
    .pixel_clk          (pixel_clk          ),
    .sys_rst_n          (sys_rst_n          ),

    .pixel_xpos         (pixel_xpos_w       ),
    .pixel_ypos         (pixel_ypos_w       ),
    .pixel_data_seiral  (pixel_data_rgb[0]  ),
    .pixel_data         (pixel_data_w       )
    );

// DPC module
dpc #(
    .THRES      (30 ),
    .DPC_MODE   (0  ),
    .CLIP       (100),
    .H          (720)
) dpc_inst(
    .clk                (pixel_clk               ),
    .rstn               (sys_rst_n               ),
    .dpc_en             (dpc_en                  ), // TODO
    .pixel_data_in_vld  (pixel_data_vld[DPC]     ), // TODO
    .pixel_data_in      (pixel_data_rgb[DPC]     ),
    .pixel_data_out_vld (pixel_data_vld[DPC+1]   ),
    .pixel_data_out     (pixel_data_rgb[DPC+1]   )
);

// BLC module
blc #(
    .BIAS    (10  ),
    .COEF    (1   ),
    .BLC_MODE(0   ),
    .DW      ( 24 )  
) blc_inst(
    .blc_en         (blc_en                ),   // TODO
    .pixel_data_in  (pixel_data_rgb[BLC]   ),
    .pixel_data_out (pixel_data_rgb[BLC+1] )
);
assign pixel_data_vld[BLC+1] = pixel_data_vld[BLC];

// AAF module
aaf #(
    .DW  (24    ),
    .H   (1280  ),
    .V   (720   ),
    .HW  (11    ),
    .VW  (10    )
) aaf_inst(
    .clk                (pixel_clk               ),
    .rstn               (sys_rst_n               ),
    .aaf_en             (aaf_en                  ), // TODO
    .pixel_data_in_vld  (pixel_data_vld[AAF]     ), 
    .pixel_data_in      (pixel_data_rgb[AAF]     ),
    .pixel_data_out_vld (pixel_data_vld[AAF+1]   ),
    .pixel_data_out     (pixel_data_rgb[AAF+1]   ),
    .aaf_done           (                        )  // TODO
);

// AWB module
awb #(
    .DW  (24    ),
    .H   (1280  ),
    .V   (720   ),
    .HW  (11    ),
    .VW  (10    )
) awb_inst(
    .clk                 (clk                    ),
    .rstn                (rstn                   ),
    .awb_en              (awb_en                 ), // TODO
    .bayer_pattern       (bayer_pattern          ), // TODO
    .awb_clip            (awb_clip               ), // TODO
    .pixel_data_in       (pixel_data_rgb[AWB]    ),
    .pixel_data_in_vld   (pixel_data_vld[AWB]    ),
    .pixel_data_out      (pixel_data_rgb[AWB+1]  ),
    .pixel_data_out_vld  (pixel_data_vld[AWB+1]  ),
    .awb_done            (                       )  // TODO
);

// CNF module
cnf #(
    .DW  (24    ),
    .H   (1280  ),
    .V   (720   ),
    .HW  (11    ),
    .VW  (10    )
) cnf_inst(
    .clk                 (clk                    ),
    .rstn                (rstn                   ),
    .cnf_en              (cnf_en                 ), // TODO
    .thres               (cnf_thres              ), // TODO
    .bayer_pattern       (bayer_pattern          ), // TODO
    .cnf_clip            (cnf_clip               ), // TODO
    .pixel_data_in       (pixel_data_rgb[CNF]    ),
    .pixel_data_in_vld   (pixel_data_vld[CNF]    ),
    .pixel_data_out      (pixel_data_rgb[CNF+1]  ),
    .pixel_data_out_vld  (pixel_data_vld[CNF+1]  ),
    .cnf_done            (                       )  // TODO
);
 
// CFA module

cfa #(
    .DW  (24    ),
    .H   (1280  ),
    .V   (720   ),
    .HW  (11    ),
    .VW  (10    )
) cfa_inst(
    .clk                 (clk                    ),
    .rstn                (rstn                   ),
    .cfa_en              (cfa_en                 ), // TODO
    .bayer_pattern       (bayer_pattern          ), // TODO
    //.cfa_clip            (cfa_clip               ), // TODO
    .pixel_data_in       (pixel_data_rgb[CFA]    ),
    .pixel_data_in_vld   (pixel_data_vld[CFA]    ),
    .pixel_data_out_r    (pixel_data_rgb[CFA+1][DW-1:DW-8]  ),
    .pixel_data_out_g    (pixel_data_rgb[CFA+1][DW-9:DW-16] ),
    .pixel_data_out_b    (pixel_data_rgb[CFA+1][DW-17:DW-24]),
    .pixel_data_out_vld  (pixel_data_vld[CFA+1]  ),
    .cfa_done            (                       )  // TODO
);
 







//����HDMI����ģ��
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (pixel_clk),
    .pclk_x5        (pixel_clk_5x),
    .reset_n        (sys_rst_n & clk_locked),
                
    .video_din      (video_rgb),
    .video_hsync    (video_hs), 
    .video_vsync    (video_vs),
    .video_de       (video_de),
                
    .tmds_clk_p     (tmds_clk_p),
    .tmds_clk_n     (tmds_clk_n),
    .tmds_data_p    (tmds_data_p),
    .tmds_data_n    (tmds_data_n)
    );

endmodule 
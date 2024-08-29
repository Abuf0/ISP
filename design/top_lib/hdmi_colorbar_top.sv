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

module  hdmi_colorbar_top# (
    parameter DW = 24   ,
    parameter H  = 1280 ,
    parameter V  = 720  ,
    parameter HW = 11   ,
    parameter VW = 10   
)(
    input        sys_clk        ,
    input        sys_rst_n      , 
    input  [15:0]isp_enable     ,
    output       tmds_clk_p     ,    // TMDS ʱ��ͨ��
    output       tmds_clk_n     ,
    output [2:0] tmds_data_p    ,   // TMDS ����ͨ��
    output [2:0] tmds_data_n
   
);
parameter BW = 16;
//wire define
logic          pixel_clk;
logic          pixel_clk_5x;
logic          clk_locked;
logic          rst_pix_n;
logic  [10:0]  pixel_xpos_w;
logic  [10:0]  pixel_ypos_w;
logic  [23:0]  pixel_data_rgb[0:16];
logic          pixel_data_vld[0:16];
logic  [23:0]  buffer_data_rgb_csc;
logic  [23:0]  pixel_data_w;
logic  [BW-1:0]  pixel_data_bayer[0:16];
//logic  [15:0]  isp_enable;
logic [23:0]   pixel_data_out;
logic [23:0]   pixel_data_load   ;
logic [23:0]   pixel_data_update ;
logic          rd_rst            ;
logic          rd_en             ;
logic          wt_rst            ;
logic          wt_en             ;

logic          video_hs;
logic          video_vs;
logic          video_de;
logic  [23:0]  video_rgb;

logic [DW-1:0] dpc_thres;
logic [DW-1:0] dpc_clip;
logic [1:0] bayer_pattern;
logic [DW-1:0] blc_bias [0:3];
logic [DW-1:0] blc_clip;
logic [DW-1:0] awb_gain [0:3];
logic [DW-1:0] awb_clip;
logic [DW-1:0] cnf_gain;
logic [DW-1:0] cnf_clip;
logic [DW-1:0] cnf_thres;
logic [DW-1:0] cfa_clip;
logic [DW-1:0] ccm_coef_r [0:3];
logic [DW-1:0] ccm_coef_g [0:3];
logic [DW-1:0] ccm_coef_b [0:3];
logic signed [DW-1:0] csc_coef_r [0:3];
logic signed [DW-1:0] csc_coef_g [0:3];
logic signed [DW-1:0] csc_coef_b [0:3];
logic [DW-1:0] bnf_dw [0:4][0:4];   
logic [DW-1:0] bnf_rw [0:3]     ;     
logic [DW-1:0] bnf_rthres [0:2]   ;   
logic [DW-1:0] bnf_clip     ;         
logic [1:0] edge_filter [0:2][0:4] ;
logic [DW-1:0] eeh_clip [0:1]     ;    
logic [DW-1:0] eeh_rthres [0:1] ;      
logic [DW-1:0] eeh_gain [0:1]  ; 
logic signed [DW-1:0] eeh_emclip [0:1];      
logic [DW-1:0] bcc_brightness;
logic [DW-1:0] bcc_constrast ;
logic [DW-1:0] bcc_clip      ;
logic [DW-1:0] fcs_edge [0:1] ;
logic [DW-1:0] fcs_gain       ;
logic [DW-1:0] fcs_intercept  ;
logic [DW-1:0] fcs_slop       ;
logic [DW-1:0] hue_cos          ;
logic [DW-1:0] hue_sin          ;
logic [DW-1:0] hsc_saturation   ;
logic [DW-1:0] hsc_clip         ;

assign dpc_thres = 30;
assign dpc_clip  = 250;
assign bayer_pattern = 2'd0;

assign blc_bias[0] = 'd0;
assign blc_bias[1] = 'd0;
assign blc_bias[2] = 'd0;
assign blc_bias[3] = 'd0;
assign blc_clip = 250;

assign awb_gain[0] = 384;  // 1.5 << 8
assign awb_gain[1] = 256;  // 1.0 << 8
assign awb_gain[2] = 256;  // 1.0 << 8
assign awb_gain[3] = 128;  // 0.5 << 8

assign awb_clip = 250;

assign cnf_gain[0] = 384;  // 1.5 << 8
assign cnf_gain[1] = 256;  // 1.0 << 8
assign cnf_gain[2] = 256;  // 1.0 << 8
assign cnf_gain[3] = 128;  // 0.5 << 8

assign cnf_clip = 1023;
assign cnf_thres = 0;
assign cfa_clip = 1023;

assign ccm_coef_r[0] = 1024 ;
assign ccm_coef_g[0] = 0    ;
assign ccm_coef_b[0] = 0    ;
assign csc_coef_r[0] = 263  ;
assign csc_coef_g[0] = -152 ;
assign csc_coef_b[0] = 450  ;

assign ccm_coef_r[1] = 0        ;
assign ccm_coef_g[1] =  1024    ;
assign ccm_coef_b[1] =  0       ;
assign csc_coef_r[1] =  516     ;
assign csc_coef_g[1] = -298     ;
assign csc_coef_b[1] = -377     ;

assign ccm_coef_r[2] = 0        ;
assign ccm_coef_g[2] =  0       ;
assign ccm_coef_b[2] =  1024    ;
assign csc_coef_r[2] =  100     ;
assign csc_coef_g[2] = 450      ;
assign csc_coef_b[2] = 73       ;

assign ccm_coef_r[3] =  0       ;
assign ccm_coef_g[3] =  0       ;
assign ccm_coef_b[3] =  0       ;
assign csc_coef_r[3] =  16384   ;
assign csc_coef_g[3] = 32768    ;
assign csc_coef_b[3] = 32768    ;

assign bnf_dw[0][0] = 8	    ;
assign bnf_dw[0][1] = 12    ;	
assign bnf_dw[0][2] = 32    ;	
assign bnf_dw[0][3] = 12    ;	
assign bnf_dw[0][4] = 8	    ;
assign bnf_dw[1][0] = 12    ;	
assign bnf_dw[1][1] = 64    ;	
assign bnf_dw[1][2] = 128	;    
assign bnf_dw[1][3] = 64	;    
assign bnf_dw[1][4] = 12	;    
assign bnf_dw[2][0] = 32	;    
assign bnf_dw[2][1] = 128	;    
assign bnf_dw[2][2] = 1024  ;
assign bnf_dw[2][3] = 128	;
assign bnf_dw[2][4] = 32	;
assign bnf_dw[3][0] = 12	;
assign bnf_dw[3][1] = 64	;
assign bnf_dw[3][2] = 128	;
assign bnf_dw[3][3] = 64	;
assign bnf_dw[3][4] = 12	;
assign bnf_dw[4][0] = 8	    ;
assign bnf_dw[4][1] = 12	;
assign bnf_dw[4][2] = 32	;
assign bnf_dw[4][3] = 12	;
assign bnf_dw[4][4] = 8	    ;
assign bnf_rw[0] =0	        ;
assign bnf_rw[1] =8	        ;
assign bnf_rw[2] =16	    ;  
assign bnf_rw[3] =32	    ; 
assign bnf_rthres[0] = 128  ;
assign bnf_rthres[1] = 32   ;
assign bnf_rthres[2] = 8	;    
assign bnf_clip = 255	    ; 
assign edge_filter[0][0] = -1;
assign edge_filter[0][1] = 0 ; 	    
assign edge_filter[0][2] = -1;
assign edge_filter[0][3] = 0 ; 	    
assign edge_filter[0][4] = -1;
assign edge_filter[1][0] = -1;
assign edge_filter[1][1] = 0 ; 	
assign edge_filter[1][2] = 8 ;
assign edge_filter[1][3] = 0 ; 	
assign edge_filter[1][4] = -1;
assign edge_filter[2][0] = -1;
assign edge_filter[2][1] = 0 ; 	
assign edge_filter[2][2] = -1;
assign edge_filter[2][3] = 0 ; 	
assign edge_filter[2][4] = -1;
assign eeh_gain[0] = 32	    ;     
assign eeh_gain[1] = 128	    ; 
assign eeh_rthres[0] = 32	    ; 
assign eeh_rthres[1] = 64	    ; 
assign eeh_emclip[0] = -64	;   
assign eeh_emclip[1] = 64	;   
assign brightness = 10      ;
assign contrast = 10        ;
assign bcc_clip = 255       ;
assign fcs_edge[0] = 64     ;
assign fcs_edge[1] = 32     ;
assign fcs_gain = 32        ;
assign fcs_intercept = 2    ;
assign fcs_slop = 3         ;

assign hue_cos        = 128;
assign hue_sin        = 180;
assign hsc_saturation = 256 ;
assign hsc_clip       = 255 ;

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
parameter BCC = 15  ;


//assign isp_enable = 16'h0000;
//*****************************************************
//**                    main code
//*****************************************************

`ifdef FPGA
//����MMCM/PLL IP��
clk_wiz_0  clk_wiz_0(
    .clk_in1        (sys_clk),
    .clk_out1       (pixel_clk),        //����ʱ��
    .clk_out2       (pixel_clk_5x),     //5������ʱ��
    
    .reset          (~sys_rst_n), 
    .locked         (clk_locked)
);
assign rst_pix_n = sys_rst_n;
`else
crgu crgu_inst(
    .clk_in     (sys_clk        ),
    .rstn_in    (sys_rst_n      ),
    .clk_out1   (pixel_clk      ),
    .clk_out2   (pixel_clk_5x   ),
    .rstn_out1  (rst_pix_n      )
);
`endif

//������Ƶ��ʾ����ģ��
video_driver u_video_driver(
    .pixel_clk      (pixel_clk),
    .sys_rst_n      (rst_pix_n),

    .video_hs       (video_hs),
    .video_vs       (video_vs),
    .video_de       (video_de),
    .video_rgb      (video_rgb),

    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    //.pixel_data     (pixel_data_w)    // show raw img
    .pixel_data     (pixel_data_out)    // show dpc img
    );

    assign pixel_data_out = pixel_data_rgb[BCC+1];  // TODO

//������Ƶ��ʾģ��
video_display  u_video_display(
    .pixel_clk          (pixel_clk          ),
    .sys_rst_n          (rst_pix_n          ),

    .pixel_xpos         (pixel_xpos_w       ),
    .pixel_ypos         (pixel_ypos_w       ),
    .pixel_data_load    (pixel_data_load    ),
    .pixel_data_update  (pixel_data_update  ),
    .rd_rst             (rd_rst             ),
    .rd_en              (rd_en              ),
    .wt_rst             (wt_rst             ),
    .wt_en              (wt_en              ),
    .pixel_data         (pixel_data_rgb[0]  ),
    .pixel_data_vld     (pixel_data_vld[0]  )
    );

// TODO
assign rd_rst = 0;
assign wt_rst = 0;
assign rd_en = 0;
assign wt_en = 0;
assign pixel_data_update = 'd0;

// DPC module
dpc #(
    .DPC_MODE   (0   ), 
    .DW         (BW   ),
    .H          (H    ),
    .V          (V    ),
    .HW         (HW   ),
    .VW         (VW   )
) dpc_inst(
    .clk                (pixel_clk               ),
    .rstn               (rst_pix_n               ),
    .dpc_en             (isp_enable[DPC]         ), // TODO
    .thres              (dpc_thres               ),
    .clip               (dpc_clip                ),
    .pixel_data_in_vld  (pixel_data_vld[DPC]     ), // TODO
    .pixel_data_in      (pixel_data_bayer[DPC]   ),
    .pixel_data_out_vld (pixel_data_vld[DPC+1]   ),
    .pixel_data_out     (pixel_data_bayer[DPC+1] )
);
assign pixel_data_bayer[DPC] = pixel_data_rgb[DPC][BW-1:0];

// BLC module
blc #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) blc_inst(
    .clk                (pixel_clk              ),
    .rstn               (rst_pix_n              ),
    .blc_en             (isp_enable[BLC]        ),   // TODO
    .bayer_pattern      (bayer_pattern          ), // TODO
    .bias               (blc_bias               ),
    .alpha              ( 0                     ),
    .beta               ( 0                     ),
    .blc_clip           (blc_clip               ),
    .pixel_data_in_vld  (pixel_data_vld[BLC]    ), 
    .pixel_data_in      (pixel_data_bayer[BLC]  ),
    .pixel_data_out_vld (pixel_data_vld[BLC+1]  ),
    .pixel_data_out     (pixel_data_bayer[BLC+1])
);

// AAF module
aaf #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) aaf_inst(
    .clk                (pixel_clk               ),
    .rstn               (rst_pix_n               ),
    .aaf_en             (isp_enable[AAF]         ), // TODO
    .pixel_data_in_vld  (pixel_data_vld[AAF]     ), 
    .pixel_data_in      (pixel_data_bayer[AAF]   ),
    .pixel_data_out_vld (pixel_data_vld[AAF+1]   ),
    .pixel_data_out     (pixel_data_bayer[AAF+1] ),
    .aaf_done           (                        )  // TODO
);

// AWB module
awb #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) awb_inst(
    .clk                 (pixel_clk              ),
    .rstn                (rst_pix_n              ),
    .awb_en              (isp_enable[AWB]        ), // TODO
    .bayer_pattern       (bayer_pattern          ), // TODO
    .awb_gain            (awb_gain               ),
    .awb_clip            (awb_clip               ), // TODO
    .pixel_data_in       (pixel_data_bayer[AWB]  ),
    .pixel_data_in_vld   (pixel_data_vld[AWB]    ),
    .pixel_data_out      (pixel_data_bayer[AWB+1]),
    .pixel_data_out_vld  (pixel_data_vld[AWB+1]  )//,
    //.awb_done            (                       )  // TODO
);

// CNF module -- RGB
cnf #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) cnf_inst(
    .clk                 (pixel_clk              ),
    .rstn                (rst_pix_n              ),
    .cnf_en              (isp_enable[CNF]        ), // TODO
    .thres               (cnf_thres              ), // TODO
    .cnf_gain            (cnf_gain               ),
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
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) cfa_inst(
    .clk                 (pixel_clk              ),
    .rstn                (rst_pix_n              ),
    .cfa_en              (isp_enable[CFA]        ), // TODO
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
 
// CCM module

ccm #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) ccm_inst(
    .clk               (pixel_clk                              ),
    .rstn              (rst_pix_n                              ),
   .ccm_en             (isp_enable[CCM]                        ),
   .ccm_coef_r         (ccm_coef_r                             ),
   .ccm_coef_g         (ccm_coef_g                             ),
   .ccm_coef_b         (ccm_coef_b                             ),
   .pixel_data_in_vld  (pixel_data_vld[CCM]                 ), 
   .pixel_data_in_r    (pixel_data_rgb[CCM][DW-1:DW-8]         ),
   .pixel_data_in_g    (pixel_data_rgb[CCM][DW-9:DW-16]        ),
   .pixel_data_in_b    (pixel_data_rgb[CCM][DW-17:DW-24]       ),
   .pixel_data_out_vld (pixel_data_vld[CCM+1]                ),
   .pixel_data_out_r   (pixel_data_rgb[CCM+1][DW-1:DW-8]       ),
   .pixel_data_out_g   (pixel_data_rgb[CCM+1][DW-9:DW-16]      ),
   .pixel_data_out_b   (pixel_data_rgb[CCM+1][DW-17:DW-24]     ),
   .ccm_done           (                                       )   
);

// GAC module

gac #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) gac_inst(
    .clk                 (pixel_clk              ),
    .rstn                (rst_pix_n              ),
    .gac_en              (isp_enable[GAC]     ),
    .pixel_data_in_vld   (pixel_data_vld[GAC]              ),
    .pixel_data_in_r     (pixel_data_rgb[GAC][DW-1:DW-8]      ),
    .pixel_data_in_g     (pixel_data_rgb[GAC][DW-9:DW-16]     ),
    .pixel_data_in_b     (pixel_data_rgb[GAC][DW-17:DW-24]    ),
    .pixel_data_out_vld  (pixel_data_vld[GAC+1]             ),
    .pixel_data_out_r    (pixel_data_rgb[GAC+1][DW-1:DW-8]    ),
    .pixel_data_out_g    (pixel_data_rgb[GAC+1][DW-9:DW-16]   ),
    .pixel_data_out_b    (pixel_data_rgb[GAC+1][DW-17:DW-24]  ),
    .gac_done            (                    ),
    .lut_din_vld         (1'b0                ),
    .lut_din             (0                   ),           
    .lut_dout            (                    )    
);

// CSC module

csc #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) csc_inst(
    .clk                 (pixel_clk              ),
    .rstn                (rst_pix_n              ),
   .csc_en             (isp_enable[CSC]                        ),
   .csc_coef_r         (csc_coef_r                             ),
   .csc_coef_g         (csc_coef_g                             ),
   .csc_coef_b         (csc_coef_b                             ),
   .pixel_data_in_vld  (pixel_data_vld[CSC]                 ), 
   .pixel_data_in_r    (pixel_data_rgb[CSC][DW-1:DW-8]         ),
   .pixel_data_in_g    (pixel_data_rgb[CSC][DW-9:DW-16]        ),
   .pixel_data_in_b    (pixel_data_rgb[CSC][DW-17:DW-24]       ),
   .pixel_data_out_vld (pixel_data_vld[CSC+1]                ),
   .pixel_data_out_r   (pixel_data_rgb[CSC+1][DW-1:DW-8]       ),
   .pixel_data_out_g   (pixel_data_rgb[CSC+1][DW-9:DW-16]      ),
   .pixel_data_out_b   (pixel_data_rgb[CSC+1][DW-17:DW-24]     ),
   .csc_done           (                                       )   
);

// NLM module

nlm #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) nlm_inst(
    .clk                (pixel_clk               ),
    .rstn               (rst_pix_n               ),
    .nlm_en             (isp_enable[NLM]         ), // TODO
    .pixel_data_in_vld  (pixel_data_vld[NLM]     ), 
    .pixel_data_in      (pixel_data_rgb[NLM]     ),
    .pixel_data_out_vld (pixel_data_vld[NLM+1]   ),
    .pixel_data_out     (pixel_data_rgb[NLM+1]   ),
    .nlm_done           (                        )  // TODO
);

// BNF module

bnf #(
    .DW  (DW  ),
    .H   (H   ),
    .V   (V   ),
    .HW  (HW  ),
    .VW  (VW  )
) bnf_inst(
    .clk                (pixel_clk               ),
    .rstn               (rst_pix_n               ),
    .bnf_en             (isp_enable[BNF]         ), // TODO
    //.dw                 (bnf_dw [0:4][0:4]       ), // TODO
    //.rw                 (bnf_rw [0:3]            ), // TODO
    //.rthres             (bnf_rthres [0:2]        ), // TODO
    .dw                 (bnf_dw                  ), // TODO
    .rw                 (bnf_rw                  ), // TODO
    .rthres             (bnf_rthres              ), // TODO
    .bnf_clip           (bnf_clip                ), // TODO
    .pixel_data_in_vld  (pixel_data_vld[BNF]     ), 
    .pixel_data_in      (pixel_data_rgb[BNF]     ),
    .pixel_data_out_vld (pixel_data_vld[BNF+1]   ),
    .pixel_data_out     (pixel_data_rgb[BNF+1]   ),
    .bnf_done           (                        )  // TODO
);

// EEH module

eeh #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) eeh_inst(
    .clk                (pixel_clk               ),
    .rstn               (rst_pix_n               ),
    .eeh_en             (isp_enable[EEH]         ), // TODO
    //.edge_filter        (edge_filter [0:2][0:4]  ), // TODO
    //.eeh_clip           (eeh_clip [0:1]          ), // TODO 
    //.eeh_rthres         (eeh_rthres [0:1]        ), // TODO
    //.eeh_gain           (eeh_gain [0:1]          ), // TODO
    .edge_filter        (edge_filter              ), // TODO
    .eeh_clip           (eeh_clip                 ), // TODO
    .eeh_rthres         (eeh_rthres               ), // TODO
    .eeh_gain           (eeh_gain                ), // TODO 
    .pixel_data_in_vld  (pixel_data_vld[EEH]     ), 
    .pixel_data_in      (pixel_data_rgb[EEH]     ),
    .pixel_data_out_vld (pixel_data_vld[EEH+1]   ),
    .pixel_data_out_em  (pixel_data_rgb[BCC]    ),
    .pixel_data_out_ee  (pixel_data_rgb[EEH]    ),
    .eeh_done           (                        )  // TODO
);
assign pixel_data_vld[BCC] = pixel_data_vld[EEH+1];

// BCC module

bcc #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) bcc_inst(
    .clk                (pixel_clk               ),
    .rstn               (rst_pix_n               ),
    .bcc_en             (isp_enable[BCC]         ), // TODO
    .brightness         (bcc_brightness          ), // TODO
    .constrast          (bcc_constrast           ), // TODO
    .bcc_clip           (bcc_clip                ), // TODO   
    .pixel_data_in_vld  (pixel_data_vld[BCC]     ), 
    .pixel_data_in      (pixel_data_rgb[BCC]     ),
    .pixel_data_out_vld (pixel_data_vld[BCC+1]   ),
    .pixel_data_out     (pixel_data_rgb[BCC+1]   ),
    .bcc_done           (                        )  // TODO
);

// FCS module

fcs #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) fcs_inst(
    .clk                    (pixel_clk               ),
    .rstn                   (rst_pix_n               ),
    .fcs_en                 (isp_enable[FCS]         ), // TODO
    .fcs_edge               (fcs_edge [0:1]          ), // TODO
    .gain                   (fcs_gain                ), // TODO
    .intercept              (fcs_intercept           ), // TODO
    .slop                   (fcs_slop                ), // TODO
    .pixel_data_in_vld      (pixel_data_vld[FCS]     ), 
    .pixel_data_in_edgemap  (pixel_data_rgb[FCS]     ),
    .buffer_data_in_ccs_y   (buffer_data_rgb_csc[DW-1:DW-8]  ),  // TODO
    .buffer_data_in_ccs_cr  (buffer_data_rgb_csc[DW-9:DW-16] ),  // TODO
    .buffer_data_in_ccs_cb  (buffer_data_rgb_csc[DW-17:DW-24]),  // TODO
    .pixel_data_out_vld     (pixel_data_vld[FCS+1]      ),
    .pixel_data_out_y       (pixel_data_rgb[FCS+1][DW-1:DW-8]  ),
    .pixel_data_out_cr      (pixel_data_rgb[FCS+1][DW-9:DW-16] ),
    .pixel_data_out_cb      (pixel_data_rgb[FCS+1][DW-17:DW-24]),
    .fcs_done               (                        )  // TODO
);

// HSC module

hsc #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) hsc_inst(
    .clk                    (pixel_clk               ),
    .rstn                   (rst_pix_n               ),
    .hsc_en                 (isp_enable[HSC]         ), // TODO
    .hue_cos                (hue_cos                 ), // TODO
    .hue_sin                (hue_sin                 ), // TODO
    .saturation             (hsc_saturation          ), // TODO
    .clip                   (hsc_clip                ), // TODO
    .pixel_data_in_vld      (pixel_data_vld[HSC]     ),
    .buffer_data_in_ccs_cr  (pixel_data_rgb[HSC][DW-9:DW-16] ),  // TODO
    .buffer_data_in_ccs_cb  (pixel_data_rgb[HSC][DW-17:DW-24]),  // TODO
    .pixel_data_out_vld     (pixel_data_vld[HSC+1]   ),
    //.pixel_data_out         (pixel_data_rgb[HSC+1][DW-9:0]   ),
    .pixel_data_out_cr      (pixel_data_rgb[HSC+1][DW-9:DW-16] ),
    .pixel_data_out_cb      (pixel_data_rgb[HSC+1][DW-17:DW-24]),
    .hsc_done               (                        )  // TODO
);

`ifdef  FPGA
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (pixel_clk),
    .pclk_x5        (pixel_clk_5x),
    .reset_n        (rst_pix_n & clk_locked),
    .video_din      (video_rgb),
    .video_hsync    (video_hs), 
    .video_vsync    (video_vs),
    .video_de       (video_de),
                
    .tmds_clk_p     (tmds_clk_p),
    .tmds_clk_n     (tmds_clk_n),
    .tmds_data_p    (tmds_data_p),
    .tmds_data_n    (tmds_data_n)
    );
`endif

endmodule 
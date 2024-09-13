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
    parameter H  = 128  ,
    parameter V  = 72   ,
    parameter HW = 11   ,
    parameter VW = 10   
)(
    input        sys_clk        ,
    input        sys_rst_n      , 
    output       tmds_clk_p     ,    // TMDS ʱ��ͨ��
    output       tmds_clk_n     ,
    output [2:0] tmds_data_p    ,   // TMDS ����ͨ��
    output [2:0] tmds_data_n
   
);
parameter BW = 16;
parameter CSC_FIFO_DEEPTH = 16 * H ;
parameter BCC_FIFO_DEEPTH = 4 * H ;

//wire define
logic          pixel_clk;
logic          pixel_clk_5x;
logic          clk_locked;
logic          rst_pix_n;
logic  [10:0]  pixel_xpos_w;
logic  [10:0]  pixel_ypos_w;
logic  [DW-1:0]  pixel_data_rgb[0:16];
logic          pixel_data_vld[0:16];
logic  [23:0]  buffer_data_rgb_csc;
logic  [23:0]  pixel_data_w;
logic  [BW-1:0]  pixel_data_bayer[0:16];
logic  [15:0]  isp_enable;
logic [DW-1:0] pixel_data_out;
logic [DW-1:0] pixel_data_load   ;
logic [DW-1:0] pixel_data_update ;
logic          rd_rst            ;
logic          rd_en             ;
logic          wt_rst            ;
logic          wt_en             ;

logic          video_hs;
logic          video_vs;
logic          video_de;
logic  [23:0]  video_rgb;

// isp_top module config //
//logic [3:0]  isp_seq [0:15];   // ISP顺序，寄存器配置
logic [BW-1:0] dpc_thres;
logic [BW-1:0] dpc_clip;
logic [1:0] bayer_pattern;
logic [BW-1:0] blc_bias [0:3];
logic [BW-1:0] blc_clip;
logic [BW-1:0] awb_gain [0:3];
logic [BW-1:0] awb_clip;
logic [BW-1:0] cnf_gain [0:3];
logic [BW-1:0] cnf_clip;
logic [BW-1:0] cnf_thres;
logic [BW-1:0] cfa_clip;
logic [DW-1:0] ccm_coef_r [0:3];
logic [DW-1:0] ccm_coef_g [0:3];
logic [DW-1:0] ccm_coef_b [0:3];
logic signed [DW-1:0] csc_coef_r [0:3];
logic signed [DW-1:0] csc_coef_g [0:3];
logic signed [DW-1:0] csc_coef_b [0:3];
logic [DW-1:0] nlm_clip;
logic [DW-1:0] bnf_dw [0:4][0:4];   
logic [DW-1:0] bnf_rw [0:3]     ;     
logic [DW-1:0] bnf_rthres [0:2]   ;   
logic [DW-1:0] bnf_clip     ;         
logic signed [4:0] edge_filter [0:2][0:4] ;
logic [DW-1:0] eeh_rthres [0:1] ;      
logic [DW-1:0] eeh_gain [0:1]  ; 
logic signed [DW:0] eeh_emclip [0:1];      
logic [DW-1:0] bcc_brightness;
logic [DW-1:0] bcc_contrast ;
logic [DW-1:0] bcc_clip      ;
logic [DW/3-1:0] fcs_edge [0:1] ;
logic [DW/3-1:0] fcs_gain       ;
logic [DW/3-1:0] fcs_intercept  ;
logic [DW/3-1:0] fcs_slop       ;
logic [DW/3-1:0] fcs_clip       ;
logic signed [DW/3:0] hue_cos          ;
logic signed [DW/3:0] hue_sin          ;
logic [DW/3-1:0] hsc_saturation   ;
logic [DW/3-1:0] hsc_clip         ;

parameter DPC = 4'd0   ;
parameter BLC = 4'd1   ;
parameter AAF = 4'd2   ;
parameter AWB = 4'd3   ;
parameter CNF = 4'd4   ;
parameter CFA = 4'd5   ;
parameter CCM = 4'd6   ;
parameter GAC = 4'd7   ;
parameter CSC = 4'd8   ;
parameter NLM = 4'd9   ;
parameter BNF = 4'd10  ;
parameter EEH = 4'd11  ;
parameter FCS = 4'd12  ;
parameter HSC = 4'd13  ;
parameter BCC = 4'd15  ;

// TODO -- replaced by regmap
assign isp_enable = 16'h0000;

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
assign cnf_clip = 250;
assign cnf_thres = 0;

assign cfa_clip = 250;

assign ccm_coef_r[0] = 1024     ;
assign ccm_coef_g[0] = 0        ;
assign ccm_coef_b[0] = 0        ;
assign ccm_coef_r[1] = 0        ;
assign ccm_coef_g[1] =  1024    ;
assign ccm_coef_b[1] =  0       ;
assign ccm_coef_r[2] = 0        ;
assign ccm_coef_g[2] =  0       ;
assign ccm_coef_b[2] =  1024    ;
assign ccm_coef_r[3] =  0       ;
assign ccm_coef_g[3] =  0       ;
assign ccm_coef_b[3] =  0       ;

assign csc_coef_r[0] = -73      ;
assign csc_coef_g[0] = 450      ;
assign csc_coef_b[0] = 100      ;
assign csc_coef_r[1] =  -377    ;
assign csc_coef_g[1] = -298     ;
assign csc_coef_b[1] = 516      ;
assign csc_coef_r[2] =  450     ;
assign csc_coef_g[2] = -152     ;
assign csc_coef_b[2] = 263      ;
assign csc_coef_r[3] =  128   ;
assign csc_coef_g[3] = 128    ;
assign csc_coef_b[3] = 16    ;

assign nlm_clip = 250;

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

assign bcc_brightness = 10      ;
assign bcc_contrast = 10        ;
assign bcc_clip = 255       ;

assign fcs_edge[0] = 32     ;
assign fcs_edge[1] = 64     ;
assign fcs_gain = 32        ;
assign fcs_intercept = 2    ;
assign fcs_slop = 3         ;
assign fcs_clip = 255       ;

assign hue_cos        = -158;
assign hue_sin        = 202;
assign hsc_saturation = 256 ;
assign hsc_clip       = 255 ;

// TODO -- end

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
    .clk_out1   (pixel_clk_5x   ),
    .clk_out2   (pixel_clk      ),
    .rstn_out1  (rst_pix_n      )
);
`endif

//������Ƶ��ʾ����ģ��
video_driver #(
    .H_DISP(H   ),
    .V_DISP(V   )
)u_video_driver(
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

//    assign pixel_data_out = pixel_data_rgb[BCC+1];  // TODO

//������Ƶ��ʾģ��
video_display #(
    .H_DISP(H   ),
    .V_DISP(V   )
) u_video_display(
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

isp_top #(
    .DW  (DW   ),
    .BW  (BW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) isp_top_inst(
    .clk                 ( pixel_clk          ),
    .rstn                ( rst_pix_n          ),
    .isp_enable          ( isp_enable         ),
    .isp_seq             ( isp_seq            ),
    .bayer_pattern       ( bayer_pattern      ),
    .dpc_thres           ( dpc_thres          ),        
    .dpc_clip            ( dpc_clip           ),        
    .blc_bias            ( blc_bias           ),        
    .blc_clip            ( blc_clip           ),        
    .awb_gain            ( awb_gain           ),        
    .awb_clip            ( awb_clip           ),        
    .cnf_gain            ( cnf_gain           ),         
    .cnf_clip            ( cnf_clip           ),         
    .cnf_thres           ( cnf_thres          ),        
    .cfa_clip            ( cfa_clip           ),        
    .ccm_coef_r          ( ccm_coef_r         ),        
    .ccm_coef_g          ( ccm_coef_g         ),        
    .ccm_coef_b          ( ccm_coef_b         ),        
    .csc_coef_r          ( csc_coef_r         ),        
    .csc_coef_g          ( csc_coef_g         ),        
    .csc_coef_b          ( csc_coef_b         ),        
    .nlm_clip            ( nlm_clip           ),        
    .bnf_dw              ( bnf_dw             ),        
    .bnf_rw              ( bnf_rw             ),        
    .bnf_rthres          ( bnf_rthres         ),        
    .bnf_clip            ( bnf_clip           ),        
    .edge_filter         ( edge_filter        ),        
    .eeh_rthres          ( eeh_rthres         ),        
    .eeh_gain            ( eeh_gain           ),        
    .eeh_emclip          ( eeh_emclip         ),        
    .bcc_brightness      ( bcc_brightness     ),               
    .bcc_contrast        ( bcc_contrast       ),                
    .bcc_clip            ( bcc_clip           ),                     
    .fcs_edge            ( fcs_edge           ),             
    .fcs_gain            ( fcs_gain           ),             
    .fcs_intercept       ( fcs_intercept      ),            
    .fcs_slop            ( fcs_slop           ),                     
    .fcs_clip            ( fcs_clip           ),                     
    .hue_cos             ( hue_cos            ),        
    .hue_sin             ( hue_sin            ),        
    .hsc_saturation      ( hsc_saturation     ),              
    .hsc_clip            ( hsc_clip           ),                    
    .pixel_data_in       ( pixel_data_rgb[0]  ),                      
    .pixel_data_in_vld   ( pixel_data_vld[0]  ),            
    .pixel_data_out      (          ),                 
    .pixel_data_out_vld  (          ),             
    .one_frame_done      (          ),                    
    .ebd_data            (          )         
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
module reg_top (
input               clk                        ,
input               arst_n                     ,
input               s_cpuif_req                ,
input               s_cpuif_req_is_wr          ,
input [13:0]        s_cpuif_addr               ,
input [15:0]        s_cpuif_wr_data            ,
input [15:0]        s_cpuif_wr_biten           ,
output              s_cpuif_req_stall_wr       ,
output              s_cpuif_req_stall_rd       ,
output              s_cpuif_rd_ack             ,
output              s_cpuif_rd_err             ,
output [15:0]       s_cpuif_rd_data            ,
output              s_cpuif_wr_ack             ,
output              s_cpuif_wr_err             ,
output [15:0]       rg_isp_enable              ,
output [16-1:0]     rg_dpc_thres               ,
output [16-1:0]     rg_dpc_clip                ,
output [1:0]        rg_bayer_pattern           ,
output [16-1:0]     rg_blc_bias [0:3]          ,
output [16-1:0]     rg_blc_clip                ,
output [16-1:0]     rg_awb_gain [0:3]          ,
output [16-1:0]     rg_awb_clip                ,
output [16-1:0]     rg_cnf_gain [0:3]          ,
output [16-1:0]     rg_cnf_clip                ,
output [16-1:0]     rg_cnf_thres               ,
output [16-1:0]     rg_cfa_clip                ,
output [24-1:0]     rg_ccm_coef_r [0:3]        ,
output [24-1:0]     rg_ccm_coef_g [0:3]        ,
output [24-1:0]     rg_ccm_coef_b [0:3]        ,
output logic signed [24-1:0]     rg_csc_coef_r [0:3]        ,   // TODO for port connection error
output logic signed [24-1:0]     rg_csc_coef_g [0:3]        ,   // TODO for port connection error
output logic signed [24-1:0]     rg_csc_coef_b [0:3]        ,   // TODO for port connection error
output [24-1:0]     rg_nlm_clip                ,
output [24-1:0]     rg_bnf_dw [0:4][0:4]       ,   
output [24-1:0]     rg_bnf_rw [0:3]            ,     
output [24-1:0]     rg_bnf_rthres [0:2]        ,   
output [24-1:0]     rg_bnf_clip                ,         
output logic signed [4:0]        rg_edge_filter [0:2][0:4]  ,   // TODO for port connection error
output [24-1:0]     rg_eeh_rthres [0:1]        ,      
output [24-1:0]     rg_eeh_gain [0:1]          , 
output logic signed [24:0]       rg_eeh_emclip [0:1]        ,   // TODO for port connection error      
output [24-1:0]     rg_bcc_brightness          ,
output [24-1:0]     rg_bcc_contrast            ,
output [24-1:0]     rg_bcc_clip                ,
output [24/3-1:0]   rg_fcs_edge [0:1]          ,
output [24/3-1:0]   rg_fcs_gain                ,
output [24/3-1:0]   rg_fcs_intercept           ,
output [24/3-1:0]   rg_fcs_slop                ,
output [24/3-1:0]   rg_fcs_clip                ,
output [24/3:0]     rg_hue_cos                 ,
output [24/3:0]     rg_hue_sin                 ,
output [24/3-1:0]   rg_hsc_saturation          ,
output [24/3-1:0]   rg_hsc_clip                ,
output [5:0]        rg_i2cs_id                 ,
output              rg_i2cs_id_en              ,
output              rg_pixel_ckgt_en           
);                             

// Signal assignments between simple and structured signal
//regmap_pkg::regmap__in_t hwif_in;
regmap_pkg::regmap__out_t hwif_out;

assign rg_isp_enable          =   hwif_out.isp_config.isp_enable_cfg.rg_isp_enable.value[15:0]     ;   
assign rg_bayer_pattern       =   hwif_out.isp_config.bayer_pattern_cfg.rg_bayer_pattern.value[1:0]    ;      
assign rg_dpc_thres           =   hwif_out.isp_config.dpc_thres_cfg.rg_dpc_thres.value[15:0]   ;   
assign rg_dpc_clip            =   hwif_out.isp_config.dpc_clip_cfg.rg_dpc_clip.value[15:0]     ;   
assign rg_blc_bias[0]         =   hwif_out.isp_config.blc_bias_0_cfg.rg_blc_bias_0.value[15:0]     ;   
assign rg_blc_bias[1]         =   hwif_out.isp_config.blc_bias_1_cfg.rg_blc_bias_1.value[15:0]     ;   
assign rg_blc_bias[2]         =   hwif_out.isp_config.blc_bias_2_cfg.rg_blc_bias_2.value[15:0]     ;   
assign rg_blc_bias[3]         =   hwif_out.isp_config.blc_bias_3_cfg.rg_blc_bias_3.value[15:0]     ;   
assign rg_blc_clip            =   hwif_out.isp_config.blc_clip_cfg.rg_blc_clip.value[15:0]     ;      
assign rg_awb_gain[0]         =   hwif_out.isp_config.awb_gain_0_cfg.rg_awb_gain_0.value[15:0]     ;       
assign rg_awb_gain[1]         =   hwif_out.isp_config.awb_gain_1_cfg.rg_awb_gain_1.value[15:0]     ;       
assign rg_awb_gain[2]         =   hwif_out.isp_config.awb_gain_2_cfg.rg_awb_gain_2.value[15:0]     ;       
assign rg_awb_gain[3]         =   hwif_out.isp_config.awb_gain_3_cfg.rg_awb_gain_3.value[15:0]     ;       
assign rg_awb_clip            =   hwif_out.isp_config.awb_clip_cfg.rg_awb_clip.value[15:0]     ;       
assign rg_cnf_gain[0]         =   hwif_out.isp_config.cnf_gain_0_cfg.rg_cnf_gain_0.value[15:0]     ;       
assign rg_cnf_gain[1]         =   hwif_out.isp_config.cnf_gain_1_cfg.rg_cnf_gain_1.value[15:0]     ;       
assign rg_cnf_gain[2]         =   hwif_out.isp_config.cnf_gain_2_cfg.rg_cnf_gain_2.value[15:0]     ;       
assign rg_cnf_gain[3]         =   hwif_out.isp_config.cnf_gain_3_cfg.rg_cnf_gain_3.value[15:0]     ;       
assign rg_cnf_clip            =   hwif_out.isp_config.cnf_clip_cfg.rg_cnf_clip.value[15:0]     ;   
assign rg_cnf_thres           =   hwif_out.isp_config.cnf_thres_cfg.rg_cnf_thres.value[15:0]   ;      
assign rg_cfa_clip            =   hwif_out.isp_config.cfa_clip_cfg.rg_cfa_clip.value[15:0]     ;   
assign rg_ccm_coef_r[0]       =   hwif_out.isp_config.ccm_coef_r_0_cfg.rg_ccm_coef_r_0.value[15:0]     ;           
assign rg_ccm_coef_r[1]       =   hwif_out.isp_config.ccm_coef_r_1_cfg.rg_ccm_coef_r_1.value[15:0]     ;           
assign rg_ccm_coef_r[2]       =   hwif_out.isp_config.ccm_coef_r_2_cfg.rg_ccm_coef_r_2.value[15:0]     ;           
assign rg_ccm_coef_r[3]       =   hwif_out.isp_config.ccm_coef_r_3_cfg.rg_ccm_coef_r_3.value[15:0]     ;           
assign rg_ccm_coef_g[0]       =   hwif_out.isp_config.ccm_coef_g_0_cfg.rg_ccm_coef_g_0.value[15:0]     ;           
assign rg_ccm_coef_g[1]       =   hwif_out.isp_config.ccm_coef_g_1_cfg.rg_ccm_coef_g_1.value[15:0]     ;           
assign rg_ccm_coef_g[2]       =   hwif_out.isp_config.ccm_coef_g_2_cfg.rg_ccm_coef_g_2.value[15:0]     ;           
assign rg_ccm_coef_g[3]       =   hwif_out.isp_config.ccm_coef_g_3_cfg.rg_ccm_coef_g_3.value[15:0]     ;           
assign rg_ccm_coef_b[0]       =   hwif_out.isp_config.ccm_coef_b_0_cfg.rg_ccm_coef_b_0.value[15:0]     ;           
assign rg_ccm_coef_b[1]       =   hwif_out.isp_config.ccm_coef_b_1_cfg.rg_ccm_coef_b_1.value[15:0]     ;           
assign rg_ccm_coef_b[2]       =   hwif_out.isp_config.ccm_coef_b_2_cfg.rg_ccm_coef_b_2.value[15:0]     ;           
assign rg_ccm_coef_b[3]       =   hwif_out.isp_config.ccm_coef_b_3_cfg.rg_ccm_coef_b_3.value[15:0]     ;           
assign rg_csc_coef_r[0]       =   hwif_out.isp_config.csc_coef_r_0_cfg.rg_csc_coef_r_0.value[15:0]     ;       
assign rg_csc_coef_r[1]       =   hwif_out.isp_config.csc_coef_r_1_cfg.rg_csc_coef_r_1.value[15:0]     ;       
assign rg_csc_coef_r[2]       =   hwif_out.isp_config.csc_coef_r_2_cfg.rg_csc_coef_r_2.value[15:0]     ;       
assign rg_csc_coef_r[3]       =   hwif_out.isp_config.csc_coef_r_3_cfg.rg_csc_coef_r_3.value[15:0]     ;       
assign rg_csc_coef_g[0]       =   hwif_out.isp_config.csc_coef_g_0_cfg.rg_csc_coef_g_0.value[15:0]     ;       
assign rg_csc_coef_g[1]       =   hwif_out.isp_config.csc_coef_g_1_cfg.rg_csc_coef_g_1.value[15:0]     ;       
assign rg_csc_coef_g[2]       =   hwif_out.isp_config.csc_coef_g_2_cfg.rg_csc_coef_g_2.value[15:0]     ;       
assign rg_csc_coef_g[3]       =   hwif_out.isp_config.csc_coef_g_3_cfg.rg_csc_coef_g_3.value[15:0]     ;       
assign rg_csc_coef_b[0]       =   hwif_out.isp_config.csc_coef_b_0_cfg.rg_csc_coef_b_0.value[15:0]     ;       
assign rg_csc_coef_b[1]       =   hwif_out.isp_config.csc_coef_b_1_cfg.rg_csc_coef_b_1.value[15:0]     ;       
assign rg_csc_coef_b[2]       =   hwif_out.isp_config.csc_coef_b_2_cfg.rg_csc_coef_b_2.value[15:0]     ;       
assign rg_csc_coef_b[3]       =   hwif_out.isp_config.csc_coef_b_3_cfg.rg_csc_coef_b_3.value[15:0]     ;       
assign rg_nlm_clip            =   hwif_out.isp_config.nlm_clip_cfg.rg_nlm_clip.value[15:0]     ;   
assign rg_bnf_dw[0][0]        =   hwif_out.isp_config.bnf_dw_00_cfg.rg_bnf_dw_00.value[15:0]   ;       
assign rg_bnf_dw[0][1]        =   hwif_out.isp_config.bnf_dw_01_cfg.rg_bnf_dw_01.value[15:0]   ;       
assign rg_bnf_dw[0][2]        =   hwif_out.isp_config.bnf_dw_02_cfg.rg_bnf_dw_02.value[15:0]   ;       
assign rg_bnf_dw[0][3]        =   hwif_out.isp_config.bnf_dw_03_cfg.rg_bnf_dw_03.value[15:0]   ;       
assign rg_bnf_dw[0][4]        =   hwif_out.isp_config.bnf_dw_04_cfg.rg_bnf_dw_04.value[15:0]   ;       
assign rg_bnf_dw[1][0]        =   hwif_out.isp_config.bnf_dw_10_cfg.rg_bnf_dw_10.value[15:0]   ;       
assign rg_bnf_dw[1][1]        =   hwif_out.isp_config.bnf_dw_11_cfg.rg_bnf_dw_11.value[15:0]   ;       
assign rg_bnf_dw[1][2]        =   hwif_out.isp_config.bnf_dw_12_cfg.rg_bnf_dw_12.value[15:0]   ;       
assign rg_bnf_dw[1][3]        =   hwif_out.isp_config.bnf_dw_13_cfg.rg_bnf_dw_13.value[15:0]   ;       
assign rg_bnf_dw[1][4]        =   hwif_out.isp_config.bnf_dw_14_cfg.rg_bnf_dw_14.value[15:0]   ;       
assign rg_bnf_dw[2][0]        =   hwif_out.isp_config.bnf_dw_20_cfg.rg_bnf_dw_20.value[15:0]   ;       
assign rg_bnf_dw[2][1]        =   hwif_out.isp_config.bnf_dw_21_cfg.rg_bnf_dw_21.value[15:0]   ;       
assign rg_bnf_dw[2][2]        =   hwif_out.isp_config.bnf_dw_22_cfg.rg_bnf_dw_22.value[15:0]   ;       
assign rg_bnf_dw[2][3]        =   hwif_out.isp_config.bnf_dw_23_cfg.rg_bnf_dw_23.value[15:0]   ;       
assign rg_bnf_dw[2][4]        =   hwif_out.isp_config.bnf_dw_24_cfg.rg_bnf_dw_24.value[15:0]   ;       
assign rg_bnf_dw[3][0]        =   hwif_out.isp_config.bnf_dw_30_cfg.rg_bnf_dw_30.value[15:0]   ;       
assign rg_bnf_dw[3][1]        =   hwif_out.isp_config.bnf_dw_31_cfg.rg_bnf_dw_31.value[15:0]   ;       
assign rg_bnf_dw[3][2]        =   hwif_out.isp_config.bnf_dw_32_cfg.rg_bnf_dw_32.value[15:0]   ;       
assign rg_bnf_dw[3][3]        =   hwif_out.isp_config.bnf_dw_33_cfg.rg_bnf_dw_33.value[15:0]   ;       
assign rg_bnf_dw[3][4]        =   hwif_out.isp_config.bnf_dw_34_cfg.rg_bnf_dw_34.value[15:0]   ;       
assign rg_bnf_dw[4][0]        =   hwif_out.isp_config.bnf_dw_40_cfg.rg_bnf_dw_40.value[15:0]   ;       
assign rg_bnf_dw[4][1]        =   hwif_out.isp_config.bnf_dw_41_cfg.rg_bnf_dw_41.value[15:0]   ;       
assign rg_bnf_dw[4][2]        =   hwif_out.isp_config.bnf_dw_42_cfg.rg_bnf_dw_42.value[15:0]   ;       
assign rg_bnf_dw[4][3]        =   hwif_out.isp_config.bnf_dw_43_cfg.rg_bnf_dw_43.value[15:0]   ;       
assign rg_bnf_dw[4][4]        =   hwif_out.isp_config.bnf_dw_44_cfg.rg_bnf_dw_44.value[15:0]   ;       
assign rg_bnf_rw[0]           =   hwif_out.isp_config.bnf_rw_0_cfg.rg_bnf_rw_0.value[15:0]     ;       
assign rg_bnf_rw[1]           =   hwif_out.isp_config.bnf_rw_1_cfg.rg_bnf_rw_1.value[15:0]     ;       
assign rg_bnf_rw[2]           =   hwif_out.isp_config.bnf_rw_2_cfg.rg_bnf_rw_2.value[15:0]     ;       
assign rg_bnf_rw[3]           =   hwif_out.isp_config.bnf_rw_3_cfg.rg_bnf_rw_3.value[15:0]     ;       
assign rg_bnf_rthres[0]       =   hwif_out.isp_config.bnf_rthres_0_cfg.rg_bnf_rthres_0.value[15:0]     ;               
assign rg_bnf_rthres[1]       =   hwif_out.isp_config.bnf_rthres_1_cfg.rg_bnf_rthres_1.value[15:0]     ;               
assign rg_bnf_rthres[2]       =   hwif_out.isp_config.bnf_rthres_2_cfg.rg_bnf_rthres_2.value[15:0]     ;               
assign rg_bnf_clip            =   hwif_out.isp_config.bnf_clip_cfg.rg_bnf_clip.value[15:0]     ;       
assign rg_edge_filter[0][0]   =   hwif_out.isp_config.edge_filter_00_cfg.rg_edge_filter_00.value[4:0]  ;               
assign rg_edge_filter[0][1]   =   hwif_out.isp_config.edge_filter_01_cfg.rg_edge_filter_01.value[4:0]  ;                
assign rg_edge_filter[0][2]   =   hwif_out.isp_config.edge_filter_02_cfg.rg_edge_filter_02.value[4:0]  ;               
assign rg_edge_filter[0][3]   =   hwif_out.isp_config.edge_filter_03_cfg.rg_edge_filter_03.value[4:0]  ;                
assign rg_edge_filter[0][4]   =   hwif_out.isp_config.edge_filter_04_cfg.rg_edge_filter_04.value[4:0]  ;               
assign rg_edge_filter[1][0]   =   hwif_out.isp_config.edge_filter_10_cfg.rg_edge_filter_10.value[4:0]  ;               
assign rg_edge_filter[1][1]   =   hwif_out.isp_config.edge_filter_11_cfg.rg_edge_filter_11.value[4:0]  ;               
assign rg_edge_filter[1][2]   =   hwif_out.isp_config.edge_filter_12_cfg.rg_edge_filter_12.value[4:0]  ;               
assign rg_edge_filter[1][3]   =   hwif_out.isp_config.edge_filter_13_cfg.rg_edge_filter_13.value[4:0]  ;               
assign rg_edge_filter[1][4]   =   hwif_out.isp_config.edge_filter_14_cfg.rg_edge_filter_14.value[4:0]  ;               
assign rg_edge_filter[2][0]   =   hwif_out.isp_config.edge_filter_20_cfg.rg_edge_filter_20.value[4:0]  ;               
assign rg_edge_filter[2][1]   =   hwif_out.isp_config.edge_filter_21_cfg.rg_edge_filter_21.value[4:0]  ;               
assign rg_edge_filter[2][2]   =   hwif_out.isp_config.edge_filter_22_cfg.rg_edge_filter_22.value[4:0]  ;               
assign rg_edge_filter[2][3]   =   hwif_out.isp_config.edge_filter_23_cfg.rg_edge_filter_23.value[4:0]  ;               
assign rg_edge_filter[2][4]   =   hwif_out.isp_config.edge_filter_24_cfg.rg_edge_filter_24.value[4:0]  ;               
assign rg_eeh_gain[0]         =   hwif_out.isp_config.eeh_gain_0_cfg.rg_eeh_gain_0.value[15:0]     ;           
assign rg_eeh_gain[1]         =   hwif_out.isp_config.eeh_gain_1_cfg.rg_eeh_gain_1.value[15:0]     ;           
assign rg_eeh_rthres[0]       =   hwif_out.isp_config.eeh_rthres_0_cfg.rg_eeh_rthres_0.value[15:0]     ;           
assign rg_eeh_rthres[1]       =   hwif_out.isp_config.eeh_rthres_1_cfg.rg_eeh_rthres_1.value[15:0]     ;           
assign rg_eeh_emclip[0]       =   hwif_out.isp_config.eeh_emclip_0_cfg.rg_eeh_emclip_0.value[15:0]     ;           
assign rg_eeh_emclip[1]       =   hwif_out.isp_config.eeh_emclip_1_cfg.rg_eeh_emclip_1.value[15:0]     ;           
assign rg_bcc_brightness      =   hwif_out.isp_config.bcc_brightness_cfg.rg_bcc_brightness.value[15:0]     ;           
assign rg_bcc_contrast        =   hwif_out.isp_config.bcc_constrast_cfg.rg_bcc_constrast.value[15:0]   ;           
assign rg_bcc_clip            =   hwif_out.isp_config.bcc_clip_cfg.rg_bcc_clip.value[15:0]     ;       
assign rg_fcs_edge[0]         =   hwif_out.isp_config.fcs_edge_0_cfg.rg_fcs_edge_0.value[15:0]     ;       
assign rg_fcs_edge[1]         =   hwif_out.isp_config.fcs_edge_1_cfg.rg_fcs_edge_1.value[15:0]     ;       
assign rg_fcs_gain            =   hwif_out.isp_config.fcs_gain_cfg.rg_fcs_gain.value[15:0]     ;       
assign rg_fcs_intercept       =   hwif_out.isp_config.fcs_intercept_cfg.rg_fcs_intercept.value[15:0]   ;           
assign rg_fcs_slop            =   hwif_out.isp_config.fcs_slop_cfg.rg_fcs_slop.value[15:0]     ;   
assign rg_fcs_clip            =   hwif_out.isp_config.fcs_clip_cfg.rg_fcs_clip.value[15:0]     ;   
assign rg_hue_cos             =   hwif_out.isp_config.hue_cos_cfg.rg_hue_cos.value[15:0]   ;       
assign rg_hue_sin             =   hwif_out.isp_config.hue_sin_cfg.rg_hue_sin.value[15:0]   ;       
assign rg_hsc_saturation      =   hwif_out.isp_config.hsc_saturation_cfg.rg_hsc_saturation.value[15:0]     ;       
assign rg_hsc_clip            =   hwif_out.isp_config.hsc_clip_cfg.rg_hsc_clip.value[15:0]     ;       
assign rg_i2cs_id             =   hwif_out.i2c_ctrl.i2c_slave_id_cfg.rg_i2cs_id.value[5:0]            ;
assign rg_i2cs_id_en          =   hwif_out.i2c_ctrl.i2c_slave_id_cfg.rg_i2cs_id_en.value              ;
assign rg_pixel_ckgt_en       =   hwif_out.top_ctrl.clock_gate_cfg.rg_pixel_ckgt_en.value             ;


// Instantiate regmap
regmap regmap_inst (
    .clk                       ( clk                  ),  
    .arst_n                    ( arst_n               ),      
    .s_cpuif_req               ( s_cpuif_req          ),  
    .s_cpuif_req_is_wr         ( s_cpuif_req_is_wr    ),  
    .s_cpuif_addr              ( s_cpuif_addr         ),  
    .s_cpuif_wr_data           ( s_cpuif_wr_data      ),   
    .s_cpuif_wr_biten          ( s_cpuif_wr_biten     ),  
    .s_cpuif_req_stall_wr      ( s_cpuif_req_stall_wr ),      
    .s_cpuif_req_stall_rd      ( s_cpuif_req_stall_rd ),      
    .s_cpuif_rd_ack            ( s_cpuif_rd_ack       ), 
    .s_cpuif_rd_err            ( s_cpuif_rd_err       ), 
    .s_cpuif_rd_data           ( s_cpuif_rd_data      ),  
    .s_cpuif_wr_ack            ( s_cpuif_wr_ack       ),  
    .s_cpuif_wr_err            ( s_cpuif_wr_err       ),  
    //.hwif_in                   ( hwif_in              ),  
    .hwif_out                  ( hwif_out             )
);

endmodule
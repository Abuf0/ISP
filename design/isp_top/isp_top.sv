
module  isp_top# (
    parameter DW = 24   ,   // RGB Data Width as rgb888
    parameter BW = 16   ,   // Bayer Data Width
    parameter H  = 128  ,
    parameter V  = 72   ,
    parameter HW = 11   ,
    parameter VW = 10   
)(
    input        clk                            ,
    input        rstn                           , 
    // ISP global parameter //
    input [15:0] isp_enable                     ,
    //input [3:0]  isp_seq [0:15]                 ,   // ISP顺序，寄存器配置
    input [1:0]  bayer_pattern                  ,
    // DPC module parameter //
    input [BW-1:0] dpc_thres                    ,
    input [BW-1:0] dpc_clip                     ,
    // BLC module parameter //
    input [BW-1:0] blc_bias [0:3]               ,
    input [BW-1:0] blc_clip                     ,
    // AWB module parameter //
    input [BW-1:0] awb_gain [0:3]               ,
    input [BW-1:0] awb_clip                     ,
    // CNF module parameter //
    input [BW-1:0] cnf_gain [0:3]               ,
    input [BW-1:0] cnf_clip                     ,
    input [BW-1:0] cnf_thres                    ,
    // CFA module parameter //
    input [BW-1:0] cfa_clip                     ,
    // CCM module parameter //
    input [DW-1:0] ccm_coef_r [0:3]             ,
    input [DW-1:0] ccm_coef_g [0:3]             ,
    input [DW-1:0] ccm_coef_b [0:3]             ,
    // CSC module parameter //
    input signed [DW-1:0] csc_coef_r [0:3]      ,
    input signed [DW-1:0] csc_coef_g [0:3]      ,
    input signed [DW-1:0] csc_coef_b [0:3]      ,
    // NLM module parameter //
    input [DW-1:0] nlm_clip                     ,
    // BNF module parameter //
    input [DW-1:0] bnf_dw [0:4][0:4]            ,   
    input [DW-1:0] bnf_rw [0:3]                 ,     
    input [DW-1:0] bnf_rthres [0:2]             ,   
    input [DW-1:0] bnf_clip                     ,     
    // EEH module parameter //
    input signed [4:0] edge_filter [0:2][0:4]   ,
    input [DW-1:0] eeh_rthres [0:1]             ,      
    input [DW-1:0] eeh_gain [0:1]               , 
    input signed [DW:0] eeh_emclip [0:1]        ,      
    // BCC module parameter //
    input [DW-1:0] bcc_brightness               ,
    input [DW-1:0] bcc_contrast                 ,
    input [DW-1:0] bcc_clip                     ,
    // FCS module parameter //
    input [DW/3-1:0] fcs_edge [0:1]             ,
    input [DW/3-1:0] fcs_gain                   ,
    input [DW/3-1:0] fcs_intercept              ,
    input [DW/3-1:0] fcs_slop                   ,
    input [DW/3-1:0] fcs_clip                   ,
    // HSC module parameter //
    input signed [DW/3:0] hue_cos               ,
    input signed [DW/3:0] hue_sin               ,
    input [DW/3-1:0] hsc_saturation             ,
    input [DW/3-1:0] hsc_clip                   ,
    // ISP input //
    input [DW-1:0] pixel_data_in                ,
    input          pixel_data_in_vld            ,
    // ISP output //
    output logic [DW-1:0] pixel_data_out        ,
    output logic pixel_data_out_vld             ,
    output logic one_frame_done                 ,   // 帧信息
    output logic [15:0] ebd_data                    // 帧信息
);

localparam CSC_FIFO_DEEPTH = 16 * H ;
localparam BCC_FIFO_DEEPTH = 4 * H ;
// Fixed index
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

logic  [BW-1:0]  pixel_data_bayer[0:16];
logic  [DW-1:0]  pixel_data_rgb[0:16];
logic            pixel_data_vld[0:16];

logic  [23:0]    buffer_data_rgb_csc;

logic [DW/3-1:0] yuv_out [0:2]    ;
logic yuv_out_vld               ;


// DPC module
dpc #(
    .DPC_MODE   (0   ), 
    .DW         (BW   ),
    .H          (H    ),
    .V          (V    ),
    .HW         (HW   ),
    .VW         (VW   )
) dpc_inst(
    .clk                (clk               ),
    .rstn               (rstn               ),
    .dpc_en             (isp_enable[DPC]         ), // TODO
    .thres              (dpc_thres               ),
    .clip               (dpc_clip                ),
    .pixel_data_in_vld  (pixel_data_vld[DPC]     ), // TODO
    .pixel_data_in      (pixel_data_bayer[DPC]   ),
    .pixel_data_out_vld (pixel_data_vld[DPC+1]   ),
    .pixel_data_out     (pixel_data_bayer[DPC+1] )
);
assign pixel_data_rgb[DPC] = pixel_data_in;
assign pixel_data_bayer[DPC] = pixel_data_rgb[DPC][BW-1:0];
assign pixel_data_vld[DPC] = pixel_data_in_vld;

// BLC module
blc #(
    .DW  (BW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) blc_inst(
    .clk                (clk              ),
    .rstn               (rstn              ),
    .blc_en             (isp_enable[BLC]        ),   // TODO
    .bayer_pattern      (bayer_pattern          ), // TODO
    .bias               (blc_bias               ),
    .alpha              ( {BW{1'b0}}            ),
    .beta               ( {BW{1'b0}}            ),
    .blc_clip           (blc_clip               ),
    .pixel_data_in_vld  (pixel_data_vld[BLC]    ), 
    .pixel_data_in      (pixel_data_bayer[BLC]  ),
    .pixel_data_out_vld (pixel_data_vld[BLC+1]  ),
    .pixel_data_out     (pixel_data_bayer[BLC+1])
);

// AAF module
aaf #(
    .DW  (BW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) aaf_inst(
    .clk                (clk               ),
    .rstn               (rstn               ),
    .aaf_en             (isp_enable[AAF]         ), // TODO
    .pixel_data_in_vld  (pixel_data_vld[AAF]     ), 
    .pixel_data_in      (pixel_data_bayer[AAF]   ),
    .pixel_data_out_vld (pixel_data_vld[AAF+1]   ),
    .pixel_data_out     (pixel_data_bayer[AAF+1] ),
    .aaf_done           (                        )  // TODO
);

// AWB module
awb #(
    .DW  (BW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) awb_inst(
    .clk                 (clk              ),
    .rstn                (rstn              ),
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
    .DW  (BW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) cnf_inst(
    .clk                 (clk              ),
    .rstn                (rstn              ),
    .cnf_en              (isp_enable[CNF]        ), // TODO
    .thres               (cnf_thres              ), // TODO
    .cnf_gain            (cnf_gain               ),
    .bayer_pattern       (bayer_pattern          ), // TODO
    .cnf_clip            (cnf_clip               ), // TODO
    .pixel_data_in       (pixel_data_bayer[CNF]    ),
    .pixel_data_in_vld   (pixel_data_vld[CNF]    ),
    .pixel_data_out      (pixel_data_bayer[CNF+1]  ),
    .pixel_data_out_vld  (pixel_data_vld[CNF+1]  ),
    .cnf_done            (                       )  // TODO
);
 
// CFA module
logic [BW-1:0] pixel_data_rgb_cfa_r;
logic [BW-1:0] pixel_data_rgb_cfa_g;
logic [BW-1:0] pixel_data_rgb_cfa_b;
cfa #(
    .DW  (BW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) cfa_inst(
    .clk                 (clk              ),
    .rstn                (rstn              ),
    .cfa_en              (isp_enable[CFA]        ), // TODO
    .bayer_pattern       (bayer_pattern          ), // TODO
    .cfa_clip            (cfa_clip               ), // TODO
    .pixel_data_in       (pixel_data_bayer[CFA]  ),
    .pixel_data_in_vld   (pixel_data_vld[CFA]    ),
    .pixel_data_out_r    (pixel_data_rgb_cfa_r   ),
    .pixel_data_out_g    (pixel_data_rgb_cfa_g   ),
    .pixel_data_out_b    (pixel_data_rgb_cfa_b   ),
    .pixel_data_out_vld  (pixel_data_vld[CFA+1]  ),
    .cfa_done            (                       )  // TODO
);

assign pixel_data_rgb[CFA+1] = {pixel_data_rgb_cfa_r[DW/3-1:0],pixel_data_rgb_cfa_g[DW/3-1:0],pixel_data_rgb_cfa_b[DW/3-1:0]};

// CCM module

ccm #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) ccm_inst(
    .clk               (clk                              ),
    .rstn              (rstn                              ),
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
    .clk                 (clk              ),
    .rstn                (rstn              ),
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
    .lut_din             ({DW/3{1'b0}}          ),           
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
    .clk                 (clk              ),
    .rstn                (rstn              ),
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

sync_fifo #(
    .FIFO_DEEPTH(CSC_FIFO_DEEPTH),
    .FIFO_WIDTH (BW             )
) fifo_csc2fcs_inst(
    .clk                (clk                          ),
    .rstn               (rstn                          ),
    .wr_en              (pixel_data_vld[CSC+1]              ),
    .rd_en              (pixel_data_vld[FCS]                ),
    .wdata              (pixel_data_rgb[CSC+1][DW-1:DW-16]  ),
    .rdata              (buffer_data_rgb_csc[DW-1:DW-16]    ),
    .fifo_empty         (                                   ),
    .fifo_full          (                                   )  
);

// NLM module

nlm #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) nlm_inst(
    .clk                (clk               ),
    .rstn               (rstn               ),
    .nlm_clip           (nlm_clip                ),
    .nlm_en             (isp_enable[NLM]         ), // TODO
    .pixel_data_in_vld  (pixel_data_vld[NLM]     ), 
    .pixel_data_in      ({16'd0,pixel_data_rgb[NLM][DW-17:DW-24]}     ),
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
    .clk                (clk               ),
    .rstn               (rstn               ),
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
logic signed [DW:0] pixel_data_em;
eeh #(
    .DW  (DW   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) eeh_inst(
    .clk                (clk               ),
    .rstn               (rstn               ),
    .eeh_en             (isp_enable[EEH]         ), // TODO
    //.edge_filter        (edge_filter [0:2][0:4]  ), // TODO
    //.eeh_clip           (eeh_clip [0:1]          ), // TODO 
    //.eeh_rthres         (eeh_rthres [0:1]        ), // TODO
    //.eeh_gain           (eeh_gain [0:1]          ), // TODO
    .edge_filter        (edge_filter              ), // TODO
    .eeh_clip           (eeh_emclip               ), // TODO
    .eeh_rthres         (eeh_rthres               ), // TODO
    .eeh_gain           (eeh_gain                ), // TODO 
    .pixel_data_in_vld  (pixel_data_vld[EEH]     ), 
    .pixel_data_in      (pixel_data_rgb[EEH]     ),
    .pixel_data_out_vld (pixel_data_vld[EEH+1]   ),
    .pixel_data_out_em  (pixel_data_em           ),
    .pixel_data_out_ee  (pixel_data_rgb[BCC]     ),
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
    .clk                (clk               ),
    .rstn               (rstn               ),
    .bcc_en             (isp_enable[BCC]         ), // TODO
    .brightness         (bcc_brightness          ), // TODO
    .contrast           (bcc_contrast            ), // TODO
    .bcc_clip           (bcc_clip                ), // TODO   
    .pixel_data_in_vld  (pixel_data_vld[BCC]     ), 
    .pixel_data_in      (pixel_data_rgb[BCC]     ),
    .pixel_data_out_vld (pixel_data_vld[BCC+1]   ),
    .pixel_data_out     (pixel_data_rgb[BCC+1]   ),
    .bcc_done           (                        )  // TODO
);

// FCS module
//----- for fifo to buffer 1 clk
logic pixel_data_in_vld_fcs_ff1;
logic signed [DW:0] pixel_data_em_ff1;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pixel_data_in_vld_fcs_ff1 <= 1'b0;
        pixel_data_em_ff1 <= 'sd0;
    end
    else begin
        pixel_data_in_vld_fcs_ff1 <= pixel_data_vld[FCS];
        pixel_data_em_ff1 <= pixel_data_em;
    end
end

fcs #(
    .DW  (DW/3   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) fcs_inst(
    .clk                    (clk               ),
    .rstn                   (rstn               ),
    .fcs_en                 (isp_enable[FCS]         ), // TODO
    .fcs_edge               (fcs_edge [0:1]          ), // TODO
    .gain                   (fcs_gain                ), // TODO
    .intercept              (fcs_intercept           ), // TODO
    .slop                   (fcs_slop                ), // TODO
    .fcs_clip               (fcs_clip                ),
    //.pixel_data_in_vld      (pixel_data_vld[FCS]     ), 
    //.pixel_data_in_edgemap  (pixel_data_em           ),
    .pixel_data_in_vld      (pixel_data_in_vld_fcs_ff1), 
    .pixel_data_in_edgemap  (pixel_data_em_ff1[DW/3:0]),
    //.buffer_data_in_ccs_y   (buffer_data_rgb_csc[DW-1:DW-8]  ),  // TODO
    .buffer_data_in_csc_cr  (buffer_data_rgb_csc[DW-9:DW-16] ),  // TODO
    .buffer_data_in_csc_cb  (buffer_data_rgb_csc[DW-1:DW-8]  ),  // TODO
    .pixel_data_out_vld     (pixel_data_vld[FCS+1]      ),
    //.pixel_data_out_y       (pixel_data_rgb[FCS+1][DW-1:DW-8]  ),
    .pixel_data_out_cr      (pixel_data_rgb[FCS+1][DW-9:DW-16] ),
    .pixel_data_out_cb      (pixel_data_rgb[FCS+1][DW-1:DW-8]  ),
    .fcs_done               (                        )  // TODO
);

// HSC module

hsc #(
    .DW  (DW/3   ),
    .H   (H    ),
    .V   (V    ),
    .HW  (HW   ),
    .VW  (VW   )
) hsc_inst(
    .clk                    (clk               ),
    .rstn                   (rstn               ),
    .hsc_en                 (isp_enable[HSC]         ), // TODO
    .hue_cos                (hue_cos                 ), // TODO
    .hue_sin                (hue_sin                 ), // TODO
    .saturation             (hsc_saturation          ), // TODO
    .clip                   (hsc_clip                ), // TODO
    .pixel_data_in_vld      (pixel_data_vld[HSC]     ),
    .buffer_data_in_ccs_cr  (pixel_data_rgb[HSC][DW-9:DW-16] ),  // TODO
    .buffer_data_in_ccs_cb  (pixel_data_rgb[HSC][DW-1:DW-8]  ),  // TODO
    .pixel_data_out_vld     (pixel_data_vld[HSC+1]   ),
    //.pixel_data_out         (pixel_data_rgb[HSC+1][DW-9:0]   ),
    .pixel_data_out_cr      (pixel_data_rgb[HSC+1][DW-9:DW-16] ),
    .pixel_data_out_cb      (pixel_data_rgb[HSC+1][DW-1:DW-8]  ),
    .hsc_done               (                        )  // TODO
);

logic [DW/3-1:0] pixel_data_hsc_cr_ff1;
logic [DW/3-1:0] pixel_data_hsc_cb_ff1;
logic pixel_data_vld_hsc_ff1;
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pixel_data_hsc_cr_ff1   <= 'd0;
        pixel_data_hsc_cb_ff1   <= 'd0;
        pixel_data_vld_hsc_ff1  <= 'd0;
    end
    else begin
        pixel_data_hsc_cr_ff1   <= pixel_data_rgb[HSC+1][DW-9:DW-16] ;
        pixel_data_hsc_cb_ff1   <= pixel_data_rgb[HSC+1][DW-1:DW-8]  ;
        pixel_data_vld_hsc_ff1  <= pixel_data_vld[HSC+1]    ;
    end
end


logic [7:0] buffer_data_bcc;

sync_fifo #(
    .FIFO_DEEPTH(BCC_FIFO_DEEPTH),
    .FIFO_WIDTH (DW/3           )
) fifo_bcc2yuv_inst(
    .clk                (clk                          ),
    .rstn               (rstn                          ),
    .wr_en              (pixel_data_vld[BCC+1]              ),
    .rd_en              (pixel_data_vld[HSC+1]              ),
    .wdata              (pixel_data_rgb[BCC+1][7:0]         ),
    .rdata              (buffer_data_bcc                    ),
    .fifo_empty         (                                   ),
    .fifo_full          (                                   )  
);


logic [DW/3-1:0] yuv_out_pre[0:2];
logic yuv_out_vld_pre;
assign yuv_out_pre[0] = buffer_data_bcc[DW/3-1:0];
assign yuv_out_pre[1] = pixel_data_hsc_cr_ff1;
assign yuv_out_pre[2] = pixel_data_hsc_cb_ff1;
assign yuv_out_vld_pre = pixel_data_vld_hsc_ff1;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        yuv_out[0]  <= 'd0 ;
        yuv_out[1]  <= 'd0 ;
        yuv_out[2]  <= 'd0 ;
        yuv_out_vld <= 'd0 ;
    end
    else begin
        yuv_out[0]  <= yuv_out_pre[0]  ;
        yuv_out[1]  <= yuv_out_pre[1]  ;
        yuv_out[2]  <= yuv_out_pre[2]  ;
        yuv_out_vld <= yuv_out_vld_pre ;
    end
end

assign pixel_data_out = {yuv_out[0],yuv_out[1],yuv_out[2]};
assign pixel_data_out_vld = yuv_out_vld;

`ifdef SIM
integer file_yuv_out;
initial begin
    file_yuv_out = $fopen("./yuv_out_result.csv","w+");  // 初始化文件
end

always @(negedge clk) begin
    if(yuv_out_vld) begin
        $fwrite(file_yuv_out,"yuv=%d, cr=%d, cb=%d\n",yuv_out[0],yuv_out[1],yuv_out[2]);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif

endmodule
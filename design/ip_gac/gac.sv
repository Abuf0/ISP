module gac#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                   clk                   ,
    input                   rstn                  ,
    input                   ccm_en                ,
    input        [DW-1:0]   ccm_coef_r [0:3]      ,
    input        [DW-1:0]   ccm_coef_g [0:3]      ,
    input        [DW-1:0]   ccm_coef_b [0:3]      ,
    input                   pixel_data_in_vld     , 
    input        [DW-1:0]   pixel_data_in_r       ,
    input        [DW-1:0]   pixel_data_in_g       ,
    input        [DW-1:0]   pixel_data_in_b       ,
    output logic            pixel_data_out_vld    ,
    output logic [DW-1:0]   pixel_data_out_r      ,
    output logic [DW-1:0]   pixel_data_out_g      ,
    output logic [DW-1:0]   pixel_data_out_b      ,
    output logic            ccm_done        
);

endmodule
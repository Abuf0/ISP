module blc#(
    parameter BIAS = 10     ,
    parameter COEF = 1      ,
    parameter BLC_MODE = 0     
)(
    input                   blc_en          ,
    input [23:0]            pixel_data_in   ,
    output logic [23:0]     pixel_data_out
);

assign pixel_data_out = blc_en?   (pixel_data_in+BIAS) : pixel_data_in;

endmodule
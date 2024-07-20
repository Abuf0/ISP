module dpc#(
    parameter THRES = 30        ,
    parameter DPC_MODE = 0      , // 0: mean  1: gradient
    parameter CLIP = 100        ,
    parameter H_DISP = 720  
)(
    input               clk             ,
    input               rstn            ,
    input               dpc_en          ,
    input        [23:0] pixel_data_in   ,
    output logic [23:0] pixel_data_out
);
logic [23:0] shift_reg [0:4*H_DISP+4-1];
genvar i;
generate
    for(i=0;i<4*H_DISP+4;i=i+1) begin: SFT_ARRAY
        if(i=0) begin
            always_ff @( posedge clk or negedge rstn ) begin
                if(~rstn)
                shift_reg[i] <= 'd0;
            else if(dpc_en)
                shift_reg[i] <= pixel_data_in;
            end
        end
        else begin
            always_ff @( posedge clk or negedge rstn ) begin
                if(~rstn)
                shift_reg[i] <= 'd0;
            else if(dpc_en)
                shift_reg[i] <= shift_reg[i-1];
            end
        end
    end
endgenerate


endmodule
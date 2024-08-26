// Dead Pixel Correction //
module dpc#(
    parameter DPC_MODE = 0      , // 0: mean  1: gradient
    parameter H = 1280  
)(
    input               clk                 ,
    input               rstn                ,
    input               dpc_en              ,
    input [7:0]         thres               ,
    input [7:0]         clip                ,
    input               pixel_data_in_vld   ,
    input        [23:0] pixel_data_in       ,
    output logic [23:0] pixel_data_out      ,
    output logic        pixel_data_out_vld
);
logic [23:0]shift_reg [0:4*H+4-1];
logic [7:0] shift_r [0:4*H+4-1];
logic [7:0] shift_g [0:4*H+4-1];
logic [7:0] shift_b [0:4*H+4-1];
logic correct_flag_r;
logic correct_flag_g;
logic correct_flag_b;
logic [23:0] pixel_data_dpc;
logic [23:0] pixel_data_out_pre;
logic pixel_data_in_vld_ff1;
logic [7:0] dpc_r;
logic [7:0] dpc_g;
logic [7:0] dpc_b;


genvar i;
generate
    for(i=0;i<4*H+4;i=i+1) begin: SFT_ARRAY
        if(i==0) begin
            always_ff @( posedge clk or negedge rstn ) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(dpc_en && pixel_data_in_vld)
                    shift_reg[i] <= pixel_data_in;
            end
        end
        else if(i==2*H+2) begin  // replace dead pixel
            always_ff @( posedge clk or negedge rstn ) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(dpc_en && pixel_data_in_vld) begin
                    //shift_reg[i] <= (pixel_data_dpc > CLIP)?    CLIP : pixel_data_dpc;  // clip
                    shift_reg[i][23:16] <= (pixel_data_dpc[23:16] > clip)?    clip : pixel_data_dpc[23:16];  // clip
                    shift_reg[i][15:8]  <= (pixel_data_dpc[15:8]  > clip)?    clip : pixel_data_dpc[15:8] ;  // clip
                    shift_reg[i][7:0]   <= (pixel_data_dpc[7:0]   > clip)?    clip : pixel_data_dpc[7:0]  ;  // clip
                end
            end
        end
        else begin
            always_ff @( posedge clk or negedge rstn ) begin
                if(~rstn && pixel_data_in_vld)
                    shift_reg[i] <= 'd0;
                else if(dpc_en)
                    shift_reg[i] <= shift_reg[i-1];
            end
        end
        assign shift_r[i] = shift_reg[i][23:16];
        assign shift_g[i] = shift_reg[i][15:8] ;
        assign shift_b[i] = shift_reg[i][7:0]  ;
    end
endgenerate

assign pixel_data_out_pre = shift_reg[4*H+3];

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out <= 'd0;
    else if(dpc_en)
        pixel_data_out <= pixel_data_out_pre;
    else 
        pixel_data_out <= pixel_data_in;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out_vld <= 1'b0;
    else if(dpc_en)
        pixel_data_out_vld <= pixel_data_in_vld_ff1;
    else 
        pixel_data_out_vld <= pixel_data_in_vld;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_in_vld_ff1 <= 1'b0;
    else if(dpc_en)
        pixel_data_in_vld_ff1 <= pixel_data_in_vld;
end

assign correct_flag_r = dpc_en?  ($abs(shift_r[0]-shift_r[2*H+1]    ) > thres && $abs(shift_r[2]-shift_r[2*H+1]    ) > thres && $abs(shift_r[4]-shift_r[2*H+1]) > thres &&
                                 $abs(shift_r[2*H-1]-shift_r[2*H+1]) > thres && $abs(shift_r[2*H+3]-shift_r[2*H+1]) > thres &&
                                 $abs(shift_r[4*H-1]-shift_r[2*H+1]) > thres && $abs(shift_r[4*H+1]-shift_r[2*H+1]) > thres && $abs(shift_r[4*H+3]-shift_r[2*H+1]) > thres) : 0;

assign correct_flag_g = dpc_en?  ($abs(shift_g[0]-shift_g[2*H+1]    ) > $abs(thres && shift_g[2]-shift_g[2*H+1]    ) > thres && $abs(shift_g[4]-shift_g[2*H+1]) > thres &&
                                 $abs(shift_g[2*H-1]-shift_g[2*H+1]) > $abs(thres && shift_g[2*H+3]-shift_g[2*H+1]) > thres &&
                                 $abs(shift_g[4*H-1]-shift_g[2*H+1]) > $abs(thres && shift_g[4*H+1]-shift_g[2*H+1]) > thres && $abs(shift_g[4*H+3]-shift_g[2*H+1]) > thres) : 0;

assign correct_flag_b = dpc_en?  ($abs(shift_b[0]-shift_b[2*H+1]    ) > $abs(thres && shift_b[2]-shift_b[2*H+1]    ) > thres && $abs(shift_b[4]-shift_b[2*H+1]) > thres &&
                                 $abs(shift_b[2*H-1]-shift_b[2*H+1]) > $abs(thres && shift_b[2*H+3]-shift_b[2*H+1]) > thres &&
                                 $abs(shift_b[4*H-1]-shift_b[2*H+1]) > $abs(thres && shift_b[4*H+1]-shift_b[2*H+1]) > thres && $abs(shift_b[4*H+3]-shift_b[2*H+1]) > thres) : 0;

assign dpc_r = correct_flag_r?   ((shift_r[2] + shift_r[2*H-1] + shift_r[2*H+3] + shift_r[4*H+1])<<2) : shift_r[2*H+1];
assign dpc_g = correct_flag_g?   ((shift_g[2] + shift_g[2*H-1] + shift_g[2*H+3] + shift_g[4*H+1])<<2) : shift_g[2*H+1];
assign dpc_b = correct_flag_b?   ((shift_b[2] + shift_b[2*H-1] + shift_b[2*H+3] + shift_b[4*H+1])<<2) : shift_b[2*H+1];

assign pixel_data_dpc = {dpc_r,dpc_g,dpc_b};

endmodule
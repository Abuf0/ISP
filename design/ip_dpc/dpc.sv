// Dead Pixel Correction //
module dpc#(
    parameter DPC_MODE = 0      , // 0: mean  1: gradient
    parameter DW = 16           ,
    parameter H = 1280          ,
    parameter V = 720           ,
    parameter HW = 11           ,
    parameter VW = 10
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
logic [7:0] dpc_r;
logic [7:0] dpc_g;
logic [7:0] dpc_b;

logic [HW-1:0] h_cnt;
logic [VW-1:0] v_cnt;

logic mask;

//logic [4*h+4-1:0] pixel_data_in_vld_ff;

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
            //always_ff@(posedge clk or negedge rstn) begin
            //    if(~rstn)
            //        pixel_data_in_vld_ff[i] <= 1'b0;
            //    else if(dpc_en)
            //        pixel_data_in_vld_ff[i] <= pixel_data_in_vld;
            //end
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
            //always_ff@(posedge clk or negedge rstn) begin
            //    if(~rstn)
            //        pixel_data_in_vld_ff[i] <= 1'b0;
            //    else if(dpc_en)
            //        pixel_data_in_vld_ff[i] <= pixel_data_in_vld_ff[i-1];
            //end            
        end
        else begin
            always_ff @( posedge clk or negedge rstn ) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(dpc_en && pixel_data_in_vld)
                    shift_reg[i] <= shift_reg[i-1];
            end
            //always_ff@(posedge clk or negedge rstn) begin
            //    if(~rstn)
            //        pixel_data_in_vld_ff[i] <= 1'b0;
            //    else if(dpc_en)
            //        pixel_data_in_vld_ff[i] <= pixel_data_in_vld;
            //end
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
        //pixel_data_out_vld <= pixel_data_in_vld_ff[4*H+3];
        pixel_data_out_vld <= mask;
    else 
        pixel_data_out_vld <= pixel_data_in_vld;
end

// assuming pixel_data_in_vld always = 1
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        mask <= 1'b0;
    else if(v_cnt==3 && h_cnt==3)
        mask <= 1'b1;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(dpc_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(dpc_en && pixel_data_in_vld && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
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

`ifdef SIM
integer file;
initial begin
   file = $fopen("./dpc_result.csv","w+");  // 初始化文件
end

always @(posedge clk) begin
    if (pixel_data_out_vld) begin
        $fwrite(file,"%d,%d,%d\n", pixel_data_out[23:16],pixel_data_out[15:8],pixel_data_out[7:0]);
    end
//     else begin
//         count <= 16‘d0;
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end

`endif

endmodule
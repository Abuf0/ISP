module bcc#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                   clk                   ,
    input                   rstn                  ,
    input                   bcc_en                ,
    input        [DW-1:0]   brightness            ,
    input        [DW-1:0]   contrast              , // real constrast * 2^5
    input        [DW-1:0]   bcc_clip              ,
    input                   pixel_data_in_vld     , 
    input        [DW-1:0]   pixel_data_in         ,
    output logic            pixel_data_out_vld    ,
    output logic [DW-1:0]   pixel_data_out        ,
    output logic            bcc_done        
);

logic [HW-1:0] h_cnt; 
logic [VW-1:0] v_cnt; 

logic pixel_data_out_vld_pre;
logic [DW-1:0] pixel_data_out_pre;
logic signed [DW:0] signed_delta;
logic signed [DW:0] signed_delta_shift;
logic signed [DW:0] signed_pixel_data_out_pre;
logic [DW-1:0] pixel_data;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) 
        pixel_data <= 'd0;
    else if(bcc_en && pixel_data_in_vld)
        pixel_data <= pixel_data_in;
end

assign signed_delta = (pixel_data - 7'd127) * contrast;
assign signed_delta_shift = signed_delta >>> 5;
assign signed_pixel_data_out_pre = pixel_data + brightness + signed_delta_shift;

assign pixel_data_out_pre = signed_pixel_data_out_pre[DW]?  'd0 : ((signed_pixel_data_out_pre > bcc_clip)?   bcc_clip : signed_pixel_data_out_pre) ;
                        

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pixel_data_out <= 'd0;
    end
    else if(bcc_en && pixel_data_out_vld_pre) 
        pixel_data_out <= pixel_data_out_pre;
    else if(~bcc_en && pixel_data_out_vld_pre)
        pixel_data_out <= pixel_data;
end


always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        {pixel_data_out_vld_pre,pixel_data_out_vld} <= 2'd0;
    else
        {pixel_data_out_vld_pre,pixel_data_out_vld} <= {pixel_data_in_vld,pixel_data_out_vld_pre};
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(bcc_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(bcc_en && pixel_data_in_vld && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        bcc_done <= 1'b0;
    else if(bcc_en && v_cnt==V-1 && h_cnt==H-1)
        bcc_done <= 1'b1;
    else if(bcc_done)
        bcc_done <= 1'b0;
end

`ifdef SIM
integer file_bcc;
initial begin
    file_bcc = $fopen("./bcc_result.csv","w+");  // 初始化文件
end

always @(negedge clk) begin
    if(pixel_data_out_vld) begin
        $fwrite(file_bcc,"%d\n",pixel_data_out);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif

endmodule
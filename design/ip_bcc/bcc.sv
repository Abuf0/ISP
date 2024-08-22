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
    input        [DW-1:0]   constrast             , // real constrast * 2^5
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
logic [DW-1:0] pixel_data;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) 
        pixel_data <= 'd0;
    else if(bcc_en && pixel_data_in_vld)
        pixel_data <= pixel_data_in;
end

assign pixel_data_out_pre = pixel_data + brightness + ((pixel_data - 7'd127) * constrast) << 5;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pixel_data_out <= 'd0;
    end
    else if(pixel_data_out_vld_pre) begin
        pixel_data_out <= pixel_data_out_pre;
    end
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
endmodule
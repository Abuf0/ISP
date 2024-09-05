module hsc#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                      clk                   ,
    input                      rstn                  ,
    input                      hsc_en                ,
    //input           [DW-1:0]   hue                   ,
    input           [DW-1:0]   hue_cos               ,
    input           [DW-1:0]   hue_sin               ,
    input           [DW-1:0]   saturation            , 
    input           [DW-1:0]   clip                  ,
    input                      pixel_data_in_vld     , 
    input           [DW-1:0]   buffer_data_in_ccs_cr ,
    input           [DW-1:0]   buffer_data_in_ccs_cb ,
    output logic               pixel_data_out_vld    ,
    output logic    [DW-1:0]   pixel_data_out_cr     ,
    output logic    [DW-1:0]   pixel_data_out_cb     ,
    output logic               hsc_done        
);

logic [HW-1:0] h_cnt; 
logic [VW-1:0] v_cnt; 

logic pixel_data_out_vld_pre;
logic signed [DW:0] pixel_data_out_hue [0:1];
logic signed [DW:0] pixel_data_out_sat [0:1];
logic signed [DW:0] pixel_data_out_pre [0:1];
logic [DW-1:0] pixel_data[0:1];
logic signed [DW:0] hsc_data [0:1];
logic signed [DW:0] edge_data;
logic [DW-1:0] edge_data_abs;
logic [DW-1:0] uv_gain;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pixel_data[0] <= 'd0;
        pixel_data[1] <= 'd0;
    end
    else if(hsc_en && pixel_data_in_vld) begin
        pixel_data[0] <= buffer_data_in_ccs_cr  ;
        pixel_data[1] <= buffer_data_in_ccs_cb  ;
    end
end

assign hsc_data[0] = (pixel_data[0] - 8'd128) * hue_cos + (pixel_data[1] - 8'd128) * hue_sin + 8'd128 ;
assign hsc_data[1] = (pixel_data[1] - 8'd128) * hue_cos + (pixel_data[0] - 8'd128) * hue_sin + 8'd128 ;

assign pixel_data_out_hue[0] = hsc_data[0] - 8'd128;
assign pixel_data_out_hue[1] = hsc_data[1] - 8'd128;

assign pixel_data_out_sat[0] = saturation * (pixel_data_out_hue[0] >>> 8) + 8'd128;
assign pixel_data_out_sat[1] = saturation * (pixel_data_out_hue[1] >>> 8) + 8'd128;

assign pixel_data_out_pre[0] = pixel_data_out_sat[0][DW]?   'd0 : ((pixel_data_out_pre[0] > clip)?  clip : pixel_data_out_pre[0]);
assign pixel_data_out_pre[1] = pixel_data_out_sat[1][DW]?   'd0 : ((pixel_data_out_pre[1] > clip)?  clip : pixel_data_out_pre[1]);

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pixel_data_out_cr <= 'd0 ;
        pixel_data_out_cb <= 'd0 ;
    end
    else if(pixel_data_out_vld_pre) begin
        pixel_data_out_cr <= hsc_en?   pixel_data_out_pre[0] : pixel_data[0];
        pixel_data_out_cb <= hsc_en?   pixel_data_out_pre[1] : pixel_data[1];
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
    else if(hsc_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(hsc_en && pixel_data_in_vld && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        hsc_done <= 1'b0;
    else if(hsc_en && v_cnt==V-1 && h_cnt==H-1)
        hsc_done <= 1'b1;
    else if(hsc_done)
        hsc_done <= 1'b0;
end

`ifdef SIM
integer file_hsc;
initial begin
    file_hsc = $fopen("./hsc_result.csv","w+");  // 初始化文件
end

always @(negedge clk) begin
    if(pixel_data_out_vld) begin
        $fwrite(file_hsc,"cr=%d, cb=%d\n",pixel_data_out_cr,pixel_data_out_cb);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif

endmodule
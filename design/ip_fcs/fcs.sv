module fcs#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                      clk                   ,
    input                      rstn                  ,
    input                      fcs_en                ,
    input           [DW-1:0]   fcs_edge [0:1]        ,
    input           [DW-1:0]   gain                  , // real constrast * 2^5
    input           [DW-1:0]   intercept             ,
    input           [DW-1:0]   slop                  ,
    input           [DW-1:0]   fcs_clip              ,
    input                      pixel_data_in_vld     , 
    input           [DW-1:0]   buffer_data_in_csc_cr ,
    input           [DW-1:0]   buffer_data_in_csc_cb ,
    input  signed   [DW:0]     pixel_data_in_edgemap ,
    output logic               pixel_data_out_vld    ,
    output logic    [DW-1:0]   pixel_data_out_cr     ,
    output logic    [DW-1:0]   pixel_data_out_cb     ,
    output logic               fcs_done        
);

logic [HW-1:0] h_cnt; 
logic [VW-1:0] v_cnt; 

logic pixel_data_out_vld_pre;
logic signed [DW:0] pixel_data_out_gain_pre [0:1];
logic signed [DW:0] pixel_data_out_gain_pre_shift [0:1];
logic signed [DW:0] pixel_data_out_gain [0:1];
logic signed [DW:0] pixel_data_out_gain_mux [0:1];
logic [DW-1:0] pixel_data_out_pre [0:1];
logic [DW-1:0] pixel_data[0:1];
logic signed [DW:0] edge_data;
logic [DW-1:0] edge_data_abs;
logic signed [DW:0] uv_gain;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pixel_data[0] <= 'd0;
        pixel_data[1] <= 'd0;
        edge_data <= 'sd0;
    end
    else if(fcs_en && pixel_data_in_vld) begin
        pixel_data[0] <= buffer_data_in_csc_cr ;
        pixel_data[1] <= buffer_data_in_csc_cb ;
        edge_data <=     pixel_data_in_edgemap ;   
    end
end

assign edge_data_abs = edge_data[DW]?   ~edge_data[DW-1:0]+1'b1 : edge_data[DW-1:0];

assign uv_gain = (edge_data_abs <= fcs_edge[0])?    gain :
                 (edge_data_abs >= fcs_edge[1])?    'd0 : (intercept - slop * edge_data);

assign pixel_data_out_gain_pre[0] = uv_gain * buffer_data_in_csc_cr;
assign pixel_data_out_gain_pre[1] = uv_gain * buffer_data_in_csc_cb;

assign pixel_data_out_gain_pre_shift[0] = pixel_data_out_gain_pre[0] >>> 8 ;
assign pixel_data_out_gain_pre_shift[1] = pixel_data_out_gain_pre[1] >>> 8 ;

assign pixel_data_out_gain[0] = pixel_data_out_gain_pre_shift[0] + 8'd128;
assign pixel_data_out_gain[1] = pixel_data_out_gain_pre_shift[1] + 8'd128;

assign pixel_data_out_gain_mux[0] = (edge_data_abs <= fcs_edge[0])?     {1'b0,buffer_data_in_csc_cr} :
                                    (edge_data_abs >= fcs_edge[1])?     'sd0 : pixel_data_out_gain[0] ;
assign pixel_data_out_gain_mux[1] = (edge_data_abs <= fcs_edge[0])?     {1'b0,buffer_data_in_csc_cb} :
                                    (edge_data_abs >= fcs_edge[1])?     'sd0 : pixel_data_out_gain[1] ;

assign pixel_data_out_pre[0] = pixel_data_out_gain_mux[0][DW]?  'd0 : ((pixel_data_out_gain_mux[0] > fcs_clip)?   fcs_clip : pixel_data_out_gain_mux[0]);
assign pixel_data_out_pre[1] = pixel_data_out_gain_mux[1][DW]?  'd0 : ((pixel_data_out_gain_mux[1] > fcs_clip)?   fcs_clip : pixel_data_out_gain_mux[1]);

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pixel_data_out_cr <= 'd0 ;
        pixel_data_out_cb <= 'd0 ;
    end
    else if(fcs_en && pixel_data_out_vld_pre) begin
        pixel_data_out_cr <= pixel_data_out_pre[0] ;
        pixel_data_out_cb <= pixel_data_out_pre[1] ;
    end
    else if(~fcs_en && pixel_data_in_vld) begin
        pixel_data_out_cr <= buffer_data_in_csc_cr;
        pixel_data_out_cb <= buffer_data_in_csc_cb;
    end
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        {pixel_data_out_vld_pre,pixel_data_out_vld} <= 2'd0;
    else if(fcs_en)
        {pixel_data_out_vld_pre,pixel_data_out_vld} <= {pixel_data_in_vld,pixel_data_out_vld_pre};
    else 
        {pixel_data_out_vld_pre,pixel_data_out_vld} <= {pixel_data_in_vld,pixel_data_in_vld};
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(fcs_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(fcs_en && pixel_data_in_vld && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        fcs_done <= 1'b0;
    else if(fcs_en && v_cnt==V-1 && h_cnt==H-1)
        fcs_done <= 1'b1;
    else if(fcs_done)
        fcs_done <= 1'b0;
end

`ifdef SIM
integer file_fcs;
initial begin
    file_fcs = $fopen("./fcs_result.csv","w+");  // 初始化文件
end

always @(negedge clk) begin
    if(pixel_data_out_vld) begin
        $fwrite(file_fcs,"cr=%d, cb=%d\n",pixel_data_out_cr,pixel_data_out_cb);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif

endmodule
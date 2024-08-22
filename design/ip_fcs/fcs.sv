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
    input                      pixel_data_in_vld     , 
    input           [DW-1:0]   buffer_data_in_ccs_y  ,
    input           [DW-1:0]   buffer_data_in_ccs_cr ,
    input           [DW-1:0]   buffer_data_in_ccs_cb ,
    input  signed   [DW:0]     pixel_data_in_edgemap ,
    output logic               pixel_data_out_vld    ,
    output logic    [DW-1:0]   pixel_data_out_y      ,
    output logic    [DW-1:0]   pixel_data_out_cr     ,
    output logic    [DW-1:0]   pixel_data_out_cb     ,
    output logic               fcs_done        
);

logic [HW-1:0] h_cnt; 
logic [VW-1:0] v_cnt; 

logic pixel_data_out_vld_pre;
logic [DW-1:0] pixel_data_out_pre [0:2];
logic [DW-1:0] pixel_data[0:2];
logic signed [DW:0] edge_data;
logic [DW-1:0] edge_data_abs;
logic [DW-1:0] uv_gain;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pixel_data[0] <= 'd0;
        pixel_data[1] <= 'd0;
        pixel_data[2] <= 'd0;
        edge_data <= 'sd0;
    end
    else if(fcs_en && pixel_data_in_vld) begin
        pixel_data[0] <= buffer_data_in_ccs_y  ;
        pixel_data[1] <= buffer_data_in_ccs_cr ;
        pixel_data[2] <= buffer_data_in_ccs_cb ;
        edge_data <=     pixel_data_in_edgemap ;   
    end
end

assign edge_data_abs = edge_data[DW]?   -edge_data : edge_data;

assign uv_gain = (edge_data_abs <= fcs_edge[0])?    gain :
                 (edge_data_abs >= fcs_edge[1])?    'd0 : (intercept - slop * edge_data);

assign pixel_data_out_pre[0] = (uv_gain * buffer_data_in_ccs_y ) >> 8 + 8'd128;
assign pixel_data_out_pre[1] = (uv_gain * buffer_data_in_ccs_cr) >> 8 + 8'd128;
assign pixel_data_out_pre[2] = (uv_gain * buffer_data_in_ccs_cb) >> 8 + 8'd128;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pixel_data_out_y  <= 'd0 ;
        pixel_data_out_cr <= 'd0 ;
        pixel_data_out_cb <= 'd0 ;
    end
    else if(pixel_data_out_vld_pre) begin
        pixel_data_out_y  <= pixel_data_out_pre[0] ;
        pixel_data_out_cr <= pixel_data_out_pre[1] ;
        pixel_data_out_cb <= pixel_data_out_pre[2] ;
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
endmodule
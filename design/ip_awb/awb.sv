module awb#(
    parameter DW = 16   ,
    parameter HW = 10   ,
    parameter VW = 10
)(
    input                 clk               ,
    input                 rstn              ,
    input                 awb_en            ,
    input        [HW-1:0] h_width           ,
    input        [VW-1:0] v_width           ,
    input        [2:0]    bayer_pattern     ,  
    input        [DW-1:0] awb_clip          , 
    input        [DW-1:0] pixel_data_in     ,
    input                 pixel_data_in_vld ,
    output logic [DW-1:0] pixel_data_out    ,
    output logic          pixel_data_out_vld,
    output logic          awb_done          
);
parameter B = 2'd0;
parameter G = 2'd1;
parameter R = 2'd2;
logic [1:0] bayer_arr[0:3];

logic [HW-1:0] h_cnt; 
logic [VW-1:0] v_cnt; 
logic state;
logic [1:0] bayer_index;
logic [DW+HW+VW-1:0] r_sum;
logic [DW+HW+VW-1:0] g_sum;
logic [DW+HW+VW-1:0] b_sum;
logic [DW-1:0] r_avg;
logic [DW-1:0] g_avg;
logic [DW-1:0] b_avg;
logic [DW-1:0] k_avg;
logic [DW-1:0] r_gain;
logic [DW-1:0] g_gain;
logic [DW-1:0] b_gain;

always@(*) begin
    {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,G,G,B};
    case(bayer_pattern) 
        2'd0:   {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,G,G,B};
        2'd1:   {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {B,G,G,R};
        default:{bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,G,G,B};
    endcase
end

always_ff@(posedge clk or negedge rstn) begin   // state: 0-statistic, 1-awb calc
    if(~rstn)
        state <= 1'b0;
    else if(awb_en) 
        state <= (h_cnt==h_width && v_cnt==v_width && pixel_data_in_vld)?    ~state : state;
    else
        state <= 1'b0;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(awb_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==h_width)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(awb_en && pixel_data_in_vld && h_cnt==h_width)
        v_cnt <= (v_cnt==v_width)?  'd0:(v_cnt+1'b1);
end

assign bayer_index = {v_cnt[0],h_cnt[0]};

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        r_sum <= 'd0;
    else if(awb_en) begin
        if(pixel_data_in_vld && ~state && bayer_arr[bayer_index] == R)
            r_sum <= r_sum + pixel_data_in;
    end
    else 
        r_sum <= 'd0;  
end
assign r_avg = state?   r_sum/(h_width*v_width) : 1;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        g_sum <= 'd0;
    else if(awb_en) begin
        if(pixel_data_in_vld && ~state && bayer_arr[bayer_index] == G)
            g_sum <= g_sum + pixel_data_in;
    end
    else 
        g_sum <= 'd0;  
end
assign g_avg = state?   g_sum/(h_width*v_width) : 1;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        b_sum <= 'd0;
    else if(awb_en) begin
        if(pixel_data_in_vld && ~state && bayer_arr[bayer_index] == B)
            b_sum <= b_sum + pixel_data_in;
    end
    else 
        b_sum <= 'd0;  
end
assign b_avg = state?   b_sum/(h_width*v_width) : 1;

assign k_avg = state?   (r_avg+b_avg+g_avg)/3 : 1;

assign r_gain = state?  k_avg/r_avg : 1;
assign g_gain = state?  k_avg/g_avg : 1;
assign b_gain = state?  k_avg/b_avg : 1;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out <= 'd0;
    else if(awb_en) begin
        if(pixel_data_in_vld && state)
            pixel_data_out <= (bayer_arr[bayer_index] == R)?    ((pixel_data_in * r_gain > awb_clip)?    awb_clip : pixel_data_in * r_gain) :
                              (bayer_arr[bayer_index] == G)?    ((pixel_data_in * g_gain > awb_clip)?    awb_clip : pixel_data_in * g_gain) :
                              (bayer_arr[bayer_index] == B)?    ((pixel_data_in * b_gain > awb_clip)?    awb_clip : pixel_data_in * b_gain) : 
                                                                ((pixel_data_in > awb_clip)?             awb_clip : pixel_data_in);
    end
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out_vld <= 1'b0;
    else if(awb_en && state && pixel_data_in_vld) 
        pixel_data_out_vld <= 1'b1;
    else
        pixel_data_out_vld <= 1'b0;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        awb_done <= 1'b0;
    else if(awb_en && state && pixel_data_in_vld && (v_cnt==v_width && h_cnt==h_width))
        awb_done <= 1'b1;
    else 
        awb_done <= 1'b0;
end

endmodule
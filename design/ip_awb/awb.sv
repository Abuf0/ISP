module awb#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 10   ,
    parameter VW = 10   
)(
    input                     clk                   ,
    input                     rstn                  ,
    input                     awb_en                ,
    input [1:0]               bayer_pattern         ,
    input [DW-1:0]            awb_gain [0:3]        ,
    input [DW-1:0]            awb_clip              ,
    input                     pixel_data_in_vld     ,
    input [DW-1:0]            pixel_data_in         ,
    output logic              pixel_data_out_vld    ,
    output logic [DW-1:0]     pixel_data_out  
);

parameter B = 2'd3;
parameter GR = 2'd1;
parameter GB = 2'd2;
parameter R = 2'd0;
logic [1:0] bayer_arr[0:3];
logic [1:0] bayer_index;

logic [DW:0] pixel_data_gain;   // TODO

logic [HW-1:0] h_cnt;
logic [VW-1:0] v_cnt;


always@(*) begin
    {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,GR,GB,B};
    case(bayer_pattern) 
        2'd0:   {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,GR,GB,B};
        2'd1:   {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {B,GR,GB,R};
        default:{bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,GR,GB,B};
    endcase
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(awb_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(awb_en && pixel_data_in_vld && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
end

assign bayer_index = {v_cnt[0],h_cnt[0]};

always@(*) begin
    pixel_data_gain = pixel_data_in;
    case(bayer_arr[bayer_index])
        R:   pixel_data_gain = (pixel_data_in * awb_gain[0]) >> 8;
        GR:  pixel_data_gain = (pixel_data_in * awb_gain[1]) >> 8;
        GB:  pixel_data_gain = (pixel_data_in * awb_gain[2]) >> 8;
        B:   pixel_data_gain = (pixel_data_in * awb_gain[3]) >> 8;
        default : pixel_data_gain = pixel_data_in;
    endcase
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out <= 'd0;
    else if(awb_en && pixel_data_in_vld) 
        pixel_data_out <= (pixel_data_gain > awb_clip)?  awb_clip : pixel_data_gain;        
    else if(~awb_en && pixel_data_in_vld) 
        pixel_data_out <= pixel_data_in;
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out_vld <= 1'b0;
    else
        pixel_data_out_vld <= pixel_data_in_vld;
end

`ifdef SIM
integer file_awb;
initial begin
   file_awb = $fopen("./awb_result.csv","w+");  // 初始化文件
end

always @(posedge clk) begin
    if (pixel_data_out_vld) begin
        $fwrite(file_awb,"%d\n",pixel_data_out);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif
endmodule
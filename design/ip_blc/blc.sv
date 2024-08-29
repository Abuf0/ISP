module blc#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 10   ,
    parameter VW = 10   
)(
    input                     clk                   ,
    input                     rstn                  ,
    input                     blc_en                ,
    input [1:0]               bayer_pattern         ,
    input [DW-1:0]            bias [0:3]            ,
    input [DW-1:0]            alpha                 ,
    input [DW-1:0]            beta                  ,
    input [DW-1:0]            blc_clip              ,
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
    else if(blc_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(blc_en && pixel_data_in_vld && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
end

assign bayer_index = {v_cnt[0],h_cnt[0]};

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out <= 'd0;
    else if(blc_en && pixel_data_in_vld) begin
        if(bayer_arr[bayer_index] == R)
            pixel_data_out <= (pixel_data_in + bias[0] > blc_clip)?  blc_clip : (pixel_data_in + bias[0]);
        else if(bayer_arr[bayer_index] == GR)
            pixel_data_out <= (pixel_data_in + bias[1] > blc_clip)?  blc_clip : (pixel_data_in + bias[1]);
        else if(bayer_arr[bayer_index] == GB)
            pixel_data_out <= (pixel_data_in + bias[2] > blc_clip)?  blc_clip : (pixel_data_in + bias[2]);
        else if(bayer_arr[bayer_index] == B)
            pixel_data_out <= (pixel_data_in + bias[3] > blc_clip)?  blc_clip : (pixel_data_in + bias[3]);        
    end
    else if(~blc_en && pixel_data_in_vld) begin
        pixel_data_out <= pixel_data_in;
    end
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out_vld <= 1'b0;
    else
        pixel_data_out_vld <= pixel_data_in_vld;
end

`ifdef SIM
integer file_blc;
initial begin
   file_blc = $fopen("./blc_result.csv","w+");  // 初始化文件
end

always @(posedge clk) begin
    if (pixel_data_out_vld) begin
        $fwrite(file_blc,"%d\n",pixel_data_out);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif
endmodule
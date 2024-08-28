module aaf#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                   clk                   ,
    input                   rstn                  ,
    input                   aaf_en                ,
    input        [DW-1:0]   pixel_data_in         ,
    input                   pixel_data_in_vld     ,
    output logic [DW-1:0]   pixel_data_out        ,
    output logic            pixel_data_out_vld    ,
    output logic            aaf_done        
);
// 原方案：padding时停顿，shift入0；舍弃原因：串行输入是连续的
logic [DW-1:0] shift_reg[0:4*H+4];
logic [DW-1:0] mac_arr[0:8];
logic [DW-1:0] pixel_data_out_pre;
logic pixel_data_out_vld_pre;
logic [HW-1:0] h_cnt;
logic [VW-1:0] v_cnt;
logic init;
genvar i;
generate 
    for(i=0;i<4*H+5;i=i+1) begin: SFT_REG
        if(i==0) begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(aaf_en && pixel_data_in_vld) 
                    shift_reg[i] <= pixel_data_in;
            end
        end
        else begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(aaf_en && pixel_data_in_vld)
                    shift_reg[i] <= shift_reg[i-1];
            end
        end
    end
endgenerate

assign mac_arr[0] = (v_cnt > 'd1 && h_cnt > 'd1)? shift_reg[4*H+4]          : 'd0 ;
assign mac_arr[1] = (v_cnt > 'd1)?                shift_reg[4*H+2]          : 'd0 ;
assign mac_arr[2] = (v_cnt > 'd1 && h_cnt < H-2)? shift_reg[4*H]            : 'd0 ;
assign mac_arr[3] = (h_cnt > 'd1)?                shift_reg[2*H+4]          : 'd0 ;
assign mac_arr[4] =                               shift_reg[2*H+2]                ;
assign mac_arr[5] = (h_cnt < H-2)?                shift_reg[2*H]            : 'd0 ;
assign mac_arr[6] = (v_cnt < V-2 && h_cnt > 'd1)? shift_reg[4]              : 'd0 ;
assign mac_arr[7] = (v_cnt < V-2)?                shift_reg[2]              : 'd0 ;
assign mac_arr[8] = (v_cnt < V-2 && h_cnt < H-2)? shift_reg[0]              : 'd0 ;

assign pixel_data_out_pre = (mac_arr[0]+mac_arr[1]+mac_arr[2]+mac_arr[3]+(mac_arr[4] << 3)+mac_arr[5]+mac_arr[6]+mac_arr[7]+mac_arr[8]) >> 4 ;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(init && v_cnt==2 && h_cnt==2)
        h_cnt <= 'd0;
    else if(aaf_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(init && v_cnt==2 && h_cnt==2)
        v_cnt <= 'd0;
    else if(aaf_en && pixel_data_in_vld && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)   
        init <= 1'b1;
    else if(init && v_cnt==2 && h_cnt==2)
        init <= 1'b0;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out <= 'd0;
    else if(aaf_en)
        pixel_data_out <= pixel_data_out_pre;
    else 
        pixel_data_out <= pixel_data_in;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out_vld <= 1'b0;
    else if(aaf_en)
        pixel_data_out_vld <= ~init && pixel_data_in_vld;
    else 
        pixel_data_out_vld <= pixel_data_in_vld;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        aaf_done <= 1'b0;
    else if(aaf_en && v_cnt==V-1 && h_cnt==H-1 && ~init && ~aaf_done)
        aaf_done <= 1'b1;
    else if(aaf_done)
        aaf_done <= 1'b0;
end


`ifdef SIM
integer file_aaf;
initial begin
   file_aaf = $fopen("./aaf_result.csv","w+");  // 初始化文件
end

always @(posedge clk) begin
    if (pixel_data_out_vld) begin
        $fwrite(file_aaf,"%d\n",pixel_data_out);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end

`endif

endmodule
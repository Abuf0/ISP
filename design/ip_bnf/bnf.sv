module bnf#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                   clk                   ,
    input                   rstn                  ,
    input                   bnf_en                ,
    input        [DW-1:0]   dw [0:4][0:4]         ,      
    input        [DW-1:0]   rw [0:3]              ,
    input        [DW-1:0]   rthres [0:2]          ,
    input        [DW-1:0]   bnf_clip              ,
    input        [DW-1:0]   pixel_data_in         ,
    input                   pixel_data_in_vld     ,
    output logic [DW-1:0]   pixel_data_out        ,
    output logic            pixel_data_out_vld    ,
    output logic            bnf_done        
);
// 原方案：padding时停顿，shift入0；舍弃原因：串行输入是连续的
logic [DW-1:0] shift_reg[0:4*H+4];
logic [DW-1:0] array[0:4][0:4];
logic [DW-1:0] rdiff[0:4][0:4];
logic [DW-1:0] weight[0:4][0:4];
logic [DW-1:0] img_wgt [0:4][0:4];
logic [DW+5-1:0] img_wgt_sum;
logic [DW+5-1:0] weight_sum;
logic [DW-1:0] pixel_data_out_pre;
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
                else if(bnf_en && pixel_data_in_vld) 
                    shift_reg[i] <= pixel_data_in;
            end
        end
        else begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(bnf_en && pixel_data_in_vld)
                    shift_reg[i] <= shift_reg[i-1];
            end
        end
    end
endgenerate

genvar x;
genvar y;
generate 
    for(x=0;x<5;x=x+1) begin
        for(y=0;y<5;y=y+1) begin
            assign array[x][y] = ( (x<2 && v_cnt < (2-x)) || (v_cnt > (V-1)+2-x) || (t<2 && h_cnt < (2-y)) || (h_cnt > (H-1)+2-y))?   'd0 : shift_reg[4*H+4-(x*H+y)];
        end 
    end
endgenerate

generate 
    for(x=0;x<5;x=x+1) begin
        for(y=0;y<5;y=y+1) begin
            logic [DW-1:0] rdiff_rw;
            assign rdiff[x][y] = (array[x][y] > array[2][2])?  array[x][y]-array[2][2] : array[2][2]-array[x][y];
            assign rdiff_rw = (rdiff[x][y] >= rthres[0])?    rw[0] :
                              (rdiff[x][y] < rthres[0] && rdiff[x][y] >= rthres[1])?     rw[1] :
                              (rdiff[x][y] < rthres[1] && rdiff[x][y] >= rthres[2])?     rw[2] :
                              (rdiff[x][y] < rthres[2])?     rw[3] : rdiff[x][y];
            assign weight[x][y] = rdiff_rw * dw[x][y];
            assign img_wgt[x][y] = array[x][y] * weight[x][y];
        end 
    end
endgenerate

assign img_wgt_sum = img_wgt[0][0] + img_wgt[0][1] + img_wgt[0][2] + img_wgt[0][3] + img_wgt[0][4] + 
                     img_wgt[1][0] + img_wgt[1][1] + img_wgt[1][2] + img_wgt[1][3] + img_wgt[1][4] + 
                     img_wgt[2][0] + img_wgt[2][1] + img_wgt[2][2] + img_wgt[2][3] + img_wgt[2][4] + 
                     img_wgt[3][0] + img_wgt[3][1] + img_wgt[3][2] + img_wgt[3][3] + img_wgt[3][4] + 
                     img_wgt[4][0] + img_wgt[4][1] + img_wgt[4][2] + img_wgt[4][3] + img_wgt[4][4] ;

assign weight_sum =  weight[0][0] + weight[0][1] + weight[0][2] + weight[0][3] + weight[0][4] + 
                     weight[1][0] + weight[1][1] + weight[1][2] + weight[1][3] + weight[1][4] + 
                     weight[2][0] + weight[2][1] + weight[2][2] + weight[2][3] + weight[2][4] + 
                     weight[3][0] + weight[3][1] + weight[3][2] + weight[3][3] + weight[3][4] + 
                     weight[4][0] + weight[4][1] + weight[4][2] + weight[4][3] + weight[4][4] ;

assign pixel_data_out_pre = img_wgt_sum / weight_sum ;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(init && v_cnt==2 && h_cnt==2)
        h_cnt <= 'd0;
    else if(bnf_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(init && v_cnt==2 && h_cnt==2)
        v_cnt <= 'd0;
    else if(bnf_en && pixel_data_in_vld && h_cnt==H-1)
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
    else if(bnf_en)
        pixel_data_out <= (pixel_data_out_pre > bnf_clip)?  bnf_clip : pixel_data_out_pre;
    else
        pixel_data_out <= pixel_data_in;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out_vld <= 'd0;
    else if(bnf_en)
        pixel_data_out_vld <= ~init && pixel_data_in_vld;
    else
        pixel_data_out_vld <= pixel_data_in_vld;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        bnf_done <= 1'b0;
    else if(bnf_en && v_cnt==V-1 && h_cnt==H-1 && ~init && ~bnf_done)
        bnf_done <= 1'b1;
    else if(bnf_done)
        bnf_done <= 1'b0;
end

`ifdef SIM
integer file_bnf;
initial begin
    file_bnf = $fopen("./bnf_result.csv","w+");  // 初始化文件
end

always @(negedge clk) begin
    if(pixel_data_out_vld) begin
        $fwrite(file_bnf,"%d\n",pixel_data_out);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif

endmodule
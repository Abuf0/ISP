module ccm#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                   clk                   ,
    input                   rstn                  ,
    input                   ccm_en                ,
    input        [DW-1:0]   ccm_coef_r [0:3]      ,
    input        [DW-1:0]   ccm_coef_g [0:3]      ,
    input        [DW-1:0]   ccm_coef_b [0:3]      ,
    input                   pixel_data_in_vld     , 
    input        [DW/3-1:0] pixel_data_in_r       ,
    input        [DW/3-1:0] pixel_data_in_g       ,
    input        [DW/3-1:0] pixel_data_in_b       ,
    output logic            pixel_data_out_vld    ,
    output logic [DW/3-1:0] pixel_data_out_r      ,
    output logic [DW/3-1:0] pixel_data_out_g      ,
    output logic [DW/3-1:0] pixel_data_out_b      ,
    output logic            ccm_done        
);

logic [DW/3-1:0]   pixel_data_r;          
logic [DW/3-1:0]   pixel_data_g;          
logic [DW/3-1:0]   pixel_data_b;  

logic [D/3+DW/3+2-1:0] pixel_data_out_r_tmp;
logic [D/3+DW/3+2-1:0] pixel_data_out_g_tmp;
logic [D/3+DW/3+2-1:0] pixel_data_out_b_tmp;

logic [HW-1:0] h_cnt; 
logic [VW-1:0] v_cnt; 

logic pixel_data_out_vld_pre;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pixel_data_r <= 'd0;
        pixel_data_g <= 'd0;
        pixel_data_b <= 'd0;
    end
    else if(pixel_data_in_vld) begin
        pixel_data_r <= pixel_data_in_r;
        pixel_data_g <= pixel_data_in_g;
        pixel_data_b <= pixel_data_in_b;
    end
end
assign pixel_data_out_r_tmp = ccm_coef_r[0]*pixel_data_r + ccm_coef_r[1]*pixel_data_g + ccm_coef_r[2]*pixel_data_b + ccm_coef_r[3];
assign pixel_data_out_g_tmp = ccm_coef_g[0]*pixel_data_r + ccm_coef_g[1]*pixel_data_g + ccm_coef_g[2]*pixel_data_b + ccm_coef_g[3];
assign pixel_data_out_b_tmp = ccm_coef_b[0]*pixel_data_r + ccm_coef_b[1]*pixel_data_g + ccm_coef_b[2]*pixel_data_b + ccm_coef_b[3];

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pixel_data_out_r <= 'd0;
        pixel_data_out_g <= 'd0;
        pixel_data_out_b <= 'd0;
    end
    else if(ccm_en) begin
        pixel_data_out_r <= pixel_data_out_r_tmp << 10;
        pixel_data_out_g <= pixel_data_out_g_tmp << 10;
        pixel_data_out_b <= pixel_data_out_b_tmp << 10;
    end
    else begin
        pixel_data_out_r <= pixel_data_r;
        pixel_data_out_g <= pixel_data_g;
        pixel_data_out_b <= pixel_data_b;
    end
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        {pixel_data_out_vld_pre,pixel_data_out_vld} <= 2'd0;
    else if(ccm_en)
        {pixel_data_out_vld_pre,pixel_data_out_vld} <= {pixel_data_in_vld,pixel_data_out_vld_pre};
    else 
        {pixel_data_out_vld_pre,pixel_data_out_vld} <= {pixel_data_in_vld,pixel_data_in_vld};
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(ccm_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(ccm_en && pixel_data_in_vld && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        ccm_done <= 1'b0;
    else if(ccm_en && v_cnt==V-1 && h_cnt==H-1)
        ccm_done <= 1'b1;
    else if(ccm_done)
        ccm_done <= 1'b0;
end

`ifdef SIM
integer file_cm;
initial begin
    file_ccm = $fopen("./ccm_result.csv","w+");  // 初始化文件
end
integer x;
integer y;
always @(negedge clk) begin
    if (pixel_data_out_vld) begin
        //for(x=0;x<9;x=x+1) begin
        //    for(y=0;y<9;y=y+1) begin
        //        $fwrite(file_cnf_p,"%d",mac_arr[x*9+y]);
        //    end
        //    $fwrite(file_cnf_p,"\n");
        //end
    fwrite(file_ccm,"(%d,%d)%d-%d-%d\n",v_cnt,h_cnt,pixel_data_out_r,pixel_data_out_g,pixel_data_out_b);
    //$fwrite(file_cnf,"%d\n",pixel_data_out);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif

endmodule
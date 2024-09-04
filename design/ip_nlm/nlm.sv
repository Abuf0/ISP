module nlm#(
    parameter DW = 16   ,
    parameter DS = 3    ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                   clk                   ,
    input                   rstn                  ,
    input                   nlm_en                ,
    input        [DW-1:0]   nlm_clip              ,
    input                   pixel_data_in_vld     , 
    input        [DW-1:0]   pixel_data_in         ,
    output logic            pixel_data_out_vld    ,
    output logic [DW-1:0]   pixel_data_out        ,
    output logic            nlm_done              
);

logic [DW-1:0]   array [0:2*DS] [0:2*DS] ;
logic            data_vld                ;
logic [DW-1:0]   wmax                    ;
logic [DW+DW-1:0]wsum                    ;
logic [DW+DW-1:0]average                 ;
logic [DW-1:0]   center                  ;
logic            calout_vld              ;
logic            calout_vld_ff1          ;

// 原方案：padding时停顿，shift入0；舍弃原因：串行输入是连续的
logic [DW-1:0] shift_reg[0:(2*DS)*H+2*DS];
logic [HW-1:0] h_cnt;
logic [VW-1:0] v_cnt;
logic init;

logic [DW-1:0]    pixel_data_out_pre;
logic [DW+DW-1:0] pixel_average;
logic [DW+DW-1:0] pixel_wsum;

genvar i;
generate 
    for(i=0;i<2*DS*H+2*DS+1;i=i+1) begin: SFT_REG
        if(i==0) begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(nlm_en && pixel_data_in_vld) 
                    shift_reg[i] <= pixel_data_in;
            end
        end
        else begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(nlm_en && pixel_data_in_vld)
                    shift_reg[i] <= shift_reg[i-1];
            end
        end
    end
endgenerate

genvar x;
genvar y;
generate 
    for(x=0;x<2*DS+1;x=x+1) begin
        for(y=0;y<2*DS+1;y=y+1) begin
            assign array[x][y] = ( (x<DS && v_cnt < (DS-x)) || (v_cnt > V+DS-x) || (y<DS && h_cnt < (DS-y)) || (h_cnt > (H+DS-y)))?   'd0 : shift_reg[2*DS*H+2*DS-(x*H+y)] ;
        end 
    end
endgenerate

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(init && v_cnt==DS && h_cnt==DS)
        h_cnt <= 'd0;
    else if(nlm_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(init && v_cnt==DS && h_cnt==DS)
        v_cnt <= 'd0;
    else if(nlm_en && pixel_data_in_vld && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
end
   
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)   
        init <= 1'b1;
    else if(init && v_cnt==DS && h_cnt==DS)
        init <= 1'b0;
end


always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        data_vld <= 'd0;
    else if(nlm_en)
        data_vld <= ~init & pixel_data_in_vld  ;
end

calweights #(
   .DW(DW)    ,
   .DS(DS)    ,   // search window size-1 /2
   .KS(1)        // neighbour window size-1 /2
) cal_weight_inst
(
    .clk               ( clk         ),
    .rstn              ( rstn        ),
    .array             ( array       ),
    .data_vld          ( data_vld    ),
    .wmax              ( wmax        ),
    .wsum              ( wsum        ),
    .average           ( average     ),
    .center            ( center      ),
    .calout_vld        ( calout_vld  ) 
);

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_wsum <= 'd0;
    else  if(calout_vld)
        pixel_wsum <= wsum ;//+ wmax;
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_average <= 'd0;
    else  if(calout_vld)
        pixel_average <= average ;//+ wmax * center;
end

assign pixel_data_out_pre = pixel_average / pixel_wsum;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out <= 'd0;
    else  if(nlm_en && calout_vld_ff1)
        pixel_data_out <= (pixel_data_out_pre > nlm_clip)?  nlm_clip : pixel_data_out_pre;
    else if(~nlm_en && pixel_data_in_vld)
        pixel_data_out <= pixel_data_in;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        {pixel_data_out_vld, calout_vld_ff1} <= 2'd0;
    else if(nlm_en)
        {pixel_data_out_vld, calout_vld_ff1} <= {calout_vld_ff1,calout_vld};
    else 
        {pixel_data_out_vld, calout_vld_ff1} <= {pixel_data_in_vld,1'b0};
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        nlm_done <= 1'b0;
    else if(nlm_en && v_cnt==V-1 && h_cnt==H-1 && ~init && ~nlm_done)
        nlm_done <= 1'b1;
    else if(nlm_done)
        nlm_done <= 1'b0;
end

`ifdef SIM
integer file_nlm;
initial begin
    file_nlm = $fopen("./nlm_result.csv","w+");  // 初始化文件
end

always @(negedge clk) begin
    if(pixel_data_out_vld) begin
        $fwrite(file_nlm,"%d\n",pixel_data_out);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif

endmodule
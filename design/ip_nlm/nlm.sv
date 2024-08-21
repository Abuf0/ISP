module nlm#(
    parameter DW = 16   ,
    parameter DS = 4    ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                   clk                   ,
    input                   rstn                  ,
    input                   nlm_en                ,
    input                   pixel_data_in_vld     , 
    input        [DW-1:0]   pixel_data_in         ,
    output logic            pixel_data_out_vld    ,
    output logic [DW-1:0]   pixel_data_out        ,
    output logic            nlm_done              
);

logic [DW-1:0]   array [0:DS*2] [0:DS*2] ;
logic            data_vld                ;
logic [DW-1:0]   wmax                    ;
logic [DW-1:0]   wsum                    ;
logic [DW-1:0]   average                 ;
logic [DW-1:0]   center                  ;
logic            calout_vld              ;
logic            calout_vld_ff1          ;

// 原方案：padding时停顿，shift入0；舍弃原因：串行输入是连续的
logic [DW-1:0] shift_reg[0:(DS-1)*H+DS-1];
logic [HW-1:0] h_cnt;
logic [VW-1:0] v_cnt;
logic flag;

logic [DW-1:0] pixel_data_out_pre;
logic [DW-1:0] pixel_average;
logic [DW-1:0] pixel_wsum;
logic [DW-1:0] pixel_data_out_pre;

genvar i;
generate 
    for(i=0;i<4*H+4;i=i+1) begin: SFT_REG
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
    for(x=0;x<DS*2+1;x=x+1) begin
        for(y=0;y<DS*2+1;y=y+1) begin
            array[x][y] = ( (v_cnt < (DS-x)) || (v_cnt > V+DS-x) || (h_cnt < (DS-y)) || (h_cnt > (H+DS-y)))?   shift_reg[x*H+y]    : 'd0;
        end 
    end
endgenerate

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(nlm_en && (pixel_data_in_vld || flag))
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(nlm_en && (pixel_data_in_vld || flag) && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        flag <= 1'b0;
    else if(nlm_en && v_cnt==V-1 && h_cnt==H-1)
        flag <= 1'b1;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        data_vld <= 'd0;
    else if(nlm_en && v_cnt >= DS && h_cnt >= DS)
        data_vld <= (pixel_data_in_vld || flag) ;
end

calweight #(
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
        pixel_wsum <= wsum + wmax;
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_average <= 'd0;
    else  if(calout_vld)
        pixel_average <= average + wmax * center;
end

assign pixel_data_out_pre = pixel_average / pixel_wsum;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out <= 'd0;
    else  if(calout_vld_ff1)
        pixel_data_out <= pixel_data_out_pre;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        {pixel_data_out_vld, calout_vld_ff1} <= 2'd0;
    else if(nlm_en)
        {pixel_data_out_vld, calout_vld_ff1} <= {calout_vld_ff1,calout_vld};
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        nlm_done <= 1'b0;
    else if(nlm_en && v_cnt==V-1 && h_cnt==H-1 && flag && ~nlm_done)
        nlm_done <= 1'b1;
    else if(nlm_done)
        nlm_done <= 1'b0;
end
endmodule
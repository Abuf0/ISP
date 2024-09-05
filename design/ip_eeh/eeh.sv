module eeh#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                           clk                   ,
    input                           rstn                  ,
    input                           eeh_en                ,
    input signed [4:0]              edge_filter [0:2][0:4],    // -1 or +1  compensate code
    input signed [DW:0]             eeh_clip [0:1]        ,
    input        [DW-1:0]           eeh_rthres [0:1]      ,
    input        [DW-1:0]           eeh_gain [0:1]        ,
    input        [DW-1:0]           pixel_data_in         ,
    input                           pixel_data_in_vld     ,
    output logic [DW-1:0]           pixel_data_out_ee     ,
    output logic signed [DW:0]      pixel_data_out_em     ,
    output logic                    pixel_data_out_vld    ,
    output logic                    eeh_done        
);
// 原方案：padding时停顿，shift入0；舍弃原因：串行输入是连续的
logic [DW-1:0] shift_reg[0:2*H+4];
logic [DW-1:0] array[0:2][0:4];

logic signed [DW:0] em_img_wght [0:2][0:4];
logic signed [DW+3:0] em_img_sum;
logic signed [DW:0] ee_img;
logic signed [DW:0] em_img;
logic signed [DW:0] em_lut;
logic signed [DW:0] em_lut_clip_pre;
logic signed [DW:0] em_lut_clip;
logic [DW-1:0]   pixel_data_out_ee_pre;
logic signed [DW:0]   pixel_data_out_em_pre;

logic pixel_data_out_vld_pre;
logic [HW-1:0] h_cnt;
logic [VW-1:0] v_cnt;
logic init;

genvar i;
generate 
    for(i=0;i<2*H+5;i=i+1) begin: SFT_REG
        if(i==0) begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(eeh_en && pixel_data_in_vld) 
                    shift_reg[i] <= pixel_data_in;
            end
        end
        else begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(eeh_en && pixel_data_in_vld)
                    shift_reg[i] <= shift_reg[i-1];
            end
        end
    end
endgenerate

genvar x;
genvar y;
generate 
    for(x=0;x<3;x=x+1) begin
        for(y=0;y<5;y=y+1) begin    // pad((1,1),(2,2))
            assign array[x][y] = ( (x<1 && v_cnt < (1-x)) || (v_cnt > V+1-x) || (y<2 && h_cnt < (2-y)) || (h_cnt > (H+2-y)))?   'd0 : shift_reg[2*H+4-(x*H+y)] ;
            assign em_img_wght[x][y] = edge_filter[x][y]*$signed(array[x][y]);
        end 
    end
endgenerate

assign em_img_sum = em_img_wght[0][0] + em_img_wght[0][1] + em_img_wght[0][2] + em_img_wght[0][3] + em_img_wght[0][4] + 
                    em_img_wght[1][0] + em_img_wght[1][1] + em_img_wght[1][2] + em_img_wght[1][3] + em_img_wght[1][4] +
                    em_img_wght[2][0] + em_img_wght[2][1] + em_img_wght[2][2] + em_img_wght[2][3] + em_img_wght[2][4] ;

assign em_img = em_img_sum >>> 3 ;

assign em_lut = (em_img <= -eeh_rthres[1])?   eeh_gain[1]*em_img :
                (em_img > -eeh_rthres[1] && em_img < -eeh_rthres[0])?   'sd0 :
                (em_img <= eeh_rthres[0] && em_img >= -eeh_rthres[1])?   eeh_gain[0]*em_img :
                (em_img > eeh_rthres[0] && em_img < eeh_rthres[1])?   'sd0 :
                (em_img >= eeh_rthres[1])?   eeh_gain[1]*em_img :    'sd0;

assign em_lut_clip_pre = ((em_lut>>>8) > eeh_clip[1])?   eeh_clip[1] : (em_lut>>>8);
assign em_lut_clip = (eeh_clip[0] > em_lut_clip_pre)?   eeh_clip[0] : em_lut_clip_pre;

assign ee_img = array[1][2] + em_lut_clip ;

assign pixel_data_out_ee_pre = (ee_img < 0)?    'd0 :
                               (ee_img > 'd255)?    'd255: ee_img ;

assign pixel_data_out_em_pre = em_img;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(init && v_cnt==1 && h_cnt==2)
        h_cnt <= 'd0;
    else if(eeh_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(init && v_cnt==1 && h_cnt==2)
        v_cnt <= 'd0;
    else if(eeh_en && pixel_data_in_vld && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
end
   
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)   
        init <= 1'b1;
    else if(init && v_cnt==1 && h_cnt==2)
        init <= 1'b0;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out_ee <= 'd0;
    else if(eeh_en)
        pixel_data_out_ee <= pixel_data_out_ee_pre;
    else
        pixel_data_out_ee <= pixel_data_in;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out_em <= 'd0;
    else if(eeh_en)
        pixel_data_out_em <= pixel_data_out_em_pre;
    else
        pixel_data_out_em <= pixel_data_in;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out_vld <= 'd0;
    else if(eeh_en)
        pixel_data_out_vld <= ~init && pixel_data_in_vld;
    else 
        pixel_data_out_vld <= pixel_data_in_vld;
end


always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        eeh_done <= 1'b0;
    else if(eeh_en && v_cnt==V-1 && h_cnt==H-1 && ~init && ~eeh_done)
        eeh_done <= 1'b1;
    else if(eeh_done)
        eeh_done <= 1'b0;
end

`ifdef SIM
integer file_eeh;
initial begin
    file_eeh = $fopen("./eeh_result.csv","w+");  // 初始化文件
end

always @(negedge clk) begin
    if(pixel_data_out_vld) begin
        $fwrite(file_eeh,"%d, %d\n",pixel_data_out_ee,pixel_data_out_em);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif

endmodule
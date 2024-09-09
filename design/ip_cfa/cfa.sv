module cfa#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                       clk                   ,
    input                       rstn                  ,
    input                       cfa_en                ,
    input        [2:0]          bayer_pattern         ,  
    input        [DW-1:0]       cfa_clip              ,
    input        [DW-1:0]       pixel_data_in         ,
    input                       pixel_data_in_vld     ,
    output logic [DW-1:0]       pixel_data_out_r      ,
    output logic [DW-1:0]       pixel_data_out_g      ,
    output logic [DW-1:0]       pixel_data_out_b      , 
    output logic                pixel_data_out_vld    ,
    output logic                cfa_done        
);
// 原方案：padding时停顿，shift入0；舍弃原因：串行输入是连续的
logic [DW-1:0] shift_reg[0:4*H+4];
logic [DW-1:0] mac_arr[0:24];
logic [HW-1:0] h_cnt;
logic [VW-1:0] v_cnt;
logic init;

logic [DW-1:0] pixel_data_out_r_pre;
logic [DW-1:0] pixel_data_out_g_pre;
logic [DW-1:0] pixel_data_out_b_pre;

parameter B = 2'd3;
parameter GB = 2'd2;
parameter GR = 2'd1;
parameter R = 2'd0;
logic [1:0] bayer_arr[0:3];
logic [1:0] bayer_index;

logic signed [DW:0] r [0:4-1];
logic signed [DW:0] g [0:4-1];
logic signed [DW:0] b [0:4-1];

always@(*) begin
    {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,GR,GB,B};
    case(bayer_pattern) 
        2'd0:   {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,GR,GB,B};
        2'd1:   {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {B,GB,GR,R};
        default:{bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,GR,GB,B};
    endcase
end
assign bayer_index = {v_cnt[0],h_cnt[0]};

genvar i;
generate 
    for(i=0;i<4*H+5;i=i+1) begin: SFT_REG
        if(i==0) begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(cfa_en && pixel_data_in_vld) 
                    shift_reg[i] <= pixel_data_in;
            end
        end
        else begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(cfa_en && pixel_data_in_vld)
                    shift_reg[i] <= shift_reg[i-1];
            end
        end
    end
endgenerate
genvar j;
generate
    for(j=0;j<2;j=j+1) begin
        assign mac_arr[j*5+0] = (v_cnt > (1-j) && h_cnt > 'd1)? shift_reg[4*H+4-(j*H+0)]            : 'd0 ;
        assign mac_arr[j*5+1] = (v_cnt > (1-j) && h_cnt > 'd0)? shift_reg[4*H+4-(j*H+1)]            : 'd0 ;
        assign mac_arr[j*5+2] = (v_cnt > (1-j)               )? shift_reg[4*H+4-(j*H+2)]            : 'd0 ;
        assign mac_arr[j*5+3] = (v_cnt > (1-j) && h_cnt < H-1)? shift_reg[4*H+4-(j*H+3)]            : 'd0 ;
        assign mac_arr[j*5+4] = (v_cnt > (1-j) && h_cnt < H-2)? shift_reg[4*H+4-(j*H+4)]            : 'd0 ;       
    end 
    for(j=2;j<5;j=j+1) begin
        assign mac_arr[j*5+0] = (v_cnt < (V+2-j) && h_cnt > 'd1)? shift_reg[4*H+4-(j*H+0)]          : 'd0 ;
        assign mac_arr[j*5+1] = (v_cnt < (V+2-j) && h_cnt > 'd0)? shift_reg[4*H+4-(j*H+1)]          : 'd0 ;
        assign mac_arr[j*5+2] = (v_cnt < (V+2-j)               )? shift_reg[4*H+4-(j*H+2)]          : 'd0 ;
        assign mac_arr[j*5+3] = (v_cnt < (V+2-j) && h_cnt < H-1)? shift_reg[4*H+4-(j*H+3)]          : 'd0 ;
        assign mac_arr[j*5+4] = (v_cnt < (V+2-j) && h_cnt < H-2)? shift_reg[4*H+4-(j*H+4)]          : 'd0 ; 
    end
endgenerate

//assign pixel_data_out_tmp = (mac_arr[0]+mac_arr[1]+mac_arr[2]+mac_arr[3]+(mac_arr[4] << 3)+mac_arr[5]+mac_arr[6]+mac_arr[7]+mac_arr[8]) >> 4 ;

assign r[0] = mac_arr[12]<<3;
assign r[1] = (mac_arr[12]<<2) + mac_arr[12] - mac_arr[10] - mac_arr[6] - mac_arr[16] - mac_arr[8] - mac_arr[18] - mac_arr[14] +
              ((mac_arr[2] + mac_arr[22])>>1) + ((mac_arr[11] + mac_arr[13])<<2);
assign r[2] = (mac_arr[12]<<2) + mac_arr[12] - mac_arr[2] - mac_arr[6] - mac_arr[8] - mac_arr[22] - mac_arr[16] - mac_arr[18] +
              ((mac_arr[10] + mac_arr[14])>>1) + ((mac_arr[7] + mac_arr[17])<<2);
assign r[3] = (mac_arr[12]<<2) + (mac_arr[12]<<1) - (3*(mac_arr[10] + mac_arr[2] + mac_arr[14] + mac_arr[22])>>1) +
              ((mac_arr[6] + mac_arr[8] + mac_arr[16] + mac_arr[18])<<1);
              

assign g[0] = (mac_arr[12]<<2) - mac_arr[2] - mac_arr[10] - mac_arr[22] - mac_arr[14] +
              ((mac_arr[17] + mac_arr[13] + mac_arr[7] + mac_arr[11])<<1);
assign g[1] = mac_arr[12]<<3;
assign g[2] = mac_arr[12]<<3;
assign g[3] = g[0];

assign b[0] = r[3];
assign b[1] = r[2];
assign b[2] = r[1];
assign b[3] = mac_arr[12]<<3;  // r[0]

assign pixel_data_out_r_pre = r[bayer_index][DW]?   'd0 : ((r[bayer_index] >> 3) > cfa_clip?     cfa_clip : (r[bayer_index] >> 3)) ;
assign pixel_data_out_g_pre = g[bayer_index][DW]?   'd0 : ((g[bayer_index] >> 3) > cfa_clip?     cfa_clip : (g[bayer_index] >> 3)) ;
assign pixel_data_out_b_pre = b[bayer_index][DW]?   'd0 : ((b[bayer_index] >> 3) > cfa_clip?     cfa_clip : (b[bayer_index] >> 3)) ;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(init && v_cnt==2 && h_cnt==2)
        h_cnt <= 'd0;
    else if(cfa_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(init && v_cnt==2 && h_cnt==2)
        v_cnt <= 'd0;
    else if(cfa_en && pixel_data_in_vld && h_cnt==H-1)
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
        pixel_data_out_vld <= 1'b0;
    else if(cfa_en)
        pixel_data_out_vld <= ~init & pixel_data_in_vld;
    else 
        pixel_data_out_vld <= pixel_data_in_vld;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        {pixel_data_out_r,pixel_data_out_g,pixel_data_out_b} <= 'd0;
    else if(cfa_en)
        {pixel_data_out_r,pixel_data_out_g,pixel_data_out_b} <= {pixel_data_out_r_pre,pixel_data_out_g_pre,pixel_data_out_b_pre};
    else 
        {pixel_data_out_r,pixel_data_out_g,pixel_data_out_b} <= {pixel_data_in,pixel_data_in,pixel_data_in};
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        cfa_done <= 1'b0;
    else if(cfa_en && v_cnt==V-1 && h_cnt==H-1 && ~init && ~cfa_done)
        cfa_done <= 1'b1;
    else if(cfa_done)
        cfa_done <= 1'b0;
end

`ifdef SIM
integer file_cfa;
initial begin
    file_cfa = $fopen("./cfa_result.csv","w+");  // 初始化文件
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
    $fwrite(file_cfa,"(%d,%d)%d-%d-%d\n",v_cnt,h_cnt,pixel_data_out_r,pixel_data_out_g,pixel_data_out_b);
    //$fwrite(file_cnf,"%d\n",pixel_data_out);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif

endmodule
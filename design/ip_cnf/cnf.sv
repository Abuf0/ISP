module cnf#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                   clk                   ,
    input                   rstn                  ,
    input                   cnf_en                ,
    input        [DW-1:0]   thres                 ,
    input        [DW-1:0]   cnf_gain [0:3]        ,
    input        [DW-1:0]   cnf_clip              ,
    input        [2:0]      bayer_pattern         ,  
    input        [DW-1:0]   pixel_data_in         ,
    input                   pixel_data_in_vld     ,
    output logic [DW-1:0]   pixel_data_out        ,
    output logic            pixel_data_out_vld    ,
    output logic            cnf_done        
);
// 原方案：padding时停顿，shift入0；舍弃原因：串行输入是连续的
logic [DW-1:0] shift_reg[0:8*H+8];
logic [DW-1:0] mac_arr[0:81-1];
logic [DW+25-1:0] mac_acc_a;
logic [DW+20-1:0] mac_acc_b;
logic [DW+20-1:0] mac_acc_c;
logic [DW+20-1:0] mac_acc_d;
logic [DW-1:0] center;
logic [DW-1:0] avg_g;
logic [DW-1:0] avg_c1;
logic [DW-1:0] avg_c2;

logic is_noise;

parameter B = 2'd3;
parameter GB = 2'd2;
parameter GR = 2'd1;
parameter R = 2'd0;
logic [1:0] bayer_arr[0:3];

//************************************
// xiao shu --> Nbit --> TODO
logic [DW-1:0] r_gain;
logic [DW-1:0] gr_gain;
logic [DW-1:0] gb_gain;
logic [DW-1:0] b_gain;

logic [DW-1:0] signal_gap;
logic signal_gap_sign;
logic [DW-1:0] damp_factor;
logic [DW-1:0] chroma_corr;
logic [DW-1:0] signal_meter;
logic [DW-1:0] fade1;
logic [DW-1:0] fade2;
logic [DW-1:0] fadetot;
logic [DW-1:0] center_out;

// ********************************
logic [DW-1:0] pixel_data_out_pre;
logic [HW-1:0] h_cnt;
logic [VW-1:0] v_cnt;
logic init;
logic [1:0] bayer_index;

assign r_gain = cnf_gain[0];
assign gr_gain = cnf_gain[1];
assign gb_gain = cnf_gain[2];
assign b_gain = cnf_gain[3];

genvar i;
generate 
    for(i=0;i<8*H+9;i=i+1) begin: SFT_REG
        if(i==0) begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(cnf_en && pixel_data_in_vld) 
                    shift_reg[i] <= pixel_data_in;
            end
        end
        else begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    shift_reg[i] <= 'd0;
                else if(cnf_en && pixel_data_in_vld)
                    shift_reg[i] <= shift_reg[i-1];
            end
        end
    end
endgenerate
genvar j;
generate 
    for(j=0;j<9;j=j+1) begin
        if(j<=3) begin
            assign mac_arr[j*9+0] = (v_cnt > (3-j) && h_cnt > 'd3)? shift_reg[8*H+8-(j*H+0)]            : 'd0 ;
            assign mac_arr[j*9+1] = (v_cnt > (3-j) && h_cnt > 'd2)? shift_reg[8*H+8-(j*H+1)]            : 'd0 ;
            assign mac_arr[j*9+2] = (v_cnt > (3-j) && h_cnt > 'd1)? shift_reg[8*H+8-(j*H+2)]            : 'd0 ;
            assign mac_arr[j*9+3] = (v_cnt > (3-j) && h_cnt > 'd0)? shift_reg[8*H+8-(j*H+3)]            : 'd0 ;
            assign mac_arr[j*9+4] = (v_cnt > (3-j))?                shift_reg[8*H+8-(j*H+4)]            : 'd0 ;
            assign mac_arr[j*9+5] = (v_cnt > (3-j) && h_cnt < H-1)? shift_reg[8*H+8-(j*H+5)]            : 'd0 ;
            assign mac_arr[j*9+6] = (v_cnt > (3-j) && h_cnt < H-2)? shift_reg[8*H+8-(j*H+6)]            : 'd0 ;
            assign mac_arr[j*9+7] = (v_cnt > (3-j) && h_cnt < H-3)? shift_reg[8*H+8-(j*H+7)]            : 'd0 ;
            assign mac_arr[j*9+8] = (v_cnt > (3-j) && h_cnt < H-4)? shift_reg[8*H+8-(j*H+8)]            : 'd0 ;
        end
        else if(j==4) begin
            assign mac_arr[j*9+0] = (h_cnt > 'd3)?                  shift_reg[8*H+8-(j*H+0)]            : 'd0 ;
            assign mac_arr[j*9+1] = (h_cnt > 'd2)?                  shift_reg[8*H+8-(j*H+1)]            : 'd0 ;
            assign mac_arr[j*9+2] = (h_cnt > 'd1)?                  shift_reg[8*H+8-(j*H+2)]            : 'd0 ;
            assign mac_arr[j*9+3] = (h_cnt > 'd0)?                  shift_reg[8*H+8-(j*H+3)]            : 'd0 ;
            assign mac_arr[j*9+4] =                                 shift_reg[8*H+8-(j*H+4)]                  ;
            assign mac_arr[j*9+5] = (h_cnt < H-1)?                  shift_reg[8*H+8-(j*H+5)]            : 'd0 ;
            assign mac_arr[j*9+6] = (h_cnt < H-2)?                  shift_reg[8*H+8-(j*H+6)]            : 'd0 ;
            assign mac_arr[j*9+7] = (h_cnt < H-3)?                  shift_reg[8*H+8-(j*H+7)]            : 'd0 ;
            assign mac_arr[j*9+8] = (h_cnt < H-4)?                  shift_reg[8*H+8-(j*H+8)]            : 'd0 ;            
        end
        else begin
            assign mac_arr[j*9+0] = (v_cnt < V+4-j && h_cnt > 'd3)? shift_reg[8*H+8-(j*H+0)]            : 'd0 ;
            assign mac_arr[j*9+1] = (v_cnt < V+4-j && h_cnt > 'd2)? shift_reg[8*H+8-(j*H+1)]            : 'd0 ;
            assign mac_arr[j*9+2] = (v_cnt < V+4-j && h_cnt > 'd1)? shift_reg[8*H+8-(j*H+2)]            : 'd0 ;
            assign mac_arr[j*9+3] = (v_cnt < V+4-j && h_cnt > 'd0)? shift_reg[8*H+8-(j*H+3)]            : 'd0 ;
            assign mac_arr[j*9+4] = (v_cnt < V+4-j)?                shift_reg[8*H+8-(j*H+4)]            : 'd0 ;
            assign mac_arr[j*9+5] = (v_cnt < V+4-j && h_cnt < H-1)? shift_reg[8*H+8-(j*H+5)]            : 'd0 ;
            assign mac_arr[j*9+6] = (v_cnt < V+4-j && h_cnt < H-2)? shift_reg[8*H+8-(j*H+6)]            : 'd0 ;
            assign mac_arr[j*9+7] = (v_cnt < V+4-j && h_cnt < H-3)? shift_reg[8*H+8-(j*H+7)]            : 'd0 ;
            assign mac_arr[j*9+8] = (v_cnt < V+4-j && h_cnt < H-4)? shift_reg[8*H+8-(j*H+8)]            : 'd0 ;
        end 
    end
endgenerate

// TODO -- trans to pipeline to improve freq
assign mac_acc_a = mac_arr[    0] + mac_arr[    2] + mac_arr[    4] + mac_arr[    6] + mac_arr[    8] +
                   mac_arr[2*9+0] + mac_arr[2*9+2] + mac_arr[2*9+4] + mac_arr[2*9+6] + mac_arr[2*9+8] +
                   mac_arr[4*9+0] + mac_arr[4*9+2] + mac_arr[4*9+4] + mac_arr[4*9+6] + mac_arr[4*9+8] +
                   mac_arr[6*9+0] + mac_arr[6*9+2] + mac_arr[6*9+4] + mac_arr[6*9+6] + mac_arr[6*9+8] +
                   mac_arr[8*9+0] + mac_arr[8*9+2] + mac_arr[8*9+4] + mac_arr[8*9+6] + mac_arr[8*9+8] ;

assign mac_acc_b = mac_arr[    1] + mac_arr[    3] + mac_arr[    5] + mac_arr[    7] +
                   mac_arr[2*9+1] + mac_arr[2*9+3] + mac_arr[2*9+5] + mac_arr[2*9+7] +
                   mac_arr[4*9+1] + mac_arr[4*9+3] + mac_arr[4*9+5] + mac_arr[4*9+7] +
                   mac_arr[6*9+1] + mac_arr[6*9+3] + mac_arr[6*9+5] + mac_arr[6*9+7] +
                   mac_arr[8*9+1] + mac_arr[8*9+3] + mac_arr[8*9+5] + mac_arr[8*9+7] ;

assign mac_acc_c = mac_arr[1*9+0] + mac_arr[1*9+2] + mac_arr[1*9+4] + mac_arr[1*9+6] + mac_arr[1*9+8] +
                   mac_arr[3*9+0] + mac_arr[3*9+2] + mac_arr[3*9+4] + mac_arr[3*9+6] + mac_arr[3*9+8] +
                   mac_arr[5*9+0] + mac_arr[5*9+2] + mac_arr[5*9+4] + mac_arr[5*9+6] + mac_arr[5*9+8] +
                   mac_arr[7*9+0] + mac_arr[7*9+2] + mac_arr[7*9+4] + mac_arr[7*9+6] + mac_arr[7*9+8] ;

assign mac_acc_d = mac_arr[1*9+1] + mac_arr[1*9+3] + mac_arr[1*9+5] + mac_arr[1*9+7] +
                   mac_arr[3*9+1] + mac_arr[3*9+3] + mac_arr[3*9+5] + mac_arr[3*9+7] +
                   mac_arr[5*9+1] + mac_arr[5*9+3] + mac_arr[5*9+5] + mac_arr[5*9+7] +
                   mac_arr[7*9+1] + mac_arr[7*9+3] + mac_arr[7*9+5] + mac_arr[7*9+7] ;

always@(*) begin
    avg_g  = 'd0;
    avg_c1 = 'd0;
    avg_c2 = 'd0;
    //case({h_cnt[0],v_cnt[0]})
    case(bayer_index)
        R: begin
            avg_g  = (mac_acc_b + mac_acc_c)/40;
            avg_c1 = mac_acc_a/25;
            avg_c2 = mac_acc_d/16;
        end
        //2'b01: begin
        //    avg_g  = (mac_acc_a + mac_acc_d)/40;
        //    avg_c1 = mac_acc_b/25;
        //    avg_c2 = mac_acc_c/16;
        //end
        //2'b10: begin
        //    avg_g  = (mac_acc_a + mac_acc_d)/40;
        //    avg_c1 = mac_acc_c/25;
        //    avg_c2 = mac_acc_b/16;
        //end
        B: begin
            avg_g  = (mac_acc_b + mac_acc_c)/40;
            avg_c1 = mac_acc_d/16;
            avg_c2 = mac_acc_a/25;
        end
    endcase
end

assign center = mac_arr[40];

assign is_noise = (center > avg_g+thres) && (center > avg_c2+thres) && (avg_c1 > avg_g+thres) && (avg_c1 > avg_c2+thres);

assign bayer_index = {v_cnt[0],h_cnt[0]};

always@(*) begin
    {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,GR,GB,B};
    case(bayer_pattern) 
        2'd0:   {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,GR,GB,B};
        2'd1:   {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {B,GR,GB,R};
        default:{bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,GR,GB,B};
    endcase
end

assign signal_gap = signal_gap_sign?    ((avg_g > avg_c2)?   (avg_g - center) : (avg_c2 - center)) :
                                        ((avg_g > avg_c2)?   (center - avg_g) : (center - avg_c2));

assign signal_gap_sign = ~(center > avg_g && center > avg_c2);
//***********************************
// TODO -- xiaoshu
always@(*) begin    
    damp_factor = 256;
    signal_meter = 'd0;
    case(bayer_arr[bayer_index])
        R : begin 
            damp_factor = (r_gain <= 256)?  256 :   // x256
                          (r_gain > 307)?   77 : 128;
            signal_meter = (77*avg_c1 + 150*avg_g + 29*avg_c2) >> 8;
        end
        B : begin
            damp_factor = (b_gain <= 256)?  256 :
                          (b_gain > 307)?   77 : 128;
            signal_meter = (77*avg_c1 + 150*avg_g + 29*avg_c2) >> 8;
        end
        default: begin
            damp_factor = 256;
            signal_meter = 'd0;
        end
    endcase

end
assign chroma_corr = signal_gap_sign?   ((avg_g > avg_c2)?  avg_g - ((damp_factor*signal_gap) >>8) : avg_c2 - ((damp_factor*signal_gap) >>8)) :
                                        ((avg_g > avg_c2)?  avg_g + ((damp_factor*signal_gap) >>8) : avg_c2 + ((damp_factor*signal_gap) >>8)) ;

always@(*) begin
    fade1 = 0;
    if(signal_meter <= 30) 
        fade1 = 256;
    else if(signal_meter > 30 && signal_meter <= 50)
        fade1 = 230;
    else if(signal_meter > 50 && signal_meter <= 70)
        fade1 = 205;
    else if(signal_meter > 70 && signal_meter <= 100)
        fade1 = 180;
    else if(signal_meter > 100 && signal_meter <= 150)
        fade1 = 154;
    else if(signal_meter > 150 && signal_meter <= 200)
        fade1 = 77;
    else if(signal_meter > 200 && signal_meter <= 250)
        fade1 = 26;
    else
        fade1 = 0;
end
always@(*) begin
    fade2 = 0;
    if(avg_c1 <= 30) 
        fade2 = 256;    // x256
    else if(avg_c1 > 30 && avg_c1 <= 50)
        fade2 = 230;
    else if(avg_c1 > 50 && avg_c1 <= 70)
        fade2 = 205;
    else if(avg_c1 > 70 && avg_c1 <= 100)
        fade2 = 154;
    else if(avg_c1 > 100 && avg_c1 <= 150)
        fade2 = 128;
    else if(avg_c1 > 150 && avg_c1 <= 200)
        fade2 = 77;
    else if(avg_c1 > 200)
        fade2 = 0;
    else
        fade2 = 0;
end

assign fadetot = fade1 * fade2;
assign center_out = (((1<<16)-fadetot)*center + fadetot * chroma_corr)>>16;

assign pixel_data_out_pre = (bayer_arr[bayer_index]==R || bayer_arr[bayer_index]==B) && is_noise?   center_out : center;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(init && v_cnt==4 && h_cnt==4)
        h_cnt <= 'd0;
    else if(cnf_en && pixel_data_in_vld)
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(init && v_cnt==4 && h_cnt==4)
        v_cnt <= 'd0;
    else if(cnf_en && pixel_data_in_vld && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
end
   
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)   
        init <= 1'b1;
    else if(init && v_cnt==4 && h_cnt==4)
        init <= 1'b0;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out_vld <= 1'b0;
    else if(cnf_en)
        pixel_data_out_vld <= ~init & pixel_data_in_vld;
    else 
        pixel_data_out_vld <= pixel_data_in_vld;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out <= 'd0;
    else if(cnf_en)
        pixel_data_out <= (pixel_data_out_pre > cnf_clip)?    cnf_clip : pixel_data_out_pre;
    else 
        pixel_data_out <= pixel_data_in;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        cnf_done <= 1'b0;
    else if(cnf_en && v_cnt==V-1 && h_cnt==H-1 && ~init && ~cnf_done)
        cnf_done <= 1'b1;
    else if(cnf_done)
        cnf_done <= 1'b0;
end

`ifdef SIM
integer file_cnf;
integer file_cnf_p;
initial begin
    file_cnf = $fopen("./cnf_result.csv","w+");  // 初始化文件
    file_cnf_p = $fopen("./cnf_result_p.csv","w+");  // 初始化文件
end
integer x;
integer y;
always @(negedge clk) begin
    if (pixel_data_out_vld) begin
        for(x=0;x<9;x=x+1) begin
            for(y=0;y<9;y=y+1) begin
                $fwrite(file_cnf_p,"%d",mac_arr[x*9+y]);
            end
            $fwrite(file_cnf_p,"\n");
        end
    $fwrite(file_cnf_p,"(%d,%d,%d,%d)sgap=%d,fac=%d,cor=%d,sigme=%d,fad1=%d,fad2=%d\n",mac_acc_a,mac_acc_b,mac_acc_c,mac_acc_d,signal_gap,damp_factor,chroma_corr,signal_meter,fade1,fade2);
    $fwrite(file_cnf_p,"\n");
    $fwrite(file_cnf,"%d\n",pixel_data_out);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif

endmodule
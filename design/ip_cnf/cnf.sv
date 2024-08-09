module cnf#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                   clk                   ,
    input                   rstn                  ,
    input                   aaf_en                ,
    input        [DW-1:0]   thres                 ,
    input        [2:0]      bayer_pattern         ,  
    input        [DW-1:0]   pixel_data_in         ,
    input                   pixel_data_in_vld     ,
    output logic [DW-1:0]   pixel_data_out        ,
    output logic            pixel_data_out_vld    ,
    output logic            aaf_done        
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

parameter B = 2'd0;
parameter G = 2'd1;
parameter R = 2'd2;
logic [1:0] bayer_arr[0:3];

//************************************
// xiao shu --> Nbit --> TODO
logic [DW-1:0] r_gain;
logic [DW-1:0] gr_gain;
logic [DW-1:0] gb_gain;
logic [DW-1:0] b_gain;

logic [DW-1:0] signal_gap;
logic [DW-1:0] damp_factor;
logic [DW-1:0] chroma_corr;
logic [DW-1:0] signal_meter;
logic [DW-1:0] fade1;
logic [DW-1:0] fade2;
logic [DW-1:0] fadetot;
logic [DW-1:0] center_out;

// ********************************
logic [DW-1:0] pixel_data_out_tmp;
logic [HW-1:0] h_cnt;
logic [VW-1:0] v_cnt;
logic flag;

genvar i;
generate 
    for(i=0;i<8*H+8;i=i+1) begin: SFT_REG
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
genvar j;
generate 
    for(j=0;j<9;j=j+1) begin
        if(j<=3) begin
            assign mac_arr[j*9+0] = (v_cnt > (3-j) && h_cnt > 'd3)? shift_reg[j*9+0]            : 'd0 ;
            assign mac_arr[j*9+1] = (v_cnt > (3-j) && h_cnt > 'd2)? shift_reg[j*9+1]            : 'd0 ;
            assign mac_arr[j*9+2] = (v_cnt > (3-j) && h_cnt > 'd1)? shift_reg[j*9+2]            : 'd0 ;
            assign mac_arr[j*9+3] = (v_cnt > (3-j) && h_cnt > 'd0)? shift_reg[j*9+3]            : 'd0 ;
            assign mac_arr[j*9+4] = (v_cnt > (3-j))?                shift_reg[j*9+4]            : 'd0 ;
            assign mac_arr[j*9+5] = (v_cnt > (3-j) && h_cnt < H-4)? shift_reg[j*9+5]            : 'd0 ;
            assign mac_arr[j*9+6] = (v_cnt > (3-j) && h_cnt < H-3)? shift_reg[j*9+6]            : 'd0 ;
            assign mac_arr[j*9+7] = (v_cnt > (3-j) && h_cnt < H-2)? shift_reg[j*9+7]            : 'd0 ;
            assign mac_arr[j*9+8] = (v_cnt > (3-j) && h_cnt < H-1)? shift_reg[j*9+8]            : 'd0 ;
        end
        else if(j==4) begin
            assign mac_arr[j*9+0] = (h_cnt > 'd3)?                  shift_reg[j*9+0]            : 'd0 ;
            assign mac_arr[j*9+1] = (h_cnt > 'd2)?                  shift_reg[j*9+1]            : 'd0 ;
            assign mac_arr[j*9+2] = (h_cnt > 'd1)?                  shift_reg[j*9+2]            : 'd0 ;
            assign mac_arr[j*9+3] = (h_cnt > 'd0)?                  shift_reg[j*9+3]            : 'd0 ;
            assign mac_arr[j*9+4] =                                 shift_reg[j*9+4]                  ;
            assign mac_arr[j*9+5] = (h_cnt < H-4)?                  shift_reg[j*9+5]            : 'd0 ;
            assign mac_arr[j*9+6] = (h_cnt < H-3)?                  shift_reg[j*9+6]            : 'd0 ;
            assign mac_arr[j*9+7] = (h_cnt < H-2)?                  shift_reg[j*9+7]            : 'd0 ;
            assign mac_arr[j*9+8] = (h_cnt < H-1)?                  shift_reg[j*9+8]            : 'd0 ;            
        end
        else begin
            assign mac_arr[j*9+0] = (v_cnt < V-8+j && h_cnt > 'd3)? shift_reg[j*9+0]            : 'd0 ;
            assign mac_arr[j*9+1] = (v_cnt < V-8+j && h_cnt > 'd2)? shift_reg[j*9+1]            : 'd0 ;
            assign mac_arr[j*9+2] = (v_cnt < V-8+j && h_cnt > 'd1)? shift_reg[j*9+2]            : 'd0 ;
            assign mac_arr[j*9+3] = (v_cnt < V-8+j && h_cnt > 'd0)? shift_reg[j*9+3]            : 'd0 ;
            assign mac_arr[j*9+4] = (v_cnt < V-8+j)?                shift_reg[j*9+4]            : 'd0 ;
            assign mac_arr[j*9+5] = (v_cnt < V-8+j && h_cnt < H-4)? shift_reg[j*9+5]            : 'd0 ;
            assign mac_arr[j*9+6] = (v_cnt < V-8+j && h_cnt < H-3)? shift_reg[j*9+6]            : 'd0 ;
            assign mac_arr[j*9+7] = (v_cnt < V-8+j && h_cnt < H-2)? shift_reg[j*9+7]            : 'd0 ;
            assign mac_arr[j*9+8] = (v_cnt < V-8+j && h_cnt < H-1)? shift_reg[j*9+8]            : 'd0 ;
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

assign mac_acc_c = mac_arr[1*9+0] + mac_arr[1*9+2] + mac_arr[1*9+4] + mac_arr[1*9+6] +
                   mac_arr[3*9+0] + mac_arr[3*9+2] + mac_arr[3*9+4] + mac_arr[3*9+6] +
                   mac_arr[5*9+0] + mac_arr[5*9+2] + mac_arr[5*9+4] + mac_arr[5*9+6] +
                   mac_arr[7*9+0] + mac_arr[7*9+2] + mac_arr[7*9+4] + mac_arr[7*9+6] ;

assign mac_acc_d = mac_arr[1*9+1] + mac_arr[1*9+3] + mac_arr[1*9+5] + mac_arr[1*9+7] +
                   mac_arr[3*9+1] + mac_arr[3*9+3] + mac_arr[3*9+5] + mac_arr[3*9+7] +
                   mac_arr[5*9+1] + mac_arr[5*9+3] + mac_arr[5*9+5] + mac_arr[5*9+7] +
                   mac_arr[7*9+1] + mac_arr[7*9+3] + mac_arr[7*9+5] + mac_arr[7*9+7] ;

always@(*) begin
    avg_g  = 'd0;
    avg_c1 = 'd0;
    avg_c2 = 'd0;
    case({h_cnt[0],v_cnt[0]})
    //case(bayer_index)
        2'b00: begin
            avg_g  = (mac_acc_b + mac_acc_c)/40;
            avg_c1 = mac_acc_a/25;
            avg_c2 = mac_acc_d/16;
        end
        2'b01: begin
            avg_g  = (mac_acc_a + mac_acc_d)/40;
            avg_c1 = mac_acc_b/25;
            avg_c2 = mac_acc_c/16;
        end
        2'b10: begin
            avg_g  = (mac_acc_a + mac_acc_d)/40;
            avg_c1 = mac_acc_c/25;
            avg_c2 = mac_acc_b/16;
        end
        2'b11: begin
            avg_g  = (mac_acc_b + mac_acc_c)/40;
            avg_c1 = mac_acc_d/25;
            avg_c2 = mac_acc_a/16;
        end
    endcase
end

assign center = mac_arr[40];

assign is_noise = (center > avg_g+thres) && (center > avg_c2+thres) && (avg_c1 > avg_g+thres) && (avg_c1 > avg_c2+thres);

assign bayer_index = {v_cnt[0],h_cnt[0]};

always@(*) begin
    {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,G,G,B};
    case(bayer_pattern) 
        2'd0:   {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,G,G,B};
        2'd1:   {bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {B,G,G,R};
        default:{bayer_arr[0],bayer_arr[1],bayer_arr[2],bayer_arr[3]} = {R,G,G,B};
    endcase
end

assign signal_gap = (avg_g > avg_c2)?   (center - avg_g) : (center - avg_c2);

//***********************************
// TODO -- xiaoshu
always@(*) begin    
    damp_factor = 1.0;
    signal_meter = 'd0;
    case(bayer_arr[bayer_index])
        R : begin 
            damp_factor = (r_gain <= 1.0)?  1.0 :
                          (r_gain > 1.2)?   0.3 : 0.5;
            signal_meter = 0.299*avg_c1 + 0.587*avg_g + 0.114*avg_c2;
        end
        B : begin
            damp_factor = (b_gain <= 1.0)?  1.0 :
                          (b_gain > 1.2)?   0.3 : 0.5;
            signal_meter = 0.299*avg_c2 + 0.587*avg_g + 0.114*avg_c1;
        end
        default: begin
            damp_factor = 1.0;
            signal_meter = 'd0;
        end
    endcase

end
assign chroma_corr = (avg_g > avg_c2)?  avg_g + damp_factor*signal_gap : avg_c2 + damp_factor*signal_gap;

always@(*) begin
    fade1 = 0;
    if(signal_meter <= 30) 
        fade1 = 1.0;
    else if(signal_meter > 30 && signal_meter <= 50)
        fade1 = 0.9;
    else if(signal_meter > 50 && signal_meter <= 70)
        fade1 = 0.9;
    else if(signal_meter > 70 && signal_meter <= 100)
        fade1 = 0.9;
    else if(signal_meter > 100 && signal_meter <= 150)
        fade1 = 0.9;
    else if(signal_meter > 150 && signal_meter <= 200)
        fade1 = 0.9;
    else if(signal_meter > 200 && signal_meter <= 250)
        fade1 = 0.9;
    else
        fade1 = 0;
end
always@(*) begin
    fade2 = 0;
    if(avg_c1 <= 30) 
        fade2 = 1.0;
    else if(avg_c1 > 30 && avg_c1 <= 50)
        fade2 = 0.9;
    else if(avg_c1 > 50 && avg_c1 <= 70)
        fade2 = 0.8;
    else if(avg_c1 > 70 && avg_c1 <= 100)
        fade2 = 0.6;
    else if(avg_c1 > 100 && avg_c1 <= 150)
        fade2 = 0.5;
    else if(avg_c1 > 150 && avg_c1 <= 200)
        fade2 = 0.3;
    else if(avg_c1 > 200)
        fade2 = 0;
    else
        fade2 = 0;
end

assign fadetot = fade1 * fade2;
assign center_out = (1-fadetot)*center + fadetot * chroma_corr;

assign pixel_data_out_tmp = (bayer_arr[bayer_index]==R || bayer_arr[bayer_index]==B) && is_noise?   center_out : center;
//assign mac_arr[1] = (v_cnt > 'd1)?                shift_reg[2]            : 'd0 ;
//assign mac_arr[2] = (v_cnt > 'd1 && h_cnt < H-2)? shift_reg[4]            : 'd0 ;
//assign mac_arr[3] = (h_cnt > 'd1)?                shift_reg[2*H]          : 'd0 ;
//assign mac_arr[4] =                               shift_reg[2*H+2] << 3         ;
//assign mac_arr[5] = (h_cnt < H-2)?                shift_reg[2*H+4]        : 'd0 ;
//assign mac_arr[6] = (v_cnt < V-2 && h_cnt > 'd1)? shift_reg[4*H]          : 'd0 ;
//assign mac_arr[7] = (v_cnt < V-2)?                shift_reg[4*H+2]        : 'd0 ;
//assign mac_arr[8] = (v_cnt < V-2 && h_cnt < H-2)? shift_reg[4*H+4]        : 'd0 ;

//assign pixel_data_out_tmp = (mac_arr[0]+mac_arr[1]+mac_arr[2]+mac_arr[3]+(mac_arr[4] << 3)+mac_arr[5]+mac_arr[6]+mac_arr[7]+mac_arr[8]) >> 4 ;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        h_cnt <= 'd0;
    else if(aaf_en && (pixel_data_in_vld || flag))
        h_cnt <= (h_cnt==H-1)?  'd0:(h_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        v_cnt <= 'd0;
    else if(aaf_en && (pixel_data_in_vld || flag) && h_cnt==H-1)
        v_cnt <= (v_cnt==V-1)?  'd0:(v_cnt+1'b1);
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        flag <= 1'b0;
    else if(aaf_en && v_cnt==V-1 && h_cnt==H-1)
        flag <= 1'b1;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out_vld <= 1'b0;
    else if(~flag) begin
        if(v_cnt == 'd2 && h_cnt >= 'd2 && pixel_data_in_vld)  
            pixel_data_out_vld <= 1'b1;
        else if(v_cnt > 'd2 && pixel_data_in_vld)
            pixel_data_out_vld <= 1'b1;
        else 
            pixel_data_out_vld <= 1'b0;
    end
    else if(flag) begin
        if(v_cnt == 'd2 && h_cnt > 'd2)
            pixel_data_out_vld <= 1'b0;
        else 
            pixel_data_out_vld <= 1'b1;
    end
end

assign pixel_data_out = pixel_data_out_tmp;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        aaf_done <= 1'b0;
    else if(aaf_en && v_cnt==V-1 && h_cnt==H-1 && flag && ~aaf_done)
        aaf_done <= 1'b1;
    else if(aaf_done)
        aaf_done <= 1'b0;
end

endmodule
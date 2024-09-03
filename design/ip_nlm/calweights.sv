// To match speed, one cycle output one  calweight
module calweights #(
    parameter DW = 16   ,
    parameter DS = 4    ,   // search window size-1 /2
    parameter KS = 1        // neighbour window size-1 /2

)(
    input                   clk                     ,
    input                   rstn                    ,
    input        [DW-1:0]   array [0:DS*2] [0:DS*2] ,
    input                   data_vld                ,
    output logic [DW-1:0]   wmax                    ,
    output logic [DW+DW-1:0]wsum                    ,
    output logic [DW+DW-1:0]average                 ,
    output logic [DW-1:0]   center                  ,
    output logic            calout_vld
);

parameter SIZE_S = 2*DS+1;
parameter SIZE_N = 2*KS+1;

logic [DW+SIZE_N-1:0] sigma [0:SIZE_N-1] [0:SIZE_N-1];
logic [DW-1:0] weight [0:SIZE_N-1] [0:SIZE_N-1];
logic [DW-1:0] wght_buff [0:SIZE_N-1] [0:SIZE_N-1];
logic [DW-1:0] array_buff [0:SIZE_S-1] [0:SIZE_S-1];
logic data_vld_ff1;
logic data_vld_ff2;

logic [DW-1:0] LUT_EXP [0:1039]; //TODO
initial begin
    $readmemh("/ext3/home/wangyufei/Projects/6-ISP/design/ip_nlm/lut_exp_bin.txt",LUT_EXP);
end

genvar i;
genvar j;
genvar kx;
genvar ky;

generate
    for(i=0; i < SIZE_S-SIZE_N; i=i+1) begin
        for(j=0; j < SIZE_S-SIZE_N; j=j+1) begin : BETWEEN_L
            logic [DW-1:0] L1 [0:SIZE_N-1] [0:SIZE_N-1];
            logic [DW-1:0] delta2 [0:SIZE_N-1] [0:SIZE_N-1];
            for(kx=0;kx<SIZE_N;kx=kx+1) begin : INSIDE_L
                for(ky=0;ky<SIZE_N;ky=ky+1) begin
                    assign L1[kx][ky] = array [i+kx][j+ky];
                    assign delta2[kx][ky] = (L1[kx][ky] - L1[KS][KS])*(L1[kx][ky] - L1[KS][KS]);
                end
            end
            assign sigma[i][j] = (delta2[0][0] + delta2[0][1] + delta2[0][2] + 
                                  delta2[1][0] + delta2[1][1] + delta2[1][2] + 
                                  delta2[2][0] + delta2[2][1] + delta2[2][2]) / (SIZE_N*SIZE_N) ;   // TODO
            if(i==DS-KS && j==DS-KS) begin
                assign weight[i][j] = 'd0;
            end
            else begin
                assign weight[i][j] = (sigma[i][j] > 1039)?   'd0 : LUT_EXP[sigma[i][j]];
            end
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    wght_buff[i][j] <= 'd0;
                else if(data_vld_ff1)
                    wght_buff[i][j] <= weight[i][j];
            end
        end
    end
endgenerate

generate
    for(i=0; i < SIZE_S-SIZE_N; i=i+1) begin
        for(j=0; j < SIZE_S-SIZE_N; j=j+1) begin 
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    array_buff[i][j] <= 'd0;
                else if(data_vld)
                    array_buff[i][j] <= array[i][j];
            end
            logic [DW-1:0] L1_buff [0:SIZE_N-1] [0:SIZE_N-1];
            for(kx=0;kx<SIZE_N;kx=kx+1) begin : INSIDE_L
                for(ky=0;ky<SIZE_N;ky=ky+1) begin
                    assign L1_buff[kx][ky] = array_buff [i+kx][j+ky];
                end
            end
        end
    end
endgenerate

// TODO
genvar k;
logic [DW-1:0] wmax_tmp [0:4][0:1];
logic [DW-1:0] wmax_mux [0:4];
logic [DW-1:0] wmax_012;
logic [DW+DW-1:0] wsum_pre;
logic [DW+DW+DW-1:0] average_pre;
assign wsum_pre =  wght_buff[0][0] + wght_buff[0][1] + wght_buff[0][2] + wght_buff[0][3] + wght_buff[0][4] +
                   wght_buff[1][0] + wght_buff[1][1] + wght_buff[1][2] + wght_buff[1][3] + wght_buff[1][4] +
                   wght_buff[2][0] + wght_buff[2][1]                   + wght_buff[2][3] + wght_buff[2][4] +
                   wght_buff[3][0] + wght_buff[3][1] + wght_buff[3][2] + wght_buff[3][3] + wght_buff[3][4] +
                   wght_buff[4][0] + wght_buff[4][1] + wght_buff[4][2] + wght_buff[4][3] + wght_buff[4][4] ;

assign average_pre =  wght_buff[0][0] * array_buff[2][2] + wght_buff[0][1] * array_buff[2][3] + wght_buff[0][2] * array_buff[2][4] + wght_buff[0][3] * array_buff[2][5] + wght_buff[0][4] * array_buff[2][6] +
                      wght_buff[1][0] * array_buff[3][2] + wght_buff[1][1] * array_buff[3][3] + wght_buff[1][2] * array_buff[3][4] + wght_buff[1][3] * array_buff[3][5] + wght_buff[1][4] * array_buff[3][6] +
                      wght_buff[2][0] * array_buff[4][2] + wght_buff[2][1] * array_buff[4][3] +                                    + wght_buff[2][3] * array_buff[4][5] + wght_buff[2][4] * array_buff[4][6] +
                      wght_buff[3][0] * array_buff[5][2] + wght_buff[3][1] * array_buff[5][3] + wght_buff[3][2] * array_buff[5][4] + wght_buff[3][3] * array_buff[5][5] + wght_buff[3][4] * array_buff[5][6] +
                      wght_buff[4][0] * array_buff[6][2] + wght_buff[4][1] * array_buff[6][3] + wght_buff[4][2] * array_buff[6][4] + wght_buff[4][3] * array_buff[6][5] + wght_buff[4][4] * array_buff[6][6] ;

generate 
    for(k=0;k<DS;k=k+1) begin
        assign wmax_tmp [k][0] = (wght_buff[k][0] > wght_buff[k][1])?   ((wght_buff[k][0] > wght_buff[k][2])?    wght_buff[k][0] : wght_buff[k][2]) :
                                                                        ((wght_buff[k][1] > wght_buff[k][2])?    wght_buff[k][1] : wght_buff[k][2]) ;
        assign wmax_tmp [k][1] = (wght_buff[k][3] > wght_buff[k][4])?   wght_buff[k][3] : wght_buff[k][4];
                                                                        
        assign wmax_mux [k] = (wmax_tmp[k][0] >  wmax_tmp[k][1])?    wmax_tmp[k][0] : wmax_tmp[k][1];
    end
endgenerate

assign wmax_012 = (wmax_mux[0] > wmax_mux[1])?     ((wmax_mux[0] > wmax_mux[2])?    wmax_mux[0] : wmax_mux[2]) :
                  ((wmax_mux[1] > wmax_mux[2])?    wmax_mux[1] : wmax_mux[2]) ;

assign wmax_pre = (wmax_012 > wmax_mux[3])?  ((wmax_012 > wmax_mux[4])?       wmax_012 : wmax_mux[4]) :
                                             ((wmax_mux[3] > wmax_mux[4])?    wmax_mux[3]  : wmax_mux[4]) ;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        wsum <= 'd0;
    else if(data_vld_ff2)
        wsum <= wsum_pre;
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        wmax <= 'd0;
    else if(data_vld_ff2)
        wmax <= wmax_pre;
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        average <= 'd0;
    else if(data_vld_ff2)
        average <= average_pre;
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        center <= 'd0;
    else if(data_vld_ff2)
        center <= array_buff[DS-KS][DS-KS];
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        {calout_vld,data_vld_ff2,data_vld_ff1} <= 3'd0;
    else
        {calout_vld,data_vld_ff2,data_vld_ff1} <= {data_vld_ff2,data_vld_ff1,data_vld};
end
endmodule
module cordic #(
    parameter DW = 32       ,
    parameter COEF_W = 16
)(
    input                   clk           , // can be gated
    input                   rstn          ,
    input        [DW-1:0]   theta         ,
    input                   theta_in_vld  ,
    output logic [DW-1:0]   cos_val       ,
    output logic [DW-1:0]   sin_val       ,
    output logic            cordic_out_vld
);
parameter UNIT = 2<<COEF_W;
parameter [DW-1:0] ROT0 = 45 * UNIT;           //45度*2^16
parameter [DW-1:0] ROT1 = 26.565 * UNIT ;      //26.5651度*2^16
parameter [DW-1:0] ROT2 = 14.036 * UNIT ;      //14.0362度*2^16
parameter [DW-1:0] ROT3 = 7.1250 * UNIT ;      //7.1250度*2^16
parameter [DW-1:0] ROT4 = 3.5763 * UNIT ;      //3.5763度*2^16
parameter [DW-1:0] ROT5 = 1.7899 * UNIT ;      //1.7899度*2^16
parameter [DW-1:0] ROT6 = 0.8952 * UNIT ;      //0.8952度*2^16
parameter [DW-1:0] ROT7 = 0.4476 * UNIT ;      //0.4476度*2^16
parameter [DW-1:0] ROT8 = 0.2238 * UNIT ;      //0.2238度*2^16
parameter [DW-1:0] ROT9 = 0.1119 * UNIT ;      //0.1119度*2^16
parameter [DW-1:0] ROT10= 0.0560 * UNIT ;      //0.0560度*2^16
parameter [DW-1:0] ROT11= 0.0280 * UNIT ;      //0.0280度*2^16
parameter [DW-1:0] ROT12= 0.0140 * UNIT ;      //0.0140度*2^16
parameter [DW-1:0] ROT13= 0.0070 * UNIT ;      //0.0070度*2^16
parameter [DW-1:0] ROT14= 0.0035 * UNIT ;      //0.0035度*2^16
parameter [DW-1:0] ROT15= 0.0018 * UNIT ;      //0.0018度*2^16
parameter [DW-1:0] K = 0.607253 * UNIT  ;
parameter [DW-1:0] ANG_180 = 180 * UNIT ;      //180度*2^16
parameter [DW-1:0] ANG_360 = 360 * UNIT ;      //360度*2^16

logic signed [DW-1:0] x_pos [0:16-1];
logic signed [DW-1:0] y_pos [0:16-1];
logic signed [DW-1:0] z_pos [0:16-1];
logic signed [DW-1:0] rot [0:16-1];
logic signed [1:0] dir [0:16-1];
logic [16-1:0] theta_vld;
logic signed [DW-1:0] theta_q1;
logic [1:0] quadrant;

assign quadrant = theta[DW-1:DW-2];
assign theta_q1 = (quadrant==2'd0)?   theta : 
                  (quadrant==2'd1)?   (ANG_180-theta) :
                  (quadrant==2'd2)?   (theta-ANG_180) : (ANG_360-theta);

genvar i;
generate 
    for(i=0;i<16;i=i+1) begin: ITERATION
        if(i==0) begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    z_pos[i] <= 'd0;
                else if(theta_in_vld)
                    z_pos[i] <= theta_q1;
            end
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    x_pos[i] <= 'd0;
                else if(theta_in_vld)
                    x_pos[i] <= K;
            end
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    y_pos[i] <= 'd0;
                else if(theta_in_vld)
                    y_pos[i] <= 'd0;
            end
            assign dir[i] = z_pos[i][DW-1];
        end
        else begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    x_pos[i] <= 'd0;
                else
                    x_pos[i] <= dir[i-1][1]?    x_pos[i-1]+(y_pos[i-1]>>i) : x_pos[i-1]-(y_pos[i-1]>>i);
            end
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    y_pos[i] <= 'd0;
                else
                    y_pos[i] <= dir[i-1][1]?    y_pos[i-1]-(x_pos[i-1]>>i) : y_pos[i-1]+(x_pos[i-1]>>i);
            end
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    z_pos[i] <= 'd0;
                else
                    z_pos[i] <= dir[i-1][1]?    z_pos[i-1]+rot[i-1] : z_pos[i-1]-rot[i-1];
            end
            assign dir[i] = z_pos[i][DW-1];
        end
    end
endgenerate

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        cos_val <= 'd0;
    else
        cos_val <= (^quadrant)?  -x_pos[15] : x_pos[15]; 
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        sin_val <= 'd0;
    else
        sin_val <= quadrant[1]?  -y_pos[15] : y_pos[15]; 
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        {cordic_out_vld,theta_vld} <= 'd0;
    else
        {cordic_out_vld,theta_vld} <= {theta_vld[15:0],theta_in_vld}; 
end

assign rot[0]  =  ROT0  ;
assign rot[1]  =  ROT1  ;
assign rot[2]  =  ROT2  ;
assign rot[3]  =  ROT3  ;
assign rot[4]  =  ROT4  ;
assign rot[5]  =  ROT5  ;
assign rot[6]  =  ROT6  ;
assign rot[7]  =  ROT7  ;
assign rot[8]  =  ROT8  ;
assign rot[9]  =  ROT9  ;
assign rot[10] =  ROT10 ;
assign rot[11] =  ROT11 ;
assign rot[12] =  ROT12 ;
assign rot[13] =  ROT13 ;
assign rot[14] =  ROT14 ;
assign rot[15] =  ROT15 ;

endmodule
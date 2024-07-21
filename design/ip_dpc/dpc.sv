module dpc#(
    parameter THRES = 30        ,
    parameter DPC_MODE = 0      , // 0: mean  1: gradient
    parameter CLIP = 100        ,
    parameter H = 720  
)(
    input               clk             ,
    input               rstn            ,
    input               dpc_en          ,
    input        [23:0] pixel_data_in   ,
    output logic [23:0] pixel_data_out
);
logic [23:0] shift_reg [0:4*H+4-1];
logic [7:0] shift_r [0:4*H+4-1];
logic [7:0] shift_g [0:4*H+4-1];
logic [7:0] shift_b [0:4*H+4-1];
logic cancel_flag_r;
logic cancel_flag_g;
logic cancel_flag_b;
logic [23:0] pixel_data_dpc;
logic [7:0] dpc_r;
logic [7:0] dpc_g;
logic [7:0] dpc_b;


genvar i;
generate
    for(i=0;i<4*H+4;i=i+1) begin: SFT_ARRAY
        if(i=0) begin
            always_ff @( posedge clk or negedge rstn ) begin
                if(~rstn)
                shift_reg[i] <= 'd0;
            else if(dpc_en)
                shift_reg[i] <= pixel_data_in;
            end
        end
        else if(i=2*H+2) begin  // replace dead pixel
            always_ff @( posedge clk or negedge rstn ) begin
                if(~rstn)
                shift_reg[i] <= 'd0;
            else if(dpc_en)
                shift_reg[i] <= (pixel_data_dpc > CLIP)?    CLIP : pixel_data_dpc;  // clip
            end
        end
        else begin
            always_ff @( posedge clk or negedge rstn ) begin
                if(~rstn)
                shift_reg[i] <= 'd0;
            else if(dpc_en)
                shift_reg[i] <= shift_reg[i-1];
            end
        end
        assign shift_r[i] = shift_reg[23:16][i];
        assign shift_g[i] = shift_reg[15:8][i];
        assign shift_b[i] = shift_reg[7:0][i];
    end
endgenerate

assign pixel_data_out = shift_reg[4*H+3];

assign cancel_flag_r = dpc_en?  (abs(shift_r[0]-shift_r[2*H+1]    ) > THRES && abs(shift_r[2]-shift_r[2*H+1]    ) > THRES && abs(shift_r[4]-shift_r[2*H+1]) > THRES &&
                                 abs(shift_r[2*H-1]-shift_r[2*H+1]) > THRES && abs(shift_r[2*H+3]-shift_r[2*H+1]) > THRES &&
                                 abs(shift_r[4*H-1]-shift_r[2*H+1]) > THRES && abs(shift_r[4*H+1]-shift_r[2*H+1]) > THRES && abs(shift_r[4*H+3]-shift_r[2*H+1]) > THRES) : 0;

assign cancel_flag_g = dpc_en?  (abs(shift_g[0]-shift_g[2*H+1]    ) > abs(THRES && shift_g[2]-shift_g[2*H+1]    ) > THRES && abs(shift_g[4]-shift_g[2*H+1]) > THRES &&
                                 abs(shift_g[2*H-1]-shift_g[2*H+1]) > abs(THRES && shift_g[2*H+3]-shift_g[2*H+1]) > THRES &&
                                 abs(shift_g[4*H-1]-shift_g[2*H+1]) > abs(THRES && shift_g[4*H+1]-shift_g[2*H+1]) > THRES && abs(shift_g[4*H+3]-shift_g[2*H+1]) > THRES) : 0;

assign cancel_flag_b = dpc_en?  (abs(shift_b[0]-shift_b[2*H+1]    ) > abs(THRES && shift_b[2]-shift_b[2*H+1]    ) > THRES && abs(shift_b[4]-shift_b[2*H+1]) > THRES &&
                                 abs(shift_b[2*H-1]-shift_b[2*H+1]) > abs(THRES && shift_b[2*H+3]-shift_b[2*H+1]) > THRES &&
                                 abs(shift_b[4*H-1]-shift_b[2*H+1]) > abs(THRES && shift_b[4*H+1]-shift_b[2*H+1]) > THRES && abs(shift_b[4*H+3]-shift_b[2*H+1]) > THRES) : 0;

assign dpc_r = cancel_flag_r?   ((shift_r[2] + shift_r[2*H-1] + shift_r[2*H+3] + shift_r[4*H+1])<<2) : shift_r[2*H+1];
assign dpc_g = cancel_flag_g?   ((shift_g[2] + shift_g[2*H-1] + shift_g[2*H+3] + shift_g[4*H+1])<<2) : shift_g[2*H+1];
assign dpc_b = cancel_flag_b?   ((shift_b[2] + shift_b[2*H-1] + shift_b[2*H+3] + shift_b[4*H+1])<<2) : shift_b[2*H+1];

assign pixel_data_dpc = {dpc_r,dpc_g,dpc_b};

endmodule
module gac#(
    parameter DW = 16   ,
    parameter H = 1280  ,
    parameter V = 720   ,
    parameter HW = 11   ,
    parameter VW = 10
)(
    input                   clk                   ,
    input                   rstn                  ,
    input                   gac_en                ,
    input                   pixel_data_in_vld     , 
    input        [DW/3-1:0] pixel_data_in_r       ,
    input        [DW/3-1:0] pixel_data_in_g       ,
    input        [DW/3-1:0] pixel_data_in_b       ,
    output logic            pixel_data_out_vld    ,
    output logic [DW/3-1:0] pixel_data_out_r      ,
    output logic [DW/3-1:0] pixel_data_out_g      ,
    output logic [DW/3-1:0] pixel_data_out_b      ,
    output logic            gac_done              ,
    //input                   lut_cen               ,
    input                   lut_din_vld           ,
    input        [DW/3-1:0] lut_din               ,
    output logic [DW/3-1:0] lut_dout    
);
logic [DW/3-1:0] lut_0 [0:255];
logic [DW/3-1:0] lut_1 [0:255];

// gamma is loaded
initial begin
    $readmemh("./gamma_lut_0.txt",lut_0);
    $readmemh("./gamma_lut_1.txt",lut_1); 
end

logic [7:0] cnt;
logic flag;
logic we_0;
logic we_1;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        cnt <= 8'd0;
    else if(gac_en && pixel_data_in_vld)
        cnt <= &cnt?    8'd0 : cnt+1'b1;
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        flag <= 1'b0;
    else if(gac_en && (&cnt))
        flag <= ~flag;
end

assign we_0 = flag?    lut_din_vld : 1'b1;
assign we_1 = flag?    1'b1 : lut_din_vld;

genvar i;
generate 
    for(i=0;i<256;i=i+1) begin
        if(i==255) begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    lut_0[i] <= 'd0;
                else if(we_0)
                    lut_0[i] <= lut_din;
            end
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    lut_1[i] <= 'd0;
                else if(we_1)
                    lut_1[i] <= lut_din;
            end            
        end
        else begin
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    lut_0[i] <= 'd0;
                else if(we_0)
                    lut_0[i] <= lut_0[i+1];
            end
            always_ff@(posedge clk or negedge rstn) begin
                if(~rstn)
                    lut_1[i] <= 'd0;
                else if(we_1)
                    lut_1[i] <= lut_1[i+1];
            end
        end
    end
endgenerate

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn) begin
       pixel_data_out_r <= 'd0; 
       pixel_data_out_g <= 'd0;
       pixel_data_out_b <= 'd0;
    end
    else if(gac_en && pixel_data_in_vld) begin
        pixel_data_out_r <= flag?   lut_1[pixel_data_in_r] : lut_0[pixel_data_in_r]; 
        pixel_data_out_g <= flag?   lut_1[pixel_data_in_g] : lut_0[pixel_data_in_g];
        pixel_data_out_b <= flag?   lut_1[pixel_data_in_b] : lut_0[pixel_data_in_b];
    end
    else if(~gac_en && pixel_data_in_vld) begin
        pixel_data_out_r <= pixel_data_in_r;
        pixel_data_out_g <= pixel_data_in_g;
        pixel_data_out_b <= pixel_data_in_b;
    end
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        pixel_data_out_vld <= 1'b0;
    else
        pixel_data_out_vld <= pixel_data_in_vld;
end

`ifdef SIM
integer file_gac;
initial begin
    file_gac = $fopen("./gac_result.csv","w+");  // 初始化文件
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
    fwrite(file_cnf,"(%d,%d)%d-%d-%d\n",v_cnt,h_cnt,pixel_data_out_r,pixel_data_out_g,pixel_data_out_b);
    //$fwrite(file_cnf,"%d\n",pixel_data_out);
    end
//     else begin
//         $fclose(file);   // 这里一定要写，关闭文件读写
//     end
end
`endif

endmodule
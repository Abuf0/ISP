module crgu(
input           clk_in      ,
input           rstn_in     ,
input           scl_in      ,
input           pixel_icg_en,
output logic    clk_out1    ,
output logic    clk_out2    ,
output logic    clk_i2c     ,
output logic    rstn_out1   ,
output logic    rstn_i2c    
);
logic clk_in_inv;
logic [2:0] cnt_p;
logic [2:0] cnt_n;
logic clk_p;
logic clk_n;
logic clk_out1_alon;
logic clk_out2_alon;
logic pixel_icg_en_sync;

`ifdef FPGA
    assign clk_in_inv = ~clk_in;
`else
    //CLKINV4M dtc_clkinvd4_inst(.A(clk_in),  .Y(clk_in_inv)  );
    assign clk_in_inv = ~clk_in;
`endif

assign clk_i2c = scl_in;

always_ff@(posedge clk_in or negedge rstn_out1) begin
    if(~rstn_out1)
        cnt_p <= 'd0;
    else
        cnt_p <= (cnt_p==3'd4)?  3'd0 : (cnt_p+1'b1);
end

always_ff@(posedge clk_in or negedge rstn_out1) begin
    if(~rstn_out1)
        clk_p <= 1'b0;
    else if(cnt_p[2:1]==2'd0)
        clk_p <= 1'b1;
    else
        clk_p <= 1'b0;
end

always_ff@(posedge clk_in_inv or negedge rstn_out1) begin
    if(~rstn_out1)
        cnt_n <= 'd0;
    else
        cnt_n <= (cnt_n==3'd4)?  3'd0 : (cnt_n+1'b1);
end

always_ff@(posedge clk_in_inv or negedge rstn_out1) begin
    if(~rstn_out1)
        clk_n <= 1'b0;
    else if(cnt_n[2:1]==2'd0)
        clk_n <= 1'b1;
    else
        clk_n <= 1'b0;
end

assign clk_out1_alon = clk_in;
assign clk_out2_alon = clk_p | clk_n;

sync_reset_n rst_pix_n_inst(.clk(clk_in),  .async_rst_n(rstn_in),  .sync_rst_n(rstn_out1));
sync_reset_n rst_i2c_n_inst(.clk(clk_i2c),  .async_rst_n(rstn_in),  .sync_rst_n(rstn_i2c));


genpart_ckgt ckgt_pixel_clk_inst(.clk(clk_out2_alon),  .enable(pixel_icg_en_sync),  .scan_enable(1'b0),  .gclk(clk_out2));
genpart_ckgt ckgt_pixel_clk_5x_inst(.clk(clk_out1_alon),  .enable(pixel_icg_en),  .scan_enable(1'b0),  .gclk(clk_out1));


endmodule
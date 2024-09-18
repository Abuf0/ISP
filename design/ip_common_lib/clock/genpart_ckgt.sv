module genpart_ckgt(
    input    clk             ,
    input    enable          ,
    input    scan_enable     ,
    output   gclk
);
//GCKSLDND4C dtc_ckgate_inst(.CK(clk),  .E(enable),  .SE(scan_enable),  .ECK(gclk) );

logic enable_latch;
always@(*) begin
    if(~clk)
        enable_latch <= enable;
end

assign gclk = clk & enable_latch;

endmodule
`timescale  1ns / 1ps
module hdmi_colorbar_top_tb();
// hdmi_colorbar_top Parameters
parameter PERIOD  = 10;


// hdmi_colorbar_top Inputs
reg   sys_clk                              = 0 ;
reg   sys_rst_n                            = 0 ;

// hdmi_colorbar_top Outputs
wire  tmds_clk_p                           ;
wire  tmds_clk_n                           ;
wire  [2:0]  tmds_data_p                   ;
wire  [2:0]  tmds_data_n                   ;


initial
begin
    forever #(PERIOD/2)  sys_clk=~sys_clk;
end

initial
begin
    #(PERIOD*2) sys_rst_n  =  1;
end

hdmi_colorbar_top  u_hdmi_colorbar_top (
    .sys_clk                 ( sys_clk            ),
    .sys_rst_n               ( sys_rst_n          ),

    .tmds_clk_p              ( tmds_clk_p         ),
    .tmds_clk_n              ( tmds_clk_n         ),
    .tmds_data_p             ( tmds_data_p   ),
    .tmds_data_n             ( tmds_data_n   )
);

initial
begin
    repeat(1000) @(posedge sys_clk);
    $finish(2);
end
endmodule
`timescale  1ns / 1ps
module hdmi_colorbar_top_tb();
// hdmi_colorbar_top Parameters
parameter PERIOD  = 10;


// hdmi_colorbar_top Inputs
logic   sys_clk                              = 0 ;
logic   sys_rst_n                            = 0 ;

logic [15:0] isp_enable = 16'h0;

// hdmi_colorbar_top Outputs
logic  tmds_clk_p                           ;
logic  tmds_clk_n                           ;
logic  [2:0]  tmds_data_p                   ;
logic  [2:0]  tmds_data_n                   ;


initial
begin
    forever #(PERIOD/2)  sys_clk=~sys_clk;
end

hdmi_colorbar_top  u_hdmi_colorbar_top (
    .sys_clk                 ( sys_clk            ),
    .sys_rst_n               ( sys_rst_n          ),
    .isp_enable              ( isp_enable         ),
    .tmds_clk_p              ( tmds_clk_p         ),
    .tmds_clk_n              ( tmds_clk_n         ),
    .tmds_data_p             ( tmds_data_p        ),
    .tmds_data_n             ( tmds_data_n        )
);

initial
begin
    #(PERIOD*2) sys_rst_n  =  1;
    #(PERIOD*2) isp_enable = 16'h0001;
    repeat(1000) @(posedge sys_clk);
    $finish(2);
end
endmodule
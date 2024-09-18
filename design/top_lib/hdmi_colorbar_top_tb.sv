`timescale  1ns / 1ps
module hdmi_colorbar_top_tb();
// hdmi_colorbar_top Parameters
parameter PERIOD  = 10;
parameter I2C_PRD = 50;
parameter DW  = 24  ;
parameter H   = 128 ;
parameter V   = 72  ;
parameter HW  = 11  ;
parameter VW  = 10  ;

// Defines
`define SIM
//`define FPGA

// hdmi_colorbar_top Inputs
logic   sys_clk                              = 0 ;
logic   sys_rst_n                            = 0 ;
logic   scl_in                     =1 ;
logic   sda_in                     =1 ;
logic   sda_out                       ;

// hdmi_colorbar_top Outputs
logic  tmds_clk_p                           ;
logic  tmds_clk_n                           ;
logic  [2:0]  tmds_data_p                   ;
logic  [2:0]  tmds_data_n                   ;


initial
begin
    forever #(PERIOD/2)  sys_clk=~sys_clk;
end

hdmi_colorbar_top #(
    .DW  (DW    ),
    .H   (H     ),
    .V   (V     ),
    .HW  (HW    ),
    .VW  (VW    )    
) u_hdmi_colorbar_top (
    .sys_clk                 ( sys_clk            ),
    .sys_rst_n               ( sys_rst_n          ),
    .scl_in                  ( scl_in             ),
    .sda_in                  ( sda_in             ),
    .sda_out                 ( sda_out            ),
    .tmds_clk_p              ( tmds_clk_p         ),
    .tmds_clk_n              ( tmds_clk_n         ),
    .tmds_data_p             ( tmds_data_p        ),
    .tmds_data_n             ( tmds_data_n        )
);

initial
begin
    #(PERIOD*2) sys_rst_n  =  1;
    repeat(100000) @(posedge sys_clk);
    $finish(2);
end

initial begin
    $fsdbDumpfile("hdmi_colorbar_top_tb.fsdb");
    $fsdbDumpvars(0,u_hdmi_colorbar_top);
    $fsdbDumpMDA();
end

task i2c_start;
    input [5:0] i2cs_id_h;
    scl_in = 1;
    sda_in = 1;
    #(I2C_PRD/4)    sda_in = 0;
    #(I2C_PRD/4)    scl_in = 0;
    #(I2C_PRD/4)    sda_in = i2cs_id_h[5];
    #(I2C_PRD/4)    scl_in = 1;
    #(I2C_PRD/2)    scl_in = 0;
    #(I2C_PRD/4)    sda_in = i2cs_id_h[4];
    #(I2C_PRD/4)    scl_in = 1;
    #(I2C_PRD/2)    scl_in = 0;
    #(I2C_PRD/4)    sda_in = i2cs_id_h[3];
    #(I2C_PRD/4)    scl_in = 1;
    #(I2C_PRD/2)    scl_in = 0;
    #(I2C_PRD/4)    sda_in = i2cs_id_h[2];
    #(I2C_PRD/4)    scl_in = 1;
    #(I2C_PRD/2)    scl_in = 0;
    #(I2C_PRD/4)    sda_in = i2cs_id_h[1];
    #(I2C_PRD/4)    scl_in = 1;
    #(I2C_PRD/2)    scl_in = 0;
    #(I2C_PRD/4)    sda_in = i2cs_id_h[0];
    #(I2C_PRD/4)    scl_in = 1;
endtask

task i2c_stop;
    #(I2C_PRD/4)    scl_in = 0;
    #(I2C_PRD/4)    sda_in = 0;
    #(I2C_PRD/4)    scl_in = 1;
    #(I2C_PRD/4)    sda_in = 1;
endtask

task i2c_read;
    input [15:0] raddr;
    output [15:0] rdata;
    integer i;
    for (i=0; i<16; i=i+1)  begin
        #(I2C_PRD/2)    scl_in = 0;
        #(I2C_PRD/4)    sda_in = raddr[15-i];
        #(I2C_PRD/4)    scl_in = 1;
    end
    

endtask

task i2c_write;
    input [15:0] waddr;
    input [15:0] wdata;
    integer i;
    for (i=0; i<16; i=i+1)  begin
        #(I2C_PRD/2)    scl_in = 0;
        #(I2C_PRD/4)    sda_in = waddr[15-i];
        #(I2C_PRD/4)    scl_in = 1;
    end
    for (i=0; i<16; i=i+1)  begin
        #(I2C_PRD/2)    scl_in = 0;
        #(I2C_PRD/4)    sda_in = wdata[15-i];
        #(I2C_PRD/4)    scl_in = 1;
    end
endtask

endmodule
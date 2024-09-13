// For read & write ISP configure registers
module i2c_slave_top(
    input clk                       ,
    input rstn                      ,
    // I2C PAD //
    input scl_in                    ,
    input sda_in                    ,
    output logic sda_out            ,
    // I2C Slave ID //
    input [5:0] rg_i2cs_id          ,
    input rg_i2cs_id_en             ,
    input i2cs_id0                  ,
    // Interface with regfile //
    input [15:0] reg_rdata          ,
    output logic [15:0] reg_wdata   ,
    output logic reg_wr_en          ,
    output logic reg_rd_en          ,
    // I2C cmd //
    output logic cmd_reset_i2c      
);

endmodule
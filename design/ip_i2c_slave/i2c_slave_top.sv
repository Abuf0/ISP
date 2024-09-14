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
logic scl_inv;
logic sda_clk;
logic sda_clk_inv;
logic rstn_i2c;
logic i2c_restart;
logic [2:0] bcnt;
logic dev_sel;
logic rw_flag;
logic i2c_stop_all;
logic i2c_stop;
logic init_stop;
logic i2c_timeout;
logic rstn_stop;

typedef enum logic [2:0] {IDLE, ADDR, DEVS , AACK, READ, RACK, WRITE, WACK} state_t;
state_t state_c,state_s;
//***************************************************************************************//
//                                    I2C timing                                         //
//                                                                                       //
//        _________      _____      _____      _____      _____      _____________       //  
//  SCL            \____/     \____/     \____/     \____/     \____/                    //  
//        ______      ___________                      ___________       _________       //  
//  SDA         \____/           \____________________/           \_____/                //  
//         ↓    ↓       ↓          ↓          ↓           ↓          ↓   ↓     ↓         //      
//       IDLE  start    1          0          0           1          0  stop  IDLE       //  
//                                                                                       //    
//***************************************************************************************//
assign scl_inv = ~scl_in;
assign sda_clk = sda_in;
assign sda_clk_inv = ~sda_clk;

assign rstn_i2c = ~i2c_stop_all & rstn & ~i2c_timeout;
assign i2c_timeout = 1'b0;

assign i2c_stop_all = i2c_stop | init_stop;

always_ff@(posedge scl_inv or negedge rstn_i2c) begin
    if(~rstn_i2c)
        state_c <= IDLE;
    else 
        state_c <= state_s;
end

always@(*) begin
    state_s = IDLE;
    case(state_c)
        IDLE:
            state_s = (i2c_restart & ~sda_in)?  ADDR : IDLE;
        ADDR:   // slave id
            state_s = (bcnt==3'd6)?   DEVS : ADDR;
        DEVS:
            state_s = dev_sel?  AACK : DEVS;
        AACK:   // slave ack
            state_s = rw_flag?  READ : WRIT;
        READ:
            state_s = (bcnt==3'd7)? RACK : READ;
        RACK:
            state_s = ~sda_in?  READ : RACK;    // need master ACK-0 to next READ
        WRITE:
            state_s = (bcnt==3'd7)? WACK : WRITE;
        WACK:
            state_s = WRITE;    // slave default ACK to next WRITE
        default:
            state_s = IDLE;
    endcase
end

assign rstn_stop = rstn & sda_in & scl_in; 
always_ff@(posedge sda_clk or negedge rstn_stop) begein  // TODO with rstn_stop
    if(~rstn_stop)
        i2c_stop <= 1'b0;
    else if(scl_in)
        i2c_stop <= 1'b1;
end

always_ff@(posedge sda_clk_inv or negedge rstn) begein 
    if(~rstn)
        init_stop <= 1'b1;
    else
        init_stop <= 1'b0;
end


endmodule
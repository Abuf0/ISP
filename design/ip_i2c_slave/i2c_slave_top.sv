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
    output logic [15:0] reg_addr    ,
    output logic [15:0] reg_wdata   ,
    output logic reg_wr_en          ,
    output logic reg_rd_en          ,
    // I2C cmd //
    output logic cmd_reset_i2c      
);

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

logic i2c_restart;  // TODO
logic dev_sel;  // TODO
logic rw_flag;
logic [2:0] bit_cnt;
logic bit_en;
logic [1:0] byte_cnt;
logic [6:0] addr;
logic [7:0] shift_in;  
logic [7:0] shift_out; 
logic [1:0] addr_data_flag;
logic [7:0] wdata;  // MUX by 16biy-reg_wdata
logic [7:0] rdata;  // NUX by 16bit-reg_rdata

// rst_i2c_n <extra>
logic scl_in_inv;
logic i2c_stop;
logic i2c_timeout;
logic sda_clk;
logic sda_clk_inv;
logic rst_stop_n;
logic rst_stop_sda_n;
logic i2c_stop_sda_n;
logic sda_oe;

assign scl_in_inv = ~scl_in;
assign sda_clk = sda_in;
assign sda_clk_inv = ~sda_in;
assign rst_stop_sda_n = scl_in & rstn;
assign rst_stop_n = scl_in & rstn & ~i2c_stop_sda_n;
assign i2c_timeout = 1'b0;  // TODO
assign rst_i2c_n = rstn && ~i2c_timeout && ~i2c_stop;

always_ff@(posedge sda_clk or negedge rst_stop_n) begin
    if(~rst_stop_n)
        i2c_stop <= 1'b0;
    else if(scl_in)
        i2c_stop <= 1'b1;
    else 
        i2c_stop <= 1'b0;
end

always_ff@(posedge sda_clk_inv or negedge rst_stop_sda_n) begin
    if(~rst_stop_sda_n)
        i2c_stop_sda_n <= 1'b0;
    else if(i2c_stop)
        i2c_stop_sda_n <= 1'b1;
end

// FSM
typedef enum logic [2:0] {IDLE, ADDR, CMND, AACK, READ, RACK, WRITE, WACK} state_t;
state_t state_cs, state_ns;
always_ff @(posedge scl_in_inv or negedge rst_i2c_n) begin
    if(~rst_i2c_n)
        state_cs <= IDLE;
    else
        state_cs <= state_ns;
end
always @(*) begin
    if(~rst_i2c_n)
        state_ns = IDLE;
    else begin
        case(state_cs)  
            //IDLE:   state_ns = (~sda_in && i2c_restart)?    ADDR:IDLE;
            IDLE:   state_ns = i2c_restart?    ADDR:IDLE;
            ADDR:   state_ns = (bit_cnt==3'd6)?     CMND:ADDR;
            CMND:   state_ns = dev_sel?  AACK:CMND;
            AACK:   state_ns = rw_flag? READ:WRITE;
            READ:   state_ns = (bit_cnt==3'd7)?     RACK:READ;
            //RACK:   state_ns = (~sda_in)?   READ:RACK;  // master ack   //non-ack:SDA=H
            RACK:   begin
                if(i2c_restart)
                    state_ns = ADDR;
                else if(~sda_in)
                    state_ns = READ;
                else 
                    state_ns = RACK;
            end
            WRITE:  state_ns = (bit_cnt==3'd7)?     WACK:WRITE;
            //WACK:   state_ns = WRITE;   // slave ack
            WACK:   begin
                if(i2c_restart)
                    state_ns = ADDR;
                else 
                    state_ns = WRITE;
            end
            default: state_ns = IDLE;
        endcase
    end
end

// i2c_restart
logic rst_restart_n;
assign rst_restart_n = scl_in & rstn;
always_ff@(posedge sda_clk_inv or negedge rst_restart_n) begin
    if(~rst_restart_n)
        i2c_restart <= 1'b0;
    else if(scl_in)
        i2c_restart <= 1'b1;
    else 
        i2c_restart <= 1'b0;
end

assign dev_sel = rg_i2cs_id_en && (addr=={rg_i2cs_id,i2cs_id0});  // TODO
always_ff @(posedge scl_in or negedge rst_i2c_n) begin // clock edge
    if(~rst_i2c_n) 
        addr <= 7'd0;
    else if(state_cs==ADDR && bit_cnt==3'd6)
        addr <= {shift_in[5:0],sda_in};
end
always_ff @(posedge scl_in or negedge rst_i2c_n) begin // clock edge
    if(~rst_i2c_n) 
        rw_flag <= 1'd0;
    else if(state_cs==CMND && dev_sel)
        rw_flag <= sda_in;
end

assign bit_en = (state_cs==ADDR) || (state_cs==READ) || (state_cs==WRITE);
always_ff@(posedge scl_in_inv or negedge rst_i2c_n) begin
    if(~rst_i2c_n)
        bit_cnt <= 3'd0;
    else if(~bit_en || i2c_restart)
        bit_cnt <= 3'd0;
    else
        bit_cnt <= bit_cnt+1'b1;
end

always_ff@(posedge scl_in_inv or negedge rst_i2c_n) begin
    if(~rst_i2c_n)
        byte_cnt <= 2'd0;
    else if(~bit_en || i2c_restart || (byte_cnt==1 && bit_cnt==3'd7))
        byte_cnt <= 2'd0;
    else
        byte_cnt <= byte_cnt+1'b1;
end

always_ff@(posedge scl_in_inv or negedge rst_i2c_n) begin
    if(~rst_i2c_n)
        addr_data_flag <= 1'd0;
    else if(~bit_en || i2c_restart)
        addr_data_flag <= 1'd0;
    else if(byte_cnt==1 && bit_cnt==3'd7)
        addr_data_flag <= ~addr_data_flag;
end

always_ff @(posedge scl_in or negedge rst_i2c_n) begin // clock edge
    if(~rst_i2c_n) 
        shift_in <= 'd0;
    else if(state_cs!=IDLE)
        shift_in <= {shift_in[6:0],sda_in};
end
always_ff @(posedge scl_in or negedge rst_i2c_n) begin // clock edge
    if(~rst_i2c_n) 
        wdata <= 'd0;
    else if(state_cs==WRITE && bit_cnt==3'd7)
        wdata <= {shift_in[6:0],sda_in};
end

always_ff @(posedge scl_in or negedge rst_i2c_n) begin // clock edge
    if(~rst_i2c_n) 
        shift_out <= 'd0;
    //else if(state_cs==AACK && rw_flag)
    //    shift_out <= rdata;
    else if(state_cs==READ && addr_data_flag && bit_cnt==0)
        shift_out <= (byte_cnt==0)? reg_rdata[15:8] : reg_rdata[7:0];
    else if(state_cs==READ)
        shift_out <= {shift_out[6:0],1'b0};
end

always_ff @(posedge scl_in or negedge rst_i2c_n) begin // clock edge
    if(~rst_i2c_n) 
        reg_addr <= 'd0;
    else if((state_cs==READ || state_cs==WRITE) && ~addr_data_flag)
        reg_addr <= {reg_addr[14:0],sda_in};
end

always_ff @(posedge scl_in or negedge rst_i2c_n) begin // clock edge
    if(~rst_i2c_n) 
        reg_wdata <= 'd0;
    else if(state_cs==WRITE && addr_data_flag)
        reg_wdata <= {reg_wdata[14:0],sda_in};
end

always_ff @(posedge scl_in or negedge rst_i2c_n) begin // clock edge
    if(~rst_i2c_n)
        reg_rd_en <= 1'b0;
    else if(state_cs==READ && ~addr_data_flag && byte_cnt==1 && bit_cnt==3'd7)
        reg_rd_en <= 1'b1;
    else 
        reg_rd_en <= 1'b0;
end

always_ff @(posedge scl_in or negedge rst_i2c_n) begin // clock edge
    if(~rst_i2c_n)
        reg_wr_en <= 1'b0;
    else if(state_cs==WRITE && ~addr_data_flag && byte_cnt==1 && bit_cnt==3'd7)
        reg_wr_en <= 1'b1;
    else 
        reg_wr_en <= 1'b0;
end

always_ff @(posedge scl_in or negedge rst_i2c_n) begin // clock edge
    if(~rst_i2c_n) 
        sda_oe <= 1'b0;
    else if(state_cs==READ)
        sda_oe <= 1'b1;
    else
        sda_oe <= 1'b0;
end

always_ff @(posedge scl_in or negedge rst_i2c_n) begin // clock edge
    if(~rst_i2c_n) 
        sda_out <= 1'b0;
    else if(state_cs==READ)
        sda_out <= shift_out[7];
    else
        sda_out <= 1'b0;
end

// TODO
assign scl_oe = 1'b0;
assign scl_out = 1'b0;

endmodule
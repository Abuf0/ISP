module sync_fifo #(
    parameter FIFO_DEEPTH = 2048    ,
    parameter FIFO_WIDTH = 16       
)(
    input                           clk             ,
    input                           rstn            ,
    input                           wr_en           ,
    input                           rd_en           ,
    input        [FIFO_WIDTH-1:0]   wdata           ,
    output logic [FIFO_WIDTH-1:0]   rdata           ,
    output logic                    fifo_empty      ,
    output logic                    fifo_full       
);
parameter PTR_WIDTH = $clog(FIFO_DEEPTH);
logic [FIFO_WIDTH-1:0] ram [0:FIFO_DEEPTH-1];
logic [PTR_WIDTH-1:0] wptr;
logic [PTR_WIDTH-1:0] rptr;
logic [PTR_WIDTH-1:0] wptr_next;
logic [PTR_WIDTH-1:0] rptr_next;
logic wptr_h;
logic rptr_h;
logic wptr_h_next;
logic rptr_h_next;
logic fifo_empty_pre;
logic fifo_full_pre;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        {wptr_h,wptr} <= 'd0;
    else if(wr_en && ~fifo_full_pre)
        {wptr_h,wptr} <= {wptr_h_next,wptr_next};
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        {rptr_h,rptr} <= 'd0;
    else if(wr_en && ~fifo_empty_pre)
        {rptr_h,rptr} <= {rptr_h_next,rptr_next};
end

assign wptr_next = (wptr==FIFO_DEEPTH-1)?   'd0 : wptr+1'b1;
assign rptr_next = (rptr==FIFO_DEEPTH-1)?   'd0 : rptr+1'b1;
assign wptr_h_next = (wptr==FIFO_DEEPTH-1)? ~wptr_h : wptr;
assign rptr_h_next = (rptr==FIFO_DEEPTH-1)? ~rptr_h : rptr;

assign fifo_full_pre =  (wptr_h_next != rptr_h_next && wptr_next == rptr_next);
assign fifo_empty_pre = (rptr_h_next == wptr_h_next && rptr_next == wptr_next);

//assign fifo_full = fifo_full_pre;
//assign fifo_empty = fifo_empty_pre;
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        fifo_full <= 1'b0;
    else
        fifo_full <= fifo_full_pre;
end
always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        fifo_empty <= 1'b0;
    else
        fifo_empty <= fifo_empty_pre;
end

always_ff@(posedge clk) begin
    if(wr_en && ~fifo_full)
        ram[wptr] <= wdata;
end

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        rdata <= 'd0;
    else if(rd_en && ~fifo_empty)
        rdata <= raw[rptr];
end

endmodule
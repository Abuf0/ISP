module sync_level(
    input           clk       ,
    input           rstn      ,
    input           data_in   ,
    output logic    data_out
);

logic data_ff1;
logic data_ff2;

always_ff@(posedge clk or negedge rstn) begin
    if(~rstn)
        {data_ff1,data_ff2} <= 2'd0;
    else 
        {data_ff1,data_ff2} <= {data_in,data_ff1};
end

assign data_out = data_ff2;

endmodule
module sync_reset_n(
    input clk,          //Ŀ��ʱ����
    input async_rst_n,      //�첽��λ������Ч
    
    output sync_rst_n    //����Ч
    );
    
//reg define
logic reset_1;
logic reset_2;
    
//*****************************************************
//**                    main code
//***************************************************** 
assign sync_rst_n  = reset_2;
    
//���첽��λ�źŽ���ͬ���ͷţ���ת���ɸ���Ч
always @ (posedge clk or negedge async_rst_n) begin
    if(!async_rst_n) begin
        reset_1 <= 1'b0;
        reset_2 <= 1'b0;
    end
    else begin
        reset_1 <= 1'b1;
        reset_2 <= reset_1;
    end
end
    
endmodule
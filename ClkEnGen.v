
module ClkEnGen #
(
    parameter DIV = 4//100MHz/16 =6.25MHz
)
(
    input iClk,
    input iRsn,
    output reg wEnClk
    );
    
    reg[$clog2(DIV)-1:0] cnt;
    
    always @(posedge iClk  or negedge iRsn) begin
        if(!iRsn) begin
            cnt<=0;
            wEnClk<=1'b0;
        end 
        else begin
            if(cnt==DIV-1) begin
                cnt<=0;
                wEnClk<=1'b1;
            end 
            else begin
                cnt<=cnt+1'b1;
                wEnClk<=1'b0;
            end
         end
       end
       
        
endmodule

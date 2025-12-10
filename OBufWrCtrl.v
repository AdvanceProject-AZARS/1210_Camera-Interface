module OBufWrCtrl (
	input iClk,
	input wRsn,
	input wEnClk,
	input wStCnn,
	input wFgRgb565Valid,
	input [15:0] wRgb565,
	
	output wOBufWrEn,
	output [16:0] wOBufWrAddr,
	output [15:0] wOBufWrDt
);

   // reg [15:0] r_wOBufWrDt;
    reg [16:0] r_OBufWrAddr;
  
    
    ///////////////////////////////////
    //Output Logic
    ///////////////////////////////////
    
    //wOBufWrEn
    assign wOBufWrEn = wFgRgb565Valid;
    /*
    //wOBufWrDt
    always @(posedge iClk or negedge wRsn) begin
        if (!wRsn)
            r_wOBufWrDt <= 16'd0;
        else if (wEnClk) begin
            if (wFgRgb565Valid)   
                r_wOBufWrDt <= wRgb565; end
    end
    */
    assign wOBufWrDt = wRgb565;
    
    //wWOBufWrAddr
    always@(posedge iClk or negedge wRsn) begin
        if(!wRsn) 
            r_OBufWrAddr <= 17'b0;
        else if(wEnClk && r_OBufWrAddr == 17'd130560)
            r_OBufWrAddr <= 17'b0;
        else if(wEnClk && wFgRgb565Valid) 
            r_OBufWrAddr <= r_OBufWrAddr + 1'b1;
        else if (wEnClk && wStCnn) 
            r_OBufWrAddr <= 17'b0;
    end
    
    assign wOBufWrAddr = r_OBufWrAddr;
    
  
    
    
endmodule

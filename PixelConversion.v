module PixelConversion(
    input               iClk,
    input               wRsn,
    input               wEnClk,           // 25MHz pixel enable
    input               wStCnn,
    input               wFgPixelValid,
    input   [23:0]      wConvPixel,

    output              wFgRgb565Valid,    
    output  [15:0]      wRgb565
);
    reg                 r_wFgRgb565Valid;
    
    reg [23:0] r_wConvPixel;
    reg [17:0] pix_cnt;
    ///////////////////////////////////////////////////////
    // RGB888 → RGB565 변환
    ///////////////////////////////////////////////////////
    wire [4:0] r5 ;
    wire [5:0] g6 ;
    wire [4:0] b5 ;
    
    wire valid_data ;

    always @(posedge iClk or negedge wRsn) begin
        if(!wRsn) 
            r_wConvPixel  <= 24'b0;
        else if(wEnClk && wFgPixelValid) 
            r_wConvPixel  <= wConvPixel;
    end

    assign r5 = r_wConvPixel[23:19];   // R[7:3]
    assign g6 = r_wConvPixel[15:10];   // G[7:2]
    assign b5 = r_wConvPixel[7:3];     // B[7:3]

    assign wRgb565 = {r5, g6, b5};
    

    ///////////////////////////////////////////////////////
    // r_wFgRgb565Valid : Pixel Valid timing (CNN → RAM Write)
    ///////////////////////////////////////////////////////
    
//////////////////////////    
//  MODIFIED; Considering 2-Cycle Delay   
//////////////////////////    
    
    always @(posedge iClk or negedge wRsn) begin
        if(!wRsn) begin
            r_wFgRgb565Valid <= 1'b0;
        end
        else if(wEnClk && !valid_data) 
            r_wFgRgb565Valid <= 1'b0;
        else if (wEnClk && wFgPixelValid)
            r_wFgRgb565Valid <= 1'b1;
    end
    
    assign wFgRgb565Valid = r_wFgRgb565Valid;
 

    always @(posedge iClk or negedge wRsn) begin
        if(!wRsn) 
            pix_cnt <= 18'd0;
        else if(wEnClk && pix_cnt == 481)
            pix_cnt <= 18'd0;
        else if(wEnClk && (wFgPixelValid || (r_wFgRgb565Valid && pix_cnt == 480)))
            pix_cnt <= pix_cnt + 1'd1;
    end

    assign valid_data = (pix_cnt == 480 || pix_cnt == 481) ? 0 : 1;
    
    
endmodule

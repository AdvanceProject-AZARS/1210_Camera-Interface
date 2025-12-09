module PixelWindow #(
    parameter IMG_W = 480,
    parameter IMG_H = 272
)(
    input               wRsn,
    input               iClk,
    input               wEnClk,        
    //input               wStCnn,          
    input               wFgIBufValid,    
    input   [15:0]      wIBufRdDt,       

    output              wFgPixelValid,  
    output  [23:0]      wPixel00, wPixel01, wPixel02,
    output  [23:0]      wPixel10, wPixel11, wPixel12,
    output  [23:0]      wPixel20, wPixel21, wPixel22,
    output              wConvolDone
     
);

    integer i;

    // ----------------------------------------------------------------------
    // 3 line-buffers for window generation
    // ----------------------------------------------------------------------
    reg [9:0] x_cnt; //2^10 = 1024 > 482
    reg [9:0] y_cnt; // 2^^10 =1024>274

    reg [23:0] linebuf0 [0:IMG_W+1]; // padding 1
    reg [23:0] linebuf1 [0:IMG_W+1];
    reg [23:0] linebuf2 [0:IMG_W+1];

    reg r_wFgPixelValid, r_wConvolDone ;
    
    // ----------------------------------------------------------------------
    // Pixel Conversion wIBufRdDt(16') -> wConvRdDt(24')
    // ----------------------------------------------------------------------
    wire [23:0] wConvRdDt;
       
    assign wConvRdDt = {
        { wIBufRdDt[15:11], wIBufRdDt[13:11] },     // R
        { wIBufRdDt[10:5],  wIBufRdDt[6:5]    },    // G
        { wIBufRdDt[4:0],   wIBufRdDt[2:0]    }     // B
    };
    
    // ----------------------------------------------------------------------
    // X Counter 
    // ----------------------------------------------------------------------
        
    always @(posedge iClk or negedge wRsn) begin
        if(!wRsn) 
            x_cnt <= 10'd1;
        else if(wEnClk && x_cnt == IMG_W + 2'd2)
            x_cnt <= 10'd1;
        else if(wEnClk && wFgIBufValid)
            x_cnt <= x_cnt + 10'd1;
    end
    
    // ----------------------------------------------------------------------
    // Y Counter
    // ----------------------------------------------------------------------
    always @(posedge iClk or negedge wRsn) begin
        if(!wRsn)
            y_cnt <= 10'd0;
        else if(wEnClk && (x_cnt == IMG_W + 2'd2) && (y_cnt == IMG_H))
            y_cnt <= 10'd0;
        else if(wEnClk && wFgIBufValid && (x_cnt == IMG_W + 2'd2) && (y_cnt < IMG_H + 1'b1))
            y_cnt <= y_cnt + 10'd1;
    end
    

    // ----------------------------------------------------------------------
    // Line buffer 2 : save current row pixels
    // ----------------------------------------------------------------------
    always @(posedge iClk or negedge wRsn) begin
        if(!wRsn) begin
            for(i = 0; i < IMG_W + 2; i = i + 1)
                linebuf2[i] <= 24'd0;
        end
        else if(wEnClk && wFgIBufValid) begin
            if (y_cnt == IMG_H)begin
                for(i = 0; i < IMG_W + 2; i = i + 1)
                    linebuf2[i] <= 24'd0;
            end
            else if (x_cnt < IMG_W + 1'b1)
                linebuf2[x_cnt] <= wConvRdDt;
        end
    end

    // ----------------------------------------------------------------------
    // Line shift : only when end of line
    // ----------------------------------------------------------------------
    always @(posedge iClk or negedge wRsn) begin
        if(!wRsn) begin
            for(i = 0; i < IMG_W + 2; i = i + 1) begin
                linebuf0[i] <= 24'd0;
                linebuf1[i] <= 24'd0;
            end
        end
        else if(wEnClk && x_cnt == IMG_W + 2'd2) begin
            for(i = 0; i < IMG_W + 2; i = i + 1) begin
                linebuf0[i] <= linebuf1[i];
                linebuf1[i] <= linebuf2[i];
            end
        end
    end

    // ----------------------------------------------------------------------
    // Window Valid (3x3 window available)
    // ----------------------------------------------------------------------
    always @(posedge iClk or negedge wRsn) begin
        if(!wRsn)
            r_wFgPixelValid <= 1'b0;
        else if(wEnClk && (x_cnt == IMG_W + 2'd2 && y_cnt == IMG_H))
            r_wFgPixelValid <= 1'b0;
        else if(wEnClk && (x_cnt >= 10'd2 && y_cnt >= 10'd1))
            r_wFgPixelValid <= 1'b1;
    end

    assign wFgPixelValid = r_wFgPixelValid;

    // ----------------------------------------------------------------------
    // wConvolDone 
    // ----------------------------------------------------------------------    
    always @(posedge iClk or negedge wRsn) begin
        if(!wRsn)
            r_wConvolDone <= 1'b0;
        else if(wEnClk && (x_cnt == IMG_W + 2'd2 && y_cnt == IMG_H))
            r_wConvolDone <= 1'b1;
        else if(wEnClk)
            r_wConvolDone <= 1'b0;
    end

    assign wConvolDone = r_wConvolDone;
   
    
    // ----------------------------------------------------------------------
    // Output 3x3 Window
    // ----------------------------------------------------------------------
    assign wPixel00 = (x_cnt >= 3 && y_cnt >= 1) ? linebuf0[x_cnt - 3] : 24'd0;
    assign wPixel01 = (x_cnt >= 3 && y_cnt >= 1) ? linebuf0[x_cnt - 2] : 24'd0;
    assign wPixel02 = (x_cnt >= 3 && y_cnt >= 1) ? linebuf0[x_cnt - 1] : 24'd0;

    assign wPixel10 = (x_cnt >= 3 && y_cnt >= 1) ? linebuf1[x_cnt - 3] : 24'd0;
    assign wPixel11 = (x_cnt >= 3 && y_cnt >= 1) ? linebuf1[x_cnt - 2] : 24'd0;
    assign wPixel12 = (x_cnt >= 3 && y_cnt >= 1) ? linebuf1[x_cnt - 1] : 24'd0;

    assign wPixel20 = (x_cnt >= 3 && y_cnt >= 1) ? linebuf2[x_cnt - 3] : 24'd0;
    assign wPixel21 = (x_cnt >= 3 && y_cnt >= 1) ? linebuf2[x_cnt - 2] : 24'd0;
    assign wPixel22 = (x_cnt >= 3 && y_cnt >= 1) ? linebuf2[x_cnt - 1] : 24'd0;

endmodule

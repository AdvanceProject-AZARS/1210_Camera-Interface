`timescale 1ns/1ps

module tb ;

    reg PL_CLK_100MHZ;
    reg PCLK;    
    reg PL_RSTN;
    reg sw_i;
    reg cam_vsync_i;
    reg cam_hsync_i;
    reg [7:0] cam_data_i;

    wire ram_wr_en_o;
    wire [16:0] ram_wr_addr_o;
    wire [15:0] ram_wr_data_o;

    wire buf_sel;
    wire fr_done;
    wire buf0_full_wr;
    wire buf1_full_wr;

    
     ClkEnGen u_ClkEnGen_6P25 (
        .iClk(PL_CLK_100MHZ),
        .iRsn(PL_RSTN),
        .wEnClk(wEnClk)
        );    


    CamBufWr u_CamBufWr (
        .iClk(PCLK),
        .wRsn(PL_RSTN),
        .sw_i(sw_i),
        .cam_vsync_i(cam_vsync_i),
        .cam_hsync_i(cam_hsync_i),
        .cam_data_i(cam_data_i),
        .ram_wr_en_o(ram_wr_en_o),
        .ram_wr_addr_o(ram_wr_addr_o),
        .ram_wr_data_o(ram_wr_data_o),
        .buf_sel(buf_sel),
        .buf0_full_wr(buf0_full_wr),
        .buf1_full_wr(buf1_full_wr), 
        .fr_done(fr_done)
    );
 //////////////////////////////////////////////////////////////////////  
  
assign wIBufRdDt = (buf_sel_rd == 1'b0) ? wIBufRdDt0 : wIBufRdDt1;
// Bus contention signature -> Separating Signal
wire [15:0] wIBufRdDt0;
wire [15:0] wIBufRdDt1;

   
     BRAM Buf0  (
        // Port A (Write port)
        .clka   (PCLK),            
        .ena    (1'b1),           
        .wea    (ram_wr_en_o && !buf_sel),        
        .addra  (ram_wr_addr_o), 
        .dina   (ram_wr_data_o),   
    
        // Port B (Read port)
        .clkb   (PL_CLK_100MHZ),         
        .enb    (wIBufRdEn && !buf_sel_rd),
        .addrb  (wIBufRdAddr), 
        .doutb  (wIBufRdDt0)   
    );
    
     BRAM Buf1  (
        // Port A (Write port)
        .clka   (PCLK),            
        .ena    (1'b1),           
        .wea    (ram_wr_en_o && buf_sel),        
        .addra  (ram_wr_addr_o), 
        .dina   (ram_wr_data_o),   
    
        // Port B (Read port)
        .clkb   (PL_CLK_100MHZ),         
        .enb    (wIBufRdEn && buf_sel_rd),    
        .addrb  (wIBufRdAddr), 
        .doutb  (wIBufRdDt1)   
    );
    
 //////////////////////////////////////////////////////////////////////   

    CamBufRd u_CamBufRd (
        .wRsn           (PL_RSTN),         // reset (active low)
        .iClk           (PL_CLK_100MHZ),         // read-domain clock
        .wEnClk         (wEnClk),       // pixel enable (CNN clock)
        .wIBufRdDt      (wIBufRdDt),    // data from BRAM
        .fr_done        (fr_done),
        .buf0_full_wr   (buf0_full_wr),
        .buf1_full_wr   (buf1_full_wr),
    
        .wIBufRdEn      (wIBufRdEn),    // read enable to BRAM
        .wIBufRdAddr    (wIBufRdAddr),  // address to BRAM
        .wFgIBufValid   (wFgIBufValid), // valid flag for CNN
        .wIBufRdDone    (wIBufRdDone),   // read complete
        .buf_sel_rd     (buf_sel_rd)
    );

wire fr_done;
wire [16:0] wIBufRdAddr;
wire wIBufRdEn;
wire [15:0] wIBufRdDt;
wire buf_sel_rd;
wire wFgIBufValid;

    PixelWindow u_PixelWindow (
        .wRsn          (PL_RSTN),        
        .iClk          (PL_CLK_100MHZ),  
        .wEnClk        (wEnClk),  
        .wFgIBufValid  (wFgIBufValid),   
        .wIBufRdDt      (wIBufRdDt), //16' Pixel, Internal Signal -> 24' Pixel 
    
        .wFgPixelValid (wFgPixelValid), 
        .wPixel00      (wPixel00),
        .wPixel01      (wPixel01),
        .wPixel02      (wPixel02),
        .wPixel10      (wPixel10),
        .wPixel11      (wPixel11),
        .wPixel12      (wPixel12),
        .wPixel20      (wPixel20),
        .wPixel21      (wPixel21),
        .wPixel22      (wPixel22),
    
        .wConvolDone   (wConvolDone)
    );

    // 100MHz system clock
    initial PL_CLK_100MHZ = 0;
    always #5 PL_CLK_100MHZ = ~PL_CLK_100MHZ;

    // 48MHz Camera clock
    initial PCLK = 0;
    always #10.416666 PCLK = ~PCLK;

    localparam H = 480;
    localparam V = 272;

    integer x, y;

    reg [15:0] pixel;

////////// Generating Task ////////// 

    task send_frame;
    begin
        $display("\n=== FRAME START at time=%t ===", $time);
    
        cam_vsync_i = 0;
    
        for (y = 0; y < V; y = y + 1) begin
            cam_hsync_i = 1;
    
            for (x = 0; x < H; x = x + 1) begin
                // 16-bit pixel 생성
                pixel = {x[7:0], y[7:0]}; 
   
                // Upper byte (pixel[15:8])
                @(posedge PCLK);
                cam_data_i = pixel[15:8];
                // Lower byte (pixel[7:0])
                @(posedge PCLK);
                cam_data_i = pixel[7:0];
            end
    
            cam_hsync_i = 0;
    
            // line gap
            repeat(10) @(posedge PCLK);
        end
    
        // frame end
        cam_vsync_i = 1;
    
        $display("=== FRAME END at time=%t ===", $time);
    
        // Wait a bit
        repeat(100) @(posedge PCLK);
    end
    endtask
  

    // =============================
    // 📌 MAIN TB: RESET → FRAME 4개 전송
    // =============================
    initial begin
        PL_RSTN = 0;
        sw_i = 0;
        cam_vsync_i = 1;
        cam_hsync_i = 0;
        cam_data_i  = 0;

        #100;
        PL_RSTN = 1;
        
        repeat(1000) @(posedge PCLK);

// FRAME SEND TASK 4TIMES
        send_frame();
        send_frame();
        send_frame();
        send_frame();
        
        

        $display("\n=== Simulation complete ===");
        #500;
    end

    // =============================
    // 📌 Debugging monitor
    // =============================
    always @(posedge PCLK) begin
        if (ram_wr_en_o) begin
            $display("[time %t] WR_EN addr=%d data=%h buf_sel=%b buf0_full=%b buf1_full=%b",
                    $time, ram_wr_addr_o, ram_wr_data_o, buf_sel, buf0_full_wr, buf1_full_wr);
        end
    end

endmodule

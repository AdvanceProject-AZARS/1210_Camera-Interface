module CamBufRd (
    input  wire           wRsn,
    input  wire           iClk,
    input  wire           wEnClk,   
    //input  wire        	  wStCnn,
    input         [15:0]  wIBufRdDt,	
    input                 fr_done,
    input                 buf0_full_wr,
    input                 buf1_full_wr,

    output   wire         	  wIBufRdEn,
    output   wire  	  [16:0]  wIBufRdAddr,
    output   reg          wFgIBufValid,
    output   reg      	  wIBufRdDone,
    output                buf_sel_rd
);

    reg           r_wIBufRdEn;
    reg    [16:0] r_wIBufRdAddr;


    localparam IMG_W = 480;
    localparam IMG_H = 272;
    localparam TOTAL_PIXELS = IMG_W * IMG_H;


///////////////////////////////////////////////////////////////////
//Output Logic; wFgIBufValid
///////////////////////////////////////////////////////////////////
		
    always @(posedge iClk or negedge wRsn) begin
        if(!wRsn)  
            wFgIBufValid <= 1'b0;
        else if (wEnClk)
            wFgIBufValid <= wIBufRdEn;
    end



///////////////////////////////////////////////////////////////////
//Output Logic; wIBufRdDone
///////////////////////////////////////////////////////////////////

    always @(posedge iClk or negedge wRsn) begin
        if (!wRsn)  
            wIBufRdDone <= 1'b0;
	    else if (wEnClk && !(wIBufRdEn))
				wIBufRdDone <= 1'b0;            
        else if (wEnClk && (wIBufRdAddr == TOTAL_PIXELS - 1)) 
				wIBufRdDone <= 1'b1;
	end


	
///////////////////////////////////////////////////////////////////
//  FSM for CamBufRd
///////////////////////////////////////////////////////////////////
	
    parameter R_IDLE = 2'b00,
              R_RUN  = 2'b01,
			  R_WAIT = 2'b10 ;


    reg [1:0] c_state, n_state;
    reg [16:0] rd_cnt;


    always @(posedge iClk or negedge wRsn) begin
        if (!wRsn)
            c_state <= R_IDLE;
        else
            c_state <= n_state;
    end


    always @(*) begin
        case (c_state)
            R_IDLE:
				n_state = (pulse_buf0_full_wr || pulse_buf1_full_wr) ? R_RUN : R_IDLE;
            R_RUN:
                n_state = (rd_cnt == TOTAL_PIXELS) ? R_WAIT : R_RUN;
			R_WAIT:
                n_state = (fr_done) ? R_IDLE : R_WAIT;
            default:
                n_state = R_IDLE;
        endcase
    end	
	
	
	reg r_buf_sel_rd;
	reg buf0_empty_rd;
	reg buf1_empty_rd;

	always @(posedge iClk or negedge wRsn) begin
		if (!wRsn) begin
		r_wIBufRdEn    <= 1'b0;
		r_wIBufRdAddr  <= rd_cnt;
		buf0_empty_rd  <= 1'b0;
		buf1_empty_rd  <= 1'b0;
		r_buf_sel_rd   <= 1'b0; end
		
		else if (wEnClk) begin //mo
			case (c_state)
				R_IDLE: begin
					r_wIBufRdEn   <= 1'b0;
					if (pulse_buf0_full_wr)
						r_buf_sel_rd <= 1'b0;
					else if (pulse_buf1_full_wr)
						r_buf_sel_rd <= 1'b1;
				end
				R_RUN: begin
					r_wIBufRdEn   <= 1'b1;   
					r_wIBufRdAddr <= rd_cnt;  
				end
				R_WAIT: begin
					r_wIBufRdEn <= 1'b0;

					if (r_buf_sel_rd == 1'b0) begin
						buf0_empty_rd <= 1'b1;
						buf1_empty_rd <= 1'b0; end
					else begin
						buf1_empty_rd <= 1'b1;
						buf0_empty_rd <= 1'b0; end
				end
				default: begin
					r_wIBufRdEn <= 1'b0;
				end
			endcase
	end
end
    assign buf_sel_rd = r_buf_sel_rd;
	assign wIBufRdEn = r_wIBufRdEn;  
	assign wIBufRdAddr = r_wIBufRdAddr;  
	
	
	
// Counter for Read Enable Signal
	always @(posedge iClk or negedge wRsn) begin
		if (!wRsn)
			rd_cnt <= 0;
		else if (wEnClk) begin
			case (c_state)
				R_IDLE: rd_cnt <= 0;
				R_RUN : rd_cnt <= rd_cnt + 1;
				R_WAIT: rd_cnt <= rd_cnt;
			endcase
		end
	end	
	
	
///////////////////////////////////////////////////////////////////
//  Wr Buffer Full Signal Pulse Generation
///////////////////////////////////////////////////////////////////

    reg sync0_ff1, sync0_ff2;
    reg sync1_ff1, sync1_ff2;	
    reg sync0_ff2_d, sync1_ff2_d;	
	
    always @(posedge iClk or negedge wRsn) begin
        if (!wRsn) begin
            sync0_ff1 <= 0;
            sync0_ff2 <= 0;
			
            sync1_ff1 <= 0;
            sync1_ff2 <= 0; end	
        else begin
            sync0_ff1 <= buf0_full_wr;
            sync0_ff2 <= sync0_ff1;
			
            sync1_ff1 <= buf1_full_wr;
            sync1_ff2 <= sync1_ff1; end	
    end


    always @(posedge iClk or negedge wRsn) begin
        if (!wRsn) begin
            sync0_ff2_d <= 0;
			sync1_ff2_d <= 0; end
        else begin
            sync0_ff2_d <= sync0_ff2;
			sync1_ff2_d <= sync1_ff2; end
    end

    assign pulse_buf0_full_wr = sync0_ff2 & ~sync0_ff2_d;
    assign pulse_buf1_full_wr = sync1_ff2 & ~sync1_ff2_d;


/*
//Output Logic; wIBufRdEn

    always @(posedge iClk or negedge wRsn) begin
        if (!wRsn) begin 
            r_wIBufRdEn <= 1'b0; end
        else if (wEnClk) begin
            if		(wStCnn)         
                    r_wIBufRdEn   <= 1'b1;
            else if (wIBufRdAddr == TOTAL_PIXELS-2) 
                    r_wIBufRdEn <= 1'b0;                    
            else       
                    r_wIBufRdEn   <= r_wIBufRdEn;                    
        end
    end
      
	  
	assign wIBufRdEn = r_wIBufRdEn;  
	

//Output Logic; wIBufRdAddr
	
    always @(posedge iClk or negedge wRsn) begin
        if(!wRsn) 
            r_wIBufRdAddr <= 0;
        else if(wEnClk) begin
            if (wStCnn) 
                r_wIBufRdAddr <= 17'd0;
            else if (wIBufRdEn && (r_wIBufRdAddr >= 0) && (r_wIBufRdAddr < TOTAL_PIXELS-1)) 
                r_wIBufRdAddr <= r_wIBufRdAddr + 1'b1;
        end
    end

	assign wIBufRdAddr = r_wIBufRdAddr;
	
*/


		
endmodule
module MainFsm(
    input wIBufRdDone,
    input wConvolDone,
    input wLcdIfDone,

    input wRsn,
    input iClk,
    input wEnClk,

    input wEnStart,

    output wStCnn,
    output wStLcdIf,

    output reg [3:0] rM_CurState
    );

    //1.상태 정의
    localparam [3:0]
        p_Idle      = 4'd0,
        p_StCnn     = 4'd1,
        p_IBufRd    = 4'd2,
        p_Convol    = 4'd3,
        p_LstOBufWr = 4'd4,
        p_StLcdIf   = 4'd5,
        p_LcdIf     = 4'd6,
        p_CnnDone   = 4'd7;

    reg[3:0]    rM_NextState;

    always @(posedge iClk or negedge wRsn) begin
        if(!wRsn)
            rM_CurState<=p_Idle;
        else if(wEnClk)
            rM_CurState<=rM_NextState;
    end


    
    always @(*)begin
        rM_NextState=rM_CurState;

        case(rM_CurState)
            p_Idle: begin
                if(wEnStart)
                    rM_NextState=p_StCnn;
            end


            p_StCnn: begin
                rM_NextState=p_IBufRd;
            end

            p_IBufRd : begin
                if(wIBufRdDone)
                    rM_NextState=p_Convol;
            end

            p_Convol: begin
                if(wConvolDone)
                    rM_NextState=p_LstOBufWr;
            end

            p_LstOBufWr : begin
                rM_NextState=p_StLcdIf;
            end

            p_StLcdIf : begin
                rM_NextState=p_LcdIf;
            end

            p_LcdIf : begin
                if(wLcdIfDone)
                    rM_NextState=p_CnnDone;
            end

            p_CnnDone : begin
                rM_NextState=p_Idle;
            end

            default:rM_NextState=p_Idle;

        endcase

    end

    assign wStCnn=(rM_CurState==p_StCnn);
    assign wStLcdIf=(rM_CurState==p_StLcdIf);
            





endmodule

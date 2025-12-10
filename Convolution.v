`timescale 1ns/1ps
module Convolution(
    input               iClk,
    input               wRsn,
    input               wEnClk,
    input               wStCnn,

    input   [23:0]      wPixel00, wPixel01, wPixel02,
    input   [23:0]      wPixel10, wPixel11, wPixel12,
    input   [23:0]      wPixel20, wPixel21, wPixel22,

    input   [1:0]       wMode,          

    output  [23:0]      wConvPixel
);

    ////////////////////////////////////////////////////
    // RGB SLICE  
    ////////////////////////////////////////////////////
    wire [7:0] r00, r01, r02, r10, r11, r12, r20, r21, r22;
    wire [7:0] g00, g01, g02, g10, g11, g12, g20, g21, g22;
    wire [7:0] b00, b01, b02, b10, b11, b12, b20, b21, b22;
    //----R-----
    assign r00 = wPixel00[23:16]; assign r01 = wPixel01[23:16]; assign r02 = wPixel02[23:16];
    assign r10 = wPixel10[23:16]; assign r11 = wPixel11[23:16]; assign r12 = wPixel12[23:16];
    assign r20 = wPixel20[23:16]; assign r21 = wPixel21[23:16]; assign r22 = wPixel22[23:16];
    //----G-----
    assign g00 = wPixel00[15:8];  assign g01 = wPixel01[15:8];  assign g02 = wPixel02[15:8];
    assign g10 = wPixel10[15:8];  assign g11 = wPixel11[15:8];  assign g12 = wPixel12[15:8];
    assign g20 = wPixel20[15:8];  assign g21 = wPixel21[15:8];  assign g22 = wPixel22[15:8];
    //----B-----
    assign b00 = wPixel00[7:0];   assign b01 = wPixel01[7:0];   assign b02 = wPixel02[7:0];
    assign b10 = wPixel10[7:0];   assign b11 = wPixel11[7:0];   assign b12 = wPixel12[7:0];
    assign b20 = wPixel20[7:0];   assign b21 = wPixel21[7:0];   assign b22 = wPixel22[7:0];

    ////////////////////////////////////////////////////
    // ★★★ wMode 기반 커널 선택 로직 ★★★
    ////////////////////////////////////////////////////

    // bypass Kernel = 모든 값 1
    localparam signed [7:0] BP00 = 0, BP01 = 0, BP02 = 0;
    localparam signed [7:0] BP10 = 0, BP11 = 1, BP12 = 0;
    localparam signed [7:0] BP20 = 0, BP21 = 0, BP22 = 0;

    // Sharpen Kernel (기존)
    localparam signed [7:0] SH00 = 0,  SH01 = -1, SH02 = 0;
    localparam signed [7:0] SH10 = -1, SH11 = 5,  SH12 = -1;
    localparam signed [7:0] SH20 = 0,  SH21 = -1, SH22 = 0;

    // Sobel X
    localparam signed [7:0] SX00 = -1, SX01 = 0,  SX02 = 1;
    localparam signed [7:0] SX10 = -2, SX11 = 0,  SX12 = 2;
    localparam signed [7:0] SX20 = -1, SX21 = 0,  SX22 = 1;

    // Sobel Y
    localparam signed [7:0] SY00 = -1, SY01 = -2, SY02 = -1;
    localparam signed [7:0] SY10 =  0, SY11 =  0, SY12 =  0;
    localparam signed [7:0] SY20 =  1, SY21 =  2, SY22 =  1;

    // 선택된 커널 저장용 레지스터
    reg signed [7:0] K00, K01, K02, K10, K11, K12, K20, K21, K22;

    always @(posedge iClk or negedge wRsn) begin
        if (!wRsn) begin
            K00 <= SH00; K01 <= SH01; K02 <= SH02;
            K10 <= SH10; K11 <= SH11; K12 <= SH12;
            K20 <= SH20; K21 <= SH21; K22 <= SH22;
        end 
        else if (wEnClk) begin
            case(wMode)
                2'b00: begin    // Blur
                    K00 <= BP00; K01 <= BP01; K02 <= BP02;
                    K10 <= BP10; K11 <= BP11; K12 <= BP12;
                    K20 <= BP20; K21 <= BP21; K22 <= BP22;
                end
                2'b01: begin    // Sharpen
                    K00 <= SH00; K01 <= SH01; K02 <= SH02;
                    K10 <= SH10; K11 <= SH11; K12 <= SH12;
                    K20 <= SH20; K21 <= SH21; K22 <= SH22;
                end
                2'b10: begin    // Sobel X
                    K00 <= SX00; K01 <= SX01; K02 <= SX02;
                    K10 <= SX10; K11 <= SX11; K12 <= SX12;
                    K20 <= SX20; K21 <= SX21; K22 <= SX22;
                end
                2'b11: begin    // Sobel Y
                    K00 <= SY00; K01 <= SY01; K02 <= SY02;
                    K10 <= SY10; K11 <= SY11; K12 <= SY12;
                    K20 <= SY20; K21 <= SY21; K22 <= SY22;
                end
                default begin    // Sharpen
                    K00 <= BP00; K01 <= BP01; K02 <= BP02;
                    K10 <= BP10; K11 <= BP11; K12 <= BP12;
                    K20 <= BP20; K21 <= BP21; K22 <= BP22;
                end
            endcase
        end
    end
    ////////////////////////////////////////////////////
    // Convolution per Channel  
    ////////////////////////////////////////////////////
    //----R-----
    wire signed [31:0] r_conv =
        $signed({1'b0, r00}) * $signed(K00) +
        $signed({1'b0, r01}) * $signed(K01) +
        $signed({1'b0, r02}) * $signed(K02) +
        $signed({1'b0, r10}) * $signed(K10) +
        $signed({1'b0, r11}) * $signed(K11) +
        $signed({1'b0, r12}) * $signed(K12) +
        $signed({1'b0, r20}) * $signed(K20) +
        $signed({1'b0, r21}) * $signed(K21) +
        $signed({1'b0, r22}) * $signed(K22);
    //----G-----
    wire signed [31:0] g_conv =
        $signed({1'b0, g00}) * $signed(K00) +
        $signed({1'b0, g01}) * $signed(K01) +
        $signed({1'b0, g02}) * $signed(K02) +
        $signed({1'b0, g10}) * $signed(K10) +
        $signed({1'b0, g11}) * $signed(K11) +
        $signed({1'b0, g12}) * $signed(K12) +
        $signed({1'b0, g20}) * $signed(K20) +
        $signed({1'b0, g21}) * $signed(K21) +
        $signed({1'b0, g22}) * $signed(K22);
    //----B-----
    wire signed [31:0] b_conv =
        $signed({1'b0, b00}) * $signed(K00) +
        $signed({1'b0, b01}) * $signed(K01) +
        $signed({1'b0, b02}) * $signed(K02) +
        $signed({1'b0, b10}) * $signed(K10) +
        $signed({1'b0, b11}) * $signed(K11) +
        $signed({1'b0, b12}) * $signed(K12) +
        $signed({1'b0, b20}) * $signed(K20) +
        $signed({1'b0, b21}) * $signed(K21) +
        $signed({1'b0, b22}) * $signed(K22);

    ////////////////////////////////////////////////////
    // ReLU + Clamp (기존 그대로)
    ////////////////////////////////////////////////////
    //----R-----
    wire [7:0] r_relu =
        (r_conv[31] == 1'b1)    ? 8'd0   :
        (r_conv>= 32'd255)      ? 8'd255 :
                                r_conv[7:0];
    //----G-----
    wire [7:0] g_relu =
        (g_conv[31] == 1'b1)       ? 8'd0   :
        (g_conv >= 32'd255)    ? 8'd255 :
                                g_conv[7:0];
    //----B-----
    wire [7:0] b_relu =
        (b_conv[31] == 1'b1)      ? 8'd0   :
        (b_conv >= 32'd255)     ? 8'd255 :
                               b_conv[7:0];

    assign wConvPixel = {r_relu, g_relu, b_relu};

endmodule

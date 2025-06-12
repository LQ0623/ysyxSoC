module seg(
    input clk,
    input [3:0] num0,
    input [3:0] num1,
    input [3:0] num2,
    input [3:0] num3,
    input [3:0] num4,
    input [3:0] num5,
    input [3:0] num6,
    input [3:0] num7,
    
    output reg [7:0] seg0,
    output reg [7:0] seg1,
    output reg [7:0] seg2,
    output reg [7:0] seg3,
    output reg [7:0] seg4,
    output reg [7:0] seg5,
    output reg [7:0] seg6,
    output reg [7:0] seg7
);

    wire [7:0] segs [16:0];
    assign segs[0] = 8'b00000011;  // 0为亮 1为熄
    assign segs[1] = 8'b10011111;
    assign segs[2] = 8'b00100101;
    assign segs[3] = 8'b00001101;
    assign segs[4] = 8'b10011001;
    assign segs[5] = 8'b01001001;
    assign segs[6] = 8'b01000001;
    assign segs[7] = 8'b00011111;
    assign segs[8] = 8'b00000001;
    assign segs[9] = 8'b00011001;
    assign segs[10] = 8'b00010001;
    assign segs[11] = 8'b00000001;
    assign segs[12] = 8'b01100011;
    assign segs[13] = 8'b00000011;
    assign segs[14] = 8'b01100001;
    assign segs[15] = 8'b01110001;
    assign segs[16] = 8'b11111111;
    always@(posedge clk)begin
        case (num0)
          4'd0:seg0 <= segs[0];
          4'd1:seg0 <= segs[1];
          4'd2:seg0 <= segs[2];
          4'd3:seg0 <= segs[3];
          4'd4:seg0 <= segs[4];
          4'd5:seg0 <= segs[5];
          4'd6:seg0 <= segs[6];
          4'd7:seg0 <= segs[7];
          4'd8:seg0 <= segs[8];
          4'd9:seg0 <= segs[9];
          4'd10:seg0 <= segs[10];
          4'd11:seg0 <= segs[11];
          4'd12:seg0 <= segs[12];
          4'd13:seg0 <= segs[13];
          4'd14:seg0 <= segs[14];
          4'd15:seg0 <= segs[15];
          default: seg0 <= segs[16];
        endcase
        case (num1)
          4'd0:seg1 <= segs[0];
          4'd1:seg1 <= segs[1];
          4'd2:seg1 <= segs[2];
          4'd3:seg1 <= segs[3];
          4'd4:seg1 <= segs[4];
          4'd5:seg1 <= segs[5];
          4'd6:seg1 <= segs[6];
          4'd7:seg1 <= segs[7];
          4'd8:seg1 <= segs[8];
          4'd9:seg1 <= segs[9];
          4'd10:seg1 <= segs[10];
          4'd11:seg1 <= segs[11];
          4'd12:seg1 <= segs[12];
          4'd13:seg1 <= segs[13];
          4'd14:seg1 <= segs[14];
          4'd15:seg1 <= segs[15];
          default: seg1 <= segs[16];
        endcase
        case (num2)
          4'd0:seg2 <= segs[0];
          4'd1:seg2 <= segs[1];
          4'd2:seg2 <= segs[2];
          4'd3:seg2 <= segs[3];
          4'd4:seg2 <= segs[4];
          4'd5:seg2 <= segs[5];
          4'd6:seg2 <= segs[6];
          4'd7:seg2 <= segs[7];
          4'd8:seg2 <= segs[8];
          4'd9:seg2 <= segs[9];
          4'd10:seg2 <= segs[10];
          4'd11:seg2 <= segs[11];
          4'd12:seg2 <= segs[12];
          4'd13:seg2 <= segs[13];
          4'd14:seg2 <= segs[14];
          4'd15:seg2 <= segs[15];
          default: seg2 <= segs[16];
        endcase
        case (num3)
          4'd0:seg3 <= segs[0];
          4'd1:seg3 <= segs[1];
          4'd2:seg3 <= segs[2];
          4'd3:seg3 <= segs[3];
          4'd4:seg3 <= segs[4];
          4'd5:seg3 <= segs[5];
          4'd6:seg3 <= segs[6];
          4'd7:seg3 <= segs[7];
          4'd8:seg3 <= segs[8];
          4'd9:seg3 <= segs[9];
          4'd10:seg3 <= segs[10];
          4'd11:seg3 <= segs[11];
          4'd12:seg3 <= segs[12];
          4'd13:seg3 <= segs[13];
          4'd14:seg3 <= segs[14];
          4'd15:seg3 <= segs[15];
          default: seg3 <= segs[16];
        endcase
        case (num4)
          4'd0:seg4 <= segs[0];
          4'd1:seg4 <= segs[1];
          4'd2:seg4 <= segs[2];
          4'd3:seg4 <= segs[3];
          4'd4:seg4 <= segs[4];
          4'd5:seg4 <= segs[5];
          4'd6:seg4 <= segs[6];
          4'd7:seg4 <= segs[7];
          4'd8:seg4 <= segs[8];
          4'd9:seg4 <= segs[9];
          4'd10:seg4 <= segs[10];
          4'd11:seg4 <= segs[11];
          4'd12:seg4 <= segs[12];
          4'd13:seg4 <= segs[13];
          4'd14:seg4 <= segs[14];
          4'd15:seg4 <= segs[15];
          default: seg4 <= segs[16];
        endcase
        case (num5)
          4'd0:seg5 <= segs[0];
          4'd1:seg5 <= segs[1];
          4'd2:seg5 <= segs[2];
          4'd3:seg5 <= segs[3];
          4'd4:seg5 <= segs[4];
          4'd5:seg5 <= segs[5];
          4'd6:seg5 <= segs[6];
          4'd7:seg5 <= segs[7];
          4'd8:seg5 <= segs[8];
          4'd9:seg5 <= segs[9];
          4'd10:seg5 <= segs[10];
          4'd11:seg5 <= segs[11];
          4'd12:seg5 <= segs[12];
          4'd13:seg5 <= segs[13];
          4'd14:seg5 <= segs[14];
          4'd15:seg5 <= segs[15];
          default: seg5 <= segs[16];
        endcase
        case (num6)
          4'd0:seg6 <= segs[0];
          4'd1:seg6 <= segs[1];
          4'd2:seg6 <= segs[2];
          4'd3:seg6 <= segs[3];
          4'd4:seg6 <= segs[4];
          4'd5:seg6 <= segs[5];
          4'd6:seg6 <= segs[6];
          4'd7:seg6 <= segs[7];
          4'd8:seg6 <= segs[8];
          4'd9:seg6 <= segs[9];
          4'd10:seg6 <= segs[10];
          4'd11:seg6 <= segs[11];
          4'd12:seg6 <= segs[12];
          4'd13:seg6 <= segs[13];
          4'd14:seg6 <= segs[14];
          4'd15:seg6 <= segs[15];
          default: seg6 <= segs[16];
        endcase
        case (num7)
          4'd0:seg7 <= segs[0];
          4'd1:seg7 <= segs[1];
          4'd2:seg7 <= segs[2];
          4'd3:seg7 <= segs[3];
          4'd4:seg7 <= segs[4];
          4'd5:seg7 <= segs[5];
          4'd6:seg7 <= segs[6];
          4'd7:seg7 <= segs[7];
          4'd8:seg7 <= segs[8];
          4'd9:seg7 <= segs[9];
          4'd10:seg7 <= segs[10];
          4'd11:seg7 <= segs[11];
          4'd12:seg7 <= segs[12];
          4'd13:seg7 <= segs[13];
          4'd14:seg7 <= segs[14];
          4'd15:seg7 <= segs[15];
          default: seg7 <= segs[16];
        endcase
    end

endmodule
`timescale 1ns/1ps

module x7seg(
    input wire      [15:0]x,    //4位数据输入
    input wire      clk,        //时钟
    input wire      rst,        //复位
    output reg[6:0] a_to_g,     //段选信号
    output reg[3:0] an          //位选信号
);

    wire[1:0]       s;          //s的每次改变选择一个数码管进行输出显示
    reg[3:0]        digit;
    reg [19:0]      clkdiv;     //计数器，分频用
    assign s = clkdiv[19:18];   //每隔5.2ms将计数器s改变一次
    always @(*) begin           //每隔s的时间分配一次，将输入的值分配给digit
        case(s)
            0: digit = x[3:0];
            1: digit = x[7:4];
            2: digit = x[11:8];
            3: digit = x[15:12];
            default: digit = x[3:0];
        endcase
    end

    always @(*) begin
        case(digit)
            0: a_to_g = 7'b1111110;
            1: a_to_g = 7'b0110000;
            2: a_to_g = 7'b1101101;
            3: a_to_g = 7'b1111001;
            4: a_to_g = 7'b0110011;
            5: a_to_g = 7'b1011011;
            6: a_to_g = 7'b1011111;
            7: a_to_g = 7'b1110000;
            8: a_to_g = 7'b1111111;
            9: a_to_g = 7'b1111011;
            'hA: a_to_g = 7'b1110111;
            'hB: a_to_g = 7'b0011111;
            'hC: a_to_g = 7'b1001110;
            'hD: a_to_g = 7'b0111101;
            'hE: a_to_g = 7'b1001111;
            'hF: a_to_g = 7'b1000111;
            default: a_to_g = 7'b1111110;
        endcase
    end

    always @(*) begin        //每隔s段时间点亮一个数码管
        an = 4'b0000;
        an[s] = 1;
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst == 1) begin
            clkdiv <= 0;
        end else begin
            clkdiv <= clkdiv + 1;
        end
    end

endmodule

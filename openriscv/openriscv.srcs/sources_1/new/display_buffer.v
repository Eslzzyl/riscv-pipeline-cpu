`timescale 1ns/1ps

`include "define.v"

module display_buffer(
    input wire                  clk,
    input wire                  rst,
    input wire[`RegBus]         reg1,
    output reg[`RegBus]         display_reg1
);

    reg[`RegBus]    reg1_buf[0:20];
    reg[4:0]        counter_i = 0;
    reg[4:0]        counter_o = 0;
    reg[`RegBus]    last_reg1 = 0;

    reg [23:0] counter = 0;

    //在时钟周期的上升沿将reg1写入缓冲区索引为counter_i的位置
    always @(*) begin
        if (rst == `RstEnable) begin
            counter_i <= 5'h0;
        end else if (reg1 != last_reg1) begin
                reg1_buf[counter_i] <= reg1;
                counter_i <= counter_i + 1;
                last_reg1 <= reg1;
        end
    end

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            counter_o <= 5'h0;
            counter <= 24'h0;
            display_reg1 <= 32'h0;
        end
        if (reg1_buf[counter_o] != 32'h3E7 && counter == 24'd10) begin
            display_reg1 <= reg1_buf[counter_o];
            counter_o <= counter_o + 1;
            counter <= 24'h0;
        end
        counter <= counter + 1;
    end

endmodule

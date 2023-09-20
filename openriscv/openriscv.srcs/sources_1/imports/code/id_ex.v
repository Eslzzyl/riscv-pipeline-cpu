//ID/EX模块，功能十分简单，就是将译码的结果在clk上升沿传递给执行模块
`timescale 1ns/1ps

`include "define.v"

module id_ex(
    input wire                  clk,
    input wire                  rst,
    input wire[`RegBus]         id_reg1,
    input wire[`RegBus]         id_reg2,
    input wire[`RegAddrBus]     id_wd,
    input wire                  id_wreg,
    input wire[`InstBus]        id_inst,
    input wire[5:0]             stall,

    //传递到执行阶段的信息
    output reg[`RegBus]         ex_reg1,
    output reg[`RegBus]         ex_reg2,
    output reg[`RegAddrBus]     ex_wd,
    output reg                  ex_wreg,
    output reg[`InstBus]        ex_inst
);

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            ex_reg1         <= `ZeroWord;
            ex_reg2         <= `ZeroWord;
            ex_wd           <= `NOPRegAddr;
            ex_wreg         <= `WriteDisable;
            ex_inst         <= `EXE_NOP;
        end else if (stall[2] == `Stop && stall[3] == `NoStop) begin
            ex_reg1         <= `ZeroWord;
            ex_reg2         <= `ZeroWord;
            ex_wd           <= `NOPRegAddr;
            ex_wreg         <= `WriteDisable;
            ex_inst         <= `EXE_NOP;
        end else if (stall[2] == `NoStop) begin
            ex_reg1         <= id_reg1;
            ex_reg2         <= id_reg2;
            ex_wd           <= id_wd;
            ex_wreg         <= id_wreg;
            ex_inst         <= id_inst;
        end
    end

endmodule
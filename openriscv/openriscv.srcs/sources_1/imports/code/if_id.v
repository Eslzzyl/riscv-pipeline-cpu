`timescale 1ns/1ps

`include "define.v"

module if_id(
    input wire                  clk,
    input wire                  rst,

    //来自取指阶段的信号，InstBus表示指令宽度32
    input wire[`InstAddrBus]    if_pc,
    input wire[`InstBus]        if_inst,

    input wire[5:0]             stall,
    input wire                  branch_flag_i,

    //对应译码阶段的信号
    output reg[`InstAddrBus]    id_pc,
    output reg[`InstBus]        id_inst
);

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            id_pc <= `ZeroWord;         //复位时pc为0
            id_inst <= `ZeroWord;       //复位时指令也是0，其实就是nop
        //发生分支时，使用空指令冲刷流水线，覆盖当前指令
        //当前指令是分支指令的下一条指令，发生分支时可以直接丢弃
        end else if (branch_flag_i == `BranchEnable) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end else begin  //不发生分支时，正常向下传递指令
            id_pc <= if_pc;
            id_inst <= if_inst;
        end
    end

endmodule
`timescale 1ns/1ps

`include "define.v"

module pc_reg (
    input wire                  clk,
    input wire                  rst,

    //流水线暂停
    input wire[5:0]             stall,

    //分支的情况
    input wire[`InstAddrBus]    branch_addr_i,
    input wire                  branch_flag_i,

    output reg[`InstAddrBus]    pc,
    output reg                  ce
);

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            ce <= `ChipDisable;         //复位时指令存储器禁用
        end else begin
            ce <= `ChipEnable;
        end
    end

    always @(posedge clk) begin
        if (ce == `ChipDisable) begin
            pc <= 32'h0;
        end else if (branch_flag_i == `BranchEnable) begin
            pc <= branch_addr_i;   //分支时，pc置为分支目标地址
        end else begin
            pc <= pc + 4'h4;       //指令存储器使能时，pc每周期加4
        end
    end

endmodule
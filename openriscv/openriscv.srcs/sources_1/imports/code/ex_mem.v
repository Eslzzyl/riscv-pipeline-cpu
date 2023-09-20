`timescale 1ns/1ps

`include "define.v"

module ex_mem (
    input wire              clk,
    input wire              rst,

    //来自执行阶段的信息
    input wire[`RegAddrBus] ex_wd,
    input wire              ex_wreg,
    input wire[`RegBus]     ex_wdata,

    input wire[5:0]         stall,

    input wire[6:0]         opcode_i,
    input wire[2:0]         funct3_i,
    input wire[`RegBus]     mem_addr_i,
    input wire[`RegBus]     mem_data_i,
    input wire[1:0]         mem_rindex_i,
    input wire[1:0]         mem_windex_i,

    //送到访存阶段的信息
    output reg[`RegAddrBus] mem_wd,         //写回寄存器地址
    output reg              mem_wreg,       //写寄存器使能
    output reg[`RegBus]     mem_wdata,      //写回寄存器数据

    output reg[6:0]         opcode_o,
    output reg[2:0]         funct3_o,
    output reg[`RegBus]     mem_addr_o,     //访存地址
    output reg[`RegBus]     mem_data_o,     //访存数据
    output reg[1:0]         mem_rindex_o,   //访存索引
    output reg[1:0]         mem_windex_o    //访存索引
);

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            mem_wd      <= `NOPRegAddr;
            mem_wreg    <= `WriteDisable;
            mem_wdata   <= `ZeroWord;

            opcode_o    <= 3'b000;
            funct3_o    <= 7'b0000000;
            mem_addr_o  <= `ZeroWord;
            mem_data_o  <= `ZeroWord;
        end else if (stall[3] == `Stop && stall[4] == `NoStop) begin
            mem_wd      <= `NOPRegAddr;
            mem_wreg    <= `WriteDisable;
            mem_wdata   <= `ZeroWord;

            opcode_o    <= 7'b0000000;
            funct3_o    <= 3'b000;
            mem_addr_o  <= `ZeroWord;
            mem_data_o  <= `ZeroWord;
        end else if (stall[3] == `NoStop) begin
            mem_wd      <= ex_wd;
            mem_wreg    <= ex_wreg;
            mem_wdata   <= ex_wdata;

            opcode_o    <= opcode_i;
            funct3_o    <= funct3_i;
            mem_addr_o  <= mem_addr_i;
            mem_data_o  <= mem_data_i;
            mem_rindex_o <= mem_rindex_i;
            mem_windex_o <= mem_windex_i;
        end
    end

endmodule
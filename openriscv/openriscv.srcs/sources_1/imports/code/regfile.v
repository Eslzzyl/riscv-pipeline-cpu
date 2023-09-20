`timescale 1ns/1ps

`include "define.v"

module regfile (
    input wire                  clk,
    input wire                  rst,

    //写端口
    //注意这里的一些端口名和书上的不一样
    input wire                  we,
    input wire[`RegAddrBus]     wr_addr,
    input wire[`RegBus]         wr_data,

    //读端口1
    input wire                  re1,
    input wire[`RegAddrBus]     rd_addr1,
    output reg[`RegBus]         rd_data1,

    //读端口2
    input wire                  re2,
    input wire[`RegAddrBus]     rd_addr2,
    output reg[`RegBus]         rd_data2,

    output reg[`RegBus]         reg3_o
);

// ********** 定义32个32位寄存器 **********

reg [`RegBus] regs[0:`RegNum-1];

//寄存器堆需要特别注意的就是x0，它在MIPS和RISC-V都被硬连线到0，永远不能改变值

//写操作是时序逻辑，只在clk的上升沿写入寄存器
// ********** 写操作 **********

always @(posedge clk) begin
    if (rst == `RstDisable) begin       //如果没有复位
        //如果写允许，且写的不是x0，就执行写入。写入x0将不会有任何效果。
        if ((we == `WriteEnable) && (wr_addr != `RegNumLog2'h0)) begin
            regs[wr_addr] <= wr_data;
            if (wr_addr == 5'b00011) begin
                reg3_o <= wr_data;
            end
        end
    end
end

//注意读寄存器是组合逻辑，端口信号一旦变化立即给出结果。
//这是为了保证在译码阶段立即取到要读的值。如果这里弄成时序逻辑，译码阶段给出寄存器地址，等读出来时那边就进到执行阶段了。
// ********** 读端口1的读操作 **********

always @(*) begin
    if (rst == `RstEnable) begin        //复位时，输出32位全0
        rd_data1 <= `ZeroWord;
    end else if (rd_addr1 == `RegNumLog2'h0) begin
        rd_data1 <= `ZeroWord;          //如果读的是x0，仍然输出全0
    end else if ((rd_addr1 == wr_addr) && (we == `WriteEnable)
            && (re1 == `ReadEnable)) begin  //如果读的寄存器就是写的寄存器，就直接给出值
        rd_data1 <= wr_data;
    end else if (re1 == `ReadEnable) begin  //最后才是正常读寄存器的情况，要求读允许。
        rd_data1 <= regs[rd_addr1];
    end else begin
        rd_data1 <= `ZeroWord;          //其他情况给出全0
    end
end

// ********** 读端口2的读操作 **********

always @(*) begin
    if (rst == `RstEnable) begin
        rd_data2 <= `ZeroWord;
    end else if (rd_addr2 == `RegNumLog2'h0) begin
        rd_data2 <= `ZeroWord;
    end else if ((rd_addr2 == wr_addr) && (we == `WriteEnable)
            && (re2 == `ReadEnable)) begin
        rd_data2 <= wr_data;
    end else if (re2 == `ReadEnable) begin
        rd_data2 <= regs[rd_addr2];
    end else begin
        rd_data2 <= `ZeroWord;
    end
end

endmodule
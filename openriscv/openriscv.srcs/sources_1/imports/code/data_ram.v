`timescale 1ns/1ps

`include "define.v"

module data_ram (
    input wire                  clk,
    input wire                  ce,
    input wire                  we,
    (* DONT_TOUCH = "TRUE" *) input wire[`DataAddrBus]    addr,
    input wire[`DataBus]        data_i,
    output reg[`DataBus]        data_o
);

    reg[`DataBus] data_mem[0:`DataMemNum-1];

    //写操作
    always @(posedge clk) begin
        if (ce == `ChipEnable && we == `WriteEnable) begin
            data_mem[addr] <= data_i;
        end
    end

    //读操作
    always @(*) begin
        if (ce == `ChipDisable) begin
            data_o <= `ZeroWord;
        end else begin
            data_o <= data_mem[addr];
        end
    end

endmodule
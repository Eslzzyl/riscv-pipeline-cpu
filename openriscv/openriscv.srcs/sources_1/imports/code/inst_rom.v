`timescale 1ns/1ps

`include "define.v"

module inst_rom(
    input wire                  rst,
    input wire                  ce,
    (* DONT_TOUCH = "TRUE" *) input wire[`InstAddrBus]    addr,
    output reg[`InstBus]        inst
);

    //定义一个数组，大小是InstMemNum，每个元素宽度是InstBus
    reg[`InstBus] inst_mem[0:`InstMemNum-1];

    //使用文件inst_rom.txt初始化指令存储器
    //initial是面向仿真的，综合器一般不支持，需要的时候要改
    initial begin
        //readmemh是verilog的系统函数
        $readmemh("D:/WorkSpace/HardwareDesign/openriscv/openriscv.srcs/sources_1/imports/code/inst_rom.txt", inst_mem);
    end

    //当复位信号无效时，根据输入的地址，给出指令存储器ROM中对应的元素
    always @(*) begin
        if (rst == `RstEnable) begin
            // inst_mem[0][`InstBus] = 32'h93001000;
            // inst_mem[1][`InstBus] = 32'h13011000;
            // inst_mem[2][`InstBus] = 32'h93011000;
            // inst_mem[3][`InstBus] = 32'h1305a000;
            // inst_mem[4][`InstBus] = 32'hb3812000;
            // inst_mem[5][`InstBus] = 32'h93000100;
            // inst_mem[6][`InstBus] = 32'h13810100;
            // inst_mem[7][`InstBus] = 32'he3eaa1fe;
            // inst_mem[8][`InstBus] = 32'h9301703e;
            inst <= `ZeroWord;
        end else if (ce == `ChipDisable) begin
            inst <= `ZeroWord;
        end else begin
            //寻址是按照字节的，但是指令是按照字的，所以要除以4（右移两位）。注意字节顺序。
            //inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
            inst <= {
                inst_mem[addr[`InstMemNumLog2+1:2]][7:0],
                inst_mem[addr[`InstMemNumLog2+1:2]][15:8],
                inst_mem[addr[`InstMemNumLog2+1:2]][23:16],
                inst_mem[addr[`InstMemNumLog2+1:2]][31:24]
            };
        end
    end

endmodule
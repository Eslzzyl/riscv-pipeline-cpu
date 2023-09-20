`include "define.v"

`timescale 1ns/1ps

module openriscv_min_sopc_tb();
    
    reg CLOCK_50;
    reg rst;

    initial begin
        CLOCK_50 = 1'b0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end

    initial begin
        // $dumpfile("wave.vcd");        //生成的vcd文件名称
        // $dumpvars(0, openriscv_min_sopc_tb);    //tb模块名称

        rst = `RstDisable;
        #95 rst = `RstEnable;
        #3000 $finish;
    end

    openriscv_min_sopc openriscv_min_sopc0(
        .clk(CLOCK_50),
        .rst_n(rst)
    );

endmodule
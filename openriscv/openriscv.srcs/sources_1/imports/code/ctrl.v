`timescale 1ns/1ps

`include "define.v"

module ctrl(
    input wire                  rst,
    input wire                  stall_req_from_id,
    input wire                  stall_req_from_ex,
    output reg[5:0]             stall
);

    //对流水线暂停信号stall的说明：
    //stall[0]表示取指地址PC是否保持不变，为1表示不变
    //stall[1]表示流水线取指阶段是否保持暂停，为1表示暂停
    //stall[2]表示流水线译码阶段是否保持暂停，为1表示暂停
    //stall[3]表示流水线执行阶段是否保持暂停，为1表示暂停
    //stall[4]表示流水线访存阶段是否保持暂停，为1表示暂停
    //stall[5]表示流水线写回阶段是否保持暂停，为1表示暂停
    //根据我们的设计，只有译码和执行阶段可能产生暂停，如果暂停，之前的各个阶段也需要暂停，之后的阶段可以正常运行
    //注意stall是高位在前低位在后的

    always @(*) begin
        if (rst == `RstEnable) begin
            stall <= 6'b0;
        end else if (stall_req_from_id == `Stop) begin
            stall <= 6'b000111;
        end else if (stall_req_from_ex == `Stop) begin
            stall <= 6'b001111;
        end else begin
            stall <= 6'b0;
        end
    end

endmodule
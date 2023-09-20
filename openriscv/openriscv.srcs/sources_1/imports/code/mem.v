`timescale 1ns/1ps

`include "define.v"

module mem (
    input wire                  rst,

    //来自执行阶段的信息
    input wire[`RegAddrBus]     wd_i,
    input wire                  wreg_i,
    input wire[`RegBus]         wdata_i,

    //来自执行阶段的Load/Store指令的信息
    input wire[6:0]             opcode_i,
    input wire[2:0]             funct3_i,
    input wire[`RegBus]         mem_addr_i,
    input wire[`RegBus]         mem_data_i,
    input wire[1:0]             mem_rindex_i,
    input wire[1:0]             mem_windex_i,

    //来自数据RAM的信息
    input wire[`RegBus]         ram_data_i,

    //访存阶段的结果
    output reg[`RegAddrBus]     wd_o,
    output reg                  wreg_o,
    output reg[`RegBus]         wdata_o,

    //送到数据RAM的信息
    output reg[`DataAddrBus]    ram_addr_o,
    output reg[`DataBus]        ram_data_o,
    output reg                  ram_ce_o,
    output reg                  ram_we_o
);

    always @(*) begin
        if (rst == `RstEnable) begin
            wd_o    <= `NOPRegAddr;
            wreg_o  <= `WriteDisable;
            wdata_o <= `ZeroWord;
            ram_addr_o <= `ZeroWord;
            ram_data_o <= `ZeroWord;
            ram_ce_o <= `ChipDisable;
            ram_we_o <= `WriteDisable;
        end else begin
            wd_o    <= wd_i;
            wreg_o  <= wreg_i;
            ram_addr_o <= mem_addr_i;
            case(opcode_i)
                `INST_TYPE_L: begin
                    ram_ce_o <= `ChipEnable;
                    ram_data_o <= `ZeroWord;
                    ram_we_o <= `WriteDisable;
                    case(funct3_i)
                        `EXE_LB: begin
                            case(mem_rindex_i)
                                2'b00: begin
                                    wdata_o <= {{24{ram_data_i[7]}}, ram_data_i[7:0]};
                                end
                                2'b01: begin
                                    wdata_o <= {{24{ram_data_i[15]}}, ram_data_i[15:8]};
                                end
                                2'b10: begin
                                    wdata_o <= {{24{ram_data_i[23]}}, ram_data_i[23:16]};
                                end
                                default: begin
                                    wdata_o <= {{24{ram_data_i[31]}}, ram_data_i[31:24]};
                                end
                            endcase
                        end
                        `EXE_LH: begin
                            case(mem_rindex_i)
                                2'b00: begin
                                    wdata_o <= {{16{ram_data_i[15]}}, ram_data_i[15:0]};
                                end
                                default: begin
                                    wdata_o <= {{16{ram_data_i[31]}}, ram_data_i[31:16]};
                                end
                            endcase
                        end
                        `EXE_LW: begin
                            wdata_o <= ram_data_i;
                        end
                        `EXE_LBU: begin
                            case(mem_rindex_i)
                                2'b00: begin
                                    wdata_o <= {{24{1'b0}}, ram_data_i[7:0]};
                                end
                                2'b01: begin
                                    wdata_o <= {{24{1'b0}}, ram_data_i[15:8]};
                                end
                                2'b10: begin
                                    wdata_o <= {{24{1'b0}}, ram_data_i[23:16]};
                                end
                                default: begin
                                    wdata_o <= {{24{1'b0}}, ram_data_i[31:24]};
                                end
                            endcase
                        end
                        `EXE_LHU: begin
                            case(mem_rindex_i)
                                2'b00: begin
                                    wdata_o <= {{16{1'b0}}, ram_data_i[15:0]};
                                end
                                default: begin
                                    wdata_o <= {{16{1'b0}}, ram_data_i[31:16]};
                                end
                            endcase
                        end
                    endcase
                end
                `INST_TYPE_S: begin
                    ram_ce_o <= `ChipEnable;
                    wdata_o <= `ZeroWord;
                    ram_we_o <= `WriteEnable;
                    case(funct3_i)
                        `EXE_SB: begin
                            case(mem_windex_i)
                                2'b00: begin
                                    ram_data_o <= {{24{1'b0}}, mem_data_i[7:0]};
                                end
                                2'b01: begin
                                    ram_data_o <= {{24{1'b0}}, mem_data_i[15:8]};
                                end
                                2'b10: begin
                                    ram_data_o <= {{24{1'b0}}, mem_data_i[23:16]};
                                end
                                default: begin
                                    ram_data_o <= {{24{1'b0}}, mem_data_i[31:24]};
                                end
                            endcase
                        end
                        `EXE_SH: begin
                            case(mem_windex_i)
                                2'b00: begin
                                    ram_data_o <= {{16{1'b0}}, mem_data_i[15:0]};
                                end
                                default: begin
                                    ram_data_o <= {{16{1'b0}}, mem_data_i[31:16]};
                                end
                            endcase
                        end
                        `EXE_SW: begin
                            ram_data_o <= mem_data_i;
                        end
                    endcase
                end
                default: begin
                    ram_ce_o <= `ChipDisable;
                    wdata_o <= wdata_i;
                end
            endcase
        end
    end

endmodule
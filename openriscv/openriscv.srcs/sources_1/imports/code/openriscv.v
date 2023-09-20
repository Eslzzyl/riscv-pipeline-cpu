`timescale 1ns/1ps

`include "define.v"

module openriscv(
    (* DONT_TOUCH = "TRUE" *) input wire                  clk,
    input wire                  rst,

    input wire[`RegBus]         rom_data_i,
    output wire[`InstAddrBus]   rom_addr_o,
    output wire                 rom_ce_o,

    input wire[`DataBus]        ram_data_i,
    output wire[`DataAddrBus]   ram_addr_o,
    output wire[`DataBus]       ram_data_o,
    output wire                 ram_ce_o,
    output wire                 ram_we_o,

    output wire[`RegBus]        display_reg
);

    //连接IF/ID模块与译码阶段ID模块的变量
    wire[`InstAddrBus]      pc;
    wire[`InstAddrBus]      id_pc_i;
    wire[`InstBus]          id_inst_i;

    //连接译码阶段ID模块输出与ID/EX模块输入的变量
    wire[`RegBus]           id_reg1_o;
    wire[`RegBus]           id_reg2_o;
    wire                    id_wreg_o;
    wire[`RegAddrBus]       id_wd_o;
    wire[`InstBus]          id_inst_o;

    //连接ID/EX模块输出与执行阶段EX模块输入的变量
    wire[`RegBus]           ex_reg1_i;
    wire[`RegBus]           ex_reg2_i;
    wire                    ex_wreg_i;
    wire[`RegAddrBus]       ex_wd_i;
    wire[`InstBus]          ex_inst_i;

    //连接执行阶段EX模块输出与EX/MEM模块输入的变量
    wire                    ex_wreg_o;
    wire[`RegAddrBus]       ex_wd_o;
    wire[`RegBus]           ex_wdata_o;

    wire[6:0]               ex_opcode_o;
    wire[2:0]               ex_funct3_o;
    wire[`RegBus]           ex_mem_addr_o;
    wire[`RegBus]           ex_mem_data_o;
    wire[1:0]               ex_mem_rindex_o;
    wire[1:0]               ex_mem_windex_o;

    //连接EX/MEM模块输出与访存阶段MEM模块输入的变量
    wire                    mem_wreg_i;
    wire[`RegAddrBus]       mem_wd_i;
    wire[`RegBus]           mem_wdata_i;

    wire[6:0]               mem_opcode_i;
    wire[2:0]               mem_funct3_i;
    wire[`RegBus]           mem_addr_i;
    wire[`RegBus]           mem_data_i;
    wire[1:0]               mem_rindex_i;
    wire[1:0]               mem_windex_i;

    //连接访存阶段MEM模块输出与MEM/WB模块输入的变量
    wire                    mem_wreg_o;
    wire[`RegAddrBus]       mem_wd_o;
    wire[`RegBus]           mem_wdata_o;

    //连接MEM/WB模块输出与回写阶段WB模块输入的变量
    wire                    wb_wreg_i;
    wire[`RegAddrBus]       wb_wd_i;
    wire[`RegBus]           wb_wdata_i;

    //连接译码阶段ID模块与通用寄存器Regfile模块的变量
    wire                    reg1_read;
    wire                    reg2_read;
    wire[`RegBus]           reg1_data;
    wire[`RegBus]           reg2_data;
    wire[`RegAddrBus]       reg1_addr;
    wire[`RegAddrBus]       reg2_addr;

    wire[5:0]               stall;
    wire                    stall_req_from_id;
    wire                    stall_req_from_ex;

    wire                    branch_flag;
    wire[`InstAddrBus]      branch_addr;

    wire                    pre_inst_is_load;

    wire[`RegBus]           reg3_data;

    //pc_reg例化
    pc_reg pc_reg0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .pc(pc),
        .ce(rom_ce_o_link),

        .branch_flag_i(branch_flag),
        .branch_addr_i(branch_addr)
    );

    assign rom_addr_o = pc;     //指令存储器输入地址就是pc的值
    assign rom_ce_o = rom_ce_o_link;

    //IF/ID模块例化
    if_id if_id0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .if_pc(pc),
        .if_inst(rom_data_i),
        .branch_flag_i(branch_flag),
        .id_pc(id_pc_i),
        .id_inst(id_inst_i)
    );

    //译码阶段ID模块例化
    id id0(
        .rst(rst),
        .pc_i(id_pc_i),
        .inst_i(id_inst_i),

        //处于执行阶段的指令要写入的目的寄存器信息
        .ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),

        //处于访存阶段的指令要写入的目的寄存器信息
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),

        //来自Regfile模块的输入
        .reg1_data_i(reg1_data),
        .reg2_data_i(reg2_data),

        //送到Regfile模块的信息
        .reg1_read_o(reg1_read),
        .reg2_read_o(reg2_read),
        .reg1_addr_o(reg1_addr),
        .reg2_addr_o(reg2_addr),

        //送到ID/EX模块的信息
        .reg1_o(id_reg1_o),
        .reg2_o(id_reg2_o),
        .wd_o(id_wd_o),
        .wreg_o(id_wreg_o),
        .inst_o(id_inst_o),

        .stall_req_from_id(stall_req_from_id),

        //分支
        .branch_flag_o(branch_flag),
        .branch_addr_o(branch_addr),

        .is_load_i(pre_inst_is_load)
    );

    //通用寄存器Regfile模块例化
    regfile regfile1(
        .clk(clk),
        .rst(rst),
        .we(wb_wreg_i),
        .wr_addr(wb_wd_i),
        .wr_data(wb_wdata_i),
        .re1(reg1_read),
        .rd_addr1(reg1_addr),
        .rd_data1(reg1_data),
        .re2(reg2_read),
        .rd_addr2(reg2_addr),
        .rd_data2(reg2_data),

        .reg3_o(reg3_data)
    );

    //ID/EX模块例化
    id_ex id_ex0(
        .clk(clk),
        .rst(rst),

        .stall(stall),

        //从译码阶段ID模块传递过来的信息
        .id_reg1(id_reg1_o),
        .id_reg2(id_reg2_o),
        .id_wd(id_wd_o),
        .id_wreg(id_wreg_o),
        .id_inst(id_inst_o),

        //传递到执行阶段EX模块的信息
        .ex_reg1(ex_reg1_i),
        .ex_reg2(ex_reg2_i),
        .ex_wd(ex_wd_i),
        .ex_wreg(ex_wreg_i),
        .ex_inst(ex_inst_i)
    );

    //EX模块例化
    ex ex0(
        .rst(rst),

        //从ID/EX模块传递过来的信息
        .reg1_i(ex_reg1_i),
        .reg2_i(ex_reg2_i),
        .wd_i(ex_wd_i),
        .wreg_i(ex_wreg_i),
        .inst_i(ex_inst_i),

        //输出到EX/MEM模块的信息
        .wd_o(ex_wd_o),
        .wreg_o(ex_wreg_o),
        .wdata_o(ex_wdata_o),

        .opcode_o(ex_opcode_o),
        .funct3_o(ex_funct3_o),
        .mem_addr_o(ex_mem_addr_o),
        .mem_data_o(ex_mem_data_o),
        .mem_rindex_o(ex_mem_rindex_o),
        .mem_windex_o(ex_mem_windex_o),

        .stall_req_from_ex(stall_req_from_ex),

        .is_load_o(pre_inst_is_load)
    );

    //EX/MEM模块例化
    ex_mem ex_mem0(
        .clk(clk),
        .rst(rst),

        .stall(stall),

        //来自执行阶段EX模块的信息
        .ex_wd(ex_wd_o),
        .ex_wreg(ex_wreg_o),
        .ex_wdata(ex_wdata_o),

        .opcode_i(ex_opcode_o),
        .funct3_i(ex_funct3_o),
        .mem_addr_i(ex_mem_addr_o),
        .mem_data_i(ex_mem_data_o),
        .mem_rindex_i(ex_mem_rindex_o),
        .mem_windex_i(ex_mem_windex_o),

        //送到访存阶段MEM模块的信息
        .mem_wd(mem_wd_i),
        .mem_wreg(mem_wreg_i),
        .mem_wdata(mem_wdata_i),

        .opcode_o(mem_opcode_i),
        .funct3_o(mem_funct3_i),
        .mem_addr_o(mem_addr_i),
        .mem_data_o(mem_data_i),
        .mem_rindex_o(mem_rindex_i),
        .mem_windex_o(mem_windex_i)
    );

    //访存阶段MEM模块例化
    mem mem0(
        .rst(rst),

        //来自EX/MEM模块的信息
        .wd_i(mem_wd_i),
        .wreg_i(mem_wreg_i),
        .wdata_i(mem_wdata_i),

        //送到MEM/WB模块的信息
        .wd_o(mem_wd_o),
        .wreg_o(mem_wreg_o),
        .wdata_o(mem_wdata_o),

        .opcode_i(mem_opcode_i),
        .funct3_i(mem_funct3_i),
        .mem_addr_i(mem_addr_i),
        .mem_data_i(mem_data_i),
        .mem_rindex_i(mem_rindex_i),
        .mem_windex_i(mem_windex_i),

        .ram_data_i(ram_data_i),

        .ram_addr_o(ram_addr_o),
        .ram_data_o(ram_data_o),
        .ram_ce_o(ram_ce_o),
        .ram_we_o(ram_we_o)
    );

    mem_wb mem_wb0(
        .clk(clk),
        .rst(rst),

        .stall(stall),

        //来自访存阶段MEM模块的信息
        .mem_wd(mem_wd_o),
        .mem_wreg(mem_wreg_o),
        .mem_wdata(mem_wdata_o),

        //送到写回阶段WB模块的信息
        .wb_wd(wb_wd_i),
        .wb_wreg(wb_wreg_i),
        .wb_wdata(wb_wdata_i)
    );

    ctrl ctrl0(
        .rst(rst),
        .stall_req_from_id(stall_req_from_id),
        .stall_req_from_ex(stall_req_from_ex),
        .stall(stall)
    );

    display_buffer display_buffer0(
        .clk(clk),
        .rst(rst),
        .reg1(reg3_data),
        .display_reg1(display_reg)
    );

endmodule
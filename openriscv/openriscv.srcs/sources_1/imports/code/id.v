`timescale 1ns/1ps

`include "define.v"

module id (
    input wire                  rst,            //复位信号
    input wire[`InstAddrBus]    pc_i,           //PC寄存器的值
    input wire[`InstAddrBus]    inst_i,         //当前指令

    //处于执行阶段的指令的运算结果
    input wire                  ex_wreg_i,      //写使能
    input wire[`RegAddrBus]     ex_wd_i,        //写回寄存器地址
    input wire[`RegBus]         ex_wdata_i,     //写回寄存器的数据

    input wire                  is_load_i,      //从ex模块传入的信号，指示前一条指令是不是load

    //处于访存阶段的指令的运算结果
    input wire                  mem_wreg_i,     //写使能
    input wire[`RegAddrBus]     mem_wd_i,       //写回寄存器地址
    input wire[`RegBus]         mem_wdata_i,    //写回寄存器的数据

    //读取的Regfile的值
    input wire[`RegBus]         reg1_data_i,    //Regfile读端口1的值
    input wire[`RegBus]         reg2_data_i,    //Regfile读端口2的值

    //输出到Regfile的信息
    output reg                  reg1_read_o,    //Regfile读端口1使能
    output reg                  reg2_read_o,    //Regfile读端口2使能
    output reg[`RegAddrBus]     reg1_addr_o,    //Regfile读端口1地址
    output reg[`RegAddrBus]     reg2_addr_o,    //Regfile读端口2地址

    //送到执行阶段的信息
    output reg[`RegBus]         reg1_o,         //Regfile读端口1的值
    output reg[`RegBus]         reg2_o,         //Regfile读端口2的值
    output reg[`RegAddrBus]     wd_o,           //写回寄存器地址
    output reg                  wreg_o,         //写使能
    output reg[`InstBus]        inst_o,         //指令

    //流水线暂停信号
    output wire                 stall_req_from_id,

    //分支
    output reg                  branch_flag_o,  //分支标志
    output reg[`InstAddrBus]    branch_addr_o   //分支地址
);

    wire[6:0] opcode = inst_i[6:0];
    wire[2:0] funct3 = inst_i[14:12];
    wire[6:0] funct7 = inst_i[31:25];
    wire[4:0] rd = inst_i[11:7];
    wire[4:0] rs1 = inst_i[19:15];
    wire[4:0] rs2 = inst_i[24:20];

    wire[`InstAddrBus] type_b_imm;

    wire[`RegBus] pc_plus_4;
    wire op1_greater_than_op2_singned;
    wire op1_greater_than_op2_unsigned;
    wire op1_equal_to_op2;

    reg stallreq_for_reg1_loadrelate;   //要读的寄存器1是否与前一条指令存在load相关
    reg stallreq_for_reg2_loadrelate;   //要读的寄存器2是否与前一条指令存在load相关

    assign type_b_imm = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};

    assign stall_req_from_id = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate | opcode == `INST_TYPE_B;

    assign pc_plus_4 = pc_i + 4;
    //有符号数比较
    assign op1_greater_than_op2_singned     =   ($signed(reg1_o) >= $signed(reg2_o));
    //无符号数比较
    assign op1_greater_than_op2_unsigned    =   (reg1_o >= reg2_o);
    //相等
    assign op1_equal_to_op2                 =   (reg1_o == reg2_o);

    //保存指令执行需要的立即数
    reg[`RegBus]    imm;

    //指示指令是否有效
    reg instvalid;

    // ********** 指令译码 **********

    always @(*) begin
        inst_o              <= inst_i;
        if (rst == `RstEnable) begin
            wd_o            <= `NOPRegAddr;
            wreg_o          <= `WriteDisable;
            instvalid       <= `InstInvalid;
            reg1_read_o     <= 1'b0;
            reg2_read_o     <= 1'b0;
            reg1_addr_o     <= `NOPRegAddr;
            reg2_addr_o     <= `NOPRegAddr;
            imm             <= `ZeroWord;
            branch_flag_o   <= `BranchDisable;
            branch_addr_o   <= `ZeroWord;
        end else begin
            wd_o            <= rd;
            wreg_o          <= `WriteDisable;
            instvalid       <= `InstInvalid;
            reg1_read_o     <= 1'b0;
            reg2_read_o     <= 1'b0;
            reg1_addr_o     <= rs1;
            reg2_addr_o     <= rs2;     //rs2不是所有指令都需要的，对于I型指令，rs2是立即数的一部分
            //这里是默认情况，后面如果要改立即数，会覆盖。如果用不到立即数就不改了
            imm             <= `ZeroWord;
            branch_flag_o   <= `BranchDisable;
            branch_addr_o   <= `ZeroWord;

            case (opcode)
                `INST_TYPE_I: begin     //I类指令
                    case(funct3)
                        `EXE_ADDI, `EXE_ORI, `EXE_XORI, `EXE_ANDI, `EXE_SLLI, `EXE_SRLI,
                        `EXE_SLTI, `EXE_SLTIU: begin
                            wreg_o      <= `WriteEnable;    //写回使能
                            reg1_read_o <= 1'b1;            //需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b0;            //不需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstValid;      //指令有效
                            imm         <= {16'h0, inst_i[31:20]};  //取得立即数。I类指令的立即数位置是31:20
                            wd_o        <= rd;              //写回的寄存器地址
                        end
                        default: begin
                            wreg_o      <= `WriteDisable;   //写回禁止
                            reg1_read_o <= 1'b0;            //不需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b0;            //不需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstInvalid;    //指令无效
                            wd_o        <= `NOPRegAddr;     //写回的寄存器地址为0
                        end
                    endcase
                end
                `INST_TYPE_R: begin     //R类指令
                    case(funct3)
                        `EXE_ADD_SUB, `EXE_SLL, `EXE_SLT, `EXE_SLTU, `EXE_XOR, `EXE_SRLI,
                        `EXE_OR, `EXE_AND: begin
                            wreg_o      <= `WriteEnable;    //写回使能
                            reg1_read_o <= 1'b1;            //需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b1;            //需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstValid;      //指令有效
                            wd_o        <= rd;              //写回的寄存器地址
                        end
                        default: begin
                            wreg_o      <= `WriteDisable;   //写回禁止
                            reg1_read_o <= 1'b0;            //不需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b0;            //不需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstInvalid;    //指令无效
                            wd_o        <= `NOPRegAddr;     //写回的寄存器地址为0
                        end
                    endcase
                end
                `INST_TYPE_B: begin     //B类指令
                    case(funct3)
                        `EXE_BEQ: begin
                            wreg_o      <= `WriteDisable;   //写回禁止
                            reg1_read_o <= 1'b1;            //需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b1;            //需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstValid;      //指令有效
                            //BEQ指令，当rs1==rs2时进行分支
                            branch_flag_o <= op1_equal_to_op2;
                            branch_addr_o <= (type_b_imm + pc_i) & {32{op1_equal_to_op2}}; //分支地址
                        end
                        `EXE_BNE: begin
                            wreg_o      <= `WriteDisable;   //写回禁止
                            reg1_read_o <= 1'b1;            //需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b1;            //需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstValid;      //指令有效
                            //BNE指令，当rs1!=rs2时进行分支
                            branch_flag_o <= ~op1_equal_to_op2;
                            branch_addr_o <= (type_b_imm + pc_i) & {32{~op1_equal_to_op2}}; //分支地址
                        end
                        `EXE_BLT: begin
                            wreg_o      <= `WriteDisable;   //写回禁止
                            reg1_read_o <= 1'b1;            //需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b1;            //需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstValid;      //指令有效
                            //BLT指令，当rs1 < rs2时进行分支（有符号比较）
                            branch_flag_o <= ~op1_greater_than_op2_singned;
                            branch_addr_o <= (type_b_imm + pc_i) & {32{~op1_greater_than_op2_singned}}; //分支地址
                        end
                        `EXE_BLTU: begin
                            wreg_o      <= `WriteDisable;   //写回禁止
                            reg1_read_o <= 1'b1;            //需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b1;            //需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstValid;      //指令有效
                            //BLTU指令，当rs1 < rs2时进行分支（无符号比较）
                            branch_flag_o <= ~op1_greater_than_op2_unsigned;
                            branch_addr_o <= (type_b_imm + pc_i) & {32{~op1_greater_than_op2_unsigned}}; //分支地址
                        end
                        `EXE_BGE: begin
                            wreg_o      <= `WriteDisable;   //写回禁止
                            reg1_read_o <= 1'b1;            //需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b1;            //需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstValid;      //指令有效
                            //BGE指令，当rs1 >= rs2时分支（有符号比较）
                            branch_flag_o <= op1_greater_than_op2_singned;
                            branch_addr_o <= (type_b_imm + pc_i) & {32{op1_greater_than_op2_singned}}; //分支地址
                        end
                        `EXE_BGEU: begin
                            wreg_o      <= `WriteDisable;   //写回禁止
                            reg1_read_o <= 1'b1;            //需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b1;            //需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstValid;      //指令有效
                            //BGEU指令，当rs1 >= rs2时分支（无符号比较）
                            branch_flag_o <= op1_greater_than_op2_unsigned;
                            branch_addr_o <= (type_b_imm + pc_i) & {32{op1_greater_than_op2_unsigned}}; //分支地址
                        end
                        default: begin
                            wreg_o      <= `WriteDisable;   //写回禁止
                            reg1_read_o <= 1'b0;            //不需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b0;            //不需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstInvalid;    //指令无效
                            branch_flag_o <= `BranchDisable;//分支禁止
                        end
                    endcase
                end
                `INST_TYPE_L: begin     //L类指令
                    case(funct3)
                        `EXE_LB, `EXE_LH, `EXE_LW, `EXE_LBU, `EXE_LHU: begin
                            wreg_o      <= `WriteEnable;    //写回使能
                            reg1_read_o <= 1'b1;            //需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b0;            //不需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstValid;      //指令有效
                            imm         <= {16'h0, inst_i[31:20]}; //立即数
                            wd_o        <= rd;              //写回寄存器地址
                        end
                        default: begin
                            wreg_o      <= `WriteDisable;   //写回禁止
                            reg1_read_o <= 1'b0;            //不需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b0;            //不需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstInvalid;    //指令无效
                            wd_o        <= `NOPRegAddr;     //写回寄存器地址
                        end
                    endcase
                end
                `INST_TYPE_S: begin     //S类指令
                    case(funct3)
                        `EXE_SB, `EXE_SW, `EXE_SH: begin
                            //注意wreg_o控制的是通用寄存器写，store类指令写的是数据RAM，所以wreg_o是禁止的
                            wreg_o      <= `WriteDisable;   //写回禁止
                            reg1_read_o <= 1'b1;            //需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b1;            //需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstValid;      //指令有效
                            //store类指令需要用到立即数，但是两个输出端口都被寄存器占掉了，所以到EX段再截取立即数
                            //这也是一个很野的写法
                        end
                        default: begin
                            wreg_o      <= `WriteDisable;   //写回禁止
                            reg1_read_o <= 1'b0;            //不需要通过Regfile的读端口1读取寄存器值
                            reg2_read_o <= 1'b0;            //不需要通过Regfile的读端口2读取寄存器值
                            instvalid   <= `InstInvalid;    //指令无效
                        end
                    endcase
                end
                //有关jal指令的解释可以看这个链接
                //https://stackoverflow.com/questions/53036468/what-is-the-definition-of-jal-in-risc-v-and-how-does-one-use-it
                `EXE_JAL: begin
                    wreg_o      <= `WriteEnable;    //写回使能
                    reg1_read_o <= 1'b0;            //不需要通过Regfile的读端口1读取寄存器值
                    reg2_read_o <= 1'b0;            //不需要通过Regfile的读端口2读取寄存器值
                    instvalid   <= `InstValid;      //指令有效
                    branch_addr_o <= {12'h0, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0} + pc_i;  //取得立即数。JAL指令的立即数位置是31,19:12,20,30:21
                    branch_flag_o <= `BranchEnable; //分支使能
                    //这个写法很野，正规的方法都要增加ID模块的输出引脚，但是我懒
                    //JAL的行为是，将指令中的立即数字段加上当前PC作为写回PC的值，同时将PC+4保存在rd里
                    imm        <= pc_plus_4;       //取得PC+4
                    wd_o        <= rd;              //写回的寄存器地址
                end
                `EXE_JALR: begin
                    wreg_o      <= `WriteEnable;    //写回使能
                    reg1_read_o <= 1'b1;            //需要通过Regfile的读端口1读取寄存器值
                    reg2_read_o <= 1'b0;            //不需要通过Regfile的读端口2读取寄存器值
                    instvalid   <= `InstValid;      //指令有效
                    branch_addr_o <= {inst_i[31:20], 1'b0} + reg1_o;  //取得立即数。JALR指令的立即数位置是31:20
                    branch_flag_o <= `BranchEnable; //分支使能
                    //JALR的行为是，将指令中的立即数加上rs1的值作为写回PC的地址，同时将PC+4保存在rd里
                    imm         <= pc_plus_4;       //取得PC+4
                    wd_o        <= rd;              //写回的寄存器地址
                end
                `EXE_NOP: begin
                    wreg_o      <= `WriteDisable;   //写回禁止
                    reg1_read_o <= 1'b0;            //不需要通过Regfile的读端口1读取寄存器值
                    reg2_read_o <= 1'b0;            //不需要通过Regfile的读端口2读取寄存器值
                    instvalid   <= `InstValid;      //指令有效
                    wd_o        <= `NOPRegAddr;     //写回的寄存器地址为0
                end
                default: begin
                end
            endcase
        end     //if
    end     //always

    // ********** 确定源操作数1 **********

    always @(*) begin
        stallreq_for_reg1_loadrelate <= `NoStop;
        if (rst == `RstEnable) begin
            reg1_o <= `ZeroWord;
        end else if (is_load_i == 1'b1 && ex_wd_i == reg1_addr_o
            && reg1_read_o == 1'b1) begin
            stallreq_for_reg1_loadrelate <= `Stop;
        //接下来的两种情况是数据前推相关的操作
        end else if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1)
            && (ex_wd_i == reg1_addr_o)) begin
            reg1_o <= ex_wdata_i;       //reg1的值是EX阶段写回的值
        end else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1)
            && (mem_wd_i == reg1_addr_o)) begin
            reg1_o <= mem_wdata_i;      //reg1的值是访存阶段写回的值
        end else if (reg1_read_o == 1'b1) begin
            reg1_o <= reg1_data_i;      //Regfile读端口1的输出值
        end else if (reg1_read_o == 1'b0) begin
            reg1_o <= imm;             //立即数
        end else begin
            reg1_o <= `ZeroWord;
        end
    end

    // ********** 确定源操作数2 **********

    always @(*) begin
        stallreq_for_reg2_loadrelate <= `NoStop;
        if (rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
        end else if (is_load_i == 1'b1 && ex_wd_i == reg2_addr_o
            && reg2_read_o == 1'b1) begin
            stallreq_for_reg2_loadrelate <= `Stop;
        //接下来的两种情况是数据前推相关的操作
        end else if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1)
            && (ex_wd_i == reg2_addr_o)) begin
            reg2_o <= ex_wdata_i;       //reg2的值是EX阶段写回的值
        end else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1)
            && (mem_wd_i == reg2_addr_o)) begin
            reg2_o <= mem_wdata_i;      //reg2的值是访存阶段写回的值
        end else if (reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;      //Regfile读端口2的输出值
        end else if (reg2_read_o == 1'b0) begin
            reg2_o <= imm;             //立即数
        end else begin
            reg2_o <= `ZeroWord;
        end
    end

endmodule
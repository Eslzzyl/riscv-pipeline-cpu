//***************** 全局宏定义 ***********************
`define RstEnable                   1'b1        //复位信号有效
`define RstDisable                  1'b0        //复位信号无效
`define ZeroWord                    32'b0       //32位全0
`define WriteEnable                 1'b1        //写使能
`define WriteDisable                1'b0        //写禁止
`define ReadEnable                  1'b1        //读使能
`define ReadDisable                 1'b0        //读禁止

`define InstValid                   1'b0        //指令有效
`define InstInvalid                 1'b1        //指令无效
`define True_v                      1'b1        //逻辑真
`define False_v                     1'b0        //逻辑假
`define ChipEnable                  1'b1        //芯片使能
`define ChipDisable                 1'b0        //芯片禁止

//流水线暂停
`define Stop                        1'b1            //流水线暂停
`define NoStop                      1'b0            //流水线不暂停

//分支
`define BranchEnable                1'b1            //分支
`define BranchDisable               1'b0            //不分支


//***************** 与具体指令有关的宏定义 ***********************

//注意下面定义了指令的机器码，MIPS和RISC-V是不一样的，不能照抄书上内容
//可以参考RISC-V中文手册V2.1的第27页：RV32I指令格式、机器码对照图
//根据opcode确定指令大类
`define INST_TYPE_I                 7'b0010011  //I型指令
//根据funct3确定指令子类
`define EXE_ADDI                    3'b000      //addi指令
`define EXE_ORI                     3'b110      //ori指令
`define EXE_XORI                    3'b100      //xori指令
`define EXE_ANDI                    3'b111      //andi指令
`define EXE_SLLI                    3'b001      //slli指令
`define EXE_SLTI                    3'b010      //slti指令
`define EXE_SLTIU                   3'b011      //sltiu指令
`define EXE_SRLI                    3'b101      //sri指令

`define INST_TYPE_R                 7'b0110011  //R型指令
//根据funct3确定指令子类
`define EXE_OR                      3'b110      //or指令
`define EXE_XOR                     3'b100      //xor指令
`define EXE_AND                     3'b111      //and指令
`define EXE_ADD_SUB                 3'b000      //add指令和sub指令
`define EXE_SLL                     3'b001      //sll指令
`define EXE_SLT                     3'b010      //slti指令
`define EXE_SLTU                    3'b011      //sltiu指令

`define INST_TYPE_L                 7'b0000011  //L型指令
`define EXE_LW                      3'b010      //lw指令
`define EXE_LB                      3'b000      //lb指令
`define EXE_LBU                     3'b100      //lbu指令
`define EXE_LH                      3'b001      //lh指令
`define EXE_LHU                     3'b101      //lhu指令

`define INST_TYPE_S                 7'b0100011  //S型指令
`define EXE_SW                      3'b010      //sw指令
`define EXE_SB                      3'b000      //sb指令
`define EXE_SH                      3'b001      //sh指令

`define INST_TYPE_JAL               7'b1101111      //JAL指令
`define INST_TYPE_JALR              7'b1100111      //JALR指令

`define EXE_LUI                     7'b0110111
`define EXE_AUIPC                   7'b0010111

// J type inst
`define INST_TYPE_B                 7'b1100011
`define EXE_BEQ                     3'b000
`define EXE_BNE                     3'b001
`define EXE_BLT                     3'b100
`define EXE_BGE                     3'b101
`define EXE_BLTU                    3'b110
`define EXE_BGEU                    3'b111

`define EXE_JAL                     7'b1101111
`define EXE_JALR                    7'b1100111

`define EXE_NOP                     7'b0000000      //nop指令，注意这不是RV32I的一部分，它被转写为ADDI x0, x0, 0

// ***************** 与指令存储器ROM有关的宏定义 ***********************
`define InstAddrBus                 31:0            //指令存储器地址总线宽度
`define InstBus                     31:0            //指令存储器数据总线宽度
`define InstMemNum                  2047            //ROM容量
`define InstMemNumLog2              11              //ROM实际使用的地址线宽度


// ***************** 与通用寄存器Regfile有关的宏定义 ***********************
`define RegAddrBus                  4:0             //寄存器地址总线宽度
`define RegBus                      31:0            //寄存器数据总线宽度
`define RegWidth                    32              //寄存器宽度
`define DoubleRegWidth              64              //两倍的寄存器宽度
`define DoubleRegBus                63:0            //两倍的寄存器数据总线宽度
`define RegNum                      32              //寄存器数量
`define RegNumLog2                  5               //寄存器实际使用的地址线宽度

//指令无效时的写回寄存器地址
`define NOPRegAddr                  5'b00000

// ***************** 与数据存储器RAM有关的宏定义 ***********************
`define DataAddrBus                 31:0            //数据存储器地址总线宽度
`define DataBus                     31:0            //数据存储器数据总线宽度
`define DataMemNum                  2047            //RAM容量
`define DataMemNumLog2              11              //RAM实际使用的地址线宽度
`define ByteWidth                   7:0             //字节宽度
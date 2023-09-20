## 基于Verilog HDL的五级流水线RISC-V CPU设计

这是合肥工业大学宣城校区2022-2023学年《系统硬件综合设计》的题目。

### 设计要求

下面把设计要求贴一下。一些有时效性、带有人名的信息已经被我删去。被删去的信息不是关键信息。

> **课程设计内容**：基于先修课程，包括数字逻辑、计算机组成原理、计算机体系结构，根据系统设计思想，使用硬件描述语言设计并实现一款有流水线等功能的比较复杂的CPU，所设计的CPU可以下载至FPGA开发板上，能运行自己编写的测试程序。
> 
> **验收过程**：验收时原则上2人一组（可以跨专业），先自述自己的工作，两人分工要明确，然后两个人分别回答老师的提问，老师根据回答问题的情况和工作量给两人分别打分。相同的完成度先验收的组比后答辩的组相对来说分数要高，因为后答辩的组有可能会参考前面同学的工作。因此鼓励同学们早点验收，这样成绩会好一些。
>
> **评分标准**：验收成绩60%；课程设计报告40%
> - 申优的同学一般要求能下载至开发板上，如果确实不能下载，则需要做出有特色的工作，具体情况需要验收老师判断。验收前要主动告知老师需要申优，上交的报告需要附上设计的工程文件。（FPGA开发板可以找3楼实验室的孟老师借。）
> - 可以设计基于MIPS、ARM、RISC-V指令集的CPU，也可以自己定义指令集。
> - 一般要求有流水线，如果不能实现流水线，需要其他有特色的工作或者比较大的工作量，具体由验收老师判断。
> - 课程设计报告每个人都要完成一份，而且不可抄袭课本、博客或者他人的设计报告，一旦发现雷同报告，将取消该课程的成绩
> - 课程设计报告不能只贴代码，代码应该作为附录，报告内容重点写如何完成设计，包括设计中遇到的困难和解决方法，验证程序尽量自己设计，所贴的仿真波形图需要文字说明。
> - 课程设计报告应该格式正确，每张图要有图名图号，表格应该有表号表名，图表需要文字说明，不能只贴图。
> - 课设报告需要有封面，课设报告模板老师会发到群文件中。

### 我们的设计

该设计由我和另一位同学合作完成。我编写了CPU的所有代码，另一位同学编写了数码管驱动电路。

由于设计结题已久，具体细节已经记不清楚，可以参考当时答辩（疫情原因采用线上答辩验收）时的自述文档：[此处](./自述/自述.md)。

该设计因代码粗陋，无法正常烧板使用，但可以正常仿真。该设计已获评“优秀”。
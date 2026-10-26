`ifndef CPU_DEFS_VH
`define CPU_DEFS_VH

// Internal controls, shared by the ALU, decoder, and immediate generator.
`define CPU_ALU_ADD  4'h0
`define CPU_ALU_SUB  4'h1
`define CPU_ALU_AND  4'h2
`define CPU_ALU_OR   4'h3
`define CPU_ALU_XOR  4'h4
`define CPU_ALU_SLL  4'h5
`define CPU_ALU_SRL  4'h6
`define CPU_ALU_SRA  4'h7
`define CPU_ALU_SLT  4'h8
`define CPU_ALU_SLTU 4'h9

`define CPU_IMM_NONE 3'd0
`define CPU_IMM_I    3'd1
`define CPU_IMM_S    3'd2
`define CPU_IMM_B    3'd3
`define CPU_IMM_U    3'd4
`define CPU_IMM_J    3'd5

`define CPU_A_RS1  2'd0
`define CPU_A_PC   2'd1
`define CPU_A_ZERO 2'd2

`define CPU_WB_ALU 2'd0
`define CPU_WB_MEM 2'd1
`define CPU_WB_PC4 2'd2

`define CPU_BR_NONE 3'd0
`define CPU_BR_EQ   3'd1
`define CPU_BR_NE   3'd2
`define CPU_BR_LT   3'd3
`define CPU_BR_GE   3'd4
`define CPU_BR_LTU  3'd5
`define CPU_BR_GEU  3'd6

`define CPU_MEM_BYTE 2'd0
`define CPU_MEM_HALF 2'd1
`define CPU_MEM_WORD 2'd2

`endif

// Vmicro16 multi-core instruction set

// TODO: Remove NOP by making a register write/read always 0
`define VMICRO16_OP_NOP          5'b00000
`define VMICRO16_OP_LW           5'b00001
`define VMICRO16_OP_SW           5'b00001
`define VMICRO16_OP_BIT          5'b00011
`define VMICRO16_OP_BIT_OR       5'b00000
`define VMICRO16_OP_BIT_XOR      5'b00001
`define VMICRO16_OP_BIT_AND      5'b00010
`define VMICRO16_OP_BIT_NOT      5'b00011
`define VMICRO16_OP_BIT_LSHFT    5'b00100
`define VMICRO16_OP_BIT_RSHFT    5'b00101
`define VMICRO16_OP_MOV          5'b00100
`define VMICRO16_OP_MOVI         5'b00101
`define VMICRO16_OP_MOVI_L       5'b10000
`define VMICRO16_OP_ARITH_U      5'b00110
`define VMICRO16_OP_ARITH_UADD   5'b11111
`define VMICRO16_OP_ARITH_USUB   5'b10000
`define VMICRO16_OP_ARITH_UADDI  5'b0????
`define VMICRO16_OP_ARITH_S      5'b00111
`define VMICRO16_OP_ARITH_SADD   5'b11111
`define VMICRO16_OP_ARITH_SSUB   5'b10000
`define VMICRO16_OP_ARITH_SSUBI  5'b0????
`define VMICRO16_OP_BR           5'b01000
// TODO: wasted upper nibble bits in BR
`define VMICRO16_OP_BR_U         8'h00
`define VMICRO16_OP_BR_E         8'h01
`define VMICRO16_OP_BR_NE        8'h02
`define VMICRO16_OP_BR_G         8'h03
`define VMICRO16_OP_BR_GE        8'h04
`define VMICRO16_OP_BR_L         8'h05
`define VMICRO16_OP_BR_LE        8'h06
`define VMICRO16_OP_BR_S         8'h07
`define VMICRO16_OP_BR_NS        8'h08
`define VMICRO16_OP_CMP          5'b01001
`define VMICRO16_OP_SETC         5'b01010

// microcode operations
`define VMICRO16_ALU_BIT_OR      5'b00000
`define VMICRO16_ALU_BIT_XOR     5'b00001
`define VMICRO16_ALU_BIT_AND     5'b00010
`define VMICRO16_ALU_BIT_NOT     5'b00011
`define VMICRO16_ALU_BIT_LSHFT   5'b00100
`define VMICRO16_ALU_BIT_RSHFT   5'b00101
`define VMICRO16_ALU_LW          5'b00111
`define VMICRO16_ALU_SW          5'b01000
`define VMICRO16_ALU_NOP         5'b01001
`define VMICRO16_ALU_MOV         5'b01010
`define VMICRO16_ALU_MOVI        5'b01011
`define VMICRO16_ALU_MOVI_L      5'b01100
`define VMICRO16_ALU_ARITH_UADD  5'b01101
`define VMICRO16_ALU_ARITH_USUB  5'b01110
`define VMICRO16_ALU_ARITH_SADD  5'b01111
`define VMICRO16_ALU_ARITH_SSUB  5'b10000
`define VMICRO16_ALU_BR_U        5'b10001
`define VMICRO16_ALU_BR_E        5'b10010
`define VMICRO16_ALU_BR_NE       5'b10011
`define VMICRO16_ALU_BR_G        5'b10100
`define VMICRO16_ALU_BR_GE       5'b10101
`define VMICRO16_ALU_BR_L        5'b10110
`define VMICRO16_ALU_BR_LE       5'b10111
`define VMICRO16_ALU_BR_S        5'b11000
`define VMICRO16_ALU_BR_NS       5'b11001
`define VMICRO16_ALU_CMP         5'b11010
`define VMICRO16_ALU_SETC        5'b11011
`define VMICRO16_ALU_ARITH_UADDI 5'b11100
`define VMICRO16_ALU_ARITH_SSUBI 5'b11101
`define VMICRO16_ALU_BAD         5'bXXXXX
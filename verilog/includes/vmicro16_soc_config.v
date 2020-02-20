// Configuration defines for the vmicro16_soc and vmicro16 cpu.

`ifndef VMICRO16_SOC_CONFIG_H
`define VMICRO16_SOC_CONFIG_H

`define FORMAL


`define CLUSTERS        2
`define CORES           4
`define SLAVES          9

///////////////////////////////////////////////////////////
// Core parameters
//////////////////////////////////////////////////////////
// Per core instruction memory
//  Set this to give each core its own instruction memory cache
`define DEF_CORE_HAS_INSTR_MEM

// Top level data width for registers, memory cells, bus widths
`define DATA_WIDTH      16

// Set this to use a workaround for the MMU's APB T2 clock
//`define FIX_T3

// Instruction memory (read only)
//   Must be large enough to support software program.
`ifdef DEF_CORE_HAS_INSTR_MEM
    // 64 16-bit words per core
    `define DEF_MEM_INSTR_DEPTH 64
`else
    // 4096 16-bit words global
    `define DEF_MEM_INSTR_DEPTH 4096
`endif

// Scratch memory (read/write) on each core.
//   See `DEF_MMU_TIM0_* defines for info.
`define DEF_MEM_SCRATCH_DEPTH 64

// Enables hardware multiplier and mult rr instruction
`define DEF_ALU_HW_MULT 1

// Enables global reset (requires more luts)
`define DEF_GLOBAL_RESET

// Enable a watch dog timer to reset the soc if threadlocked
//`define DEF_USE_WATCHDOG

// Enable to detect bus communication stalls or errors.
//   If detected, the whole SoC will be soft-reset, as if by a watchdog
//`define DEF_USE_BUS_RESET

// Enables instruction memory programming via UART0
//`define DEF_USE_REPROG

`ifdef DEF_USE_REPROG
    `ifndef DEF_GLOBAL_RESET
        `error_DEF_USE_REPROG_requires_DEF_GLOBAL_RESET
    `endif
`endif

//////////////////////////////////////////////////////////
// Memory mapping
//////////////////////////////////////////////////////////
`define APB_WIDTH       (2 + `clog2(`CORES) + `DATA_WIDTH)

`define IC_CLUSTER_DEC_MSB 15
`define IC_CLUSTER_DEC_LSB 15

`define IC_DMEM_PSEL_PERI 0
`define IC_DMEM_PSEL_DMEM 1

// BRAM address = 0x1000 to 0x1FFF
`define IC_DMEM_DEC_MSB 12
`define IC_DMEM_DEC_LSB 12

// PMEM address = 0x0000 to 0x00ff
`define IC_DMEM_PMEM_DEC_MSB 7
`define IC_DMEM_PMEM_DEC_LSB 4

`define IC_DMEM_PMEM_PSEL_GPIO0 0
`define IC_DMEM_PMEM_PSEL_GPIO1 1
`define IC_DMEM_PMEM_PSEL_GPIO2 2
`define IC_DMEM_PMEM_PSEL_UART0 3
`define IC_DMEM_PMEM_PSEL_REGS0 4
`define IC_DMEM_PMEM_PSEL_TIMR0 5
`define IC_DMEM_PMEM_PSEL_WDOG0 6
`define IC_DMEM_PMEM_PSEL_PERR0 7
`define IC_DMEM_PMEM_PSEL__LAST 8
`define IC_DMEM_PMEM_PSEL__NUM  `IC_DMEM_PMEM_PSEL__LAST
`define APB_GPIO0_PINS  8
`define APB_GPIO1_PINS  16
`define APB_GPIO2_PINS  8

// Shared memory words
`define APB_BRAM0_CELLS 4096

//////////////////////////////////////////////////////////
// Memory mapping
//////////////////////////////////////////////////////////
// TIM0
// Number of scratch memory cells per core
`define DEF_MMU_TIM0_CELLS  64

//////////////////////////////////////////////////////////
// Interrupts
//////////////////////////////////////////////////////////
// Enable/disable interrupts
//   Disabling will free up resources for other features
//`define DEF_ENABLE_INT
// Number of interrupt in signals
`define DEF_NUM_INT     8
// Default interrupt bitmask (0 = hidden, 1 = enabled)
`define DEF_INT_MASK    0
// Bit position of the TIMR0 interrupt signal
`define DEF_INT_TIMR0   0

`endif

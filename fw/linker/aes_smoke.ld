/* Reference linker layout for src/aes_smoke.S when using an RV32I assembler.
 * The supplied .hex is emitted directly by build_aes_smoke.py, not by ld.
 * Initialized data requires a future loader; Harvard ROM is not data-readable.
 */
OUTPUT_ARCH(riscv)
ENTRY(_start)
MEMORY {
  IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 4K
  DMEM (rw) : ORIGIN = 0x00001000, LENGTH = 4K
}
SECTIONS {
  .text : { *(.text*) } > IMEM
  .results (NOLOAD) : { . += 68; } > DMEM
  .bss (NOLOAD) : { *(.bss*) *(COMMON) } > DMEM
  .data : { *(.data*) *(.sdata*) *(.rodata*) } > DMEM
  __stack_top = ORIGIN(DMEM) + LENGTH(DMEM);
  ASSERT(SIZEOF(.data) == 0, "Initialized data needs a Harvard startup loader")
  ASSERT(SIZEOF(.text) <= LENGTH(IMEM), "Instruction ROM overflow")
}

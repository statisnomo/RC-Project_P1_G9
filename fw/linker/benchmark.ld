OUTPUT_ARCH(riscv)
ENTRY(_start)
MEMORY {
 IMEM (rx) : ORIGIN = 0, LENGTH = 4K
 DMEM (rw) : ORIGIN = 0x1200, LENGTH = 3584
}
SECTIONS {
 .text : { *(.text.start) *(.text*) } > IMEM
 .bss (NOLOAD) : { *(.bss*) *(.sbss*) *(COMMON) } > DMEM
 .data : { *(.data*) *(.sdata*) *(.rodata*) *(.srodata*) } > DMEM
 __stack_top = 0x2000;
 ASSERT(SIZEOF(.data)==0, "Harvard startup does not load C initialized data")
 ASSERT(SIZEOF(.bss)==0, "Explicit RAM layout only for this benchmark")
 ASSERT(SIZEOF(.text)<=4096, "Benchmark exceeds 4 KiB instruction ROM")
}

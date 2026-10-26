# Reset entry at address 0. Only instructions in our 37-instruction subset.
# fw/cpu_smoke.hex is the matching pre-encoded 4 KB ROM image.
# The MMIO write is observed by a simulation stub or the board smoke checker,
# not a real AES peripheral.
    .section .text
    .globl _start
_start:
    lui  x1, 0x1          # RAM base = 0x1000
    addi x2, x0, 10       # Count down from ten
    addi x3, x0, 0        # Sum starts at zero
sum_loop:
    add  x3, x3, x2
    addi x2, x2, -1
    bne  x2, x0, sum_loop
    sw   x3, 0(x1)        # RAM[0x1000] = 55
    lw   x4, 0(x1)
    addi x5, x4, 1
    sw   x5, 4(x1)        # RAM[0x1004] = 56
    lui  x6, 0x40000
    sw   x5, 0(x6)        # Test stub receives exactly one write of 56
done:
    jal  x0, done         # No unsupported HALT/EBREAK instruction needed

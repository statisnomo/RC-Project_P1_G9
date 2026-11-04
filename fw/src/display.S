.section .text
.global _start
_start:
    lui x1, 0x1
    lui x2, 0x40000
    addi x3, x2, 256
    addi x4, x0, 1
    # Lookup table at 0x1000, byte order ROW1/COL1 through ROW4/COL4.
    li x5, 0x0a030201
    sw x5, 0(x1)
    li x5, 0x0b060504
    sw x5, 4(x1)
    li x5, 0x0c090807
    sw x5, 8(x1)
    li x5, 0x0d0e0f00
    sw x5, 12(x1)
    # Fixed public demonstration key 00 01 ... 0F, low byte first.
    li x5, 0x03020100
    sw x5, 16(x2)
    li x5, 0x07060504
    sw x5, 20(x2)
    li x5, 0x0b0a0908
    sw x5, 24(x2)
    li x5, 0x0f0e0d0c
    sw x5, 28(x2)
block:
    addi x6, x0, 0
poll:
    lw x7, 0(x3)
    andi x21, x7, 4
    bne x21, x0, shutdown
    andi x7, x7, 1
    beq x7, x0, poll
    lw x8, 4(x3)
    add x8, x1, x8
    lbu x12, 0(x8)
    sw x4, 8(x3)
    andi x9, x6, 1
    bne x9, x0, low
    slli x10, x12, 4
    beq x0, x0, next
low:
    or x10, x10, x12
    srli x9, x6, 1
    add x9, x1, x9
    sb x10, 16(x9)
next:
    addi x6, x6, 1
    addi x9, x0, 32
    bne x6, x9, poll
    lw x5, 16(x1)
    sw x5, 32(x2)
    lw x5, 20(x1)
    sw x5, 36(x2)
    lw x5, 24(x1)
    sw x5, 40(x2)
    lw x5, 28(x1)
    sw x5, 44(x2)
    sw x4, 0(x2)
wait_aes:
    lw x7, 4(x2)
    andi x7, x7, 2
    beq x7, x0, wait_aes
    lw x5, 48(x2)
    sw x5, 32(x1)
    lw x5, 52(x2)
    sw x5, 36(x1)
    lw x5, 56(x2)
    sw x5, 40(x1)
    lw x5, 60(x2)
    sw x5, 44(x1)
    # Transfer byte-ordered CT words to display staging; submit only when idle.
    addi x13, x2, 512
    addi x14, x2, 768
    lw x5, 32(x1)
    sw x5, 16(x13)
    lw x5, 36(x1)
    sw x5, 20(x13)
    lw x5, 40(x1)
    sw x5, 24(x13)
    lw x5, 44(x1)
    sw x5, 28(x13)
wait_display:
    lw x7, 0(x13)
    andi x7, x7, 1
    beq x7, x0, wait_display
    sw x4, 4(x13)
    # Transmit independent uppercase hex debug output then LF.
    addi x16, x0, 0
serial_char:
    srli x17, x16, 1
    add x17, x17, x1
    lbu x18, 32(x17)
    andi x19, x16, 1
    bne x19, x0, lower_digit
    srli x18, x18, 4
lower_digit:
    andi x18, x18, 15
    sltiu x19, x18, 10
    addi x18, x18, 48
    bne x19, x0, wait_tx
    addi x18, x18, 7
wait_tx:
    lw x7, 4(x14)
    andi x7, x7, 1
    bne x7, x0, wait_tx
    sw x18, 0(x14)
    addi x16, x16, 1
    addi x19, x0, 32
    bne x16, x19, serial_char
wait_lf:
    lw x7, 4(x14)
    andi x7, x7, 1
    bne x7, x0, wait_lf
    addi x18, x0, 10
    sw x18, 0(x14)
    addi x31, x0, 1
    beq x0, x0, block
shutdown:
    # A chord stops input and requests an orderly panel shutdown.
    # Hold the chord to keep power off; release it to restart with an empty block.
    addi x13, x2, 512
wait_idle_shutdown:
    lw x7, 0(x13)
    andi x7, x7, 1
    beq x7, x0, wait_idle_shutdown
    addi x20, x0, 2
    sw x20, 4(x13)
wait_off:
    lw x7, 0(x13)
    andi x7, x7, 2
    beq x7, x0, wait_off
    addi x20, x0, 3
    sw x20, 8(x3)
wait_release:
    lw x7, 0(x3)
    andi x7, x7, 6
    bne x7, x0, wait_release
    addi x20, x0, 4
    sw x20, 4(x13)
    beq x0, x0, block

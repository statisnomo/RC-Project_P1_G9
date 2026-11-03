# Build with fw/build_keypad_aes.py. x12 retires once per accepted digit;
# x31 retires once per completed ciphertext. Four CT words at 0x1020.
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
    addi x31, x0, 1
    beq x0, x0, block

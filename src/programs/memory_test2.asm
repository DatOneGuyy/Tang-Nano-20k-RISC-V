addi x10, x0, 10
sw x2, 0(x3)
addi x2, x2, 1
addi x3, x3, 4
blt x2, x10, -12
lw x20, 0(x0)
lw x21, 4(x0)
lw x22, 8(x0)
lw x23, 12(x0)
lw x24, 16(x0)
lw x25, 20(x0)
lw x26, 24(x0)
lw x27, 28(x0)
lw x28, 32(x0)
lw x29, 36(x0)
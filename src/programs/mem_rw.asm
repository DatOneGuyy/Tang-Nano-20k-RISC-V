addi x10, x0, 10
addi x1, x1, 1
addi x4, x4, 4
sw x1, 0(x4)
blt x1, x10, -12
addi x5, x5, 1
addi x4, x0, 4
lw x2, 0(x4)
add x3, x3, x2
blt x5, x10, -16
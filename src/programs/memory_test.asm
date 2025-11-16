addi x2, x2, -1
addi x3, x0, 4
sh x2, 0(x3)
lh x20, 0(x3)
beq x3, x3, 4
addi x3, x3, 4
sh x2, 1(x3)
lw x21, 0(x3)
addi x3, x3, 4
sh x2, 2(x3)
lw x22, 0(x3)
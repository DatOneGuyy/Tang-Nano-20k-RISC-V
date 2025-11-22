lui x2, 0x12345
addi x2, x2, 0x678
addi x3, x0, 4
sw x2, 0(x3)
lw x5, 0(x3)
sh x2, 4(x3)
lh x6, 4(x3)
addi x2, x0, 0x12
slli x2, x2, 8
addi x2, x2, 0x34
sh x2, 6(x3)
lh x7, 6(x3)
ori x2, x0, 0x12
sb x2, 8(x3)
lb x8, 8(x3)
ori x2, x0, 0x34 
sb x2, 9(x3)
lb x9, 9(x3)
ori x2, x0, 0x56
sb x2, 10(x3)
lb x10, 10(x3)
ori x2, x0, 0x78
sb x2, 11(x3)
lb x11, 11(x3)
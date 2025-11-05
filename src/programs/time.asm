addi x2, x0, 1435
addi x3, x0, 2000
addi x3, x3, 322
addi x31, x0, 100

blt x2, x3, 12
addi x3, x3, 2000
addi x3, x3, 400

blt x2, x31, 16
addi x2, x2, -100
addi x4, x4, 60
beq x0, x0, -12

blt x3, x31, 16
addi x3, x3, -100
addi x5, x5, 60
beq x0, x0, -12

add x4, x4, x2
add x5, x5, x3
sub x6, x5, x4

blt x6, x31, 16
addi x6, x6, -60
addi x7, x7, 1
beq x0, x0, -12
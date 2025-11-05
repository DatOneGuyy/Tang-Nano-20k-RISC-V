addi x2, x0, 1435
addi x3, x0, 2000
addi x3, x3, 322
addi x31, x0, 100
addi x30, x0, 1000

bltu x2, x3, 12
addi x3, x3, 2000
addi x3, x3, 400

sub x4, x3, x2
addi x4, x4, -40

bltu x4, x30, 16
sub x4, x4, x30
addi x5, x5, 10
beq x0, x0, -12
bltu x4, x31, 16
sub x4, x4, x31
addi x5, x5, 1
beq x0, x0, -12
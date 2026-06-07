addi x2, x0, 7  // x2 = 7
addi x3, x0, 7  // x3 = 7

beq x2, x3, taken

addi x5, x0, 19 // x5 = 19
addi x1, x0, 36 // x1 = 36

taken:
sub x4, x3, x5 // x4 = 7

addi x31, x0, 1 // PASS_VALUE

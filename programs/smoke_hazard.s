addi x2, x0, 7  // x2 = 7
addi x3, x0, 3  // x3 = 3
addi x5, x0, 19 // x5 = 19
addi x1, x0, 36 // x1 = 36

add x4, x3, x5 // x4 = 22
and x7, x5, x4 // x7 = 18
sw x7, 0(x1) // mem[9] = 18
or x3, x7, x2 // x3 = 23

lw x6, 0(x1) // x6 = 18
sub x8, x6, x3 // x8 = -5
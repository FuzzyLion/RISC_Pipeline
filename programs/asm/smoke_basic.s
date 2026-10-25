addi x1, x0, 5
nop
nop
nop
nop

addi x2, x0, 7
nop
nop
nop
nop

add x3, x1, x2
nop
nop
nop
nop

sw x3, 0(x0)
nop
nop
nop
nop

lw x4, 0(x0)
nop
nop
nop
nop
nop
nop

auipc x16, 0
nop
nop
nop
nop
nop

addi x31, x0, 1 // PASS_VALUE

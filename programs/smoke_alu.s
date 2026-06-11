addi x1, x0, -8
addi x2, x0, 3

slti x3, x1, -1
sltiu x4, x1, 1
xori x5, x2, 6
ori x6, x2, 8
andi x7, x1, 15
slli x8, x2, 4
srli x9, x1, 4
srai x10, x1, 4

beq x3, x0, fail
bne x4, x0, fail
blt x2, x1, fail
bge x1, x2, fail
bltu x1, x2, fail
bgeu x2, x1, fail

beq x1, x2, fail
bne x1, x2, branch_blt
fail:
addi x31, x0, 2
jal x0, done

branch_blt:
blt x1, x2, branch_bge
addi x31, x0, 3
jal x0, done

branch_bge:
bge x2, x1, branch_bltu
addi x31, x0, 4
jal x0, done

branch_bltu:
bltu x2, x1, branch_bgeu
addi x31, x0, 5
jal x0, done

branch_bgeu:
bgeu x1, x2, pass
addi x31, x0, 6
jal x0, done

pass:
addi x31, x0, 1

done:
jal x0, done

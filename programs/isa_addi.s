addi x1, x0, 8
addi x3, x0, 8

beq x1, x0, fail

beq x3, x1, pass

fail:
addi x31, x0, 2
jal x0, done

pass:
addi x31, x0, 1

done:
jal x0, done

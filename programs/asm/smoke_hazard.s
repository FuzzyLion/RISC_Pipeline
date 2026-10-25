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

# Load a jump target and immediately consume it as JALR's rs1.
# x11 starts at zero so missing the load-use stall selects a wrong target.
la   x10, load_jalr_target
sw   x10, 4(x1)
addi x11, x0, 0
lw   x11, 4(x1)
jalr x12, 0(x11)
addi x13, x0, 1 // Wrong path: must be flushed.

load_jalr_target:
addi x14, x0, 1
addi x31, x0, 1

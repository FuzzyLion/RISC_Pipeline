.section .text.start, "ax", @progbits
.globl _start

_start:
    addi x31, x0, 0

    # Give the trap handler a known DMEM context base before installing mtvec.
    addi t0, x0, 0x100
    csrw mscratch, t0

    la   t4, trap_handler
    csrw mtvec, t4

    # The raw JAL encoding targets PC + 2. That target is illegal for RV32I
    # without the C extension, and the faulting JAL must not update ra.
    addi  s0, x0, 1
    auipc s2, 0
    .word 0x002000ef # jal ra, 2
    addi  s1, x0, 1

unexpected_return:
    addi x31, x0, 3
unexpected_return_loop:
    j unexpected_return_loop

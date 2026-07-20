.section .text.start, "ax", @progbits
.globl _start

_start:
    addi x31, x0, 0

    # Give the trap handler a known DMEM context base before installing mtvec.
    addi t0, x0, 0x100
    csrw mscratch, t0

    la   t4, trap_handler
    csrw mtvec, t4

    # A faulting load must not overwrite its destination register.
    addi  a0, x0, 0x55
    addi  s0, x0, 1
    auipc s2, 0
    lw    a0, 2(x0)
    addi  s1, x0, 1

unexpected_return:
    addi x31, x0, 3
unexpected_return_loop:
    j unexpected_return_loop

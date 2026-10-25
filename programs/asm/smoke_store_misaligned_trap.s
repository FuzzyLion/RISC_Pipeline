.section .text.start, "ax", @progbits
.globl _start

_start:
    addi x31, x0, 0

    # Give the trap handler a known DMEM context base before installing mtvec.
    addi t0, x0, 0x100
    csrw mscratch, t0

    la   t4, trap_handler
    csrw mtvec, t4

    # Establish a known memory word, then prove the misaligned store cannot
    # modify it even though its byte range would overlap that word.
    addi  a0, x0, 0x33
    sw    a0, 0(x0)
    addi  a1, x0, 0x55
    addi  s0, x0, 1
    auipc s2, 0
    sw    a1, 2(x0)
    addi  s1, x0, 1

unexpected_return:
    addi x31, x0, 3
unexpected_return_loop:
    j unexpected_return_loop

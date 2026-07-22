.section .text.start, "ax", @progbits
.globl _start

_start:
    addi x31, x0, 0

    # Give the trap handler a known DMEM context base before installing mtvec.
    addi t0, x0, 0x100
    csrw mscratch, t0

    la   t4, trap_handler
    csrw mtvec, t4

    # Give an exact addr for timecmp address.
    .equ MTIMECMP_LOW_ADDR,  0x10000000
    .equ MTIMECMP_HIGH_ADDR, 0x10000004
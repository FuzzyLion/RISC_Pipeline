.section .text.start, "ax", @progbits
.globl _start

_start:
    addi x31, x0, 0

    addi t0, x0, 0x100
    csrw mscratch, t0
    la   t4, trap_handler
    csrw mtvec, t4

    # Enable interrupts, but leave the timer deadline at its reset value.
    addi t4, x0, 0x80
    csrw mie, t4
    addi t4, x0, 0x08
    csrs mstatus, t4

    addi s3, x0, 0x66
    addi t4, x0, 0x55
    addi s0, x0, 1
    auipc s2, 0
    csrrw s3, 0x7c0, t4       # Legal CSR encoding, unsupported CSR address.
    addi s1, x0, 1           # Must be flushed, and s3 must remain 0x66.

unexpected_return:
    addi x31, x0, 3
unexpected_return_loop:
    j unexpected_return_loop

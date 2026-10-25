.section .text.start, "ax", @progbits
.globl _start

.equ MTIMECMP_LOW_ADDR,  0x10000000
.equ MTIMECMP_HIGH_ADDR, 0x10000004
.equ FIRST_DEADLINE,     80

_start:
    addi x31, x0, 0

    addi t0, x0, 0x100
    csrw mscratch, t0
    la   t4, trap_handler
    csrw mtvec, t4

    # Program a real timer deadline while global interrupts remain disabled.
    li t4, MTIMECMP_LOW_ADDR
    li t5, -1
    sw t5, 0(t4)
    li t4, MTIMECMP_HIGH_ADDR
    sw x0, 0(t4)
    li t4, MTIMECMP_LOW_ADDR
    li t5, FIRST_DEADLINE
    sw t5, 0(t4)

wait_for_pending:
    csrr t4, mip
    andi t4, t4, 0x80
    beq t4, x0, wait_for_pending

    li t4, 0x80
    csrs mie, t4

    # Prepare every marker before opening global interrupts.
    li s3, 0x66
    li t4, 0x55
    li t5, 0x08
    li s0, 1
    auipc s2, 0

    # Keep these adjacent: MIE becomes 1 as the faulting CSR enters EX.
    # The timer is already pending, so both requests are valid at trap entry.
    csrs  mstatus, t5
    csrrw s3, 0x7c0, t4
    addi  s1, x0, 1          # Must be flushed; s3 must remain 0x66.

unexpected_return:
    addi x31, x0, 3
unexpected_return_loop:
    j unexpected_return_loop

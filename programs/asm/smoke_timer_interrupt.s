.section .text.start, "ax", @progbits
.globl _start

.equ MTIMECMP_LOW_ADDR,  0x10000000
.equ MTIMECMP_HIGH_ADDR, 0x10000004
.equ FIRST_DEADLINE,     80

_start:
    addi x31, x0, 0

    # Give the trap handler a known DMEM context base before installing mtvec.
    addi t0, x0, 0x100
    csrw mscratch, t0

    la   t4, trap_handler
    csrw mtvec, t4

    # Program the first 64-bit deadline through the real MMIO store path.
    # Keep interrupts disabled while the request becomes pending so the smoke
    # can prove both MTIE and global MIE gating.
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

    # Values that the interrupt handler must preserve.
    li t1, 0x11
    li t2, 0x22
    li t3, 0x33
    li s0, 0

    # Enable the timer source first and global machine interrupts last.
    li t4, 0x80
    csrs mie, t4

    li t4, 0x08
    csrs mstatus, t4

wait_for_return:
    addi s0, s0, 1
    csrr t5, mie
    andi t5, t5, 0x80
    bne t5, x0, wait_for_return

    # Reaching here proves that the handler cleared MTIE and mret returned.
    li s1, 1
    li x31, 1

done:
    j done

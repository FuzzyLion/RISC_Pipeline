.section .text.start, "ax", @progbits
.globl _start

_start:
    la   t0, trap_handler
    csrw mtvec, t0

.section .trap, "ax", @progbits
.align 2
.globl trap_handler

trap_handler:
    # save registers that will be overwriten
    csrrw t0, mscratch, t0
    sw t1, 0(t0)
    sw t2, 4(t0)
    sw t3, 8(t0)
    #check cause of exception
    csrr t1, mcause

machine_envcall:
    addi t2, x0, 11
    bne t1, t2, exit
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j trap_return

#restore registers and return from the exception
trap_return:
    lw t1, 0(t0)
    lw t2, 4(t0)
    lw t3, 8(t0)
    csrrw t0, mscratch, t0
    mret

exit:
    lw t1, 0(t0)
    lw t2, 4(t0)
    lw t3, 8(t0)
    csrrw t0, mscratch, t0
    mret

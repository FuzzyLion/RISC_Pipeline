.section .trap, "ax", @progbits
.align 2
.globl trap_handler

trap_handler:
    # save registers that will be overwriten
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
    mret

exit:
    lw t1, 0(t0)
    lw t2, 4(t0)
    lw t3, 8(t0)
    addi x31, x0, 2
    j fail

fail:
    j fail

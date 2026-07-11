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
    addi t2, x0, 0

jumpbranchmisaligned:
    bne t1, t2, illegalinstr
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j done

illegalinstr:
    addi t2, x0, 2
    bne t1, t2, softwareinterrupt
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j done

softwareinterrupt:
    addi t2, x0, 32771
    bne t1, t2, timerinterrupt
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j done

timerinterrupt:
    addi t2, x0, 32775
    bne t1, t2, externalinterrupt
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j done

externalinterrupt:
    addi t2, x0, 32779
    bne t1, t2, breakpoint
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j done

breakpoint:
    addi t2, x0, 3
    bne t1, t2, loadmisaligned
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j done

loadmisaligned:
    addi t2, x0, 5
    bne t1, t2, storemisaligned
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j done

storemisaligned:
    addi t2, x0, 6
    bne t1, t2, machineenvcall
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j done

machineenvcall:
    addi t2, x0, 11
    bne t1, t2, exit
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j done

#restore registers and return from the exception
done:
    lw t1, 0(t0)
    lw t2, 4(t0)
    csrrw t0, mscratch, t0
    mret

exit:

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

jump_branch_misaligned:
    bne t1, t2, illegal_instr
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j trap_return

illegal_instr:
    addi t2, x0, 2
    bne t1, t2, software_interrupt
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j trap_return

software_interrupt:
    addi t2, x0, 0x80000003
    bne t1, t2, timer_interrupt
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j trap_return

timer_interrupt:
    addi t2, x0, 0x80000007
    bne t1, t2, external_interrupt
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j trap_return

external_interrupt:
    addi t2, x0, 0x8000000B
    bne t1, t2, breakpoint
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j trap_return

breakpoint:
    addi t2, x0, 3
    bne t1, t2, load_misaligned
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j trap_return

load_misaligned:
    addi t2, x0, 4
    bne t1, t2, store_misaligned
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j trap_return

store_misaligned:
    addi t2, x0, 6
    bne t1, t2, machine_envcall
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j trap_return

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
    csrrw t0, mscratch, t0
    mret

exit:

.section .trap, "ax", @progbits
.align 2
.globl trap_handler

.equ MTIMECMP_LOW_ADDR,  0x10000000
.equ MTIMECMP_HIGH_ADDR, 0x10000004

trap_handler:
    # Save registers that will be overwritten.
    csrrw t0, mscratch, t0
    sw t1, 0(t0)
    sw t2, 4(t0)
    sw t3, 8(t0)

    # Dispatch explicitly by the architectural mcause value. Labels do not
    # select themselves; every supported cause needs a branch target.
    csrr t1, mcause

    addi t2, x0, 2
    beq  t1, t2, illegal_instr

    addi t2, x0, 11
    beq  t1, t2, machine_envcall

    addi t2, x0, 3
    beq  t1, t2, machine_envbreak

    addi t2, x0, 0
    beq  t1, t2, instr_addr_misaligned

    addi t2, x0, 4
    beq  t1, t2, load_misaligned

    addi t2, x0, 6
    beq  t1, t2, store_misaligned

    li t2, 0x80000007
    beq  t1, t2, machine_timer_interrupt

    j fatal_trap

illegal_instr:
    j fatal_trap

machine_envcall:
    j resume_after_trap_instr

machine_envbreak:
    # Current teaching policy: treat EBREAK as a resumable software marker.
    # This is not a hardware Debug-Mode implementation.
    j resume_after_trap_instr

resume_after_trap_instr:
    csrr t3, mepc
    addi t3, t3, 4
    csrw mepc, t3
    j trap_return

instr_addr_misaligned:
    j fatal_trap

load_misaligned:
    j fatal_trap

store_misaligned:
    j fatal_trap

machine_timer_interrupt:
    # Use the standard RV32 three-store sequence so the comparator never sees
    # an unintended mixed old/new 64-bit deadline.
    li t1, MTIMECMP_LOW_ADDR
    li t2, -1
    sw t2, 0(t1)

    li t1, MTIMECMP_HIGH_ADDR
    li t2, 1
    sw t2, 0(t1)

    li t1, MTIMECMP_LOW_ADDR
    li t2, 0
    sw t2, 0(t1)

    # One-shot policy: after one delivery, do not accept another timer
    # interrupt.
    li t2, 0x80
    csrrc x0, mie, t2

    j trap_return

# Restore registers and return from the exception.
trap_return:
    lw t1, 0(t0)
    lw t2, 4(t0)
    lw t3, 8(t0)
    csrrw t0, mscratch, t0
    mret

fatal_trap:
    lw t1, 0(t0)
    lw t2, 4(t0)
    lw t3, 8(t0)
    csrrw t0, mscratch, t0

    # Testbench completion signature only. mcause/mepc/mtval remain the
    # authoritative architectural trap record in csr_file.
    addi x31, x0, 2
    j fatal_loop

fatal_loop:
    j fatal_loop

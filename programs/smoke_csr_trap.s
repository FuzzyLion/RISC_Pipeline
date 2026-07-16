.section .text.start, "ax", @progbits
.globl _start

_start:
    addi x31, x0, 0

    # Install the direct-mode trap handler without relying on a fixed link address.
    la   t4, trap_handler
    csrw mtvec, t4

    # Contract with the current handler: t0 is a stable, aligned DMEM scratch base.
    addi t0, x0, 0x100
    addi t1, x0, 0x11
    addi t2, x0, 0x22
    addi t3, x0, 0x33
    addi s1, x0, 0

    # ECALL site 1: basic entry, return, and scratch-register preservation.
    ecall
    addi s1, s1, 1

    addi a0, x0, 0x100
    bne  t0, a0, fail_preserve
    addi a0, x0, 0x11
    bne  t1, a0, fail_preserve
    addi a0, x0, 0x22
    bne  t2, a0, fail_preserve
    addi a0, x0, 0x33
    bne  t3, a0, fail_preserve

    addi a0, x0, 1
    bne  s1, a0, fail_first_return

    # Register CSR forms: verify rd receives the old CSR value.
    addi t4, x0, 0x0f
    csrrw s2, mtval, t4       # old=0x00, new=0x0f
    addi t4, x0, 0x30
    csrrs s3, mtval, t4       # old=0x0f, new=0x3f
    addi t4, x0, 0x0c
    csrrc s4, mtval, t4       # old=0x3f, new=0x33

    # Immediate CSR forms.
    csrrwi s5, mtval, 5       # old=0x33, new=0x05
    csrrsi s6, mtval, 16      # old=0x05, new=0x15
    csrrci s7, mtval, 1       # old=0x15, new=0x14

    # Zero-source CSRRS/CSRRSI are pure reads and must not modify mtval.
    csrrs  s8, mtval, x0      # old=0x14, no write
    csrrsi s9, mtval, 0       # old=0x14, no write
    csrr   a0, mtval
    addi   a1, x0, 0x14
    bne    a0, a1, fail_csr

    addi a1, x0, 0
    bne  s2, a1, fail_csr
    addi a1, x0, 0x0f
    bne  s3, a1, fail_csr
    addi a1, x0, 0x3f
    bne  s4, a1, fail_csr
    addi a1, x0, 0x33
    bne  s5, a1, fail_csr
    addi a1, x0, 0x05
    bne  s6, a1, fail_csr
    addi a1, x0, 0x15
    bne  s7, a1, fail_csr
    addi a1, x0, 0x14
    bne  s8, a1, fail_csr
    bne  s9, a1, fail_csr

    # ECALL site 2: trap entry must overwrite mtval and return here exactly once.
    ecall
    addi s1, s1, 1
    addi a0, x0, 2
    bne  s1, a0, fail_second_return

    # Reach the third site through a redirect so it occupies a distinct control path.
    jal  x0, third_ecall_site
    jal  x0, fail_third_return

third_ecall_site:
    ecall
    auipc a6, 0
    addi  s1, s1, 1

    # The AUIPC is the first instruction after ECALL, so its PC must equal mepc.
    csrr  a7, mepc
    bne   a6, a7, fail_mepc

    addi a0, x0, 3
    bne  s1, a0, fail_third_return

test_pass:
    addi x31, x0, 1
test_done:
    j test_done

fail_preserve:
    addi x31, x0, 3
    j test_done

fail_first_return:
    addi x31, x0, 4
    j test_done

fail_csr:
    addi x31, x0, 5
    j test_done

fail_second_return:
    addi x31, x0, 6
    j test_done

fail_third_return:
    addi x31, x0, 7
    j test_done

fail_mepc:
    addi x31, x0, 8
    j test_done

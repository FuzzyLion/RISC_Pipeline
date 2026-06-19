// Lightweight riscv-tests environment for the current Phase 3 core.
//
// This file intentionally implements only the macro interface needed by
// rv32ui user-level integer tests. It avoids CSR, trap, ecall, and tohost
// machinery because those belong to later CSR/exception phases.

#ifndef RISC_PIPELINE_RISCV_LITE_TEST_H
#define RISC_PIPELINE_RISCV_LITE_TEST_H

#define RVTEST_RV32U
#define RVTEST_RV64U RVTEST_RV32U

#define TESTNUM gp

#define RVTEST_CODE_BEGIN                                               \
        .section .text;                                                 \
        .align 2;                                                       \
        .globl _start;                                                  \
_start:                                                                 \
        li x1, 0;                                                       \
        li x2, 0;                                                       \
        li x3, 0;                                                       \
        li x4, 0;                                                       \
        li x5, 0;                                                       \
        li x6, 0;                                                       \
        li x7, 0;                                                       \
        li x8, 0;                                                       \
        li x9, 0;                                                       \
        li x10, 0;                                                      \
        li x11, 0;                                                      \
        li x12, 0;                                                      \
        li x13, 0;                                                      \
        li x14, 0;                                                      \
        li x15, 0;                                                      \
        li x16, 0;                                                      \
        li x17, 0;                                                      \
        li x18, 0;                                                      \
        li x19, 0;                                                      \
        li x20, 0;                                                      \
        li x21, 0;                                                      \
        li x22, 0;                                                      \
        li x23, 0;                                                      \
        li x24, 0;                                                      \
        li x25, 0;                                                      \
        li x26, 0;                                                      \
        li x27, 0;                                                      \
        li x28, 0;                                                      \
        li x29, 0;                                                      \
        li x30, 0;                                                      \
        li x31, 0;                                                      \
        li TESTNUM, 0;

#define RVTEST_CODE_END

#define RVTEST_PASS                                                     \
        li x31, 1;                                                      \
1:      jal x0, 1b

#define RVTEST_FAIL                                                     \
        beq TESTNUM, x0, 1f;                                            \
        slli x31, TESTNUM, 1;                                           \
        addi x31, x31, 1;                                               \
        jal x0, 2f;                                                     \
1:      addi x31, x0, 2;                                                \
2:      jal x0, 2b

#define RVTEST_DATA_BEGIN                                               \
        .section .data;                                                 \
        .align 4;                                                       \
        .global begin_signature;                                        \
begin_signature:

#define RVTEST_DATA_END                                                 \
        .align 4;                                                       \
        .global end_signature;                                          \
end_signature:

#endif

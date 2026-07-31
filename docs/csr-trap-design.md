# CSR, Exceptions, and Machine-Timer Interrupts

Phase 4 now meets this project's minimum milestone. The core has a complete
Machine Mode loop: software can access the implemented CSRs, traps enter
through `mtvec`, the handler can inspect the recorded cause, and `mret` returns
to normal execution. A one-shot machine-timer interrupt also works through the
real MMIO path.

The boundary matters. This is not full RISC-V privileged-architecture support.
It is the smallest design that makes traps precise, testable, and useful for
the next SoC phase.

The seventeen-test directed regression that protects this milestone is
registered in `sim/run_regression.sh`.

## 1. Scope

The implemented CSR set includes:

- `mstatus`
- `mie`
- `mtvec`
- `mscratch`
- `mepc`
- `mcause`
- `mtval`
- `mip`

The core decodes all six base CSR read/modify/write forms used in this project:
`CSRRW`, `CSRRS`, `CSRRC`, `CSRRWI`, `CSRRSI`, and `CSRRCI`. It also decodes
`ecall`, `ebreak`, and `mret`.

The implemented synchronous trap sources are:

- illegal instruction or unsupported CSR access
- Machine Mode `ecall`
- breakpoint exception from `ebreak`
- instruction-address misalignment
- load-address misalignment
- store-address misalignment

The implemented interrupt source is one machine timer. Software programs the
64-bit `mtimecmp` value through two 32-bit MMIO addresses. Timer expiry appears
as the read-only `mip.MTIP` bit and is accepted only when both `mie.MTIE` and
`mstatus.MIE` are set.

The following work remains intentionally outside this milestone:

- software and external interrupts
- vectored `mtvec` mode
- periodic timer scheduling
- nested or reentrant traps
- a general ABI-safe runtime
- other privilege modes and privilege transitions
- broad privileged-architecture compliance

## 2. Architecture and Ownership

The main design decision is to keep detection, arbitration, architectural
state, and redirection separate. They belong to one trap flow, but each has a
different job.

| Block | Responsibility | What it does not own |
| --- | --- | --- |
| `control_unit.sv` | Detects illegal encodings, CSR/system operations, `ecall`, `ebreak`, and `mret` | Trap priority and CSR state |
| `pc_target_gen.sv` | Computes branch/jump targets and reports instruction-address misalignment | `mcause`, `mepc`, or trap priority |
| `alu_op.sv` | Computes effective addresses and reports load/store misalignment | Pipeline flushing or CSR updates |
| `trap_ctrl.sv` | Selects the authoritative trap, produces `mcause`/`mtval`/`mepc`, and requests flushing | Persistent CSR storage |
| `csr_file.sv` | Owns CSR state, CSR instruction semantics, trap-entry state changes, and `mret` state changes | PC selection |
| `pc_mux.sv` | Gives trap entry priority over branch/jump/`mret` redirects | Trap detection |
| `hazard_unit.sv` and pipeline registers | Turn trap and redirect decisions into stalls, flushes, and bubbles | Trap metadata |
| `machine_timer.sv` | Owns `mtime`, `mtimecmp`, and the level-sensitive timer request | Interrupt enable policy |
| `mmio_decoder.sv` | Routes timer MMIO stores away from data RAM | Timer state or trap arbitration |

The resulting control flow is:

```text
Decode/EX detection
        |
        v
trap_ctrl: cause, metadata, priority, trap entry
        |                     |
        |                     +--> flush D/E and kill E-to-M
        |
        +--> csr_file: save mepc/mcause/mtval and update mstatus
        |
        +--> pc_mux: PC <- mtvec

handler
        |
        +--> optional mepc update or timer acknowledgement
        |
        +--> mret: restore mstatus and PC <- mepc
```

This split adds a few explicit signals to `core.sv`, but the ownership stays
easy to explain. It also keeps `csr_file.sv` from becoming a second Control
Unit and `trap_ctrl.sv` from turning into a hidden CSR bank.

## 3. Key Design Decisions and Trade-offs

**The precise trap boundary is the EX stage.**

The current instruction becomes authoritative in EX, once forwarding and
address or target calculation are available. On trap entry, Fetch and Decode
are flushed. `trap_flush_M` then prevents the current EX instruction from
entering MEM. The older instruction already in MEM is not killed and can still
complete.

For a synchronous exception, the EX instruction is the faulting instruction
and must not commit. For a timer interrupt, the same EX instruction is legal
but still gets squashed. Its address is saved in `mepc`, so `mret` re-executes
it. Both cases use the same precise boundary:

```text
older instructions  -> complete once
current EX instruction -> does not commit
younger instructions -> flushed
```

The trade-off is that an interrupt can currently be accepted only when EX holds
a valid instruction. That is enough for the current running-program model. A
future idle or `wfi` design may need an interrupt boundary that does not depend
on `valid_E`.

**Synchronous exceptions win over the timer interrupt.**

The timer request is asynchronous to the current instruction, while a
synchronous exception describes the instruction itself. If both appear at the
same EX boundary, the instruction's own fault wins.

The current priority is:

| Priority | Event | `mcause` |
| ---: | --- | --- |
| 1 | Illegal instruction or unsupported CSR access | `2` |
| 2 | Machine Mode `ecall` | `11` |
| 3 | `ebreak` | `3` |
| 4 | Instruction-address misaligned | `0` |
| 5 | Load-address misaligned | `4` |
| 6 | Store-address misaligned | `6` |
| 7 | Machine-timer interrupt | `0x8000_0007` |

The synchronous order follows a simple sequence of questions: is the
instruction itself valid, did a legal control-flow instruction produce a legal
target, and did a legal memory instruction produce a legal data address? The
timer is considered only when no synchronous event wins.

In `pc_mux.sv`, a trap redirect also wins over an ordinary branch, jump, or
`mret` redirect. If a timer is accepted while a branch is in EX, that branch is
squashed and later re-executed from `mepc`.

**Trap entry and pipeline flush remain separate concepts.**

One accepted trap currently drives all three trap-flush outputs. They could be
collapsed into one wire, but their meanings are different:

- `trap_entry_E` says architectural trap state must be recorded.
- `trap_flush_D` and `trap_flush_E` remove younger work.
- `trap_flush_M` kills the current EX instruction before it gains MEM-stage
  side effects.

Keeping those roles explicit will make later memory waits, multiple execution
units, and new interrupt boundaries easier to reason about.

**CSR state has one owner and restricted write masks.**

`csr_file.sv` is the only owner of persistent CSR state. A CSR address selects
the state register, while the instruction type decides how to form the new
value.

CSR instructions return the old CSR value to `rd`. `CSRRW` and `CSRRWI`
always write. `CSRRS` and `CSRRC` become pure reads when `rs1 == x0`.
`CSRRSI` and `CSRRCI` become pure reads when `uimm == 0`.

Only implemented bits are writable:

- CSR instructions can update `mstatus.MIE` and `mstatus.MPIE`; Machine Mode
  `MPP` remains fixed for this design.
- Software can update only `mie.MTIE`.
- `mip.MTIP` is a read-only architectural view of the hardware timer request.
- `mtvec` is forced to word alignment, so the current path is Direct mode
  only.

This is stricter than storing arbitrary 32-bit values, and deliberately so: it
prevents software from creating interrupt state that the hardware does not
implement.

**Full CSR vectors are kept between modules.**

The design passes the full `mstatus`, `mie`, and `mip` values into
`trap_ctrl.sv` instead of exposing only three one-bit signals. That leaves some
unused-bit noise today, but it gives software, the timer, and future interrupt
sources one stable architectural interface.

The width is not the important part. What matters is that every value has one
authority. In particular, `mip` is not a normal software-writable register. It
is an architectural view assembled from pending hardware sources:

```text
mip[3]  <- future software interrupt
mip[7]  <- current timer interrupt
mip[11] <- future external interrupt
```

**CSR operands use the forwarded EX value.**

CSR instructions can depend on a nearby producer just like ALU instructions.
Using the original Decode-stage `rs1` value would bypass forwarding and could
write stale data into a CSR. The CSR source therefore comes from the forwarded
EX operand.

CSR read results also have an explicit MEM-to-EX forwarding path. This avoids
artificial NOPs after a CSR read and keeps CSR behavior inside the existing
hazard model.

**JALR masking happens before alignment checking.**

RISC-V defines JALR as clearing target bit 0. The core therefore computes:

```text
target = (forwarded_rs1 + sign_extended_imm) & 0xFFFF_FFFE
```

The RV32I-only core checks 4-byte alignment only after this masking. A raw
result of `0x101` becomes the legal target `0x100`; a final target of `0x102`
is still misaligned and traps.

Clearing bit 0 is normal JALR behavior, not an attempt to repair an exception.

**`mepc` policy depends on the trap type.**

Hardware records the accepted EX-stage PC in every case.

- For `ecall` and the current teaching-policy `ebreak`, the handler advances
  `mepc` by 4 before `mret` so execution resumes after the trap instruction.
- For a timer interrupt, the handler does not advance `mepc`; the interrupted
  instruction must run again.
- Illegal and misaligned exceptions currently go to a fatal path rather than
  pretending that general recovery exists.

`ebreak` and `ecall` remain different architectural causes even though the
handler gives them the same resume policy. The core has no Debug Module,
`dpc`/`dcsr`, or `dret`, so this is not debugger recovery.

**Trap entry and `mret` only change the status they own.**

Trap entry performs:

```text
mstatus.MPIE <- mstatus.MIE
mstatus.MIE  <- 0
mepc         <- accepted PC
mcause       <- selected cause
mtval        <- cause-specific value
PC           <- mtvec
```

`mret` performs:

```text
mstatus.MIE  <- mstatus.MPIE
mstatus.MPIE <- 1
PC           <- mepc
```

`mret` does not clear `mie` or `mip`. `mie` is software configuration;
`mip.MTIP` reports whether the timer source is still pending. The handler must
acknowledge the source by moving `mtimecmp` into the future.

**The first timer is deliberately one-shot.**

`machine_timer.sv` is a counter and comparator, not a clock generator:

```text
system clock -> mtime increments
mtime >= mtimecmp -> timer_irq is high
```

Software writes `mtimecmp` through:

```text
0x1000_0000 -> mtimecmp[31:0]
0x1000_0004 -> mtimecmp[63:32]
```

Only aligned full-word stores are accepted. The MMIO decoder keeps those
writes out of the normal data-memory path, so timer programming cannot alias
into RAM.

RV32 software updates the 64-bit compare value with a safe three-store
sequence: write all ones to the low half, write the high half, then write the
final low half. This prevents the comparator from seeing a mixed old/new
deadline and firing early.

The handler then disables `mie.MTIE`, so the test is intentionally one-shot.
Periodic scheduling is not included because software cannot yet read `mtime`
through MMIO. A real periodic handler needs readable `mtime`, a previous
deadline maintained in software, or a hardware reload mechanism. That belongs
to the SoC and runtime, not to the basic CPU trap path.

**The handler is a teaching runtime, not a production runtime.**

The current handler uses `mscratch` as a known data-memory scratch base and
saves only the temporary registers it overwrites. Cause dispatch stays
explicit: every supported `mcause` has its own branch, and unknown causes go to
`fatal_trap`.

The handler is intentionally small and easy to inspect. The trade-off is that
it is not ABI-safe, reentrant, nested-trap-safe, or suitable for a general
application.

The linked `.trap` section does not have a fixed assumed address. The linker
places it, then startup loads the `trap_handler` symbol and installs that
address in `mtvec`.

## 4. Verification Evidence

Verification is directed and layered. Module tests check local contracts;
processor smokes prove that the pieces work together through real instruction
streams.

| Area | Evidence |
| --- | --- |
| CSR decode | All six CSR forms, `ecall`, `ebreak`, `mret`, and illegal system encodings in `control_unit_tb.sv` |
| Hazard behavior | CSR result forwarding, trap flush priority, and existing load-use/redirect behavior in `hazard_unit_tb.sv` |
| Target alignment | JALR bit-0 clearing and taken-target alignment in `pc_target_gen_tb.sv` |
| Mixed CSR/trap flow | Old-value writeback, pure reads, two `ebreak` sites, one `ecall`, handler preservation, `mepc`, and `mret` in `smoke_csr_trap` |
| Precise synchronous traps | Separate illegal-instruction and instruction/load/store-misaligned smokes |
| Machine timer | MMIO programming, disabled pending state, cause 7, D/E/M flushing, one-shot acknowledgement, register preservation, and `mret` re-execution |

The precise-trap smokes check more than `mcause`. They prove that a younger
instruction is flushed and that the faulting JAL, load, or store does not
commit its prohibited side effect.

The timer smoke checks that:

1. `mtimecmp` is programmed through the real MMIO store path.
2. `MTIP` can be pending while `MTIE` or global `MIE` still blocks delivery.
3. Exactly one timer trap is accepted with `mcause = 0x8000_0007`.
4. D, E, and the current E-to-M transfer are flushed.
5. The handler moves `mtimecmp` into the future and clears `mie.MTIE`.
6. `mret` returns to the saved `mepc`, and that instruction is re-executed.

The regression contains seven module tests and ten processor smoke tests. A
green result is strong evidence for this scoped milestone, but it does not
claim complete privileged compliance.

The `x31` completion value belongs only to the software/testbench protocol. It
is not an architectural feature. Each program and testbench must agree on the
meaning of a nonzero value; the architectural trap record remains `mcause`,
`mepc`, and `mtval`.

## 5. Known Limits and Future Expansion

Future work should preserve the current ownership boundaries. Do not widen
`csr_file.sv` or `trap_ctrl.sv` without a clear contract.

1. **Broaden precise-exception coverage.** Add a processor-level unsupported
   CSR test and more combinations of older in-flight side effects. The key
   invariant is still: older work completes once, the faulting instruction has
   no prohibited side effect, and younger work disappears.
2. **Move timer ownership toward the SoC boundary.** The current internal MMIO
   path was useful to prove the interrupt loop. Phase 5 should define the
   address map and peripheral boundary more cleanly.
3. **Add readable timer state and periodic scheduling.** Expose `mtime` through
   an MMIO read path, define safe RV32 64-bit reads, calculate the next
   deadline, and prove repeated ticks. If a slower timer rate is needed, use a
   clock enable or prescaler rather than creating a second fabric clock.
4. **Add software and external interrupts.** Extend the `mip` and `mie`
   architectural views, define source priority, and keep all synchronous
   exceptions ahead of asynchronous delivery at the chosen precise boundary.
5. **Support vectored `mtvec` only when there is a real use case.** Direct mode
   is simpler and already sufficient for the current cause dispatcher.
6. **Build an ABI-safe trap frame.** Define stack ownership, saved registers,
   nested-trap policy, and recovery rules before using the handler as a general
   runtime.
7. **Revisit interrupt acceptance around stalls and idle states.** The future
   handshake memory interface, long-latency units, cache misses, and possible
   `wfi` behavior need an explicit rule for when an interrupt becomes
   architecturally accepted.
8. **Expand verification when the state space justifies it.** Keep the current
   SystemVerilog directed tests as the fast baseline. Add Cocotb, randomized
   latency, reference models, or differential testing when Cache, buses, and
   broader privileged behavior make them materially useful.

## 6. Phase 4 Closure

Phase 4 can close because the project-level exit condition now holds:

```text
CSR instruction
    -> architectural CSR state
    -> synchronous exception or enabled timer interrupt
    -> precise pipeline kill and redirect
    -> handler dispatch and acknowledgement
    -> mret and normal execution
```

The important result is not the number of implemented CSRs. It is the fact that
every control decision has one owner, every accepted trap has a precise
architectural boundary, and the implemented path has a focused test that proves
its real behavior.

Relevant implementation and verification files:

- [`rtl/core/csr_file.sv`](../rtl/core/csr_file.sv)
- [`rtl/core/trap_ctrl.sv`](../rtl/core/trap_ctrl.sv)
- [`rtl/core/pc_mux.sv`](../rtl/core/pc_mux.sv)
- [`rtl/core/machine_timer.sv`](../rtl/core/machine_timer.sv)
- [`rtl/core/mmio_decoder.sv`](../rtl/core/mmio_decoder.sv)
- [`software/runtime/trap_handler.s`](../software/runtime/trap_handler.s)
- [`programs/smoke_csr_trap.s`](../programs/smoke_csr_trap.s)
- [`programs/smoke_timer_interrupt.s`](../programs/smoke_timer_interrupt.s)
- [`tb/core_smoke_timer_interrupt_tb.sv`](../tb/core_smoke_timer_interrupt_tb.sv)
- [`sim/run_regression.sh`](../sim/run_regression.sh)
- [`docs/plans/system/phase-4-csr-exception-interrupt.md`](plans/system/phase-4-csr-exception-interrupt.md)

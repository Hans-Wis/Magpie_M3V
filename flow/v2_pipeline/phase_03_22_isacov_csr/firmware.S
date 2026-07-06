/* ADR-0063 V5 backlog #2 (host): exercise the csr.v datapath — CSR read/write across
   M-mode CSRs + a trap round-trip (ecall -> handler -> mret). Avoids non-deterministic
   counters (mcycle/minstret/time) so DUT/Spike lockstep matches. rd != x0 so results
   are compared. rv32imc_zicsr lockstep. */
.section .init
.global _start
_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    /* mtvec -> trap handler */
    la   t0, mtvec_handler
    csrw mtvec, t0
    csrr s0, mtvec

    /* read-only identity CSRs — misa/mhartid match DUT<->Spike; mvendorid/marchid/mimpid
       are implementation-specific (differ) so we READ them (exercises csr.v) but into a
       scratch reg we do NOT rely on — keep observed regs on the matching ones only. */
    csrr s1, misa
    csrr x0, mvendorid          /* rd=x0: exercised, not compared */
    csrr x0, marchid
    csrr x0, mimpid
    csrr s5, mhartid

    /* mscratch read/write/set/clear */
    li   t1, 0x12345678
    csrw mscratch, t1
    csrr s6, mscratch
    li   t2, 0x0000000F
    csrrs s7, mscratch, t2
    csrrc s8, mscratch, t2

    /* mstatus / mie / mip R-M-W (deterministic state) */
    li   t3, 0x8
    csrrs s9, mstatus, t3       /* set MIE */
    csrrc s10, mstatus, t3      /* clear MIE */
    li   t4, 0x880
    csrrs s11, mie, t4          /* enable MEIP/MTIP bits */
    csrr t5, mie

    /* reachable writable M-mode CSR arms not yet hit: mcause / mtval (state, deterministic) */
    li   t1, 0x40000005
    csrw mcause, t1
    csrr t2, mcause
    li   t1, 0xCAFEBABE
    csrw mtval, t1              /* write arm covered; readback masked bit31 in Spike (WARL) */
    csrr x0, mtval             /* exercised, not value-compared */

    /* reachable read-only CSR arms — read to x0 (exercised, value not compared).
       PMP CSRs read back 0 at PMP_ENTRIES=0 (deterministic, both DUT & M-only Spike).
       NOTE: the U-mode counter shadows (cycle/instret 0xC00) are NOT tested here — the
       DUT implements them but the M-only Spike traps them illegal (lenient-vs-strict
       divergence, recorded); use mcycle/minstret if M-mode counter coverage is wanted. */
    csrr x0, pmpcfg0
    csrr x0, pmpaddr0
    csrr x0, pmpaddr7

    /* trigger a trap: ecall from M-mode -> mcause=11 */
    li   a0, 0
    ecall
    /* returns here after mret */
    li   a1, 0x600D
    j    done

    .balign 4
mtvec_handler:
    csrr a2, mcause             /* 11 = ecall-from-M */
    csrr a3, mepc               /* faulting pc */
    addi a3, a3, 4              /* skip the ecall */
    csrw mepc, a3
    csrr a4, mtval
    mret

done:
    ebreak

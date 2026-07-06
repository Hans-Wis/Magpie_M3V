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

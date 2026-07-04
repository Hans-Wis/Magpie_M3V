/* ADR-0049 S3: unaligned vs1 GROUP source on an OPMVV .vv op must be illegal
   (Codex finding — the aligned random pools never generate it). */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    li   a0, 16
    vsetvli t1, a0, e8, m2, ta, ma
    vmv.v.i v2, 3
    vmv.v.i v4, 5
    vaaddu.vv v6, v4, v2       /* legal baseline */
    vmv.x.s t2, v6
    vaaddu.vv v6, v4, v1       /* vs1=1 unaligned @m2 -> illegal terminator */
    ebreak

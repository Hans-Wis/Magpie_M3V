/* ADR-0036 gate_40 — vector-CSR lockstep grid (P0④ checkpoint discipline).
 * Straight-line vset{i}vl{i} grid over legal SEW×LMUL configs and AVL boundary
 * values, with a dense csrr checkpoint (vl, vtype, vstart) after EVERY config
 * change so vector-CSR state enters the compared scalar commit stream bit-exact.
 * No vector datapath ops (3A), no traps: fully lockstep-comparable end to end.
 */
.section .init
.global _start

.macro CKPT
    csrr t2, vl
    csrr t3, vtype
    csrr t4, vstart
.endm

_start:
    li   t0, 0x200            /* mstatus.VS = Initial (bits 10:9 = 01) */
    csrs mstatus, t0
    csrr s0, mstatus          /* VS readback into the compared stream */
    csrr s1, vlenb            /* 16 */

    /* vxsat / vcsr / vstart round-trips (writable, alias, cleared-by-vset) */
    li   t0, 1
    csrw vxsat, t0
    csrr s2, vxsat
    csrr s3, vcsr
    csrw vxsat, x0
    csrr s4, vcsr
    li   t0, 5
    csrw vstart, t0
    csrr s5, vstart

    /* ---- alias-group forwarding windows (adjacent + 1-gap pairs) ---- */
    li   t0, 1
    csrw vxsat, t0
    csrr s6, vcsr             /* 1-apart cross-alias */
    csrw vcsr, x0
    csrr s7, vxsat            /* 1-apart reverse */
    li   t0, 3
    csrw vcsr, t0
    nop
    csrr s8, vxrm             /* 2-apart cross-alias */
    csrw vxsat, x0
    csrr s9, mstatus          /* VS-dirty side-effect window */
    csrw vcsr, x0

    /* ---- e8 grid ---- */
    li   a0, 100
    vsetvli t1, a0, e8, mf4, ta, ma     /* vlmax=4  -> vl=4; also clears vstart */
    CKPT
    li   a0, 3
    vsetvli t1, a0, e8, mf4, ta, ma     /* vl=3 */
    CKPT
    li   a0, 4
    vsetvli t1, a0, e8, mf4, ta, ma     /* vl=4 boundary */
    CKPT
    li   a0, 5
    vsetvli t1, a0, e8, mf4, ta, ma     /* vl=4 (AVL>vlmax) */
    CKPT
    li   a0, 100
    vsetvli t1, a0, e8, mf2, ta, ma     /* vlmax=8 */
    CKPT
    vsetvli t1, a0, e8, m1, ta, ma      /* 16 */
    CKPT
    vsetvli t1, a0, e8, m2, ta, ma      /* 32 */
    CKPT
    li   a0, 200
    vsetvli t1, a0, e8, m8, ta, ma      /* vlmax=128 -> vl=128 */
    CKPT
    li   a0, 1
    vsetvli t1, a0, e8, m8, ta, ma      /* vl=1 */
    CKPT

    /* ---- e16 / e32 grid ---- */
    li   a0, 100
    vsetvli t1, a0, e16, mf2, ta, ma    /* vlmax=4 */
    CKPT
    vsetvli t1, a0, e16, m1, ta, ma     /* 8 */
    CKPT
    vsetvli t1, a0, e16, m4, ta, ma     /* 32 */
    CKPT
    vsetvli t1, a0, e32, m1, ta, ma     /* 4 */
    CKPT
    vsetvli t1, a0, e32, m2, ta, ma     /* 8 */
    CKPT
    li   a0, 7
    vsetvli t1, a0, e32, m2, ta, ma     /* 7 */
    CKPT

    /* ---- vsetivli (immediate AVL) ---- */
    vsetivli t1, 9, e8, m1, ta, ma      /* 9 */
    CKPT
    vsetivli t1, 31, e16, m1, ta, ma    /* min(31, 8) = 8 */
    CKPT
    vsetivli t1, 0, e32, m1, ta, ma     /* vl=0 */
    CKPT

    /* ---- tail/mask policy bit combinations (encoding coverage) ---- */
    li   a0, 100
    vsetvli t1, a0, e8, m1, tu, mu
    CKPT
    vsetvli t1, a0, e8, m1, ta, mu
    CKPT
    vsetvli t1, a0, e8, m1, tu, ma
    CKPT

    /* ---- keep-vl matrix ---- */
    vsetvli t1, a0, e16, m2, ta, ma     /* vlmax=16, vl=16 */
    CKPT
    vsetvli t1, x0, e16, m2, ta, ma     /* rs1=x0 rd!=x0 -> vl=vlmax=16 */
    CKPT
    vsetvli x0, x0, e8, m1, ta, ma      /* rd=x0 rs1=x0, same ratio (8/1 vs 16/2) -> keep vl */
    CKPT
    vsetvli x0, x0, e32, m8, ta, ma     /* ratio change -> match Spike (vill or keep) */
    CKPT
    li   a0, 100
    vsetvli t1, a0, e32, m1, ta, ma     /* recovery to a legal config */
    CKPT

    /* vsetvl (register vtype form) */
    li   a1, 0x0C0                      /* vtype = vsew=e8? bits: vlmul=000,vsew=000,vta[6]=1,vma[7]=1 -> 0xC0 */
    li   a0, 20
    vsetvl t1, a0, a1                   /* e8m1 ta ma -> vl=16 */
    CKPT
    ebreak

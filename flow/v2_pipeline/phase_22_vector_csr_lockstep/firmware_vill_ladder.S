/* ADR-0036 gate_41 — vill ladder (3A scope): illegal vtype configurations must
 * set vill (vtype=0x80000000, vl=0) and a legal vsetvli must recover. Illegal
 * vtypes are injected via the vsetvl register form (rs2 carries a raw vtype),
 * which lets us hit reserved encodings the assembler would reject. Checkpoints
 * after every step. NOTE (recorded in the gate): "vector op after vill traps"
 * is 3B scope — in 3A no vector compute op exists, and a trapping op would end
 * the commit trace; the vill STATE machine is what this ladder verifies.
 */
.section .init
.global _start

.macro CKPT
    csrr t2, vl
    csrr t3, vtype
    csrr t4, vstart
.endm

_start:
    li   t0, 0x200
    csrs mstatus, t0

    /* baseline legal */
    li   a0, 100
    vsetvli t1, a0, e8, m1, ta, ma
    CKPT

    /* fractional-rule violation: e8 mf8 -> SEW/LMUL = 64 > ELEN=32 -> vill */
    li   a1, 0x0C5                    /* vlmul=101(mf8), vsew=000(e8), ta|ma */
    vsetvl t1, a0, a1
    CKPT
    /* recovery */
    vsetvli t1, a0, e8, m1, ta, ma
    CKPT

    /* e16 mf4 -> 64 > 32 -> vill */
    li   a1, 0x0CE                    /* vlmul=110(mf4), vsew=001(e16) */
    vsetvl t1, a0, a1
    CKPT
    vsetvli t1, a0, e16, m1, ta, ma
    CKPT

    /* e32 mf2 -> 64 > 32 -> vill */
    li   a1, 0x0D7                    /* vlmul=111(mf2), vsew=010(e32) */
    vsetvl t1, a0, a1
    CKPT

    /* reserved vlmul=100 -> vill */
    li   a1, 0x0C4
    vsetvl t1, a0, a1
    CKPT

    /* SEW beyond ELEN: vsew=011 (e64) -> vill in Zve32x */
    li   a1, 0x0D8                    /* vlmul=000, vsew=011 */
    vsetvl t1, a0, a1
    CKPT

    /* reserved vtype bits set -> vill */
    li   a1, 0x100C0                  /* bit16 set above the defined fields */
    vsetvl t1, a0, a1
    CKPT

    /* final recovery + boundary re-check */
    li   a0, 2
    vsetvli t1, a0, e8, mf4, ta, ma
    CKPT
    ebreak

// RVV Zve32x int8 dot-product — the ISA-parity vector kernel for Phase 0.
// Widening int8*int8 -> int16 -> int32 accumulate, then reduce. Uses only Zve32x
// (integer EEW<=32), VLEN pinned to 128 via the Zvl128b sub-extension.
#include <riscv_vector.h>

int vdot_i8(const signed char *a, const signed char *b, int n) {
  vint32m1_t acc = __riscv_vmv_v_x_i32m1(0, __riscv_vsetvlmax_e32m1());
  for (int vl; n > 0; n -= vl, a += vl, b += vl) {
    vl = __riscv_vsetvl_e8mf4(n);
    vint8mf4_t  va = __riscv_vle8_v_i8mf4(a, vl);
    vint8mf4_t  vb = __riscv_vle8_v_i8mf4(b, vl);
    vint16mf2_t p  = __riscv_vwmul_vv_i16mf2(va, vb, vl);   // int8*int8 -> int16
    acc = __riscv_vwadd_wv_i32m1(acc, p, vl);               // widen-accumulate -> int32
  }
  vint32m1_t z = __riscv_vmv_v_x_i32m1(0, 1);
  acc = __riscv_vredsum_vs_i32m1_i32m1(acc, z, __riscv_vsetvlmax_e32m1());
  return __riscv_vmv_x_s_i32m1_i32(acc);
}

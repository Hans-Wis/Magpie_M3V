// Driver: known int8 vectors, hand-checkable expected dot product.
// 1*2 + 2*3 + 3*4 + 4*5 + 5*6 + 6*7 + 7*8 + 8*9 = 2+6+12+20+30+42+56+72 = 240
extern int vdot_i8(const signed char *, const signed char *, int);

int npu_main(void) {
  static const signed char a[8] = {1, 2, 3, 4, 5, 6, 7, 8};
  static const signed char b[8] = {2, 3, 4, 5, 6, 7, 8, 9};
  return vdot_i8(a, b, 8);   // == 240
}

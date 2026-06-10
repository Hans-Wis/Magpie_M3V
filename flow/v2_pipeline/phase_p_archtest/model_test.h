#ifndef MAGPIE_M1_ARCH_TEST_MODEL_TEST_H
#define MAGPIE_M1_ARCH_TEST_MODEL_TEST_H

#define RVMODEL_BOOT

#define RVMODEL_HALT       \
  fence;                   \
  la x1, tohost;           \
  li x2, 1;                \
  sw x2, 0(x1);            \
  ebreak;                  \
1:                         \
  j 1b;

#define RVMODEL_DATA_BEGIN \
  .align 4;

#define RVMODEL_DATA_END   \
  .align 4;                \
  .pushsection .tohost,"aw",@progbits; \
  .align 8;                \
  .global tohost;          \
tohost:                    \
  .dword 0;                \
  .global fromhost;        \
fromhost:                  \
  .dword 0;                \
  .popsection;

#define RVMODEL_IO_INIT
#define RVMODEL_IO_WRITE_STR(_R, _STR)
#define RVMODEL_IO_CHECK()
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I)
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

#define RVMODEL_SET_MSW_INT
#define RVMODEL_CLEAR_MSW_INT
#define RVMODEL_CLEAR_MTIMER_INT
#define RVMODEL_CLEAR_MEXT_INT

#endif

/* gate_89/90 firmware (ADR-0070 P1): GPIO directed sequence, then a heartbeat
 * loop the JTAG phase halts/resumes around. sp stays 0x80010000 (crt0) as the
 * abstract-read golden. */
#include <stdint.h>

#define GPIO_BASE      0x11000000u
#define GPIO_OUT       (GPIO_BASE + 0x00u)
#define GPIO_IN        (GPIO_BASE + 0x04u)
#define GPIO_DIR       (GPIO_BASE + 0x08u)

#define SHARED_BASE    0x80000000u
#define FLAG_GPIO_RDY  (SHARED_BASE + 0xFE20u)  /* fw -> TB: DIR/OUT programmed */
#define FLAG_TB_DRIVEN (SHARED_BASE + 0xFE24u)  /* TB -> fw: gpio_in stable     */
#define FLAG_IN_VALUE  (SHARED_BASE + 0xFE28u)  /* fw -> TB: IN readback        */
#define HEARTBEAT      (SHARED_BASE + 0xFE2Cu)

static inline void store32(uint32_t addr, uint32_t data)
{
    *(volatile uint32_t *)addr = data;
}

static inline uint32_t load32(uint32_t addr)
{
    return *(volatile uint32_t *)addr;
}

int main(void)
{
    uint32_t beat = 0;

    store32(FLAG_GPIO_RDY, 0u);
    store32(FLAG_IN_VALUE, 0u);
    store32(HEARTBEAT, 0u);

    store32(GPIO_DIR, 0x000000FFu);
    store32(GPIO_OUT, 0x0000005Au);
    store32(FLAG_GPIO_RDY, 1u);

    while (load32(FLAG_TB_DRIVEN) != 1u) { }
    store32(FLAG_IN_VALUE, load32(GPIO_IN));

    for (;;) {
        beat++;
        store32(HEARTBEAT, beat);
    }
    return 0;
}

#define LED_REG (*(volatile unsigned int *)0x40000000u)

void main(void)
{
    unsigned int pattern = 1u;

    while (1) {
        LED_REG = pattern;
        pattern = ((pattern << 1) | (pattern >> 3)) & 0x0fu;
        if (pattern == 0u)
            pattern = 1u;

        for (volatile unsigned int i = 0; i < 10000u; i++)
            ;
    }
}

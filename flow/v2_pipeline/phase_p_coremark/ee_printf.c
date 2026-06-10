#include <stdarg.h>
#include "core_portme.h"

void uart_send_char(char c);

static void puts_raw(const char *s)
{
    while (*s)
        uart_send_char(*s++);
}

static void print_unsigned(unsigned long v, unsigned base, int width, char pad)
{
    char buf[32];
    unsigned i = 0;

    if (v == 0) {
        buf[i++] = '0';
    } else {
        while (v != 0) {
            unsigned digit = (unsigned)(v % base);
            buf[i++] = (char)(digit < 10 ? '0' + digit : 'a' + digit - 10);
            v /= base;
        }
    }

    while ((int)i < width) {
        uart_send_char(pad);
        width--;
    }
    while (i != 0)
        uart_send_char(buf[--i]);
}

static void print_signed(long v)
{
    if (v < 0) {
        uart_send_char('-');
        print_unsigned((unsigned long)(-v), 10, 0, ' ');
    } else {
        print_unsigned((unsigned long)v, 10, 0, ' ');
    }
}

int ee_printf(const char *fmt, ...)
{
    va_list ap;
    int count = 0;

    va_start(ap, fmt);
    while (*fmt) {
        int long_arg = 0;
        int width = 0;
        char pad = ' ';

        if (*fmt != '%') {
            uart_send_char(*fmt++);
            count++;
            continue;
        }

        fmt++;
        if (*fmt == '0') {
            pad = '0';
            fmt++;
        }
        while (*fmt >= '0' && *fmt <= '9') {
            width = width * 10 + (*fmt - '0');
            fmt++;
        }
        if (*fmt == 'l') {
            long_arg = 1;
            fmt++;
        }

        switch (*fmt) {
        case 's':
            puts_raw(va_arg(ap, const char *));
            break;
        case 'c':
            uart_send_char((char)va_arg(ap, int));
            break;
        case 'd':
        case 'i':
            print_signed(long_arg ? va_arg(ap, long) : va_arg(ap, int));
            break;
        case 'u':
            print_unsigned(long_arg ? va_arg(ap, unsigned long) : va_arg(ap, unsigned int), 10, width, pad);
            break;
        case 'x':
        case 'X':
            print_unsigned(long_arg ? va_arg(ap, unsigned long) : va_arg(ap, unsigned int), 16, width, pad);
            break;
        case '%':
            uart_send_char('%');
            break;
        default:
            uart_send_char('%');
            if (*fmt)
                uart_send_char(*fmt);
            break;
        }
        if (*fmt)
            fmt++;
    }
    va_end(ap);
    return count;
}

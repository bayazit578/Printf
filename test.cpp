#include "stdio.h"
extern "C" int print_f(const char*, ...);

int main() {
    print_f("%s %o %x %b %c%c\n", "10", 0x8, 0x10, 0x2, '1', '0');
    return 0;
}

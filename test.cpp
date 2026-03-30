#include "stdio.h"
#include "math.h"
extern "C" int print_f(const char*, ...);

int main() {
    print_f("%x  %o  %b\n", 0xDEAD, 34535, 23);

    print_f("%s: %x%%\n","Ded_32", 0xded32);

    print_f("%d %d %d %d %d %d %d \n", 1, 1, 1, 1, 1, 1, 1);

    print_f("HELLO %d %d %d %d %d %d %d %d %d %d\n %d %s %x %d%c%b\n", 1, 2, 3, 4, 5,
                                                     6, 7, 8, -9, -10, -1, "love", 3802, 100, 33, 126);
    print_f("\nHello\n");

    print_f("%y %% %b\n", 0b010101010101);
}


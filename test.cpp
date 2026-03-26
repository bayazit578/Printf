#include "stdio.h"
extern "C" int print_f(const char*, ...);

int main() {
    print_f("%s", "sexualize");
    return 0;
}

extern "C" int print_f(const char*, ...);

int main()
{
    print_f("%o", 0x8);
    return 0;
}

#include <kernel/types.h>
#include <user/user.h>
#include <kernel/param.h>


int main(int argc, char *argv[]) {


    if (argc < 2) {
        printf("Usage: %s virtual_address [pid]\n", argv[0]);
    }

        int pid = atoi(argv[1]);
        int va_int = atoi(argv[2]);
        uint64 va_uint = (uint64) va_int;

        uint64 pa = va2pa(pid, va_uint);
        printf("Physical from userspace: 0x%x\n", pa);
    return 1;
}
// Do some random stuff to test EECS151/251A rv32ui processors
#include <stdint.h>

#define csr_tohost(csr_val) { \
    asm volatile ("csrw 0x51e,%[v]" :: [v]"r"(csr_val)); \
}

#ifdef SHORT
#define NUMELTS 64
#define CONST   2080
#else
#define NUMELTS 1024
#define CONST   524800
#endif

unsigned int assert_equals(unsigned int a, unsigned int b);
int x[NUMELTS];
int y[NUMELTS];

void main() {

    int i;
    int j;
    for(i = 0; i < NUMELTS; i++) {
        x[i] = i + 1;
    }

    for(i = 0; i < NUMELTS; i++) {
        y[i] = 0;
        for(j=0; j < i+1; j++) {
            y[i] = y[i] + x[j];
        }
    }

    if(assert_equals(y[NUMELTS-1], CONST)) {
        csr_tohost(1);
    } else {
        csr_tohost(2);
    }

    // spin
    for( ; ; ) {
        asm volatile ("nop");
    }

}

unsigned int assert_equals(unsigned int a, unsigned int b) {
    return (a == b);
}

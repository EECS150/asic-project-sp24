// Do some random stuff to test EECS151/251A rv32ui processors
#include <stdint.h>

#define csr_tohost(csr_val) { \
    asm volatile ("csrw 0x51e,%[v]" :: [v]"r"(csr_val)); \
}

#define NUMELTS 150

unsigned int assert_equals(unsigned int a, unsigned int b);
int x[NUMELTS];

void main() {

    x[0] = 0;
    x[1] = 1;
    int i;
    for(i = 2; i < NUMELTS; i++) {
        x[i] = x[i-1] + x[i-2];
    }


    if(assert_equals(x[35],9227465)) {
    //if(assert_equals(x[10],55)) {
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

// John C. Wright
// johnwright@eecs.berkeley.edu
// Do some random stuff to test EECS151/251A rv32ui processors
#include <stdint.h>

#define csr_tohost(csr_val) { \
    asm volatile ("csrw 0x51e,%[v]" :: [v]"r"(csr_val)); \
}

unsigned int assert_equals(unsigned int a, unsigned int b);
unsigned int fibonacci(unsigned int n);
int dotp(int *a, int* b, int n);
int mul(int a, int b);
void upcase(char *src);
int my_strcmp(char* a, char* b);

int x[5] = {1, 2, 3, 4, -5};
int y[5] = {-5, 4, 3, -2, -1};

char str[10] = "Go Bears!";

void main() {

    if (assert_equals(fibonacci(6),13)) {
        if (assert_equals(dotp(x,y,5),9)) {
            upcase(str);
            if (my_strcmp(str,"GO BEARS!")) {
                // pass
                csr_tohost(1);
            } else {
                // fail code 4
                csr_tohost(4);
            }
        } else {
            // fail code 3
            csr_tohost(3);
        }
    } else {
        // fail code 2
        csr_tohost(2);
    }

    // spin
    for( ; ; ) {
        asm volatile ("nop");
    }

}

// Get the nth fibonacci number
unsigned int fibonacci(unsigned int n) {
    if (n == 0) {
        return 1;
    } else if (n == 1) {
        return 1;
    } else {
        return fibonacci(n-1) + fibonacci(n-2);
    }
}

unsigned int assert_equals(unsigned int a, unsigned int b) {
    return (a == b);
}

int dotp(int *a, int *b, int n) {
    int s = 0;
    for (int i = 0; i < n; i++) {
        s += mul(a[i],b[i]);
    }
    return s;
}

int mul(int a, int b) {
    int accum = 0;
    for (int i = 0; i < 8*sizeof(int); i++) {
        int mask = 1 << i;
        if ((mask & b) != 0) {
            accum += a << i;
        }
    }
    return accum;
}

void upcase(char* src) {
    for (int i = 0; src[i] != '\0'; i++) {
        if(src[i] >= 'a' && src[i] <= 'z') {
            // unset the ASCII lower case bit
            src[i] = src[i] & ~0x20;
        }
    }
}

int my_strcmp(char* a, char* b) {
    int result = 1;
    for (int i = 0; a[i] != '\0'; i++) {
        result &= (a[i] == b[i]);
    }
    return result;
}

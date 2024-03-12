.section    .start
.global     _start

_start:
    li      sp, 0x80000
    jal     main

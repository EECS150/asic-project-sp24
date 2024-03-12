TESTS := $(notdir $(shell find . -type f -name "*.c"))
TESTS_HEX := $(subst .c,.hex,$(TESTS))

ifeq ($(TEST_SIZE), SHORT)
GCC_OPTS  := -march=rv32i -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -DSHORT
else
GCC_OPTS  := -march=rv32i -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none
endif

RISCV_PACKAGE := riscv64-linux-gnu
RISCV_DEFAULT := riscv64-unknown-elf
RISCV_DEFAULT_PRESENT := $(shell command -v $(RISCV_DEFAULT)-gcc 2> /dev/null)

ifdef RISCV_DEFAULT_PRESENT
    RISCV := $(RISCV_DEFAULT)
else
    RISCV := $(RISCV_PACKAGE)
endif

all: $(TESTS_HEX)

%.hex: %.c
	$(RISCV)-gcc $(GCC_OPTS) -T $(basename $(notdir $^)).ld $^ -o $(basename $(notdir $^)).elf
	$(RISCV)-objdump -D -Mnumeric $(basename $(notdir $^)).elf > $(basename $@).dump
	$(RISCV)-objcopy $(basename $@).elf -O binary $(basename $@).bin
	$(RISCV)-bin2hex -w 128 $(basename $@).bin $(basename $@).hex
	../init.sh $(basename $@).hex

clean:
	rm -f *.elf *.bin *.hex *.dump

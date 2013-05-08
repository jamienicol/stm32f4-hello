BINARY = hello
SOURCES = src/main.c
LDSCRIPT = stm32f4-discovery.ld

PREFIX ?= arm-none-eabi

CC = $(PREFIX)-gcc
LD = $(PREFIX)-gcc
OBJCOPY = $(PREFIX)-objcopy
OBJDUMP = $(PREFIX)-objdump
GDB = $(PREFIX)-gdb
FLASH = $(shell which st-flash)

TOOLCHAIN_DIR := $(shell dirname `which $(CC)`)/../$(PREFIX)

CFLAGS += -O2 -g -Wall -Wextra -Werror -MD -DSTM32F4 -std=c99 \
          -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
LDSCRIPT ?= $(BINARY).ld
LDFLAGS += -T$(LDSCRIPT) -nostartfiles -Wl,--gc-sections \
           -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
OBJS = $(SOURCES:.c=.o)

# Be silent per default, but 'make V=1' will show all compiler calls.
ifneq ($(V),1)
Q := @
NULL := 2>/dev/null
else
LDFLAGS += -Wl,--print-gc-sections
endif

.SUFFIXES: .elf .bin .hex .srec .list .images
.SECONDEXPANSION:
.SECONDARY:

all: images

images: $(BINARY).images
flash: $(BINARY).stlink-flash

%.images: %.bin %.hex %.srec %.list
	@#echo "*** $* images generated ***"

%.bin: %.elf
	@#printf "  OBJCOPY $(*).bin\n"
	$(Q)$(OBJCOPY) -Obinary $(*).elf $(*).bin

%.hex: %.elf
	@#printf "  OBJCOPY $(*).hex\n"
	$(Q)$(OBJCOPY) -Oihex $(*).elf $(*).hex

%.srec: %.elf
	@#printf "  OBJCOPY $(*).srec\n"
	$(Q)$(OBJCOPY) -Osrec $(*).elf $(*).srec

%.list: %.elf
	@#printf "  OBJDUMP $(*).list\n"
	$(Q)$(OBJDUMP) -S $(*).elf > $(*).list

%.elf: $(OBJS) $(LDSCRIPT) $(TOOLCHAIN_DIR)/lib/libopencm3_stm32f4.a
	@#printf "  LD      $(subst $(shell pwd)/,,$(@))\n"
	$(Q)$(LD) -o $(*).elf $(OBJS) -lopencm3_stm32f4 $(LDFLAGS)

%.o: %.c Makefile
	@#printf "  CC      $(subst $(shell pwd)/,,$(@))\n"
	$(Q)$(CC) $(CFLAGS) -o $@ -c $<

clean:
	$(Q)rm -f $(OBJS)
	$(Q)rm -f $(OBJS:.o=.d)
	$(Q)rm -f *.elf
	$(Q)rm -f *.bin
	$(Q)rm -f *.hex
	$(Q)rm -f *.srec
	$(Q)rm -f *.list

%.stlink-flash: %.bin
	@printf "  FLASH  $<\n"
	$(Q)$(FLASH) write $(*).bin 0x8000000

.PHONY: images clean

-include $(OBJS:.o=.d)

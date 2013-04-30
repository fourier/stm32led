# Using the CodeSourcery Lite ARM EABI tools
CROSS_COMPILE = arm-none-eabi-
CC   = $(CROSS_COMPILE)gcc
LD   = $(CROSS_COMPILE)ld
CP   = $(CROSS_COMPILE)objcopy
SZ   = $(CROSS_COMPILE)size
HEX  = $(CP) -O ihex 
BIN  = $(CP) -O binary
MCU  = cortex-m3

# 
# Define project name and Ram/Flash mode here
PROJECT        = main
RUN_FROM_FLASH = 1

# Paths
# Path to the STM32 Standard Peripherial library
# one can dowload it here: http://www.st.com/st-web-ui/static/active/en/st_prod_software_internet/resource/technical/software/firmware/stsw-stm32054.zip
# or go to st.com, search for your product (STM32F103VET in my case), go to Design Resources tab
# and find it (the product name STSW-STM32054 in my case)
STDLIBROOT = ../STM32F10x_StdPeriph_Lib_V3.5.0
# libraries subdirectory
LIBSDIR    = $(STDLIBROOT)/Libraries
# path to the STM32 STDLib project template - needed for stm32*conf.h
STMTMPLINCDIR = $(STDLIBROOT)/Project/STM32F10x_StdPeriph_Template
CORELIBDIR = $(LIBSDIR)/CMSIS/CM3/CoreSupport
DEVDIR  = $(LIBSDIR)/CMSIS/CM3/DeviceSupport/ST/STM32F10x
STMSPDDIR    = $(LIBSDIR)/STM32F10x_StdPeriph_Driver
STMSPSRCDDIR = $(STMSPDDIR)/src
STMSPINCDDIR = $(STMSPDDIR)/inc
# device directory contains the device dependent files which are not a part of STD library
DEVICE       = ./Device
STARTUP      = $(DEVICE)/startup
LINKER       = $(DEVICE)/linker

# Directory to store generated object files
OBJDIR = ./obj


# List C source files here
SRC  = main.c
SRC += $(CORELIBDIR)/core_cm3.c
SRC += $(DEVDIR)/system_stm32f10x.c
SRC += $(STARTUP)/crt.c 
SRC += $(STARTUP)/vectors_stm32f10x_hd.c
## used parts of the STM-Library
#SRC += $(STMSPSRCDDIR)/stm32f10x_usart.c
#SRC += $(STMSPSRCDDIR)/stm32f10x_flash.c
SRC  += $(STMSPSRCDDIR)/stm32f10x_gpio.c
SRC  += $(STMSPSRCDDIR)/stm32f10x_rcc.c
#SRC += $(STMSPSRCDDIR)/stm32f10x_spi.c
#SRC += $(STMSPSRCDDIR)/stm32f10x_rtc.c
#SRC += $(STMSPSRCDDIR)/stm32f10x_bkp.c
#SRC += $(STMSPSRCDDIR)/stm32f10x_pwr.c
#SRC += $(STMSPSRCDDIR)/stm32f10x_dma.c
#SRC += $(STMSPSRCDDIR)/stm32f10x_tim.c
#SRC += $(STMSPSRCDDIR)/stm32f10x_exti.c
#SRC += $(STMSPSRCDDIR)/misc.c


# List all include directories here
DINCDIR = $(CORELIBDIR) \
          $(DEVDIR) \
          $(STMSPINCDDIR) \
					$(STMTMPLINCDIR)


# List all default C defines here, like -D_DEBUG=1
DDEFS = -DSTM32F10X_HD -DUSE_STDPERIPH_DRIVER

# Define linker script file here
ifeq ($(RUN_FROM_FLASH), 0)
LDSCRIPT = $(LINKER)/stm32f103xe_ram.ld
FULL_PRJ = $(PROJECT)_ram
else
LDSCRIPT = $(LINKER)/stm32f103xe_flash.ld
FULL_PRJ = $(PROJECT)_rom
endif

INCDIR  = $(patsubst %,-I%,$(DINCDIR))

ifeq ($(RUN_FROM_FLASH), 0)
DEFS    = $(DDEFS) $(UDEFS) -DRUN_FROM_FLASH=0 -DVECT_TAB_SRAM
else
DEFS    = $(DDEFS) $(UDEFS) -DRUN_FROM_FLASH=1
endif

FNAMES = $(foreach file, $(SRC), $(notdir $(file)))
OBJECTS = $(foreach file, $(FNAMES:.c=.o), $(OBJDIR)/$(file))

CFLAGS =  -mcpu=$(MCU) -gdwarf-2 -ggdb -mthumb -fomit-frame-pointer -Wall $(DEFS)
#CFLAGS =  -mcpu=$(MCU) -gdwarf-2 -mthumb -fomit-frame-pointer -Wall -Wstrict-prototypes $(DEFS)
LDFLAGS = -mcpu=$(MCU) -mthumb -gdwarf-2 -ggdb -nostartfiles -T$(LDSCRIPT) -Wl,-Map=$(FULL_PRJ).map,--cref,--no-warn-mismatch

# Generate dependency information
CFLAGS += -MD -MP -MF .dep/$(@F).d

# Macro to create a target: object file in the $(OBJDIR) directory
define make-deps
$(OBJDIR)/$(notdir $(1:%.c=%.o)): $1
endef

# First target - .elf, .hex and .bin files
all: $(FULL_PRJ).elf $(FULL_PRJ).hex $(FULL_PRJ).bin
	@echo Size of the sections:
	@$(SZ) $(FULL_PRJ).elf

# generate list of target - a target per file
$(foreach d, $(SRC), $(eval $(call make-deps,$d)))

$(OBJDIR):
	@mkdir -p $(OBJDIR)

# ensure we have $(OBJDIR) before building objects
$(OBJECTS): | $(OBJDIR)


%.o : # Dependencies declared above
	@echo Compiling $< into $@
	$(CC) -c $(CFLAGS) -I . $(INCDIR) $< -o $@


%elf: $(OBJECTS)
	@echo Linking $@
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

%hex: %elf
	@echo Creating $@
	@$(HEX) $< $@

%bin: %elf
	@echo Creating $@
	@$(BIN) $< $@


clean:
	-rm -f $(OBJECTS)
	-rm -fr $(OBJDIR)
	-rm -f $(FULL_PRJ).elf
	-rm -f $(FULL_PRJ).map
	-rm -f $(FULL_PRJ).hex
	-rm -f $(FULL_PRJ).bin
	-rm -fR .dep

# flash the binary to the device using serial port
flash:
	stm32flash -w main_rom.hex -v -g 0x0 /dev/tty.PL2303-000013FA

# 
# Include the dependency files, should be the last of the makefile
#
-include $(shell mkdir .dep 2>/dev/null) $(wildcard .dep/*)

# *** EOF ***

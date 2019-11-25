#
# ReGBA for the RetroFW
#
# by pingflood; 2019
#

TARGET = regba/regba.dge

CHAINPREFIX := /opt/mipsel-linux-uclibc
CROSS_COMPILE := $(CHAINPREFIX)/usr/bin/mipsel-linux-

CC          := $(CROSS_COMPILE)gcc
STRIP       := $(CROSS_COMPILE)strip

SYSROOT     := $(shell $(CC) --print-sysroot)
SDL_CFLAGS  := $(shell $(SYSROOT)/usr/bin/sdl-config --cflags)
SDL_LIBS    := $(shell $(SYSROOT)/usr/bin/sdl-config --libs)

OBJS        := ./source/opendingux/main.o ./source/opendingux/draw.o ./source/opendingux/port.o ./source/opendingux/port-asm.o ./source/opendingux/od-input.o ./source/video.o          \
              ./source/input.o ./source/bios.o ./source/zip.o ./source/sound.o ./source/mips/stub.o         \
              ./source/stats.o ./source/memory.o ./source/cpu_common.o ./source/cpu_asm.o ./source/opendingux/od-sound.o  \
              ./source/sha1.o ./source/opendingux/imageio.o ./source/unifont.o ./source/opendingux/gui.o ./source/opendingux/od-memory.o ./source/opendingux/settings.o

HEADERS     := ./source/opendingux/cheats.h ./source/common.h ./source/cpu_common.h ./source/cpu.h ./source/opendingux/draw.h ./source/opendingux/main.h    \
               ./source/input.h ./source/memory.h ./source/opendingux/message.h ./source/mips/emit.h ./source/sound.h     \
               ./source/stats.h ./source/video.h ./source/zip.h ./source/opendingux/port.h ./source/opendingux/od-sound.h ./source/sha1.h     \
               ./source/opendingux/imageio.h ./source/unifont.h ./source/opendingux/od-input.h ./source/opendingux/settings.h

INCLUDE     := -I./source/opendingux/ -I./source -I./source/mips
OPTIMIZE =  -O2 -mips32 -march=mips32 -mno-mips16 -fomit-frame-pointer -fno-builtin   \
            -Wno-write-strings -Wno-sign-compare -ffast-math -ftree-vectorize \
			-funswitch-loops -fno-strict-aliasing

DEFS        := -DGCW_ZERO -DRETROGAME -DMIPS_XBURST -DLOAD_ALL_ROM \
               -DGIT_VERSION=$(shell git describe --always)
HAS_MIPS32R2 := $(shell echo | $(CC) -dM -E - |grep _MIPS_ARCH_MIPS32R2)
ifneq ($(HAS_MIPS32R2),)
	DEFS += -DMIPS_32R2
endif

CFLAGS      := $(SDL_CFLAGS) -mno-abicalls -Wall -Wno-unused-variable \
               -O2 -fomit-frame-pointer $(DEFS) $(INCLUDE) $(OPTIMIZE)
ASFLAGS     := $(CFLAGS) -D__ASSEMBLY__
LDFLAGS     := $(SDL_LIBS) -lpthread -lz -lm -lpng

DATA_TO_CLEAN := .opk_data $(TARGET).opk regba/regba.ipk

include ./source/Makefile.rules

.PHONY: all opk

all: $(TARGET)

ipk: $(TARGET)
	@rm -rf /tmp/.regba-ipk/ && mkdir -p /tmp/.regba-ipk/root/home/retrofw/.gpsp /tmp/.regba-ipk/root/home/retrofw/emus/regba /tmp/.regba-ipk/root/home/retrofw/apps/gmenu2x/sections/emulators /tmp/.regba-ipk/root/home/retrofw/apps/gmenu2x/sections/emulators.systems
	@cp regba/game_config.txt /tmp/.regba-ipk/root/home/retrofw/.gpsp
	@cp regba/regba.dge regba/regba.png regba/regba.man.txt bios/gba_bios.bin regba/regba-sp-border-silver.png /tmp/.regba-ipk/root/home/retrofw/emus/regba
	@cp regba/regba.lnk /tmp/.regba-ipk/root/home/retrofw/apps/gmenu2x/sections/emulators
	@cp regba/gba.regba.lnk /tmp/.regba-ipk/root/home/retrofw/apps/gmenu2x/sections/emulators.systems
	@sed "s/^Version:.*/Version: $$(date +%Y%m%d)/" regba/control > /tmp/.regba-ipk/control
	@cp regba/conffiles /tmp/.regba-ipk/
	@tar --owner=0 --group=0 -czvf /tmp/.regba-ipk/control.tar.gz -C /tmp/.regba-ipk/ control conffiles
	@tar --owner=0 --group=0 -czvf /tmp/.regba-ipk/data.tar.gz -C /tmp/.regba-ipk/root/ .
	@echo 2.0 > /tmp/.regba-ipk/debian-binary
	@ar r regba/regba.ipk /tmp/.regba-ipk/control.tar.gz /tmp/.regba-ipk/data.tar.gz /tmp/.regba-ipk/debian-binary

opk: $(TARGET)
	@mksquashfs \
	regba/default.retrofw.desktop \
	regba/regba.dge \
	regba/game_config.txt \
	regba/regba.png \
	regba/regba.man.txt \
	bios/gba_bios.bin \
	regba/regba-sp-border-silver.png \
	regba/regba.opk \
	-all-root -noappend -no-exports -no-xattrs

# The two below declarations ensure that editing a .c file recompiles only that
# file, but editing a .h file recompiles everything.
# Courtesy of Maarten ter Huurne.

# Each object file depends on its corresponding source file.
$(C_OBJS): %.o: %.c

# Object files all depend on all the headers.
$(OBJS): $(HEADERS)

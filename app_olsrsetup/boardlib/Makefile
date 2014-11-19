CROSS_COMPILE?=msp430-
AR:=$(CROSS_COMPILE)ar
LD:=$(CROSS_COMPILE)ld
CC:=$(CROSS_COMPILE)gcc

PICODIR?=../../lib/picotcp
PREFIX?=$(PWD)/build

LIBNAME:=libpico_msp430_tiny.a

CFLAGS =-c -Wall
CFLAGS += -I$(PREFIX)/include/arch/
CFLAGS += -I$(PREFIX)/include/
CFLAGS += -I$(PREFIX)/lib/

LDFLAGS += -L$(PREFIX)

SOURCES=pico_msp430_tiny.c

LIB_OBJ=pico_msp430_tiny.o
LIB_AR=$(PREFIX)/lib/$(LIBNAME)

all: libpico_msp430_tiny

libpico_msp430_tiny:
	@make -C $(PICODIR) deps PREFIX=$(PREFIX)
	@cp -f $(PICODIR)/include/*.h $(PREFIX)/include
	@cp -fa $(PICODIR)/include/arch $(PREFIX)/include
	@cp -f $(PICODIR)/modules/*.h $(PREFIX)/include
	@$(CC) $(CFLAGS) $(SOURCES) -o $(PREFIX)/lib/$(LIB_OBJ)
	$(AR) cr $(LIB_AR) $(PREFIX)/lib/$(LIB_OBJ)

clean:
	rm -rf $(PREFIX)

FORCE:

CC=msp430-gcc
CFLAGS=-c -Wall
CFLAGS += -I.././build/include/arch/
CFLAGS += -I.././build/include/

SOURCES=pico_msp430_tiny.c

all: libpico_msp430_tiny.a

pico_msp430_tiny.o: pico_msp430_tiny.c
	$(CC) $(CFLAGS) pico_msp430_tiny.c

libpico_msp430_tiny.a: pico_msp430_tiny.o
	ar cr libpico_msp430_tiny.a pico_msp430_tiny.o
clean:
	rm -rf pico_msp430_tiny.o 
	rm -rf *.o 

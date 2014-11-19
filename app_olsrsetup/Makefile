COMPONENT=PicoAppC
BOARDLIBDIR=../lib/boardlib

TINYOS_ROOT_DIR?=../lib/tinyos-main
include $(TINYOS_ROOT_DIR)/Makefile.include
MAKERULES=$(TINYOS_ROOT_DIR)/support/make/Makerules

PICODIR=../lib/picotcp
PREFIX?=$(PWD)/build
PRINTF_ENABLED?=0
PFLAGS += -DSERIAL_MESSAGING
BUILD_EXTRA_DEPS += PicoSerial.class
CLEAN_EXTRA += *.class PicoSerialMsg.java
SERIAL_MESSAGING=1

CFLAGS += -I./build/include/
CFLAGS += -I./build/include/arch/
CFLAGS += -I$(BOARDLIBDIR)/


LDFLAGS += -L./build/lib
LDFLAGS += -lpicotcp
LDFLAGS += -lpico_msp430_tiny

LDFLAGS += -Wl,-Map=./build/telosb/mapfile.map

PFLAGS += -DCC2420_HW_ACKNOWLEDGEMENTS
PFLAGS += -DCC2420_HW_ADDRESS_RECOGNITION
PFLAGS += -DPACKET_LINK

PFLAGS += -DTOSH_DATA_LENGTH=112

TOSMAKE_PRE_EXE_DEPS += libpicotcp.a

TOSMAKE_CLEAN_EXTRA += picoclean.a

libpicotcp.a:
	make -C $(PICODIR) ARCH=msp430 CROSS_COMPILE=msp430- TFTP=0 SNTP_CLIENT=0 MDNS=0 UDP=1 TCP=0 MCAST=0 IPFRAG=1 IPV6=0 OLSR=1 DNS_CLIENT=0 DHCP_CLIENT=0 HTTP_CLIENT=0 DHCP_SERVER=0 HTTP_SERVER=0 ICMP4=1 SLAACV4=0 ZMQ=0 ETH=0 DEVLOOP=0 NAT=0 IPFILTER=0 SIMPLE_HTTP=0 DEBUG=1
	make -C $(BOARDLIBDIR) PREFIX=$(PREFIX)

picoclean:
	make -C $(PICODIR) PREFIX=$(PREFIX) clean
	make -C $(BOARDLIBDIR) PREFIX=$(PREFIX) clean

PicoSerial.class: $(wildcard *.java) PicoSerialMsg.java
	javac -target 1.4 -source 1.4 *.java

PicoSerialMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=PicoSerialMsg PicoSerial.h pico_serial_msg  -o $@

include $(MAKERULES)

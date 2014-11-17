#ifndef PICO_SERIAL_H
#define PICO_SERIAL_H

enum {
  AM_PICO_SERIAL_MSG = 0x89,
};
typedef nx_struct pico_serial_msg {
   nx_uint8_t protocol;
   nx_uint8_t error ;
   //nx_uint32_t bytes;
   nx_uint32_t dest;
   nx_uint32_t gateway;
   nx_uint32_t metric;
   //nx_uint32_t time;
} pico_serial_msg_t;

#endif

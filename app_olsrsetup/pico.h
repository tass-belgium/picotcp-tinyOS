#ifndef PICO_H
#define PICO_H
//#include "pico_config.h"
  
// The max packet datagram unit is defined by testing. Larger PDU fails packet transmission.
#define MAX_802154_PHY_PDU 111 


typedef struct pico_radio_msg {
  uint8_t buffer[MAX_802154_PHY_PDU];
  uint8_t length;
} test_pico_msg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif

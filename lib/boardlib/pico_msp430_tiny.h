/*********************************************************************
   PicoTCP. Copyright (c) 2012 TASS Belgium NV. Some rights reserved.
   See LICENSE and COPYING for usage.

 *********************************************************************/
#ifndef _INCLUDE_TINY_MSP430
#define _INCLUDE_TINY_MSP430

#include "pico_constants.h"

extern void msp430_inc_time_ms(void);
extern void msp430_init_time(void);

//#define dbg(...)
  #define printf(...) {}
  #define printfflush(...) {}

#endif

/*********************************************************************
   PicoTCP. Copyright (c) 2012 TASS Belgium NV. Some rights reserved.
   See LICENSE and COPYING for usage.

 *********************************************************************/
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "pico_msp430_tiny.h"
#include "pico_msp430.h"
#include "pico_constants.h"

static pico_time timestamp;

pico_time msp430_time_s(){
     return timestamp/1000;
}

pico_time msp430_time_ms(){
     return timestamp;
}

void msp430_inc_time_ms(){
     timestamp++;
}

void msp430_init_time(){
     timestamp=0;
}

// $Id: PicoAppC.nc
/*********************************************************************
PicoTCP. Copyright (c) 2012 TASS Belgium NV. Some rights reserved.
See LICENSE and COPYING for usage.
Do not redistribute without a written permission by the Copyright
holders.

Author: Brecht Van Cauwenberghe
*********************************************************************/
// Minimum size pool = 3
#define RADIO_POOL_SIZE 7
#define SERIAL_POOL_SIZE 7

#define RADIO_RECV_QUEUE_SIZE 7
#define RADIO_SEND_QUEUE_SIZE 7
#define PRINT_QUEUE_SIZE 90

#ifdef SERIAL_MESSAGING
  #define SERIAL_QUEUE_SIZE 30
  #include "PicoSerial.h"
#endif

#include "Timer.h"
#include "pico_device.h"
#include "pico_addressing.h"
#include "pico_ipv4.h"
#include "pico_stack.h"
#include "pico.h"
#include "pico_msp430_tiny.h"


#include "pico_olsr.h"

configuration PicoAppC {
}
implementation {
  components PicoC as App;
  components MainC, LedsC;
  components PicoDriverC;
  components new PoolC(message_t, RADIO_POOL_SIZE) as RadioPool;
  components new PoolC(message_t, SERIAL_POOL_SIZE) as SerialPool;
  components new QueueC(message_t*, RADIO_SEND_QUEUE_SIZE) as RadioSendQueue;
  components new QueueC(message_t*, RADIO_RECV_QUEUE_SIZE) as RadioRecvQueue;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  components ActiveMessageC;

  // Wiring of the application
  App.Boot -> MainC.Boot;
  App.CC2420dev -> PicoDriverC;
  App.Leds -> LedsC;
  //  App.Timer0 -> Timer0;
  App.Timer1 -> Timer2;

  #ifdef SERIAL_MESSAGING
    components SerialActiveMessageC as AMSerial;
    components new QueueC(message_t *, SERIAL_QUEUE_SIZE) as SerialSendQueue;
    components new QueueC(void *, PRINT_QUEUE_SIZE) as PingQueue;
    components new QueueC(void *, PRINT_QUEUE_SIZE) as RouteQueue;
    App.SerialControl -> AMSerial;
    App.SerialRX -> AMSerial.Receive[AM_PICO_SERIAL_MSG];
    App.SerialTX -> AMSerial.AMSend[AM_PICO_SERIAL_MSG];
    App.Packet -> AMSerial;
    App.MsgPool -> SerialPool;
    App.PrintRouteQueue -> RouteQueue;
    App.PrintPingQueue -> PingQueue;
    App.SendQueue -> SerialSendQueue;
  #else
    // printf enabled
    components SerialStartC;
    components PrintfC;
  #endif

  // Wiring of the driver
  PicoDriverC.RadioPool -> RadioPool;
  PicoDriverC.SendQueue -> RadioSendQueue;
  PicoDriverC.RecvQueue -> RadioRecvQueue;
  PicoDriverC.Timer1 -> Timer1;
  PicoDriverC.Packet -> AMSenderC;
  PicoDriverC.Boot -> MainC.Boot;
  PicoDriverC.Receive -> AMReceiverC;
  PicoDriverC.AMSend -> AMSenderC;
  PicoDriverC.AMControl -> ActiveMessageC;
  PicoDriverC.Leds -> LedsC;
  }

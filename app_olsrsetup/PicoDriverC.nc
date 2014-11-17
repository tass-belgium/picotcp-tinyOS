// $Id: PicoDriverC.nc
/*********************************************************************
  PicoTCP. Copyright (c) 2011 TASS Belgium NV. Some rights reserved.
  See LICENSE and COPYING for usage.
  Do not redistribute without a written permission by the Copyright
  holders.

Author: Brecht Van Cauwenberghe
 *********************************************************************/
#include "pico.h"
#include "pico_ipv4.h"
#include "pico_device.h"
#include "pico_stack.h"
#include "pico_constants.h"
#include "pico_msp430_tiny.h"
#define HOST_NETMASK 0xFF000000

module PicoDriverC @safe() {
    provides interface CC2420dev;

    uses interface Timer<TMilli> as Timer1;
    uses interface Boot;
    uses interface Pool<message_t> as RadioPool;
    uses interface Queue<message_t *> as SendQueue;
    uses interface Queue<message_t *> as RecvQueue;
    uses interface Leds;
    uses interface Receive;
    uses interface AMSend;
    uses interface SplitControl as AMControl;
    uses interface Packet;
}

implementation {
    //message_t sendpacket;
    bool locked=FALSE;
    bool started=FALSE;
    struct pico_ip4 target;
    void sendTask();
    struct pico_ip4 *ptarget, *pdest, *psource, gateway;
    static uint16_t gateway_address=0xFFFF;
    uint8_t * protocol = NULL;


    int tinyERR(void) {
        volatile int c = 3600;
        c++;
        return -1;
    }


    //////////////////////////////////////////////////////////////////
    //  CONTROL CONNECTIONS
    //////////////////////////////////////////////////////////////////

    event void Boot.booted() {
        call AMControl.start();
        call Timer1.startPeriodic(1);
        msp430_init_time();
    }

    //////////////////////////////////////////////////////////////////
    //  PICO DEVICE CONNECTIONS
    //////////////////////////////////////////////////////////////////
    event void Timer1.fired() {
        msp430_inc_time_ms();
    }

    /*******************************************
     * Send callback function of pico device    *
     *******************************************/
    int pico_cc2420_send(struct pico_device *dev, void *buf, int length) {
        test_pico_msg_t* rcm = NULL;
        message_t* psendpacket = NULL;

        if (locked) {
            call Leds.led0On();
            return 0;
        }

        psendpacket = call RadioPool.get();
        if (psendpacket == NULL) {
            tinyERR();
            call Leds.led0On();
            return 0;
        }

        rcm = (test_pico_msg_t*) call Packet.getPayload(psendpacket, sizeof(test_pico_msg_t));
        if (rcm == NULL) {
            call RadioPool.put(psendpacket);
            call Leds.led0On();
            tinyERR();
            return 0;
        }

        if(length <= TOSH_DATA_LENGTH) {
            memcpy(rcm->buffer,buf,length);
            rcm->length = length;
        } else {
            call RadioPool.put(psendpacket);
            call Leds.led0On();
            tinyERR();
            return 0;
        }

        pdest = (struct pico_ip4 *) &(rcm->buffer[16]);
        ptarget = (struct pico_ip4 *) &(rcm->buffer[16]);
        psource = (struct pico_ip4 *) &(rcm->buffer[12]);
        protocol = (uint8_t *) &(rcm->buffer[9]);
        target.addr = (ptarget->addr);
        gateway = pico_ipv4_route_get_gateway(&target);
        //if (*protocol == 1)
            tinyERR();
        if (gateway.addr == 0u) {
            gateway_address = (uint16_t) long_be(HOST_NETMASK & (ptarget->addr));
            // if is broadcast make broadcast
            if (gateway_address == 0xFF){
                gateway_address = 0xFFFF;
            }
        } else {
            // multihop neighbour, can be send via gateway
            gateway_address = (uint16_t) long_be(HOST_NETMASK & (gateway.addr));
        }

        if (call AMSend.send(gateway_address, psendpacket, sizeof(test_pico_msg_t)) == SUCCESS){
            call Leds.led1On();
            locked = TRUE;
        }else{
            call Leds.led0On();
            call RadioPool.put(psendpacket);
            return 0;
        }
        return length;
    }

    /*******************************************
     * poll callback function of pico device    *
     *******************************************/
    int pico_cc2420_poll(struct pico_device * dev, int loop_score) {
        // Get the reassembled packets out the buffer and return them towards the picostack
        test_pico_msg_t* rcm=NULL;
        message_t* recvmsg=NULL;

        if(call RecvQueue.empty() == FALSE){
            recvmsg = call RecvQueue.dequeue();

            if (recvmsg == NULL) {
                tinyERR();
                return loop_score;
            }

            rcm = (test_pico_msg_t*) call Packet.getPayload(recvmsg, sizeof(test_pico_msg_t));
            if (rcm == NULL) {
                call RadioPool.put(recvmsg);
                call Leds.led0On();
                tinyERR();
                return loop_score;
            }

            if (pico_stack_recv(dev, rcm->buffer, rcm->length) <=0) {
                call RadioPool.put(recvmsg);
                call Leds.led0On();
                tinyERR();
                return loop_score;
            }

            call Leds.led2Off();
            call RadioPool.put(recvmsg);

        }
        return loop_score--;
    }

    /*******************************************
     * Create function of pico device           *
     *******************************************/
    command struct pico_device* CC2420dev.create() {
        // TODO pass the device name as an argument to the create function
        struct pico_device* ccdev = pico_zalloc(sizeof(struct pico_device));
        char name[]={"CC2440"};
        if( 0 != pico_device_init((struct pico_device *)ccdev, name, NULL)) {
            tinyERR();
            return NULL;
        }

        ccdev->send = pico_cc2420_send;
        ccdev->poll = pico_cc2420_poll;

        return ccdev;
    }

    //////////////////////////////////////////////////////////////////
    // RADIO CC2420 CONNECTIONS
    //////////////////////////////////////////////////////////////////

    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS && started == FALSE ) {
            locked = FALSE;
            // for some reason this call is triggered multiple times after startup,
            // the started parameter prevents unwanted locking
            started = TRUE;
        } else {
            call AMControl.start();
        }
    }

    event void AMControl.stopDone(error_t err) {
        // do nothing
    }

    event message_t* Receive.receive(message_t* bufPtr,  void* payload, uint8_t length) {
        test_pico_msg_t* rcm = NULL;
        message_t* precvpacket = NULL;

        precvpacket = call RadioPool.get();
        if (precvpacket == NULL) {
            tinyERR();
            return bufPtr;
        }

        rcm = (test_pico_msg_t*) call Packet.getPayload(precvpacket, sizeof(test_pico_msg_t));
        if (rcm == NULL) {
            call RadioPool.put(precvpacket);
            tinyERR();
            return bufPtr;
        }

        if(length <= TOSH_DATA_LENGTH) {
            memcpy(rcm->buffer,payload,length);
            rcm->length = length;
        } else {
            call RadioPool.put(precvpacket);
            tinyERR();
            return bufPtr;
        }

        // HEADER
        if (call RecvQueue.enqueue(precvpacket) != SUCCESS) {
            call RadioPool.put(precvpacket);
            tinyERR();
            return bufPtr;
        }

        call Leds.led2On();
        return bufPtr;
    }

    event void AMSend.sendDone(message_t* bufPtr, error_t error) {
        // checking if the correct packet was send
        call Leds.led1Off();
        call RadioPool.put(bufPtr);
        locked = FALSE;
    }
}

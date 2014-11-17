// $Id: PicoC.nc
/*********************************************************************
  PicoTCP. Copyright (c) 2012 TASS Belgium NV. Some rights reserved.
  See LICENSE and COPYING for usage.
  Do not redistribute without a written permission by the Copyright
  holders.

Author: Brecht Van Cauwenberghe
 *********************************************************************/

#define PICO_PING_TEST 1
#define OSLR_ENABLED 1

#define SERIAL_MSG_TYPE_ROUTE 1
#define SERIAL_MSG_TYPE_PING 2

#include "Timer.h"
#include "pico_device.h"
#include "pico_addressing.h"
#include "pico_ipv4.h"
#include "pico_stack.h"
#include "pico.h"
#include "pico_msp430_tiny.h"

#if PICO_PING_TEST
#include "pico_icmp4.h"
#endif

#include "pico_olsr.h"

#define NUM_PING 1


module PicoC @safe() {
    uses {
        interface CC2420dev;
        //interface Timer<TMilli> as Timer0;
        interface Timer<TMilli> as Timer1;
        interface Leds;
        interface Boot;
        interface Packet;
        interface SplitControl as SerialControl;
        interface AMSend as SerialTX;
        interface Receive as SerialRX;
        interface Pool<message_t> as MsgPool;
        interface Queue<message_t *> as SendQueue;
        interface Queue<void *> as PrintRouteQueue;
        interface Queue<void *> as PrintPingQueue;
    }
}

implementation {
    struct pico_device* pdev = NULL;
    struct pico_ip4 hostip;
    char localipaddr[30];
    bool SerialLocked = TRUE;
    struct pico_ip4 mask;
    uint8_t i;
    uint8_t seconds = 0;
    pico_time timestamp=0;
    uint16_t interval = 1000;
    uint16_t timeout  = 9999;
    uint8_t size  = 28;
    uint8_t poolsize = 0;
    uint16_t counter;
    static uint16_t integer = 0;

    int tinyOOM(void) {
        volatile int c = 3600;
        c++;
        c++;
        c++;
        return -1;
    }

    int tinyERR(void) {
        volatile int c = 3600;
        c++;
        return -1;
    }


    static int serialPrintTask(){
        struct pico_ipv4_route *entry=NULL;
        struct pico_icmp4_stats *status=NULL;
        struct pico_ip4 address;
        pico_serial_msg_t* rcm = NULL;
        message_t* packet = NULL;
        if (SerialLocked){
            return 0;
        }

        if (call PrintRouteQueue.empty() == FALSE){
            entry = call PrintRouteQueue.dequeue();
        }else if (call PrintPingQueue.empty() == FALSE){
            status = call PrintPingQueue.dequeue();
        }else{
            tinyERR();
            return 0;
        }

        if (entry == NULL && status==NULL) {
            tinyERR();
            return -1;
        }

        ////////////////////////////////////////////////////////////////////////
        // GOT an entry/status => Create a serial message packet
        ////////////////////////////////////////////////////////////////////////

        packet = call MsgPool.get();
        if(packet == NULL){
            tinyOOM();
            return -1;
        }

        rcm = (pico_serial_msg_t*)call Packet.getPayload(packet, sizeof(pico_serial_msg_t));
        if (rcm == NULL) {
            tinyOOM();
            call MsgPool.put(packet);
            return -1;
        }

        if (entry != NULL) {
            rcm->protocol = PICO_PROTO_MANET;
            rcm->dest = 0xFF & long_be(entry->dest.addr);
            rcm->metric = entry->metric;
            rcm->error = call PrintRouteQueue.size();
            rcm->gateway = 0xFF & long_be(entry->gateway.addr);
        }else if(status != NULL){
            address = pico_ipv4_route_get_gateway(&(status->dst));
            rcm->protocol = PICO_PROTO_ICMP4;
            rcm->dest = 0xFF & long_be(status->dst.addr);
            rcm->metric = status->size;
            rcm->error = status->err;
            rcm->gateway = 0xFF & long_be(address.addr);
        } else {
            call MsgPool.put(packet);
            return -1;
        }

        ////////////////////////////////////////////////////////////////////////
        // GOT a packet put it on the serial port
        ////////////////////////////////////////////////////////////////////////
        if (call SerialTX.send(AM_BROADCAST_ADDR, packet, sizeof(pico_serial_msg_t)) == SUCCESS) {
            SerialLocked = TRUE;
            return 0;
        }else{
            return 1;
        }
    }

    void cb_ping(struct pico_icmp4_stats *s) {
        if (call PrintPingQueue.enqueue(s) == SUCCESS) {
            serialPrintTask();
        }else{
            call Leds.led0On();
            tinyERR();
        }
    }


    static int olsr_print_route_entry(struct pico_ipv4_route * entry){
        if (call PrintRouteQueue.enqueue(entry) == SUCCESS) {
            serialPrintTask();
        } else {
            tinyERR();
        }
        return 0;
    }

    int print_routes() {
        struct pico_tree_node *index;
        struct pico_ipv4_route * entry;
        char addr[16];

        pico_tree_foreach(index, &Routes) {
            entry = index->keyValue;
            olsr_print_route_entry(entry);
            pico_ipv4_to_string(addr, entry->dest.addr);
            //if ((TOS_NODE_ID == 170) && (entry->metric>3)) {
                //seconds++;
                //if (seconds >= 5) {
                //    pico_icmp4_ping(addr, NUM_PING, interval, timeout, size, cb_ping);
                //    seconds = 0;
                //}
            //}
        }
        return 0;
    }

    event void SerialControl.startDone(error_t err) {
        if (err == SUCCESS) {
            SerialLocked=FALSE;
        }
    }

    event void SerialControl.stopDone(error_t err) {}

    event void SerialTX.sendDone(message_t* bufPtr, error_t error) {
        call MsgPool.put(bufPtr);
        SerialLocked=FALSE;
        if (call PrintRouteQueue.empty() == FALSE) {
            serialPrintTask();
        }
    }

    event message_t* SerialRX.receive(message_t* bufPtr, void* payload, uint8_t len) {
        return bufPtr;
    }


    event void Boot.booted() {
        pico_stack_init();
        call SerialControl.start();

        pdev = call CC2420dev.create();
        if (pdev == NULL) {
            call Leds.led0On();
        }

        pico_string_to_ipv4("10.42.0.0",&hostip.addr);

        hostip.addr += long_be((uint32_t)(TOS_NODE_ID & 0xFF));
        hostip.addr += long_be((uint32_t)(TOS_NODE_ID & 0xFF00));
        pico_string_to_ipv4("255.255.0.0",&mask.addr);
        pico_ipv4_to_string(localipaddr, hostip.addr);

        if(pico_ipv4_link_add(pdev, hostip, mask)!=0) {
            call Leds.led0On();
        }

        pico_olsr_init();

        if(pico_olsr_add(pdev)){
            call Leds.led0On();
        }

        call Timer1.startOneShot(10);
    }

    event void Timer1.fired() {
        atomic {
            if(!SerialLocked){
                pico_stack_tick();
            }
            if (counter++ == 20){
                print_routes();
                counter=0;
            }
        }
        call Timer1.startOneShot(50);
    }

}



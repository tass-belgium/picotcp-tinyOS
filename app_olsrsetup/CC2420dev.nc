// $Id: CC2420dev.nc,v 1.6 2010-06-29 22:07:46 scipio Exp $

/**
 * @author Van Cauwenberghe Brecht 
 */


interface CC2420dev {

   /*
   * Create a pico device with param name as name.
   * Return : pointer to allocated sturct pico_device
   */
  
  command struct pico_device* create();
}

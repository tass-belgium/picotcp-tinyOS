motelist 
sudo chmod 666 /dev/ttyUSB0
sudo chmod 666 /dev/ttyUSB1
echo "***********************************************************************"
echo "LISTEN TO SERIAL /dev/ttyUSB1 -> Should print received packets"
echo "***********************************************************************"
#java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB0:115200 > ./dump1.txt
java PicoSerial -comm serial@/dev/ttyUSB1:115200 

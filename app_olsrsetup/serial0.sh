motelist
sudo chmod 666 /dev/ttyUSB0
echo "***********************************************************************"
echo "LISTEN TO SERIAL /dev/ttyUSB0 -> Should print received packets"
echo "***********************************************************************"
#java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB0:115200 > ./dump1.txt
java PicoSerial -comm serial@/dev/ttyUSB0:115200 

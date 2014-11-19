picoMESH
---------------

Welcome to the one and only <font color=ff00f0>PicoMESH repository</font>. 

picoMESH is a port of picoTCP into a tinyOS application

picoTCP is a TCP/IP stack designed for embedded systems, and developed by *[TASS Belgium NV](http://www.tass.be)*
For more information, visit [the project's website](http://www.picotcp.com)

##Setup
To download the repo, simply clone it:

    git clone https://github.com/tass-belgium/picotcp-tinyOS.git

Initialise the submodules:

    git submodule update --init

Install the tinyOS dependencies describes on the tinyos github repo:

    https://github.com/tinyos/tinyos-main

## Building the telosb image

In order to build your first Telosb image, execute the tinyOS make command in the application folder

    cd app_olsrsetup
    make telosb

if all goes well, a main.exe should now be found in ./build/telosb/

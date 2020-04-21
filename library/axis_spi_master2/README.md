# axis\_spi\_master

SPI Master with AXIS interface.

* NO FIFO
* AXIS interface for flow control

```
           +-------+
           |       |-----> M_AXIS
SPI <----> | Core  |
           |       |<----- S_AXIS
           +-------+
```

## SPI Protocol

```
                           ___     ___     ___     ___     ___
    SCK   CPOL=0  ________/   \___/   \___/   \___/   \___/   \____________
                  ________     ___     ___     ___     ___     ____________
          CPOL=1          \___/   \___/   \___/   \___/   \___/
                  ____                                             ________
    SS                \___________________________________________/
                       _______ _______ _______ _______ _______
    MOSI/ CPHA=0  zzzzX___0___X___1___X__...__X___6___X___7___X---Xzzzzzzzz
    MISO                   _______ _______ _______ _______ _______
          CPHA=1  zzzz----X___0___X___1___X__...__X___6___X___7___Xzzzzzzzz
```

## Limitation

This core is fixed CPOL = 0 and CPHA = 1. That means both master (this core) and salve will drive MOSI/MISO at rising edge of SCK, and should sample MISO/MOSI at falling edge.

## Version

| Version | History         |
| :------ | :-------------- |
| v1.0    | Initial version |

## TODO

* Time out logic for M_AXIS interface
* Add error status ports
# Coreboard 1588

1588 核心板 FPGA 工程。

## Basic Information

* **Project**: 1588 Corebard
* **Tool**: Vivado 2019.2
* **FPGA Part**: xc7a100tcsg324-2L
* **Configuration Memory**: MT25QL128
* **Clocks**:
  * **F4**, *A7_GCLK*, 25MHz, 25ppm. For none data sampling modules.
  * **E3**, *1588_CLK_OUT*, 25MHz. For data sampling modules.
* **Interfaces**:
  * 4-wire SPI0 to MCU, for register access
  * FMC to MCU, for data access
  * GPIO to MCU, for reset, watch dog, irq
  * 4-wire SPI1, GPIO to ADS8684, 
  * 4-wire SPI2, GPIO to ADS1248,
  * QSPI to Flash

## Register Access

Register access is done via *SPI0*. 4-wire.

Write Register, MCU send 7 octets to FPGA via SPI0:

```
|W | A15 ~ A0 | Dummy | D31 ~ D0 |
```

Read Regiseter, MCU send 7 octets to FPGA via SPI0, there should be a no gap between each byte (SS remains low).

```
|Rn| A15 ~ A0 | Dummy | D31 ~ D0 |
```

## LEDs

* **A3**, FPGA_LED1
* **C2**, FPGA_LED2
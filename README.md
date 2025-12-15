Efficient AHB-Lite to SPI Bridge

This project implements a custom AHB-Lite to SPI bridge designed for efficient 8-bit data transmission from an AHB-Lite master to an SPI slave device. The design is targeted for FPGA platforms and validated using the PYNQ-Z2 board.

The system uses an AXI4-Lite to AHB-Lite bridge, a custom AHB-Lite slave with FIFO buffering, and a hardware SPI master operating in Mode-0.

Key Features

8-bit unidirectional data transfer (AHB → SPI)

AHB clock: 100 MHz

SPI clock: 6.25 MHz (derived internally)

FIFO-based byte streaming

Memory-mapped control and status registers

Hardware-controlled DC and RESET signals

Verified using Python MMIO and DSO waveform analysis

| Register | Offset | Description             |
| -------- | ------ | ----------------------- |
| TX FIFO  | `0x00` | Write SPI data byte     |
| DC       | `0x08` | Data / Command control  |
| FLAGS    | `0x0C` | FIFO & DC status        |
| TX_CNT   | `0x10` | Total transmitted bytes |
| FSM      | `0x14` | SPI FSM debug state     |
| RESET    | `0x18` | SPI slave reset control |


Controlled from Jupyter Notebook using Python

Signal behavior verified on DSO (SCLK, MOSI, CS, DC, RESET)

Correct SPI timing and FSM operation confirmed

Applications

TFT / OLED display interfacing

Sensor or peripheral communication

Embedded SoC-FPGA data bridging

Author

Shitalkumar Pal
EXTC Engineering | FPGA & Embedded Systems

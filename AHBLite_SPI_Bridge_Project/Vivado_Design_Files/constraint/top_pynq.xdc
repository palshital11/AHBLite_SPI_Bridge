###############################################################
# PYNQ-Z2 JA PMOD - SPI Signals
# Single-ended SPI mapped to JA header
###############################################################

## SPI Clock (JA1P)
set_property PACKAGE_PIN Y18 [get_ports spi_sclk_0]
set_property IOSTANDARD LVCMOS33 [get_ports spi_sclk_0]

## SPI MOSI (JA2P)
set_property PACKAGE_PIN Y16 [get_ports spi_mosi_0]
set_property IOSTANDARD LVCMOS33 [get_ports spi_mosi_0]

## SPI MISO (JA3P)
set_property PACKAGE_PIN U18 [get_ports spi_miso_0]
set_property IOSTANDARD LVCMOS33 [get_ports spi_miso_0]

## SPI Chip Select (JA4P)
set_property PACKAGE_PIN W18 [get_ports spi_cs_0]
set_property IOSTANDARD LVCMOS33 [get_ports spi_cs_0]

## SPI Data/Command (D/C pin on TFT/OLED) (JA4N)
set_property PACKAGE_PIN W19 [get_ports spi_dc_0]
set_property IOSTANDARD LVCMOS33 [get_ports spi_dc_0]

set_property PACKAGE_PIN Y17 [get_ports tft_reset_0]
set_property IOSTANDARD LVCMOS33 [get_ports tft_reset_0]


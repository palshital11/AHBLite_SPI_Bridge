`timescale 1ns/1ps

module top_pynq (

    // Clocks / Reset
    input  wire         ACLK,
    input  wire         ARESETN,

    // AXI4-Lite
    input  wire [31:0]  AWADDR,
    input  wire         AWVALID,
    output wire         AWREADY,

    input  wire [31:0]  WDATA,
    input  wire [3:0]   WSTRB,
    input  wire         WVALID,
    output wire         WREADY,

    output wire [1:0]   BRESP,
    output wire         BVALID,
    input  wire         BREADY,

    input  wire [31:0]  ARADDR,
    input  wire         ARVALID,
    output wire         ARREADY,

    output wire [31:0]  RDATA,
    output wire [1:0]   RRESP,
    output wire         RVALID,
    input  wire         RREADY,

    // SPI Pins
    output wire spi_sclk,
    output wire spi_mosi,
    input  wire spi_miso,
    output wire spi_cs,
    output wire spi_dc,

    // NEW RESET PIN
    output wire tft_reset
);

    // Internal AHB Signals
    wire [31:0] haddr;
    wire [1:0]  htrans;
    wire        hwrite;
    wire [31:0] hwdata;
    wire [31:0] hrdata;
    wire        hready;
    wire [1:0]  hresp;

    // AXI4-Lite → AHB Bridge
    axi4lite_to_ahb_bridge u_axi2ahb (
        .ACLK    (ACLK),
        .ARESETN (ARESETN),
        .AWADDR  (AWADDR),
        .AWVALID (AWVALID),
        .AWREADY (AWREADY),
        .WDATA   (WDATA),
        .WSTRB   (WSTRB),
        .WVALID  (WVALID),
        .WREADY  (WREADY),
        .BRESP   (BRESP),
        .BVALID  (BVALID),
        .BREADY  (BREADY),
        .ARADDR  (ARADDR),
        .ARVALID (ARVALID),
        .ARREADY (ARREADY),
        .RDATA   (RDATA),
        .RRESP   (RRESP),
        .RVALID  (RVALID),
        .RREADY  (RREADY),
        .HADDR   (haddr),
        .HTRANS  (htrans),
        .HWRITE  (hwrite),
        .HWDATA  (hwdata),
        .HRDATA  (hrdata),
        .HREADY  (hready),
        .HRESP   (hresp)
    );

    // AHB → SPI Bridge + RESET
    ahb_spi_bridge u_spi (
        .HCLK      (ACLK),
        .HRESETn   (ARESETN),
        .HADDR     (haddr),
        .HTRANS    (htrans),
        .HWRITE    (hwrite),
        .HWDATA    (hwdata),
        .HRDATA    (hrdata),
        .HREADY    (hready),
        .HRESP     (hresp),

        .spi_sclk  (spi_sclk),
        .spi_mosi  (spi_mosi),
        .spi_miso  (spi_miso),
        .spi_cs    (spi_cs),
        .spi_dc    (spi_dc),

        .tft_reset (tft_reset)
    );

endmodule

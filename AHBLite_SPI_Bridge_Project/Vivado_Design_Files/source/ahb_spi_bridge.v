`timescale 1ns/1ps

module ahb_spi_bridge(
    input  wire        HCLK,
    input  wire        HRESETn,

    // AHB-Lite bus
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [31:0] HWDATA,

    output reg  [31:0] HRDATA,
    output wire        HREADY,
    output wire        HRESP,

    // SPI pins
    output wire spi_sclk,
    output wire spi_mosi,
    input  wire spi_miso,
    output wire spi_cs,
    output reg  spi_dc,

    // NEW: TFT RESET pin
    output reg  tft_reset
);

    wire valid     = HTRANS[1];
    wire ahb_write = valid && HWRITE;
    wire [3:0] addr = HADDR[5:2];

    //------------------------------------------------------------
    // TX BYTE FIFO (single-clock)
    //------------------------------------------------------------
    wire [7:0] fifo_dout;
    wire fifo_empty, fifo_full;
    reg  fifo_rd_en;

    fifo_sc fifo_inst (
        .clk    (HCLK),
        .resetn (HRESETn),
        .din    (HWDATA[7:0]),
        .wr_en  (ahb_write && addr == 4'h0 && !fifo_full),
        .rd_en  (fifo_rd_en),
        .dout   (fifo_dout),
        .full   (fifo_full),
        .empty  (fifo_empty)
    );

    //------------------------------------------------------------
    // AHB Ready/Response
    //------------------------------------------------------------
    assign HREADY = ~fifo_full;
    assign HRESP  = 1'b0;

    //------------------------------------------------------------
    // SPI MASTER
    //------------------------------------------------------------
    reg  tx_start;
    wire tx_done;

    spi_master spi_inst (
        .clk      (HCLK),
        .resetn   (HRESETn),
        .tx_data  (fifo_dout),
        .tx_start (tx_start),
        .spi_sclk (spi_sclk),
        .spi_mosi (spi_mosi),
        .spi_miso (spi_miso),
        .spi_cs   (spi_cs),
        .tx_done  (tx_done)
    );

    //------------------------------------------------------------
    // FSM
    //------------------------------------------------------------
    localparam IDLE=0, POP=1, LAUNCH=2, WAIT=3;
    reg [1:0] state;

    reg [31:0] tx_count = 0;

    always @(posedge HCLK or negedge HRESETn)
        if (!HRESETn) begin
            state      <= IDLE;
            fifo_rd_en <= 0;
            tx_start   <= 0;
            tx_count   <= 0;
        end else begin
            fifo_rd_en <= 0;
            tx_start   <= 0;

            case (state)

                IDLE:
                    if (!fifo_empty)
                        state <= POP;

                POP: begin
                    fifo_rd_en <= 1;
                    state <= LAUNCH;
                end

                LAUNCH: begin
                    tx_start <= 1;
                    state <= WAIT;
                end

                WAIT:
                    if (tx_done) begin
                        tx_count <= tx_count + 1;
                        state <= IDLE;
                    end

            endcase
        end

    //------------------------------------------------------------
    // DC Register (0x08 → addr 4'h2)
    //------------------------------------------------------------
    always @(posedge HCLK)
        if (ahb_write && addr == 4'h2)
            spi_dc <= HWDATA[0];

    //------------------------------------------------------------
    // NEW: RESET Register (0x18 → addr 4'h6)
    //------------------------------------------------------------
    always @(posedge HCLK or negedge HRESETn)
        if (!HRESETn)
            tft_reset <= 1'b1;     // default HIGH
        else if (ahb_write && addr == 4'h6)
            tft_reset <= HWDATA[0];

    //------------------------------------------------------------
    // Debug State
    //------------------------------------------------------------
    reg [1:0] dbg_state;
    always @(posedge HCLK)
        dbg_state <= state;

    //------------------------------------------------------------
    // READBACK REGISTERS
    //------------------------------------------------------------
    always @(*) begin
        case (addr)

            4'h2: HRDATA = {31'b0, spi_dc};                           // 0x08

            4'h3: HRDATA = {29'b0, spi_dc, fifo_full, fifo_empty};    // 0x0C FLAGS

            4'h4: HRDATA = tx_count;                                  // 0x10

            4'h5: HRDATA = {30'b0, dbg_state};                        // 0x14

            4'h6: HRDATA = {31'b0, tft_reset};                        // 0x18 RESET

            default: HRDATA = 32'h0;

        endcase
    end

endmodule

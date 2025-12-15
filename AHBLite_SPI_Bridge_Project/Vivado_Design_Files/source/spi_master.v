`timescale 1ns/1ps

module spi_master (
    input  wire        clk,        // HCLK = 100 MHz
    input  wire        resetn,

    input  wire [7:0]  tx_data,
    input  wire        tx_start,

    output reg         spi_sclk,
    output reg         spi_mosi,
    input  wire        spi_miso,
    output reg         spi_cs,

    output reg         tx_done
);

    //--------------------------------------------------
    // 100 MHz → 12.5 MHz using divider-by-8
    //--------------------------------------------------
    reg [2:0] div_cnt;
    reg       clk_en;       // 1-cycle pulse every 8 HCLK cycles

    always @(posedge clk or negedge resetn)
        if (!resetn) begin
            div_cnt <= 0;
            clk_en  <= 0;
        end else begin
            div_cnt <= div_cnt + 1;
            clk_en  <= (div_cnt == 3'd7);
        end

    //--------------------------------------------------
    // SPI logic triggered only when clk_en = 1
    //--------------------------------------------------
    reg [7:0] shreg;
    reg [2:0] bitcnt;
    reg       active;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            active   <= 0;
            spi_cs   <= 1;
            spi_sclk <= 0;
            spi_mosi <= 0;
            tx_done  <= 0;
        end else begin
            tx_done <= 0;

            if (tx_start && !active) begin
                active   <= 1;
                spi_cs   <= 0;
                shreg    <= tx_data;
                bitcnt   <= 3'd7;
                spi_sclk <= 0;
                spi_mosi <= tx_data[7];
            end

            if (active && clk_en) begin
                spi_sclk <= ~spi_sclk;

                if (spi_sclk == 0) begin
                    // Falling edge: output MSB
                    spi_mosi <= shreg[7];
                end else begin
                    // Rising edge: shift register
                    shreg <= {shreg[6:0], 1'b0};

                    if (bitcnt == 0) begin
                        active  <= 0;
                        spi_cs  <= 1;
                        tx_done <= 1;
                    end else begin
                        bitcnt <= bitcnt - 1;
                    end
                end
            end
        end
    end

endmodule

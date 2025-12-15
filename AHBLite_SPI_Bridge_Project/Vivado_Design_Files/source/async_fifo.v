`timescale 1ns/1ps

module fifo_sc #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire                  clk,
    input  wire                  resetn,

    input  wire [DATA_WIDTH-1:0] din,
    input  wire                  wr_en,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] dout,
    output wire                  full,
    output wire                  empty
);

    localparam ADDR_BITS = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_BITS:0] wptr = 0;
    reg [ADDR_BITS:0] rptr = 0;

    assign empty = (wptr == rptr);
    assign full  = (wptr[ADDR_BITS] != rptr[ADDR_BITS]) &&
                   (wptr[ADDR_BITS-1:0] == rptr[ADDR_BITS-1:0]);

    always @(posedge clk or negedge resetn)
        if (!resetn)
            wptr <= 0;
        else if (wr_en && !full) begin
            mem[wptr[ADDR_BITS-1:0]] <= din;
            wptr <= wptr + 1;
        end

    always @(posedge clk or negedge resetn)
        if (!resetn) begin
            rptr <= 0;
            dout <= 0;
        end else if (rd_en && !empty) begin
            dout <= mem[rptr[ADDR_BITS-1:0]];
            rptr <= rptr + 1;
        end

endmodule

`timescale 1ns/1ps
module axi4lite_to_ahb_bridge #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                   ACLK,
    input  wire                   ARESETN,

    // AXI Write Address
    input  wire [ADDR_WIDTH-1:0]  AWADDR,
    input  wire                   AWVALID,
    output reg                    AWREADY,

    // AXI Write Data
    input  wire [DATA_WIDTH-1:0]  WDATA,
    input  wire [3:0]             WSTRB,
    input  wire                   WVALID,
    output reg                    WREADY,

    // AXI Write Response
    output reg [1:0]              BRESP,
    output reg                    BVALID,
    input  wire                   BREADY,

    // AXI Read Address
    input  wire [ADDR_WIDTH-1:0]  ARADDR,
    input  wire                   ARVALID,
    output reg                    ARREADY,

    // AXI Read Data
    output reg [DATA_WIDTH-1:0]   RDATA,
    output reg [1:0]              RRESP,
    output reg                    RVALID,
    input  wire                   RREADY,

    // AHB Master Interface
    output reg [ADDR_WIDTH-1:0]   HADDR,
    output reg [1:0]              HTRANS,
    output reg                    HWRITE,
    output reg [2:0]              HSIZE,
    output reg [DATA_WIDTH-1:0]   HWDATA,

    input  wire [DATA_WIDTH-1:0]  HRDATA,
    input  wire                   HREADY,
    input  wire                   HRESP
);

    localparam TRN_IDLE   = 2'b00;
    localparam TRN_NONSEQ = 2'b10;

    // local FSM states
    localparam IDLE  = 3'd0,
               WADDR = 3'd1,
               WEXEC = 3'd2,
               WRESP = 3'd3,
               RADDR = 3'd4,
               REXEC = 3'd5;

    reg [2:0] state;

    // Buffers / flags for AXI handshakes
    reg aw_pending;
    reg w_pending;
    reg ar_pending;

    reg [ADDR_WIDTH-1:0] awbuf;
    reg [DATA_WIDTH-1:0] wbuf;
    reg [ADDR_WIDTH-1:0] arbuf;

    // default sizes
    initial begin
        HSIZE = 3'b010; // 32-bit transfers
    end

    // Reset / main FSM
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            // AXI signals
            AWREADY <= 0;
            WREADY  <= 0;
            ARREADY <= 0;
            BVALID  <= 0;
            BRESP   <= 2'b00;
            RVALID  <= 0;
            RRESP   <= 2'b00;
            RDATA   <= {DATA_WIDTH{1'b0}};

            // AHB
            HADDR   <= {ADDR_WIDTH{1'b0}};
            HWRITE  <= 1'b0;
            HTRANS  <= TRN_IDLE;
            HWDATA  <= {DATA_WIDTH{1'b0}};
            HSIZE   <= 3'b010;

            // internal
            state <= IDLE;
            aw_pending <= 1'b0;
            w_pending  <= 1'b0;
            ar_pending <= 1'b0;
            awbuf <= {ADDR_WIDTH{1'b0}};
            wbuf  <= {DATA_WIDTH{1'b0}};
            arbuf <= {ADDR_WIDTH{1'b0}};
        end else begin
            // Default handshake outputs
            AWREADY <= 0;
            WREADY  <= 0;
            ARREADY <= 0;

            // Clear AXI responses when accepted by master
            if (BVALID && BREADY) BVALID <= 0;
            if (RVALID && RREADY) RVALID <= 0;

            case (state)
                // IDLE: accept AW/AR and W as they come
                IDLE: begin
                    HTRANS <= TRN_IDLE;
                    HWRITE <= 1'b0;

                    // Capture AW when present and not already pending
                    if (AWVALID && !aw_pending) begin
                        AWREADY <= 1;
                        aw_pending <= 1'b1;
                        awbuf <= AWADDR;
                    end

                    // Capture W when present and not already pending
                    if (WVALID && !w_pending) begin
                        WREADY <= 1;
                        w_pending <= 1'b1;
                        wbuf <= WDATA;
                    end

                    // If both AW and W are available, start write execution
                    if (aw_pending && w_pending) begin
                        // Drive AHB signals for transfer
                        HADDR <= awbuf;
                        HWRITE <= 1'b1;
                        HWDATA <= wbuf;
                        HTRANS <= TRN_NONSEQ;
                        state <= WEXEC;
                    end else if (AWVALID && !AWREADY && !aw_pending) begin
                        // case where AWVALID presented but W not yet -> AWREADY asserted above
                    end

                    // Read handling: if AR arrives (read) and not pending and nobody trying to write
                    if (ARVALID && !ar_pending && !(aw_pending && w_pending)) begin
                        ARREADY <= 1;
                        ar_pending <= 1'b1;
                        arbuf <= ARADDR;
                        // start read immediately if not in write progress
                        HADDR <= ARADDR;
                        HWRITE <= 1'b0;
                        HTRANS <= TRN_NONSEQ;
                        state <= REXEC;
                    end
                end

                // Write execution: we have set HTRANS=NONSEQ and wait HREADY
                WEXEC: begin
                    // keep driving signals until HREADY
                    HTRANS <= TRN_NONSEQ;
                    HWRITE <= 1'b1;
                    HADDR  <= awbuf;
                    HWDATA <= wbuf;
                    HSIZE  <= 3'b010;

                    if (HREADY) begin
                        // AHB write accepted; deassert HTRANS and generate BRESP
                        HTRANS <= TRN_IDLE;
                        BVALID <= 1'b1;
                        BRESP  <= 2'b00; // OKAY
                        // clear buffers
                        aw_pending <= 1'b0;
                        w_pending <= 1'b0;
                        state <= WRESP;
                    end
                end

                // Wait for AXI master to accept BVALID (BREADY)
                WRESP: begin
                    HTRANS <= TRN_IDLE;
                    HWRITE <= 1'b0;
                    if (!BVALID) begin
                        // safety: if BVALID was cleared by master, go idle
                        state <= IDLE;
                    end else begin
                        // stay here until master accepts BVALID via BREADY (handled at top)
                        if (BVALID && BREADY) begin
                            state <= IDLE;
                        end
                    end
                end

                // Read execution: HTRANS set in REXEC on capture
                REXEC: begin
                    HTRANS <= TRN_NONSEQ;
                    HWRITE <= 1'b0;
                    HADDR  <= arbuf;
                    HSIZE  <= 3'b010;

                    if (HREADY) begin
                        // capture HRDATA and present RDATA/RVALID
                        RDATA <= HRDATA;
                        RRESP <= 2'b00;
                        RVALID <= 1'b1;
                        ar_pending <= 1'b0;
                        HTRANS <= TRN_IDLE;
                        state <= RRESP;
                    end
                end

                // Wait for master to accept RVALID
                RRESP: begin
                    HTRANS <= TRN_IDLE;
                    if (RVALID && RREADY) begin
                        RVALID <= 1'b0;
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase

            // If AXI master presents AWVALID while we are in IDLE, make AWREADY (handled above).
            // Also allow simultaneous capture of AW/W in the same cycle (if both valid).
            // The top-of-case IDLE logic already asserts AWREADY/WREADY when conditions met.
        end
    end

endmodule
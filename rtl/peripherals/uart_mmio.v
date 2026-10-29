`timescale 1ns / 1ps

// One-byte, polled UART TX. Parameters must both be >= 1.
// Bus writes take effect only at completion; see docs/uart_interface.md.
module uart_mmio #(
    parameter integer CLKS_PER_BIT = 868,
    parameter integer WAIT_CYCLES = 1
) (
    input wire clk, input wire rst, input wire valid, input wire write,
    input wire [31:0] addr, input wire [31:0] wdata,
    input wire [3:0] wstrb, input wire [1:0] size,
    output reg ready, output reg [31:0] rdata, output reg error,
    output wire tx, output wire busy
);
    localparam integer COUNT_WIDTH = (WAIT_CYCLES < 2) ? 1 : $clog2(WAIT_CYCLES);
    reg [COUNT_WIDTH-1:0] wait_count;
    wire [31:0] byte_mask = {{8{wstrb[3]}}, {8{wstrb[2]}},
                             {8{wstrb[1]}}, {8{wstrb[0]}}};
    reg [3:0] allowed_lanes;
    reg bad_access;
    reg request_bad, request_send, request_write, request_status;
    reg [7:0] request_byte;
    wire tx_start = !rst && valid && ready && request_send && !error;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) transmitter (
        .clk(clk), .rst(rst), .start(tx_start), .data(request_byte),
        .tx(tx), .busy(busy), .done()
    );

    always @* begin
        case (size)
            0: allowed_lanes = 4'b0001 << addr[1:0];
            1: allowed_lanes = 4'b0011 << addr[1:0];
            2: allowed_lanes = 4'b1111;
            default: allowed_lanes = 4'b0000;
        endcase
        bad_access = addr[31:8] != 24'h400003 || size == 3 ||
            (size == 1 && addr[0]) || (size == 2 && addr[1:0] != 0) ||
            (write ? ((wstrb & ~allowed_lanes) != 0) : (wstrb != 0));
        case (addr[7:2])
            0: if (write && (wdata & byte_mask & 32'hffffff00) != 0)
                bad_access = 1'b1;
            1: if (write) bad_access = 1'b1;
            default: bad_access = 1'b1;
        endcase
    end

    // BUSY is checked on the completion edge, including the stop-bit edge.
    always @* begin
        error = request_bad || (request_send && busy);
        rdata = 0;
        if (!error && !request_write && request_status)
            rdata = {30'b0, !busy, busy};
    end

    always @(posedge clk) begin
        if (rst) begin
            ready <= 1'b0;
            wait_count <= 0;
            request_bad <= 1'b0;
            request_send <= 1'b0;
            request_write <= 1'b0;
            request_status <= 1'b0;
            request_byte <= 0;
        end else begin
            if (valid && !ready) begin
                request_bad <= bad_access;
                request_send <= write && addr[7:2] == 0 && wstrb[0];
                request_write <= write;
                request_status <= addr[7:2] == 1;
                request_byte <= wdata[7:0];
            end
            if (!valid || ready) begin
                ready <= 1'b0;
                wait_count <= 0;
            end else if (wait_count == WAIT_CYCLES-1) begin
                ready <= 1'b1;
            end else begin
                wait_count <= wait_count + 1'b1;
            end
        end
    end
endmodule

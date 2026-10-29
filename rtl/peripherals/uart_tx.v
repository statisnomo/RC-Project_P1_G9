`timescale 1ns / 1ps

// 8N1 transmitter, one clock domain. CLKS_PER_BIT must be >= 1.
// START is accepted only while idle; reset and busy-start rules are in
// docs/uart_interface.md. At 100 MHz, 868 clocks/bit gives ~115200 baud.
module uart_tx #(parameter integer CLKS_PER_BIT = 868) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] data,
    output reg        tx,
    output reg        busy,
    output reg        done
);
    localparam integer COUNT_WIDTH = (CLKS_PER_BIT < 2) ? 1 : $clog2(CLKS_PER_BIT);
    reg [COUNT_WIDTH-1:0] bit_count;
    reg [3:0] bit_index;
    reg [9:0] frame;

    always @(posedge clk) begin
        if (rst) begin
            tx <= 1'b1;
            busy <= 1'b0;
            done <= 1'b0;
            bit_count <= 0;
            bit_index <= 0;
            frame <= 10'h3ff;
        end else begin
            done <= 1'b0;
            if (!busy) begin
                tx <= 1'b1;
                if (start) begin
                    frame <= {1'b1, data, 1'b0};
                    tx <= 1'b0;
                    busy <= 1'b1;
                    bit_count <= 0;
                    bit_index <= 0;
                end
            end else if (bit_count == CLKS_PER_BIT-1) begin
                bit_count <= 0;
                if (bit_index == 9) begin
                    tx <= 1'b1;
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    frame <= {1'b1, frame[9:1]};
                    tx <= frame[1];
                    bit_index <= bit_index + 1'b1;
                end
            end else begin
                bit_count <= bit_count + 1'b1;
            end
        end
    end
endmodule

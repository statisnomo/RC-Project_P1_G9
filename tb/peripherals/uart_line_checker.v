`timescale 1ns / 1ps

// Pin-level reference: ideal 8N1 levels/durations from testbench requests.
// No transmitter internals are read. Checks every clock, including idle.
module uart_line_checker #(
    parameter integer CLKS_PER_BIT = 8,
    parameter integer CHECK_DONE = 1
) (
    input wire clk, input wire rst,
    input wire expect_start, input wire [7:0] expect_byte,
    input wire tx, input wire busy, input wire done,
    output integer checks = 0,
    output integer frames = 0,
    output integer aborted = 0
);
    reg active = 0;
    reg [7:0] saved_byte;
    reg wanted_tx, wanted_done;
    integer age = 0;
    integer symbol;
    always @(posedge clk) begin
        wanted_done = 0;
        if (rst) begin
            if (active) aborted = aborted + 1;
            active = 0;
            age = 0;
        end else if (active) begin
            if (expect_start)
                $fatal(1, "FAIL UART checker received overlapping requests");
            age = age + 1;
            if (age == 10 * CLKS_PER_BIT) begin
                active = 0;
                frames = frames + 1;
                wanted_done = 1;
            end
        end else if (expect_start) begin
            saved_byte = expect_byte;
            active = 1;
            age = 0;
        end
        wanted_tx = 1;
        if (active) begin
            symbol = age / CLKS_PER_BIT;
            if (symbol == 0) wanted_tx = 0;
            else if (symbol <= 8) wanted_tx = saved_byte[symbol-1];
        end
        #1;
        checks = checks + 1;
        if (tx !== wanted_tx || busy !== active ||
            (CHECK_DONE && done !== wanted_done))
            $fatal(1, "FAIL UART pin/timing div=%0d time=%0t age=%0d tx=%b/%b busy=%b/%b done=%b/%b",
                   CLKS_PER_BIT, $time, age, tx, wanted_tx, busy, active, done, wanted_done);
    end
endmodule

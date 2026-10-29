`timescale 1ns / 1ps

module uart_tx_checks #(parameter integer DIV = 8) (output reg finished = 0);
    reg clk = 0; always #5 clk = ~clk;
    reg rst = 1, start = 0;
    reg [7:0] data = 0;
    wire tx, busy, done;
    wire [31:0] checks, frames, aborted;
    integer value, phase, before_frames;
    localparam integer BYTE_CASES = (DIV == 868) ? 16 : 256;
    uart_tx #(.CLKS_PER_BIT(DIV)) dut (.*);
    uart_line_checker #(.CLKS_PER_BIT(DIV)) serial_check (
        .clk(clk), .rst(rst), .expect_start(start && !busy), .expect_byte(data),
        .tx(tx), .busy(busy), .done(done), .checks(checks), .frames(frames), .aborted(aborted)
    );

    task launch;
        input [7:0] value_to_send;
        begin
            @(negedge clk); data = value_to_send; start = 1;
            @(negedge clk); start = 0; data = ~value_to_send;
        end
    endtask
    task finish_frame;
        begin wait (busy == 0); @(negedge clk); end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst = 0;
        // First GUI example: ASCII 'A'. Busy START and changing DATA must
        // not replace, queue, or corrupt this character.
        launch(8'h41);
        start = 1; data = 8'hff;
        repeat (2 * DIV) @(negedge clk);
        start = 0;
        finish_frame();
        if (frames != 1) $fatal(1, "FAIL busy START created an extra frame");

        // Exhaust all byte values at small dividers, with broad patterns
        // at the actual 100 MHz / 115200 divider.
        for (value = 0; value < BYTE_CASES; value = value + 1) begin
            launch((DIV == 868) ? value * 17 : value);
            finish_frame();
        end

        // Continuous START means a new request whenever idle. Ensure the
        // stop bit finishes and DONE pulses once per frame.
        before_frames = frames;
        @(negedge clk); data = 8'h5a; start = 1;
        wait (frames == before_frames + 3);
        @(negedge clk); start = 0;
        repeat (3) @(negedge clk);
        if (frames != before_frames + 3) $fatal(1, "FAIL held START count");

        // Reset in the start bit, each data bit, and the stop bit. Recover
        // with a complete frame after every abort. Reset also wins START.
        for (phase = 0; phase < 10; phase = phase + 1) begin
            launch(8'h00);
            repeat (phase * DIV) @(negedge clk);
            rst = 1; start = 1;
            @(negedge clk); rst = 0; start = 0;
            launch(8'ha5);
            finish_frame();
        end
        if (aborted != 10) $fatal(1, "FAIL reset phase coverage: %0d", aborted);
        if (frames != BYTE_CASES + 14) $fatal(1, "FAIL completed frame count: %0d", frames);
        repeat (12 * DIV) @(negedge clk);
        $display("UART_TX_CASE div=%0d: %0d pin/timing checks, %0d frames, %0d reset aborts",
                 DIV, checks, frames, aborted);
        finished = 1;
    end
endmodule

module tb_uart_tx;
    wire one_done, two_done, seven_done, real_done;
    uart_tx_checks #(.DIV(1)) fast_one (.finished(one_done));
    uart_tx_checks #(.DIV(2)) fast_two (.finished(two_done));
    uart_tx_checks #(.DIV(7)) fast_seven (.finished(seven_done));
    uart_tx_checks #(.DIV(868)) real_baud (.finished(real_done));
    initial begin
        wait (one_done && two_done && seven_done && real_done);
        $display("PASS tb_uart_tx: 4 dividers, 840 complete frames, 40 reset aborts");
        $finish;
    end
    initial begin #100000000; $fatal(1, "FAIL UART TX watchdog"); end
endmodule

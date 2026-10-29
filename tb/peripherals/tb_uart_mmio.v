`timescale 1ns / 1ps

module uart_mmio_checks #(parameter integer WAIT_CYCLES = 1) (output reg finished = 0);
    localparam integer DIV = 8;
    localparam [31:0] BASE = 32'h40000300;
    reg clk = 0; always #5 clk = ~clk;
    reg rst = 1, valid = 0, write = 0;
    reg [31:0] addr = 0, wdata = 0;
    reg [3:0] wstrb = 0;
    reg [1:0] size = 2;
    reg expected_send = 0;
    wire ready, error, tx, busy;
    wire [31:0] rdata, pin_checks, frames, aborted;
    integer checks = 0, transfers = 0;
    integer value, lane, offset, edge_index, phase, before_frames, before_transfers;
    reg [31:0] reply;
    uart_mmio #(.CLKS_PER_BIT(DIV), .WAIT_CYCLES(WAIT_CYCLES)) dut (.*);
    uart_line_checker #(.CLKS_PER_BIT(DIV), .CHECK_DONE(0)) serial_check (
        .clk(clk), .rst(rst), .expect_start(valid && ready && expected_send),
        .expect_byte(wdata[7:0]), .tx(tx), .busy(busy), .done(1'b0),
        .checks(pin_checks), .frames(frames), .aborted(aborted)
    );
    always @(posedge clk) if (!rst && valid && ready) transfers = transfers + 1;

    task equal;
        input [31:0] actual, wanted;
        input [255:0] label_text;
        begin
            checks = checks + 1;
            if (actual !== wanted)
                $fatal(1, "FAIL UART MMIO wait=%0d %0s time=%0t got=%h want=%h",
                       WAIT_CYCLES, label_text, $time, actual, wanted);
        end
    endtask
    // Called at a falling edge, before the first wait edge.
    task complete_request;
        input expected_error;
        output [31:0] result_word;
        integer waited;
        begin
            waited = 0;
            while (ready !== 1) begin
                @(negedge clk); waited = waited + 1;
                if (waited > WAIT_CYCLES + 1) $fatal(1, "FAIL UART bus stuck");
            end
            equal(waited, WAIT_CYCLES, "fixed response wait");
            equal(error, expected_error, "completion error");
            result_word = rdata;
            if (write || expected_error) equal(rdata, 0, "write/error returns zero");
            @(posedge clk); #2;
        end
    endtask
    task access_bus;
        input wr;
        input [31:0] address, value_word;
        input [3:0] lanes;
        input [1:0] width;
        input expected_error, sends_byte;
        output [31:0] result_word;
        begin
            @(negedge clk);
            valid = 1; write = wr; addr = address; wdata = value_word;
            wstrb = lanes; size = width; expected_send = sends_byte;
            complete_request(expected_error, result_word);
            @(negedge clk); valid = 0; expected_send = 0;
        end
    endtask
    task send_byte;
        input [7:0] byte_value;
        begin access_bus(1, BASE, byte_value, 1, 0, 0, 1, reply); end
    endtask
    task finish_frame;
        begin wait (busy == 0); @(negedge clk); end
    endtask
    task read_status;
        input [31:0] expected_status;
        begin
            access_bus(0, BASE + 4, 0, 0, 2, 0, 0, reply);
            equal(reply, expected_status, "live status");
        end
    endtask

    initial begin
        repeat (3) @(negedge clk); rst = 0;
        read_status(2);
        // First GUI transaction sends ASCII 'A'; errors and no-ops during
        // this frame must not replace the byte or create extra starts.
        send_byte(8'h41);
        read_status(1);
        access_bus(1, BASE, 8'h42, 1, 0, 1, 0, reply);
        access_bus(1, BASE, 32'hffffffff, 0, 2, 0, 0, reply);
        access_bus(1, BASE + 1, 0, 2, 0, 0, 0, reply);
        finish_frame();
        equal(frames, 1, "busy/no-op byte count");
        read_status(2);

        for (value = 0; value < 256; value = value + 1) begin
            send_byte(value);
            finish_frame();
        end
        // Legal halfword/word sends and ignored unstrobed reserved bytes.
        access_bus(1, BASE, 8'h55, 3, 1, 0, 1, reply); finish_frame();
        access_bus(1, BASE, 8'haa, 15, 2, 0, 1, reply); finish_frame();
        access_bus(1, BASE, 32'hffffff00, 1, 2, 0, 1, reply); finish_frame();

        // Upper byte lanes never enqueue bytes. Nonzero enabled reserved
        // bits fail; disabled lanes are ignored. Reads return a whole word.
        for (lane = 0; lane < 4; lane = lane + 1) begin
            access_bus(0, BASE + lane, 0, 0, 0, 0, 0, reply);
            equal(reply, 0, "TXDATA reads zero");
            access_bus(0, BASE + 4 + lane, 0, 0, 0, 0, 0, reply);
            equal(reply, 2, "status containing word");
            access_bus(1, BASE + 4 + lane, 0, 0, 0, 1, 0, reply);
            access_bus(1, BASE + lane, 0, 15 ^ (1 << lane), 0, 1, 0, reply);
            if (lane != 0) begin
                access_bus(1, BASE + lane, 0, 1 << lane, 0, 0, 0, reply);
                access_bus(1, BASE + lane, 32'hff << (lane*8), 1 << lane, 0, 1, 0, reply);
            end
        end
        // Each byte strobe mask, zero data. Only lane zero sends a byte.
        for (value = 0; value < 16; value = value + 1) begin
            access_bus(1, BASE, 0, value, 2, 0, value & 1, reply);
            if (value & 1) finish_frame();
        end
        access_bus(0, BASE + 1, 0, 0, 1, 1, 0, reply);
        access_bus(1, BASE + 3, 0, 0, 1, 1, 0, reply);
        for (offset = 1; offset < 4; offset = offset + 1)
            access_bus(1, BASE + offset, 0, 0, 2, 1, 0, reply);
        access_bus(0, BASE, 0, 0, 3, 1, 0, reply);
        access_bus(1, BASE, 0, 0, 3, 1, 0, reply);
        access_bus(0, BASE, 0, 1, 2, 1, 0, reply);
        access_bus(1, BASE, 32'h00000100, 3, 1, 1, 0, reply);
        access_bus(1, BASE, 32'h80000000, 15, 2, 1, 0, reply);
        for (offset = 8; offset < 256; offset = offset + 4) begin
            access_bus(0, BASE + offset, 0, 0, 2, 1, 0, reply);
            access_bus(1, BASE + offset, 0, 0, 2, 1, 0, reply);
        end
        access_bus(1, 32'h40000000, 8'h41, 1, 0, 1, 0, reply);
        access_bus(1, 32'h40000200, 8'h41, 1, 0, 1, 0, reply);
        access_bus(0, 32'h40000404, 0, 0, 2, 1, 0, reply);
        access_bus(1, 32'h00000300, 8'h41, 1, 0, 1, 0, reply);

        // Cancel at every wait position, including READY high but before
        // the completion edge. There must be no serial side effect.
        before_frames = frames; before_transfers = transfers;
        for (edge_index = 0; edge_index <= WAIT_CYCLES; edge_index = edge_index + 1) begin
            @(negedge clk); valid = 1; write = 1; addr = BASE;
            wdata = 8'hcc; wstrb = 1; size = 0; expected_send = 1;
            if (edge_index == 0) #1;
            else repeat (edge_index) @(negedge clk);
            valid = 0; expected_send = 0;
            @(negedge clk); equal(ready, 0, "cancel clears ready");
        end
        equal(transfers, before_transfers, "canceled requests do not complete");
        equal(frames, before_frames, "canceled requests send nothing");

        // Reset wins over an otherwise accepted TXDATA completion.
        @(negedge clk); valid = 1; write = 1; addr = BASE;
        wdata = 8'hcc; wstrb = 1; size = 0; expected_send = 1;
        repeat (WAIT_CYCLES) @(negedge clk);
        equal(ready, 1, "reset at response"); rst = 1;
        @(negedge clk); valid = 0; expected_send = 0; rst = 0;
        equal(transfers, before_transfers, "reset cancels completion");
        read_status(2);

        // Continuous VALID with identical request bits is still multiple
        // transfers. The first sends, the next three fail busy exactly once.
        before_frames = frames; before_transfers = transfers;
        @(negedge clk); valid = 1; write = 1; addr = BASE;
        wdata = 8'h96; wstrb = 1; size = 0; expected_send = 1;
        for (value = 0; value < 4; value = value + 1) begin
            expected_send = (value == 0);
            complete_request(value != 0, reply);
            @(negedge clk);
        end
        valid = 0; expected_send = 0;
        equal(transfers, before_transfers + 4, "continuous VALID transfers");
        finish_frame(); equal(frames, before_frames + 1, "continuous VALID byte count");

        // Busy is sampled live at completion: finishing-stop edge fails;
        // the next edge succeeds even though request capture was while busy.
        for (value = 0; value < 2; value = value + 1) begin
            send_byte(8'h35);
            while (serial_check.age < 10*DIV - WAIT_CYCLES - 1 + value)
                @(negedge clk);
            valid = 1; write = 1; addr = BASE; wdata = 8'hca;
            wstrb = 1; size = 0; expected_send = value;
            complete_request(value == 0, reply);
            @(negedge clk); valid = 0; expected_send = 0;
            finish_frame();
        end

        // Abort in each serial phase and send a clean byte after reset.
        for (phase = 0; phase < 10; phase = phase + 1) begin
            send_byte(0);
            repeat (phase * DIV) @(negedge clk);
            rst = 1;
            @(negedge clk); rst = 0;
            read_status(2); send_byte(8'ha5); finish_frame();
        end
        equal(aborted, 10, "reset aborts all ten bit phases");
        equal(frames, 282, "total received frames");
        repeat (12*DIV) @(negedge clk);
        $display("UART_MMIO_CASE wait=%0d: %0d bus checks, %0d pin checks, %0d frames, %0d aborts",
                 WAIT_CYCLES, checks, pin_checks, frames, aborted);
        finished = 1;
    end
endmodule

module tb_uart_mmio;
    wire short_done, delayed_done;
    uart_mmio_checks #(.WAIT_CYCLES(1)) short_wait (.finished(short_done));
    uart_mmio_checks #(.WAIT_CYCLES(4)) delayed_wait (.finished(delayed_done));
    initial begin
        wait (short_done && delayed_done);
        $display("PASS tb_uart_mmio: waits 1/4, 564 complete frames, 20 reset aborts");
        $finish;
    end
    initial begin #10000000; $fatal(1, "FAIL UART MMIO watchdog"); end
endmodule

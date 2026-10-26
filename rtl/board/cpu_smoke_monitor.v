`timescale 1ns / 1ps

// Board-only test peripheral and observer for fw/cpu_smoke.hex, NOT AES.
// Check a load of 55, its dependent increment to 56, exactly one delayed
// MMIO signature write, and five retirements of the final loop at PC 0x30.
// Keep checking faults/duplicate writes after PASS; first failure is sticky.
module cpu_smoke_monitor #(
    parameter integer RESPONSE_DELAY = 5,
    parameter integer TIMEOUT_CYCLES = 1000000
) (
    input wire clk, input wire rst,
    input wire mmio_valid, input wire mmio_write,
    input wire [31:0] mmio_addr, input wire [31:0] mmio_wdata,
    input wire [3:0] mmio_wstrb, input wire [1:0] mmio_size,
    output wire mmio_ready,
    input wire halted, input wire [3:0] fault_code,
    input wire trace_valid, input wire [31:0] trace_pc,
    input wire trace_rd_we, input wire [4:0] trace_rd,
    input wire [31:0] trace_wdata,
    output reg done, output reg failed, output reg [3:0] first_failure
);
    reg [31:0] age, elapsed;
    reg signature_seen, load_seen, increment_seen;
    reg [2:0] loop_count;
    wire transfer = mmio_valid && mmio_ready;
    // Ready depends on registered wait state, not combinational request valid.
    // Transfer still requires both signals. This avoids an address-decode ->
    // valid -> ready -> CPU-control round trip in the board timing path.
    assign mmio_ready = !rst && age >= RESPONSE_DELAY;
    wire signature_ok = mmio_write && mmio_addr == 32'h40000000 &&
                        mmio_wdata == 32'd56 && mmio_wstrb == 4'hf && mmio_size == 2;
    wire load_event = trace_valid && trace_pc == 32'h1c;
    wire increment_event = trace_valid && trace_pc == 32'h20;
    wire loop_event = trace_valid && trace_pc == 32'h30;
    wire bad_trace = (load_event && (!trace_rd_we || trace_rd != 4 || trace_wdata != 55)) ||
                     (increment_event && (!trace_rd_we || trace_rd != 5 || trace_wdata != 56));
    reg [3:0] detected_failure;
    always @* begin
        detected_failure = 0;
        if (halted) detected_failure = (fault_code != 0) ? fault_code : 4'hf;
        else if (transfer && !signature_ok) detected_failure = 4'h8;
        else if (transfer && signature_seen) detected_failure = 4'h9;
        else if (bad_trace) detected_failure = 4'ha;
        else if (loop_event && !(signature_seen && load_seen && increment_seen)) detected_failure = 4'hc;
        else if (!done && elapsed >= TIMEOUT_CYCLES - 1) detected_failure = 4'hb;
    end

    always @(posedge clk) begin
        if (rst) begin
            age <= 0; elapsed <= 0;
            signature_seen <= 0; load_seen <= 0; increment_seen <= 0; loop_count <= 0;
            done <= 0; failed <= 0; first_failure <= 0;
        end else begin
            if (!mmio_valid || transfer) age <= 0;
            else if (age < RESPONSE_DELAY) age <= age + 1'b1;
            if (!done) elapsed <= elapsed + 1'b1;
            if (transfer && signature_ok) signature_seen <= 1;
            if (load_event) load_seen <= 1;
            if (increment_event) increment_seen <= 1;
            if (loop_event && loop_count < 5) loop_count <= loop_count + 1'b1;
            if (loop_event && loop_count == 4 && signature_seen && load_seen && increment_seen)
                done <= 1;
            if (!failed && detected_failure != 0) begin
                failed <= 1; done <= 1; first_failure <= detected_failure;
            end
        end
    end
endmodule

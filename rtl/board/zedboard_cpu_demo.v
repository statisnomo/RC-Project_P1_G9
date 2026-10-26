`timescale 1ns / 1ps

// CPU smoke program in the PL, observed through the same LEDs as the ALU demo.
// No ARM, Pmod, UART adapter, or physical reset button is required.
module zedboard_cpu_demo #(
    parameter ROM_FILE = "cpu_smoke.hex",
    parameter integer HEARTBEAT_HALF_PERIOD = 50000000,
    parameter integer TIMEOUT_CYCLES = 1000000
) (
    input wire clk_100mhz,
    output wire [7:0] led
);
    reg [15:0] startup_reset = 16'hffff;
    reg [31:0] heartbeat_count = 0;
    reg heartbeat = 0;
    wire rst = startup_reset[15];
    wire mv, mw, mr, halted, tv, twe, done, failed;
    wire [31:0] ma, md, tp, tw;
    wire [3:0] ms, fc, first_failure;
    wire [1:0] size;
    wire [4:0] tr;

    always @(posedge clk_100mhz) begin
        startup_reset <= {startup_reset[14:0], 1'b0};
        if (rst) begin heartbeat_count <= 0; heartbeat <= 0; end
        else if (heartbeat_count == HEARTBEAT_HALF_PERIOD - 1) begin
            heartbeat_count <= 0; heartbeat <= ~heartbeat;
        end else heartbeat_count <= heartbeat_count + 1'b1;
    end

    soc_minimal #(.ROM_FILE(ROM_FILE)) soc (
        .clk(clk_100mhz), .rst(rst),
        .mmio_valid(mv), .mmio_write(mw), .mmio_addr(ma), .mmio_wdata(md),
        .mmio_wstrb(ms), .mmio_size(size), .mmio_ready(mr),
        .mmio_rdata(32'b0), .mmio_error(1'b0),
        .halted(halted), .fault_code(fc), .fault_pc(), .fault_value(),
        .trace_valid(tv), .trace_pc(tp), .trace_instr(),
        .trace_rd_we(twe), .trace_rd(tr), .trace_wdata(tw)
    );
    cpu_smoke_monitor #(.TIMEOUT_CYCLES(TIMEOUT_CYCLES)) monitor (
        .clk(clk_100mhz), .rst(rst), .mmio_valid(mv), .mmio_write(mw),
        .mmio_addr(ma), .mmio_wdata(md), .mmio_wstrb(ms), .mmio_size(size),
        .mmio_ready(mr), .halted(halted), .fault_code(fc),
        .trace_valid(tv), .trace_pc(tp), .trace_rd_we(twe), .trace_rd(tr), .trace_wdata(tw),
        .done(done), .failed(failed), .first_failure(first_failure)
    );
    assign led[0] = heartbeat;
    assign led[1] = !rst && done && !failed;
    assign led[2] = !rst && failed;
    assign led[3] = !rst && !done;
    assign led[7:4] = (!rst && failed) ? first_failure : 4'b0;
endmodule

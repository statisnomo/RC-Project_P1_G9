`timescale 1ns / 1ps

// Only fixed-voltage PL clock/LED banks are used; no PS or Pmod is needed.
module zedboard_alu_demo #(
    parameter integer HEARTBEAT_HALF_PERIOD = 50000000
) (
    input wire clk_100mhz,
    output wire [7:0] led
);
    // Vivado maps initialization to FPGA configuration. This is an FPGA
    // startup reset source, not the reset strategy for a portable ASIC core.
    reg [15:0] startup_reset = 16'hffff;
    reg [31:0] heartbeat_count = 0;
    reg heartbeat = 0;
    wire rst = startup_reset[15];
    wire done, failed;
    wire [3:0] first_failure;

    always @(posedge clk_100mhz) begin
        startup_reset <= {startup_reset[14:0], 1'b0};
        if (rst) begin
            heartbeat_count <= 0;
            heartbeat <= 0;
        end else if (heartbeat_count == HEARTBEAT_HALF_PERIOD - 1) begin
            heartbeat_count <= 0;
            heartbeat <= ~heartbeat;
        end else begin
            heartbeat_count <= heartbeat_count + 1'b1;
        end
    end

    alu_selftest tester (
        .clk(clk_100mhz), .rst(rst), .done(done), .failed(failed),
        .first_failure(first_failure)
    );
    assign led[0] = heartbeat;
    assign led[1] = !rst && done && !failed;
    assign led[2] = !rst && failed;
    assign led[3] = !rst && !done;
    assign led[7:4] = (!rst && failed) ? first_failure : 4'b0;
endmodule

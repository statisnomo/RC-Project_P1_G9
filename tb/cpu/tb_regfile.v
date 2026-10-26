`timescale 1ns / 1ps

// Run with a simulator that supports $fatal (for Icarus: -g2012).
// The testbench otherwise uses Verilog-2005 syntax.
module tb_regfile;
    reg         clk;
    reg         rst;
    reg         we;
    reg  [4:0]  waddr;
    reg  [31:0] wdata;
    reg  [4:0]  raddr1;
    wire [31:0] rdata1;
    reg  [4:0]  raddr2;
    wire [31:0] rdata2;

    reg [31:0] expected_registers [0:31];
    reg [31:0] random_state;
    reg [31:0] random_controls;
    reg [31:0] random_data;
    integer checks;
    integer errors;
    integer register_index;
    integer cycle_index;

    regfile dut (
        .clk(clk), .rst(rst),
        .we(we), .waddr(waddr), .wdata(wdata),
        .raddr1(raddr1), .rdata1(rdata1),
        .raddr2(raddr2), .rdata2(rdata2)
    );

    always #5 clk = ~clk;

    function [31:0] next_random;
        input [31:0] state;
        reg [31:0] value;
        begin
            value = state ^ (state << 13);
            value = value ^ (value >> 17);
            next_random = value ^ (value << 5);
        end
    endfunction

    task check_ports;
        reg [31:0] expected1;
        reg [31:0] expected2;
        begin
            expected1 = (raddr1 == 0) ? 32'd0 : expected_registers[raddr1];
            expected2 = (raddr2 == 0) ? 32'd0 : expected_registers[raddr2];
            checks = checks + 2;
            if (rdata1 !== expected1) begin
                errors = errors + 1;
                $display("FAIL regfile t=%0t port=1 addr=%0d got=%h expected=%h rst=%b we=%b",
                         $time, raddr1, rdata1, expected1, rst, we);
            end
            if (rdata2 !== expected2) begin
                errors = errors + 1;
                $display("FAIL regfile t=%0t port=2 addr=%0d got=%h expected=%h rst=%b we=%b",
                         $time, raddr2, rdata2, expected2, rst, we);
            end
        end
    endtask

    // The first check occurs before the active edge. In particular, raising
    // rst must not clear data early, and we must not bypass wdata to a read.
    task clock_cycle;
        input reset_value;
        input write_enable;
        input [4:0] write_address;
        input [31:0] write_data;
        input [4:0] read_address1;
        input [4:0] read_address2;
        integer index;
        begin
            @(negedge clk);
            rst = reset_value;
            we = write_enable;
            waddr = write_address;
            wdata = write_data;
            raddr1 = read_address1;
            raddr2 = read_address2;
            #1;
            check_ports;
            @(posedge clk);
            #1;
            if (reset_value) begin
                for (index = 0; index < 32; index = index + 1)
                    expected_registers[index] = 32'd0;
            end else if (write_enable && (write_address != 0)) begin
                expected_registers[write_address] = write_data;
            end
            check_ports;
        end
    endtask

    // Address changes must propagate without a rising clock edge.
    task read_pair;
        input [4:0] address1;
        input [4:0] address2;
        begin
            @(negedge clk);
            rst = 0;
            we = 0;
            raddr1 = address1;
            raddr2 = address2;
            #1;
            check_ports;
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        we = 0;
        waddr = 0;
        wdata = 0;
        raddr1 = 0;
        raddr2 = 0;
        checks = 0;
        errors = 0;
        random_state = 32'hc0ffee01;
        for (register_index = 0; register_index < 32;
             register_index = register_index + 1)
            expected_registers[register_index] = 32'd0;

        // x0 is defined even before the first reset clock edge.
        #1;
        check_ports;
        @(posedge clk);
        #1;
        check_ports;
        for (register_index = 0; register_index < 32;
             register_index = register_index + 1)
            read_pair(register_index[4:0], 31 - register_index);

        // Exercise every writable register and both same-address read ports.
        for (register_index = 1; register_index < 32;
             register_index = register_index + 1)
            clock_cycle(0, 1, register_index[4:0],
                        32'h10203040 ^ (32'h01010101 * register_index),
                        register_index[4:0], register_index[4:0]);
        for (register_index = 0; register_index < 32;
             register_index = register_index + 1)
            read_pair(register_index[4:0], 31 - register_index);

        clock_cycle(0, 1, 5'd0, 32'hffffffff, 5'd0, 5'd0);
        clock_cycle(0, 0, 5'd7, 32'hdeadbeef, 5'd7, 5'd0);
        clock_cycle(0, 1, 5'd7, 32'hdeadbeef, 5'd7, 5'd7);
        clock_cycle(0, 1, 5'd7, 32'h01234567, 5'd7, 5'd7);

        // Reset is synchronous and wins even when a write is requested.
        clock_cycle(1, 1, 5'd7, 32'hffffffff, 5'd7, 5'd31);
        clock_cycle(1, 1, 5'd11, 32'hffffffff, 5'd11, 5'd0);
        for (register_index = 0; register_index < 32;
             register_index = register_index + 1)
            read_pair(register_index[4:0], 31 - register_index);

        // Independent scoreboard checks random addresses/data, disabled
        // writes, x0 writes, occasional resets, and read/write collisions.
        for (cycle_index = 0; cycle_index < 512;
             cycle_index = cycle_index + 1) begin
            random_state = next_random(random_state);
            random_controls = random_state;
            random_state = next_random(random_state);
            random_data = random_state;
            clock_cycle((cycle_index % 97) == 96,
                        random_controls[15], random_controls[4:0], random_data,
                        (cycle_index % 4) == 0 ? random_controls[4:0] : random_controls[9:5],
                        (cycle_index % 4) == 1 ? random_controls[4:0] : random_controls[14:10]);
        end
        for (register_index = 0; register_index < 32;
             register_index = register_index + 1)
            read_pair(register_index[4:0], 31 - register_index);

        if (errors != 0)
            $fatal(1, "FAIL tb_regfile: %0d of %0d port checks failed", errors, checks);
        $display("PASS tb_regfile: %0d port checks", checks);
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "FAIL tb_regfile: simulation watchdog expired");
    end
endmodule

`timescale 1ns / 1ps
// Architectural traces come from the independent Python interpreter.
// The slave models independently implement RAM and side-effecting MMIO.
// Vivado stages data files next to the simulator; standalone runners use build/.
module tb_cpu_core #(
`ifdef VIVADO_GUI
    parameter PROGRAM_DIR = "./"
`else
    parameter PROGRAM_DIR = "../../tb/programs/"
`endif
);
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst = 1, checking = 0;
    wire iv, ir, ie, dv, dw, dr, de;
    wire [31:0] ia, idata, da, wd, rd;
    wire [3:0] ws, fault_code;
    wire [1:0] size;
    wire halted, tv, twe;
    wire [31:0] fault_pc, fault_value, tp, ti, tw;
    wire [4:0] tr;
    cpu_core dut (.clk(clk), .rst(rst),
        .imem_valid(iv), .imem_addr(ia), .imem_ready(ir), .imem_rdata(idata), .imem_error(ie),
        .dmem_valid(dv), .dmem_write(dw), .dmem_addr(da), .dmem_wdata(wd),
        .dmem_wstrb(ws), .dmem_size(size), .dmem_ready(dr), .dmem_rdata(rd), .dmem_error(de),
        .halted(halted), .fault_code(fault_code), .fault_pc(fault_pc), .fault_value(fault_value),
        .trace_valid(tv), .trace_pc(tp), .trace_instr(ti), .trace_rd_we(twe), .trace_rd(tr), .trace_wdata(tw));

    reg [31:0] program_words [0:1023];
    reg [31:0] ram [0:1023], scratch [0:3];
    reg [159:0] expected_trace [0:2047];
    reg [223:0] expected_bus [0:2047];
    reg [31:0] expected_regs [0:31], expected_ram [0:1023];
    integer mode = 0, i_age = 0, d_age = 0, i_sequence = 0, d_sequence = 0;
    integer trace_count = 0, bus_count = 0, expected_count, expected_bus_count;
    integer read_count = 0, write_count = 0;
    integer total_retired = 0, case_count = 0, cycles, n, lane;
    integer load_bypass = 0, stalled_decode = 0, drained_fetch = 0;
    reg i_waiting = 0, d_waiting = 0;
    reg [31:0] held_iaddr;
    reg [70:0] held_data;
    reg [31:0] data_reply;
    reg data_error;
    reg [159:0] observed_trace;
    reg [223:0] observed_bus;
    string case_name;
    `include "sim_data_check.vh"

    assign ir = iv && (mode != 1 || i_age >= 1 + ((ia[5:2] ^ (i_sequence & 15)) % 7));
    assign dr = dv && (mode == 0 || d_age >= (mode == 1 ? 1 + (d_sequence % 7) : 8));
    assign ie = ia >= 4096 || ia[1:0] != 0;
    assign idata = ie ? 32'b0 : program_words[ia[11:2]];
    assign rd = data_reply;
    assign de = data_error;
    always @* begin
        data_reply = 0; data_error = 0;
        if (da >= 'h1000 && da < 'h2000) data_reply = ram[da[11:2]];
        else if (da >= 'h40000000 && da < 'h40000400) begin
            if (da[7:2] == 0) data_reply = scratch[da[9:8]];
            else if (da[7:2] == 1 && !dw) data_reply = read_count;
            else data_error = 1;
        end else data_error = 1;
    end

    always @(posedge clk) begin
        if (rst) begin
            i_age = 0; d_age = 0; i_sequence = 0; d_sequence = 0;
            i_waiting = 0; d_waiting = 0;
        end else begin
            if (i_waiting && (!iv || ia !== held_iaddr))
                $fatal(1,"FAIL %s: instruction request changed while waiting", case_name);
            if (d_waiting && (!dv || {dw,da,wd,ws,size} !== held_data))
                $fatal(1,"FAIL %s: data request changed while waiting", case_name);
            i_waiting = iv && !ir; held_iaddr = ia;
            d_waiting = dv && !dr; held_data = {dw,da,wd,ws,size};
            if (dut.d_advance && dut.rf_we && dut.e_mem_read &&
                ((dut.d_rs1_used && dut.e_rd == dut.d_rs1) ||
                 (dut.d_rs2_used && dut.e_rd == dut.d_rs2))) load_bypass = load_bypass + 1;
            if (dv && !dr && dut.d_valid) stalled_decode = stalled_decode + 1;
            if (dut.f_discard && iv && ir) drained_fetch = drained_fetch + 1;
            if (dv && dr) begin
                observed_bus = {da, {31'b0,dw}, dw ? wd : 32'b0,
                                {28'b0,ws}, {30'b0,size}, dw ? 32'b0 : rd, {31'b0,de}};
                if (checking) begin
                    if (bus_count >= expected_bus_count || observed_bus !== expected_bus[bus_count])
                        $fatal(1,"FAIL %s mode %0d bus %0d actual=%h expected=%h",case_name,mode,bus_count,observed_bus,expected_bus[bus_count]);
                    bus_count = bus_count + 1;
                end
                if (!de) begin
                    if (dw) begin
                        write_count = write_count + 1;
                        for (lane = 0; lane < 4; lane = lane + 1)
                            if (ws[lane]) begin
                                if (da < 'h2000) ram[da[11:2]][lane*8 +: 8] <= wd[lane*8 +: 8];
                                else scratch[da[9:8]][lane*8 +: 8] <= wd[lane*8 +: 8];
                            end
                    end else if (da >= 'h40000000) read_count <= read_count + 1;
                end
            end
            // Use nonblocking updates: ready and read data remain stable for
            // the DUT's sampling edge, including the side-effecting read counter.
            if (iv && ir) begin i_age <= 0; i_sequence <= i_sequence + 1; end
            else if (iv) i_age <= i_age + 1;
            else i_age <= 0;
            if (dv && dr) begin d_age <= 0; d_sequence <= d_sequence + 1; end
            else if (dv) d_age <= d_age + 1;
            else d_age <= 0;
        end
        #1;
        if (!rst && checking && tv) begin
            observed_trace = {tp, ti, {31'b0,twe}, {27'b0,(twe ? tr : 5'b0)}, twe ? tw : 32'b0};
            if (trace_count >= expected_count || observed_trace !== expected_trace[trace_count])
                $fatal(1,"FAIL %s mode %0d trace %0d actual=%h expected=%h",case_name,mode,trace_count,observed_trace,expected_trace[trace_count]);
            trace_count = trace_count + 1; total_retired = total_retired + 1;
        end
    end

    task run_case;
        input string name;
        input integer commits, transfers;
        input [3:0] code;
        input [31:0] pc, value;
        integer k;
        string hex_path, trace_path, bus_path, regs_path, ram_path;
        begin
            @(negedge clk); rst = 1; checking = 0; case_name = name;
            // Materialize paths as strings instead of passing a mixed
            // packed-parameter/string concatenation into simulator file I/O.
            hex_path = $sformatf("%0s%0s.hex", PROGRAM_DIR, name);
            trace_path = $sformatf("%0s%0s.trace", PROGRAM_DIR, name);
            bus_path = $sformatf("%0s%0s.bus", PROGRAM_DIR, name);
            regs_path = $sformatf("%0s%0s.regs", PROGRAM_DIR, name);
            ram_path = $sformatf("%0s%0s.ram", PROGRAM_DIR, name);
            require_hex_file(hex_path, 1024);
            require_hex_file(trace_path, commits > 0 ? commits : 1);
            require_hex_file(bus_path, transfers > 0 ? transfers : 1);
            require_hex_file(regs_path, 32);
            require_hex_file(ram_path, 1024);
            $readmemh(hex_path, program_words, 0, 1023);
            $readmemh(trace_path, expected_trace, 0, commits > 0 ? commits-1 : 0);
            $readmemh(bus_path, expected_bus, 0, transfers > 0 ? transfers-1 : 0);
            $readmemh(regs_path, expected_regs, 0, 31);
            $readmemh(ram_path, expected_ram, 0, 1023);
            for (k=0;k<1024;k=k+1) ram[k]=0;
            for (k=0;k<4;k=k+1) scratch[k]=0;
            trace_count=0; bus_count=0; read_count=0; write_count=0;
            expected_count=commits; expected_bus_count=transfers;
            repeat(3) @(negedge clk);
            checking=1; rst=0; cycles=0;
            while (!halted && cycles < 20000) begin @(negedge clk); cycles=cycles+1; end
            if (!halted || fault_code !== code || fault_pc !== pc || fault_value !== value)
                $fatal(1,"FAIL %s mode %0d fault: code=%0d pc=%h value=%h",name,mode,fault_code,fault_pc,fault_value);
            repeat(16) @(negedge clk); // Detect any late retirement or repeated effect after a fault.
            if (trace_count != commits || bus_count != transfers)
                $fatal(1,"FAIL %s count mismatch trace=%0d bus=%0d",name,trace_count,bus_count);
            for (k=0;k<32;k=k+1)
                if (dut.registers.regs[k] !== expected_regs[k]) $fatal(1,"FAIL %s register x%0d",name,k);
            for (k=0;k<1024;k=k+1)
                if (ram[k] !== expected_ram[k]) $fatal(1,"FAIL %s RAM word %0d",name,k);
            if (dv || tv || fault_code !== code || fault_pc !== pc || fault_value !== value)
                $fatal(1,"FAIL %s halt did not remain stable",name);
            checking=0; case_count=case_count+1;
        end
    endtask

    initial begin
        for (mode=0;mode<3;mode=mode+1) begin
            `include "cases.vh"
        end
        if (load_bypass == 0 || stalled_decode == 0 || drained_fetch == 0)
            $fatal(1,"FAIL missing pipeline coverage: bypass=%0d stall=%0d drain=%0d",load_bypass,stalled_decode,drained_fetch);
        // Reset cancels a not-yet-completed store and restarts PC/register state.
        @(negedge clk); rst=1; mode=2; checking=0;
        // The same file was checked during run_case above; use a stable string.
        case_name = $sformatf("%0sdependencies.hex", PROGRAM_DIR);
        require_hex_file(case_name, 1024);
        $readmemh(case_name,program_words,0,1023);
        ram[0]=32'haabbccdd; write_count=0;
        repeat(3) @(negedge clk);
        rst=0;
        wait(dv && dw && !dr);
        @(negedge clk); rst=1;
        repeat(3) @(negedge clk);
        if (write_count != 0 || ram[0] !== 32'haabbccdd || halted || dut.registers.regs[2] != 0)
            $fatal(1,"FAIL reset cancellation or RAM preservation");
        run_case("dependencies",18,11,4'd1,32'h0000004c,0);
        $display("PASS tb_cpu_core: %0d cases, %0d retirements, load bypass=%0d, stalled decode cycles=%0d, drained fetches=%0d; reset cancellation",case_count,total_retired,load_bypass,stalled_decode,drained_fetch);
        $finish;
    end
    initial begin #10000000; $fatal(1,"FAIL CPU test watchdog"); end
endmodule

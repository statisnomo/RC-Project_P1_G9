`timescale 1ns / 1ps
module tb_soc_minimal #(
`ifdef VIVADO_GUI
    parameter ROM_FILE = "cpu_smoke.hex"
`else
    parameter ROM_FILE = "../../fw/cpu_smoke.hex"
`endif
);
    `include "sim_data_check.vh"
    reg clk=0, rst=1;
    always #5 clk=~clk;
    wire mv,mw,halted,tv,twe;
    wire [31:0] ma,md,fp,fv,tp,ti,tw;
    wire [3:0] ms,fc;
    wire [1:0] size;
    wire [4:0] tr;
    integer age=0, writes=0, loops=0, cycles=0, retires=0;
    wire ready=mv && age>=5;
    soc_minimal #(.ROM_FILE(ROM_FILE)) dut (
        .clk(clk),.rst(rst),.mmio_valid(mv),.mmio_write(mw),.mmio_addr(ma),
        .mmio_wdata(md),.mmio_wstrb(ms),.mmio_size(size),
        .mmio_ready(ready),.mmio_rdata(32'b0),.mmio_error(1'b0),
        .halted(halted),.fault_code(fc),.fault_pc(fp),.fault_value(fv),
        .trace_valid(tv),.trace_pc(tp),.trace_instr(ti),.trace_rd_we(twe),.trace_rd(tr),.trace_wdata(tw));

    // Check the actual DUT ROM before releasing reset. Read the reference
    // with fscanf, independently of the ROM's time-zero readmemh call.
    // Never reload/repair the DUT here: that would hide an initialization bug.
    task automatic check_program_rom;
        input string filename;
        integer handle, index, scanned;
        reg [31:0] expected;
        begin
            require_hex_file(filename, 1024);
            handle = $fopen(filename, "r");
            if (handle == 0) begin
                $fatal(1, "FAIL SIM_DATA cannot reopen '%0s' for ROM comparison", filename);
                return;
            end
            for (index=0; index<1024; index=index+1) begin
                scanned = $fscanf(handle, "%h", expected);
                if (scanned != 1 || (^expected) === 1'bx) begin
                    $fclose(handle);
                    $fatal(1, "FAIL SIM_DATA '%0s' changed during ROM comparison at word=%0d", filename, index);
                    return;
                end
                if (dut.rom.words[index] !== expected) begin
                    $fclose(handle);
                    $fatal(1, "FAIL SIM_ROM_LOAD '%0s' word=%0d actual=%h expected=%h; CPU held in reset", filename, index, dut.rom.words[index], expected);
                    return;
                end
            end
            $fclose(handle);
            $display("SIM_ROM_LOAD_OK '%0s': all 1024 DUT words match file; first instruction=%h", filename, dut.rom.words[0]);
        end
    endtask
    always @(posedge clk) begin
        if(rst) age<=0;
        else if(mv && ready) begin
            age<=0;
            if(!mw || ma !== 32'h40000000 || md !== 56 || ms !== 4'hf || size !== 2)
                $fatal(1,"FAIL soc MMIO signature");
            writes=writes+1;
        end else if(mv) age<=age+1;
        #1;
        if(!rst) begin
            if(halted) $fatal(1,"FAIL soc fault: code=%0d pc=%h value=%h ROM='%0s'",fc,fp,fv,ROM_FILE);
            if(tv) begin
                retires=retires+1;
                if(tp == 48) loops=loops+1;
            end
        end
    end
    initial begin
        #1; // Let time-zero ROM initialization finish; Run All starts this check.
        check_program_rom(ROM_FILE);
        repeat(3) @(negedge clk);
        rst=0;
        while(loops<5 && cycles<2000) begin @(negedge clk); cycles=cycles+1; end
        if(loops<5 || writes!=1 || dut.ram.words[0] !== 55 || dut.ram.words[1] !== 56 ||
           dut.cpu.registers.regs[4] !== 55 || dut.cpu.registers.regs[5] !== 56)
            $fatal(1,"FAIL soc final check: loops=%0d writes=%0d RAM[0]=%h RAM[1]=%h x4=%h x5=%h retires=%0d",loops,writes,dut.ram.words[0],dut.ram.words[1],dut.cpu.registers.regs[4],dut.cpu.registers.regs[5],retires);
        $display("PASS tb_soc_minimal: ROM program, sum=55, load-use=56, one delayed MMIO write, %0d retirements",retires);
        $finish;
    end
    initial begin #100000; $fatal(1,"FAIL soc watchdog"); end
endmodule

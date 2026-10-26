`timescale 1ns / 1ps
module tb_soc_minimal #(
`ifdef VIVADO_GUI
    parameter ROM_FILE = "cpu_smoke.hex"
`else
    parameter ROM_FILE = "../../fw/cpu_smoke.hex"
`endif
);
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
            if(halted) $fatal(1,"FAIL soc fault %0d at %h",fc,fp);
            if(tv) begin
                retires=retires+1;
                if(tp == 48) loops=loops+1;
            end
        end
    end
    initial begin
        repeat(3) @(negedge clk);
        rst=0;
        while(loops<5 && cycles<2000) begin @(negedge clk); cycles=cycles+1; end
        if(loops<5 || writes!=1 || dut.ram.words[0] !== 55 || dut.ram.words[1] !== 56 ||
           dut.cpu.registers.regs[4] !== 55 || dut.cpu.registers.regs[5] !== 56)
            $fatal(1,"FAIL soc final RAM/register/signature check");
        $display("PASS tb_soc_minimal: ROM program, sum=55, load-use=56, one delayed MMIO write, %0d retirements",retires);
        $finish;
    end
    initial begin #100000; $fatal(1,"FAIL soc watchdog"); end
endmodule

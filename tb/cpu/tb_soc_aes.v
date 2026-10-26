`timescale 1ns / 1ps
module soc_aes_checks #(parameter WAIT_CYCLES=1) (output reg finished=0);
    reg clk=0;always #5 clk=~clk;
    reg rst=1,negative_test=0;
    wire mmio_valid,mmio_write,mmio_ready,mmio_error,aes_busy,aes_done,halted,trace_valid,trace_rd_we;
    wire [31:0] mmio_addr,mmio_wdata,mmio_rdata,fault_pc,fault_value,trace_pc,trace_instr,trace_wdata;
    wire [3:0] mmio_wstrb,fault_code;
    wire [1:0] mmio_size;
    wire [4:0] trace_rd;
`ifdef VIVADO_GUI
    localparam ROM="aes_smoke.hex";
`else
    localparam ROM="fw/aes_smoke.hex";
`endif
    soc_aes #(.ROM_FILE(ROM),.AES_WAIT_CYCLES(WAIT_CYCLES)) dut(.*);
    integer cycles=0,starts=0,reads=0,key_writes=0,pt_writes=0,passes=0;
    integer first_operand=-1,launch_cycle=0,run_count,i;
    function [31:0] expected_word;
        input integer idx;
        reg [127:0] ct;
        integer b;
        begin
            case(idx/4)
                0,1:ct=128'h69c4e0d86a7b0430d8cdb78070b4c55a;
                2:ct=128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
                default:ct=128'h3925841d02dc09fbdc118597196a0b32;
            endcase
            for(b=0;b<4;b=b+1) expected_word[8*b +: 8]=ct[127-8*(4*(idx%4)+b) -: 8];
        end
    endfunction
    always @(posedge clk) begin
        if(rst) begin cycles=0;starts=0;reads=0;key_writes=0;pt_writes=0;first_operand=-1;end
        else begin
            cycles=cycles+1;
            if(!negative_test && halted) $fatal(1,"FAIL CPU halt %0d pc=%h",fault_code,fault_pc);
            if(mmio_valid && mmio_ready) begin
                if(!negative_test && mmio_error) $fatal(1,"FAIL CPU MMIO error addr=%h",mmio_addr);
                if(mmio_write && mmio_addr[7:4]==1) key_writes=key_writes+1;
                if(mmio_write && mmio_addr[7:4]==2) pt_writes=pt_writes+1;
                if(mmio_write && (mmio_addr[7:4]==1 || mmio_addr[7:4]==2) && first_operand<0) first_operand=cycles;
                if(dut.aes.core_start) begin starts=starts+1;launch_cycle=cycles;end
                if(!mmio_write && mmio_addr[7:4]==3) begin
                    if(!negative_test && (reads>=16 || mmio_addr!==32'h40000030+4*(reads%4) || mmio_rdata!==expected_word(reads)))
                        $fatal(1,"FAIL CPU ciphertext word %0d got=%h expected=%h",reads,mmio_rdata,expected_word(reads));
                    reads=reads+1;
                    if(!negative_test && reads%4==0) begin
                        $display("CPU_AES_MEASURE wait=%0d block=%0d operand-first-write-to-last-read=%0d start-to-last-read=%0d clocks",WAIT_CYCLES,(reads/4)-1,cycles-first_operand,cycles-launch_cycle);
                        first_operand=-1;
                    end
                end
            end
        end
    end
    task reset_system;
        begin @(negedge clk);rst=1;repeat(3) @(negedge clk);rst=0;end
    endtask
    task wait_status;
        input [31:0] expected;
        integer waited;
        begin
            waited=0;
            while(dut.system.cpu.registers.regs[31]===0 && waited<30000) begin
                @(negedge clk);waited=waited+1;
                if(halted) $fatal(1,"FAIL unexpected halt waiting for firmware status");
            end
            if(dut.system.cpu.registers.regs[31] !== expected)
                $fatal(1,"FAIL firmware status actual=%h expected=%h",dut.system.cpu.registers.regs[31],expected);
            repeat(20) @(negedge clk);
            if(dut.system.ram.words[16] !== expected) $fatal(1,"FAIL RAM status");
        end
    endtask
    task healthy_result;
        begin
            wait_status(1);
            if(starts!=4 || reads!=16 || key_writes!=12 || pt_writes!=16)
                $fatal(1,"FAIL operation counts start=%0d reads=%0d keys=%0d pt=%0d",starts,reads,key_writes,pt_writes);
            for(i=0;i<16;i=i+1) if(dut.system.ram.words[i] !== expected_word(i)) $fatal(1,"FAIL RAM ciphertext %0d",i);
            if(dut.system.cpu.registers.regs[2] !== 32'h2000) $fatal(1,"FAIL stack initialization");
            passes=passes+1;
        end
    endtask
    initial begin
        reset_system;healthy_result;
        reset_system;wait(aes_busy);reset_system;healthy_result;
        reset_system;healthy_result;
        // Exercise both firmware failure branches using testbench-only faults.
        negative_test=1;reset_system;wait(aes_done);
        force dut.aes.core_ct=128'b0;
        wait_status(2);release dut.aes.core_ct;
        reset_system;force dut.aes.core.done=1'b0;
        wait_status(3);release dut.aes.core.done;
        // Unimplemented peripheral windows must terminate with an access error.
        reset_system;wait(mmio_valid);
        @(negedge clk);force dut.mmio_addr=32'h40000100;
        wait(halted);@(negedge clk);
        if(fault_code!==7) $fatal(1,"FAIL unimplemented window must be store-access fault");
        release dut.mmio_addr;
        reset_system;negative_test=0;healthy_result;
        $display("PASS soc_aes_checks: wait=%0d, %0d healthy four-block runs, reset mid-AES, mismatch, poll timeout, absent peripheral error",WAIT_CYCLES,passes);
        finished=1;
    end
endmodule
module tb_soc_aes;
    wire a,b;
    soc_aes_checks #(.WAIT_CYCLES(1)) normal_bus(a);
    soc_aes_checks #(.WAIT_CYCLES(5)) delayed_bus(b);
    initial begin wait(a&&b);$display("PASS tb_soc_aes: real CPU/ROM/RAM/AES, 1/5 wait edges, 32 checked blocks, restart and firmware error paths");$finish;end
    initial begin #3000000;$fatal(1,"FAIL CPU AES watchdog");end
endmodule

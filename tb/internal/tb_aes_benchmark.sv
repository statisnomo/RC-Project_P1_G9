`timescale 1ns/1ps
module aes_benchmark_case #(parameter WAITS=1)(output reg finished=0);
    reg clk=0,rst=1;always #5 clk=~clk;
    wire halted;
    soc_benchmark #(.WAIT_CYCLES(WAITS)) dut(clk,rst,halted);
    reg [383:0] vectors[0:412];
    integer trial=0,reads=0,cycle=0,last_cycle=0;
    integer sw_ticks=0,hw_ticks=0,sw_min=32'h7fffffff,sw_max=0,hw_min=32'h7fffffff,hw_max=0;
    integer changed=0,flip_min=128,flip_max=0,flip_sum=0;
    reg [127:0] result,swresult;
    reg tracking=0;
    // Independent cycle measurement at each timer request capture.
    always @(posedge clk) begin
        cycle++;
        if(!rst && halted) $fatal(1,"FAIL benchmark halt waits=%0d pc=%h fault=%h",WAITS,dut.system.cpu.fault_pc,dut.system.cpu.fault_code);
        if(!rst && tracking && dut.timer.valid && !dut.timer.ready) begin
            case(reads%4)
                0,2:last_cycle=cycle;
                1:sw_ticks=cycle-last_cycle;
                3:hw_ticks=cycle-last_cycle;
            endcase
            reads++;
        end
    end
    task launch(input integer n);
        @(negedge clk);
        for(integer wordno=0;wordno<4;wordno++) for(integer b=0;b<4;b++) begin
            dut.system.ram.words[wordno][8*b+:8]=vectors[n][383-8*(4*wordno+b)-:8];
            dut.system.ram.words[4+wordno][8*b+:8]=vectors[n][255-8*(4*wordno+b)-:8];
        end
        dut.system.ram.words[17]=1;
    endtask
    initial begin
        $readmemh("benchmark_vectors.mem",vectors);
        for(integer n=0;n<413;n++) if(^vectors[n]===1'bx) $fatal(1,"FAIL missing benchmark vector %0d",n);
        repeat(5) @(negedge clk);rst=0;
        wait(dut.system.ram.words[16]===1);tracking=1;
        for(trial=0;trial<413;trial++) begin
            launch(trial);
            wait(dut.system.ram.words[17]===0 && dut.system.ram.words[16]===2);
            @(negedge clk);
            for(integer wordno=0;wordno<4;wordno++) for(integer b=0;b<4;b++) begin
                result[127-8*(4*wordno+b)-:8]=dut.system.ram.words[12+wordno][8*b+:8];
                swresult[127-8*(4*wordno+b)-:8]=dut.system.ram.words[8+wordno][8*b+:8];
            end
            if(result!==vectors[trial][127:0] || swresult!==vectors[trial][127:0] || dut.system.ram.words[18]!==1)
                $fatal(1,"FAIL benchmark vector=%0d waits=%0d SW=%h HW=%h expected=%h",trial,WAITS,swresult,result,vectors[trial][127:0]);
            if(reads!=4*(trial+1) || sw_ticks<=0 || hw_ticks<=0 ||
               dut.system.ram.words[19]!==sw_ticks || dut.system.ram.words[20]!==hw_ticks)
                $fatal(1,"FAIL benchmark timing trial=%0d reads=%0d SW=%0d HW=%0d",trial,reads,sw_ticks,hw_ticks);
            if(sw_ticks<sw_min) sw_min=sw_ticks;if(sw_ticks>sw_max) sw_max=sw_ticks;
            if(hw_ticks<hw_min) hw_min=hw_ticks;if(hw_ticks>hw_max) hw_max=hw_ticks;
            if(trial==284) $display("BENCHMARK_FIPS waits=%0d sw_cycles=%0d hw_cycles=%0d",WAITS,sw_ticks,hw_ticks);
            if(trial>=285) begin
                changed=$countones(result^vectors[284][127:0]);
                if($countones(vectors[trial][255:128]^vectors[284][255:128])!=1) $fatal(1,"FAIL flip stimulus");
                if(changed<flip_min) flip_min=changed;if(changed>flip_max) flip_max=changed;flip_sum+=changed;
            end
        end
        // Abort a software operation and verify that startup returns to a clean mailbox.
        launch(284);wait(dut.system.ram.words[16]===0);repeat(100) @(negedge clk);
        tracking=0;rst=1;repeat(5) @(negedge clk);rst=0;
        wait(dut.system.ram.words[16]===1);
        if(dut.system.ram.words[17]!==0) $fatal(1,"FAIL benchmark reset mailbox");
        launch(284);wait(dut.system.ram.words[17]===0 && dut.system.ram.words[16]===2);
        if(dut.system.ram.words[18]!==1) $fatal(1,"FAIL benchmark restart");
        $display("BENCHMARK_CASE_PASS waits=%0d vectors=413 sw_cycles=%0d..%0d hw_cycles=%0d..%0d flips=128 changed_bits=%0d..%0d sum=%0d reset_restart=PASS",WAITS,sw_min,sw_max,hw_min,hw_max,flip_min,flip_max,flip_sum);
        finished=1;
    end
endmodule
module tb_aes_benchmark;
    wire a,b;
    aes_benchmark_case #(.WAITS(1)) normal(a);
    aes_benchmark_case #(.WAITS(5)) delayed(b);
    initial begin wait(a && b);
        $display("PASS tb_aes_benchmark: real RV32I software AES versus MMIO hardware, 413 independent vectors per wait mode, CPU-visible timer checked, 128 one-bit changes and reset recovery");$finish;end
    initial begin #1000000000;$fatal(1,"FAIL benchmark watchdog");end
endmodule

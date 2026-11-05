`timescale 1ns/1ps
module tb_benchmark_recovery;
    reg clk=0,rst=1;always #5 clk=~clk;
    wire halted;integer starts=0;
    soc_benchmark dut(clk,rst,halted);
    always @(posedge clk) if(!rst) begin
        if(halted) $fatal(1,"FAIL recovery CPU halted");
        if(dut.aes.core_start) starts++;
    end
    task launch;
        @(negedge clk);
        dut.system.ram.words[0]=32'h03020100;dut.system.ram.words[1]=32'h07060504;
        dut.system.ram.words[2]=32'h0b0a0908;dut.system.ram.words[3]=32'h0f0e0d0c;
        dut.system.ram.words[4]=32'h33221100;dut.system.ram.words[5]=32'h77665544;
        dut.system.ram.words[6]=32'hbbaa9988;dut.system.ram.words[7]=32'hffeeddcc;
        dut.system.ram.words[17]=1;
    endtask
    task check_good;
        wait(dut.system.ram.words[17]===0 && dut.system.ram.words[16]===2);
        if(dut.system.ram.words[18]!==1 || dut.system.ram.words[12]!==32'hd8e0c469 ||
           dut.system.ram.words[13]!==32'h30047b6a || dut.system.ram.words[14]!==32'h80b7cdd8 ||
           dut.system.ram.words[15]!==32'h5ac5b470) $fatal(1,"FAIL recovery ciphertext");
    endtask
    initial begin
        repeat(5) @(negedge clk);rst=0;wait(dut.system.ram.words[16]===1);
        // Hide DONE from the CPU: the bounded status loop must return an error.
        force dut.aes.rdata=32'b0;
        launch();wait(dut.system.ram.words[17]===0 && dut.system.ram.words[16]===3);
        if(dut.system.ram.words[18]!==0 || starts!=1) $fatal(1,"FAIL timeout reporting");
        release dut.aes.rdata;
        launch();check_good();
        // Reset after START while the accelerator is actually busy.
        launch();wait(dut.aes.busy===1);@(negedge clk);rst=1;
        repeat(5) @(negedge clk);rst=0;wait(dut.system.ram.words[16]===1);
        // Both timestamp differences must work across modulo-2^32 wrap.
        @(negedge clk);dut.timer.cycles=32'hfffff000;
        launch();check_good();
        if(dut.system.ram.words[19]!==24576 || dut.system.ram.words[20]!==213)
            $fatal(1,"FAIL modulo timer differences");
        $display("PASS tb_benchmark_recovery: bounded hardware-status timeout, clean retry, reset during AES and software timing across 32-bit wrap");$finish;
    end
    initial begin #50000000;$fatal(1,"FAIL recovery watchdog");end
endmodule

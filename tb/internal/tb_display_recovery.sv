`timescale 1ns/1ps
// Same shipped ROM as the board. Faults are injected only by this testbench.
module tb_display_recovery;
    reg clk=0,rst=1; always #5 clk=~clk;
    reg [15:0] keys=0;
    wire [3:0] rows,drive;
    wire cs,sd,sck,dc,res,vbat,vdd,tx,halted,key_event,block_event;
    keypad_matrix_model matrix(keys,drive,rows);
    soc_display #(.COLUMN_CYCLES(6),.DEBOUNCE_FRAMES(2),.WAIT_CYCLES(4),
        .CLKS_PER_BIT(8),.RESET_CYCLES(9),.PANEL_CYCLES(19),.DISCHARGE_CYCLES(37),.HALF_SPI(3))
        dut(.clk(clk),.rst(rst),.rows_n(rows),.col_drive_low(drive),.cs_n(cs),.mosi(sd),
            .sclk(sck),.dc(dc),.res_n(res),.vbat_n(vbat),.vdd_n(vdd),.tx(tx),.halted(halted),
            .key_event(key_event),.block_event(block_event),.last_digit());
    localparam [63:0] POS=64'hdefb73a98654210c;
    integer completed=0,events=0,case_no=0;
    always @(posedge clk) if(!rst) begin
        if(block_event) completed++;
        if(key_event) events++;
    end
    task tick(input integer n);repeat(n) @(negedge clk);endtask
    task boot;
        rst=1;keys=0;tick(5);rst=0;tick(250);
        completed=0;events=0;
        if(dut.system.ram.words[12]!==0 || dut.system.ram.words[13]!==0) $fatal(1,"FAIL boot diagnostics");
    endtask
    task digit(input [3:0] n);
        keys=16'h1<<POS[4*n+:4];tick(250);keys=0;tick(200);
    endtask
    task zero_block;for(integer i=0;i<32;i++) digit(0);endtask
    task check_zero_result;
        if(dut.system.ram.words[8]!==32'h373ba1c6 || dut.system.ram.words[9]!==32'h825b8f87 ||
           dut.system.ram.words[10]!==32'h62814f6f || dut.system.ram.words[11]!==32'h79d8c8a1)
            $fatal(1,"FAIL recovery ciphertext");
    endtask
    initial begin
        boot();digit(10); // incomplete input must be discarded on overflow
        // Freeze an actual status read, then let two real scanner events fill
        // and overflow the one-entry mailbox. The event logic is not forced.
        force dut.keypad.ready=0;
        digit(1);digit(2);
        if(dut.keypad.events.overflow!==1) $fatal(1,"FAIL overflow stimulus");
        release dut.keypad.ready;
        wait(vdd===1);wait(vdd===0);wait(dut.oled.idle);tick(250);
        if(completed!=0 || halted || dut.system.ram.words[13]!==1 || dut.keypad.events.overflow)
            $fatal(1,"FAIL overflow recovery");
        zero_block();wait(completed==1);check_zero_result();
        if(halted || dut.system.ram.words[12]!==0) $fatal(1,"FAIL recovery error");

        // Exercise all six bounded status waits. Shorten only the remaining
        // register count after the real loop has loaded its production budget;
        // execute its normal decrement, branch, diagnostic store and halt.
        for(case_no=1;case_no<=6;case_no++) begin
            boot();
            fork
                begin
                    wait(dut.system.cpu.registers.regs[26]==case_no);
                    if(case_no==1) force dut.aes.rdata=0;
                    else if(case_no==3) force dut.uart.rdata=1;
                    else force dut.oled.rdata=0;
                    @(negedge clk);
                    dut.system.cpu.registers.regs[28]=3;
                end
                begin
                    if(case_no<=3) zero_block();
                    else begin
                        wait(dut.oled.idle);keys=16'h9000;
                        if(case_no==6) begin wait(vdd===1);keys=0;end
                    end
                end
            join
            wait(halted);tick(10);
            if(dut.system.ram.words[12]!==case_no || dut.system.fault_value!==32'h00100073 ||
               dut.system.cpu.registers.regs[28]!==0 || completed!=0)
                $fatal(1,"FAIL timeout path %0d code=%h count=%h",case_no,dut.system.ram.words[12],dut.system.cpu.registers.regs[28]);
            release dut.aes.rdata;release dut.uart.rdata;release dut.oled.rdata;
        end
        boot();zero_block();wait(completed==1);check_zero_result();
        if(halted) $fatal(1,"FAIL recovery after fault reset");
        $display("PASS tb_display_recovery: real mailbox overflow, discarded partial block, recovery ciphertext, six bounded status faults, diagnostic codes and reset recovery");$finish;
    end
    initial begin #15000000;$fatal(1,"FAIL recovery watchdog case=%0d",case_no);end
endmodule

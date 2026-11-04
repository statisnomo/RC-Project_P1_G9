`timescale 1ns/1ps
module display_repeat_case #(parameter WAITS=1)(output reg finished=0);
    reg clk=0,rst=1;always #5 clk=~clk;
    reg [15:0] keys=0;wire [3:0] rows,drive;
    wire tx,halted,block_event;
    reg [255:0] vectors[0:9];
    localparam [63:0] POS=64'hdefb73a98654210c;
    localparam DIV=8;
    integer trial=0,blocks=0,chars=0,starts=0,cycle=0,start_cycle=0;
    integer latency_min=1000000,latency_max=0;
    keypad_matrix_model matrix(keys,drive,rows);
    soc_display #(.COLUMN_CYCLES(6),.DEBOUNCE_FRAMES(2),.WAIT_CYCLES(WAITS),
        .CLKS_PER_BIT(DIV),.RESET_CYCLES(9),.PANEL_CYCLES(19),.DISCHARGE_CYCLES(37),.HALF_SPI(2))
        dut(.clk(clk),.rst(rst),.rows_n(rows),.col_drive_low(drive),.tx(tx),.halted(halted),.block_event(block_event));
    always @(posedge clk) if(!rst) begin
        cycle++;
        if(halted) $fatal(1,"FAIL repeat halt waits=%0d trial=%0d",WAITS,trial);
        if(block_event) blocks++;
        if(dut.aes.core_start) begin start_cycle=cycle;starts++;end
        // CPU-visible latency: accepted START store to last completed CT load.
        // Excludes key/plaintext writes, formatting, OLED and serial transfer.
        if(dut.v && !dut.w && dut.addr==32'h4000003c && dut.ready[0]) begin
            if(cycle-start_cycle<latency_min) latency_min=cycle-start_cycle;
            if(cycle-start_cycle>latency_max) latency_max=cycle-start_cycle;
        end
    end
    initial forever begin: serial
        reg [7:0] value,expected;reg [3:0] digit;
        @(negedge tx);if(!rst) begin
            repeat(DIV/2) @(posedge clk);
            if(tx!==0) $fatal(1,"FAIL repeat UART start");
            for(integer b=0;b<8;b++) begin repeat(DIV) @(posedge clk);value[b]=tx;end
            repeat(DIV) @(posedge clk);if(tx!==1) $fatal(1,"FAIL repeat UART stop");
            if(chars>=330) $fatal(1,"FAIL extra UART data");
            if(chars%33==32) expected=10;
            else begin digit=vectors[chars/33][127-4*(chars%33)-:4];expected=digit<10?48+digit:55+digit;end
            if(value!==expected) $fatal(1,"FAIL repeat UART index=%0d got=%h want=%h",chars,value,expected);
            chars++;
        end
    end
    initial begin
        $readmemh("display_lab_vectors.mem",vectors);
        for(integer j=0;j<10;j++) if(^vectors[j]===1'bx) $fatal(1,"FAIL missing display vectors");
        repeat(5) @(negedge clk);rst=0;repeat(250) @(negedge clk);
        for(trial=0;trial<10;trial++) begin
            for(integer i=0;i<32;i++) begin
                keys=16'h1<<POS[4*vectors[trial][255-i*4-:4]+:4];repeat(250) @(negedge clk);
                keys=0;repeat(200) @(negedge clk);
            end
            wait(blocks==trial+1 && chars==(trial+1)*33);wait(dut.oled.idle);
            for(integer w=0;w<4;w++) for(integer b=0;b<4;b++)
                if(dut.system.ram.words[8+w][8*b+:8]!==vectors[trial][127-8*(4*w+b)-:8])
                    $fatal(1,"FAIL repeat RAM waits=%0d trial=%0d",WAITS,trial);
            if(dut.oled.frame!=={dut.system.ram.words[11],dut.system.ram.words[10],dut.system.ram.words[9],dut.system.ram.words[8]})
                $fatal(1,"FAIL repeat display snapshot");
        end
        if(starts!=10 || dut.system.ram.words[12]!==0 || dut.system.ram.words[13]!==0) $fatal(1,"FAIL repeat counters");
        $display("REPEAT_CASE_PASS waits=%0d blocks=10 chars=330 CPU_START_TO_CT_READ_cycles=%0d..%0d",WAITS,latency_min,latency_max);
        finished=1;
    end
endmodule
module tb_display_repeat;
    wire a,b;
    display_repeat_case #(.WAITS(1)) normal(a);
    display_repeat_case #(.WAITS(5)) delayed(b);
    initial begin wait(a && b);
        $display("PASS tb_display_repeat: waits 1/5, 20 blocks from independent .NET AES vectors, 660 UART frames, RAM and OLED snapshots, CPU-visible cycle measurements");$finish;end
    initial begin #10000000;$fatal(1,"FAIL repeat watchdog");end
endmodule

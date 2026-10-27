`timescale 1ns / 1ps

module aes_mmio_checks #(parameter WAIT_CYCLES=1) (output reg finished=0);
    reg clk=0; always #5 clk=~clk;
    reg rst=1, valid=0, write=0;
    reg [31:0] addr=0,wdata=0;
    reg [3:0] wstrb=0;
    reg [1:0] size=2;
    wire ready,error,busy,done;
    wire [31:0] rdata;
    aes_mmio #(.WAIT_CYCLES(WAIT_CYCLES)) dut (.*);
    `include "aes_reference.vh"
    integer checks=0, transfers=0, starts=0, completions=0, cycle=0, launch_cycle=0;
    integer i,j,m,n,offset,before_starts;
    reg active=0;
    reg [31:0] got,expected_word,mask_value;
    reg [31:0] random_state=32'h1a5e0001;
    reg [127:0] key_value,pt_value,expected_ct;
    reg [383:0] vectors [0:283];
    localparam [127:0] KEY=128'h000102030405060708090a0b0c0d0e0f;
    localparam [127:0] PT=128'h00112233445566778899aabbccddeeff;
    localparam [127:0] CT=128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    function [31:0] word_le;
        input [127:0] value;
        input integer idx;
        integer b;
        begin for(b=0;b<4;b=b+1) word_le[8*b +: 8]=value[127-8*(4*idx+b) -: 8]; end
    endfunction
    task equal;
        input [127:0] actual,wanted;
        input [255:0] label_text;
        begin
            checks=checks+1;
            if(actual !== wanted) $fatal(1,"FAIL MMIO wait=%0d %0s time=%0t actual=%032h expected=%032h",WAIT_CYCLES,label_text,$time,actual,wanted);
        end
    endtask
    always @(posedge clk) begin
        cycle=cycle+1;
        if(rst) active=0;
        else begin
            if(valid && ready) transfers=transfers+1;
            if(dut.core_start) begin
                starts=starts+1; active=1; launch_cycle=cycle;
            end
        end
        #1;
        if(!rst && active && done) begin
            equal(cycle-launch_cycle,11,"accept-to-DONE latency");
            completions=completions+1; active=0;
        end
        if(!rst && busy && done) $fatal(1,"FAIL busy and done overlap");
    end
    task reset_dut;
        begin
            @(negedge clk); rst=1; valid=0;
            repeat(2) @(negedge clk);
            equal({ready,busy,done},0,"reset status");
            equal(dut.core_ct,0,"reset ciphertext");
            for(n=0;n<4;n=n+1) begin
                equal(dut.key_words[n],0,"reset key"); equal(dut.pt_words[n],0,"reset PT");
            end
            rst=0;
        end
    endtask
    task access_bus;
        input wr;
        input [31:0] address,data;
        input [3:0] strobes;
        input [1:0] width;
        input expect_error;
        output [31:0] reply;
        integer waited;
        reg [127:0] old_key,old_pt;
        begin
            @(negedge clk);
            valid=1;write=wr;addr=address;wdata=data;wstrb=strobes;size=width;
            old_key=dut.core_key; old_pt=dut.core_pt; waited=0;
            while(ready !== 1) begin
                @(negedge clk); waited=waited+1;
                equal(dut.core_key,old_key,"no key effect before completion");
                equal(dut.core_pt,old_pt,"no PT effect before completion");
                if(waited>WAIT_CYCLES+2) $fatal(1,"FAIL bus stuck");
            end
            equal(waited,WAIT_CYCLES,"wait edge count");
            equal(error,expect_error,"bus error");
            reply=rdata;
            @(posedge clk); #1;
            if(expect_error) begin
                equal(dut.core_key,old_key,"failed write preserves key");
                equal(dut.core_pt,old_pt,"failed write preserves PT");
                equal(reply,0,"failed access returns zero");
            end
            @(negedge clk);valid=0;
        end
    endtask
    task write_word;
        input [31:0] offset_value,data;
        begin access_bus(1,32'h40000000+offset_value,data,15,2,0,got); end
    endtask
    task read_word;
        input [31:0] offset_value,wanted;
        begin access_bus(0,32'h40000000+offset_value,0,0,2,0,got);equal(got,wanted,"register readback");end
    endtask
    task operands;
        input [127:0] k,p;
        begin
            for(m=0;m<4;m=m+1) begin
                write_word(16+4*m,word_le(k,m));write_word(32+4*m,word_le(p,m));
            end
        end
    endtask
    task result_block;
        input [127:0] wanted;
        integer polls;
        begin
            polls=0;
            while(done !== 1) begin
                access_bus(0,32'h40000004,0,0,2,0,got); polls=polls+1;
                if(polls>10) $fatal(1,"FAIL poll timeout");
            end
            read_word(4,2);
            for(m=0;m<4;m=m+1) read_word(48+4*m,word_le(wanted,m));
            read_word(4,2); // reads do not clear DONE
        end
    endtask

    initial begin
`ifdef VIVADO_GUI
        $readmemh("aes128_kat.mem",vectors);
`else
        $readmemh("tb/crypto/vectors/aes128_kat.mem",vectors);
`endif
        reset_dut;
        read_word(0,0);read_word(4,0);
        for(i=0;i<4;i=i+1) begin read_word(16+4*i,0);read_word(32+4*i,0);read_word(48+4*i,0);end
        // Every strobe pattern on every writable operand word.
        for(i=0;i<8;i=i+1) begin
            offset=(i<4)?16+4*i:32+4*(i-4); expected_word=0;
            for(j=0;j<16;j=j+1) begin
                random_state=next_random(random_state);
                mask_value=0;
                for(m=0;m<4;m=m+1) if((j>>m)&1) mask_value[8*m +: 8]=8'hff;
                access_bus(1,32'h40000000+offset,random_state,j,2,0,got);
                expected_word=(expected_word & ~mask_value)|(random_state & mask_value);
                read_word(offset,expected_word);
            end
        end
        // Little-endian byte and halfword accesses, including read lane addresses.
        write_word(16,0);
        for(i=0;i<4;i=i+1) access_bus(1,32'h40000010+i,(32'h11*(i+1))<<(8*i),1<<i,0,0,got);
        read_word(16,32'h44332211);
        for(i=0;i<4;i=i+1) begin
            access_bus(0,32'h40000010+i,0,0,0,0,got);equal(got,32'h44332211,"byte read containing word");
        end
        access_bus(1,32'h40000012,32'hbbaa0000,12,1,0,got);read_word(16,32'hbbaa2211);
        // Reserved window, read-only, alignment, size and lane violations.
        for(i=0;i<64;i=i+1) begin
            if(i!=0 && i!=1 && !(i>=4 && i<=15)) begin
                access_bus(0,32'h40000000+4*i,0,0,2,1,got);
                access_bus(1,32'h40000000+4*i,1,15,2,1,got);
            end
        end
        access_bus(0,32'h40000100,0,0,2,1,got);
        access_bus(1,32'h50000010,1,15,2,1,got);
        access_bus(1,32'h40000004,0,0,2,1,got);
        for(i=0;i<4;i=i+1) access_bus(1,32'h40000030+4*i,0,15,2,1,got);
        access_bus(0,32'h40000011,0,0,1,1,got);
        access_bus(1,32'h40000012,1,15,2,1,got);
        access_bus(0,32'h40000010,0,0,3,1,got);
        access_bus(1,32'h40000010,1,2,0,1,got);
        access_bus(0,32'h40000010,0,1,2,1,got);
        access_bus(1,32'h40000000,2,15,2,1,got);
        access_bus(1,32'h40000001,32'h100,2,0,1,got);
        before_starts=starts;
        access_bus(1,32'h40000000,32'hffffff01,0,2,0,got);
        access_bus(1,32'h40000001,1,2,0,0,got); // unstrobed bit 0 ignored
        equal(starts,before_starts,"no accidental START");

        operands(KEY,PT);write_word(0,1);
        access_bus(1,32'h40000000,1,15,2,1,got);
        access_bus(1,32'h40000010,0,15,2,1,got);
        result_block(CT);
        read_word(16,32'h03020100);
        write_word(0,1);
        access_bus(1,32'h40000020,0,15,2,1,got);
        access_bus(1,32'h40000020,0,0,2,0,got);
        result_block(CT);
        // Request capture can occur while BUSY, but the completion edge
        // decides acceptance. At DONE's edge BUSY is still one before
        // the edge (reject); one edge later it is zero (accept).
        for(i=0;i<2;i=i+1) begin
            operands(KEY,PT);write_word(0,1);
            while(cycle-launch_cycle < 10+i-WAIT_CYCLES) @(negedge clk);
            valid=1;write=1;addr=32'h40000010;wdata=32'h12345678;wstrb=15;size=2;
            equal(busy,1,"boundary request begins busy");
            while(ready!==1) @(negedge clk);
            if(i==0) equal(error,128'd1,"DONE-edge rejects busy write");
            else equal(error,128'd0,"next edge accepts idle write");
            @(posedge clk);#2;
            equal(cycle-launch_cycle,11+i,"boundary completion cycle");
            equal(dut.key_words[0],(i==0)?32'h03020100:32'h12345678,"boundary write effect");
            equal(done,1,"operand write preserves DONE");
            equal(dut.core_ct,CT,"in-flight key snapshot intact");
            @(negedge clk);valid=0;
            result_block(CT);
        end
        // All published answers through the actual register interface.
        for(i=0;i<284;i=i+1) begin
            if((^vectors[i])===1'bx) $fatal(1,"FAIL missing vector");
            operands(vectors[i][383:256],vectors[i][255:128]);
            write_word(0,1); result_block(vectors[i][127:0]);
        end
        // Consecutive transfers with VALID continuously high.
        @(negedge clk);valid=1;write=1;size=2;wstrb=15;addr=32'h40000010;wdata=32'h12345678;
        for(i=0;i<3;i=i+1) begin
            while(ready!==1) @(negedge clk);
            @(posedge clk); #1;
            equal(dut.key_words[i],32'h12345678+i,"continuous-valid write");
            @(negedge clk);addr=addr+4;wdata=wdata+1;
        end
        valid=0;
        // Cancellation before READY completion must not apply the pending write.
        reset_dut;
        @(negedge clk);valid=1;write=1;size=2;wstrb=15;addr=32'h40000010;wdata=1;
        @(negedge clk);valid=0;
        repeat(3) @(negedge clk);read_word(16,0);
        // Reset on the completion edge cancels START, and at every AES round.
        for(i=0;i<=11;i=i+1) begin
            operands(KEY,PT);
            if(i==0) begin
                @(negedge clk);valid=1;write=1;size=2;wstrb=15;addr=32'h40000000;wdata=1;
                while(ready!==1) @(negedge clk);
                rst=1;@(posedge clk);#1;equal(busy,0,"reset beats START");
            end else begin
                write_word(0,1);
                repeat(i-1) @(negedge clk);
                rst=1;@(posedge clk);#1;equal({busy,done},0,"reset abort stage");
            end
            reset_dut;repeat(13) @(negedge clk);equal(done,0,"no stale completion");
        end
        operands(KEY,PT);write_word(0,1);result_block(CT);
        $display("PASS aes_mmio_checks: wait=%0d, %0d checks, %0d transfers, %0d starts, %0d completions",WAIT_CYCLES,checks,transfers,starts,completions);
        finished=1;
    end
endmodule

module tb_aes_mmio;
    wire a,b;
    aes_mmio_checks #(.WAIT_CYCLES(1)) normal_bus(a);
    aes_mmio_checks #(.WAIT_CYCLES(3)) delayed_bus(b);
    initial begin wait(a && b); $display("PASS tb_aes_mmio: 1/3 wait edges, 284 NIST blocks per mode, byte strobes, access errors, busy writes, held requests, reset cancellation");$finish;end
    initial begin #2000000;$fatal(1,"FAIL AES MMIO watchdog");end
endmodule

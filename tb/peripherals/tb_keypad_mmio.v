`timescale 1ns / 1ps
module keypad_mmio_checks #(parameter integer WAIT=1, INTEGRATED=0)(output reg finished=0);
    reg clk=0;always #5 clk=~clk;
    reg rst=1,valid=0,write=0,press=0,key_down=0,blocked=0;
    reg [31:0] addr=0,wdata=0;
    reg [3:0] wstrb=0,key_position=0;
    reg [1:0] size=2;
    reg [15:0] keys=0;
    wire ready,error;
    wire [31:0] rdata;
    wire [3:0] rows_n,col_drive_low;
    integer checks=0,transfers=0,k,before_count;
    localparam [31:0] BASE=32'h40000100;
    generate if(INTEGRATED) begin:physical
        keypad_matrix_model matrix(.*);
        keypad_mmio #(.COLUMN_CYCLES(5),.DEBOUNCE_FRAMES(3),.WAIT_CYCLES(WAIT)) dut(.*);
    end else begin:mailbox
        keypad_event_mmio #(.WAIT_CYCLES(WAIT)) dut(.*);
    end endgenerate
    always @(posedge clk) if(!rst && valid && ready) transfers=transfers+1;
    task clocks(input integer n);repeat(n) @(negedge clk);endtask
    task event_pulse(input [3:0] position);
        begin @(negedge clk);press=1;key_position=position;@(negedge clk);press=0;end
    endtask
    task access_bus(input bit wr,input [31:0] address,data,input [3:0] lanes,
        input [1:0] access_size,input bit expected_error,input [31:0] expected,
        input bit simultaneous_press,input [3:0] new_position);
        integer waited;
        begin
            @(negedge clk);valid=1;write=wr;addr=address;wdata=data;wstrb=lanes;size=access_size;
            waited=0;
            while(!ready && waited<30) begin @(negedge clk);waited=waited+1;end
            if(!ready || waited!=WAIT || error!==expected_error ||
                ((!wr || expected_error) && rdata!==expected))
                $fatal(1,"FAIL keypad bus int=%0d wait=%0d addr=%h error=%b data=%h expected=%h waited=%0d",INTEGRATED,WAIT,address,error,rdata,expected,waited);
            press=simultaneous_press;key_position=new_position;
            @(negedge clk);valid=0;press=0;checks=checks+1;
        end
    endtask
    task rd(input integer offset,input [31:0] expected);
        access_bus(0,BASE+offset,0,0,2,0,expected,0,0);
    endtask
    task ctrl(input [31:0] data);
        access_bus(1,BASE+8,data,15,2,0,0,0,0);
    endtask
    initial begin
        clocks(3);rst=0;clocks(140);rd(0,0);rd(4,0);rd(8,0);
        if(INTEGRATED) begin
            // Full pin-driven scanner -> event storage -> bus, every position.
            for(k=0;k<16;k=k+1) begin
                keys=16'b1<<k;clocks(140);rd(0,3);rd(4,k);rd(4,k);
                ctrl(1);clocks(140);rd(0,2); // Held key must not requeue.
                keys=0;clocks(140);rd(0,0);
            end
            keys=1;clocks(140);keys=0;clocks(140);
            keys=2;clocks(140);rd(0,11);rd(4,0); // Second key lost, first retained.
            keys=0;clocks(140);ctrl(3);rd(0,0);
            keys=16'h0013;clocks(140);rd(0,4); // Ghosting chord rejected.
            keys=1;clocks(140);rd(0,4);
            keys=0;clocks(140);rd(0,0);
            keys=16'h8000;clocks(140);rst=1;clocks(3);rst=0;clocks(140);rd(0,0);
            keys=0;clocks(140);keys=16'h8000;clocks(140);rd(0,3);rd(4,15);
            keys=0;clocks(140);ctrl(1);rd(0,0);
        end else begin
            for(k=0;k<16;k=k+1) begin
                event_pulse(k);rd(0,1);rd(4,k);rd(4,k);ctrl(1);rd(0,0);
            end
            event_pulse(2);event_pulse(3);rd(0,9);rd(4,2);
            ctrl(2);rd(0,1);rd(4,2);
            // ACK and a new event on the same completion edge: keep new event.
            access_bus(1,BASE+8,1,15,2,0,0,1,9);rd(0,1);rd(4,9);
            // A fresh overflow wins over simultaneous clear, retaining old data.
            access_bus(1,BASE+8,2,15,2,0,0,1,10);rd(0,9);rd(4,9);
            access_bus(1,BASE+8,3,15,2,0,0,1,11);rd(0,1);rd(4,11);
            // Byte lanes and no-ops must not consume pending data.
            access_bus(1,BASE+8,1,0,2,0,0,0,0);rd(0,1);
            access_bus(1,BASE+9,0,2,0,0,0,0,0);rd(0,1);
            access_bus(1,BASE+8,4,1,0,1,0,0,0);rd(0,1);
            access_bus(1,BASE,0,0,2,1,0,0,0);
            access_bus(1,BASE+4,1,15,2,1,0,0,0);
            access_bus(0,BASE+12,0,0,2,1,0,0,0);
            access_bus(1,BASE+9,1,1,0,1,0,0,0);
            access_bus(1,BASE+9,1,15,2,1,0,0,0);
            access_bus(0,BASE+1,0,0,1,1,0,0,0);
            access_bus(0,BASE,0,0,3,1,0,0,0);
            access_bus(0,BASE,0,1,2,1,0,0,0);
            access_bus(1,32'h40000208,1,15,2,1,0,0,0);rd(0,1);
            access_bus(0,BASE+5,0,0,0,0,11,0,0); // Containing word read.
            // Cancel an ACK after READY rises but before the completion edge.
            @(negedge clk);valid=1;write=1;addr=BASE+8;wdata=1;wstrb=15;size=2;
            clocks(WAIT);valid=0;clocks(2);rd(0,1);rd(4,11);
            // Continuous VALID carries two reads without consuming the event.
            @(negedge clk);before_count=transfers;valid=1;write=0;addr=BASE+4;wstrb=0;
            while(transfers<before_count+2) begin
                @(negedge clk);
                if(ready && (error || rdata!==11)) $fatal(1,"FAIL continuous read");
            end
            valid=0;clocks(2);rd(0,1);
            key_down=1;blocked=1;rd(0,7);key_down=0;blocked=0;
            access_bus(1,BASE+8,1,1,0,0,0,0,0);rd(0,0);
            event_pulse(4);
            @(negedge clk);valid=1;write=1;addr=BASE+8;wdata=1;wstrb=15;size=2;
            clocks(WAIT);rst=1;press=1;key_position=7;clocks(2);
            valid=0;press=0;rst=0;clocks(2);rd(0,0);rd(4,0);
        end
        $display("PASS keypad_mmio_checks: integrated=%0d wait=%0d checks=%0d transfers=%0d",INTEGRATED,WAIT,checks,transfers);
        finished=1;
    end
endmodule
module tb_keypad_mmio;
    wire a,b,c,d;
    keypad_mmio_checks #(.WAIT(1)) fast(a);
    keypad_mmio_checks #(.WAIT(4)) delayed(b);
    keypad_mmio_checks #(.WAIT(1),.INTEGRATED(1)) pins_fast(c);
    keypad_mmio_checks #(.WAIT(4),.INTEGRATED(1)) pins_delayed(d);
    initial begin wait(a&&b&&c&&d);$display("PASS tb_keypad_mmio: mailbox and real scanner, waits 1/4, 16 positions, ACK/event races, overflow, invalid/cancelled accesses and reset");$finish;end
    initial begin #5000000;$fatal(1,"FAIL keypad MMIO watchdog");end
endmodule

`timescale 1ns/1ps
// Exercise the actual SoC decoder/mux with CPU execution isolated. Unit benches
// cover each peripheral; this catches cross-window response and side effects.
module display_bus_case #(parameter WAITS=1)(output reg finished=0);
    reg clk=0,rst=1;always #5 clk=~clk;
    reg valid=0,wr=0;reg [31:0] addr=0,data=0;reg [3:0] lanes=0;reg [1:0] size=2;
    wire halted;integer checks=0;
    soc_display #(.WAIT_CYCLES(WAITS),.RESET_CYCLES(9),.PANEL_CYCLES(19),
        .DISCHARGE_CYCLES(37),.HALF_SPI(3)) dut(.clk(clk),.rst(rst),.rows_n(4'hf),.halted(halted));
    task access_bus(input bit write_req,input [31:0] address,value,input [3:0] strobes,
        input bit bad,input [31:0] expected,input bit check_data);
        integer clocks;
        @(negedge clk);valid=1;wr=write_req;addr=address;data=value;lanes=strobes;clocks=0;
        #1; // allow combinational address selection to settle before READY
        while(dut.system.dr!==1) begin
            @(negedge clk);clocks++;
            if(clocks>20) $fatal(1,"FAIL routing watchdog %h",address);
        end
        if(dut.system.de!==bad || (!write_req && !bad && check_data && dut.system.rd!==expected))
            $fatal(1,"FAIL routing waits=%0d addr=%h err=%b data=%h",WAITS,address,dut.system.de,dut.system.rd);
        @(negedge clk);valid=0;checks++;
    endtask
    initial begin
        force dut.system.cpu.halted=1;
        force dut.system.dv=valid;force dut.system.dw=wr;force dut.system.da=addr;
        force dut.system.wd=data;force dut.system.ws=lanes;force dut.system.size=size;
        repeat(5) @(negedge clk);rst=0;
        access_bus(1,32'h40000010,32'h12345678,15,0,0,0);
        access_bus(1,32'h40000210,32'h89abcdef,15,0,0,0);
        access_bus(0,32'h40000010,0,0,0,32'h12345678,1);
        access_bus(0,32'h40000210,0,0,0,32'h89abcdef,1);
        access_bus(0,32'h40000100,0,0,0,0,1);
        access_bus(0,32'h40000304,0,0,0,2,1);
        // Last aligned word in each 256-byte window must reach that slave's
        // invalid-register response, rather than aliasing its low registers.
        for(integer p=0;p<4;p++) begin
            access_bus(0,32'h400000fc+(p<<8),0,0,1,0,0);
            access_bus(1,32'h400000fc+(p<<8),32'hffffffff,15,1,0,0);
        end
        access_bus(0,32'h3ffffffc,0,0,1,0,0);
        access_bus(0,32'h40000400,0,0,1,0,0);
        access_bus(0,32'h40010010,0,0,1,0,0);
        access_bus(1,32'h40000210,0,3,1,0,0); // OLED requires whole words
        access_bus(1,32'h40000010,32'h000000aa,1,0,0,0); // AES permits byte lanes
        access_bus(0,32'h40000010,0,0,0,32'h123456aa,1);
        access_bus(0,32'h40000210,0,0,0,32'h89abcdef,1);
        // Cancel a captured OLED write with reset before its completion edge.
        @(negedge clk);valid=1;wr=1;addr=32'h40000210;data=32'hdeadbeef;lanes=15;
        @(negedge clk);rst=1;valid=0;
        repeat(3) @(negedge clk);rst=0;
        access_bus(0,32'h40000210,0,0,0,0,1);
        if(dut.oled.staging!==0 || dut.aes.key_words[0]!==0) $fatal(1,"FAIL reset isolation");
        $display("BUS_CASE_PASS waits=%0d checks=%0d",WAITS,checks);finished=1;
    end
endmodule
module tb_display_bus;
    wire a,b;
    display_bus_case #(.WAITS(1)) normal(a);
    display_bus_case #(.WAITS(5)) delayed(b);
    initial begin wait(a && b);
        $display("PASS tb_display_bus: waits 1/5, 44 routed accesses, four windows, boundaries, invalid addresses, byte strobes and reset cancellation");$finish;end
    initial begin #50000;$fatal(1,"FAIL routing timeout");end
endmodule

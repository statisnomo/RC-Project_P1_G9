`timescale 1ns / 1ps
module tb_memories #(
`ifdef VIVADO_GUI
    parameter ROM_FILE = "cpu_smoke.hex"
`else
    parameter ROM_FILE = "../../fw/cpu_smoke.hex"
`endif
);
    reg clk=0,rst=1,valid=0,write=0,iv=0;
    always #5 clk=~clk;
    reg [31:0] addr=0,wdata=0,ia=0;
    reg [3:0] strobe=0;
    wire ready,error,ir,ie;
    wire [31:0] rdata,idata;
    integer checks=0,k;
    data_ram ram(.clk(clk),.rst(rst),.valid(valid),.write(write),.addr(addr),
                 .wdata(wdata),.wstrb(strobe),.ready(ready),.rdata(rdata),.error(error));
    instr_rom #(.INIT_FILE(ROM_FILE)) rom(.clk(clk),.rst(rst),.valid(iv),.addr(ia),
                                                          .ready(ir),.rdata(idata),.error(ie));
    task access_ram;
        input wr;
        input [31:0] address,data;
        input [3:0] lanes;
        input err;
        input [31:0] expected;
        begin
            @(negedge clk); valid=1;write=wr;addr=address;wdata=data;strobe=lanes;
            if(ready) $fatal(1,"FAIL RAM acknowledged before synchronous read");
            @(negedge clk);
            if(!ready || error !== err || (!wr && !err && rdata !== expected))
                $fatal(1,"FAIL RAM address=%h read=%h expected=%h error=%b",address,rdata,expected,error);
            @(negedge clk); valid=0;
            checks=checks+1;
        end
    endtask
    task access_rom;
        input [31:0] address,expected;
        input err;
        begin
            @(negedge clk);iv=1;ia=address;
            if(ir) $fatal(1,"FAIL ROM early acknowledgement");
            @(negedge clk);
            if(!ir || ie !== err || (!err && idata !== expected)) $fatal(1,"FAIL ROM %h",address);
            @(negedge clk);iv=0;checks=checks+1;
        end
    endtask
    initial begin
        repeat(3) @(negedge clk); rst=0;
        access_rom(0,32'h000010b7,0);
        access_rom(4092,0,0);
        access_rom(4096,0,1);
        access_rom(2,0,1);
        access_ram(1,'h1000,'h12345678,15,0,0);
        access_ram(0,'h1000,0,0,0,'h12345678);
        access_ram(1,'h1000,'haabbccdd,1,0,0);
        access_ram(0,'h1000,0,0,0,'h123456dd);
        access_ram(1,'h1001,'haabbccdd,2,0,0);
        access_ram(0,'h1000,0,0,0,'h1234ccdd);
        access_ram(1,'h1002,'haabbccdd,4,0,0);
        access_ram(0,'h1000,0,0,0,'h12bbccdd);
        access_ram(1,'h1003,'haabbccdd,8,0,0);
        access_ram(0,'h1000,0,0,0,'haabbccdd);
        access_ram(1,'h1000,0,0,0,0);
        access_ram(0,'h1000,0,0,0,'haabbccdd);
        access_ram(1,'h1ffc,'hdeadbeef,15,0,0);
        access_ram(0,'h1ffc,0,0,0,'hdeadbeef);
        access_ram(1,'h2000,0,15,1,0);
        access_ram(0,'h1000,0,0,0,'haabbccdd);
        access_ram(0,0,0,0,1,0);
        // Reset between request capture and completion cancels the write.
        @(negedge clk);valid=1;write=1;addr='h1000;wdata=0;strobe=15;
        @(negedge clk);rst=1;
        @(negedge clk);valid=0;
        @(negedge clk);rst=0;
        access_ram(0,'h1000,0,0,0,'haabbccdd);
        // Back-to-back requests may keep valid high; each ready edge writes once.
        @(negedge clk);valid=1;write=1;addr='h1004;wdata=11;strobe=15;
        repeat(2) @(negedge clk);
        addr='h1008;wdata=22;
        repeat(2) @(negedge clk);
        valid=0;
        access_ram(0,'h1004,0,0,0,11);
        access_ram(0,'h1008,0,0,0,22);
        $display("PASS tb_memories: %0d checks, byte lanes, boundaries, errors, reset cancellation, back-to-back requests",checks);
        $finish;
    end
    initial begin #100000; $fatal(1,"FAIL memory watchdog"); end
endmodule

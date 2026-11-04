`timescale 1ns/1ps
module tb_display_system;
    reg clk=0,rst=1; always #5 clk=~clk;
    wire [3:0] rows,drive; reg [15:0] keys=0;
    wire cs,sd,sck,dc,res,vbat,vdd,tx,halted;
    localparam DIV=8;
    keypad_matrix_model matrix(keys,drive,rows);
    soc_display #(.COLUMN_CYCLES(6),.DEBOUNCE_FRAMES(2),.WAIT_CYCLES(4),
        .CLKS_PER_BIT(DIV),.RESET_CYCLES(9),.PANEL_CYCLES(19),.DISCHARGE_CYCLES(37),.HALF_SPI(3))
        dut(.clk(clk),.rst(rst),.rows_n(rows),.col_drive_low(drive),.cs_n(cs),.mosi(sd),
            .sclk(sck),.dc(dc),.res_n(res),.vbat_n(vbat),.vdd_n(vdd),.tx(tx),.halted(halted));
    localparam [127:0] CT0=128'h69c4e0d86a7b0430d8cdb78070b4c55a,CT1=128'hc6a13b37878f5b826f4f8162a1c8d879;
    localparam [175:0] INIT=176'hae8d14d9f1a81fda02a1c8813fa6200021007f220003;
    // Row-based 5x7 pixel reference; independent of the hardware column ROM.
    function automatic [55:0] glyph_rows(input [3:0] n);
        case(n)
        0:return 56'h0e11131519110e; 1:return 56'h040c040404040e;
        2:return 56'h0e11010204081f; 3:return 56'h1f02040201110e;
        4:return 56'h02060a121f0202; 5:return 56'h1f101e0101110e;
        6:return 56'h0608101e11110e; 7:return 56'h1f010204080808;
        8:return 56'h0e11110e11110e; 9:return 56'h0e11110f01020c;
        10:return 56'h0e11111f111111; 11:return 56'h1e11111e11111e;
        12:return 56'h0e11101010110e; 13:return 56'h1c12111111121c;
        14:return 56'h1f10101e10101f; default:return 56'h1f10101e101010;
        endcase
    endfunction
    integer packets=0,bits=0,chars=0,acks=0,swaps=0,overlap=0;
    reg [7:0] octet;
    always @(posedge sck) if(!rst) begin
        if(cs!==0 || res!==1 || vdd!==0) $fatal(1,"FAIL invalid SPI transfer");
        octet={octet[6:0],sd};bits++;
    end
    always @(posedge cs) if(!rst && bits!=0) begin: receive
        integer offset,page,x,k;
        reg [127:0] ct;
        reg [55:0] glyph;
        reg [7:0] expected;
        if(bits!=8) $fatal(1,"FAIL byte length");
        if(packets==1559) expected=8'hae;
        else if(packets>=1560 && packets<1582) expected=INIT[175-8*(packets-1560)-:8];
        else if(packets>=1582 && packets<2094) expected=0;
        else if(packets==2094) expected=8'haf;
        else if(packets<22) expected=INIT[175-8*packets-:8];
        else if(packets<534) expected=0;
        else if(packets==534) expected=8'haf;
        else begin
            if(vbat!==0 || packets>=1559) $fatal(1,"FAIL unexpected OLED data");
            offset=(packets-535)%512;page=offset/128;x=offset%128;expected=0;
            ct=packets<1047?CT0:CT1;
            if((page==1 || page==2) && x%8<5) begin
                k=(page-1)*16+x/8;
                glyph=glyph_rows(ct[127-k*4-:4]);
                for(int row=0;row<7;row++) expected[row]=glyph[8*(6-row)+4-x%8];
            end
        end
        if(octet!==expected || dc!==((packets>=22 && packets<534) ||
           (packets>=535 && packets<1559) || (packets>=1582 && packets<2094)))
            $fatal(1,"FAIL OLED byte %d got %h expected %h dc %b",packets,octet,expected,dc);
        bits=0;packets++;
    end
    initial forever begin: recv_uart
        reg [7:0] value,expect_char; reg [127:0] ct; reg [3:0] n;
        @(negedge tx); if(!rst) begin
            repeat(DIV/2) @(posedge clk);
            if(tx!==0) $fatal(1,"FAIL UART start");
            for(int i=0;i<8;i++) begin repeat(DIV) @(posedge clk);value[i]=tx;end
            repeat(DIV) @(posedge clk);if(tx!==1) $fatal(1,"FAIL UART stop");
            ct=chars<33?CT0:CT1;
            if(chars%33==32) expect_char=10;
            else begin n=ct[127-4*(chars%33)-:4];expect_char=n<10?48+n:55+n;end
            if(chars>=66 || value!==expect_char) $fatal(1,"FAIL UART char %d: %h != %h",chars,value,expect_char);
            chars++;
        end
    end
    always @(posedge clk) if(!rst) begin
        if(halted) $fatal(1,"FAIL processor halted PC %h",dut.system.fault_pc);
        if(dut.v && dut.w && dut.ready[dut.portnum]) begin
            if(dut.addr==32'h40000108) acks++;
            if(dut.addr==32'h40000204) swaps++;
            if(dut.addr==32'h40000210 && packets>535 && packets<1047) overlap++;
        end
    end
    localparam [63:0] POS=64'hdefb73a98654210c;
    task automatic digit(input [3:0] n);
        keys=16'h1<<POS[4*n+:4];repeat(180) @(negedge clk);
        keys=0;repeat(150) @(negedge clk);
    endtask
    localparam [127:0] P=128'h00112233445566778899aabbccddeeff;
    initial begin
        repeat(5) @(negedge clk);rst=0;repeat(160) @(negedge clk);
        for(int i=0;i<31;i++) digit(P[127-i*4-:4]);
        if(acks!=31 || swaps!=0 || chars!=0) $fatal(1,"FAIL partial input");
        digit(15);wait(chars==33);
        for(int i=0;i<32;i++) digit(0);
        wait(packets==1559 && chars==66);repeat(250) @(negedge clk);
        if(acks!=64 || swaps!=2 || overlap!=1) $fatal(1,"FAIL submission counts %d %d %d",acks,swaps,overlap);
        keys=16'h9000; // Printed 0 + D, on the bottom row.
        wait(vdd===1);repeat(150) @(negedge clk);
        if(packets!=1560 || vbat!==1 || chars!=66) $fatal(1,"FAIL shutdown hold");
        keys=0;wait(packets==2095);wait(dut.oled.idle);repeat(250) @(negedge clk);
        if(dut.system.cpu.halted || swaps!=4 || acks!=65) $fatal(1,"FAIL restart");
        $display("PASS tb_display_system: 64 digits, 2 AES ciphertexts, 1024 pixel bytes, 66 UART characters, overlap, partial input, chord shutdown and release restart");$finish;
    end
    initial begin #2500000;$fatal(1,"FAIL watchdog packets=%d chars=%d",packets,chars);end
endmodule

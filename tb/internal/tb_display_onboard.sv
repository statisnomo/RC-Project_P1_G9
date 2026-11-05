`timescale 1ns/1ps
// Onboard panel model: consumes every eight SCLK rising edges, WITHOUT CS.
// A CS-framed monitor would miss stray clocks when the physical panel is selected.
module tb_display_onboard;
    reg clk=0;always #5 clk=~clk;
    reg [15:0] keys=0;
    wire [3:0] rows,cols,low;
    wire sd,sck,dc,res,vbat,vdd,tx;wire [7:0] led;
    for(genvar i=0;i<4;i++) assign low[i]=(cols[i]===1'b0);
    keypad_matrix_model model(keys,low,rows);
    zedboard_display_onboard #(.COLUMN_CYCLES(6),.DEBOUNCE_FRAMES(2),
        .RESET_CYCLES(9),.PANEL_CYCLES(19),.HALF_SPI(3)) dut(
        .clk_100mhz(clk),.rows_n(rows),.cols_n(cols),.mosi(sd),.sclk(sck),
        .dc(dc),.res_n(res),.vbat_n(vbat),.vdd_n(vdd),.tx(tx),.led(led));
    // Test-only acceleration of the 3.5-second discharge; production stays unchanged.
    defparam dut.demo.soc.DISCHARGE_CYCLES=37;
    localparam DIV=868;
    localparam [175:0] INIT=176'hae8d14d9f1a81fda02a1c8813fa6200021007f220003;
    localparam [127:0] CT0=128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    localparam [127:0] CT1=128'hc6a13b37878f5b826f4f8162a1c8d879;
    // Independent row-based glyphs (RTL uses a column ROM).
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
    integer bytes=0,bits=0,chars=0,cycles=0,last_rise=0,panel_off_edge=0;
    reg [7:0] octet=0;reg byte_dc;
    always @(posedge clk) cycles++;
    always @(posedge sck) begin: decode
        integer p,offset,page,x,k;reg [7:0] expected;reg expected_dc;
        reg [127:0] ct;reg [55:0] glyph;
        if(dut.demo.rst || res!==1 || vdd!==0 || cycles-last_rise<6)
            $fatal(1,"FAIL onboard clock/power/reset");
        last_rise=cycles;
        if(bits==0) byte_dc=dc;
        if(dc!==byte_dc || (sd!==0 && sd!==1)) $fatal(1,"FAIL onboard byte integrity");
        octet={octet[6:0],sd};bits++;
        if(bits==8) begin
            expected=0;expected_dc=0;
            p=bytes>=1048 ? bytes-1048 : bytes;
            if(bytes==1047) expected=8'hae;
            else if(p<22) expected=INIT[175-8*p-:8];
            else if(p<534) expected_dc=1;
            else if(p==534) expected=8'haf;
            else begin
                if(p>=1047 || vbat!==0) $fatal(1,"FAIL extra onboard pixels");
                offset=p-535;page=offset/128;x=offset%128;expected_dc=1;
                ct=bytes<1047?CT0:CT1;
                if((page==1 || page==2) && x%8<5) begin
                    k=(page-1)*16+x/8;glyph=glyph_rows(ct[127-4*k-:4]);
                    for(integer r=0;r<7;r++) expected[r]=glyph[8*(6-r)+4-x%8];
                end
            end
            if(octet!==expected || dc!==expected_dc)
                $fatal(1,"FAIL onboard byte=%0d got=%h want=%h dc=%b",bytes,octet,expected,dc);
            bits=0;bytes++;
        end
    end
    always @(posedge vbat) if(!dut.demo.rst && cycles>30) begin
        if(bytes!=1048 || vdd!==0) $fatal(1,"FAIL onboard shutdown order");
        panel_off_edge=cycles;
    end
    always @(posedge vdd) if(!dut.demo.rst && cycles>30)
        if(cycles-panel_off_edge<37 || bits!=0) $fatal(1,"FAIL onboard discharge");
    always @(negedge clk) if(!dut.demo.rst) begin
        if(led[7]!==0 || !$onehot(low)) $fatal(1,"FAIL onboard CPU/keypad");
        for(integer c=0;c<4;c++) if(!low[c] && cols[c]!==1'bz) $fatal(1,"FAIL onboard pad drive");
    end
    initial forever begin: serial
        reg [7:0] value,expected;reg [3:0] n;reg [127:0] ct;
        @(negedge tx);if(!dut.demo.rst) begin
            repeat(DIV/2) @(posedge clk);if(tx!==0) $fatal(1,"FAIL onboard UART start");
            for(integer b=0;b<8;b++) begin repeat(DIV) @(posedge clk);value[b]=tx;end
            repeat(DIV) @(posedge clk);if(tx!==1) $fatal(1,"FAIL onboard UART stop");
            if(chars>=66) $fatal(1,"FAIL extra onboard UART");
            ct=chars<33?CT0:CT1;
            if(chars%33==32) expected=10;
            else begin n=ct[127-4*(chars%33)-:4];expected=n<10?48+n:55+n;end
            if(value!==expected) $fatal(1,"FAIL onboard UART char=%0d",chars);
            chars++;
        end
    end
    localparam [63:0] POS=64'hdefb73a98654210c;
    localparam [127:0] P=128'h00112233445566778899aabbccddeeff;
    task digit(input [3:0] n);
        keys=16'h1<<POS[4*n+:4];repeat(250) @(negedge clk);
        keys=0;repeat(200) @(negedge clk);
    endtask
    initial begin
        repeat(300) @(negedge clk);
        for(integer i=0;i<32;i++) digit(P[127-4*i-:4]);
        wait(chars==33 && bytes==1047);repeat(200) @(negedge clk);
        if(led[5]!==1 || led[3:0]!==15) $fatal(1,"FAIL onboard first-block LEDs");
        keys=16'h9000;wait(vdd===1);repeat(200) @(negedge clk);
        if(led[5:0]!==6'b000010) $fatal(1,"FAIL onboard off LEDs");
        keys=16'h1000;repeat(200) @(negedge clk);
        if(vdd!==1 || bytes!=1048) $fatal(1,"FAIL restart with one key held");
        keys=0;wait(dut.demo.soc.oled.idle);repeat(250) @(negedge clk);
        if(bytes!=1583) $fatal(1,"FAIL onboard clear after restart");
        for(integer i=0;i<32;i++) digit(0);
        wait(chars==66 && bytes==2095);repeat(200) @(negedge clk);
        if(bits!=0 || led[5]!==0 || dut.demo.soc.system.ram.words[12]!==0)
            $fatal(1,"FAIL onboard completion");
        $display("PASS tb_display_onboard: CS tied low, 2095 SPI bytes, two exact ciphertext frames, 66 UART frames at divider 868, power sequencing, partial chord release and restart");$finish;
    end
    initial begin #12000000;$fatal(1,"FAIL onboard timeout bytes=%0d chars=%0d",bytes,chars);end
endmodule

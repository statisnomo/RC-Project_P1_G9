`timescale 1ns/1ps
module tb_oled_pattern;
    reg clk=0; always #5 clk=~clk;
    wire cs,sd,sck,dc,res,vbat,vdd;
    wire [7:0] led;
    zedboard_oled_pattern #(.RESET_CYCLES(1100),.PANEL_CYCLES(2000),.VIEW_CYCLES(3000),
        .DISCHARGE_CYCLES(2200),.HALF_SPI(5)) dut(clk,cs,sd,sck,dc,res,vbat,vdd,led);
    localparam [175:0] init_cmds=176'hae8d14d9f1a81fda02a1c8813fa6200021007f220003;
    integer frames=0,bits=0,data_index,power_edge,clock_count=0,reset_start;
    reg [7:0] octet,expected;
    always @(posedge clk) clock_count++;
    always @(negedge res) reset_start=clock_count;
    always @(posedge res) if(vdd===0 && clock_count-reset_start<1100) $fatal(1,"FAIL reset pulse");
    always @(negedge vbat) begin
        if(frames!=534 || vdd!==0) $fatal(1,"FAIL panel power before full clear");power_edge=clock_count;
    end
    always @(posedge vbat) if(clock_count>2) begin
        if(frames!=1048) $fatal(1,"FAIL panel shutdown order");power_edge=clock_count;
    end
    always @(posedge cs) if(bits!=0) begin
        if(bits!=8) $fatal(1,"FAIL SPI byte length");
        if(frames<22) expected=init_cmds[175-8*frames-:8];
        else if(frames<534) expected=0;
        else if(frames==534) begin
            expected=8'haf;
            if(vbat!==0 || clock_count-power_edge<2000) $fatal(1,"FAIL panel settle");
        end else if(frames==1047) expected=8'hae;
        else begin
            data_index=frames-535;
            expected=((data_index/8)%2)^((data_index/128)%2)?255:0;
        end
        if(octet!==expected || dc!==((frames>=22 && frames<534)||(frames>=535 && frames<1047)))
            $fatal(1,"FAIL OLED transaction %d value=%h dc=%b",frames,octet,dc);
        frames++;bits=0;
    end
    always @(posedge sck) begin
        if(cs!==0 || res!==1 || vdd!==0) $fatal(1,"FAIL SPI while inactive");
        octet={octet[6:0],sd};bits++;
    end
    integer shown=0;
    always @(posedge clk) if(led[0]) shown++;
    initial begin
        wait(led[1]===1'b1); #1;
        if(frames!=1048 || shown!=3000 || vbat!==1 || vdd!==1 || clock_count-power_edge<2200)
            $fatal(1,"FAIL OLED final status");
        $display("PASS tb_oled_pattern: 1048 SPI bytes, full clear, checkerboard, power-up and timed shutdown");$finish;
    end
    initial begin #2000000; $fatal(1,"FAIL OLED timeout");end
endmodule

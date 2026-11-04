`timescale 1ns/1ps
module tb_display_board;
    reg clk=0;always #5 clk=~clk;
    reg [15:0] keys=1;
    wire [3:0] rows,cols,low;
    wire [7:0] led;
    wire cs,sd,sck,dc,res,vbat,vdd,tx;
    for(genvar i=0;i<4;i++) assign low[i]=(cols[i]===1'b0);
    keypad_matrix_model model(keys,low,rows);
    zedboard_display #(.COLUMN_CYCLES(6),.DEBOUNCE_FRAMES(2),.RESET_CYCLES(9),.PANEL_CYCLES(19),.HALF_SPI(3))
        dut(clk,rows,cols,cs,sd,sck,dc,res,vbat,vdd,tx,led);
    always @(negedge clk) if(!dut.rst) begin
        if(led[7]!==0 || !$onehot(low)) $fatal(1,"FAIL board CPU/pads");
        for(int i=0;i<4;i++) if(!low[i] && cols[i]!==1'bz) $fatal(1,"FAIL inactive pad");
    end
    task tick(input integer n);repeat(n) @(negedge clk);endtask
    initial begin
        tick(300);if(led[4:0]!==0) $fatal(1,"FAIL held at boot");
        keys=0;tick(150);keys=1;tick(200);
        if(led[4:0]!==5'h11) $fatal(1,"FAIL key 1 LED event");
        tick(500);if(led[4:0]!==5'h11) $fatal(1,"FAIL hold repeated");
        keys=0;tick(150);keys=8;tick(200);
        if(led[4:0]!==5'h0a || led[5]!==0) $fatal(1,"FAIL key A / incomplete block");
        $display("PASS tb_display_board: startup reset, physical pad drive, CPU digit LEDs and hold suppression");$finish;
    end
    initial begin #100000;$fatal(1,"FAIL board watchdog");end
endmodule

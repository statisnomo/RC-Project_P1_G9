`timescale 1ns/1ps
module tb_keypad_aes;
    reg clk=0; always #5 clk=~clk;
    wire [3:0] cols,rows;
    wire [7:0] led;
    reg [15:0] keys=0;
    // Sense the top-level pads; unknown or actively driven high is an error.
    wire [3:0] low;
    for(genvar i=0;i<4;i=i+1) assign low[i]=(cols[i]===1'b0);
    keypad_matrix_model matrix(keys,low,rows);
    zedboard_keypad_aes #(.COLUMN_CYCLES(8),.DEBOUNCE_FRAMES(3),.WAIT_CYCLES(4))
        dut(.clk_100mhz(clk),.rows_n(rows),.cols_n(cols),.led(led));
    integer events=0,blocks=0,acks=0,starts=0;
    always @(negedge clk) if(!dut.rst) begin
        if(led[7]!==0) $fatal(1,"FAIL CPU halted (check keypad_aes.hex), PC=%h",dut.system.fault_pc);
        if(!$onehot(low)) $fatal(1,"FAIL column drive");
        for(integer c=0;c<4;c=c+1) if(!low[c] && cols[c]!==1'bz) $fatal(1,"FAIL inactive column");
        if(dut.tv && dut.we && dut.rd==12) events++;
        if(dut.tv && dut.we && dut.rd==31) blocks++;
        if(dut.v && dut.w && dut.addr==32'h40000108 && dut.kr) acks++;
        if(dut.v && dut.w && dut.addr==32'h40000000 && dut.ar) starts++;
    end
    task ticks(input integer n); repeat(n) @(negedge clk); endtask
    // Physical switch position indexed by its printed hex label (0 through F).
    localparam [63:0] POS=64'hdefb73a98654210c;
    task tap(input [3:0] digit);
        reg prev;
        begin
            prev=led[4];
            keys=16'h1 << POS[4*digit+:4]; ticks(480);
            if(led[4]!==~prev || led[3:0]!==digit) $fatal(1,"FAIL printed key %h LED=%h",digit,led);
            keys=0; ticks(180);
        end
    endtask
    task test_block(input [127:0] p,input [127:0] ct,input integer n);
        reg [7:0] got;
        begin
            for(integer j=0;j<32;j=j+1) tap(p[127-4*j-:4]);
            ticks(300);
            if(events!=32*n || acks!=32*n || starts!=n || blocks!=n || led[5]!==n[0])
                $fatal(1,"FAIL counts %d %d %d %d",events,acks,starts,blocks);
            for(integer j=0;j<16;j=j+1) begin
                got=dut.system.ram.words[8+j/4][8*(j%4)+:8];
                if(got!==ct[127-8*j-:8]) $fatal(1,"FAIL ciphertext block %d byte %d got %h",n,j,got);
            end
        end
    endtask
    initial begin
        keys=1; ticks(450); keys=0; ticks(200);
        keys=16'h0033; ticks(350); keys=1; ticks(240); keys=0; ticks(200);
        if(events!=0 || acks!=0) $fatal(1,"FAIL startup/chord event");
        test_block(128'h00112233445566778899aabbccddeeff,128'h69c4e0d86a7b0430d8cdb78070b4c55a,1);
        test_block(0,128'hc6a13b37878f5b826f4f8162a1c8d879,2);
        $display("PASS tb_keypad_aes: 64 printed digits, 64 ACKs, 2 ciphertexts in RAM, open-drain columns and chord rejection"); $finish;
    end
endmodule

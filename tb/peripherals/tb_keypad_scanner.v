`timescale 1ns / 1ps
module keypad_scanner_checks #(
    parameter integer COL=8, DB=3
) (output reg finished=0);
    reg clk=0; always #5 clk=~clk;
    reg rst=1;
    reg [15:0] keys=0;
    wire [3:0] rows_n, col_drive_low, key_position;
    wire press, release_event, key_down, blocked, scan_valid;
    wire [15:0] scan_keys;
    integer presses=0, releases=0, k, phase, previous_p, previous_r;
    reg last_press=0, last_release=0;
    reg [3:0] last_key=0;
    keypad_matrix_model matrix(.*);
    keypad_scanner #(.COLUMN_CYCLES(COL),.DEBOUNCE_FRAMES(DB)) dut(.*);
    always @(posedge clk) begin
        #1;
        if (rst) begin last_press=0; last_release=0; end
        else begin
            if (col_drive_low !== 1 && col_drive_low !== 2 &&
                col_drive_low !== 4 && col_drive_low !== 8)
                $fatal(1,"FAIL keypad column selection");
            if ((press && last_press) || (release_event && last_release) ||
                (press && release_event)) $fatal(1,"FAIL keypad pulse width");
            if (press) begin
                if (!key_down || blocked) $fatal(1,"FAIL invalid press state");
                presses=presses+1; last_key=key_position;
            end
            if (release_event) begin
                if (key_down) $fatal(1,"FAIL invalid release state");
                releases=releases+1;
            end
            last_press=press; last_release=release_event;
        end
    end
    task clocks(input integer count);
        repeat(count) @(negedge clk);
    endtask
    task settle;
        clocks(4*COL*(DB+3));
    endtask
    task set_keys(input [15:0] value);
        begin @(negedge clk); keys=value; end
    endtask
    task reset_now;
        begin
            @(negedge clk);rst=1;clocks(3);
            if (key_down || blocked || press || release_event || col_drive_low!==0)
                $fatal(1,"FAIL keypad reset");
            rst=0;
        end
    endtask
    // Count public completed scans, not the DUT's internal debounce counter.
    task exact_threshold(input [15:0] value, input bit is_press);
        integer matching;
        begin
            matching=0;set_keys(value);
            while(matching<DB) begin
                @(negedge clk);
                if(scan_valid) begin
                    if(scan_keys===value) matching=matching+1;
                    else matching=0;
                    if(matching<DB && (press || release_event))
                        $fatal(1,"FAIL debounce accepted before threshold");
                    if(matching==DB && (is_press ? !press : !release_event))
                        $fatal(1,"FAIL debounce missed exact threshold DB=%0d",DB);
                end
            end
        end
    endtask
    initial begin
        clocks(3);rst=0;settle;
        if (presses || releases || key_down) $fatal(1,"FAIL idle keypad");
        exact_threshold(16'h0001,1);settle;
        exact_threshold(0,0);settle;
        // Every physical position, long hold, stable release, then repeat.
        for (k=0;k<16;k=k+1) begin
            previous_p=presses;previous_r=releases;
            set_keys(16'b1 << k);settle;
            if (presses!=previous_p+1 || last_key!==k[3:0] || !key_down)
                $fatal(1,"FAIL key mapping position=%0d got=%0d presses=%0d",k,last_key,presses);
            settle;
            if (presses!=previous_p+1) $fatal(1,"FAIL held key repeated");
            set_keys(0);settle;
            if (releases!=previous_r+1 || key_down) $fatal(1,"FAIL stable release");
        end
        // Sub-column glitches never span DB full stable scans (DB >= 3).
        if (DB>1) begin
            previous_p=presses;
            for (phase=0;phase<12;phase=phase+1) begin
                set_keys(16'h0020);clocks(COL-1);set_keys(0);clocks(2*COL+1);
            end
            settle;
            if (presses!=previous_p) $fatal(1,"FAIL press bounce accepted");
        end
        previous_p=presses;previous_r=releases;
        set_keys(16'h0020);settle;
        if (presses!=previous_p+1) $fatal(1,"FAIL post-bounce press");
        if (DB>1) begin
            for (phase=0;phase<10;phase=phase+1) begin
                set_keys(0);clocks(COL-1);set_keys(16'h0020);clocks(2*COL+1);
            end
            settle;
            if (releases!=previous_r || presses!=previous_p+1)
                $fatal(1,"FAIL release bounce created event");
        end
        // Changing directly to another key is not a second press.
        set_keys(16'h8000);settle;
        if (presses!=previous_p+1) $fatal(1,"FAIL rollover accepted");
        set_keys(0);settle;
        if (releases!=previous_r+1) $fatal(1,"FAIL rollover release");
        // Same row, same column, diagonal pair, and ghost-producing rectangle.
        for (phase=0;phase<4;phase=phase+1) begin
            previous_p=presses;
            // DB=1 cannot filter a partial snapshot during a mid-scan change.
            // Establish a coherent chord before the next column is sampled.
            while(!scan_valid) @(negedge clk);
            case(phase)
                0:set_keys(16'h0003);
                1:set_keys(16'h0011);
                2:set_keys(16'h0021);
                3:set_keys(16'h0013);
            endcase
            settle;
            if (!blocked || presses!=previous_p) $fatal(1,"FAIL chord rejection phase=%0d",phase);
            if (phase==3 && scan_keys!==16'h0033) $fatal(1,"FAIL ghost matrix fixture");
            set_keys(16'h0001);settle;
            if (!blocked || presses!=previous_p) $fatal(1,"FAIL chord partial release rearmed");
            set_keys(0);settle;
            if (blocked) $fatal(1,"FAIL chord lock not cleared");
            set_keys(16'h0001);settle;set_keys(0);settle;
            if (presses!=previous_p+1) $fatal(1,"FAIL chord recovery");
        end
        // Reset at each scan phase while held: no event until release/repress.
        for (phase=0;phase<4;phase=phase+1) begin
            set_keys(16'h0400);settle;clocks(phase*COL);
            reset_now;previous_p=presses;previous_r=releases;settle;
            if (presses!=previous_p || key_down) $fatal(1,"FAIL reset-held phantom press");
            set_keys(0);settle;
            if (releases!=previous_r) $fatal(1,"FAIL reset phantom release");
            set_keys(16'h0400);settle;set_keys(0);settle;
            if (presses!=previous_p+1) $fatal(1,"FAIL reset recovery");
        end
        $display("PASS keypad_scanner_checks: COL=%0d DB=%0d; 16 positions, held/release/repress, bounce policy, rollover, chords/ghosting, reset; %0d presses %0d releases",COL,DB,presses,releases);
        finished=1;
    end
endmodule
module tb_keypad_scanner;
    wire a,b,c;
    keypad_scanner_checks #(.COL(4),.DB(3)) minimum(a);
    keypad_scanner_checks #(.COL(11),.DB(5)) longer(b);
    keypad_scanner_checks #(.COL(7),.DB(1)) no_debounce(c);
    initial begin wait(a&&b&&c);$display("PASS tb_keypad_scanner: 3 timing configurations, all positions, bounce, holds, rollover, chords, ghosting and reset");$finish;end
    initial begin #10000000;$fatal(1,"FAIL keypad watchdog");end
endmodule

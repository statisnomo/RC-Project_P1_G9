`timescale 1ns / 1ps
// Logical bit 0 = ROW1/COL1. An external top drives selected columns low
// and leaves other columns high impedance. See docs/keypad_scanner.md.
// COLUMN_CYCLES >= 4; DEBOUNCE_FRAMES >= 1; synchronous active-high reset.
module keypad_scanner #(
    parameter integer COLUMN_CYCLES = 25000,
    parameter integer DEBOUNCE_FRAMES = 20
) (
    input wire clk, input wire rst,
    input wire [3:0] rows_n,
    output wire [3:0] col_drive_low,
    output reg press, output reg release_event,
    output reg [3:0] key_position,
    output reg key_down, output reg blocked,
    output reg scan_valid, output reg [15:0] scan_keys
);
    localparam integer CW = (COLUMN_CYCLES < 2) ? 1 : $clog2(COLUMN_CYCLES);
    localparam integer DW = (DEBOUNCE_FRAMES < 2) ? 1 : $clog2(DEBOUNCE_FRAMES+1);
    (* ASYNC_REG = "TRUE" *) reg [3:0] rows_meta, rows_sync;
    reg [CW-1:0] column_count;
    reg [1:0] column;
    reg [15:0] partial_keys, candidate;
    reg [DW-1:0] stable_count;
    reg armed;
    reg [15:0] complete_keys;
    reg [3:0] detected_position;
    integer row, bit_index, pressed_count;

    assign col_drive_low = rst ? 4'b0000 : (4'b0001 << column);
    always @* begin
        complete_keys = partial_keys;
        for (row=0; row<4; row=row+1)
            complete_keys[4*row+column] = !rows_sync[row];
        pressed_count = 0;
        detected_position = 0;
        for (bit_index=0; bit_index<16; bit_index=bit_index+1)
            if (complete_keys[bit_index]) begin
                pressed_count = pressed_count + 1;
                detected_position = bit_index;
            end
    end

    always @(posedge clk) begin
        if (rst) begin
            rows_meta <= 4'hf; rows_sync <= 4'hf;
            column_count <= 0; column <= 0;
            partial_keys <= 0; candidate <= 0; stable_count <= 0;
            armed <= 0; blocked <= 0; key_down <= 0; key_position <= 0;
            press <= 0; release_event <= 0; scan_valid <= 0; scan_keys <= 0;
        end else begin
            rows_meta <= rows_n; rows_sync <= rows_meta;
            press <= 0; release_event <= 0; scan_valid <= 0;
            if (column_count == COLUMN_CYCLES-1) begin
                column_count <= 0;
                column <= column + 1'b1;
                partial_keys <= complete_keys;
                if (column == 3) begin
                    scan_valid <= 1;
                    scan_keys <= complete_keys;
                    if (complete_keys != candidate) begin
                        candidate <= complete_keys;
                        stable_count <= 1;
                    end else if (stable_count < DEBOUNCE_FRAMES) begin
                        stable_count <= stable_count + 1'b1;
                    end
                    // Reject a chord immediately at the scan boundary.
                    // Returning to a single key cannot re-arm the scanner.
                    if (pressed_count > 1) begin
                        blocked <= 1;
                        armed <= 0;
                    end
                    if (DEBOUNCE_FRAMES == 1 ||
                        (complete_keys == candidate && stable_count >= DEBOUNCE_FRAMES-1)) begin
                        if (pressed_count == 0) begin
                            if (key_down) release_event <= 1;
                            key_down <= 0;
                            armed <= 1;
                            blocked <= 0;
                        end else if (pressed_count == 1 && armed && !blocked) begin
                            press <= 1;
                            key_down <= 1;
                            key_position <= detected_position;
                            armed <= 0;
                        end
                    end
                end
            end else column_count <= column_count + 1'b1;
        end
    end
endmodule

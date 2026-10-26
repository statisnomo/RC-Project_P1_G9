`timescale 1ns / 1ps

// Byte 4*column+row occupies bits [127-8*(4*column+row) -: 8].
module aes_shift_rows (
    input wire [127:0] state_in,
    output wire [127:0] state_out
);
    genvar column, row;
    generate
        for (column = 0; column < 4; column = column + 1) begin : columns
            for (row = 0; row < 4; row = row + 1) begin : rows
                assign state_out[127-8*(4*column+row) -: 8] =
                    state_in[127-8*(4*((column+row)%4)+row) -: 8];
            end
        end
    endgenerate
endmodule

`timescale 1ns / 1ps
// Passive switch network with row pull-ups and open-drain columns.
// Propagating low through connected switches also models rectangle ghosting.
module keypad_matrix_model (
    input wire [15:0] keys,
    input wire [3:0] col_drive_low,
    output reg [3:0] rows_n
);
    reg [3:0] low_rows, low_cols;
    integer pass_index, r, c;
    always @* begin
        low_rows = 0;
        low_cols = col_drive_low;
        for (pass_index=0; pass_index<8; pass_index=pass_index+1)
            for (r=0; r<4; r=r+1)
                for (c=0; c<4; c=c+1)
                    if (keys[4*r+c]) begin
                        if (low_cols[c]) low_rows[r] = 1;
                        if (low_rows[r]) low_cols[c] = 1;
                    end
        rows_n = ~low_rows;
    end
endmodule

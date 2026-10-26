`timescale 1ns / 1ps

module aes_mix_columns (
    input wire [127:0] state_in,
    output wire [127:0] state_out
);
    function [7:0] xtime;
        input [7:0] value;
        begin
            xtime = {value[6:0], 1'b0} ^ (8'h1b & {8{value[7]}});
        end
    endfunction

    genvar column;
    generate
        for (column = 0; column < 4; column = column + 1) begin : columns
            wire [7:0] a = state_in[127-32*column -: 8];
            wire [7:0] b = state_in[119-32*column -: 8];
            wire [7:0] c = state_in[111-32*column -: 8];
            wire [7:0] d = state_in[103-32*column -: 8];
            wire [7:0] total = a ^ b ^ c ^ d;
            assign state_out[127-32*column -: 8] = a ^ total ^ xtime(a ^ b);
            assign state_out[119-32*column -: 8] = b ^ total ^ xtime(b ^ c);
            assign state_out[111-32*column -: 8] = c ^ total ^ xtime(c ^ d);
            assign state_out[103-32*column -: 8] = d ^ total ^ xtime(d ^ a);
        end
    endgenerate
endmodule

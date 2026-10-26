`timescale 1ns / 1ps

module aes_round (
    input wire [127:0] state_in,
    input wire [127:0] round_key,
    input wire final_round,
    output wire [127:0] state_out
);
    wire [127:0] substituted, shifted, mixed;
    genvar byte_index;
    generate
        for (byte_index = 0; byte_index < 16; byte_index = byte_index + 1) begin : bytes
            aes_sbox box (
                .data_in(state_in[127-8*byte_index -: 8]),
                .data_out(substituted[127-8*byte_index -: 8])
            );
        end
    endgenerate
    aes_shift_rows shift (.state_in(substituted), .state_out(shifted));
    aes_mix_columns mix (.state_in(shifted), .state_out(mixed));
    assign state_out = (final_round ? shifted : mixed) ^ round_key;
endmodule

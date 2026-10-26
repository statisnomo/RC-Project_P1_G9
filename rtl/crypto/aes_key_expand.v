`timescale 1ns / 1ps

// AES-128 only. round_index=1 produces round key 1 from the original key.
module aes_key_expand (
    input wire [127:0] key_in,
    input wire [3:0] round_index,
    output wire [127:0] key_out
);
    wire [31:0] rotated = {key_in[23:0], key_in[31:24]};
    wire [31:0] substituted;
    reg [7:0] rcon;
    wire [31:0] word0 = key_in[127:96] ^ substituted ^ {rcon, 24'b0};
    wire [31:0] word1 = key_in[95:64] ^ word0;
    wire [31:0] word2 = key_in[63:32] ^ word1;
    wire [31:0] word3 = key_in[31:0] ^ word2;
    genvar byte_index;
    generate
        for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1) begin : bytes
            aes_sbox box (
                .data_in(rotated[31-8*byte_index -: 8]),
                .data_out(substituted[31-8*byte_index -: 8])
            );
        end
    endgenerate
    always @* begin
        case (round_index)
            1: rcon = 8'h01;
            2: rcon = 8'h02;
            3: rcon = 8'h04;
            4: rcon = 8'h08;
            5: rcon = 8'h10;
            6: rcon = 8'h20;
            7: rcon = 8'h40;
            8: rcon = 8'h80;
            9: rcon = 8'h1b;
            10: rcon = 8'h36;
            default: rcon = 8'h00;
        endcase
    end
    assign key_out = ((round_index >= 1) && (round_index <= 10)) ?
                     {word0, word1, word2, word3} : 128'b0;
endmodule

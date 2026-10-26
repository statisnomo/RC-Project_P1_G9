`timescale 1ns / 1ps

module tb_aes_primitives;
    reg [7:0] byte_in;
    wire [7:0] byte_out;
    reg [127:0] state_in, key_in;
    reg [3:0] round_index;
    reg final_round;
    wire [127:0] shifted, mixed, rounded, next_key;
    integer checks = 0;
    integer i, j;
    reg [31:0] random_state = 32'hae512804;
    reg [127:0] published_keys [1:10];

    aes_sbox sbox (.data_in(byte_in), .data_out(byte_out));
    aes_shift_rows shift (.state_in(state_in), .state_out(shifted));
    aes_mix_columns mix (.state_in(state_in), .state_out(mixed));
    aes_round round_dut (.state_in(state_in), .round_key(key_in),
        .final_round(final_round), .state_out(rounded));
    aes_key_expand expand (.key_in(key_in), .round_index(round_index), .key_out(next_key));

    `include "aes_reference.vh"

    task check_value;
        input [127:0] actual, expected;
        input [255:0] label_text;
        begin
            checks = checks + 1;
            if (actual !== expected) begin
                $display("FAIL %0s actual=%032h expected=%032h", label_text, actual, expected);
                $fatal(1,"AES primitive mismatch");
            end
        end
    endtask

    initial begin
        byte_in = 0; state_in = 0; key_in = 0; round_index = 1; final_round = 0;
        for (i = 0; i < 256; i = i + 1) begin
            byte_in = i; #1;
            check_value(byte_out,ref_sbox(i),"S-box exhaustive");
        end
        // Basis vectors catch every bit lane in the linear state transforms.
        for (i = 0; i < 128; i = i + 1) begin
            state_in = 128'b1 << i; #1;
            check_value(shifted,ref_shift(state_in),"ShiftRows basis");
            check_value(mixed,ref_mix(state_in),"MixColumns basis");
        end
        state_in = 128'h000102030405060708090a0b0c0d0e0f; #1;
        check_value(shifted,128'h00050a0f04090e03080d02070c01060b,"ShiftRows byte labels");
        state_in = 128'hdb135345000000000000000000000000; #1;
        check_value(mixed,128'h8e4da1bc000000000000000000000000,"MixColumns example");

        // FIPS 197 Appendix A.1, all ten expanded AES-128 round keys.
        published_keys[1]=128'ha0fafe1788542cb123a339392a6c7605;
        published_keys[2]=128'hf2c295f27a96b9435935807a7359f67f;
        published_keys[3]=128'h3d80477d4716fe3e1e237e446d7a883b;
        published_keys[4]=128'hef44a541a8525b7fb671253bdb0bad00;
        published_keys[5]=128'hd4d1c6f87c839d87caf2b8bc11f915bc;
        published_keys[6]=128'h6d88a37a110b3efddbf98641ca0093fd;
        published_keys[7]=128'h4e54f70e5f5fc9f384a64fb24ea6dc4f;
        published_keys[8]=128'head27321b58dbad2312bf5607f8d292f;
        published_keys[9]=128'hac7766f319fadc2128d12941575c006e;
        published_keys[10]=128'hd014f9a8c9ee2589e13f0cc8b6630ca6;
        key_in = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        for (i = 1; i <= 10; i = i + 1) begin
            round_index = i; #1;
            check_value(next_key,published_keys[i],"Published round key");
            key_in = next_key;
        end
        for (i = 0; i < 16; i = i + 1) begin
            if (i == 0 || i > 10) begin
                round_index = i; #1;
                check_value(next_key,128'b0,"Invalid key round");
            end
        end
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                random_state = next_random(random_state);
                state_in[j*32 +: 32] = random_state;
                random_state = next_random(random_state);
                key_in[j*32 +: 32] = random_state;
            end
            round_index = (i%10)+1; final_round = 0; #1;
            check_value(shifted,ref_shift(state_in),"ShiftRows random");
            check_value(mixed,ref_mix(state_in),"MixColumns random");
            check_value(next_key,ref_key(key_in,round_index),"Round key random");
            check_value(rounded,ref_round(state_in,key_in,0),"Normal round random");
            final_round = 1; #1;
            check_value(rounded,ref_round(state_in,key_in,1),"Final round random");
        end
        $display("PASS tb_aes_primitives: %0d checks; all 256 S-box entries, state transforms, 10 published round keys, normal/final rounds",checks);
        $finish;
    end
endmodule

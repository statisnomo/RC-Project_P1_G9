`timescale 1ns / 1ps

// AES-128 encryption, one reused round datapath and on-the-fly key expansion.
// See docs/aes_interface.md for byte order and the 11-clock latency contract.
module aes128_core (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [127:0] key,
    input wire [127:0] plaintext,
    output reg busy,
    output reg done,
    output reg [127:0] ciphertext
);
    reg [127:0] state;
    reg [127:0] round_key;
    reg [3:0] round_index;
    wire [127:0] next_key;
    wire [127:0] next_state;

    aes_key_expand expand (
        .key_in(round_key), .round_index(round_index), .key_out(next_key)
    );
    aes_round round_datapath (
        .state_in(state), .round_key(next_key),
        .final_round(round_index == 4'd10), .state_out(next_state)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= 128'b0;
            round_key <= 128'b0;
            round_index <= 4'b0;
            ciphertext <= 128'b0;
            busy <= 1'b0;
            done <= 1'b0;
        end else if (!busy) begin
            if (start) begin
                state <= plaintext;
                round_key <= key;
                round_index <= 4'd0;
                ciphertext <= 128'b0;
                busy <= 1'b1;
                done <= 1'b0;
            end
        end else if (round_index == 4'd0) begin
            // E1: the original key is added before the ten AES rounds.
            state <= state ^ round_key;
            round_index <= 4'd1;
        end else begin
            state <= next_state;
            round_key <= next_key;
            if (round_index == 4'd10) begin
                // E11: publish once. A start here is ignored while busy.
                ciphertext <= next_state;
                busy <= 1'b0;
                done <= 1'b1;
                round_index <= 4'd0;
            end else begin
                round_index <= round_index + 1'b1;
            end
        end
    end
endmodule

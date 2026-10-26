`timescale 1ns / 1ps

// Completion-based CPU bus. See docs/aes_mmio.md for all access semantics.
module aes_mmio #(parameter integer WAIT_CYCLES = 1) (
    input wire clk, input wire rst, input wire valid, input wire write,
    input wire [31:0] addr, input wire [31:0] wdata,
    input wire [3:0] wstrb, input wire [1:0] size,
    output reg ready, output reg [31:0] rdata, output reg error,
    output wire busy, output wire done
);
    reg [31:0] key_words [0:3];
    reg [31:0] pt_words [0:3];
    localparam integer COUNT_WIDTH = (WAIT_CYCLES < 2) ? 1 : $clog2(WAIT_CYCLES);
    reg [COUNT_WIDTH-1:0] wait_count;
    wire [31:0] byte_mask = {{8{wstrb[3]}},{8{wstrb[2]}},{8{wstrb[1]}},{8{wstrb[0]}}};
    wire [31:0] masked_data = wdata & byte_mask;
    wire [5:0] word_offset = addr[7:2];
    reg [3:0] allowed_lanes;
    reg bad_access, needs_idle;
    reg request_bad, request_needs_idle, request_start, request_write;
    reg [5:0] request_offset;
    reg [3:0] request_strobes;
    reg [31:0] request_data;
    wire [127:0] core_key, core_pt, core_ct;
    wire core_start = !rst && valid && ready && request_start && !error;
    integer word_index, lane;
    genvar k;
    function [31:0] reverse_bytes;
        input [31:0] word_value;
        begin reverse_bytes = {word_value[7:0],word_value[15:8],word_value[23:16],word_value[31:24]}; end
    endfunction
    generate
        for (k=0; k<4; k=k+1) begin : core_words
            assign core_key[127-k*32 -: 32] = reverse_bytes(key_words[k]);
            assign core_pt[127-k*32 -: 32] = reverse_bytes(pt_words[k]);
        end
    endgenerate
    aes128_core core (.clk(clk), .rst(rst), .start(core_start), .key(core_key),
        .plaintext(core_pt), .busy(busy), .done(done), .ciphertext(core_ct));

    // Decode during the mandatory wait cycle, before the completion edge.
    // BUSY is deliberately checked live at completion, not at capture.
    always @* begin
        case (size)
            0: allowed_lanes = 4'b0001 << addr[1:0];
            1: allowed_lanes = 4'b0011 << addr[1:0];
            2: allowed_lanes = 4'b1111;
            default: allowed_lanes = 4'b0000;
        endcase
        bad_access = addr[31:8] != 24'h400000 || size == 3 ||
            (size == 1 && addr[0]) || (size == 2 && addr[1:0] != 0) ||
            (write ? ((wstrb & ~allowed_lanes) != 0) : (wstrb != 0));
        needs_idle = 0;
        case (word_offset)
            6'h00: begin
                if (write && (masked_data & 32'hfffffffe) != 0) bad_access = 1;
                needs_idle = write && masked_data[0];
            end
            6'h01,6'h0c,6'h0d,6'h0e,6'h0f: if (write) bad_access = 1;
            6'h04,6'h05,6'h06,6'h07,6'h08,6'h09,6'h0a,6'h0b:
                needs_idle = write && (|wstrb);
            default: bad_access = 1;
        endcase
    end

    // Registered address/control breaks the CPU address-to-readback path.
    // Register contents, BUSY and DONE still reflect the completion edge.
    always @* begin
        error = request_bad || (request_needs_idle && busy);
        rdata = 0;
        case (request_offset)
            6'h01: rdata = {30'b0,done,busy};
            6'h04,6'h05,6'h06,6'h07: rdata = key_words[request_offset[1:0]];
            6'h08,6'h09,6'h0a,6'h0b: rdata = pt_words[request_offset[1:0]];
            6'h0c,6'h0d,6'h0e,6'h0f:
                rdata = reverse_bytes(core_ct[127-32*request_offset[1:0] -: 32]);
            default: rdata = 0;
        endcase
        if (error || request_write) rdata = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            ready <= 0;
            wait_count <= 0;
            request_bad <= 0;
            request_needs_idle <= 0;
            request_start <= 0;
            request_write <= 0;
            request_offset <= 0;
            request_strobes <= 0;
            request_data <= 0;
            for (word_index=0; word_index<4; word_index=word_index+1) begin
                key_words[word_index] <= 0;
                pt_words[word_index] <= 0;
            end
        end else begin
            // The master holds request fields stable until completion.
            // Capture each new request; continuous VALID can carry a new
            // transaction after the previous completion without a bubble.
            if (valid && !ready) begin
                request_bad <= bad_access;
                request_needs_idle <= needs_idle;
                request_start <= write && word_offset == 0 && masked_data[0];
                request_write <= write;
                request_offset <= word_offset;
                request_strobes <= wstrb;
                request_data <= wdata;
            end
            if (!valid || ready) begin
                ready <= 0;
                wait_count <= 0;
            end else if (wait_count == WAIT_CYCLES-1) begin
                ready <= 1;
            end else wait_count <= wait_count + 1'b1;

            if (valid && ready && request_write && !error) begin
                for (lane=0; lane<4; lane=lane+1) begin
                    if (request_strobes[lane]) begin
                        if (request_offset >= 6'h04 && request_offset <= 6'h07)
                            key_words[request_offset[1:0]][lane*8 +: 8] <= request_data[lane*8 +: 8];
                        if (request_offset >= 6'h08 && request_offset <= 6'h0b)
                            pt_words[request_offset[1:0]][lane*8 +: 8] <= request_data[lane*8 +: 8];
                    end
                end
            end
        end
    end
endmodule

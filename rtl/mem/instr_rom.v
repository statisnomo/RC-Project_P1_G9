`timescale 1ns / 1ps
// 4 KB, synchronous read. Unfilled locations are illegal instructions (zero).
module instr_rom #(parameter INIT_FILE = "") (
    input wire clk, input wire rst, input wire valid, input wire [31:0] addr,
    output reg ready, output reg [31:0] rdata, output reg error
);
    (* rom_style = "block" *) reg [31:0] words [0:1023];
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) words[i] = 32'b0;
        if (INIT_FILE != "") $readmemh(INIT_FILE, words);
    end
    // Keep the memory output separate from reset/control to permit BRAM inference.
    always @(posedge clk)
        if (valid && !ready) rdata <= words[addr[11:2]];
    always @(posedge clk) begin
        if (rst) begin ready <= 0; error <= 0; end
        else begin
            ready <= valid && !ready;
            if (valid && !ready) error <= (addr[31:12] != 0 || addr[1:0] != 0);
        end
    end
endmodule

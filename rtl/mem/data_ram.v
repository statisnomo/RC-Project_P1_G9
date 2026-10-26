`timescale 1ns / 1ps
// 4 KB at 0x1000. Contents are NOT cleared by reset; software initializes RAM.
// Read the containing 32-bit word; write enabled little-endian byte lanes.
module data_ram (
    input wire clk, input wire rst, input wire valid, input wire write,
    input wire [31:0] addr, input wire [31:0] wdata, input wire [3:0] wstrb,
    output reg ready, output reg [31:0] rdata, output reg error
);
    (* ram_style = "block" *) reg [31:0] words [0:1023];
    integer lane;
    always @(posedge clk) begin
        if (valid && !ready) rdata <= words[addr[11:2]];
        // Side effects occur only on the completion edge, never while waiting.
        if (!rst && valid && ready && write && !error)
            for (lane = 0; lane < 4; lane = lane + 1)
                if (wstrb[lane]) words[addr[11:2]][lane*8 +: 8] <= wdata[lane*8 +: 8];
    end
    always @(posedge clk) begin
        if (rst) begin ready <= 0; error <= 0; end
        else begin
            ready <= valid && !ready;
            if (valid && !ready) error <= (addr[31:12] != 20'h00001);
        end
    end
endmodule

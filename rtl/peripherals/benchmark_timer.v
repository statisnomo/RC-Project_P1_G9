`timescale 1ns/1ps
// Development benchmark: free-running 32-bit counter at 0x40000380.
// Snapshot on request capture; one response, cancellable, word reads only.
module benchmark_timer(input wire clk,rst,valid,write,
    input wire [31:0] addr,input wire [3:0] wstrb,input wire [1:0] size,
    output reg ready,output reg error,output reg [31:0] rdata);
    reg [31:0] cycles;
    always @(posedge clk) begin
        if(rst) begin cycles<=0;ready<=0;error<=0;rdata<=0;end
        else begin
            cycles<=cycles+1'b1;
            ready<=valid && !ready;
            if(valid && !ready) begin
                rdata<=cycles;
                error<=write || addr!=32'h40000380 || wstrb!=0 || size!=2;
            end
        end
    end
endmodule

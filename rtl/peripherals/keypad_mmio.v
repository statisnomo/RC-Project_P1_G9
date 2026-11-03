`timescale 1ns / 1ps
// One-entry event mailbox. Reads do not consume events; CTRL provides W1 ACK.
// See docs/keypad_mmio.md for completion-edge and overflow priorities.
module keypad_event_mmio #(parameter integer WAIT_CYCLES=1) (
    input wire clk, rst, valid, write,
    input wire [31:0] addr, wdata,
    input wire [3:0] wstrb, input wire [1:0] size,
    output reg ready, output reg [31:0] rdata, output wire error,
    input wire press, input wire [3:0] key_position,
    input wire key_down, blocked
);
    localparam integer CW=(WAIT_CYCLES<2)?1:$clog2(WAIT_CYCLES);
    reg [CW-1:0] wait_count;
    reg pending, overflow;
    reg [3:0] saved_position;
    reg [3:0] allowed_lanes;
    reg bad_access;
    reg request_bad, request_write, request_ack, request_clear;
    reg [1:0] request_reg;
    wire [31:0] mask={{8{wstrb[3]}},{8{wstrb[2]}},{8{wstrb[1]}},{8{wstrb[0]}}};
    wire complete=!rst && valid && ready && !error;
    wire ack=complete && request_ack;
    wire clear_overflow=complete && request_clear;
    assign error=request_bad;
    always @* begin
        case(size)
            0:allowed_lanes=4'b0001 << addr[1:0];
            1:allowed_lanes=4'b0011 << addr[1:0];
            2:allowed_lanes=4'b1111;
            default:allowed_lanes=0;
        endcase
        bad_access=addr[31:8]!=24'h400001 || size==3 ||
            (size==1 && addr[0]) || (size==2 && addr[1:0]!=0) ||
            (write ? ((wstrb & ~allowed_lanes)!=0) : (wstrb!=0));
        case(addr[7:2])
            0,1:if(write) bad_access=1;
            2:if(write && (wdata & mask & 32'hfffffffc)!=0) bad_access=1;
            default:bad_access=1;
        endcase
        rdata=0;
        if(!error && !request_write) begin
            case(request_reg)
                0:rdata={28'b0,overflow,blocked,key_down,pending};
                1:rdata=pending ? {28'b0,saved_position} : 32'b0;
                default:rdata=0;
            endcase
        end
    end
    always @(posedge clk) begin
        if(rst) begin
            ready<=0;wait_count<=0;
            request_bad<=0;request_write<=0;request_reg<=0;
            request_ack<=0;request_clear<=0;
            pending<=0;overflow<=0;saved_position<=0;
        end else begin
            if(valid && !ready) begin
                request_bad<=bad_access;request_write<=write;request_reg<=addr[3:2];
                request_ack<=write && addr[7:2]==2 && wstrb[0] && wdata[0];
                request_clear<=write && addr[7:2]==2 && wstrb[0] && wdata[1];
            end
            if(!valid || ready) begin ready<=0;wait_count<=0;end
            else if(wait_count==WAIT_CYCLES-1) ready<=1;
            else wait_count<=wait_count+1'b1;
            if(ack) begin pending<=0;saved_position<=0;end
            if(clear_overflow) overflow<=0;
            if(press) begin
                // An ACK frees the slot on this edge. Never discard a new
                // event merely because software acknowledged the old one.
                if(!pending || ack) begin pending<=1;saved_position<=key_position;end
                else overflow<=1; // New overflow wins over simultaneous clear.
            end
        end
    end
endmodule

module keypad_mmio #(
    parameter integer COLUMN_CYCLES=25000,
    parameter integer DEBOUNCE_FRAMES=20,
    parameter integer WAIT_CYCLES=1
) (
    input wire clk, rst, valid, write,
    input wire [31:0] addr, wdata,
    input wire [3:0] wstrb, input wire [1:0] size,
    output wire ready, output wire [31:0] rdata, output wire error,
    input wire [3:0] rows_n, output wire [3:0] col_drive_low
);
    wire press,key_down,blocked;
    wire [3:0] key_position;
    keypad_scanner #(.COLUMN_CYCLES(COLUMN_CYCLES),.DEBOUNCE_FRAMES(DEBOUNCE_FRAMES)) scanner (
        .clk(clk),.rst(rst),.rows_n(rows_n),.col_drive_low(col_drive_low),
        .press(press),.release_event(),.key_position(key_position),
        .key_down(key_down),.blocked(blocked),.scan_valid(),.scan_keys());
    keypad_event_mmio #(.WAIT_CYCLES(WAIT_CYCLES)) events (
        .clk(clk),.rst(rst),.valid(valid),.write(write),.addr(addr),.wdata(wdata),
        .wstrb(wstrb),.size(size),.ready(ready),.rdata(rdata),.error(error),
        .press(press),.key_position(key_position),.key_down(key_down),.blocked(blocked));
endmodule

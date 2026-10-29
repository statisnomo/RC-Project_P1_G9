`timescale 1ns / 1ps
// Maintainer-only negative tests. A FAIL is expected, before CPU execution.
module tb_soc_minimal_rom_fault #(parameter MODE=0);
    tb_soc_minimal #(.ROM_FILE(MODE == 0 ? "deliberately_missing_soc.hex" : "cpu_smoke.hex")) checks();
    initial begin
        if (MODE == 1) begin
            // Corrupt the final word after the DUT loads it, before preflight.
            // This proves the comparison covers all 1024 words, not just boot.
            #0.5;
            checks.dut.rom.words[1023] = 32'h00000001;
        end
    end
endmodule

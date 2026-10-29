`timescale 1ns / 1ps
// Maintainer-only fault injection. Not an extra lab simulation set.
module tb_sim_data_check #(parameter integer MODE = 0);
    `include "sim_data_check.vh"
    initial begin
        #1;
        case (MODE)
            0: require_hex_file("valid.mem", 2);
            1: require_hex_file("deliberately_missing.mem", 1);
            2: require_hex_file("short.mem", 2);
            3: require_hex_file("malformed.mem", 1);
            4: require_hex_file("unknown.mem", 1);
            5: require_hex_file("valid.mem", 1);
            default: $fatal(1,"FAIL invalid diagnostic mode");
        endcase
        if (MODE != 0) $fatal(1,"FAIL expected SIM_DATA rejection did not occur");
        $display("PASS tb_sim_data_check: valid fixture accepted");
        $finish;
    end
endmodule

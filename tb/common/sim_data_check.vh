// Simulation-only preflight for the project's plain hexadecimal data files.
// Call before $readmemh so missing/short data fails before testing the RTL.
task automatic require_hex_file;
    input string filename;
    input integer expected_words;
    integer handle, scanned, words_read;
    reg [383:0] parsed_word;
    begin
        handle = $fopen(filename, "r");
        if (handle == 0) begin
            $fatal(1, "FAIL SIM_DATA cannot open '%0s'. Recreate the project with scripts/create_lab_compat_project.tcl; check staged data files and VIVADO_GUI.", filename);
            return;
        end
        words_read = 0;
        while (!$feof(handle)) begin
            scanned = $fscanf(handle, "%h", parsed_word);
            if (scanned == 1) begin
                if ((^parsed_word) === 1'bx) begin
                    $fclose(handle);
                    $fatal(1, "FAIL SIM_DATA unknown hex digits in '%0s', word %0d", filename, words_read);
                    return;
                end
                words_read = words_read + 1;
            end else if (scanned == 0) begin
                $fclose(handle);
                $fatal(1, "FAIL SIM_DATA malformed hex in '%0s', after word %0d", filename, words_read);
                return;
            end
        end
        $fclose(handle);
        if (words_read != expected_words) begin
            $fatal(1, "FAIL SIM_DATA '%0s': expected %0d words, found %0d. Re-extract the complete pack.", filename, expected_words, words_read);
            return;
        end
        $display("SIM_DATA_OK '%0s': %0d words", filename, words_read);
    end
endtask

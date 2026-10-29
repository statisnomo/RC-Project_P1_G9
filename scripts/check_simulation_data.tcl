# Read-only setup validation. Uses Tcl built-ins available in older Vivado.
# The project uses plain hex tokens, with no addresses or comments in data files.
proc check_lab_hex {relative expected_words digits} {
    global root
    set path [file join $root $relative]
    if {![file isfile $path]} { error "SIM_DATA missing file: $path" }
    set stream [open $path r]
    set tokens [regexp -all -inline {\S+} [read $stream]]
    close $stream
    if {[llength $tokens] != $expected_words} {
        error "SIM_DATA $relative: expected $expected_words words, found [llength $tokens]"
    }
    set pattern [format {^[0-9a-fA-F]{%d}$} $digits]
    foreach token $tokens {
        if {![regexp $pattern $token]} { error "SIM_DATA malformed hex token in $relative" }
    }
}
check_lab_hex tb/crypto/vectors/aes128_kat.mem 284 96
check_lab_hex fw/cpu_smoke.hex 1024 8
check_lab_hex fw/aes_smoke.hex 1024 8
set stream [open [file join $root tb programs cases.vh] r]
set case_text [read $stream]
close $stream
set checked_cases 0
foreach line [split $case_text "\n"] {
    if {[regexp {^run_case\("([a-zA-Z0-9_]+)", ([0-9]+), ([0-9]+),} $line unused name commits transfers]} {
        check_lab_hex tb/programs/${name}.hex 1024 8
        check_lab_hex tb/programs/${name}.trace [expr {max(1,$commits)}] 40
        check_lab_hex tb/programs/${name}.bus [expr {max(1,$transfers)}] 56
        check_lab_hex tb/programs/${name}.regs 32 8
        check_lab_hex tb/programs/${name}.ram 1024 8
        incr checked_cases
    }
}
if {$checked_cases != 25} { error "SIM_DATA expected 25 CPU programs, found $checked_cases" }
puts "SIM_DATA_FILES_OK: 128 hex files; 284 AES vectors; both 1024-word ROMs; 25 CPU programs"

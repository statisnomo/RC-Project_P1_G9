# Combined display build and lab record

The November 4 independent keypad/AES and external OLED board demos passed, along with the four new simulation tests. [The lab record](lab_results_2026-11-04.md) includes exact supplied messages and links to five archived photographs. Bitstream regeneration at the lab was not performed. On rechecking November 5, all four supplied waveform configuration files were found and archived with matching hashes in the lab evidence folder.

The next build connects the full CPU/keypad/AES path to the external OLED and UART. The firmware uses 504 bytes of the 4096-byte ROM. Its fixed demonstration key is 00 through 0F; this is a functional AES demonstration, not a secret-key storage design. It takes 32 hex digits per block and retains the previous ciphertext while the next block is typed. A recognized chord requests orderly OLED shutdown, held until release; releasing restarts with a blank display and resets the input count. Input overflow handling and peripheral fault timeouts remain open.

At the user's request, the new combined layout is **JA keypad, JC OLED, JD1 optional UART TX**. The published November 3 independent OLED image remains a JB image. The combined bitstream is packaged with JA/JC in its filename, and the packager checks the actual implemented I/O report against the requested connector mapping.

Development benches cover OLED access errors/cancellation/power sequencing, two full ciphertexts reconstructed from physical SPI bytes and UART bits, a second result staged during an existing display transfer, incomplete input, shutdown/restart, and the board wrapper's input pads and LED feedback. The routed build and PASS logs are retained under `evidence/display_candidate_2026-11-04/` (run begun November 4, continued November 5). Physical combined-display testing remains pending.

The prior cleanup removed 115 Git-ignored compiler-cache directories (74,007,380 bytes, 70.6 MiB). It preserved source, projects, bitstreams, waveforms, saved evidence and all published ZIPs. These regenerated caches were never tracked, so there is no source deletion to push. The existing lab ZIP remains byte-for-byte unchanged.

The user's intended generation workflow is to receive the code and supplied .bit, run implementation in Vivado, and generate a new .bit from the same design. The new guide describes that directly; it does not require a demonstration edit or a Tcl setup script.

The first combined route missed setup by 0.504 ns. The critical path passed from CPU address calculation through the new OLED request/error decode back to CPU writeback. The OLED interface now registers request decoding, read selection and write data before completion, matching the other MMIO responders. All three behavioral benches passed after this change. The final implementation reports, rather than the failed exploratory image, determine publication.


Final Vivado 2025.2 route meets 100 MHz: setup WNS +0.146 ns, hold WHS +0.132 ns. The implemented pin report confirms OLED on JC and UART on JD1. DRC has no errors; the expected PL-only ZPS7-1 warning remains. The combined image has not been physically tested.


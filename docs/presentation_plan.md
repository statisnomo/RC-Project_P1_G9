# Presentation direction: a processor with measurable hardware acceleration

Goal: make the audience see the machine, the correctness check and the benefit
of dedicated hardware. The final data is ciphertext; the project result is a
custom computer that can execute and measure both ways of producing it.

## The three-minute demonstration

**First 40 seconds — show the real machine.** Point to the ZedBoard and
keypad. Explain that the design runs in FPGA logic, with a custom RISC-V CPU
and no ARM application. Enter the known-answer block. Show the exact expected
OLED ciphertext and say: “Our CPU read the input and controlled the AES
peripheral through memory-mapped registers.” Use the physically passed
external-OLED image until the onboard image has its own lab pass.

**Next minute — answer why there is an accelerator.** Show the comparison
view in `presentation_demo.html`. Say: “We ran software AES and hardware AES
on the same custom processor. Both produced the correct answer. This compact
software implementation took 24,576 cycles; the complete hardware call,
including transfers, took 213. That is 115.4 times fewer cycles.” Explicitly
identify these as Vivado simulation measurements until the board's live
counter/display integration is validated. Do not call the 11-cycle AES core
latency the full application latency or claim that typing becomes 115x faster.

**Next 40 seconds — let someone choose a bit.** Open “Change one bit”. Move
the selector and show that exactly one plaintext bit changes, while many
ciphertext bits change. Each displayed answer is independently checked, not
random visual noise. Say: “For these 128 changes we observed 47 to 79 output
bits change. This illustrates diffusion.” The offline view shows saved
verified results; it is not connected to the board.

**Last 40 seconds — show engineering reliability.** If the physical restart
test has passed, show the chord shutdown, release and next valid block. Show
one concise verification summary with the number of independent answers,
reset/error tests and routed implementation resources. Explain one pipeline
hazard and how valid/ready waits allow the CPU to use slower peripherals.

## What else is possible, in priority order

1. **Live benchmark screen:** keypad input → both paths → MATCH + cycle counts
   on the board's OLED. Backend is verified; display integration is next.
2. **Live avalanche mode:** retain a block, flip one selected bit and show a
   changed-bit count. Backend vectors and presenter view are ready; interactive
   board controls and display are not built yet.
3. **Readable message / recovery demonstration:** show a short readable message,
   its ciphertext and recovered message. This needs text-entry/display support
   and an explicitly identified decryption implementation. There is currently
   no decryption engine; do not present recovery as an existing feature.
4. **Laptop viewer through UART:** display plaintext/ciphertext, cycle counts
   and bit differences on a large screen using real board output. This depends
   on the still-pending 3.3 V UART adapter and protocol work.

Finish the first two before adding larger features. A correct live comparison
and one audience-controlled bit change make a stronger, explainable demo than
many unfinished modes. The deadline remains November 20; keep a known-working
bitstream, expected outputs and a short physical demonstration video as backup.

## Open the offline presenter

Open `docs/presentation_demo.html` in a browser; it needs no network or
installation. Use its full-screen button or F11. It has three chapters with
keyboard-accessible tabs. The page's data and interaction logic were checked;
its visual browser preview was blocked by the tool's local-file policy and
still needs a manual look on the presentation laptop.

## Presentation completion checks

- [x] Software AES executes on the real custom CPU in simulation.
- [x] Fairly scoped complete-call timing, checked against independent cycles.
- [x] Independent known-answer and 128 single-bit-change checks.
- [x] Offline presenter generated from saved passing evidence.
- [ ] Manual browser/layout check on the actual presentation laptop.
- [ ] OLED labels, input progress, MATCH and both cycle counts integrated.
- [ ] Integrated presentation image passes simulation and routed timing.
- [ ] Live comparison and avalanche mode verified on the board.
- [ ] Optional UART viewer if the adapter becomes available.
- [ ] Final video, report, slides and rehearsal with exact measured claims.

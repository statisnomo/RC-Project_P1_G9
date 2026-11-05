# Ready-to-program ZedBoard builds

**Built-in OLED option:** [onboard display image](zedboard_display_onboard/zedboard_display_onboard.bit)
uses the JA keypad and the ZedBoard's own display, with optional UART on JD1.
Use [the onboard lab guide](../LAB_ONBOARD_OLED.md) to rebuild through Vivado's
GUI and perform test 27. Seven local simulations passed; routed 100 MHz
setup/hold slack is +0.241/+0.106 ns. Physical onboard acceptance is pending.
The external OLED image below remains the physically demonstrated backup.

**Hardened November 5 combined image:** [keypad JA + OLED JC](zedboard_display/zedboard_display_ja_jc.bit), with overflow recovery and bounded status waits. Use [the combined guide](../NEXT_LAB_COMBINED.md) for its LED meanings and expected ciphertext, and [the optional UART test](../LAB_UART_OPTIONAL.md) for JD1. Matching [implementation evidence](../evidence/display_hardened_2026-11-05/) and [bitstream hash](zedboard_display/bitstream.sha256) identify this build. The old standalone OLED is a JB image. The self-tests below use a different LED legend.

## October self-tests

These three builds are included in GitHub so the lab guides' paths work
after downloading the repository. They match the verified October 27 lab
ZIP. Target: **xc7z020clg484-1**, **100 MHz PL clock**, Vivado **2025.2**.

Program these images through **Hardware Manager > Open Target > Auto
Connect > Program Device**. Leave the `.ltx` debug-probes field empty.

1. [ALU self-test](zedboard_alu_demo/zedboard_alu_demo.bit).
2. [CPU self-test](zedboard_cpu_demo/zedboard_cpu_demo.bit).
3. [CPU plus AES self-test](zedboard_aes_demo/zedboard_aes_demo.bit).

For a healthy result, **LD0 blinks, LD1 stays ON, and LD2-LD7 stay OFF**.
The [lab walkthrough](../docs/lab_2026-10-27.md) explains the test order,
reprogramming, evidence to save, and how to interpret the LEDs.

On GitHub, open a `.bit` file and use **Download raw file**. Do not save the
HTML preview page as a bitstream. To get everything, use **Code > Download
ZIP** and extract the whole repository. A `.dcp` file is a routed design
checkpoint for inspection; choose the `.bit` file when programming.

Each folder includes its routed timing, utilization, and DRC reports.
The existing constraints and firmware for rebuilding remain in the
project's `constraints/`, `fw/`, and `scripts/` folders. `SHA256SUMS.txt`
identifies the published artifacts, with paths relative to this folder.

All three images passed their implementation timing checks. On October 27,
the user also reported **physical PASS for all three**, with the healthy
LED pattern above, including **3/3 AES trials**. See the
[physical lab record](../docs/lab_results_2026-10-27.md).

Vivado caches, temporary runs, and unrelated generated builds remain
ignored. These saved builds are deliberate distribution artifacts.


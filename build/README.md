# Ready-to-program ZedBoard builds

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

"""Printable companion to docs/lab_2026-10-27.md; no lab tooling required."""
from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output/pdf/lab-testing-guide-2026-10-27.pdf"
OUT.parent.mkdir(parents=True, exist_ok=True)
NAVY = colors.HexColor("#17364D")
TEAL = colors.HexColor("#087E80")
styles = {
    "title": ParagraphStyle("title", fontName="Helvetica-Bold", fontSize=22, leading=26, textColor=NAVY, spaceAfter=10),
    "sub": ParagraphStyle("sub", fontName="Helvetica", fontSize=10, leading=14, textColor=TEAL, spaceAfter=12),
    "head": ParagraphStyle("head", fontName="Helvetica-Bold", fontSize=12, leading=16, textColor=NAVY, spaceBefore=12, spaceAfter=5),
    "body": ParagraphStyle("body", fontName="Helvetica", fontSize=10, leading=14, spaceAfter=7),
    "code": ParagraphStyle("code", fontName="Courier", fontSize=8.4, leading=12, spaceAfter=8),
    "note": ParagraphStyle("note", fontName="Helvetica", fontSize=9, leading=12, textColor=colors.HexColor("#465766"), spaceAfter=8),
    "good": ParagraphStyle("good", fontName="Helvetica-Bold", fontSize=12, leading=17, textColor=TEAL, spaceAfter=8),
}
story = []


def p(text, kind="body"):
    story.append(Paragraph(text, styles[kind]))


def page(title, subtitle):
    if story:
        story.append(PageBreak())
    p(title, "title")
    p(subtitle, "sub")


def chrome(canvas, doc):
    width, height = A4
    canvas.setStrokeColor(TEAL)
    canvas.setLineWidth(2)
    canvas.line(40, height-30, width-40, height-30)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(NAVY)
    canvas.drawString(40, 24, "Custom RISC-V SoC + AES | Lab pack: 27 October 2026")
    canvas.drawRightString(width-40, 24, f"{doc.page} / 3")


page("Lab testing guide", "27 October 2026 | Vivado GUI only | Target: ZedBoard XC7Z020")
p("<b>Aim:</b> test three small machines in order: the ALU, the CPU, then the CPU controlling AES. Give the physical tests priority while the board is available. Simulations also work at home.")
p("1. Open the complete pack", "head")
p("Extract <b>riscv_soc_lab_2026-10-27.zip</b> to a short writable folder, such as C:\\RC_Lab. Keep all folders together. In <b>Vivado 2025.2 &gt; Open Project</b>, choose:")
p("riscv_soc_project/vivado/riscv_soc_lab/riscv_soc_lab.xpr", "code")
p("Part: <b>xc7z020clg484-1</b>. Zynq-7000 support and cable drivers are needed; a board-catalogue entry is not. No compiler, Python, or terminal is needed.")
p("2. Connect through USB-JTAG", "head")
p("Use the lab's approved power supply and documented JTAG-boot setup. Ask staff to confirm the board/device and setup. Use <b>USB-JTAG J17</b>, not USB-UART. Keep external Pmods disconnected for these tests.")
p("3. Program each image", "head")
p("Choose <b>Open Hardware Manager &gt; Open Target &gt; Auto Connect</b>. Select XC7Z020, then <b>Program Device</b>. Set the Bitstream file, leave the .ltx debug-probes field empty, and click <b>Program</b>.")
p("Paths below are relative to the extracted <b>riscv_soc_project</b> folder. Observe each image for at least 10 seconds and save its filename plus an LED video.")
for name, explanation in (
    ("alu", "[ ] ALU: fixed arithmetic/logic self-tests."),
    ("cpu", "[ ] CPU: real instructions, ROM/RAM, and a test MMIO device."),
    ("aes", "[ ] CPU + AES: four encrypted blocks checked by firmware and a separate hardware observer."),
):
    p(explanation)
    p(f"build/zedboard_{name}_demo/zedboard_{name}_demo.bit", "code")
p("Expected for every image", "head")
p("LD0 blinking + LD1 ON + LD2-LD7 OFF", "good")
p("LD0 is the heartbeat; LD1 is application PASS. LD3 may finish too quickly to see. The separate configuration DONE LED does not prove that the program passed.", "note")
p("<b>Repeat:</b> program the AES image three times; confirm the same result. Reprogramming supplies a fresh startup reset. PROG clears configuration; it is not an application-reset button. Do not program flash.")

page("Small simulation checks", "Run one block at a time | No FPGA board required")
p("Close the old simulation. Open <b>Simulation Settings</b>, select the named set, confirm its top, then click <b>Run Simulation &gt; Run Behavioral Simulation &gt; Run All</b>. Read the automatic PASS line in the Tcl Console pane; do not type commands.")
for title, text in (
    ("[ ] First lesson: ALU", "Set <b>sim_1</b>, top <b>tb_alu</b>. Expected: <b>4,142 checks</b>. View operand_a, operand_b, alu_op, result, zero. The first ADD wraps ffffffff + 00000001 to zero, with zero=1."),
    ("[ ] AES maths", "Set <b>sim_aes_primitives</b>, top <b>tb_aes_primitives</b>. Expected: <b>1,810 checks</b>. This checks the transformations used inside each AES round."),
    ("[ ] AES alone", "Set <b>sim_aes_core</b>, top <b>tb_aes128_core</b>. Expected: <b>17,433 checks / 556 completed blocks</b>. At 25-135 ns inspect START, BUSY, DONE and ciphertext."),
    ("[ ] AES register interface", "Set <b>sim_aes_mmio</b>, top <b>tb_aes_mmio</b>. Expected: <b>26,632 / 48,264 checks</b> for one/three wait edges, then PASS tb_aes_mmio. Check that a write takes effect only at a clock edge with VALID and READY high."),
    ("[ ] CPU controls AES", "Set <b>sim_soc_aes</b>, top <b>tb_soc_aes</b>. Expected: <b>32 healthy blocks</b> plus error/reset checks, then PASS tb_soc_aes. Under normal_bus/dut, add mmio_* and aes_busy/aes_done to the waveform."),
    ("[ ] Board wrapper", "Set <b>sim_aes_board</b>, top <b>tb_aes_board</b>. Expected: <b>13 monitor scenarios</b> plus real program, restart and LED checks, then PASS tb_aes_board."),
):
    p(title, "head")
    p(text)
p("What to look for in the CPU/AES waveform", "head")
p("A completed write of 1 to <b>40000000</b> starts AES. Reads at <b>40000004</b> poll status. Reads at <b>40000030-4000003c</b> fetch ciphertext. Use hexadecimal radix. The first full ciphertext is:")
p("69c4e0d86a7b0430d8cdb78070b4c55a", "code")
p("These benches deliberately inject faults. Judge the final PASS, not a temporary fault signal. A $finish after PASS is normal. If time stays at 0 ns, click Run All. Save PASS screenshots and a waveform.", "note")
p("The full <b>VIVADO_START_HERE.md</b> covers all 14 sets, including register file, decoder, immediate generator, memories, and CPU regression. The folder <b>docs/</b> contains the detailed lab procedure and editable record sheet.", "note")

page("Record the lab result", "Tick only what you personally observe | Keep separate records for each image")
p("Date/time: ____________________  Vivado version: ____________________")
p("Board revision / detected device: ____________________________________")
p("Source changed or supplied images used? _____________________________")
for name in ("ALU", "CPU", "CPU + AES"):
    p(name, "head")
    p("[ ] LD0 blinking   [ ] LD1 ON   [ ] LD2-LD7 OFF   Result: PASS / FAIL / NOT TESTED")
    p("Image used / video location: _________________________________________")
p("AES repeat checks: 1st _________   2nd _________   3rd _________")
p("Simulation PASS screenshots / waveform: ______________________________")
p("If a test fails", "head")
p("Record the first error, exact image name, and all eight LEDs. For the AES image, LD7:LD4 encode the first fault if LD2 is on. Save the pattern; docs/zedboard_aes_demo.md explains the codes. If Vivado cannot find the device, ask staff to check power, data cable, JTAG connector, drivers, and boot setup.")
p("Information to collect for the next build", "head")
p("<b>No additional ZedBoard files are needed for today's LED tests.</b> Your device overview, user guide, E.1 schematic, and sample XDC are already in docs/references/zedboard/.")
for item in (
    "[ ] Board front/back photos, revision label, FPGA marking, and current jumper positions. Obtain matching board documentation if the revision differs from the supplied E.1 schematic.",
    "[ ] Keypad and OLED model/revision, front/back photos, pin-1 markings, and actual keypad key legends. Confirm external Pmod OLED versus the board's built-in display.",
    "[ ] Matching Pmod manuals/schematics and any adapter/extension-cable pinout available in the lab. Official reference links are saved in docs/references/pmods/README.md.",
    "[ ] For later PL UART: adapter model, pinout and confirmed 3.3 V logic. No UART adapter is needed for these tests.",
):
    p(item)
p("Engineering status", "head")
p("CPU/AES simulation passes. The supplied AES image meets routed 100 MHz timing: <b>+0.311 ns setup / +0.159 ns hold</b>; DRC has zero errors and the documented PL-only ZPS7-1 warning. <b>Physical results remain pending until observed.</b>", "note")
p("Update docs/lab_record_template.md, docs/progress_log.md and checklist tasks P1/P2/P4-P10/H2 only for tests completed. Next: independently tested UART, keypad and OLED controllers.", "note")

doc = SimpleDocTemplate(str(OUT), pagesize=A4, rightMargin=40, leftMargin=40,
                        topMargin=45, bottomMargin=43, title="RISC-V SoC lab testing guide - 27 October 2026")
doc.build(story, onFirstPage=chrome, onLaterPages=chrome)
reader = PdfReader(OUT)
assert len(reader.pages) == 3, f"Unexpected page spill: {len(reader.pages)} pages"
assert all(len(page.extract_text()) > 500 for page in reader.pages)
print(f"Created {OUT} ({len(reader.pages)} pages)")

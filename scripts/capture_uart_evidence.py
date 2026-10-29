"""Save the passed UART tests, synthesis reports, and exact source hashes."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "evidence/uart_m3_2026-10-27"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for bench in ("tb_uart_tx", "tb_uart_mmio", "tb_cpu_board", "tb_aes_board"):
        source = ROOT / f"build/uart_tests/{bench}.log"
        text = source.read_text()
        assert f"PASS {bench}:" in text and "FAIL" not in text, source
        shutil.copy2(source, OUT / source.name)
    for simset, bench in (("sim_uart_tx", "tb_uart_tx"),
                          ("sim_uart_mmio", "tb_uart_mmio")):
        wave = ROOT / f"vivado/riscv_soc_lab/riscv_soc_lab.sim/{simset}/behav/xsim/{bench}_behav.wdb"
        assert wave.stat().st_size > 0
        shutil.copy2(wave, OUT / wave.name)
    summary = (ROOT / "build/uart_synthesis/summary.txt").read_text()
    assert "Inferred latches: 0" in summary
    assert "UART_SYNTHESIS_COMPLETE:" in (ROOT / "build/uart_synthesis/synthesis.log").read_text()
    (OUT / "synthesis").mkdir(exist_ok=True)
    for name in ("summary.txt", "utilization.rpt", "timing_synth.rpt",
                 "register_paths.rpt", "synthesis.log"):
        shutil.copy2(ROOT / "build/uart_synthesis" / name, OUT / "synthesis" / name)
    sources = [
        "rtl/peripherals/uart_tx.v", "rtl/peripherals/uart_mmio.v",
        "tb/peripherals/uart_line_checker.v", "tb/peripherals/tb_uart_tx.v",
        "tb/peripherals/tb_uart_mmio.v", "scripts/add_uart_to_project.tcl",
        "scripts/update_uart_gui_project.tcl", "scripts/create_vivado_gui_project.tcl",
        "scripts/verify_uart_gui.tcl", "scripts/check_uart_synthesis.tcl",
        "docs/uart_interface.md", "vivado/riscv_soc_lab/riscv_soc_lab.xpr",
    ]
    manifest = {name: digest(ROOT / name) for name in sources}
    (OUT / "source_sha256.json").write_text(json.dumps(manifest, indent=2) + "\n")
    artifacts = {p.relative_to(OUT).as_posix(): digest(p) for p in sorted(OUT.rglob("*"))
                 if p.is_file() and p.suffix in (".log", ".wdb", ".rpt", ".txt")}
    (OUT / "artifact_sha256.json").write_text(json.dumps(artifacts, indent=2) + "\n")
    print(f"UART evidence saved: {len(manifest)} source hashes, {len(artifacts)} artifacts")


if __name__ == "__main__":
    main()

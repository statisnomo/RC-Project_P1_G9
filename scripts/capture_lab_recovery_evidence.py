"""Preserve recovery regressions and deliberately failing data diagnostics."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / "build/lab_recovery_tests"
OUT = ROOT / "evidence/lab_sim_recovery_2026-10-29"
BENCHES = (
    "tb_cpu_core", "tb_aes128_core", "tb_aes_mmio", "tb_soc_aes",
    "tb_alu", "tb_regfile", "tb_imm_gen", "tb_decode", "tb_memories",
    "tb_soc_minimal", "tb_alu_selftest", "tb_cpu_board", "tb_aes_primitives",
    "tb_aes_board", "tb_uart_tx", "tb_uart_mmio",
)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    summary = (RUN / "summary.txt").read_text()
    assert all(marker in summary for marker in (
        "LAB_RECOVERY_SIM_PASS", "SIM_DATA_GUARD_PASS", "SOC_ROM_GUARD_PASS"))
    OUT.mkdir(parents=True, exist_ok=True)
    for bench in BENCHES:
        path = RUN / f"{bench}.log"
        contents = path.read_text()
        assert f"PASS {bench}:" in contents and "FAIL" not in contents, path
        shutil.copy2(path, OUT / path.name)
    for index, pattern in enumerate((
            "FAIL SIM_DATA cannot open 'deliberately_missing_soc.hex'",
            "FAIL SIM_ROM_LOAD 'cpu_smoke.hex' word=1023 actual=00000001 expected=00000000")):
        path = RUN / f"soc_rom_diagnostic_{index}.log"
        contents = path.read_text()
        assert pattern in contents and "PASS tb_soc_minimal:" not in contents, path
        assert "File descriptor (0)" not in contents, path
        shutil.copy2(path, OUT / path.name)
    patterns = ("PASS tb_sim_data_check:", "cannot open 'deliberately_missing.mem'",
                "expected 2 words, found 1", "malformed hex", "unknown hex digits",
                "expected 1 words, found 2")
    for index, pattern in enumerate(patterns):
        path = RUN / f"diagnostic_{index}.log"
        contents = path.read_text()
        assert pattern in contents and "File descriptor (0)" not in contents, path
        shutil.copy2(path, OUT / path.name)
    shutil.copy2(RUN / "summary.txt", OUT / "summary.txt")
    paths = []
    for folder in ("rtl", "tb", "fw", "constraints"):
        paths.extend(p for p in (ROOT / folder).rglob("*")
                     if p.is_file() and "__pycache__" not in p.parts)
    paths.extend((ROOT / "scripts").glob("*.tcl"))
    paths.append(ROOT / "vivado/riscv_soc_lab/riscv_soc_lab.xpr")
    manifest = {p.relative_to(ROOT).as_posix(): digest(p) for p in sorted(paths)}
    (OUT / "source_sha256.json").write_text(json.dumps(manifest, indent=2) + "\n")
    artifacts = {p.name: digest(p) for p in sorted(OUT.glob("*"))
                 if p.suffix in (".log", ".txt")}
    (OUT / "artifact_sha256.json").write_text(json.dumps(artifacts, indent=2) + "\n")
    print(f"Saved 16 passing benches, 8 diagnostic scenarios, {len(manifest)} source hashes")


if __name__ == "__main__":
    main()

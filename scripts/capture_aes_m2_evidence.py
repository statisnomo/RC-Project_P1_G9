"""Save passed integration logs/waves and the exact current source hashes."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "evidence/aes_m2_2026-10-27"


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for simset, bench in (("sim_aes_mmio", "tb_aes_mmio"),
                          ("sim_soc_aes", "tb_soc_aes"),
                          ("sim_aes_board", "tb_aes_board")):
        log = ROOT / f"build/aes_tests/{bench}.log"
        content = log.read_text()
        assert f"PASS {bench}:" in content and "FAIL" not in content, str(log)
        shutil.copy2(log, OUT / log.name)
        wave = ROOT / f"vivado/riscv_soc_lab/riscv_soc_lab.sim/{simset}/behav/xsim/{bench}_behav.wdb"
        shutil.copy2(wave, OUT / wave.name)
    build_log = ROOT / "build/aes_tests/build_aes.log"
    assert "\nBUILD_PASS:" in build_log.read_text()
    shutil.copy2(build_log, OUT / "build_aes.log")
    paths = []
    for folder in ("rtl", "tb", "fw", "constraints"):
        paths += [p for p in (ROOT / folder).rglob("*") if p.is_file()
                  and "__pycache__" not in p.parts]
    paths += [ROOT / "scripts/build_zedboard_aes.tcl",
              ROOT / "scripts/verify_aes_gui.tcl",
              ROOT / "vivado/riscv_soc_lab/riscv_soc_lab.xpr",
              ROOT / "build/zedboard_aes_demo/zedboard_aes_demo.bit"]
    manifest = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in sorted(paths)}
    (OUT / "source_sha256.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Saved integration evidence and {len(manifest)} source/image hashes")


if __name__ == "__main__":
    main()

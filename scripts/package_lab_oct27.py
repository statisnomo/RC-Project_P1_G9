"""Package the October 27 GUI lab delivery; preserve older dated ZIPs."""
from pathlib import Path
import hashlib
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "riscv_soc_project/"
BASE = ROOT / "deliverables/riscv_soc_vivado_gui_aes_2026-10-24.zip"
TARGET = ROOT / "deliverables/riscv_soc_lab_2026-10-27.zip"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    board = ROOT / "build/zedboard_aes_demo"
    summary = (board / "summary.txt").read_text()
    margins = re.search(r"setup slack: ([-.\d]+) ns; hold slack: ([-.\d]+) ns", summary)
    assert margins and all(float(v) >= 0 for v in margins.groups()), "Routed timing must pass"
    assert (board / "zedboard_aes_demo.bit").stat().st_size > 1_000_000

    # The previous archive preserves earlier board-image/report snapshots.
    with zipfile.ZipFile(BASE) as archive:
        data = {item.filename[len(PREFIX):]: archive.read(item)
                for item in archive.infolist()
                if not item.is_dir() and item.filename.startswith(PREFIX)
                and "/.Xil/" not in item.filename
                and not item.filename.endswith("dfx_runtime.txt")}
    for folder in ("rtl", "tb", "fw", "docs", "constraints", "scripts",
                   "evidence/aes_m2_2026-10-27", "output/pdf"):
        for path in (ROOT / folder).rglob("*"):
            if path.is_file() and not any(p in (".Xil", "__pycache__") for p in path.parts):
                if path.name != "dfx_runtime.txt":
                    data[path.relative_to(ROOT).as_posix()] = path.read_bytes()
    for name in ("README.md", "VIVADO_START_HERE.md", "LAB_START_HERE.md",
                 "vivado/riscv_soc_lab/riscv_soc_lab.xpr"):
        data[name] = (ROOT / name).read_bytes()
    for name in ("zedboard_aes_demo.bit", "summary.txt", "timing.rpt",
                 "critical_paths.rpt", "utilization.rpt", "drc.rpt",
                 "routed.dcp", "aes_smoke.hex"):
        data["build/zedboard_aes_demo/" + name] = (board / name).read_bytes()

    data.pop("SHA256SUMS.txt", None)
    data.pop("PACK_CONTENTS.txt", None)
    data["PACK_CONTENTS.txt"] = (
        "Vivado GUI lab pack - 27 October 2026\n"
        "14 simulation sets; CPU-to-AES MMIO integration.\n"
        "Start with docs/lab_2026-10-27.md. No terminal required.\n"
        "ALU, CPU, and CPU+AES bitstreams included, with routed reports.\n"
        "Physical observations remain pending until performed in the lab.\n"
        "SHA256SUMS.txt covers every payload file except itself.\n\n"
        + "\n".join(sorted(data)) + "\n"
    ).encode("utf-8")
    data["SHA256SUMS.txt"] = "".join(
        f"{sha(content)}  {name}\n" for name, content in sorted(data.items())
    ).encode("utf-8")
    temporary = TARGET.with_suffix(".zip.tmp")
    with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for name, content in sorted(data.items()):
            assert ".." not in Path(name).parts and not Path(name).is_absolute()
            archive.writestr(PREFIX + name, content)
    with zipfile.ZipFile(temporary) as archive:
        assert archive.testzip() is None, "ZIP CRC check failed"
        assert len(archive.namelist()) == len(data)
        for name, content in data.items():
            assert sha(archive.read(PREFIX + name)) == sha(content)
    temporary.replace(TARGET)
    TARGET.with_suffix(".zip.sha256").write_text(
        f"{sha(TARGET.read_bytes())}  {TARGET.name}\n", encoding="utf-8")
    print(f"Created {TARGET.name}: {len(data)} files, {TARGET.stat().st_size} bytes; CRC/SHA verified")


if __name__ == "__main__":
    main()

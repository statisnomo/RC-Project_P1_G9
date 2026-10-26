"""Preserve the prior lab evidence and add the verified October 24 AES milestone."""
from pathlib import Path
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "riscv_soc_project/"
BASE = ROOT / "deliverables/riscv_soc_vivado_gui_with_board_refs_2026-10-22.zip"
TARGET = ROOT / "deliverables/riscv_soc_vivado_gui_aes_2026-10-24.zip"

def sha(data):
    return hashlib.sha256(data).hexdigest()

def main():
    # Retain historical board builds and original nine-test evidence.
    with zipfile.ZipFile(BASE) as archive:
        data = {item.filename[len(PREFIX):]: archive.read(item)
                for item in archive.infolist()
                if not item.is_dir() and item.filename.startswith(PREFIX)
                and "/.Xil/" not in item.filename
                and not item.filename.endswith("dfx_runtime.txt")}
    for folder in ("rtl", "tb", "fw", "docs", "constraints", "scripts",
                   "evidence/aes_m1_2026-10-24", "build/aes_synthesis"):
        for path in (ROOT / folder).rglob("*"):
            if path.is_file() and not any(p in (".Xil", "__pycache__") for p in path.parts):
                if path.name != "dfx_runtime.txt":
                    data[path.relative_to(ROOT).as_posix()] = path.read_bytes()
    for name in ("README.md", "VIVADO_START_HERE.md", "LAB_START_HERE.md",
                 "build/vivado_gui_validation/gui_test_summary.txt",
                 "build/reference_review/audit.json",
                 "vivado/riscv_soc_lab/riscv_soc_lab.xpr"):
        data[name] = (ROOT / name).read_bytes()
    data.pop("SHA256SUMS.txt", None)
    data.pop("PACK_CONTENTS.txt", None)
    data["PACK_CONTENTS.txt"] = (
        "Vivado GUI lab pack — 24 October 2026\n"
        "Eleven simulation sets; standalone AES milestone M1.\n"
        "Open VIVADO_START_HERE.md, then docs/aes_core.md.\n"
        "Included ALU/CPU bitstreams do not contain AES. Physical tests pending.\n"
        "SHA256SUMS.txt checks every payload file (excluding itself).\n\n"
        + "\n".join(sorted(data)) + "\n"
    ).encode("utf-8")
    data["SHA256SUMS.txt"] = "".join(
        f"{sha(content)}  {name}\n" for name, content in sorted(data.items())
    ).encode("utf-8")
    temporary = TARGET.with_suffix(".zip.tmp")
    with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for name, content in sorted(data.items()):
            archive.writestr(PREFIX + name, content)
    temporary.replace(TARGET)
    TARGET.with_suffix(".zip.sha256").write_text(
        f"{sha(TARGET.read_bytes())}  {TARGET.name}\n", encoding="utf-8")
    print(f"Created {TARGET.name}: {len(data)} files, {TARGET.stat().st_size} bytes")

if __name__ == "__main__":
    main()

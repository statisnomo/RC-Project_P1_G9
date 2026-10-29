"""Create a separate UART-step ZIP while preserving the accepted lab pack."""
from pathlib import Path, PurePosixPath
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "riscv_soc_project/"
BASE = ROOT / "deliverables/riscv_soc_lab_2026-10-27.zip"
TARGET = ROOT / "deliverables/riscv_soc_uart_step_2026-10-27.zip"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    assert not TARGET.exists(), "Preserve the existing UART delivery; choose a new revision name"
    evidence = ROOT / "evidence/uart_m3_2026-10-27"
    for name, wanted in json.loads((evidence / "source_sha256.json").read_text()).items():
        assert sha((ROOT / name).read_bytes()) == wanted, f"Untested source change: {name}"
    for name, wanted in json.loads((evidence / "artifact_sha256.json").read_text()).items():
        assert sha((evidence / name).read_bytes()) == wanted, f"Changed evidence: {name}"
    with zipfile.ZipFile(BASE) as archive:
        data = {item.filename[len(PREFIX):]: archive.read(item)
                for item in archive.infolist()
                if not item.is_dir() and item.filename.startswith(PREFIX)}
    for folder in ("rtl", "tb", "fw", "docs", "constraints", "scripts",
                   "evidence/uart_m3_2026-10-27"):
        for path in (ROOT / folder).rglob("*"):
            if path.is_file() and not any(p in (".Xil", "__pycache__") for p in path.parts):
                if path.name != "dfx_runtime.txt":
                    data[path.relative_to(ROOT).as_posix()] = path.read_bytes()
    for name in ("README.md", "VIVADO_START_HERE.md", "LAB_START_HERE.md",
                 "build/README.md", "build/SHA256SUMS.txt",
                 "vivado/riscv_soc_lab/riscv_soc_lab.xpr"):
        data[name] = (ROOT / name).read_bytes()
    for path in ROOT.glob("*.wcfg"):
        data[path.name] = path.read_bytes()
    # Copy the exact published artifacts, including the CPU ROM and hash file.
    for line in (ROOT / "build/SHA256SUMS.txt").read_text().splitlines():
        digest, name = line.split("  ", 1)
        payload = (ROOT / "build" / name).read_bytes()
        assert sha(payload) == digest.lower(), name
        data["build/" + name] = payload
    for old in ("PACK_CONTENTS.txt", "SHA256SUMS.txt"):
        data.pop(old, None)
    data["PACK_CONTENTS.txt"] = (
        "UART step - 27 October 2026\n"
        "Start with docs/uart_tx.md. No board or terminal required for the new tests.\n"
        "16 simulation sets; sim_uart_tx is active.\n"
        "Two UART sets and the CPU/CPU-AES board regressions passed in this revision.\n"
        "Original 14-set baseline evidence remains included as a historical snapshot.\n"
        "Three original board images are unchanged; user reported ALU/CPU/AES PASS.\n"
        "UART CPU integration, routed board build, and physical reception are future work.\n"
        "The older printable PDF is the three-image board procedure, not a UART guide.\n"
        "SHA256SUMS.txt covers every payload file except itself.\n\n"
        + "\n".join(sorted(data)) + "\n"
    ).encode("utf-8")
    data["SHA256SUMS.txt"] = "".join(
        f"{sha(payload)}  {name}\n" for name, payload in sorted(data.items())
    ).encode("utf-8")
    temporary = TARGET.with_suffix(".zip.tmp")
    with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for name, payload in sorted(data.items()):
            path = PurePosixPath(name)
            assert not path.is_absolute() and ".." not in path.parts
            archive.writestr(PREFIX + name, payload)
    with zipfile.ZipFile(temporary) as archive:
        assert archive.testzip() is None
        for name, payload in data.items():
            assert sha(archive.read(PREFIX + name)) == sha(payload), name
    temporary.replace(TARGET)
    TARGET.with_suffix(".zip.sha256").write_text(
        f"{sha(TARGET.read_bytes())}  {TARGET.name}\n", encoding="utf-8")
    print(f"Created {TARGET.name}: {len(data)} files, {TARGET.stat().st_size} bytes; CRC/SHA verified")


if __name__ == "__main__":
    main()

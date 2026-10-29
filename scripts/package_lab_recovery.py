"""Package the Vivado 2020 recovery route; never replace a prior delivery."""
from pathlib import Path, PurePosixPath
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "riscv_soc_project/"
BASE = ROOT / "deliverables/riscv_soc_uart_step_2026-10-27.zip"
TARGET = ROOT / "deliverables/riscv_soc_lab_recovery_2026-10-28.zip"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    assert not TARGET.exists(), "Use a new revision name rather than replace a delivery"
    evidence = ROOT / "evidence/lab_sim_recovery_2026-10-28"
    for name, expected in json.loads((evidence / "source_sha256.json").read_text()).items():
        assert sha((ROOT / name).read_bytes()) == expected, f"Untested source: {name}"
    for name, expected in json.loads((evidence / "artifact_sha256.json").read_text()).items():
        assert sha((evidence / name).read_bytes()) == expected, f"Changed evidence: {name}"
    with zipfile.ZipFile(BASE) as archive:
        data = {item.filename[len(PREFIX):]: archive.read(item)
                for item in archive.infolist()
                if not item.is_dir() and item.filename.startswith(PREFIX)}
    for name, payload in data.items():
        if name.startswith(("rtl/", "fw/", "constraints/")):
            assert sha((ROOT / name).read_bytes()) == sha(payload), f"Unexpected hardware change: {name}"
    for folder in ("rtl", "tb", "fw", "docs", "constraints", "scripts",
                   "evidence/lab_sim_recovery_2026-10-28"):
        for path in (ROOT / folder).rglob("*"):
            if path.is_file() and not any(p in (".Xil", "__pycache__") for p in path.parts):
                if path.name != "dfx_runtime.txt":
                    data[path.relative_to(ROOT).as_posix()] = path.read_bytes()
    for name in ("README.md", "VIVADO_START_HERE.md", "LAB_START_HERE.md",
                 "vivado/riscv_soc_lab/riscv_soc_lab.xpr"):
        data[name] = (ROOT / name).read_bytes()
    # Board artifacts are preserved from the working UART/lab pack.
    for line in data["build/SHA256SUMS.txt"].decode("utf-8").splitlines():
        digest, name = line.split("  ", 1)
        assert sha(data["build/" + name]) == digest.lower(), name
    for old in ("PACK_CONTENTS.txt", "SHA256SUMS.txt"):
        data.pop(old, None)
    data["PACK_CONTENTS.txt"] = (
        "Lab simulation recovery - 28 October 2026\n"
        "START: docs/lab_simulation_recovery.md\n"
        "Lab Vivado 2020: Tools > Run Tcl Script > scripts/create_lab_compat_project.tcl\n"
        "The script creates a fresh project in the running Vivado version and leaves it open.\n"
        "Retest sim_cpu_core, sim_aes_core, sim_aes_mmio, sim_soc_aes first.\n"
        "Local verification: Vivado 2025.2; 16 normal tests plus 6 data-diagnostic scenarios.\n"
        "Vivado 2020 execution remains to be confirmed at the lab.\n"
        "Hardware RTL and the three previously working bitstreams are unchanged by this recovery.\n"
        "Previous milestone evidence and printable board guide are historical snapshots.\n"
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

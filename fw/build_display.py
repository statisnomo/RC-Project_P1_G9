"""Build the development RV32I ROM. Uses GNU binutils; ships a ready .hex."""
from pathlib import Path
import argparse, os, subprocess, tempfile
p = argparse.ArgumentParser()
p.add_argument("--prefix", default=os.environ.get("RISCV_PREFIX", "riscv64-unknown-elf-"),
               help="GNU tool prefix, including optional path and final hyphen")
prefix = p.parse_args().prefix
fw = Path(__file__).resolve().parent
with tempfile.TemporaryDirectory() as tmp:
    def run(tool, *args): subprocess.run([prefix + tool, *args], cwd=tmp, check=True)
    run("as", "-march=rv32i", "-mabi=ilp32", "-mno-relax", "-o", "main.o", fw/"src/display.S")
    run("ld", "-m", "elf32lriscv", "--no-relax", "-Ttext=0", "-e", "_start", "-o", "main.elf", "main.o")
    run("objcopy", "-O", "binary", "-j", ".text", "main.elf", "main.bin")
    code = (Path(tmp)/"main.bin").read_bytes()
if not (0 < len(code) <= 4096 and len(code) % 4 == 0):
    raise ValueError("Program must fit 4 KiB Harvard ROM")
data = code.ljust(4096, b'\0')
(fw/"display.hex").write_bytes(''.join(f'{int.from_bytes(data[i:i+4],"little"):08x}\n'
                                      for i in range(0,4096,4)).encode())
print(f"Development ROM: {len(code)} / 4096 bytes")

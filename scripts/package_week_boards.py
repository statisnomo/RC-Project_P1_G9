"""Create the self-contained Nov 3 GUI/board lab kit, without cached Vivado runs."""
from pathlib import Path
import sys
from zipfile import ZipFile, ZIP_DEFLATED
from hashlib import sha256
root = Path(__file__).resolve().parents[1]
source_only = sys.argv[1:] == ['--sources-only']
assert not sys.argv[1:] or source_only
archive = root / 'deliverables' / ('riscv_soc_lab_2026-11-03_sources.zip' if source_only else 'riscv_soc_lab_2026-11-03.zip')
archive.parent.mkdir(exist_ok=True)
files = {}
def add(path, dest=None):
    p = root / path
    assert p.is_file(), p
    files[dest or p.relative_to(root).as_posix()] = p.read_bytes()
for path in ('LAB_THIS_WEEK.md', 'LAB_THIS_WEEK.html', 'docs/lab_record_2026-11-03.txt', 'fw/src/keypad_aes.S', 'fw/build_keypad_aes.py','fw/keypad_aes.hex',
             'scripts/add_keypad_to_project.tcl', 'scripts/create_week_board_common.tcl',
             'scripts/create_keypad_board_project.tcl', 'scripts/create_oled_board_project.tcl',
             'docs/keypad_scanner.md','docs/keypad_mmio.md','rtl/soc/soc_minimal.v'):
    add(path)
for sub in ('rtl/mem','rtl/cpu','rtl/crypto'):
    for path in (root/sub).iterdir():
        if path.suffix in ('.v','.vh'): add(path)
for stem in ('keypad_scanner','keypad_mmio'):
    add(f'rtl/peripherals/{stem}.v')
    add(f'tb/peripherals/tb_{stem}.v')
add('tb/peripherals/keypad_matrix_model.v')
for stem in ('keypad_aes','oled_pattern'):
    top = 'zedboard_'+stem
    for path in (f'rtl/board/{top}.v',f'constraints/{top}.xdc',f'tb/board/tb_{stem}.v'): add(path)
    if not source_only: add(f'build/{top}/{top}.bit',f'prebuilt/{top}.bit')
for p in (root/'evidence/week_2026-11-03').rglob('*'):
    if p.is_file() and p.suffix in ('.rpt','.log','.md'): add(p)
assert len([p for p in files if p.endswith('.bit')]) == (0 if source_only else 2)
assert source_only or len([p for p in files if p.endswith('timing.rpt')]) == 2
files['SHA256SUMS.txt'] = ''.join(f'{sha256(data).hexdigest()}  {path}\n' for path,data in sorted(files.items())).encode()
with ZipFile(archive,'w',ZIP_DEFLATED) as z:
    for path,data in sorted(files.items()): z.writestr(path,data)
with ZipFile(archive) as z:
    assert z.testzip() is None
    assert all(z.read(path)==data for path,data in files.items())
digest = sha256(archive.read_bytes()).hexdigest()
archive.with_suffix('.zip.sha256').write_text(f'{digest}  {archive.name}\n', encoding='ascii')
print(f'{archive}: {len(files)} verified entries, {archive.stat().st_size} bytes. SHA256 {digest}')



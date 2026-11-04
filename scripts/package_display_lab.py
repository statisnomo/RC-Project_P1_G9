"""Package only the combined JA/JC build after checking simulation and pin evidence."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from hashlib import sha256
import re

root=Path(__file__).resolve().parents[1]
evidence=root/'evidence/display_candidate_2026-11-04'
pinmap={'cs_n':'AB7','mosi':'AB6','sclk':'AA4','dc':'R6','res_n':'T6','vbat_n':'T4','vdd_n':'U4','tx':'V7'}
report=(evidence/'pins.rpt').read_text()
xdc=(root/'constraints/zedboard_display.xdc').read_text()
for port,pin in pinmap.items():
    assert re.search(r'\|\s*'+pin+r'\s*\|\s*'+port+r'\s*\|',report), (port,pin,'implemented pin')
    assert re.search(r'PACKAGE_PIN\s+'+pin+r'\s+\[get_ports\s+\{?'+port+r'\}?\]',xdc), (port,pin,'XDC')
for top in ('tb_oled_access','tb_display_system','tb_display_board'):
    s=(evidence/(top+'.log')).read_text()
    assert 'PASS '+top+':' in s and 'FAIL' not in s
assert 'All user specified timing constraints are met.' in (evidence/'timing.rpt').read_text()
assert (evidence/'summary.txt').is_file()
files={}
def add(p,dest=None):
    p=root/p
    files[dest or p.relative_to(root).as_posix()]=p.read_bytes()
for path in ('NEXT_LAB_COMBINED.md','NEXT_LAB_COMBINED.html','fw/display.hex','fw/build_display.py',
             'fw/src/display.S','docs/oled_hex.md','rtl/board/zedboard_display.v',
             'rtl/soc/soc_display.v','rtl/soc/soc_minimal.v','constraints/zedboard_display.xdc',
             'tb/peripherals/keypad_matrix_model.v','scripts/build_display_candidate.tcl'):
    add(path)
for d in ('rtl/cpu','rtl/mem','rtl/crypto','rtl/peripherals','tb/internal'):
    for p in (root/d).iterdir():
        if p.suffix in ('.v','.vh','.sv'):add(p)
for p in evidence.iterdir():
    if p.suffix in ('.txt','.rpt','.log','.md'):add(p)
add('build/display_candidate/zedboard_display.bit','prebuilt/zedboard_display_ja_jc.bit')
files['SHA256SUMS.txt']=''.join(f'{sha256(v).hexdigest()}  {k}\n' for k,v in sorted(files.items())).encode()
archive=root/'deliverables/riscv_soc_combined_ja_jc_2026-11-05.zip'
with ZipFile(archive,'w',ZIP_DEFLATED) as z:
    for name,data in files.items():z.writestr(name,data)
with ZipFile(archive) as z:
    assert z.testzip() is None
    assert all(z.read(k)==v for k,v in files.items())
archive.with_suffix('.zip.sha256').write_text(sha256(archive.read_bytes()).hexdigest()+'  '+archive.name+'\n')
print(f'{archive}: {len(files)} files, {archive.stat().st_size} bytes; checked JC/JD pin report and ZIP hashes')

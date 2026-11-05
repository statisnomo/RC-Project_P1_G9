"""Standalone onboard OLED kit. Never replaces the working external-OLED ZIP."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from hashlib import sha256
import json, re, subprocess, sys

root=Path(__file__).resolve().parents[1]
evidence=root/'evidence/display_onboard_2026-11-05'
manifest_name='evidence/display_onboard_2026-11-05/source_hashes.json'
subprocess.run([sys.executable,str(root/'scripts/release_manifest.py'),'check',manifest_name],check=True)
pins={'mosi':'AA12','sclk':'AB12','dc':'U10','res_n':'U9','vbat_n':'U11','vdd_n':'U12','tx':'V7'}
report=(evidence/'pins.rpt').read_text()
xdc=(root/'constraints/zedboard_display_onboard.xdc').read_text()
for port,pin in pins.items():
    assert re.search(r'\|\s*'+pin+r'\s*\|\s*'+port+r'\s*\|',report), (port,pin)
    assert re.search(r'PACKAGE_PIN\s+'+pin+r'\s+\[get_ports\s+\{?'+port+r'\}?\]',xdc), (port,pin)
assert not re.search(r'\|\s*cs_n\s*\|',report) and 'cs_n' not in xdc
tops=('tb_oled_access','tb_display_system','tb_display_board','tb_display_recovery',
      'tb_display_bus','tb_display_repeat','tb_display_onboard')
for top in tops:
    s=(evidence/(top+'.log')).read_text()
    assert 'PASS '+top+':' in s and 'FAIL' not in s
assert 'All user specified timing constraints are met.' in (evidence/'timing.rpt').read_text()
assert 'Seven simulations passed.' in (evidence/'summary.txt').read_text()
files={}
def add(name,dest=None):
    files[dest or name]=(root/name).read_bytes()
for name in ('LAB_ONBOARD_OLED.md','LAB_ONBOARD_OLED.html','LAB_UART_OPTIONAL.md','LAB_UART_OPTIONAL.html',
    'docs/lab_ten_blocks.md','docs/lab_ten_blocks.html','docs/display_lab_vectors.json',
    'docs/lab_results_2026-11-05.md','docs/onboard_display.md','docs/oled_hex.md',
    'fw/display.hex','fw/src/display.S','fw/build_display.py',
    'rtl/board/zedboard_display.v','rtl/board/zedboard_display_onboard.v',
    'rtl/soc/soc_minimal.v','rtl/soc/soc_display.v','constraints/zedboard_display_onboard.xdc',
    'tb/peripherals/keypad_matrix_model.v','tb/internal/display_lab_vectors.mem',
    'scripts/build_display_onboard.tcl','scripts/release_manifest.py'):
    add(name)
for folder in ('rtl/cpu','rtl/mem','rtl/crypto','rtl/peripherals'):
    for p in (root/folder).iterdir():
        if p.suffix in ('.v','.vh'):add(p.relative_to(root).as_posix())
for top in tops:add('tb/internal/'+top+'.sv')
for p in evidence.iterdir():
    if p.suffix in ('.txt','.rpt','.log','.json','.md'):add(p.relative_to(root).as_posix())
add('build/display_onboard/zedboard_display_onboard.bit','prebuilt/zedboard_display_onboard.bit')
record=json.loads(files[manifest_name])
record={k:v for k,v in record.items() if k in files}
assert all(sha256(files[k].replace(b'\r\n',b'\n')).hexdigest()==v for k,v in record.items())
files[manifest_name]=(json.dumps(record,indent=2)+'\n').encode()
files['SHA256SUMS.txt']=''.join(f'{sha256(v).hexdigest()}  {k}\n' for k,v in sorted(files.items())).encode()
archive=root/'deliverables/riscv_soc_onboard_oled_2026-11-05.zip'
with ZipFile(archive,'w',ZIP_DEFLATED) as z:
    for name,data in files.items():z.writestr(name,data)
with ZipFile(archive) as z:
    assert z.testzip() is None and all(z.read(k)==v for k,v in files.items())
archive.with_suffix('.zip.sha256').write_text(sha256(archive.read_bytes()).hexdigest()+'  '+archive.name+'\n')
print(f'{archive}: {len(files)} files, {archive.stat().st_size} bytes; onboard pin report, source and ZIP hashes checked')

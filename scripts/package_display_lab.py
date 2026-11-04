"""Package only the combined JA/JC build after checking simulation and pin evidence."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from hashlib import sha256
import re, json, subprocess, sys

root=Path(__file__).resolve().parents[1]
evidence=root/'evidence/display_hardened_2026-11-05'
subprocess.run([sys.executable, str(root/'scripts/release_manifest.py'), 'check',
                'evidence/display_hardened_2026-11-05/source_hashes.json'], check=True)
pinmap={'cs_n':'AB7','mosi':'AB6','sclk':'AA4','dc':'R6','res_n':'T6','vbat_n':'T4','vdd_n':'U4','tx':'V7'}
report=(evidence/'pins.rpt').read_text()
xdc=(root/'constraints/zedboard_display.xdc').read_text()
for port,pin in pinmap.items():
    assert re.search(r'\|\s*'+pin+r'\s*\|\s*'+port+r'\s*\|',report), (port,pin,'implemented pin')
    assert re.search(r'PACKAGE_PIN\s+'+pin+r'\s+\[get_ports\s+\{?'+port+r'\}?\]',xdc), (port,pin,'XDC')
for top in ('tb_oled_access','tb_display_system','tb_display_board','tb_display_recovery','tb_display_bus','tb_display_repeat'):
    s=(evidence/(top+'.log')).read_text()
    assert 'PASS '+top+':' in s and 'FAIL' not in s
assert 'All user specified timing constraints are met.' in (evidence/'timing.rpt').read_text()
assert (evidence/'summary.txt').is_file()
baseline=(root/'evidence/release_regression_2026-11-05/summary.txt').read_text()
assert len(re.findall(r'^PASS ',baseline,re.M))==20
files={}
def add(p,dest=None):
    p=root/p
    files[dest or p.relative_to(root).as_posix()]=p.read_bytes()
for path in ('NEXT_LAB_COMBINED.md','NEXT_LAB_COMBINED.html','LAB_UART_OPTIONAL.md','LAB_UART_OPTIONAL.html',
             'docs/lab_ten_blocks.md','docs/lab_ten_blocks.html','docs/display_lab_vectors.json','docs/lab_record_combined.txt',
             'docs/release_2026-11-05.md','docs/board_io_plan.md','fw/display.hex','fw/build_display.py',
             'fw/src/display.S','docs/oled_hex.md','rtl/board/zedboard_display.v',
             'rtl/soc/soc_display.v','rtl/soc/soc_minimal.v','constraints/zedboard_display.xdc',
             'tb/peripherals/keypad_matrix_model.v','scripts/build_display_candidate.tcl',
             'scripts/release_manifest.py','scripts/generate_lab_vectors.ps1'):
    add(path)
for d in ('rtl/cpu','rtl/mem','rtl/crypto','rtl/peripherals','tb/internal'):
    for p in (root/d).iterdir():
        if p.suffix in ('.v','.vh','.sv','.mem'):add(p)
for p in evidence.iterdir():
    if p.suffix in ('.txt','.rpt','.log','.md','.json'):add(p)
add('evidence/release_regression_2026-11-05/summary.txt')
add('build/display_hardened/zedboard_display.bit','prebuilt/zedboard_display_ja_jc.bit')
# The repository manifest also includes older board tops. The standalone kit
# keeps only its own source entries, without changing any recorded hashes.
manifest_name='evidence/display_hardened_2026-11-05/source_hashes.json'
record=json.loads(files[manifest_name])
files[manifest_name]=(json.dumps({k:v for k,v in record.items() if k in files},indent=2)+'\n').encode()
assert all(sha256(files[k].replace(b'\r\n',b'\n')).hexdigest()==v for k,v in json.loads(files[manifest_name]).items())
files['SHA256SUMS.txt']=''.join(f'{sha256(v).hexdigest()}  {k}\n' for k,v in sorted(files.items())).encode()
archive=root/'deliverables/riscv_soc_hardened_ja_jc_2026-11-05.zip'
with ZipFile(archive,'w',ZIP_DEFLATED) as z:
    for name,data in files.items():z.writestr(name,data)
with ZipFile(archive) as z:
    assert z.testzip() is None
    assert all(z.read(k)==v for k,v in files.items())
archive.with_suffix('.zip.sha256').write_text(sha256(archive.read_bytes()).hexdigest()+'  '+archive.name+'\n')
print(f'{archive}: {len(files)} files, {archive.stat().st_size} bytes; checked JC/JD pin report and ZIP hashes')

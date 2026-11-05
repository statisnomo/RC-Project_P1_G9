"""Package the verified development benchmark separately from physical lab kits."""
from pathlib import Path
from hashlib import sha256
from zipfile import ZipFile,ZIP_DEFLATED
import json
root=Path(__file__).resolve().parents[1]
evidence=root/'evidence/benchmark_2026-11-05'
tops=('tb_benchmark_timer','tb_aes_benchmark','tb_benchmark_recovery')
for top in tops:
    log=(evidence/(top+'.log')).read_text()
    assert 'PASS '+top+':' in log and 'FAIL' not in log
manifest=json.loads((root/'fw/benchmark_manifest.json').read_text())
for name,want in manifest['source_hashes'].items():
    assert sha256((root/name).read_bytes().replace(b'\r\n',b'\n')).hexdigest()==want,name
# The generated ROM is LF text; Windows Git checkouts may use CRLF.
assert sha256((root/'fw/benchmark.hex').read_bytes().replace(b'\r\n',b'\n')).hexdigest()==manifest['rom_sha256']
files={}
def add(name):files[name]=(root/name).read_bytes()
for folder in ('rtl/cpu','rtl/mem','rtl/crypto'):
    for p in (root/folder).iterdir():
        if p.suffix in ('.v','.vh'):add(p.relative_to(root).as_posix())
for name in ('rtl/soc/soc_minimal.v','rtl/soc/soc_benchmark.v','rtl/peripherals/benchmark_timer.v',
             'fw/benchmark.hex','fw/benchmark_manifest.json','fw/build_benchmark.py','fw/linker/benchmark.ld',
             'fw/src/aes_software.c','fw/src/benchmark.c','tb/internal/benchmark_vectors.mem',
             'tb/crypto/vectors/aes128_kat.mem','docs/benchmark.md','docs/presentation_plan.md',
             'docs/presentation_demo.html','scripts/verify_benchmark.tcl','scripts/build_presentation_demo.py',
             'scripts/templates/presentation_demo.html','scripts/check_presentation_demo.cjs',
             'scripts/generate_benchmark_vectors.ps1'):
    add(name)
for top in tops:add('tb/internal/'+top+'.sv')
source={name:sha256(data.replace(b'\r\n',b'\n')).hexdigest() for name,data in files.items()
        if name.startswith(('rtl/','fw/','tb/'))}
(evidence/'source_hashes.json').write_text(json.dumps(source,indent=2)+'\n')
for p in evidence.iterdir():
    if p.suffix in ('.log','.json','.md','.txt'):add(p.relative_to(root).as_posix())
files['START_HERE.md']=b'''# Software-versus-hardware benchmark: development kit

Start with docs/benchmark.md for Vivado GUI tests 28-30.
Open docs/presentation_demo.html in a browser for recorded simulation results.
This ZIP contains no bitstream: live OLED benchmark integration is still next.
Your existing physical display lab kit remains the board-testing baseline.
'''
files['SHA256SUMS.txt']=''.join(f'{sha256(v).hexdigest()}  {k}\n' for k,v in sorted(files.items())).encode()
dest=root/'deliverables/riscv_soc_benchmark_dev_2026-11-06.zip'
with ZipFile(dest,'w',ZIP_DEFLATED) as z:
    for name,data in files.items():z.writestr(name,data)
with ZipFile(dest) as z:
    assert z.testzip() is None
    for name,data in files.items():assert z.read(name)==data
dest.with_suffix('.zip.sha256').write_text(sha256(dest.read_bytes()).hexdigest()+'  '+dest.name+'\n')
print(f'{len(files)} files; source hashes checked; development ZIP: {dest}')

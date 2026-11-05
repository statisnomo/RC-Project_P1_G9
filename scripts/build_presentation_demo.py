"""Build an offline presenter view using saved, verified simulation evidence."""
from pathlib import Path
import hashlib,json,re
root=Path(__file__).resolve().parents[1]
log=(root/'evidence/benchmark_2026-11-05/tb_aes_benchmark.log').read_text()
assert 'PASS tb_aes_benchmark:' in log and 'FAIL' not in log
pattern=r'BENCHMARK_CASE_PASS waits=(\d+) vectors=(\d+) sw_cycles=(\d+)\.\.(\d+) hw_cycles=(\d+)\.\.(\d+) flips=(\d+) changed_bits=(\d+)\.\.(\d+) sum=(\d+) reset_restart=PASS'
modes=[]
for row in re.findall(pattern,log):
    w,n,slo,shi,hlo,hhi,nflip,lo,hi,total=map(int,row)
    assert n==413 and slo==shi and hlo==hhi and nflip==128
    modes.append(dict(waits=w,software=slo,hardware=hlo,speedup=slo/hlo))
assert [v['waits'] for v in modes]==[1,5]
records=(root/'tb/internal/benchmark_vectors.mem').read_text().splitlines()
assert len(records)==413
base=records[284]
flips=[]
for bit,row in enumerate(records[285:]):
    assert row[:32]==base[:32] and (int(row[32:64],16)^int(base[32:64],16)).bit_count()==1
    diff=int(row[64:],16)^int(base[64:],16)
    flips.append(dict(bit=bit,plaintext=row[32:64],ciphertext=row[64:],changed=diff.bit_count()))
counts=[v['changed'] for v in flips]
assert (min(counts),max(counts),sum(counts))==(lo,hi,total)
data=dict(date='2026-11-05',source='Vivado 2025.2 behavioral simulation',modes=modes,
          key=base[:32],plaintext=base[32:64],ciphertext=base[64:],flips=flips,
          flipped_bits_min=lo,flipped_bits_max=hi,flipped_bits_mean=total/128,
          blocks_per_mode=413,log_sha256=hashlib.sha256(log.encode()).hexdigest())
template=(root/'scripts/templates/presentation_demo.html').read_text(encoding='utf-8')
assert template.count('__VERIFIED_DATA__')==1
(root/'docs/presentation_demo.html').write_text(template.replace('__VERIFIED_DATA__',json.dumps(data,separators=(',',':'))),encoding='utf-8')
(root/'evidence/benchmark_2026-11-05/results.json').write_text(json.dumps(data,indent=2)+'\n')
print('Built offline presentation from 826 checked comparisons and 128 one-bit input changes.')

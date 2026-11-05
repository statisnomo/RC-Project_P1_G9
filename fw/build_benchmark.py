"""Compile a separate 4 KiB RV32I benchmark ROM; never replaces display.hex."""
from pathlib import Path
import argparse, hashlib, json, os, re, subprocess, tempfile

root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--prefix',default=os.environ.get('RISCV_PREFIX','riscv64-unknown-elf-'))
a=p.parse_args()
flags=['-march=rv32i','-mabi=ilp32','-mno-relax','-msmall-data-limit=0',
       '-Os','-ffreestanding','-fno-builtin','-fno-pic','-fno-stack-protector',
       '-fno-unwind-tables','-fno-asynchronous-unwind-tables','-fstack-usage']

def mul(a,b):
    r=0
    for _ in range(8):
        if b&1:r^=a
        a=((a<<1) ^ (0x11b if a&128 else 0))&255;b>>=1
    return r
def sbox(x):
    inv=0 if x==0 else 1
    if x:
        for _ in range(254):inv=mul(inv,x)
    return inv ^ ((inv<<1|inv>>7)&255) ^ ((inv<<2|inv>>6)&255) ^ ((inv<<3|inv>>5)&255) ^ ((inv<<4|inv>>4)&255) ^ 0x63

table=bytes(sbox(i) for i in range(256))
assert table[:4]==bytes.fromhex('637c777b') and table[0x53]==0xed
start=['.section .text.start','.global _start','_start:','li sp,0x2000',
       'li t0,0x1000','li t1,0x1200','1: sw zero,0(t0)','addi t0,t0,4','bltu t0,t1,1b',
       'li t0,0x1100']
for i in range(0,256,4):
    start += [f'li t1,0x{int.from_bytes(table[i:i+4],"little"):08x}',f'sw t1,{i}(t0)']
start += ['call main','2: j 2b']
out=root/'build/benchmark_firmware';out.mkdir(parents=True,exist_ok=True)
workdir=None
def run(tool,*args):
    return subprocess.check_output([a.prefix+tool,*map(str,args)],text=True,cwd=workdir)
with tempfile.TemporaryDirectory() as tmp:
    tmp=Path(tmp);workdir=tmp;asm=tmp/'startup.S';asm.write_text('\n'.join(start)+'\n')
    # This bundled Windows GCC loses quoting in subprocess paths with spaces.
    # Compile local filenames in a temporary directory instead.
    for name in ('aes_software.c','benchmark.c'):
        (tmp/name).write_bytes((root/'fw/src'/name).read_bytes())
    (tmp/'benchmark.ld').write_bytes((root/'fw/linker/benchmark.ld').read_bytes())
    objects=[]
    for name in ('startup.S','aes_software.c','benchmark.c'):
        obj=Path(name).stem+'.o';run('gcc',*flags,'-c',name,'-o',obj);objects.append(obj)
    elf=tmp/'benchmark.elf'
    run('gcc',*flags,'-nostdlib','-Wl,--no-relax','-Wl,-T,benchmark.ld',*objects,'-o','benchmark.elf')
    binary=tmp/'benchmark.bin';run('objcopy','-O','binary','-j','.text','benchmark.elf','benchmark.bin')
    code=binary.read_bytes();assert 0<len(code)<=4096 and len(code)%4==0
    disasm=run('objdump','-d','-M','no-aliases','benchmark.elf')
    allowed=set('add sub sll slt sltu xor srl sra or and addi slti sltiu xori ori andi slli srli srai lui auipc jal jalr beq bne blt bge bltu bgeu lb lh lw lbu lhu sb sh sw'.split())
    instructions=re.findall(r'^\s*[0-9a-f]+:\s+[0-9a-f]{8}\s+(\S+)',disasm,re.M)
    assert instructions and not set(instructions)-allowed,set(instructions)-allowed
    (out/'benchmark.dis').write_text(disasm)
    (out/'benchmark.elf').write_bytes(elf.read_bytes())
    stack=''.join(f.read_text() for f in tmp.glob('*.su'))
    (out/'stack_usage.txt').write_text(stack)
workdir=None
data=code.ljust(4096,b'\0')
rom=''.join(f'{int.from_bytes(data[i:i+4],"little"):08x}\n' for i in range(0,4096,4)).encode()
(root/'fw/benchmark.hex').write_bytes(rom)
manifest={'compiler':run('gcc','--version').splitlines()[0],'flags':flags,'code_bytes':len(code),
          'rom_bytes':4096,'rom_sha256':hashlib.sha256(rom).hexdigest(),
          'instruction_mnemonics':sorted(set(instructions)),'stack_usage':stack,
          'source_hashes':{f:hashlib.sha256((root/f).read_bytes().replace(b'\r\n',b'\n')).hexdigest()
           for f in ('fw/src/aes_software.c','fw/src/benchmark.c','fw/linker/benchmark.ld','fw/build_benchmark.py')}}
(root/'fw/benchmark_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(f'Benchmark ROM: {len(code)}/4096 bytes; {len(instructions)} audited RV32I instructions')
print(stack)

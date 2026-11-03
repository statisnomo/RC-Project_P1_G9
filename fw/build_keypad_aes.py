"""Encode only the RV32I forms in keypad_aes.S. The lab uses the shipped ROM."""
from pathlib import Path
import re

root = Path(__file__).resolve().parent
code, labels = [], {}
for line in (root / 'src/keypad_aes.S').read_text().splitlines():
    line = line.partition('#')[0].strip()
    if not line:
        continue
    if line.endswith(':'):
        assert line[:-1] not in labels
        labels[line[:-1]] = len(code)*4
        continue
    op, *args = re.findall(r'[\w-]+', line)
    if op == 'li':
        dest, val = args
        val = int(val, 0)
        hi = (val + 2048) >> 12
        code.extend([('lui', dest, str(hi & 0xfffff)), ('addi', dest, dest, str(val-(hi<<12)))])
    else:
        code.append((op,*args))

def reg(s):
    assert re.fullmatch(r'x(?:[0-9]|[12][0-9]|3[01])', s)
    return int(s[1:])

def imm(s):
    v = int(s, 0)
    assert -2048 <= v < 2048
    return v & 4095

def encode(pc, op, d, a, b=None):
    rd = reg(d)
    if op == 'lui':
        assert 0 <= int(a,0) < 2**20
        return int(a,0)<<12 | rd<<7 | 0x37
    if op in ('beq','bne'):
        off = labels[b]-pc
        assert off%4==0 and -4096<=off<4096
        return ((off>>12&1)<<31 | (off>>5&63)<<25 | reg(a)<<20 | rd<<15 |
                (op=='bne')<<12 | (off>>1&15)<<8 | (off>>11&1)<<7 | 0x63)
    if op in ('lw','lbu','sw','sb'):
        n, base = imm(a), reg(b)
        if op in ('lw','lbu'):
            return n<<20 | base<<15 | (2 if op=='lw' else 4)<<12 | rd<<7 | 3
        return (n>>5)<<25 | rd<<20 | base<<15 | (2 if op=='sw' else 0)<<12 | (n&31)<<7 | 0x23
    if op in ('add','or'):
        return reg(b)<<20 | reg(a)<<15 | (6 if op=='or' else 0)<<12 | rd<<7 | 0x33
    if op in ('srli','slli'):
        assert 0 <= int(b,0) < 32
    return imm(b)<<20 | reg(a)<<15 | {'addi':0,'andi':7,'slli':1,'srli':5}[op]<<12 | rd<<7 | 0x13

words = [encode(i*4,*inst) for i,inst in enumerate(code)]
assert len(words)<=1024
(root/'keypad_aes.hex').write_text(''.join(f'{w:08x}\n' for w in words+[0]*(1024-len(words))), encoding='ascii')

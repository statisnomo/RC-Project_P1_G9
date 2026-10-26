"""Generate reproducible programs and independent architectural expectations.

No RTL controls are imported. This interpreter uses literal RISC-V encodings.
Generated files are committed inputs: running HDL tests needs no Python/toolchain.
"""
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tb" / "programs"
OUT.mkdir(exist_ok=True)
MASK = 0xFFFFFFFF

def sx(x, bits):
    return (x & ((1 << (bits - 1)) - 1)) - (x & (1 << (bits - 1)))

def i(op, rd, f3, rs1, imm):
    return ((imm & 4095) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op

def r(rd, f3, rs1, rs2, f7=0):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0x33

def s(f3, rs1, rs2, imm):
    return ((imm & 0xFE0) << 20) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | ((imm & 31) << 7) | 0x23

def b(f3, rs1, rs2, imm):
    return ((imm & 0x1000) << 19) | ((imm & 0x7E0) << 20) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | ((imm & 30) << 7) | ((imm & 0x800) >> 4) | 0x63

def j(rd, imm):
    return ((imm & 0x100000) << 11) | ((imm & 0x7FE) << 20) | ((imm & 0x800) << 9) | (imm & 0xFF000) | (rd << 7) | 0x6F

def u(op, rd, imm):
    return (imm << 12) | (rd << 7) | op

def addi(rd, rs, imm): return i(0x13, rd, 0, rs, imm)
def lui(rd, imm): return u(0x37, rd, imm)
def lw(rd, rs, imm=0): return i(3, rd, 2, rs, imm)
def sw(rs, base=1, imm=0): return s(2, base, rs, imm)

class Program:
    def __init__(self):
        self.words = {}
        self.pc = 0
        self.labels = {}
        self.fixups = []
    def emit(self, *words):
        for word in words:
            assert self.pc % 4 == 0 and 0 <= self.pc < 4096
            assert self.pc not in self.words
            self.words[self.pc] = word
            self.pc += 4
        return self
    def label(self, name): self.labels[name] = self.pc
    def branch(self, f3, a, c, label):
        self.fixups.append((self.pc, lambda off: b(f3, a, c, off), label))
        self.emit(0)
    def jump(self, rd, label):
        self.fixups.append((self.pc, lambda off: j(rd, off), label))
        self.emit(0)
    def finish(self):
        for pc, encode, label in self.fixups:
            self.words[pc] = encode(self.labels[label] - pc)
        return self.words

coverage = set()
def interpret(program):
    regs, ram, scratch = [0]*32, [0]*1024, [0]*4
    pc, reads = 0, 0
    trace, transfers = [], []
    for _ in range(5000):
        if pc & 3: return trace, transfers, regs, ram, (2, pc, pc)
        if not 0 <= pc < 4096: return trace, transfers, regs, ram, (3, pc, pc)
        ins = program.get(pc, 0)
        op, rd, f3, a, c, f7 = ins & 127, (ins >> 7) & 31, (ins >> 12) & 7, (ins >> 15) & 31, (ins >> 20) & 31, ins >> 25
        av, cv, imm = regs[a], regs[c], sx(ins >> 20, 12)
        nxt, write, val, name = (pc + 4) & MASK, False, 0, ""
        fault = None
        if op in (0x13, 0x33):
            rhs = cv if op == 0x33 else imm & MASK
            sh = rhs & 31
            sub = op == 0x33 and f7 == 0x20 and f3 == 0
            arith = f3 == 5 and f7 == 0x20
            legal = (op == 0x33 and (f7 == 0 or (f7 == 0x20 and f3 in (0, 5)))) or (op == 0x13 and (f3 not in (1, 5) or f7 == 0 or (f3 == 5 and f7 == 0x20)))
            if legal:
                if f3 == 0: val, name = (av - rhs, "SUB") if sub else (av + rhs, "ADD")
                elif f3 == 1: val, name = av << sh, "SLL"
                elif f3 == 2: val, name = int(sx(av,32) < sx(rhs,32)), "SLT"
                elif f3 == 3: val, name = int(av < rhs), "SLTU"
                elif f3 == 4: val, name = av ^ rhs, "XOR"
                elif f3 == 5: val, name = (sx(av,32) >> sh, "SRA") if arith else (av >> sh, "SRL")
                elif f3 == 6: val, name = av | rhs, "OR"
                else: val, name = av & rhs, "AND"
                if op == 0x13: name += "I" if name != "SLTU" else "" # SLTIU spelling below
                if op == 0x13 and f3 == 3: name = "SLTIU"
                write = True
        elif op in (0x37, 0x17):
            val = (ins & 0xFFFFF000) + (pc if op == 0x17 else 0)
            write, name = True, "AUIPC" if op == 0x17 else "LUI"
        elif op == 0x6F or (op == 0x67 and f3 == 0):
            off = sx(((ins >> 31) << 20) | (ins & 0xFF000) | (((ins >> 20) & 1) << 11) | (((ins >> 21) & 1023) << 1),21)
            nxt = (pc + off) & MASK if op == 0x6F else ((av + imm) & MASK) & ~1
            write, val, name = True, pc + 4, "JAL" if op == 0x6F else "JALR"
            if nxt & 3: fault = (2, pc, nxt)
        elif op == 0x63 and f3 in (0,1,4,5,6,7):
            off = sx(((ins >> 31) << 12) | (((ins >> 7) & 1) << 11) | (((ins >> 25) & 63) << 5) | (((ins >> 8) & 15) << 1),13)
            cond = {0:av==cv,1:av!=cv,4:sx(av,32)<sx(cv,32),5:sx(av,32)>=sx(cv,32),6:av<cv,7:av>=cv}[f3]
            name = {0:"BEQ",1:"BNE",4:"BLT",5:"BGE",6:"BLTU",7:"BGEU"}[f3]
            if cond:
                nxt = (pc + off) & MASK
                if nxt & 3: fault = (2, pc, nxt)
        elif (op == 3 and f3 in (0,1,2,4,5)) or (op == 0x23 and f3 in (0,1,2)):
            store = op == 0x23
            size = f3 & 3
            width = 1 << size
            off = sx(((ins >> 25) << 5) | ((ins >> 7) & 31),12) if store else imm
            addr = (av + off) & MASK
            name = {0:"SB",1:"SH",2:"SW"}[f3] if store else {0:"LB",1:"LH",2:"LW",4:"LBU",5:"LHU"}[f3]
            if addr % width: fault = (5 if store else 4, pc, addr)
            else:
                lane = addr & 3
                data = (cv << (lane*8)) & MASK if store else 0
                strobe = ((1 << width)-1) << lane if store else 0
                err, read = 0, 0
                if 0x1000 <= addr < 0x2000:
                    idx = (addr - 0x1000) // 4
                    read = ram[idx]
                    if store:
                        mask = sum(255 << (k*8) for k in range(4) if strobe & (1 << k))
                        ram[idx] = (read & ~mask) | (data & mask)
                elif 0x40000000 <= addr < 0x40000400:
                    idx, offset = (addr >> 8) & 3, addr & 0xFC
                    if offset == 0:
                        read = scratch[idx]
                        if store:
                            mask = sum(255 << (k*8) for k in range(4) if strobe & (1 << k))
                            scratch[idx] = (read & ~mask) | (data & mask)
                        else: reads += 1
                    elif offset == 4 and not store:
                        read = reads
                        reads += 1
                    else: err = 1
                else: err = 1
                transfers.append((addr, int(store), data, strobe, size, read if not store else 0, err))
                if err: fault = (7 if store else 6, pc, addr)
                elif not store:
                    val = (read >> (lane*8)) & ((1 << (width*8))-1)
                    if f3 < 4: val = sx(val, width*8)
                    write = True
        if not name: fault = (1, pc, ins)
        if fault: return trace, transfers, regs, ram, fault
        coverage.add(name)
        val &= MASK
        trace.append((pc, ins, int(write and rd != 0), rd if write and rd else 0, val if write and rd else 0))
        if write and rd: regs[rd] = val
        pc = nxt
    raise AssertionError("program did not terminate")

cases = {}
p = Program().emit(lui(1,0x80000), addi(2,0,-1), addi(3,0,31), addi(4,0,7))
for f3,f7 in [(0,0),(0,32),(1,0),(2,0),(3,0),(4,0),(5,0),(5,32),(6,0),(7,0)]:
    p.emit(r(5,f3,1,2,f7), r(6,f3,5,3,f7), r(0,f3,6,4,f7))
for f3,imm in [(0,-7),(2,-1),(3,-1),(4,-1),(6,0x155),(7,0x7FF),(1,31),(5,31),(5,0x41F)]:
    p.emit(i(0x13,7,f3,1,imm))
p.emit(u(0x17,8,0xFFFFF), addi(9,0,11), addi(9,9,1), r(10,0,9,9), addi(0,0,123), addi(11,0,1))
cases["arithmetic"] = p.finish()

p = Program().emit(lui(1,1), addi(2,0,7), sw(2), lw(3,1), addi(4,3,5), r(5,0,3,4), sw(5,1,4), lw(6,1,4), sw(6,1,8), lw(7,1,8), b(0,7,5,8), 0,
                   addi(8,1,16), sw(8,1,12), lw(9,1,12), sw(7,9), lw(10,9), lw(0,9), addi(11,0,2))
cases["dependencies"] = p.finish()

p = Program().emit(lui(1,1), lui(2,0x80FF8), addi(2,2,-255), sw(2))
for offset in range(4):
    p.emit(i(3,3+offset,0,1,offset), i(3,7+offset,4,1,offset))
for offset in (0,2): p.emit(i(3,11+offset,1,1,offset), i(3,15+offset,5,1,offset))
p.emit(addi(2,0,-86))
for offset in range(4): p.emit(s(0,1,2,offset), lw(20,1))
p.emit(s(1,1,2,0), lw(21,1), s(1,1,2,2), lw(22,1), lui(23,2), sw(22,23,-4), lw(24,23,-4), i(3,25,4,23,-1), i(3,26,5,23,-2))
cases["memory_lanes"] = p.finish()

p = Program().emit(lui(1,1), addi(2,0,-1), addi(3,0,1), addi(4,0,0))
for f3,yes,no in [(0,(2,2),(2,3)),(1,(2,3),(2,2)),(4,(2,3),(3,2)),(5,(3,2),(2,3)),(6,(3,2),(2,3)),(7,(2,3),(3,2))]:
    p.emit(b(f3,*yes,8), sw(3,1,0), addi(4,4,1), b(f3,*no,2), addi(4,4,1))
p.emit(addi(5,0,5))
p.label("loop")
p.emit(addi(4,4,1), addi(5,5,-1))
p.branch(1,5,0,"loop")
p.emit(sw(4))
cases["branches"] = p.finish()

p = Program().emit(lui(1,1), addi(2,0,0))
p.jump(5,"sub")
p.emit(addi(2,2,10))
p.jump(0,"after_sub")
p.emit(sw(2))
p.label("sub")
p.emit(addi(2,2,1), i(0x67,0,0,5,0))
p.label("after_sub")
# The indirect target is odd; JALR clears bit zero. rd=rs1 uses the old source.
target = p.pc + 16
p.emit(addi(6,0,target|1), i(0x67,6,0,6,0), sw(2), 0, addi(7,6,0), sw(2,1,4))
cases["jumps"] = p.finish()

p = Program().emit(lui(1,1), addi(1,1,-4), i(0x67,5,0,1,0), 0, addi(2,0,42), 0)
p.pc = 4092
p.emit(j(0,16-4092))
cases["wrong_path_fetch"] = p.finish()

p = Program().emit(lui(1,0x40000), addi(2,0,123))
for offset in (0,0x100,0x200,0x300): p.emit(sw(2,1,offset), lw(3,1,offset), lw(0,1,offset), addi(2,2,1))
p.emit(lw(4,1,4), addi(5,0,-1), s(0,1,5,1), lw(6,1), s(1,1,5,2), lw(7,1), lw(8,1,4))
cases["mmio_once"] = p.finish()

rng = random.Random(0x52563332)
p = Program().emit(lui(1,1), addi(2,0,-1), lui(3,0x80000))
for _ in range(220):
    rd, a, c, f3 = rng.randrange(2,32), rng.randrange(32), rng.randrange(32), rng.randrange(8)
    if rng.randrange(2): p.emit(r(rd,f3,a,c, rng.choice((0,32)) if f3 in (0,5) else 0))
    else:
        imm = rng.randrange(-2048,2048) if f3 not in (1,5) else rng.randrange(32) | (0x400 if f3==5 and rng.randrange(2) else 0)
        p.emit(i(0x13,rd,f3,a,imm))
p.emit(sw(31))
cases["random_alu"] = p.finish()

fault_programs = {
    "illegal": [addi(2,0,99), 0xFFFFFFFF],
    "bad_shift": [i(0x13,2,1,0,0x20)],
    "fence_unsupported": [0x0000000F],
    "load_half_alignment": [lui(1,1), i(3,2,1,1,1)],
    "load_word_alignment": [lui(1,1), lw(2,1,2)],
    "store_half_alignment": [lui(1,1), s(1,1,2,1)],
    "store_word_alignment": [lui(1,1), sw(2,1,2)],
    "jal_alignment": [j(2,2)],
    "jalr_alignment": [addi(1,0,3), i(0x67,1,0,1,0)],
    "branch_alignment": [b(0,0,0,2)],
    "fetch_access": [j(2,4096)],
    "load_access_x0": [lui(1,2), lw(0,1)],
    "store_access": [lui(1,2), sw(2)],
    "data_rom_access": [lw(2,0)],
    "mmio_read_error": [lui(1,0x40000), lw(2,1,8)],
    "mmio_write_error": [lui(1,0x40000), sw(2,1,4)],
    "mmio_window_end": [lui(1,0x40000), lw(2,1,0x400)],
}
for name, words in fault_programs.items():
    cases[name] = Program().emit(*words, sw(2), addi(3,0,88)).finish()

def write_words(path, rows):
    path.write_text("".join("".join(f"{v & MASK:08x}" for v in row) + "\n" for row in rows), encoding="ascii")

calls = []
total = 0
for name, program in cases.items():
    trace, transfers, regs, ram, fault = interpret(program)
    write_words(OUT/f"{name}.hex", [(program.get(n*4,0),) for n in range(1024)])
    write_words(OUT/f"{name}.trace", trace or [(0,)*5])
    write_words(OUT/f"{name}.bus", transfers or [(0,)*7])
    write_words(OUT/f"{name}.regs", [(x,) for x in regs])
    write_words(OUT/f"{name}.ram", [(x,) for x in ram])
    calls.append(f'run_case("{name}", {len(trace)}, {len(transfers)}, 4\'d{fault[0]}, 32\'h{fault[1]:08x}, 32\'h{fault[2]:08x});')
    total += len(trace)
(OUT/"cases.vh").write_text("// Generated by tb/gen_cpu_programs.py. Included inside the timing-mode loop.\n"+"\n".join(calls)+"\n", encoding="ascii")
required = set("ADD SUB SLL SLT SLTU XOR SRL SRA OR AND ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI LUI AUIPC JAL JALR BEQ BNE BLT BGE BLTU BGEU LB LH LW LBU LHU SB SH SW".split())
assert coverage == required, (required-coverage, coverage-required)
print(f"Generated {len(cases)} programs, {total} expected retirements, all {len(coverage)} supported instructions.")

# The human-readable equivalent is fw/src/cpu_smoke.S. No compiler is needed
# for this first ROM image. Keep both in sync if the demonstration changes.
smoke = [lui(1,1), addi(2,0,10), addi(3,0,0), r(3,0,3,2), addi(2,2,-1),
         b(1,2,0,-8), sw(3), lw(4,1), addi(5,4,1), sw(5,1,4),
         lui(6,0x40000), sw(5,6), j(0,0)]
write_words(ROOT/"fw"/"cpu_smoke.hex", [(smoke[n] if n<len(smoke) else 0,) for n in range(1024)])

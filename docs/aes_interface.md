# AES-128 interface and byte ordering

Defined 24 October 2026 for the standalone core. The CPU/MMIO wrapper was
added on October 26; see [its contract](aes_mmio.md). Approved addresses are unchanged.

## Core ports

`aes128_core` has inputs `clk`, active-high synchronous `rst`, `start`,
`key[127:0]`, and `plaintext[127:0]`; outputs are `busy`, sticky `done`,
and `ciphertext[127:0]`. All control decisions happen on rising clock edges.

- Reset has highest priority. It cancels work and clears busy, done, output,
  internal state, and the current round key. Hold reset across a clock edge.
- A request is accepted when `start && !busy && !rst` at the edge. Both
  operands are captured then; changes afterwards cannot alter that block.
- Acceptance sets busy, clears done, and clears the old ciphertext to zero.
- While busy, start is ignored. There is no request queue. The caller should
  pulse start for one cycle; a level held into a later idle edge is a NEW
  request and is accepted there. Completion and acceptance do not share an edge.
- Completion publishes ciphertext, clears busy, and sets done. Done and the
  ciphertext remain unchanged until reset or the next accepted request.
- Read ciphertext only when done is high. Busy and done are never both high.

The schedule captures at edge E0, performs initial AddRoundKey at E1,
rounds 1-9 at E2-E10, and final round 10 at E11. The final round omits
MixColumns. The verified core latency is **11 clock periods from
acceptance to done**, including on-the-fly key expansion. Earliest next
acceptance is E12. `tb_aes128_core` checked these boundaries on October 24.
A 100 MHz target does not establish timing closure. See [the AES guide](aes_core.md)
for measured verification results and the separate synthesis estimate.

## One unambiguous byte convention

Byte 0 is bits `[127:120]`, byte 1 is `[119:112]`, and byte 15 is `[7:0]`.
The printed hex string therefore follows the normal left-to-right byte order.
AES state position `(row r, column c)` contains byte `4*c+r`.

For example, the byte sequence `00 11 22 33 ... ee ff` is the vector
`128'h00112233445566778899aabbccddeeff`. Columns contain consecutive groups
of four bytes; the first column is `00 11 22 33`.

Primitive modules use the same convention:

- `aes_sbox`: one byte in, substituted byte out.
- `aes_shift_rows`: 128-bit state in/out; row r shifts left by r columns.
- `aes_mix_columns`: 128-bit state in/out; multiply each column in GF(2^8).
- `aes_round`: SubBytes -> ShiftRows -> optional MixColumns -> AddRoundKey.
  `final_round=1` selects the path without MixColumns.
- `aes_key_expand`: current 128-bit round key and round number 1-10 to
  the next key. Round numbers outside 1-10 return zero.

## CPU word mapping

The CPU is little-endian. To let consecutive byte stores preserve the byte
sequence, register word 0 holds bytes 0-3 with byte 0 in bits `[7:0]`.
Word 1 holds bytes 4-7, and so on. The wrapper reverses bytes within each
32-bit word when assembling the core vector; it does not reverse word order.

Examples used by the wrapper:

- Key `000102030405060708090a0b0c0d0e0f` -> KEY0=`03020100`,
  KEY1=`07060504`, KEY2=`0b0a0908`, KEY3=`0f0e0d0c`.
- Plaintext `00112233445566778899aabbccddeeff` -> PT0=`33221100`,
  PT1=`77665544`, PT2=`bbaa9988`, PT3=`ffeeddcc`.
- Ciphertext bytes map back into CT0-CT3 using the same rule.

All values above are hexadecimal. This mapping and the byte-strobe/status/error
behavior are verified by `tb_aes_mmio`. See [the M2 register contract](aes_mmio.md)
for START/DONE register semantics.

## First user interface

The user selected **32 hexadecimal digits per block** on October 24.
The first firmware/UI design will use the fixed public demo key
`000102030405060708090a0b0c0d0e0f` and display the input count plus all
32 ciphertext digits. Two rows of 16 output digits fit the planned text view.

Digits 0-9 and A-D are literal. A short `*` press enters E; a short `#`
press enters F. A `*` hold of at least one second clears the entry. Commit
an ordinary key on release so a clear hold cannot also insert E. Encryption
starts automatically when digit 32 is committed. Ignore new entry during
encryption; after the result is displayed, the next ordinary key begins
a new block. Clear also returns the displayed-result state to empty entry.
No padding is required because the block must contain exactly 32 digits.

These are design decisions for later keypad/firmware tests, not claims
that those components have been built. The fixed key and raw single-block
encryption demonstrate architecture; this is not a secure messaging protocol.

October 26 note: the symbol mapping above assumed a keypad with `*`/`#`.
Confirm the actual module's key legends at the lab; a keypad with literal
E/F keys will use those directly and needs a documented long-press clear
choice before M3 firmware. The selected 32-hex-digit block format is unchanged.

## References and verification

Algorithm: [NIST FIPS 197](https://csrc.nist.gov/pubs/fips/197/final), sections
3-5. Independent expected block outputs: the AES-128 encryption sections of
[NIST's known-answer vectors](https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program/block-ciphers).
The input/output/status contract and word mapping are our project decisions.

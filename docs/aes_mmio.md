# CPU control of AES: register contract

Defined 24 October 2026, before implementing the wrapper. The approved
address map and standalone [AES core contract](aes_interface.md) are retained.

## A request and its completion

`aes_mmio` uses the existing CPU bus: `valid`, `write`, byte `addr`,
lane-aligned `wdata`, four byte strobes `wstrb`, transfer `size`, and
responses `ready`, `rdata`, `error`. Size 0/1/2 means byte/halfword/word.
Read data and error are meaningful only on a completed transfer. Outside
that edge they may reflect an earlier request; they are not gated by VALID.
Address, write data/strobes and access checks are captured during the wait
cycle. Live BUSY and register contents still decide the completion result.
This keeps address calculation out of the CPU read-response path.

The master holds the request unchanged until a rising edge with VALID and
READY high. Only that edge applies a write or starts AES. The default
response has one wait edge; the `WAIT_CYCLES` parameter can add more for
testing. It must be at least one. There is one outstanding transfer.

After completion, keeping VALID high represents another transfer; READY
returns low while its response is prepared. There is no implicit request
deduplication. Dropping VALID before completion cancels preparation without
a side effect. Synchronous active-high reset cancels the transfer and AES,
and clears key/plaintext registers and status/output. Reset wins even on
an otherwise successful completion edge.

Reads return the containing aligned 32-bit register word. The CPU selects
and extends the requested byte/halfword. Halfword/word addresses must be
naturally aligned. Size 3 is invalid. Reads require zero write strobes;
writes may enable any subset of the lanes within the stated access size.
Strobes outside those lanes are invalid. A zero-strobe write to a writable
register is a successful no-op, including while busy.

## Register meanings

Base address is `0x40000000`; the window is exactly 256 bytes.

- **0x00 CTRL:** reads zero. Writing a strobed bit 0 as one starts a block.
  This is a command, not a stored bit. Zero does nothing. A nonzero reserved
  bit in any strobed byte is an error. Unstrobed data bits are ignored.
- **0x04 STAT:** read-only; bit 0 BUSY, bit 1 DONE; other bits zero.
- **0x10-0x1c KEY0-KEY3:** read/write key words, respecting byte strobes.
- **0x20-0x2c PT0-PT3:** read/write plaintext words, respecting byte strobes.
- **0x30-0x3c CT0-CT3:** read-only ciphertext words. Reset/start clears them;
  use them only when DONE is one.

A successful START captures all eight operand words on that same bus
completion edge. BUSY rises, DONE clears, and old output clears. Encryption
completes 11 clock periods later. DONE and ciphertext remain until reset
or the next accepted START; reading status/output has no clearing effect.
Writing operands while idle leaves the previous completed result intact.

A START or any nonempty KEY/PT write **while BUSY is one returns an error**
and changes no state. This includes the edge on which AES completes: the
busy value before that edge decides the access. There is no command queue.
KEY/PT/STAT/CT reads remain available during encryption.

Reserved offsets, addresses outside the AES window, misaligned transfers,
invalid sizes/strobes, and all writes to read-only registers return an
error. A failing read returns zero; a failing write has no side effect.
The CPU's existing bus-fault behavior applies, so normal firmware polls
status and only submits valid accesses. No additional error register is added.

## Bytes and an example

Word 0 holds bytes 0-3, with byte 0 in bits 7:0. Consecutive byte stores
therefore match memory byte order. The wrapper reverses bytes within each
word when connecting to the core's printed 128-bit vector.

```text
KEY0..3 = 03020100 07060504 0b0a0908 0f0e0d0c
PT0..3  = 33221100 77665544 bbaa9988 ffeeddcc
CTRL    = 00000001
CT0..3  = d8e0c469 30047b6a 80b7cdd8 5ac5b470
```

The displayed ciphertext string is
`69c4e0d86a7b0430d8cdb78070b4c55a`. See the standalone guide for the
underlying published expected value. This register-word mapping is our
project convention, not an AES algorithm change.

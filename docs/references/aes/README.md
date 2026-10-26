# AES reference vectors

Retrieved directly from NIST on **24 October 2026**:
[AES known-answer archive](https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Algorithm-Validation-Program/documents/aes/KAT_AES.zip).
The [NIST CAVP page](https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program/block-ciphers)
describes the test files. Algorithm specification:
[FIPS 197](https://csrc.nist.gov/pubs/fips/197/final).

`KAT_AES.zip` is the unmodified downloaded archive. The four adjacent `.rsp`
files are unmodified extracts. We use only their AES-128 **ENCRYPT** sections:

- `ECBGFSbox128.rsp`: 7 cases.
- `ECBKeySbox128.rsp`: 21 cases.
- `ECBVarKey128.rsp`: 128 cases.
- `ECBVarTxt128.rsp`: 128 cases.

Total: **284 published key/plaintext/ciphertext triples**. ECB vectors let
us check the raw single-block encryption primitive; no multi-block mode,
decryption, padding, or authentication is implemented by this core.

`manifest.json` records source, archive/file SHA-256 values, case counts,
and the index range of each group. The offline converter
`tb/crypto/import_nist_vectors.py` verifies the pinned archive hash and
copies the published answers into `tb/crypto/vectors/aes128_kat.mem`.
It does not calculate expected ciphertext. Each 384-bit row is key,
plaintext, ciphertext, with the key first in the printed hexadecimal text.

The Vivado project already includes that data file; no download or Python
step is needed in the lab. Passing these tests is project verification,
not NIST certification.

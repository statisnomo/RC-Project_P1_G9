"""Bind evidence to source content, normalizing CRLF to LF for Git checkouts."""
from pathlib import Path
from hashlib import sha256
import argparse, json

root = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('mode', choices=('write', 'check'))
p.add_argument('manifest')
p.add_argument('--extra', action='append', default=[], help='Additional build input when recording a new manifest')
args = p.parse_args()
paths = [q for folder in ('rtl', 'tb/internal') for q in (root/folder).rglob('*')
         if q.suffix in ('.v', '.vh', '.sv', '.mem')]
paths += [root/q for q in ('fw/display.hex','fw/src/display.S','fw/build_display.py',
    'constraints/zedboard_display.xdc','tb/peripherals/keypad_matrix_model.v')]
paths += [root/q for q in args.extra]
manifest = root/args.manifest
saved = json.loads(manifest.read_text()) if args.mode == 'check' else None
# An archived build records its own inputs. Adding an unrelated board variant
# must not invalidate that archive; changing any recorded input still does.
if saved is not None:
    paths = [root/q for q in saved]
current = {q.relative_to(root).as_posix(): sha256(q.read_bytes().replace(b'\r\n', b'\n')).hexdigest() for q in sorted(paths)}
if args.mode == 'write':
    manifest.parent.mkdir(parents=True, exist_ok=True)
    manifest.write_text(json.dumps(current, indent=2)+'\n')
else:
    if saved != current:
        raise SystemExit('Build inputs changed: '+', '.join(k for k in saved.keys() | current.keys() if saved.get(k)!=current.get(k)))
print(f'{args.mode}: {len(current)} source hashes')

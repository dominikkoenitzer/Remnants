"""Reconcile a regenerated package-lock.json with upstream's copy.

Usage: python upstream/lockmerge.py <upstream-tag> <path/to/package-lock.json>

Run it right after `npm install --package-lock-only --ignore-scripts` in the
lockfile's directory. Older npm versions drop fields that upstream's newer npm
writes, most importantly `libc` on the glibc and musl platform packages. For
every package whose version and source did not change, this keeps upstream's
entry exactly as it was; added, removed and re-versioned packages come from the
regenerated file, with `libc` restored where upstream had it.
"""
import json
import subprocess
import sys

tag, path = sys.argv[1], sys.argv[2]
upstream_text = subprocess.run(['git', 'show', f'{tag}:{path}'], capture_output=True, text=True, encoding='utf8').stdout
upstream = json.loads(upstream_text)['packages']
regenerated = json.load(open(path, encoding='utf8'))

merged = {}
kept = 0
for key, entry in regenerated['packages'].items():
	old = upstream.get(key)
	if key != '' and old and old.get('version') == entry.get('version') and old.get('resolved') == entry.get('resolved'):
		merged[key] = old
		kept += 1
		continue
	if old and 'libc' in old and 'libc' not in entry:
		entry = dict(entry)
		entry['libc'] = old['libc']
	merged[key] = entry
regenerated['packages'] = merged

with open(path, 'w', encoding='utf8', newline='\n') as f:
	f.write(json.dumps(regenerated, indent=2, ensure_ascii=False) + '\n')

libc = sum(1 for entry in merged.values() if 'libc' in entry)
print(f'{path}: kept {kept} upstream entries, {libc} entries carry libc')

"""List files that still import a module removed by the path lists.

Usage: python upstream/importgate.py <tree-ish> <output-file>

Scans relative imports in src, extensions/*/src and build of the given tree. A
file counts as a leak when one of its imports resolves into remove-dirs.txt or
remove-files.txt. Such files compile against modules that no longer exist, so
the count must be 0 before a sync is done.
"""
import collections
import os
import posixpath
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
tree = sys.argv[1]
dirs = [l.strip() for l in open(os.path.join(HERE, 'remove-dirs.txt')) if l.strip()]
files = set(l.strip() for l in open(os.path.join(HERE, 'remove-files.txt')) if l.strip())


def dead(path):
	return path in files or any(path == d or path.startswith(d + '/') for d in dirs)


out = subprocess.run(
	['git', 'grep', '-n', '-E', r"(from|import)\s*\(?\s*'\.{1,2}/[^']*'", tree, '--', 'src', 'extensions/*/src', 'build'],
	capture_output=True, text=True, encoding='utf8').stdout
hits = collections.defaultdict(list)
rx = re.compile(r"(?:from|import)\s*\(?\s*'(\.{1,2}/[^']*)'")
for line in out.splitlines():
	_, path, _, code = line.split(':', 3)
	if dead(path):
		continue
	for spec in rx.findall(code):
		target = posixpath.normpath(posixpath.join(posixpath.dirname(path), spec))
		target = re.sub(r'\.js$', '', target)
		candidates = [target + '.ts', target + '.tsx', target + '.js', target + '.css', target, target + '/index.ts']
		if any(dead(c) for c in candidates):
			hits[path].append(spec)

print('files importing removed modules:', len(hits), 'import lines:', sum(len(v) for v in hits.values()))
counts = collections.Counter('/'.join(p.split('/')[:5]) for p in hits)
for key, value in counts.most_common(25):
	print(value, key)
with open(sys.argv[2], 'w') as f:
	f.write('\n'.join(f'{p}\t{", ".join(v)}' for p, v in sorted(hits.items())))

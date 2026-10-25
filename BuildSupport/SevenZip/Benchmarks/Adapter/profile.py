"""Aggregate an xctrace time-profile export: self time by leaf and inclusive time by frame."""
import subprocess, sys, collections
import xml.etree.ElementTree as ET
trace = sys.argv[1]
top = int(sys.argv[2]) if len(sys.argv) > 2 else 25
xml = subprocess.check_output(['xcrun', 'xctrace', 'export', '--input', trace, '--xpath',
    '/trace-toc/run[@number="1"]/data/table[@schema="time-profile"]'])
root = ET.fromstring(xml)
ids = {}
def resolve(el):
    ref = el.get('ref')
    if ref is not None:
        return ids[ref]
    if el.get('id') is not None:
        ids[el.get('id')] = el
    for child in el:
        resolve(child)
    return el
leaf = collections.Counter(); incl = collections.Counter(); total = 0
for row in root.iter('row'):
    bt = None; weight = 1
    for child in row:
        r = resolve(child)
        if r.tag in ('backtrace', 'tagged-backtrace'):
            bt = r
        if r.tag == 'weight':
            weight = int(r.text) if r.text else 1
    if bt is None:
        continue
    frames = []
    for f in bt.iter('frame'):
        f = ids.get(f.get('ref'), f)
        frames.append(f.get('name') or '?')
    if not frames:
        continue
    total += weight
    leaf[frames[0]] += weight
    for name in set(frames):
        incl[name] += weight
print('total weight', total)
print('--- self')
for n, w in leaf.most_common(top): print(f'{100*w/total:6.2f}% {n[:140]}')
print('--- inclusive')
for n, w in incl.most_common(top * 2): print(f'{100*w/total:6.2f}% {n[:140]}')

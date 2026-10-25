"""Count syscalls per name for one process in an xctrace System Trace export."""
import subprocess, sys, collections
import xml.etree.ElementTree as ET
trace, process = sys.argv[1], sys.argv[2]
xml = open(trace, 'rb').read() if trace.endswith('.xml') else subprocess.check_output(['xcrun', 'xctrace', 'export', '--input', trace, '--xpath',
    '/trace-toc/run[@number="1"]/data/table[@schema="syscall"]'])
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
cols = [c.find('mnemonic').text for c in root.iter('col')]
counts = collections.Counter(); durations = collections.Counter()
for row in root.iter('row'):
    values = [resolve(c) for c in row]
    record = dict(zip(cols, values))
    proc = record.get('process')
    if proc is None or process not in (proc.get('fmt') or ''):
        continue
    name = record.get('call')
    name = (name.get('fmt') or name.text) if name is not None else '?'
    counts[name] += 1
    d = record.get('duration')
    if d is not None and d.text:
        durations[name] += int(d.text)
total = sum(counts.values())
print('total syscalls', total, 'total ns', sum(durations.values()))
for name, n in counts.most_common(18):
    print(f'{n:7d} {durations[name]/1e6:9.2f} ms {name}')

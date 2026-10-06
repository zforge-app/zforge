#!/usr/bin/env python3
"""Compare committed Foundation traversal with current traversal on identical data."""
import argparse, hashlib, json, pathlib, subprocess, re, signal, os, ctypes
libc = ctypes.CDLL(None, use_errno=True)
def set_tags(file, values):
    import plistlib
    data = plistlib.dumps(values, fmt=plistlib.FMT_BINARY)
    if libc.setxattr(os.fsencode(file), b"com.apple.metadata:_kMDItemUserTags", data, len(data), 0, 0):
        raise OSError(ctypes.get_errno(), "setxattr failed")
repo = pathlib.Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--output', type=pathlib.Path, required=True)
p.add_argument('--fixture', type=pathlib.Path)
p.add_argument('--files', type=int, default=100_000)
a = p.parse_args(); out = a.output; out.mkdir(parents=True, exist_ok=True)
cat = (repo/'Zforge/Services/FinderTagCatalog.swift').read_text()
metadata = cat[cat.index('nonisolated enum FinderTagMetadata'):cat.index('nonisolated enum FinderTagPresentation')]
common = 'import Foundation\nimport Darwin\n' + metadata
for name in ['ZforgeTemporaryStorage.swift', 'UserDirectoryService.swift']:
    common += (repo/'Zforge/Services'/name).read_text()
main = '''
actor Result {
 var records: TaggedFileScanner.Batch = [:]
 func receive(_ batch: TaggedFileScanner.Batch) { records.merge(batch) { _, new in new } }
}
@main struct Diagnostic {
 static func main() async throws {
  let result = Result()
  let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
  let start = Date()
  await TaggedFileScanner.scan([root]) { await result.receive($0) }
  let elapsed = Date().timeIntervalSince(start)
  let records = await result.records
  let normalized = Dictionary(uniqueKeysWithValues: records.map { (String($0.key.dropFirst(root.path.count)), $0.value) })
  print("elapsed_seconds=\\(elapsed)")
  print("records=" + String(decoding: try JSONEncoder().encode(normalized), as: UTF8.self))
 }
}
'''
variants = {
 'foundation': subprocess.check_output(['git','show','8af9fcb:Zforge/Services/TaggedFileScanner.swift'], cwd=repo, text=True),
 'native': (repo/'Zforge/Services/TaggedFileScanner.swift').read_text()
}
hashes = {}
for name in ['TagDirectoryReader.c','TagDirectoryReader.h']:
    hashes[name] = hashlib.sha256((repo/'Zforge/Native'/name).read_bytes()).hexdigest()
native = repo/'Zforge/Native'
subprocess.run(['xcrun','clang','-c',str(native/'TagDirectoryReader.c'),'-o',str(out/'reader.o')], check=True)
for name, scanner in variants.items():
    source = common + scanner + main
    hashes[name] = hashlib.sha256(source.encode()).hexdigest()
    path = out/(name+'.swift'); path.write_text(source)
    subprocess.run(['xcrun','swiftc','-parse-as-library','-module-cache-path',str(out/'modules'),'-import-objc-header',str(native/'TagDirectoryReader.h'),str(path),str(out/'reader.o'),'-o',str(out/name)],check=True)
root = a.fixture or out/'fixture'; root.mkdir(exist_ok=True)
if a.fixture is None:
    # Bounded fanout includes visible files, hidden descendants and a package.
    for i in range(a.files):
        directory = root/f'folder-{i//1000:03d}'; directory.mkdir(exist_ok=True)
        file = directory/f'file-{i:06d}.txt'; file.touch()
        if i % 10000 == 0:
            import plistlib
            set_tags(file, ['Benchmark\n6'])
    for dirname in ['.hidden','Fixture.app']:
        directory = root/dirname; directory.mkdir(exist_ok=True)
        for i in range(100):
            file = directory/f'file-{i}.txt'; file.touch()
            set_tags(file, ['Excluded\n4'])
results = []
for repeat in range(3):
    for name in (['foundation','native'] if repeat % 2 == 0 else ['native','foundation']):
        run = subprocess.Popen(['/usr/bin/time','-l',str(out/name),str(root)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,start_new_session=True)
        try: stdout,stderr = run.communicate(timeout=600)
        except BaseException:
            os.killpg(run.pid,signal.SIGTERM);run.wait();raise
        if run.returncode: raise RuntimeError(stderr)
        timing = re.search(r'([\d.]+) real\s+([\d.]+) user\s+([\d.]+) sys',stderr)
        item = dict(variant=name,repeat=repeat+1,elapsed_seconds=float(re.search(r'elapsed_seconds=(\S+)',stdout)[1]),
            records=json.loads(re.search(r'records=(.+)',stdout)[1]),cpu_seconds=float(timing[2])+float(timing[3]),
            rss_bytes=int(re.search(r'(\d+)  maximum resident',stderr)[1]),footprint_bytes=int(re.search(r'(\d+)  peak memory footprint',stderr)[1]))
        results.append(item);print(json.dumps(item),flush=True)
        (out/'results.json').write_text(json.dumps(dict(files=a.files,reference_commit='8af9fcb',source_sha256=hashes,measurements=results),indent=2)+'\n')
assert all(item['records'] == results[0]['records'] for item in results)
assert len(results[0]['records']) == (a.files+9999)//10000

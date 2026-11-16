#!/usr/bin/env python3
"""Compare committed Foundation traversal with current traversal on identical data."""
import argparse, hashlib, json, pathlib, subprocess, re, signal, os, ctypes, time, datetime
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
p.add_argument('--tagged-files', type=int, help='Visible tagged-file count; default retains the sparse ten-per-100,000 workload')
a = p.parse_args()
if a.files < 1: p.error('--files must be positive')
tagged_files = a.tagged_files if a.tagged_files is not None else (a.files + 9999) // 10000
if not 0 <= tagged_files <= a.files: p.error('--tagged-files must be between zero and --files')
tagged_indices = {i * a.files // tagged_files for i in range(tagged_files)}
out = a.output; out.mkdir(parents=True, exist_ok=True)
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
  let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true).standardizedFileURL
  let start = Date()
  await TaggedFileScanner.scan([root]) { await result.receive($0) }
  let elapsed = Date().timeIntervalSince(start)
  let records = await result.records
  // Older Foundation traversal returns physical paths; native traversal keeps
  // the supplied root identity. Compare the same fixture-relative filenames.
  guard let physical = realpath(root.path, nil) else { preconditionFailure("Fixture realpath unavailable") }
  let rootAliases = [root.path, String(cString: physical)]
  free(physical)
  let normalized = Dictionary(uniqueKeysWithValues: records.map { path, colors in
   guard let prefix = rootAliases.first(where: { TagScanRoots.covers($0, path) }) else {
    preconditionFailure("Scanner published a path outside the fixture")
   }
   return (String(path.dropFirst(prefix.count)), colors)
  })
  print("elapsed_seconds=\\(elapsed)")
  print("records=" + String(decoding: try JSONEncoder().encode(normalized), as: UTF8.self))
 }
}
'''
variants = {
 'foundation': subprocess.check_output(['git','show','3aa216a:Zforge/Services/TaggedFileScanner.swift'], cwd=repo, text=True),
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
if a.fixture is None and any(root.iterdir()):
    raise RuntimeError('Generated fixture directory must be empty')
if a.fixture is None:
    # Bounded fanout includes visible files, hidden descendants and a package.
    for i in range(a.files):
        directory = root/f'folder-{i//1000:03d}'; directory.mkdir(exist_ok=True)
        file = directory/f'file-{i:06d}.txt'; file.touch()
        if i in tagged_indices:
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
        wall_start, monotonic_start = time.time(), time.monotonic()
        run = subprocess.Popen(['/usr/bin/time','-l',str(out/name),str(root)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,start_new_session=True)
        try: stdout,stderr = run.communicate(timeout=600)
        except BaseException:
            os.killpg(run.pid,signal.SIGTERM);run.wait();raise
        wall_elapsed, monotonic_elapsed = time.time() - wall_start, time.monotonic() - monotonic_start
        if run.returncode: raise RuntimeError(stderr)
        timing = re.search(r'([\d.]+) real\s+([\d.]+) user\s+([\d.]+) sys',stderr)
        item = dict(variant=name,repeat=repeat+1,elapsed_seconds=float(re.search(r'elapsed_seconds=(\S+)',stdout)[1]),
            started_utc=datetime.datetime.fromtimestamp(wall_start, datetime.timezone.utc).isoformat(),
            process_wall_seconds=wall_elapsed, process_monotonic_seconds=monotonic_elapsed,
            wall_minus_monotonic_seconds=wall_elapsed-monotonic_elapsed,
            records=json.loads(re.search(r'records=(.+)',stdout)[1]),cpu_seconds=float(timing[2])+float(timing[3]),
            rss_bytes=int(re.search(r'(\d+)  maximum resident',stderr)[1]),footprint_bytes=int(re.search(r'(\d+)  peak memory footprint',stderr)[1]))
        results.append(item)
        assert len(item['records']) == tagged_files
        expected = {f'/folder-{i//1000:03d}/file-{i:06d}.txt': {'Benchmark': 6} for i in tagged_indices}
        assert item['records'] == expected, {
            'missing_sample': sorted(expected.keys() - item['records'].keys())[:3],
            'unexpected_sample': sorted(item['records'].keys() - expected.keys())[:3]}

        print(json.dumps({k:v for k,v in item.items() if k != 'records'} | {'tagged_records': len(item['records'])}),flush=True)
        published = []
        for measured in results:
            row = {k:v for k,v in measured.items() if k != 'records'}
            row['tagged_records'] = len(measured['records'])
            row['records_sha256'] = hashlib.sha256(json.dumps(measured['records'], sort_keys=True, separators=(',', ':')).encode()).hexdigest()
            if tagged_files <= 100: row['records'] = measured['records']
            published.append(row)
        (out/'results.json').write_text(json.dumps(dict(files=a.files,tagged_files=tagged_files,reference_commit='3aa216a',source_sha256=hashes,benchmark_script_sha256=hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest(),measurements=published),indent=2)+'\n')
assert all(item['records'] == results[0]['records'] for item in results)
assert len(results[0]['records']) == tagged_files

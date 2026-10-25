#!/usr/bin/env python3
"""ZF-25 adapter benchmark: official CLI vs bridge (static/dynamic) vs complete ArchiveServing.

Every measured source tree is compiled with the same harnesses, so a baseline export of
HEAD and the working tree can be compared A/B in the same time window.
"""
import argparse, hashlib, json, os, platform, statistics, subprocess, sys, time
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
CLI = REPO / 'Vendor/7zz'
ENGINE_SOURCES = ['Services/ArchiveEngine.swift', 'Services/ArchiveEntry.swift',
                  'Services/NativeSevenZipBackend.swift', 'Models/CompressionOptions.swift',
                  'Models/BrowserModels.swift', 'Services/AppLocalization.swift',
                  'Services/ZforgeTemporaryStorage.swift', 'Models/FileBrowserPreferences.swift']
SWIFT_FLAGS = ['-swift-version', '6', '-default-isolation', 'MainActor',
               '-enable-upcoming-feature', 'NonisolatedNonsendingByDefault',
               '-enable-upcoming-feature', 'InferIsolatedConformances',
               '-enable-upcoming-feature', 'MemberImportVisibility']
WORKLOADS = {
    # name: (dataset, archive, CLI creation switches)
    'small2k-store-zip': ('Small2k', 'small2k-store.zip', ['-tzip', '-mx=0']),
    'small10k-deflate-zip': ('Small10k', 'small10k-deflate.zip', ['-tzip', '-mx=5', '-mm=Deflate', '-mfb=32', '-mmt=2']),
    'tree10k-store-zip': ('Tree10k', 'tree10k-store.zip', ['-tzip', '-mx=0']),
    'tree10k-solid-7z': ('Tree10k', 'tree10k-solid.7z', ['-t7z', '-mx=5', '-m0=LZMA2', '-md=64m', '-mfb=32', '-ms=on', '-mmt=2']),
    'large64-store-zip': ('Large64', 'large64-store.zip', ['-tzip', '-mx=0']),
    'tiny-store-zip': ('Tiny', 'tiny-store.zip', ['-tzip', '-mx=0']),
}
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()


def run(command, **kw):
    return subprocess.run([str(c) for c in command], check=True, **kw)


def build(name, source, library, out):
    """Static and dynamic bridge harnesses plus the complete-engine harness for one tree."""
    out.mkdir(parents=True)
    native = source / 'Zforge/Native'
    clang = ['xcrun', 'clang++', '-arch', 'arm64', '-mmacosx-version-min=26.0', '-std=c++20',
             '-fobjc-arc', '-Os', '-g', '-I', native]
    run(clang + ['-c', native / 'SevenZipBridge.mm', '-o', out / 'SevenZipBridge.o'])
    # Same construction as the historical dynamic variant (bridge + force-loaded core in a dylib).
    run(clang + ['-dynamiclib', out / 'SevenZipBridge.o', '-Wl,-force_load,' + str(library),
                 '-Wl,-dead_strip', '-install_name', '@rpath/libSevenZipNative.dylib',
                 '-framework', 'Foundation', '-o', out / 'libSevenZipNative.dylib'])
    run(clang + [HERE / 'bridge.mm', out / 'SevenZipBridge.o', '-Wl,-force_load,' + str(library),
                 '-Wl,-dead_strip', '-framework', 'Foundation', '-o', out / 'bridge-static'])
    run(clang + [HERE / 'bridge.mm', out / 'libSevenZipNative.dylib', '-Wl,-rpath,' + str(out),
                 '-framework', 'Foundation', '-o', out / 'bridge-dynamic'])
    header = out / 'Bridging.h'
    header.write_text(f'#import "{native / "SevenZipBridge.h"}"\n')
    run(['xcrun', 'swiftc', '-O', '-wmo', '-g', '-target', 'arm64-apple-macos26.0', *SWIFT_FLAGS,
         '-import-objc-header', header, *[source / 'Zforge' / s for s in ENGINE_SOURCES],
         HERE / 'engine.swift', out / 'SevenZipBridge.o', '-Xlinker', '-force_load', '-Xlinker', library,
         '-Xlinker', '-dead_strip', '-lc++', '-framework', 'Foundation', '-o', out / 'engine-static'])
    (out / 'build.json').write_text(json.dumps({
        'name': name, 'source': str(source), 'library_sha256': sha(library),
        'bridge_sha256': sha(native / 'SevenZipBridge.mm'),
        'backend_sha256': sha(source / 'Zforge/Services/NativeSevenZipBackend.swift'),
        'engine_sha256': sha(source / 'Zforge/Services/ArchiveEngine.swift')}, indent=2) + '\n')


def xorshift_blocks():
    seed = 42
    def block(count):
        nonlocal seed
        data = bytearray(count)
        for offset in range(0, count, 8):
            seed ^= (seed << 13) & 0xFFFFFFFFFFFFFFFF; seed ^= seed >> 7; seed ^= (seed << 17) & 0xFFFFFFFFFFFFFFFF
            data[offset:offset + 8] = seed.to_bytes(8, 'little')
        return bytes(data)
    return block


def datasets(root):
    root.mkdir(parents=True)
    block = xorshift_blocks()
    (root / 'Tiny').mkdir(); (root / 'Tiny/Tiny.txt').write_bytes(b'tiny')
    (root / 'Small2k').mkdir()
    for i in range(2000):
        (root / f'Small2k/Item-{i:04d}.txt').write_bytes(bytes(range(256)))
    (root / 'Small10k').mkdir()
    for i in range(10000):
        (root / f'Small10k/Item-{i:05d}.bin').write_bytes(block(2048) + bytes(2048))
    for d in range(100):
        folder = root / f'Tree10k/Folder-{d:02d}'
        folder.mkdir(parents=True)
        for i in range(100):
            (folder / f'Item-{i:02d}.bin').write_bytes(block(2048) + bytes(2048))
    (root / 'Large64').mkdir()
    (root / 'Large64/Large.bin').write_bytes(bytes(range(256)) * (64 * 1024 * 1024 // 256))
    (root / 'Large256').mkdir()
    chunk = block(512 * 1024) + bytes(512 * 1024)
    with open(root / 'Large256/Large.bin', 'wb') as handle:
        for _ in range(256):
            handle.write(chunk)
    (root / 'Archives').mkdir()
    for workload, (dataset, archive, switches) in WORKLOADS.items():
        run([CLI, 'a', *switches, root / 'Archives' / archive, '.'], cwd=root / dataset,
            stdout=subprocess.DEVNULL)
    manifest = {}
    for dataset in sorted({w[0] for w in WORKLOADS.values()} | {'Large256'}):
        base = root / dataset
        manifest[dataset] = {str(p.relative_to(base)): sha(p) for p in sorted(base.rglob('*')) if p.is_file()}
    (root / 'manifest.json').write_text(json.dumps(manifest) + '\n')


def verify(output, expected):
    actual = {str(p.relative_to(output)): sha(p) for p in output.rglob('*') if p.is_file()}
    if actual != expected:
        missing = sorted(set(expected) - set(actual))[:5]
        extra = sorted(set(actual) - set(expected))[:5]
        raise AssertionError(f'extraction mismatch in {output}: missing {missing}, extra {extra}')
    return len(actual)


def cli_phase(options, cwd=None):
    start = time.monotonic()
    child = os.fork()
    if child == 0:
        if cwd: os.chdir(cwd)
        sink = os.open(os.devnull, os.O_WRONLY); os.dup2(sink, 1); os.dup2(sink, 2)
        os.execv(str(CLI), [str(CLI)] + [str(o) for o in options])
    _, status, usage = os.wait4(child, 0)
    if os.waitstatus_to_exitcode(status) != 0:
        raise RuntimeError(options)
    return time.monotonic() - start, {'user_s': usage.ru_utime, 'system_s': usage.ru_stime,
                                      'peak_rss_bytes': usage.ru_maxrss}


def timing(args):
    data = args.datasets.resolve()
    manifest = json.loads((data / 'manifest.json').read_text())
    builds = {b: args.builds.resolve() / b for b in args.variants}
    work_root = args.output_dir.resolve(); work_root.mkdir(parents=True)
    log = open(work_root / 'records.jsonl', 'w')
    backends = ['CLI'] + [f'{b}:{kind}' for b in args.variants for kind in args.kinds]
    for round_index in range(args.rounds):
        order = backends[round_index % len(backends):] + backends[:round_index % len(backends)]
        for workload in args.workloads:
            dataset, archive_name, _ = WORKLOADS[workload]
            archive = data / 'Archives' / archive_name
            for backend in order:
                work = work_root / f'{workload}-{backend.replace(":", "-")}-{round_index}'
                work.mkdir()
                record = {'workload': workload, 'backend': backend, 'round': round_index}
                if backend == 'CLI':
                    record['list_s'], record['list_usage'] = cli_phase(['l', '-slt', archive])
                    record['test_s'], record['test_usage'] = cli_phase(['t', archive])
                    output = work / 'Output-0'
                    record['extract_s'], record['extract_usage'] = cli_phase(['x', '-y', '-o' + str(output), archive])
                else:
                    build, kind = backend.split(':')
                    binary = builds[build] / kind
                    if kind.startswith('engine'):
                        command = [binary, 'extract', archive, work, 1, 'all']
                    else:
                        command = [binary, 'extract', archive, work, 1, 1]
                    start = time.monotonic()
                    process = run(command, capture_output=True, text=True,
                                  env={**os.environ, 'TMPDIR': str(work) + '/'})
                    record['process_s'] = time.monotonic() - start
                    record.update(json.loads(process.stdout.splitlines()[-1]))
                    output = work / 'Output-0'
                    if kind.startswith('engine'):
                        record.pop('run', None)
                record['verified_files'] = verify(output, manifest[dataset])
                log.write(json.dumps(record, sort_keys=True) + '\n'); log.flush()
                run(['rm', '-rf', work])
                print(round_index, workload, backend, round(record['extract_s'] * 1000, 2), flush=True)
    log.close()


def selected(args):
    """Multi-selection extraction through ArchiveServing (every other root item)."""
    data = args.datasets.resolve()
    work_root = args.output_dir.resolve(); work_root.mkdir(parents=True)
    log = open(work_root / 'records.jsonl', 'w')
    for round_index in range(args.rounds):
        order = args.variants[round_index % 2:] + args.variants[:round_index % 2]
        for workload in args.workloads:
            dataset, archive_name, _ = WORKLOADS[workload]
            for build in order:
                work = work_root / f'{workload}-{build}-{round_index}'; work.mkdir()
                process = run([args.builds.resolve() / build / 'engine-static', 'extract',
                               data / 'Archives' / archive_name, work, 1, 'selected'],
                              capture_output=True, text=True, env={**os.environ, 'TMPDIR': str(work) + '/'})
                record = {'workload': workload, 'backend': f'{build}:engine-selected', 'round': round_index}
                record.update(json.loads(process.stdout.splitlines()[-1]))
                expected = json.loads((data / 'manifest.json').read_text())[dataset]
                roots = sorted({k.split('/')[0] for k in expected})[::2]
                subset = {k: v for k, v in expected.items() if k.split('/')[0] in roots}
                record['verified_files'] = verify(work / 'Output-0', subset)
                log.write(json.dumps(record, sort_keys=True) + '\n'); log.flush()
                run(['rm', '-rf', work])
                print(round_index, workload, build, round(record['extract_s'] * 1000, 2), flush=True)


def memory(args):
    data = args.datasets.resolve()
    expected = json.loads((data / 'manifest.json').read_text())['Large256']
    work_root = args.output_dir.resolve(); work_root.mkdir(parents=True)
    log = open(work_root / 'records.jsonl', 'w')
    kinds = [(b, k) for b in args.variants for k in args.kinds]
    for round_index in range(args.rounds):
        order = kinds[round_index % len(kinds):] + kinds[:round_index % len(kinds)]
        for build, kind in order:
            work = work_root / f'{build}-{kind}-{round_index}'; work.mkdir()
            binary = args.builds.resolve() / build / kind.split('+')[0]
            if kind.startswith('engine'):
                command = [binary, 'memory', data / 'Large256', work, args.cycles]
            else:
                command = [binary, 'memory', data / 'Large256', work, args.cycles, 1 if kind.endswith('+relief') else 0]
            process = run(command, capture_output=True, text=True, env={**os.environ, 'TMPDIR': str(work) + '/'})
            rows = [json.loads(line) for line in process.stdout.splitlines()]
            for cycle in range(args.cycles):
                output = work / f'Output-{cycle}'
                if kind.startswith('engine'):
                    output = output / 'Large256'
                verify(output, expected)
            log.write(json.dumps({'build': build, 'kind': kind, 'round': round_index, 'rows': rows}) + '\n'); log.flush()
            run(['rm', '-rf', work])
            final = rows[-1]['memory']['footprint'] / 2**20
            print(round_index, build, kind, 'final footprint MiB', round(final, 1), flush=True)


def summarize(args):
    records = [json.loads(l) for p in args.records for l in Path(p).read_text().splitlines()]
    groups = {}
    for r in records:
        for op in ('list_s', 'test_s', 'extract_s', 'open_list_s'):
            if op in r:
                groups.setdefault((r['workload'], r['backend'], op), []).append(r[op] * 1000)
    summary = []
    for (workload, backend, op), values in sorted(groups.items()):
        values.sort()
        q = statistics.quantiles(values, n=4) if len(values) > 1 else [values[0]] * 3
        summary.append({'workload': workload, 'backend': backend, 'operation': op, 'n': len(values),
                        'median_ms': statistics.median(values), 'min_ms': values[0], 'max_ms': values[-1],
                        'q1_ms': q[0], 'q3_ms': q[2], 'samples_ms': [round(v, 3) for v in values]})
    print(json.dumps(summary, indent=1))


def summarize_memory(args):
    """Phase-end footprint (MiB) per build/kind, cycle and phase across processes."""
    groups = {}
    for p in args.records:
        for line in Path(p).read_text().splitlines():
            r = json.loads(line)
            for row in r['rows']:
                key = (r['build'], r['kind'], row.get('cycle', -1), row['phase'])
                groups.setdefault(key, []).append(row['memory']['footprint'] / 2**20)
    print(json.dumps([{'build': b, 'kind': k, 'cycle': c, 'phase': ph, 'n': len(v),
                       'median_mib': statistics.median(v), 'min_mib': min(v), 'max_mib': max(v)}
                      for (b, k, c, ph), v in sorted(groups.items())], indent=1))


parser = argparse.ArgumentParser()
sub = parser.add_subparsers(dest='command', required=True)
p = sub.add_parser('build'); p.add_argument('--name', required=True); p.add_argument('--source', type=Path, required=True)
p.add_argument('--static-library', type=Path, required=True); p.add_argument('--output-dir', type=Path, required=True)
p = sub.add_parser('datasets'); p.add_argument('--output-dir', type=Path, required=True)
for name in ('timing', 'selected', 'memory'):
    p = sub.add_parser(name)
    p.add_argument('--datasets', type=Path, required=True); p.add_argument('--builds', type=Path, required=True)
    p.add_argument('--output-dir', type=Path, required=True); p.add_argument('--rounds', type=int, default=5)
    p.add_argument('--variants', nargs='+', default=['baseline', 'candidate'])
    p.add_argument('--workloads', nargs='+', default=list(WORKLOADS))
    p.add_argument('--kinds', nargs='+', default=['bridge-static', 'bridge-dynamic', 'engine-static'])
    p.add_argument('--cycles', type=int, default=3)
p = sub.add_parser('summarize'); p.add_argument('records', nargs='+')
p = sub.add_parser('summarize-memory'); p.add_argument('records', nargs='+')
args = parser.parse_args()
if args.command == 'build':
    build(args.name, args.source.resolve(), args.static_library.resolve(), args.output_dir.resolve() / args.name)
elif args.command == 'datasets':
    datasets(args.output_dir.resolve())
else:
    {'timing': timing, 'selected': selected, 'memory': memory, 'summarize': summarize,
     'summarize-memory': summarize_memory}[args.command](args)

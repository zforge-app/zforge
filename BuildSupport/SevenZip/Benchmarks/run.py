#!/usr/bin/env python3
"""Same ZIP Store core workload for official CLI, static bridge and dynamic bridge."""
import argparse, hashlib, json, os, platform, statistics, subprocess, sys, time
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--static-library', type=Path, required=True)
parser.add_argument('--dynamic-library', type=Path, required=True)
parser.add_argument('--output-dir', type=Path, required=True)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[3]
root = args.output_dir.resolve()
root.mkdir(parents=True, exist_ok=False)
static = args.static_library.resolve()
dynamic = args.dynamic_library.resolve()
# Official reference CLI, downloaded and verified on demand (not tracked in Git).
cli = Path(subprocess.run([sys.executable, str(repo / 'Scripts/fetch-7zz.py')], check=True,
                          capture_output=True, text=True).stdout.strip())
bridge = repo / 'Zforge/Native/SevenZipBridge.mm'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
base = ['xcrun', 'clang++', '-arch', 'arm64', '-mmacosx-version-min=26.0',
        '-std=c++20', '-fobjc-arc', '-O2', '-g', '-framework', 'Foundation',
        '-Wl,-dead_strip', str(Path(__file__).with_name('native.mm'))]
subprocess.run(base + [str(bridge), '-Wl,-force_load,' + str(static),
                       '-o', str(root/'static')], check=True)
subprocess.run(base + [str(dynamic), '-Wl,-rpath,' + str(dynamic.parent),
                       '-o', str(root/'dynamic')], check=True)
for dataset in ('Large', 'Small'):
    folder = root/dataset
    folder.mkdir()
    if dataset == 'Large':
        (folder/'Large.bin').write_bytes(bytes(range(256)) * (64 * 1024 * 1024 // 256))
    else:
        for index in range(2000):
            (folder/f'Item-{index:04d}.txt').write_bytes(bytes(range(256)))
records = []
for dataset in ('Large', 'Small'):
    source = root/dataset
    expected = {p.name: sha(p) for p in source.iterdir()}
    for run in range(3):
        order = ['CLI', 'static', 'dynamic']
        order = order[run:] + order[:run]
        for backend in order:
            work = root/f'{dataset}-{backend}-{run}'
            work.mkdir()
            result = {'dataset': dataset, 'run': run, 'backend': backend}
            if backend != 'CLI':
                start = time.monotonic()
                process = subprocess.run([str(root/backend), str(source), str(work)],
                                         capture_output=True, text=True, check=True)
                result.update(json.loads(process.stdout))
                result['process_total_s'] = time.monotonic() - start
            else:
                archive = work/'CLI.zip'
                out = work/'Output'
                out.mkdir()
                phases = [('write', ['a', '-tzip', '-mx=0', str(archive), '.']),
                          ('list', ['l', '-slt', str(archive)]),
                          ('test', ['t', str(archive)]),
                          ('extract', ['x', '-y', '-o'+str(out), str(archive)])]
                for phase, options in phases:
                    start = time.monotonic()
                    child = os.fork()
                    if child == 0:
                        os.chdir(source)
                        sink = os.open(os.devnull, os.O_WRONLY)
                        os.dup2(sink, 1)
                        os.dup2(sink, 2)
                        os.execv(str(cli), [str(cli)] + options)
                    _, status, usage = os.wait4(child, 0)
                    if os.waitstatus_to_exitcode(status) != 0:
                        raise RuntimeError((phase, options, status))
                    result[phase+'_s'] = time.monotonic() - start
                    result[phase+'_rss_bytes'] = usage.ru_maxrss
            actual = {p.name: sha(p) for p in (work/'Output').iterdir()}
            assert actual == expected, (dataset, backend, run, 'extraction mismatch')
            result['verified_files'] = len(actual)
            records.append(result)
            print(dataset, run, backend, flush=True)
summary = []
for dataset in ('Large', 'Small'):
    for backend in ('CLI', 'static', 'dynamic'):
        rows = [r for r in records if r['dataset'] == dataset and r['backend'] == backend]
        entry = {'dataset': dataset, 'backend': backend}
        entry.update({p+'_s': statistics.median(r[p+'_s'] for r in rows)
                      for p in ('write', 'list', 'test', 'extract')})
        summary.append(entry)
metadata = {
    'scope': 'ZIP Store core microbenchmark; 3 rotating-order warm-cache repetitions; native O2; no Swift staging, UI or sandbox; native phase timers exclude process/loader startup, CLI timers include per-command startup; extraction hashes checked outside timers',
    'host': platform.platform(),
    'architecture': platform.machine(),
    'compiler': subprocess.check_output(['xcrun', 'clang++', '--version'], text=True).splitlines()[0],
    'revision': json.loads((repo/'Vendor/7zip-provenance.json').read_text())['revision'],
    'cli_sha256': sha(cli), 'static_sha256': sha(static), 'dynamic_sha256': sha(dynamic),
    'bridge_sha256': sha(bridge),
    'datasets': {d: {'files': len(list((root/d).iterdir())),
                     'bytes': sum(p.stat().st_size for p in (root/d).iterdir())}
                 for d in ('Large', 'Small')}
}
(root/'results.json').write_text(json.dumps({'metadata': metadata, 'medians': summary, 'records': records}, indent=2)+'\n')
print(json.dumps(summary, indent=2))

#!/usr/bin/env python3
"""Compare the pre-fix and current tag scanner with controlled local files."""
import argparse
import json
import re
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path)
parser.add_argument('--files', type=int, default=30_000)
args = parser.parse_args()
output = args.output or Path(tempfile.mkdtemp(prefix='zforge-tag-benchmark-'))
output.mkdir(parents=True, exist_ok=True)
fixture = output / 'fixture'
fixture.mkdir(exist_ok=True)
for index in range(args.files):
    directory = fixture / str(index // 1_000)
    directory.mkdir(exist_ok=True)
    (directory / f'file-{index}.txt').touch()


def historical(path):
    return subprocess.check_output(['git', 'show', f'866a55c:{path}'], cwd=REPO, text=True)


def metadata(source):
    return source[source.index('nonisolated enum FinderTagMetadata'):source.index('nonisolated enum FinderTagPresentation')]


old = historical('Zforge/Services/FinderTagCatalog.swift')
old_scanner = old[old.index('nonisolated enum TaggedFileScanner'):old.index('struct FinderTagDot')]
main = r'''
nonisolated enum UserDirectoryService {
    static let homeURL = URL(fileURLWithPath: "/nonexistent-fixture-home")
}
@main struct Diagnostic {
    static func main() async {
        let start = Date()
        await TaggedFileScanner.scan([URL(fileURLWithPath: CommandLine.arguments[1])]) { _ in }
        print("elapsed_seconds=\(Date().timeIntervalSince(start))")
        if CommandLine.arguments.contains("--idle") {
            var usage = rusage()
            func cpu() -> Double {
                getrusage(RUSAGE_SELF, &usage)
                return Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec)
                    + Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1e6
            }
            let before = cpu()
            try? await Task.sleep(for: .seconds(10))
            print("idle_cpu_seconds=\(cpu() - before)")
        }
    }
}
'''
current = (REPO / 'Zforge/Services/FinderTagCatalog.swift').read_text()
for variant, definitions in [
    ('baseline', metadata(old) + old_scanner + historical('Zforge/Services/ZforgeTemporaryStorage.swift')),
    ('corrected', metadata(current) + (REPO / 'Zforge/Services/TaggedFileScanner.swift').read_text()
     + (REPO / 'Zforge/Services/ZforgeTemporaryStorage.swift').read_text()),
]:
    source = output / f'{variant}.swift'
    source.write_text('import Foundation\nimport Darwin\n' + definitions + main)
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', '-module-cache-path', str(output / 'modules'),
                    str(source), '-o', str(output / variant)], check=True)

results = []
for repeat in range(1, 4):
    for variant in (['baseline', 'corrected'] if repeat % 2 else ['corrected', 'baseline']):
        run = subprocess.run(['/usr/bin/time', '-l', str(output / variant), str(fixture)], text=True, capture_output=True)
        text = run.stdout + run.stderr
        (output / f'{variant}-{repeat}.txt').write_text(text)
        if run.returncode:
            raise RuntimeError(f'{variant} failed: {text}')
        timing = re.search(r'([\d.]+) real\s+([\d.]+) user\s+([\d.]+) sys', text)
        results.append(dict(repeat=repeat, variant=variant,
            seconds=float(re.search(r'elapsed_seconds=(\S+)', text)[1]),
            cpu_seconds=float(timing[2]) + float(timing[3]),
            rss_bytes=int(re.search(r'(\d+)  maximum resident', text)[1]),
            footprint_bytes=int(re.search(r'(\d+)  peak memory footprint', text)[1])))
idle = subprocess.check_output([str(output / 'corrected'), str(fixture), '--idle'], text=True)
(output / 'idle.txt').write_text(idle)
(output / 'results.json').write_text(json.dumps(dict(file_count=args.files, measurements=results,
    idle_cpu_seconds=float(re.search(r'idle_cpu_seconds=(\S+)', idle)[1])), indent=2) + '\n')
print(output / 'results.json')

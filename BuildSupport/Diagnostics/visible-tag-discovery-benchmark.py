#!/usr/bin/env python3
"""Measure real visible Home/Shared tag discovery and post-completion idle CPU."""
import argparse, hashlib, os, signal, pathlib, subprocess, json, re
repo=pathlib.Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output',type=pathlib.Path,required=True)
args=parser.parse_args()
out=args.output;out.mkdir(parents=True,exist_ok=True)
cat=(repo/'Zforge/Services/FinderTagCatalog.swift').read_text()
metadata=cat[cat.index('nonisolated enum FinderTagMetadata'):cat.index('nonisolated enum FinderTagPresentation')]
src='import Foundation\nimport Darwin\n'+metadata
for p in ['TaggedFileScanner.swift','ZforgeTemporaryStorage.swift','UserDirectoryService.swift']:src+=(repo/'Zforge/Services'/p).read_text()
src+='''
actor Counts {
 var batches = 0
 var tagged = 0
 func receive(_ batch: TaggedFileScanner.Batch) { batches += 1; tagged += batch.count }
}
@main struct Diagnostic {
 static func main() async {
   let counts = Counts()
   let start = Date()
   await TaggedFileScanner.scan(TagDiscoveryPolicy.standardRoots) { await counts.receive($0) }
   print("elapsed_seconds=\\(Date().timeIntervalSince(start))")
   print("tagged_records=\\(await counts.tagged)")
   print("batches=\\(await counts.batches)")
   func cpu() -> Double {
      var usage = rusage(); getrusage(RUSAGE_SELF, &usage)
      return Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec) + Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1e6
   }
   let before = cpu()
   try? await Task.sleep(for: .seconds(10))
   print("idle_cpu_seconds=\\(cpu() - before)")
 }
}
'''
(out/'measure.swift').write_text(src)
native=repo/'Zforge/Native'
source_hash={'measure.swift':hashlib.sha256(src.encode()).hexdigest()}
for name in ['TagDirectoryReader.c','TagDirectoryReader.h']:
 source_hash[name]=hashlib.sha256((native/name).read_bytes()).hexdigest()
subprocess.run(['xcrun','clang','-c',str(native/'TagDirectoryReader.c'),'-o',str(out/'reader.o')],check=True)
subprocess.run(['xcrun','swiftc','-parse-as-library','-module-cache-path',str(out/'modules'),'-import-objc-header',str(native/'TagDirectoryReader.h'),str(out/'measure.swift'),str(out/'reader.o'),'-o',str(out/'measure')],check=True)
results=[]
for repeat in range(3):
 run=subprocess.Popen(['/usr/bin/time','-l',str(out/'measure')],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,start_new_session=True)
 try:
  stdout,stderr=run.communicate(timeout=600)
 except BaseException:
  os.killpg(run.pid,signal.SIGTERM)
  run.wait()
  raise
 t=stdout+stderr;(out/f'run-{repeat+1}.txt').write_text(t)
 if run.returncode:raise RuntimeError(t)
 def val(k):return float(re.search(k+r'=(\S+)',t)[1])
 timing=re.search(r'([\d.]+) real\s+([\d.]+) user\s+([\d.]+) sys',t)
 result=dict(repeat=repeat+1,elapsed_seconds=val('elapsed_seconds'),tagged_records=int(val('tagged_records')),batches=int(val('batches')),idle_cpu_seconds=val('idle_cpu_seconds'),cpu_seconds=float(timing[2])+float(timing[3]),rss_bytes=int(re.search(r'(\d+)  maximum resident',t)[1]),footprint_bytes=int(re.search(r'(\d+)  peak memory footprint',t)[1]))
 results.append(result);print(json.dumps(result),flush=True)
 (out/'results.json').write_text(json.dumps(dict(source_sha256=source_hash,acceptance_seconds=60,idle_window_seconds=10,scope='Visible Home and Users/Shared; unsandboxed production scanner, warm caches',measurements=results),indent=2)+'\n')

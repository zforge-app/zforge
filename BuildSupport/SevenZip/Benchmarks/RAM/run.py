#!/usr/bin/env python3
"""Build instrumented temporary snapshots; sample complete app trees externally."""
import argparse, hashlib, io, json, socket
import statistics, subprocess, tarfile, time, uuid
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('--output-dir',type=Path,required=True)
parser.add_argument('--repetitions',type=int,default=3)
parser.add_argument('--interval-ms',type=int,default=5)
parser.add_argument('--build-only',action='store_true')
parser.add_argument('--reuse-builds',action='store_true')
parser.add_argument('--refresh-driver',action='store_true')
parser.add_argument('--variants',nargs='+',choices=['CLI','static','dynamic'],default=['CLI','static','dynamic'])
parser.add_argument('--datasets',nargs='+',choices=['Large','Small'],default=['Large','Small'])
parser.add_argument('--formats',nargs='+',choices=['zip','7z'],default=['zip','7z'])
args=parser.parse_args()
assert args.repetitions>0 and args.interval_ms>0
repo=Path(__file__).resolve().parents[4]
root=args.output_dir.resolve()
root.mkdir(parents=True,exist_ok=args.reuse_builds)
refs={'CLI':'05d1720','static':'feat/7zz-static-linking','dynamic':'feat/7zz-dinamic-linking'}
metadata={'refs':{},'driver_sha256':hashlib.sha256(Path(__file__).with_name('driver.swift').read_bytes()).hexdigest(),'sampler_sha256':hashlib.sha256(Path(__file__).with_name('sampler.c').read_bytes()).hexdigest(),'host':subprocess.check_output(['sw_vers'],text=True).strip(),'variants':args.variants,'datasets':args.datasets,'formats':args.formats,'interval_ms':args.interval_ms,'repetitions':args.repetitions,'scope':'Real Release app with fixture UI; actual ArchiveServing engine and staging; full descendant process tree; RSS and physical footprint sampled externally; temporary injected automation only'}
apps={}
for variant,ref in refs.items():
    revision=subprocess.check_output(['git','rev-parse',ref],cwd=repo,text=True).strip()
    metadata['refs'][variant]=revision
    checkout=root/('source-'+variant)
    derived=root/('build-'+variant)
    if not args.reuse_builds:
        checkout.mkdir()
        data=subprocess.check_output(['git','archive',revision],cwd=repo)
        with tarfile.open(fileobj=io.BytesIO(data)) as archive:
            for member in archive:
                target=(checkout/member.name).resolve()
                assert checkout.resolve() in target.parents and not member.issym() and not member.islnk(),member.name
                archive.extract(member,checkout)
        # Normalize platform only for the old CLI snapshot.
        project=checkout/'Zforge.xcodeproj/project.pbxproj'
        project.write_text(project.read_text().replace('MACOSX_DEPLOYMENT_TARGET = 26.5;','MACOSX_DEPLOYMENT_TARGET = 26.0;'))
    if not args.reuse_builds or args.refresh_driver:
        driver=Path(__file__).with_name('driver.swift').read_text().replace('__ENGINE__','SevenZipArchiveEngine' if variant=='CLI' else 'NativeSevenZipArchiveEngine')
        (checkout/'Zforge/Services/ArchiveRAMBenchmark.swift').write_text(driver)
        delegate=checkout/'Zforge/AppDelegate.swift'
        text=delegate.read_text()
        if 'func applicationDidFinishLaunching' not in text: text=text.replace('    static let archiveURLsReceived', '    func applicationDidFinishLaunching(_ notification: Notification) { ArchiveRAMBenchmark.start() }\n\n    static let archiveURLsReceived')
        delegate.write_text(text)
        command=['xcodebuild','build','-project','Zforge.xcodeproj','-scheme','Zforge','-configuration','Release','-destination','platform=macOS,arch=arm64','-derivedDataPath',str(derived),'ARCHS=arm64','MACOSX_DEPLOYMENT_TARGET=26.0']
        print('Building',variant,revision,flush=True)
        with (root/(variant+'-build.log')).open('w') as log:
            subprocess.run(command,cwd=checkout,stdout=log,stderr=subprocess.STDOUT,check=True)
    for source_file in ['Zforge/Services/ArchiveEngine.swift','Zforge/Models/CompressionOptions.swift'] + ([] if variant=='CLI' else ['Zforge/Native/SevenZipBridge.mm','Zforge/Native/SevenZipBridge.h','Zforge/Services/NativeSevenZipBackend.swift']):
        expected_source=subprocess.check_output(['git','show',revision+':'+source_file],cwd=repo)
        assert (checkout/source_file).read_bytes()==expected_source,(variant,'stale build source',source_file)
    apps[variant]=derived/'Build/Products/Release/Zforge.app/Contents/MacOS/Zforge'
    assert apps[variant].exists(),apps[variant]
subprocess.run(['xcrun','clang','-O2','-arch','arm64','-mmacosx-version-min=26.0',str(Path(__file__).with_name('sampler.c')),'-o',str(root/'sampler')],check=True)
(root/'metadata.json').write_text(json.dumps(metadata,indent=2)+'\n')
if args.build_only: raise SystemExit(0)

results=[]
if True:
 for dataset in args.datasets:
  for format_name in args.formats:
   for repetition in range(args.repetitions):
    order=args.variants;shift=repetition%len(order);order=order[shift:]+order[:shift]
    for variant in order:
     case=f'{dataset}-{format_name}-{repetition}-{variant}'
     print('Running',case,flush=True)
     server=socket.socket();server.bind(('127.0.0.1',0));server.listen(1);server.settimeout(90)
     port=server.getsockname()[1]
     events=[];process=None;sampler=None
     sample_path=root/(case+'-samples.csv')
     try:
      log=(root/(case+'-app.log')).open('w')
      started=time.clock_gettime_ns(time.CLOCK_MONOTONIC)
      process=subprocess.Popen(['open','-n','-W',str(apps[variant].parents[2]),'--args','--ui-fixtures','--ram-benchmark-port',str(port),'--ram-benchmark-dataset',dataset,'--ram-benchmark-format',format_name,'--ram-benchmark-output',case],stdout=log,stderr=subprocess.STDOUT)
      with sample_path.open('w') as samples:
       client,_=server.accept();client.settimeout(600)
       with client,client.makefile('r') as stream:
        for line in stream:
         event=json.loads(line);event['timestamp_ns']=time.clock_gettime_ns(time.CLOCK_MONOTONIC);events.append(event)
         (root/(case+'-events.json')).write_text(json.dumps(events,indent=2)+'\n')
         if event['kind']=='ready':
          assert event['windows']>0 and event['benchmark_window_visible'],(case,'no app window')
          sampler=subprocess.Popen([str(root/'sampler'),str(event['pid']),str(args.interval_ms)],stdout=samples)
          client.sendall(b'A')
         if event['kind']=='error': raise RuntimeError((case,event))
       process.wait(timeout=30)
       sampler.terminate();sampler.wait(timeout=10)
      log.close()
      assert process.returncode==0,(case,process.returncode)
      ready=next(e for e in events if e['kind']=='ready')
      assert ready['windows']>0,(case,ready)
      assert any(e['kind']=='done' for e in events),(case,'no done event')
      done=next(e for e in events if e['kind']=='done')
      assert done['hashes_match'] and done['verified_files']==(1 if dataset=='Large' else 10000),(case,'content mismatch')
      values=[]
      for line in sample_path.read_text().splitlines():
       t,rss,footprint,count,parent_rss,parent_fp,parent_ok,sevenzip=map(int,line.split(','))
       if parent_ok: values.append({'t':t,'rss':rss,'footprint':footprint,'processes':count,'parent_rss':parent_rss,'parent_footprint':parent_fp,'sevenzip':sevenzip})
      assert values,(case,'no process metrics')
      phases={}
      ranges=[] # Sampling starts after Launch Services creates a window and reports the app PID.
      for e in events:
       if e['kind']=='begin':
        end=next(x for x in events if x['kind']=='end' and x['phase']==e['phase'])
        ranges.append((e['phase'],e['timestamp_ns'],end['timestamp_ns']))
      for name,begin,end in ranges:
       selected=[v for v in values if begin<=v['t']<=end]
       if not selected:
        phases[name]={'duration_s':(end-begin)/1e9,'samples':0,'warning':'phase shorter than sampling interval; no isolated peak inferred'}
        continue
       phases[name]={'duration_s':(end-begin)/1e9,'samples':len(selected),'peak_rss':max(v['rss'] for v in selected),'peak_footprint':max(v['footprint'] for v in selected),'median_rss':statistics.median(v['rss'] for v in selected),'median_footprint':statistics.median(v['footprint'] for v in selected),'max_processes':max(v['processes'] for v in selected)}
      gaps=[(b['t']-a['t'])/1e6 for a,b in zip(values,values[1:])]
      begin=next(e['timestamp_ns'] for e in events if e.get('phase')=='baseline' and e['kind']=='begin')
      end=next(e['timestamp_ns'] for e in events if e.get('phase')=='post' and e['kind']=='end')
      measured=[v for v in values if begin<=v['t']<=end]
      result={'case':case,'dataset':dataset,'format':format_name,'repetition':repetition,'variant':variant,'pid':ready['pid'],'windows':ready['windows'],'verified_files':done['verified_files'],'phases':phases,'peak_rss':max(v['rss'] for v in measured),'peak_footprint':max(v['footprint'] for v in measured),'max_processes':max(v['processes'] for v in values),'samples_with_7zz':sum(v['sevenzip'] for v in measured),'median_interval_ms':statistics.median(gaps),'max_interval_ms':max(gaps),'events':events}
      if variant=='CLI': assert result['max_processes']>=2 and result['samples_with_7zz']>0,(case,'7zz not observed')
      results.append(result)
      (root/'results.json').write_text(json.dumps({'metadata':metadata,'records':results},indent=2)+'\n')
     finally:
      server.close()
      if process and process.poll() is None: process.terminate();process.wait(timeout=10)
      if sampler and sampler.poll() is None: sampler.terminate();sampler.wait(timeout=10)
print('Completed',len(results),'fresh app launches',flush=True)

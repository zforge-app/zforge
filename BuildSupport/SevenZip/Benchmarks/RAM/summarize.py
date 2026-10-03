#!/usr/bin/env python3
"""Export raw samples and summaries from a completed RAM run."""
import argparse, gzip, json, statistics
from pathlib import Path
parser=argparse.ArgumentParser()
parser.add_argument('run_dir',type=Path)
parser.add_argument('destination',type=Path)
args=parser.parse_args()
raw=json.loads((args.run_dir/'results.json').read_text())
rows=raw['records']
summary=[]
for dataset in raw['metadata']['datasets']:
 for fmt in raw['metadata']['formats']:
  for variant in raw['metadata']['variants']:
   selected=[r for r in rows if r['dataset']==dataset and r['format']==fmt and r['variant']==variant]
   assert len(selected)==raw['metadata']['repetitions'],(dataset,fmt,variant,'incomplete run')
   entry={'dataset':dataset,'format':fmt,'variant':variant}
   for key in ['peak_rss','peak_footprint']:
    values=[r[key]/1048576 for r in selected]
    entry[key+'_mib']=statistics.median(values)
    entry[key+'_range_mib']=[min(values),max(values)]
   for phase in ['baseline','create','test','extract','post']:
    observed=[r['phases'][phase] for r in selected if r['phases'][phase]['samples']>0]
    assert len(observed)==len(selected),(dataset,fmt,variant,phase,'sampling gap')
    metric='median_footprint' if phase in ['baseline','post'] else 'peak_footprint'
    entry[phase+'_footprint_mib']=statistics.median(z[metric]/1048576 for z in observed)
   entry['delta_peak_from_baseline_mib']=statistics.median((r['peak_footprint']-r['phases']['baseline']['median_footprint'])/1048576 for r in selected)
   summary.append(entry)
raw['summary']=summary
args.destination.mkdir(parents=True,exist_ok=True)
(args.destination/'results.json').write_text(json.dumps(raw,indent=2)+'\n')
series=args.destination/'samples';series.mkdir(exist_ok=True)
for row in rows:
 source=args.run_dir/(row['case']+'-samples.csv')
 with (series/(source.name+'.gz')).open('wb') as output:
  # Zero timestamp makes the artifact reproducible from a given CSV.
  with gzip.GzipFile(filename='',mode='wb',fileobj=output,mtime=0) as compressed:
   compressed.write(source.read_bytes())
print(json.dumps(summary,indent=2))

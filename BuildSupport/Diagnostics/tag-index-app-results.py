#!/usr/bin/env python3
"""Summarize finite cold/warm Zforge captures without recording filesystem paths."""
import argparse, csv, ctypes, datetime, json, pathlib, time, statistics
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--capture', action='append', required=True, help='phase:csv:log_json:pid')
p.add_argument('--source-hashes', type=pathlib.Path, required=True)
p.add_argument('--output', type=pathlib.Path, required=True)
a=p.parse_args()
class Timespec(ctypes.Structure): _fields_=[('seconds',ctypes.c_long),('nanoseconds',ctypes.c_long)]
libc=ctypes.CDLL(None);ts=Timespec();libc.clock_gettime(6,ctypes.byref(ts))
# Darwin CLOCK_MONOTONIC matches the sampler; log wall timestamps map to it.
wall_offset_ns=time.time_ns()-(ts.seconds*10**9+ts.nanoseconds)
results=[]
for capture in a.capture:
 phase,series,log,pid=capture.split(':');pid=int(pid)
 rows=[{k:int(v) for k,v in r.items()} for r in csv.DictReader(open(series))]
 events=[e for e in json.load(open(log)) if e.get('processID')==pid]
 markers=[]
 for e in events:
  stamp=datetime.datetime.strptime(e['timestamp'],'%Y-%m-%d %H:%M:%S.%f%z')
  age=(stamp.timestamp()*1e9-wall_offset_ns-rows[0]['monotonic_ns']+rows[0]['process_age_ns'])/1e9
  markers.append(dict(process_age_seconds=age,message=e.get('eventMessage','')))
 # Grants can arrive in stages. Use the last ready marker in the capture so a
 # fast Shared-only checkpoint cannot stand in for Home's later readiness.
 ready=next((m for m in reversed(markers) if m['message'].startswith('Tag index ready:')),None)
 if not ready:raise RuntimeError('Missing ready marker: '+phase)
 def window(start,end):
  selected=[r for r in rows if start<=r['process_age_ns']/1e9<=end]
  if len(selected)<2:return None
  first,last=selected[0],selected[-1]
  return dict(start_age_seconds=first['process_age_ns']/1e9,end_age_seconds=last['process_age_ns']/1e9,
   samples=len(selected),cpu_percent=(last['cpu_ns']-first['cpu_ns'])/(last['monotonic_ns']-first['monotonic_ns'])*100,
   mean_footprint_mib=statistics.mean(r['footprint_bytes'] for r in selected)/2**20)
 ready_age=ready['process_age_seconds']
 idle_requested_start=max(10,ready_age+5)
 idle_available=next((r['process_age_ns']/1e9 for r in rows if r['process_age_ns']/1e9>=idle_requested_start),None)
 idle_start=idle_available if idle_available is not None else idle_requested_start
 results.append(dict(phase=phase,pid=pid,ready=ready,markers=markers,startup=window(0,5),active=window(15,ready_age-2),
  idle=window(idle_start,idle_start+25),idle_capture_gap_seconds=idle_start-idle_requested_start,
  peak_footprint_mib=max(r['lifetime_peak_footprint_bytes'] for r in rows)/2**20,samples=rows))
a.output.write_text(json.dumps(dict(source_sha256=json.load(a.source_hashes.open()),
 acceptance=dict(first_pass_seconds=60,cached_ready_seconds=5,idle_cpu_percent=0.5,peak_footprint_mib=130),
 clock_mapping='Darwin CLOCK_MONOTONIC to current wall offset; log timestamps mapped to process age',captures=results),indent=2)+'\n')
for r in results:print(json.dumps({k:v for k,v in r.items() if k not in ['samples','markers']}))

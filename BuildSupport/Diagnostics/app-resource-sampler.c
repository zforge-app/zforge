#include <libproc.h>
#include <mach/mach_time.h>
#include <sys/resource.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
int main(int argc, char **argv) {
 if(argc!=4) return 2;
 int pid=atoi(argv[1]), interval=atoi(argv[2]), rounds=atoi(argv[3]);
 setvbuf(stdout,NULL,_IOLBF,0);
 mach_timebase_info_data_t tb;mach_timebase_info(&tb);
 puts("monotonic_ns,cpu_ns,rss_bytes,footprint_bytes,process_age_ns,lifetime_peak_footprint_bytes");
 for(int i=0;i<rounds;i++) {
  struct rusage_info_v4 usage={0};
  if(proc_pid_rusage(pid,RUSAGE_INFO_V4,(rusage_info_t*)&usage)!=0) return 3;
  struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);
  printf("%llu,%llu,%llu,%llu,%llu,%llu\n",(unsigned long long)t.tv_sec*1000000000ULL+t.tv_nsec,
   (unsigned long long)((usage.ri_user_time+usage.ri_system_time)*(long double)tb.numer/tb.denom),usage.ri_resident_size,usage.ri_phys_footprint,
 (unsigned long long)((mach_absolute_time()-usage.ri_proc_start_abstime)*(long double)tb.numer/tb.denom),usage.ri_lifetime_max_phys_footprint);
  struct timespec pause={interval/1000,(interval%1000)*1000000};nanosleep(&pause,NULL);
 }
}

#include <libproc.h>
#include <sys/resource.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
static volatile sig_atomic_t stopped=0;
static void stop(int s){stopped=1;}
static void sample(int pid, unsigned long long *rss, unsigned long long *footprint,int *count,int *sevenzip) {
    char name[64]={0};
    if(proc_name(pid,name,sizeof(name))>0 && strcmp(name,"7zz")==0) *sevenzip=1;
    struct rusage_info_v4 usage={0};
    if(proc_pid_rusage(pid,RUSAGE_INFO_V4,(rusage_info_t *)&usage)==0){
        *rss+=usage.ri_resident_size;*footprint+=usage.ri_phys_footprint;(*count)++;
    }
    int children[512];
    int child_count=proc_listchildpids(pid,children,sizeof(children));
    for(int i=0;i<child_count;i++) if(children[i]>0 && children[i]!=pid)
        sample(children[i],rss,footprint,count,sevenzip);
}
int main(int argc,char **argv){
    if(argc!=3)return 2;
    int pid=atoi(argv[1]), ms=atoi(argv[2]);
    signal(SIGTERM,stop);signal(SIGINT,stop);
    setvbuf(stdout,NULL,_IOLBF,0);
    while(!stopped && kill(pid,0)==0){
        struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);
        unsigned long long rss=0,footprint=0;int count=0,sevenzip=0;
        struct rusage_info_v4 parent={0};
        int parentOK=proc_pid_rusage(pid,RUSAGE_INFO_V4,(rusage_info_t *)&parent)==0;
        sample(pid,&rss,&footprint,&count,&sevenzip);
        printf("%llu,%llu,%llu,%d,%llu,%llu,%d,%d\n",(unsigned long long)t.tv_sec*1000000000ULL+t.tv_nsec,rss,footprint,count,parent.ri_resident_size,parent.ri_phys_footprint,parentOK,sevenzip);
        struct timespec delay={ms/1000,(ms%1000)*1000000};nanosleep(&delay,NULL);
    }
    return 0;
}

#import <Foundation/Foundation.h>
#include <sys/resource.h>
#import "../../../Zforge/Native/SevenZipBridge.h"
int main(int argc,char **argv) { @autoreleasepool {
 if(argc!=3) return 1;
 NSString *input=[NSString stringWithUTF8String:argv[1]], *root=[NSString stringWithUTF8String:argv[2]];
 NSFileManager *fm=[NSFileManager defaultManager]; [fm createDirectoryAtPath:root withIntermediateDirectories:YES attributes:nil error:nil];
 NSMutableArray *sources=[NSMutableArray array];
 for(NSString *name in [[fm contentsOfDirectoryAtPath:input error:nil] sortedArrayUsingSelector:@selector(compare:)]) {
  ZFSevenZipSource *source=[ZFSevenZipSource new]; source.path=[input stringByAppendingPathComponent:name];source.archivePath=name;source.posixMode=0100644;
  NSDictionary *attrs=[fm attributesOfItemAtPath:source.path error:nil]; source.size=[attrs[NSFileSize] unsignedLongLongValue]; source.modified=attrs[NSFileModificationDate];[sources addObject:source];
 }
 ZFSevenZipOperation *operation=[ZFSevenZipOperation new]; NSError *error=nil; NSString *archive=[root stringByAppendingPathComponent:@"Native.zip"];
 NSTimeInterval start=NSDate.timeIntervalSinceReferenceDate;
 if(![ZFSevenZipBridge writeAtPath:archive format:@"zip" updatingPath:nil sources:sources properties:@{@"x":@0} password:nil operation:operation error:&error]){NSLog(@"%@",error);return 2;}
 double write=NSDate.timeIntervalSinceReferenceDate-start;start=NSDate.timeIntervalSinceReferenceDate;
 NSArray<ZFSevenZipEntry*>*entries=[ZFSevenZipBridge entriesAtPath:archive password:nil operation:operation error:&error];if(!entries)return 3;
 double list=NSDate.timeIntervalSinceReferenceDate-start;start=NSDate.timeIntervalSinceReferenceDate;
 if(![ZFSevenZipBridge testAtPath:archive password:nil operation:operation error:&error])return 4;
 double test=NSDate.timeIntervalSinceReferenceDate-start;start=NSDate.timeIntervalSinceReferenceDate;
 NSString *output=[root stringByAppendingPathComponent:@"Output"];[fm createDirectoryAtPath:output withIntermediateDirectories:YES attributes:nil error:nil];
 NSMutableArray *indices=[NSMutableArray array],*destinations=[NSMutableArray array];
 for(ZFSevenZipEntry *entry in entries){[indices addObject:@(entry.index)];[destinations addObject:[output stringByAppendingPathComponent:entry.path]];}
 if(![ZFSevenZipBridge extractAtPath:archive password:nil indices:indices destinations:destinations byteLimit:UINT64_MAX operation:operation error:&error]) {NSLog(@"%@",error);return 5;}
 double extract=NSDate.timeIntervalSinceReferenceDate-start;
 rusage usage; getrusage(RUSAGE_SELF, &usage);
 printf("{\"peak_rss_bytes\":%ld,\"files\":%lu,\"write_s\":%.6f,\"list_s\":%.6f,\"test_s\":%.6f,\"extract_s\":%.6f}\n",usage.ru_maxrss,(unsigned long)entries.count,write,list,test,extract);
 return 0;
}}

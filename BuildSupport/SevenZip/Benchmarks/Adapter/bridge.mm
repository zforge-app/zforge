// ZF-25 bridge-level harness. Benchmark tooling only; never linked into the app.
// Links either the static core plus the bridge source or the dynamic bridge library.
#import <Foundation/Foundation.h>
#include <mach/mach.h>
#include <malloc/malloc.h>
#include <sys/resource.h>
#include <time.h>
#import "SevenZipBridge.h" // From the measured source tree, passed with -I.

namespace {
double Now() { return (double)clock_gettime_nsec_np(CLOCK_UPTIME_RAW) / 1e9; }

uint64_t Footprint() {
    task_vm_info_data_t info;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&info, &count) != KERN_SUCCESS) return 0;
    return info.phys_footprint;
}

NSDictionary *Memory() {
    malloc_statistics_t stats = {};
    malloc_zone_statistics(nullptr, &stats);
    return @{@"footprint": @(Footprint()), @"malloc_in_use": @(stats.size_in_use),
             @"malloc_allocated": @(stats.size_allocated)};
}

struct Usage {
    double user, system; long inblock, oublock, nvcsw, nivcsw;
    static Usage Read() {
        rusage u; getrusage(RUSAGE_SELF, &u);
        return {u.ru_utime.tv_sec + u.ru_utime.tv_usec / 1e6, u.ru_stime.tv_sec + u.ru_stime.tv_usec / 1e6,
                u.ru_inblock, u.ru_oublock, u.ru_nvcsw, u.ru_nivcsw};
    }
};

NSDictionary *Delta(const Usage &a, const Usage &b) {
    return @{@"user_s": @(b.user - a.user), @"system_s": @(b.system - a.system),
             @"voluntary_switches": @(b.nvcsw - a.nvcsw), @"involuntary_switches": @(b.nivcsw - a.nivcsw)};
}

void Emit(NSDictionary *object) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingSortedKeys error:nil];
    fwrite(data.bytes, 1, data.length, stdout); fputc('\n', stdout); fflush(stdout);
}

[[noreturn]] void Fail(NSString *step, NSError *error) {
    fprintf(stderr, "%s failed: %s\n", step.UTF8String, error.description.UTF8String);
    exit(2);
}

NSArray<ZFSevenZipSource *> *Sources(NSString *input) {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSMutableArray *sources = [NSMutableArray array];
    NSArray *names = [[fm subpathsOfDirectoryAtPath:input error:nil] sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *name in names) {
        NSString *path = [input stringByAppendingPathComponent:name];
        NSDictionary *attrs = [fm attributesOfItemAtPath:path error:nil];
        BOOL directory = [attrs.fileType isEqualToString:NSFileTypeDirectory];
        ZFSevenZipSource *source = [ZFSevenZipSource new];
        source.path = path; source.archivePath = name; source.directory = directory;
        source.posixMode = (directory ? 040000 : 0100000) | ((NSNumber *)attrs[NSFilePosixPermissions]).unsignedIntValue;
        source.size = directory ? 0 : [attrs[NSFileSize] unsignedLongLongValue];
        source.modified = attrs[NSFileModificationDate];
        [sources addObject:source];
    }
    return sources;
}

// Mirrors the Swift preparation contract: directories are created before the
// native call and receive an empty destination; files map to root/path.
double Extract(NSString *archive, NSString *output, NSArray<ZFSevenZipEntry *> *entries,
               NSUInteger stride, ZFSevenZipOperation *operation, NSUInteger *files) {
    NSFileManager *fm = NSFileManager.defaultManager;
    double start = Now();
    [fm createDirectoryAtPath:output withIntermediateDirectories:YES attributes:nil error:nil];
    NSMutableArray *indices = [NSMutableArray array], *destinations = [NSMutableArray array];
    NSUInteger position = 0; *files = 0;
    for (ZFSevenZipEntry *entry in entries) {
        NSString *destination = [output stringByAppendingPathComponent:entry.path];
        if (entry.directory) {
            [fm createDirectoryAtPath:destination withIntermediateDirectories:YES attributes:nil error:nil];
            continue;
        }
        if (position++ % stride) continue;
        [fm createDirectoryAtPath:destination.stringByDeletingLastPathComponent
            withIntermediateDirectories:YES attributes:nil error:nil];
        [indices addObject:@(entry.index)]; [destinations addObject:destination]; ++*files;
    }
    NSError *error = nil;
    if (![ZFSevenZipBridge extractAtPath:archive password:nil indices:indices destinations:destinations
            rootPath:output byteLimit:UINT64_MAX operation:operation error:&error]) Fail(@"extract", error);
    return Now() - start;
}
}

int main(int argc, char **argv) { @autoreleasepool {
    if (argc < 2) return 1;
    NSString *mode = @(argv[1]);
    ZFSevenZipOperation *operation = [ZFSevenZipOperation new];
    NSError *error = nil;
    if ([mode isEqualToString:@"extract"] && argc == 6) {
        // extract <archive> <work> <repetitions> <stride>: list/test/extract, fresh output per repetition.
        NSString *archive = @(argv[2]), *work = @(argv[3]);
        int repetitions = atoi(argv[4]); NSUInteger stride = (NSUInteger)atoi(argv[5]);
        for (int run = 0; run < repetitions; ++run) @autoreleasepool {
            Usage u0 = Usage::Read(); double t0 = Now();
            NSArray<ZFSevenZipEntry *> *entries = [ZFSevenZipBridge entriesAtPath:archive password:nil operation:operation error:&error];
            if (!entries) Fail(@"list", error);
            double list = Now() - t0; Usage u1 = Usage::Read(); t0 = Now();
            if (![ZFSevenZipBridge testAtPath:archive password:nil operation:operation error:&error]) Fail(@"test", error);
            double test = Now() - t0; Usage u2 = Usage::Read();
            NSUInteger files = 0;
            NSString *output = [work stringByAppendingPathComponent:[NSString stringWithFormat:@"Output-%d", run]];
            double extract = Extract(archive, output, entries, stride, operation, &files);
            Usage u3 = Usage::Read();
            Emit(@{@"run": @(run), @"entries": @(entries.count), @"extracted_files": @(files),
                   @"list_s": @(list), @"test_s": @(test), @"extract_s": @(extract),
                   @"list_usage": Delta(u0, u1), @"test_usage": Delta(u1, u2), @"extract_usage": Delta(u2, u3),
                   @"memory": Memory()});
        }
        return 0;
    }
    if ([mode isEqualToString:@"create"] && argc == 6) {
        // create <input> <work> <format> <repetitions>: native creation timing only.
        NSString *input = @(argv[2]), *work = @(argv[3]), *format = @(argv[4]);
        NSArray *sources = Sources(input);
        NSDictionary *properties = [format isEqualToString:@"zip"] ? @{@"x": @0} : @{@"x": @5, @"0": @"LZMA2", @"d": @"64m", @"fb": @32, @"s": @YES, @"mt": @2};
        for (int run = 0; run < atoi(argv[5]); ++run) @autoreleasepool {
            NSString *archive = [work stringByAppendingPathComponent:[NSString stringWithFormat:@"Created-%d.%@", run, format]];
            double t0 = Now();
            if (![ZFSevenZipBridge writeAtPath:archive format:format updatingPath:nil sources:sources properties:properties
                    excludingPaths:@[] password:nil operation:operation error:&error]) Fail(@"create", error);
            Emit(@{@"run": @(run), @"create_s": @(Now() - t0), @"memory": Memory()});
            [NSFileManager.defaultManager removeItemAtPath:archive error:nil];
        }
        return 0;
    }
    if ([mode isEqualToString:@"memory"] && argc == 6) {
        // memory <input> <work> <cycles> <relief:0|1>: OR-11 large 7z pipeline repeated in one process.
        NSString *input = @(argv[2]), *work = @(argv[3]);
        int cycles = atoi(argv[4]); bool relief = atoi(argv[5]) != 0;
        NSArray *sources = Sources(input);
        NSDictionary *properties = @{@"x": @5, @"0": @"LZMA2", @"d": @"64m", @"fb": @32, @"s": @YES, @"mt": @2};
        Emit(@{@"phase": @"baseline", @"memory": Memory()});
        for (int cycle = 0; cycle < cycles; ++cycle) {
            NSString *archive = [work stringByAppendingPathComponent:[NSString stringWithFormat:@"Cycle-%d.7z", cycle]];
            NSString *output = [work stringByAppendingPathComponent:[NSString stringWithFormat:@"Output-%d", cycle]];
            auto phase = [&](NSString *name, double seconds) {
                NSMutableDictionary *row = [@{@"cycle": @(cycle), @"phase": name, @"seconds": @(seconds), @"memory": Memory()} mutableCopy];
                if (relief) {
                    size_t released = malloc_zone_pressure_relief(nullptr, 0);
                    row[@"relief_released"] = @(released); row[@"after_relief"] = Memory();
                }
                Emit(row);
            };
            double t0 = Now();
            @autoreleasepool {
                if (![ZFSevenZipBridge writeAtPath:archive format:@"7z" updatingPath:nil sources:sources properties:properties
                        excludingPaths:@[] password:nil operation:operation error:&error]) Fail(@"create", error);
            }
            phase(@"create", Now() - t0); t0 = Now();
            NSArray<ZFSevenZipEntry *> *entries;
            @autoreleasepool {
                entries = [ZFSevenZipBridge entriesAtPath:archive password:nil operation:operation error:&error];
                if (!entries) Fail(@"list", error);
            }
            phase(@"list", Now() - t0); t0 = Now();
            @autoreleasepool {
                if (![ZFSevenZipBridge testAtPath:archive password:nil operation:operation error:&error]) Fail(@"test", error);
            }
            phase(@"test", Now() - t0);
            NSUInteger files = 0; double seconds;
            @autoreleasepool { seconds = Extract(archive, output, entries, 1, operation, &files); }
            phase(@"extract", seconds); entries = nil;
            [NSFileManager.defaultManager removeItemAtPath:archive error:nil];
            sleep(1);
            phase(@"idle", 1);
        }
        // Optional hold so vmmap/footprint can inspect the retained regions.
        if (getenv("ZF_BENCH_HOLD_SECONDS")) { Emit(@{@"phase": @"hold", @"pid": @(getpid())}); sleep(atoi(getenv("ZF_BENCH_HOLD_SECONDS"))); }
        return 0;
    }
    return 1;
}}

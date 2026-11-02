// SPDX-License-Identifier: LGPL-2.1-or-later
// Zforge native adapter; see Vendor/7zip/DOC/copying.txt.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// Synchronous native API. Swift callers must execute it on a worker.
@interface ZFSevenZipEntry : NSObject
@property(nonatomic, copy) NSString *path;
@property(nonatomic) NSUInteger index;
@property(nonatomic) BOOL directory;
@property(nonatomic) BOOL encrypted;
@property(nonatomic) BOOL symbolicLink;
@property(nonatomic, nullable) NSNumber *posixMode;
@property(nonatomic, nullable) NSNumber *size;
@property(nonatomic, nullable) NSNumber *packedSize;
@property(nonatomic, nullable) NSDate *modified;
@property(nonatomic, nullable) NSDate *created;
@property(nonatomic, nullable) NSDate *accessed;
@property(nonatomic, nullable, copy) NSString *checksum;
@property(nonatomic, nullable, copy) NSString *method;
/// The entry belongs to a block that holds other files, so decoding it starts before the entry.
@property(nonatomic) BOOL solidBlock;
/// Compressed size of that block; the whole archive for compressed tar and single-file streams.
@property(nonatomic, nullable) NSNumber *solidBlockPackedSize;
@end

@interface ZFSevenZipOperation : NSObject
- (void)cancel;
/// Bytes read from the archive and its volumes by this operation (instrumentation).
@property(nonatomic, readonly) uint64_t sourceBytesRead;
/// A handler asked for the password during this operation (for listing: the names are encrypted).
@property(nonatomic, readonly) BOOL passwordRequested;
/// The operation was cancelled (the native work stops at its next check).
@property(nonatomic, readonly) BOOL isCancelled;
/// Called on the reading thread after each read of the archive, with the bytes read so far
/// (instrumentation for tests; it may block to hold a read in flight).
@property(nonatomic, copy, nullable) void (^readObserver)(uint64_t total);
@end

@interface ZFSevenZipSource : NSObject
@property(nonatomic, copy) NSString *path;
@property(nonatomic, copy) NSString *archivePath;
@property(nonatomic) BOOL directory;
@property(nonatomic) uint64_t size;
@property(nonatomic) uint32_t posixMode;
@property(nonatomic, nullable, copy) NSString *linkTarget;
@property(nonatomic) NSDate *modified;
@end

@interface ZFSevenZipBridge : NSObject
+ (NSArray<NSString *> *)formats;
/// Compressed tar streams are read sequentially: the outer stream feeds the tar handler.
+ (BOOL)isCompressedTarPath:(NSString *)path;
+ (nullable NSArray<ZFSevenZipEntry *> *)entriesAtPath:(NSString *)path
    password:(nullable NSString *)password operation:(ZFSevenZipOperation *)operation
    error:(NSError **)error;
+ (BOOL)testAtPath:(NSString *)path password:(nullable NSString *)password
    operation:(ZFSevenZipOperation *)operation error:(NSError **)error;
+ (BOOL)extractAtPath:(NSString *)path password:(nullable NSString *)password
    indices:(NSArray<NSNumber *> *)indices destinations:(NSArray<NSString *> *)destinations
    rootPath:(NSString *)rootPath
    byteLimit:(uint64_t)byteLimit operation:(ZFSevenZipOperation *)operation
    error:(NSError **)error;
/// Opens the archive once, asks `ready` (nil: skip) whether it is still the archive the caller
/// listed — a NO fails before anything is written —, then calls the planner for each entry
/// (nil or empty skips it; setting `abort` stops with an error) and extracts from that same
/// opening. Compressed tar is one decompression pass that stops after the entry `lastIndex`
/// (UINT32_MAX reads to the end and verifies the outer stream).
+ (BOOL)extractPlannedAtPath:(NSString *)path password:(nullable NSString *)password
    rootPath:(NSString *)rootPath byteLimit:(uint64_t)byteLimit lastIndex:(uint32_t)lastIndex
    planner:(NSString * _Nullable (^)(ZFSevenZipEntry *entry, BOOL *abort))planner
    ready:(nullable BOOL (^)(void))ready
    operation:(ZFSevenZipOperation *)operation error:(NSError **)error;
+ (BOOL)writeAtPath:(NSString *)path format:(NSString *)format
    updatingPath:(nullable NSString *)updatingPath sources:(NSArray<ZFSevenZipSource *> *)sources
    properties:(NSDictionary<NSString *, id> *)properties excludingPaths:(NSArray<NSString *> *)excludingPaths password:(nullable NSString *)password
    operation:(ZFSevenZipOperation *)operation error:(NSError **)error;
@end
NS_ASSUME_NONNULL_END

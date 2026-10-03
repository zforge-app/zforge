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
@end

@interface ZFSevenZipOperation : NSObject
- (void)cancel;
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
+ (nullable NSArray<ZFSevenZipEntry *> *)entriesAtPath:(NSString *)path
    password:(nullable NSString *)password operation:(ZFSevenZipOperation *)operation
    error:(NSError **)error;
+ (BOOL)testAtPath:(NSString *)path password:(nullable NSString *)password
    operation:(ZFSevenZipOperation *)operation error:(NSError **)error;
+ (BOOL)extractAtPath:(NSString *)path password:(nullable NSString *)password
    indices:(NSArray<NSNumber *> *)indices destinations:(NSArray<NSString *> *)destinations
    byteLimit:(uint64_t)byteLimit operation:(ZFSevenZipOperation *)operation
    error:(NSError **)error;
+ (BOOL)writeAtPath:(NSString *)path format:(NSString *)format
    updatingPath:(nullable NSString *)updatingPath sources:(NSArray<ZFSevenZipSource *> *)sources
    properties:(NSDictionary<NSString *, id> *)properties password:(nullable NSString *)password
    operation:(ZFSevenZipOperation *)operation error:(NSError **)error;
@end
NS_ASSUME_NONNULL_END

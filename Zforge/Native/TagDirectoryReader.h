#ifndef ZFORGE_TAG_DIRECTORY_READER_H
#define ZFORGE_TAG_DIRECTORY_READER_H
#include <stdbool.h>
#include <stdint.h>

typedef struct ZFTagDirectoryReader ZFTagDirectoryReader;
typedef struct {
    const char *path;
    bool isDirectory;
    bool isHidden;
    bool mayHaveXattrs;
    bool hasError;
    // False only for a directory whose name has no extension separator and
    // whose returned Finder info lacks the bundle bit: LaunchServices cannot
    // classify it as a package. Every other directory keeps the full check.
    bool mayBePackage;
} ZFTagDirectoryEntry;

// Conservative rule also used when a volume omits the extended field.
bool ZFTagMayHaveXattrs(uint32_t objectType, bool hasExtendedFlags, uint64_t extendedFlags);
uint32_t ZFTagObjectTypeFromMode(uint32_t mode);
// Conservative package pre-check; finderInfo may be NULL when not returned.
bool ZFTagMayBePackage(const char *name, const uint8_t *finderInfo);

// Worker-local cursor; returned paths remain valid until the next call.
ZFTagDirectoryReader *ZFTagDirectoryOpen(const char *path);
// 1 = item, 0 = finished, -1 = unsupported bulk enumeration (use fallback).
int ZFTagDirectoryNext(ZFTagDirectoryReader *, ZFTagDirectoryEntry *);
bool ZFTagDirectoryFailed(const ZFTagDirectoryReader *);
void ZFTagDirectoryClose(ZFTagDirectoryReader *);
#endif

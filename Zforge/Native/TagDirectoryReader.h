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
} ZFTagDirectoryEntry;

// Conservative rule also used when a volume omits the extended field.
bool ZFTagMayHaveXattrs(uint32_t objectType, bool hasExtendedFlags, uint64_t extendedFlags);
uint32_t ZFTagObjectTypeFromMode(uint32_t mode);

// Worker-local cursor; returned paths remain valid until the next call.
ZFTagDirectoryReader *ZFTagDirectoryOpen(const char *path);
// 1 = item, 0 = finished, -1 = unsupported bulk enumeration (use fallback).
int ZFTagDirectoryNext(ZFTagDirectoryReader *, ZFTagDirectoryEntry *);
bool ZFTagDirectoryFailed(const ZFTagDirectoryReader *);
void ZFTagDirectoryClose(ZFTagDirectoryReader *);
#endif

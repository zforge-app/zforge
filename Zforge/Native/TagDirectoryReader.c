#include "TagDirectoryReader.h"
#include <sys/attr.h>
#include <sys/stat.h>
#include <sys/vnode.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// Fixed-size metadata buffer plus one reusable pathname per active directory.
struct ZFTagDirectoryReader {
    int descriptor;
    bool failed;
    bool delivered;
    uint32_t remaining;
    size_t offset;
    size_t prefixLength;
    size_t pathCapacity;
    char *path;
    unsigned char buffer[32768];
};

ZFTagDirectoryReader *ZFTagDirectoryOpen(const char *path) {
    int descriptor = open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (descriptor < 0) return NULL;
    ZFTagDirectoryReader *reader = calloc(1, sizeof(*reader));
    if (!reader) { close(descriptor); errno = ENOMEM; return NULL; }
    reader->descriptor = descriptor;
    reader->prefixLength = strlen(path) + 1;
    reader->pathCapacity = reader->prefixLength + NAME_MAX * 3 + 1;
    reader->path = malloc(reader->pathCapacity);
    if (!reader->path) { close(descriptor); free(reader); errno = ENOMEM; return NULL; }
    memcpy(reader->path, path, reader->prefixLength - 1);
    reader->path[reader->prefixLength - 1] = '/';
    return reader;
}

static bool field(const unsigned char *base, size_t length, size_t *offset, void *out, size_t size) {
    if (*offset > length || size > length - *offset) return false;
    memcpy(out, base + *offset, size);
    *offset += size;
    return true;
}

int ZFTagDirectoryNext(ZFTagDirectoryReader *reader, ZFTagDirectoryEntry *entry) {
    while (true) {
        if (!reader->remaining) {
            struct attrlist attributes = { .bitmapcount = ATTR_BIT_MAP_COUNT,
                .commonattr = ATTR_CMN_RETURNED_ATTRS | ATTR_CMN_NAME | ATTR_CMN_OBJTYPE | ATTR_CMN_FLAGS | ATTR_CMN_ERROR, .forkattr = ATTR_CMNEXT_EXT_FLAGS };
            int count = getattrlistbulk(reader->descriptor, &attributes, reader->buffer, sizeof(reader->buffer), FSOPT_ATTR_CMN_EXTENDED | FSOPT_PACK_INVAL_ATTRS);
            if (count < 0) {
                if (!reader->delivered) return -1;
                reader->failed = true;
                return 0;
            }
            if (!count) return 0;
            reader->remaining = (uint32_t)count;
            reader->offset = 0;
        }
        const unsigned char *base = reader->buffer + reader->offset;
        size_t offset = 0;
        uint32_t length;
        if (reader->offset > sizeof(reader->buffer) - sizeof(length)
            || !field(base, sizeof(reader->buffer) - reader->offset, &offset, &length, sizeof(length))
            || length < 24 || length > sizeof(reader->buffer) - reader->offset) {
            reader->failed = true;
            return 0;
        }
        reader->offset += length;
        reader->remaining--;
        attribute_set_t returned;
        if (!field(base, length, &offset, &returned, sizeof(returned))) { reader->failed = true; return 0; }
        // PACK_INVAL_ATTRS reserves every requested slot, including ERROR
        // when its returned mask is clear. Common fields precede extended ones.
        uint32_t error = 0, type = 0, flags = 0;
        if (!field(base, length, &offset, &error, sizeof(error))) { reader->failed = true; return 0; }
        size_t referenceOffset = offset;
        attrreference_t name;
        uint64_t extended = 0;
        bool hasExtended = (returned.forkattr & ATTR_CMNEXT_EXT_FLAGS) != 0;
        if (!field(base, length, &offset, &name, sizeof(name))
            || !field(base, length, &offset, &type, sizeof(type))
            || !field(base, length, &offset, &flags, sizeof(flags))
            || !field(base, length, &offset, &extended, sizeof(extended))) { reader->failed = true; return 0; }
        int64_t start = (int64_t)referenceOffset + name.attr_dataoffset;
        if (start < (int64_t)offset || start > length || !name.attr_length || name.attr_length > length - (size_t)start
            || base[start + name.attr_length - 1] != 0) { reader->failed = true; return 0; }
        const char *rawName = (const char *)base + start;
        size_t needed = reader->prefixLength + name.attr_length;
        if (needed > reader->pathCapacity) {
            char *path = realloc(reader->path, needed);
            if (!path) { reader->failed = true; return 0; }
            reader->path = path; reader->pathCapacity = needed;
        }
        memcpy(reader->path + reader->prefixLength, rawName, name.attr_length);
        bool hidden = rawName[0] == '.' || (flags & UF_HIDDEN) != 0;
        if (error) {
            if (error == ENOENT || hidden) continue;
            // Preserve the individual retry path. One inaccessible item must
            // not turn its entire accessible parent into deferred work.
            *entry = (ZFTagDirectoryEntry){ .path = reader->path, .hasError = true };
            reader->delivered = true;
            return 1;
        }
        if ((returned.commonattr & (ATTR_CMN_OBJTYPE | ATTR_CMN_FLAGS)) != (ATTR_CMN_OBJTYPE | ATTR_CMN_FLAGS)) {
            struct stat info;
            if (lstat(reader->path, &info)) { if (errno != ENOENT) reader->failed = true; continue; }
            flags = info.st_flags;
            type = ZFTagObjectTypeFromMode(info.st_mode);
        }
        *entry = (ZFTagDirectoryEntry){ .path = reader->path, .isDirectory = type == VDIR,
            .isHidden = rawName[0] == '.' || (flags & UF_HIDDEN) != 0, .hasError = false,
            // getxattr follows a symlink. Its target may have tags even when
            // the link inode itself has no extended attributes.
            .mayHaveXattrs = ZFTagMayHaveXattrs(type, hasExtended, extended) };
        reader->delivered = true;
        return 1;
    }
}

bool ZFTagMayHaveXattrs(uint32_t type, bool hasExtended, uint64_t extended) {
    return type == VLNK || !hasExtended || (extended & EF_NO_XATTRS) == 0;
}

uint32_t ZFTagObjectTypeFromMode(uint32_t mode) {
    return S_ISLNK(mode) ? VLNK : (S_ISDIR(mode) ? VDIR : VREG);
}

bool ZFTagDirectoryFailed(const ZFTagDirectoryReader *reader) { return reader->failed; }
void ZFTagDirectoryClose(ZFTagDirectoryReader *reader) {
    close(reader->descriptor); free(reader->path); free(reader);
}

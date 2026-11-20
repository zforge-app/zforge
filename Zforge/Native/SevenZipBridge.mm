// SPDX-License-Identifier: LGPL-2.1-or-later
// Zforge native adapter; see Vendor/7zip/DOC/copying.txt.
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <fcntl.h>
#include <memory>
#include <mutex>
#include <thread>
#include <unistd.h>
#include <sys/stat.h>
#include <vector>
#include <algorithm>
#include <map>
#include <string>
#define BOOL ZF7ZipBOOL
#include "../../Vendor/7zip/CPP/Common/MyCom.h"
#include "../../Vendor/7zip/CPP/Common/UTFConvert.h"
#include "../../Vendor/7zip/CPP/Windows/PropVariant.h"
#include "../../Vendor/7zip/CPP/7zip/Common/FileStreams.h"
#include "../../Vendor/7zip/CPP/7zip/Common/MultiOutStream.h"
#include "../../Vendor/7zip/CPP/7zip/Common/StreamObjects.h"
#include "../../Vendor/7zip/CPP/7zip/Archive/IArchive.h"
#include "../../Vendor/7zip/CPP/7zip/IPassword.h"
#undef BOOL
#import "SevenZipBridge.h"

using NWindows::NCOM::CPropVariant;
extern "C" HRESULT GetNumberOfFormats(UInt32 *);
extern "C" HRESULT GetHandlerProperty2(UInt32, PROPID, PROPVARIANT *);
extern "C" HRESULT CreateObject(const GUID *, const GUID *, void **);

@implementation ZFSevenZipEntry
- (instancetype)init { if ((self = [super init])) _path = @""; return self; }
@end
@implementation ZFSevenZipSource
- (instancetype)init { if ((self = [super init])) { _path = @""; _archivePath = @""; _modified = [NSDate date]; } return self; }
@end
@implementation ZFSevenZipOperation { @public std::atomic<bool> stopped; std::atomic<uint64_t> bytesRead; std::atomic<bool> askedPassword; }
- (instancetype)init { if ((self = [super init])) { stopped.store(false); bytesRead.store(0); askedPassword.store(false); } return self; }
- (BOOL)passwordRequested { return askedPassword.load(); }
- (BOOL)isCancelled { return stopped.load(); }
- (void)cancel { stopped.store(true); }
- (uint64_t)sourceBytesRead { return bytesRead.load(); }
@end

namespace {
NSString *WideString(const wchar_t *str, unsigned length) {
    UString wide;
    wide.SetFrom(str, length);
    AString utf8;
    ConvertUnicodeToUTF8(wide, utf8);
    return [[NSString alloc] initWithBytes: utf8.Ptr() length:utf8.Len() encoding:NSUTF8StringEncoding];
}
NSString *String(BSTR str) {
    return str ? WideString(str, SysStringLen(str)) : nil;
}
BSTR Password(NSString *password) {
    UString wide;
    NSData *data = [password dataUsingEncoding:NSUTF8StringEncoding];
    AString utf8;
    utf8.SetFrom((const char *)data.bytes, (unsigned)data.length);
    if (!ConvertUTF8ToUnicode(utf8, wide)) return nullptr;
    return SysAllocStringLen(wide.Ptr(), wide.Len());
}
NSNumber *Number(const CPropVariant &p) {
    if (p.vt == VT_UI8) return @(p.uhVal.QuadPart);
    if (p.vt == VT_UI4) return @(p.ulVal);
    return nil;
}
NSDate *Date(const CPropVariant &p) {
    if (p.vt != VT_FILETIME) return nil;
    uint64_t ticks = ((uint64_t)p.filetime.dwHighDateTime << 32) | p.filetime.dwLowDateTime;
    // A zero FILETIME is unset (7-Zip's own UI shows it empty), not 1601-01-01 (D-103).
    if (ticks == 0) return nil;
    return [NSDate dateWithTimeIntervalSince1970:(double)ticks / 10000000.0 - 11644473600.0];
}
CPropVariant Property(IInArchive *arc, UInt32 index, PROPID key) {
    CPropVariant prop;
    if (arc->GetProperty(index, key, &prop) != S_OK) throw E_FAIL;
    return prop;
}
struct Context {
    ZFSevenZipOperation *operation;
    NSString *password;
    int failure = 0;
    bool passwordRequested = false;
    /// A volume a handler asked for that is not in the archive's folder (ZF-83, failure 9).
    NSString *missingVolume = nil;
    // Total size of the archive files opened by the successful handler (all volumes).
    UInt64 sourceSize = 0;
    HRESULT check() { return operation->stopped.load() ? E_ABORT : S_OK; }
    HRESULT secret(BSTR *result) {
        *result = nullptr;
        passwordRequested = true;
        operation->askedPassword.store(true);
        if (!password) { failure = 1; return E_ABORT; }
        *result = Password(password);
        return *result ? S_OK : E_OUTOFMEMORY;
    }
};
/// Reads the archive in place and counts the bytes read for the operation.
class SourceStream final : public IInStream, public IStreamGetSize, public CMyUnknownImp {
    Z7_COM_UNKNOWN_IMP_3(IInStream, ISequentialInStream, IStreamGetSize)
    Z7_IFACE_COM7_IMP(ISequentialInStream)
    Z7_IFACE_COM7_IMP(IInStream)
    Z7_IFACE_COM7_IMP(IStreamGetSize)
public:
    CMyComPtr<IInStream> file;
    UInt64 length = 0;
    ZFSevenZipOperation *operation = nil;
};
Z7_COM7F_IMF(SourceStream::Read(void *data, UInt32 size, UInt32 *processed)) {
    UInt32 done = 0;
    HRESULT result = file->Read(data, size, &done);
    const uint64_t total = operation->bytesRead.fetch_add(done) + done;
    if (auto observer = operation.readObserver) observer(total);
    if (processed) *processed = done;
    return result;
}
Z7_COM7F_IMF(SourceStream::Seek(Int64 offset, UInt32 origin, UInt64 *position)) {
    return file->Seek(offset, origin, position);
}
Z7_COM7F_IMF(SourceStream::GetSize(UInt64 *size)) { *size = length; return S_OK; }
HRESULT OpenSource(NSString *path, Context &ctx, CMyComPtr<IInStream> &result, UInt64 *length) {
    CInFileStream *file = new CInFileStream;
    CMyComPtr<IInStream> owner = file;
    if (!file->Open(path.fileSystemRepresentation)) return S_FALSE;
    UInt64 size = 0;
    if (!file->GetLength(size)) return E_FAIL;
    SourceStream *source = new SourceStream;
    result = source;
    source->file = owner; source->length = size; source->operation = ctx.operation;
    ctx.sourceSize += size;
    if (length) *length = size;
    return S_OK;
}
/// Presents numbered volumes (`name.7z.001`, `name.7z.002`, ...) as one seekable stream.
/// 7-Zip 26.06 removed the equivalent `CMultiStream`; this keeps the bridge independent of it.
class VolumeStream final : public IInStream, public IStreamGetSize, public CMyUnknownImp {
    Z7_COM_UNKNOWN_IMP_3(IInStream, ISequentialInStream, IStreamGetSize)
    Z7_IFACE_COM7_IMP(ISequentialInStream)
    Z7_IFACE_COM7_IMP(IInStream)
    Z7_IFACE_COM7_IMP(IStreamGetSize)
    struct Volume {
        CMyComPtr<IInStream> stream;
        UInt64 start = 0, size = 0;
    };
    std::vector<Volume> volumes;
    UInt64 position = 0, length = 0;
public:
    void append(CMyComPtr<IInStream> stream, UInt64 size) {
        volumes.push_back({stream, length, size});
        length += size;
    }
    bool isEmpty() const { return volumes.empty(); }
};
Z7_COM7F_IMF(VolumeStream::Read(void *data, UInt32 size, UInt32 *processed)) {
    if (processed) *processed = 0;
    if (size == 0 || position >= length) return S_OK;
    // The volume that holds `position`: the last one starting at or before it.
    auto volume = std::upper_bound(volumes.begin(), volumes.end(), position,
        [](UInt64 offset, const Volume &item) { return offset < item.start; }) - 1;
    const UInt64 local = position - volume->start;
    RINOK(volume->stream->Seek((Int64)local, STREAM_SEEK_SET, nullptr))
    const UInt32 chunk = (UInt32)std::min<UInt64>(size, volume->size - local);
    UInt32 done = 0;
    const HRESULT result = volume->stream->Read(data, chunk, &done);
    position += done;
    if (processed) *processed = done;
    return result;
}
Z7_COM7F_IMF(VolumeStream::Seek(Int64 offset, UInt32 origin, UInt64 *newPosition)) {
    switch (origin) {
        case STREAM_SEEK_SET: break;
        case STREAM_SEEK_CUR: offset += (Int64)position; break;
        case STREAM_SEEK_END: offset += (Int64)length; break;
        default: return STG_E_INVALIDFUNCTION;
    }
    if (offset < 0) return HRESULT_WIN32_ERROR_NEGATIVE_SEEK;
    position = (UInt64)offset;
    if (newPosition) *newPosition = position;
    return S_OK;
}
Z7_COM7F_IMF(VolumeStream::GetSize(UInt64 *size)) { *size = length; return S_OK; }
class OpenCallback final : public IArchiveOpenCallback, public ICryptoGetTextPassword,
    public IArchiveOpenVolumeCallback, public CMyUnknownImp {
    Z7_IFACES_IMP_UNK_3(IArchiveOpenCallback, ICryptoGetTextPassword, IArchiveOpenVolumeCallback)
public:
    Context *context;
    NSString *path;
};
Z7_COM7F_IMF(OpenCallback::SetTotal(const UInt64 *, const UInt64 *)) { return context->check(); }
Z7_COM7F_IMF(OpenCallback::SetCompleted(const UInt64 *, const UInt64 *)) { return context->check(); }
Z7_COM7F_IMF(OpenCallback::CryptoGetTextPassword(BSTR *p)) { return context->secret(p); }
Z7_COM7F_IMF(OpenCallback::GetProperty(PROPID key, PROPVARIANT *value)) {
    CPropVariant prop;
    if (key == kpidName) {
        prop.vt = VT_BSTR; prop.bstrVal = Password(path.lastPathComponent);
    } else if (key == kpidIsDir) prop = false;
    else if (key == kpidSize) {
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        prop = (UInt64)[attrs[NSFileSize] unsignedLongLongValue];
    }
    prop.Detach(value); return S_OK;
}
Z7_COM7F_IMF(OpenCallback::GetStream(const wchar_t *name, IInStream **stream)) {
    *stream = nullptr;
    NSString *component = WideString(name, (unsigned)wcslen(name));
    if (!component || ![component isEqualToString:component.lastPathComponent] || [component isEqualToString:@".."])
        return E_FAIL;
    NSString *candidate = [path.stringByDeletingLastPathComponent stringByAppendingPathComponent:component];
    // Only sibling files of the authorized archive are available to the handler.
    CMyComPtr<IInStream> owner;
    if (OpenSource(candidate, *context, owner, nullptr) != S_OK) {
        // RAR and spanned ZIP handlers name the next volume they need (ZF-83).
        if (!context->missingVolume) context->missingVolume = component;
        return S_FALSE;
    }
    *stream = owner.Detach(); return context->check();
}
struct Archive {
    CMyComPtr<IInArchive> handler;
    CMyComPtr<IInStream> input;
    NSString *format = nil;
    ~Archive() { if (handler) handler->Close(); }
};
/// The volume number of `name` when it is `<prefix><digits>` (three or more digits), or 0.
unsigned VolumeNumber(NSString *name, NSString *prefix) {
    if (name.length <= prefix.length + 2) return 0;
    if ([name compare:prefix options:NSCaseInsensitiveSearch range:NSMakeRange(0, prefix.length)] != NSOrderedSame) return 0;
    NSString *suffix = [name substringFromIndex:prefix.length];
    if ([suffix rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location != NSNotFound) return 0;
    return (unsigned)suffix.integerValue;
}
HRESULT Input(NSString *path, Context &ctx, CMyComPtr<IInStream> &result) {
    NSString *base = path.stringByDeletingPathExtension;
    NSString *number = path.pathExtension;
    // `name.7z.NNN` / `name.zip.NNN` (three or more digits) are byte slices of one archive,
    // read as one stream from volume 1 (ZF-83). The engine names a missing volume first.
    bool split = number.length >= 3 && number.integerValue == 1
        && [number rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location == NSNotFound
        && ([@"7z" isEqualToString:base.pathExtension.lowercaseString] || [@"zip" isEqualToString:base.pathExtension.lowercaseString]);
    if (!split) return OpenSource(path, ctx, result, nullptr) == S_OK ? S_OK : E_FAIL;
    NSArray<NSString *> *siblings = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path.stringByDeletingLastPathComponent error:nil];
    NSString *prefix = [base.lastPathComponent stringByAppendingString:@"."];
    std::vector<std::pair<unsigned, NSString *>> volumes;
    for (NSString *name in siblings) {
        unsigned index = VolumeNumber(name, prefix);
        if (index > 0) volumes.push_back({index, name});
    }
    std::sort(volumes.begin(), volumes.end(), [](const auto &a, const auto &b) { return a.first < b.first; });
    VolumeStream *multi = new VolumeStream; result = multi;
    unsigned expected = 1;
    for (const auto &volume : volumes) {
        if (volume.first != expected++) return E_FAIL;
        CMyComPtr<IInStream> stream;
        UInt64 size = 0;
        NSString *file = [path.stringByDeletingLastPathComponent stringByAppendingPathComponent:volume.second];
        if (OpenSource(file, ctx, stream, &size) != S_OK) return E_FAIL;
        multi->append(stream, size);
    }
    return multi->isEmpty() ? E_FAIL : S_OK;
}
HRESULT Open(NSString *path, Context &ctx, Archive &arc) {
    UInt32 count = 0; RINOK(GetNumberOfFormats(&count))
    // Try extension matches first, then probe remaining registered handlers.
    NSString *extension = path.pathExtension.lowercaseString;
    if (extension.length >= 3 && extension.integerValue == 1) extension = path.stringByDeletingPathExtension.pathExtension.lowercaseString;
    std::vector<UInt32> order;
    for (int match = 1; match >= 0; --match) {
        for (UInt32 i = 0; i < count; ++i) {
            CPropVariant ext; RINOK(GetHandlerProperty2(i, NArchive::NHandlerPropID::kExtension, &ext))
            NSString *extensions = ext.vt == VT_BSTR ? String(ext.bstrVal) : @"";
            bool matches = [[extensions componentsSeparatedByString:@" "] containsObject:extension];
            if (matches == (bool)match) order.push_back(i);
        }
    }
    for (UInt32 i : order) {
        RINOK(ctx.check())
        CPropVariant id; RINOK(GetHandlerProperty2(i, NArchive::NHandlerPropID::kClassID, &id))
        if (id.vt != VT_BSTR || SysStringByteLen(id.bstrVal) != sizeof(GUID)) continue;
        GUID cls; memcpy(&cls, id.bstrVal, sizeof(cls));
        CMyComPtr<IInArchive> handler;
        if (CreateObject(&cls, &IID_IInArchive, (void **)&handler) != S_OK) continue;
        CMyComPtr<IInStream> input;
        ctx.sourceSize = 0;
        ctx.missingVolume = nil;
        RINOK(Input(path, ctx, input))
        OpenCallback *callback = new OpenCallback;
        CMyComPtr<IArchiveOpenCallback> owner = callback;
        callback->context = &ctx; callback->path = path;
        UInt64 scan = 8 * 1024 * 1024;
        HRESULT result = handler->Open(input, &scan, owner);
        if (ctx.passwordRequested && ctx.password && (result == S_FALSE || result == E_FAIL)) ctx.failure = 2;
        if (ctx.failure || result == E_ABORT) return E_ABORT;
        if (result == S_OK && ctx.missingVolume) {
            // The handler opened what it found, but the set is incomplete (ZF-83).
            handler->Close();
            ctx.failure = 9;
            return E_FAIL;
        }
        if (result == S_OK) {
            CPropVariant name; RINOK(GetHandlerProperty2(i, NArchive::NHandlerPropID::kName, &name))
            arc.handler = handler; arc.input = input;
            arc.format = name.vt == VT_BSTR ? String(name.bstrVal) : @"";
            return S_OK;
        }
        handler->Close();
    }
    return S_FALSE;
}
ZFSevenZipEntry *MakeEntry(IInArchive *arc, UInt32 i) {
    ZFSevenZipEntry *entry = [ZFSevenZipEntry new]; entry.index = i;
    auto name = Property(arc, i, kpidPath);
    entry.path = name.vt == VT_BSTR ? String(name.bstrVal) : @"";
    auto folder = Property(arc, i, kpidIsDir);
    entry.directory = folder.vt == VT_BOOL && folder.boolVal != VARIANT_FALSE;
    auto crypt = Property(arc, i, kpidEncrypted);
    entry.encrypted = crypt.vt == VT_BOOL && crypt.boolVal != VARIANT_FALSE;
    entry.size = Number(Property(arc, i, kpidSize));
    entry.packedSize = Number(Property(arc, i, kpidPackSize));
    auto mode = Property(arc, i, kpidPosixAttrib);
    entry.posixMode = Number(mode);
    auto attributes = Property(arc, i, kpidAttrib);
    if (!entry.posixMode && attributes.vt == VT_UI4 && (attributes.ulVal & 0x8000)) entry.posixMode = @(attributes.ulVal >> 16);
    auto link = Property(arc, i, kpidSymLink);
    entry.symbolicLink = ([entry.posixMode unsignedIntValue] & 0170000) == 0120000 || link.vt == VT_BSTR;
    entry.modified = Date(Property(arc, i, kpidMTime));
    entry.created = Date(Property(arc, i, kpidCTime));
    entry.accessed = Date(Property(arc, i, kpidATime));
    auto crc = Property(arc, i, kpidCRC);
    if (crc.vt == VT_UI4) entry.checksum = [NSString stringWithFormat:@"%08X", crc.ulVal];
    auto method = Property(arc, i, kpidMethod);
    if (method.vt == VT_BSTR) entry.method = String(method.bstrVal);
    return entry;
}
/// The tar handler cannot read sparse entries from a sequential stream (it indexes its
/// random-access item table), so such entries stop the operation instead.
bool IsSparse(IInArchive *arc, UInt32 i) {
    auto characts = Property(arc, i, kpidCharacts);
    if (characts.vt != VT_BSTR) return false;
    return [[String(characts.bstrVal) componentsSeparatedByString:@" "] containsObject:@"SPARSE"];
}
bool IsStreamFormat(NSString *format) {
    return [@[@"gzip", @"bzip2", @"xz", @"zstd", @"zstd2", @"lzma", @"lzma86", @"Z"] containsObject:format];
}
bool IsCompressedTar(NSString *path) {
    NSString *name = path.lastPathComponent.lowercaseString;
    for (NSString *suffix in @[@".tar.gz", @".tgz", @".tar.bz2", @".tbz", @".tbz2", @".tar.xz", @".txz", @".tar.zst", @".tzst"])
        if ([name hasSuffix:suffix]) return true;
    return false;
}
HRESULT CreateHandler(NSString *format, const GUID *iid, void **result) {
    UInt32 count = 0; RINOK(GetNumberOfFormats(&count))
    for (UInt32 i = 0; i < count; ++i) {
        CPropVariant name; GetHandlerProperty2(i, NArchive::NHandlerPropID::kName, &name);
        if (name.vt != VT_BSTR || ![String(name.bstrVal) isEqualToString:format]) continue;
        CPropVariant id; GetHandlerProperty2(i, NArchive::NHandlerPropID::kClassID, &id);
        if (id.vt != VT_BSTR || SysStringByteLen(id.bstrVal) != sizeof(GUID)) continue;
        GUID cls; memcpy(&cls, id.bstrVal, sizeof(cls));
        return CreateObject(&cls, iid, result);
    }
    return E_NOINTERFACE;
}

/// Marks entries whose decoding starts before them: members of a block shared with other
/// files. Block sizes come from the index; where a handler does not expose the block's
/// compressed size (CAB folders, WIM/ESD solid resources) an upper bound is used.
void ApplySolidBlocks(const Archive &arc, NSArray<ZFSevenZipEntry *> *entries, UInt64 sourceSize) {
    NSString *format = arc.format;
    if (IsStreamFormat(format)) {
        for (ZFSevenZipEntry *entry in entries) { entry.solidBlock = YES; entry.solidBlockPackedSize = @(sourceSize); }
        return;
    }
    bool sevenZip = [format isEqualToString:@"7z"], cab = [format isEqualToString:@"Cab"];
    bool rar = [format isEqualToString:@"Rar"] || [format isEqualToString:@"Rar5"];
    bool wim = [format isEqualToString:@"wim"];
    if (!sevenZip && !cab && !rar && !wim) return;
    // Block key per file entry; files of one block share a key.
    std::vector<std::pair<ZFSevenZipEntry *, Int64>> members;
    Int64 run = -1;
    UInt64 largestSolid = 0;
    for (ZFSevenZipEntry *entry in entries) {
        if (entry.directory) continue;
        if (sevenZip || cab) {
            auto block = Property(arc.handler, (UInt32)entry.index, kpidBlock);
            if (block.vt == VT_UI4) members.push_back({entry, (Int64)block.ulVal});
            else if (block.vt == VT_I4 && block.lVal >= 0) members.push_back({entry, (Int64)block.lVal});
        } else if (rar) {
            // A solid RAR entry continues the dictionary of the previous file entry.
            auto solid = Property(arc.handler, (UInt32)entry.index, kpidSolid);
            bool continues = solid.vt == VT_BOOL && solid.boolVal != VARIANT_FALSE;
            if (!continues || run < 0) run = (Int64)entry.index;
            members.push_back({entry, run});
        } else {
            auto solid = Property(arc.handler, (UInt32)entry.index, kpidSolid);
            if (solid.vt == VT_BOOL && solid.boolVal != VARIANT_FALSE) {
                members.push_back({entry, 0});
                largestSolid = std::max(largestSolid, (UInt64)entry.packedSize.unsignedLongLongValue);
            }
        }
    }
    std::map<Int64, std::pair<unsigned, UInt64>> blocks;
    for (auto &member : members) {
        auto &block = blocks[member.second];
        block.first += 1;
        block.second += member.first.packedSize.unsignedLongLongValue;
    }
    for (auto &member : members) {
        const auto &block = blocks[member.second];
        if (!wim && block.first < 2) continue;
        member.first.solidBlock = YES;
        // Upper bounds where the handler does not report the block's size.
        UInt64 size = cab || (wim && largestSolid == 0) ? sourceSize : wim ? largestSolid : block.second;
        member.first.solidBlockPackedSize = @(size);
    }
}

/// Bounded in-memory pipe between the outer stream handler (producer thread) and the tar
/// handler reading sequentially (operation thread). Nothing is written to disk.
struct StreamPipe {
    std::mutex mutex;
    std::condition_variable changed;
    std::vector<Byte> ring;
    size_t head = 0, count = 0;
    bool finished = false, closed = false;
    HRESULT result = S_OK;
    Int32 itemResult = NArchive::NExtract::NOperationResult::kOK;
    ZFSevenZipOperation *operation;
    StreamPipe(size_t capacity, ZFSevenZipOperation *operation) : ring(capacity), operation(operation) {}
    bool stopped() const { return operation->stopped.load(); }
    bool succeeded() {
        std::lock_guard<std::mutex> lock(mutex);
        return finished && result == S_OK && itemResult == NArchive::NExtract::NOperationResult::kOK;
    }
};
class PipeWriter final : public ISequentialOutStream, public CMyUnknownImp {
    Z7_IFACES_IMP_UNK_1(ISequentialOutStream)
public:
    std::shared_ptr<StreamPipe> pipe;
};
Z7_COM7F_IMF(PipeWriter::Write(const void *data, UInt32 size, UInt32 *processed)) {
    if (processed) *processed = 0;
    std::unique_lock<std::mutex> lock(pipe->mutex);
    const size_t capacity = pipe->ring.size();
    UInt32 done = 0;
    while (done < size) {
        while (pipe->count == capacity && !pipe->closed && !pipe->stopped())
            pipe->changed.wait_for(lock, std::chrono::milliseconds(50));
        if (pipe->closed || pipe->stopped()) return E_ABORT;
        const size_t tail = (pipe->head + pipe->count) % capacity;
        const size_t chunk = std::min({capacity - pipe->count, capacity - tail, (size_t)(size - done)});
        memcpy(pipe->ring.data() + tail, (const Byte *)data + done, chunk);
        pipe->count += chunk; done += (UInt32)chunk;
        if (processed) *processed = done;
        pipe->changed.notify_all();
    }
    return S_OK;
}
class PipeReader final : public ISequentialInStream, public CMyUnknownImp {
    Z7_IFACES_IMP_UNK_1(ISequentialInStream)
public:
    std::shared_ptr<StreamPipe> pipe;
};
Z7_COM7F_IMF(PipeReader::Read(void *data, UInt32 size, UInt32 *processed)) {
    if (processed) *processed = 0;
    if (size == 0) return S_OK;
    std::unique_lock<std::mutex> lock(pipe->mutex);
    while (pipe->count == 0 && !pipe->finished && !pipe->stopped())
        pipe->changed.wait_for(lock, std::chrono::milliseconds(50));
    if (pipe->stopped()) return E_ABORT;
    if (pipe->count == 0) {
        // End of the decompressed stream; a failed outer stream is an error, not an end.
        bool ok = pipe->result == S_OK && pipe->itemResult == NArchive::NExtract::NOperationResult::kOK;
        return ok ? S_OK : E_FAIL;
    }
    const size_t capacity = pipe->ring.size();
    const size_t chunk = std::min({pipe->count, capacity - pipe->head, (size_t)size});
    memcpy(data, pipe->ring.data() + pipe->head, chunk);
    pipe->head = (pipe->head + chunk) % capacity; pipe->count -= chunk;
    if (processed) *processed = (UInt32)chunk;
    pipe->changed.notify_all();
    return S_OK;
}
class PipeProducerCallback final : public IArchiveExtractCallback, public CMyUnknownImp {
    Z7_IFACES_IMP_UNK_1(IArchiveExtractCallback)
    Z7_IFACE_COM7_IMP(IProgress)
public:
    std::shared_ptr<StreamPipe> pipe;
    CMyComPtr<ISequentialOutStream> writer;
    HRESULT check() { return pipe->stopped() ? E_ABORT : S_OK; }
};
Z7_COM7F_IMF(PipeProducerCallback::SetTotal(UInt64)) { return check(); }
Z7_COM7F_IMF(PipeProducerCallback::SetCompleted(const UInt64 *)) { return check(); }
Z7_COM7F_IMF(PipeProducerCallback::PrepareOperation(Int32)) { return check(); }
Z7_COM7F_IMF(PipeProducerCallback::GetStream(UInt32 index, ISequentialOutStream **stream, Int32 askMode)) {
    *stream = nullptr; RINOK(check())
    if (index != 0 || askMode != NArchive::NExtract::NAskMode::kExtract) return S_OK;
    *stream = writer; (*stream)->AddRef(); return S_OK;
}
Z7_COM7F_IMF(PipeProducerCallback::SetOperationResult(Int32 result)) {
    std::lock_guard<std::mutex> lock(pipe->mutex);
    pipe->itemResult = result;
    return S_OK;
}
/// A compressed tar opened for one sequential pass. The outer handler decompresses on a
/// producer thread; the tar handler reads the pipe through `IArchiveOpenSeq`.
struct TarStream {
    Archive outer;
    CMyComPtr<IInArchive> tar;
    std::shared_ptr<StreamPipe> pipe;
    CMyComPtr<ISequentialInStream> reader;
    std::thread producer;
    ~TarStream() { stop(); if (tar) tar->Close(); }
    void stop() {
        if (pipe) {
            { std::lock_guard<std::mutex> lock(pipe->mutex); pipe->closed = true; }
            pipe->changed.notify_all();
        }
        if (producer.joinable()) producer.join();
    }
    /// Reads the rest of the stream so the outer handler verifies its checksum.
    HRESULT drain() {
        std::vector<Byte> buffer(1 << 16);
        for (;;) {
            UInt32 read = 0;
            RINOK(reader->Read(buffer.data(), (UInt32)buffer.size(), &read))
            if (read == 0) return S_OK;
        }
    }
    HRESULT open(NSString *path, Context &ctx) {
        RINOK(Open(path, ctx, outer))
        if (!IsStreamFormat(outer.format)) return S_FALSE;
        UInt32 count = 0; RINOK(outer.handler->GetNumberOfItems(&count))
        if (count < 1) return S_FALSE;
        RINOK(CreateHandler(@"tar", &IID_IInArchive, (void **)&tar))
        CMyComPtr<IArchiveOpenSeq> sequential;
        tar.QueryInterface(IID_IArchiveOpenSeq, &sequential);
        if (!sequential) return E_NOINTERFACE;
        pipe = std::make_shared<StreamPipe>(1 << 20, ctx.operation);
        PipeReader *readerSpec = new PipeReader; reader = readerSpec; readerSpec->pipe = pipe;
        RINOK(sequential->OpenSeq(reader))
        // The producer owns its COM objects: their reference counts are not thread-safe.
        IInArchive *handler = outer.handler;
        std::shared_ptr<StreamPipe> shared = pipe;
        producer = std::thread([handler, shared] {
            PipeWriter *writerSpec = new PipeWriter;
            CMyComPtr<ISequentialOutStream> writer = writerSpec; writerSpec->pipe = shared;
            PipeProducerCallback *callbackSpec = new PipeProducerCallback;
            CMyComPtr<IArchiveExtractCallback> callback = callbackSpec;
            callbackSpec->pipe = shared; callbackSpec->writer = writer;
            const UInt32 index = 0;
            HRESULT result;
            try { result = handler->Extract(&index, 1, 0, callback); } catch (...) { result = E_FAIL; }
            callback.Release(); writer.Release();
            { std::lock_guard<std::mutex> lock(shared->mutex); shared->finished = true; shared->result = result; }
            shared->changed.notify_all();
        });
        return S_OK;
    }
};
class ListCallback final : public IArchiveExtractCallback, public CMyUnknownImp {
    Z7_IFACES_IMP_UNK_1(IArchiveExtractCallback)
    Z7_IFACE_COM7_IMP(IProgress)
public:
    Context *context;
    IInArchive *archive;
    NSMutableArray<ZFSevenZipEntry *> *entries;
};
Z7_COM7F_IMF(ListCallback::SetTotal(UInt64)) { return context->check(); }
Z7_COM7F_IMF(ListCallback::SetCompleted(const UInt64 *)) { return context->check(); }
Z7_COM7F_IMF(ListCallback::PrepareOperation(Int32)) { return context->check(); }
Z7_COM7F_IMF(ListCallback::SetOperationResult(Int32)) { return context->check(); }
Z7_COM7F_IMF(ListCallback::GetStream(UInt32 index, ISequentialOutStream **stream, Int32)) {
    *stream = nullptr; RINOK(context->check())
    try {
        if (IsSparse(archive, index)) { context->failure = 5; return E_ABORT; }
        [entries addObject:MakeEntry(archive, index)];
    } catch (...) { return E_FAIL; }
    return S_OK; // no stream: the handler skips the data
}

int OpenOutput(NSString *path, NSString *rootPath, int root,
    std::map<std::string, int> &parents) {
    NSString *prefix = [rootPath isEqualToString:@"/"] ? rootPath : [rootPath stringByAppendingString:@"/"];
    if (![path hasPrefix:prefix]) return -1;
    NSArray<NSString *> *components = [[path substringFromIndex:prefix.length] pathComponents];
    if (!components.count) return -1;
    for (NSString *component in components)
        if ([component isEqualToString:@"."] || [component isEqualToString:@".."] || [component isEqualToString:@"/"])
            return -1;
    std::string key(path.stringByDeletingLastPathComponent.fileSystemRepresentation);
    int parent;
    auto existing = parents.find(key);
    if (existing != parents.end()) parent = existing->second;
    else {
        parent = dup(root);
        if (parent < 0) return -1;
        for (NSUInteger i = 0; i + 1 < components.count; ++i) {
            int child = openat(parent, components[i].fileSystemRepresentation,
                O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
            close(parent);
            if (child < 0) return -1;
            parent = child;
        }
        if (parents.size() >= 64) {
            auto stale = parents.begin(); close(stale->second); parents.erase(stale);
        }
        parents.emplace(key, parent);
    }
    return openat(parent, path.lastPathComponent.fileSystemRepresentation,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
}

class Output final : public ISequentialOutStream, public CMyUnknownImp {
    Z7_IFACES_IMP_UNK_1(ISequentialOutStream)
public:
    int fd = -1;
    UInt64 written = 0, limit;
    Context *context;
    UInt32 mode = 0;
    bool hasMode = false;
    NSDate *modified = nil;
    ~Output() { if (fd >= 0) close(fd); }
};
Z7_COM7F_IMF(Output::Write(const void *data, UInt32 size, UInt32 *processed)) {
    if (processed) *processed = 0;
    RINOK(context->check())
    if (written > limit || size > limit - written) { context->failure = 3; return E_ABORT; }
    const char *bytes = (const char *)data;
    UInt32 done = 0;
    while (done < size) {
        ssize_t n = write(fd, bytes + done, size - done);
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0) { if (errno == ENOSPC) context->failure = 6; return E_FAIL; }
        done += (UInt32)n;
    }
    written += done; if (processed) *processed = done; return S_OK;
}
constexpr UInt32 kUnselected = UINT32_MAX;
class ExtractCallback final : public IArchiveExtractCallback, public ICryptoGetTextPassword,
    public CMyUnknownImp {
    Z7_IFACES_IMP_UNK_2(IArchiveExtractCallback, ICryptoGetTextPassword)
    Z7_IFACE_COM7_IMP(IProgress)
public:
    Context *context;
    // Archive index -> position in `destinations`; the first occurrence wins.
    std::vector<UInt32> positions;
    NSArray<NSString *> *destinations;
    UInt64 limit;
    int itemResult = 0;
    CMyComPtr<ISequentialOutStream> output;
    CMyComPtr<IInArchive> archive;
    Output *file = nullptr;
    std::map<std::string, int> parents;
    NSString *rootPath = nil;
    int root = -1;
    // A file promise grants only its own URL: without a root folder, the single output is
    // opened by that exact path and nothing else can be written.
    NSString *exactPath = nil;
    // Sequential (compressed tar) mode: destinations come from the planner per entry.
    NSString * _Nullable (^planner)(ZFSevenZipEntry *, BOOL *) = nil;
    UInt32 lastIndex = UINT32_MAX;
    UInt32 current = UINT32_MAX;
    bool stoppedEarly = false;
    ~ExtractCallback() { for (auto &parent : parents) close(parent.second); if (root >= 0) close(root); }
};
Z7_COM7F_IMF(ExtractCallback::SetTotal(UInt64)) { return context->check(); }
Z7_COM7F_IMF(ExtractCallback::SetCompleted(const UInt64 *)) { return context->check(); }
Z7_COM7F_IMF(ExtractCallback::CryptoGetTextPassword(BSTR *p)) { return context->secret(p); }
Z7_COM7F_IMF(ExtractCallback::PrepareOperation(Int32)) { return context->check(); }
Z7_COM7F_IMF(ExtractCallback::SetOperationResult(Int32 result)) {
    if (file && result == NArchive::NExtract::NOperationResult::kOK) {
        if (file->hasMode && fchmod(file->fd, file->mode & 0777) != 0) return E_FAIL;
        if (file->modified) {
            double seconds = file->modified.timeIntervalSince1970;
            timespec times[2] = {{0, UTIME_OMIT}, {(time_t)seconds, (long)((seconds - (time_t)seconds) * 1000000000)}};
            if (futimens(file->fd, times) != 0) return E_FAIL;
        }
    }
    file = nullptr; output.Release();
    if (result != NArchive::NExtract::NOperationResult::kOK) {
        itemResult = result;
        // Formats without a password check (7z AES) report a wrong password as a data or CRC
        // error in the encrypted item; 7-Zip's own UI reads it as “Wrong password?” (D-116).
        bool encryptedDataError = context->passwordRequested && context->password
            && (result == NArchive::NExtract::NOperationResult::kDataError
                || result == NArchive::NExtract::NOperationResult::kCRCError);
        if (result == NArchive::NExtract::NOperationResult::kWrongPassword || encryptedDataError) context->failure = 2;
        return E_FAIL;
    }
    // Every requested entry is written: stop decompressing the rest of the stream.
    if (planner && current == lastIndex) { stoppedEarly = true; return E_ABORT; }
    return context->check();
}
Z7_COM7F_IMF(ExtractCallback::GetStream(UInt32 index, ISequentialOutStream **stream, Int32 askMode)) {
    *stream = nullptr; file = nullptr; output.Release(); RINOK(context->check())
    NSString *destination = nil;
    if (planner) {
        if (index > lastIndex) { stoppedEarly = true; return E_ABORT; }
        ZFSevenZipEntry *entry = nil;
        try {
            if (IsSparse(archive, index)) { context->failure = 5; return E_ABORT; }
            entry = MakeEntry(archive, index);
        } catch (...) { return E_FAIL; }
        BOOL abort = NO;
        destination = planner(entry, &abort);
        if (abort) { context->failure = 7; return E_ABORT; }
        current = index;
        if (askMode != NArchive::NExtract::NAskMode::kExtract || destination.length == 0) return S_OK;
    } else {
        if (askMode != NArchive::NExtract::NAskMode::kExtract) return S_OK;
        if (index >= positions.size() || positions[index] == kUnselected) return S_OK;
        destination = destinations[positions[index]];
        if (destination.length == 0) return S_OK; // directory, created by Swift
    }
    file = new Output;
    output = file; file->context = context; file->limit = limit;
    if (root >= 0) file->fd = OpenOutput(destination, rootPath, root, parents);
    else if (exactPath && [destination isEqualToString:exactPath])
        file->fd = open(destination.fileSystemRepresentation, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
    if (file->fd < 0) { file = nullptr; output.Release(); return E_FAIL; }
    auto mode = Property(archive, index, kpidPosixAttrib);
    auto attributes = Property(archive, index, kpidAttrib);
    if (mode.vt == VT_UI4) { file->mode = mode.ulVal; file->hasMode = true; }
    else if (attributes.vt == VT_UI4 && (attributes.ulVal & 0x8000)) {
        file->mode = attributes.ulVal >> 16; file->hasMode = true;
    }
    file->modified = Date(Property(archive, index, kpidMTime));
    *stream = output; (*stream)->AddRef(); return S_OK;
}
/// Opens the destination folder, or, when the destination itself does not exist yet (a file
/// promise), restricts the extraction to creating exactly that path.
bool OpenRoot(ExtractCallback *callback, NSString *rootPath) {
    callback->root = open(rootPath.fileSystemRepresentation, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (callback->root >= 0) return true;
    if (errno != ENOENT) return false;
    callback->exactPath = rootPath;
    return true;
}
class UpdateCallback final : public IArchiveUpdateCallback2, public ICryptoGetTextPassword2,
    public CMyUnknownImp {
    Z7_IFACES_IMP_UNK_3(IArchiveUpdateCallback, IArchiveUpdateCallback2, ICryptoGetTextPassword2)
    Z7_IFACE_COM7_IMP(IProgress)
public:
    Context *context;
    NSArray<ZFSevenZipSource *> *sources;
    std::vector<UInt32> kept;
    int itemResult = 0;
};
Z7_COM7F_IMF(UpdateCallback::SetTotal(UInt64)) { return context->check(); }
Z7_COM7F_IMF(UpdateCallback::SetCompleted(const UInt64 *)) { return context->check(); }
Z7_COM7F_IMF(UpdateCallback::CryptoGetTextPassword2(Int32 *defined, BSTR *password)) {
    *defined = context->password != nil; *password = nullptr;
    return *defined ? context->secret(password) : context->check();
}
Z7_COM7F_IMF(UpdateCallback::GetUpdateItemInfo(UInt32 index, Int32 *newData, Int32 *newProps, UInt32 *archiveIndex)) {
    RINOK(context->check())
    if (index < kept.size()) { *newData = 0; *newProps = 0; *archiveIndex = kept[index]; }
    else { *newData = 1; *newProps = 1; *archiveIndex = (UInt32)-1; }
    return S_OK;
}
Z7_COM7F_IMF(UpdateCallback::GetProperty(UInt32 index, PROPID key, PROPVARIANT *value)) {
    if (index < kept.size() || index - kept.size() >= sources.count) return E_INVALIDARG;
    ZFSevenZipSource *source = sources[index - kept.size()];
    CPropVariant prop;
    switch (key) {
        case kpidPath: prop.vt = VT_BSTR; prop.bstrVal = Password(source.archivePath); break;
        case kpidIsDir: prop = (bool)source.directory; break;
        case kpidSize: prop = (UInt64)source.size; break;
        case kpidAttrib: prop = (UInt32)((source.posixMode << 16) | 0x8000 | (source.directory ? 0x10 : 0x20)); break;
        case kpidPosixAttrib: prop = (UInt32)source.posixMode; break;
        case kpidSymLink: if (source.linkTarget) { prop.vt = VT_BSTR; prop.bstrVal = Password(source.linkTarget); } break;
        case kpidMTime: {
            uint64_t ticks = (uint64_t)((source.modified.timeIntervalSince1970 + 11644473600.0) * 10000000.0);
            prop.vt = VT_FILETIME; prop.filetime.dwLowDateTime = (UInt32)ticks;
            prop.filetime.dwHighDateTime = (UInt32)(ticks >> 32); break;
        }
    }
    prop.Detach(value); return context->check();
}
Z7_COM7F_IMF(UpdateCallback::GetStream(UInt32 index, ISequentialInStream **stream)) {
    *stream = nullptr; RINOK(context->check())
    if (index < kept.size() || index - kept.size() >= sources.count) return E_INVALIDARG;
    ZFSevenZipSource *source = sources[index - kept.size()];
    if (source.directory) return S_OK;
    if (source.linkTarget) {
        const char *target = source.linkTarget.UTF8String;
        CBufInStream *buffer = new CBufInStream;
        CMyComPtr<ISequentialInStream> owner = buffer;
        buffer->Init((const Byte *)target, strlen(target));
        *stream = owner.Detach(); return S_OK;
    }
    CInFileStream *file = new CInFileStream;
    CMyComPtr<ISequentialInStream> owner = file;
    if (!file->Open(source.path.fileSystemRepresentation)) return E_FAIL;
    *stream = owner.Detach(); return S_OK;
}
Z7_COM7F_IMF(UpdateCallback::SetOperationResult(Int32 result)) {
    if (result != NArchive::NUpdate::NOperationResult::kOK) { itemResult = result; return E_FAIL; }
    return context->check();
}
Z7_COM7F_IMF(UpdateCallback::GetVolumeSize(UInt32, UInt64 *)) { return S_FALSE; }
Z7_COM7F_IMF(UpdateCallback::GetVolumeStream(UInt32, ISequentialOutStream **stream)) { *stream = nullptr; return S_FALSE; }
bool Finish(HRESULT result, Context &context, NSError **error, int itemResult = 0) {
    if (result == S_OK && !itemResult && !context.failure) return true;
    NSInteger code = context.operation->stopped.load() ? 4 : context.failure ?: 5;
    NSMutableDictionary *info = [@{ @"HRESULT": @((int32_t)result), @"itemResult": @(itemResult) } mutableCopy];
    if (context.missingVolume) info[@"missingVolume"] = context.missingVolume;
    if (error) *error = [NSError errorWithDomain:@"Zforge.SevenZip" code:code userInfo:info];
    return false;
}
}
@implementation ZFSevenZipBridge
+ (NSArray<NSString *> *)formats {
    NSMutableArray *result = [NSMutableArray array];
    UInt32 count = 0;
    if (GetNumberOfFormats(&count) != S_OK) return result;
    for (UInt32 i = 0; i < count; ++i) {
        CPropVariant name;
        if (GetHandlerProperty2(i, NArchive::NHandlerPropID::kName, &name) == S_OK && name.vt == VT_BSTR)
            [result addObject:String(name.bstrVal)];
    }
    return result;
}
+ (BOOL)isCompressedTarPath:(NSString *)path { return IsCompressedTar(path); }
+ (NSArray<ZFSevenZipEntry *> *)entriesAtPath:(NSString *)path password:(NSString *)password
    operation:(ZFSevenZipOperation *)operation error:(NSError **)error {
    Context ctx{operation, password};
    try {
        if (IsCompressedTar(path)) {
            // One decompression pass reads every tar header; nothing is written.
            TarStream stream;
            if (!Finish(stream.open(path, ctx), ctx, error)) return nil;
            NSMutableArray *entries = [NSMutableArray array];
            ListCallback *callback = new ListCallback;
            CMyComPtr<IArchiveExtractCallback> owner = callback;
            callback->context = &ctx; callback->archive = stream.tar; callback->entries = entries;
            HRESULT result = stream.tar->Extract(nullptr, (UInt32)-1, 0, owner);
            if (result == S_OK) result = stream.drain();
            stream.stop();
            if (result == S_OK && !stream.pipe->succeeded()) result = E_FAIL;
            if (result == S_OK && entries.count == 0) {
                CPropVariant flags;
                if (stream.tar->GetArchiveProperty(kpidErrorFlags, &flags) == S_OK && flags.vt == VT_UI4 && flags.ulVal)
                    result = S_FALSE;
            }
            if (!Finish(result, ctx, error)) return nil;
            for (ZFSevenZipEntry *entry in entries) { entry.solidBlock = YES; entry.solidBlockPackedSize = @(ctx.sourceSize); }
            return entries;
        }
        Archive arc; if (!Finish(Open(path, ctx, arc), ctx, error)) return nil;
        UInt32 count; if (!Finish(arc.handler->GetNumberOfItems(&count), ctx, error)) return nil;
        NSMutableArray *entries = [NSMutableArray arrayWithCapacity:count];
        for (UInt32 i = 0; i < count; ++i) {
            if (!Finish(ctx.check(), ctx, error)) return nil;
            [entries addObject:MakeEntry(arc.handler, i)];
        }
        ApplySolidBlocks(arc, entries, ctx.sourceSize);
        return entries;
    } catch (...) { Finish(E_FAIL, ctx, error); return nil; }
}
+ (BOOL)testAtPath:(NSString *)path password:(NSString *)password
    operation:(ZFSevenZipOperation *)operation error:(NSError **)error {
    Context ctx{operation, password};
    try {
        Archive arc; if (!Finish(Open(path, ctx, arc), ctx, error)) return NO;
        ExtractCallback *callback = new ExtractCallback;
        CMyComPtr<IArchiveExtractCallback> owner = callback;
        callback->context = &ctx;
        HRESULT result = arc.handler->Extract(nullptr, (UInt32)-1, 1, owner);
        return Finish(result, ctx, error, callback->itemResult);
    } catch (...) { return Finish(E_FAIL, ctx, error); }
}
+ (BOOL)extractAtPath:(NSString *)path password:(NSString *)password
    indices:(NSArray<NSNumber *> *)indices destinations:(NSArray<NSString *> *)destinations
    rootPath:(NSString *)rootPath byteLimit:(uint64_t)byteLimit operation:(ZFSevenZipOperation *)operation error:(NSError **)error {
    Context ctx{operation, password};
    try {
        if (indices.count != destinations.count) return Finish(E_INVALIDARG, ctx, error);
        Archive arc; if (!Finish(Open(path, ctx, arc), ctx, error)) return NO;
        UInt32 count = 0;
        if (!Finish(arc.handler->GetNumberOfItems(&count), ctx, error)) return NO;
        ExtractCallback *callback = new ExtractCallback;
        CMyComPtr<IArchiveExtractCallback> owner = callback;
        // A direct table keeps each callback O(1); a linear search per item made
        // extracting n selected items O(n^2).
        callback->positions.assign(count, kUnselected);
        std::vector<UInt32> selected;
        selected.reserve(indices.count);
        UInt32 position = 0;
        for (NSNumber *number in indices) {
            UInt32 index = number.unsignedIntValue;
            // The archive is read in place: if it was replaced since it was listed, an index
            // can be past its items, and the handlers do not check (out-of-bounds read).
            if (index >= count) return Finish(E_INVALIDARG, ctx, error);
            selected.push_back(index);
            if (index < count && callback->positions[index] == kUnselected) callback->positions[index] = position;
            ++position;
        }
        std::sort(selected.begin(), selected.end());
        selected.erase(std::unique(selected.begin(), selected.end()), selected.end());
        callback->context = &ctx; callback->archive = arc.handler;
        callback->destinations = destinations; callback->limit = byteLimit;
        callback->rootPath = rootPath;
        if (!OpenRoot(callback, rootPath)) return Finish(E_FAIL, ctx, error);
        HRESULT result = selected.empty() ? S_OK : arc.handler->Extract(selected.data(), (UInt32)selected.size(), 0, owner);
        return Finish(result, ctx, error, callback->itemResult);
    } catch (...) { return Finish(E_FAIL, ctx, error); }
}
+ (BOOL)extractPlannedAtPath:(NSString *)path password:(NSString *)password rootPath:(NSString *)rootPath
    byteLimit:(uint64_t)byteLimit lastIndex:(uint32_t)lastIndex
    planner:(NSString * _Nullable (^)(ZFSevenZipEntry *, BOOL *))planner
    ready:(BOOL (^)(void))ready
    operation:(ZFSevenZipOperation *)operation error:(NSError **)error {
    Context ctx{operation, password};
    try {
        // The archive is read in place: plan and extract from this one opening, after the
        // caller confirmed it is still the archive it listed (nothing written before that).
        if (IsCompressedTar(path)) {
            TarStream stream;
            if (!Finish(stream.open(path, ctx), ctx, error)) return NO;
            if (ready && !ready()) { ctx.failure = 8; return Finish(E_ABORT, ctx, error); }
            ExtractCallback *callback = new ExtractCallback;
            CMyComPtr<IArchiveExtractCallback> owner = callback;
            callback->context = &ctx; callback->archive = stream.tar;
            callback->limit = byteLimit; callback->rootPath = rootPath;
            callback->planner = planner; callback->lastIndex = lastIndex;
            if (!OpenRoot(callback, rootPath)) return Finish(E_FAIL, ctx, error);
            HRESULT result = stream.tar->Extract(nullptr, (UInt32)-1, 0, owner);
            const bool early = callback->stoppedEarly && result == E_ABORT && !ctx.failure && !operation->stopped.load();
            if (early) result = S_OK;
            // A full pass also verifies the outer stream (its checksum follows the tar data).
            else if (result == S_OK) result = stream.drain();
            stream.stop();
            if (result == S_OK && !early && !stream.pipe->succeeded()) result = E_FAIL;
            return Finish(result, ctx, error, callback->itemResult);
        }
        Archive arc;
        if (!Finish(Open(path, ctx, arc), ctx, error)) return NO;
        if (ready && !ready()) { ctx.failure = 8; return Finish(E_ABORT, ctx, error); }
        UInt32 count = 0;
        if (!Finish(arc.handler->GetNumberOfItems(&count), ctx, error)) return NO;
        ExtractCallback *callback = new ExtractCallback;
        CMyComPtr<IArchiveExtractCallback> owner = callback;
        callback->positions.assign(count, kUnselected);
        NSMutableArray<NSString *> *destinations = [NSMutableArray array];
        std::vector<UInt32> selected;
        for (UInt32 i = 0; i < count; ++i) {
            if (!Finish(ctx.check(), ctx, error)) return NO;
            BOOL abort = NO;
            NSString *destination = planner(MakeEntry(arc.handler, i), &abort);
            if (abort) { ctx.failure = 7; return Finish(E_ABORT, ctx, error); }
            if (destination.length == 0) continue;
            callback->positions[i] = (UInt32)destinations.count;
            [destinations addObject:destination];
            selected.push_back(i);
        }
        callback->context = &ctx; callback->archive = arc.handler;
        callback->destinations = destinations; callback->limit = byteLimit;
        callback->rootPath = rootPath;
        if (!OpenRoot(callback, rootPath)) return Finish(E_FAIL, ctx, error);
        HRESULT result = selected.empty() ? S_OK : arc.handler->Extract(selected.data(), (UInt32)selected.size(), 0, owner);
        return Finish(result, ctx, error, callback->itemResult);
    } catch (...) { return Finish(E_FAIL, ctx, error); }
}
+ (BOOL)writeAtPath:(NSString *)path format:(NSString *)format updatingPath:(NSString *)updatingPath
    sources:(NSArray<ZFSevenZipSource *> *)sources properties:(NSDictionary<NSString *, id> *)properties
    excludingPaths:(NSArray<NSString *> *)excludingPaths password:(NSString *)password
    volumeSizes:(NSArray<NSNumber *> *)volumeSizes operation:(ZFSevenZipOperation *)operation error:(NSError **)error {
    Context ctx{operation, password};
    try {
        Archive old;
        CMyComPtr<IOutArchive> writer;
        if (updatingPath) {
            if (!Finish(Open(updatingPath, ctx, old), ctx, error)) return NO;
            if (!Finish(old.handler->QueryInterface(IID_IOutArchive, (void **)&writer), ctx, error)) return NO;
        } else if (CreateHandler(format, &IID_IOutArchive, (void **)&writer) != S_OK) {
            writer.Release();
        }
        if (!writer) return Finish(E_NOINTERFACE, ctx, error);
        NSMutableDictionary *effective = [properties mutableCopy];
        if (old.handler && password) {
            if ([format isEqualToString:@"7z"] && ctx.passwordRequested) effective[@"he"] = @YES;
            if ([format isEqualToString:@"zip"]) {
                UInt32 count = 0; old.handler->GetNumberOfItems(&count);
                for (UInt32 i = 0; i < count; ++i) {
                    auto encrypted = Property(old.handler, i, kpidEncrypted);
                    if (encrypted.vt != VT_BOOL || encrypted.boolVal == VARIANT_FALSE) continue;
                    auto method = Property(old.handler, i, kpidMethod);
                    if (method.vt == VT_BSTR && [String(method.bstrVal) containsString:@"AES"])
                        effective[@"em"] = @"AES256";
                    else effective[@"em"] = @"ZipCrypto";
                    break;
                }
            }
        }
        if (effective.count) {
            CMyComPtr<ISetProperties> setter;
            if (!Finish(writer->QueryInterface(IID_ISetProperties, (void **)&setter), ctx, error)) return NO;
            std::vector<UString> storage;
            std::vector<CPropVariant> values;
            for (NSString *key in effective) {
                BSTR b = Password(key); storage.emplace_back(b); SysFreeString(b);
                CPropVariant v; id value = effective[key];
                if ([value isKindOfClass:[NSString class]]) { v.vt = VT_BSTR; v.bstrVal = Password(value); }
                else if (CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID()) v = (bool)[value boolValue];
                else v = (UInt32)[value unsignedIntValue];
                values.push_back(v);
            }
            std::vector<const wchar_t *> names;
            for (const auto &name : storage) names.push_back(name.Ptr());
            if (!Finish(setter->SetProperties(names.data(), values.data(), (UInt32)names.size()), ctx, error)) return NO;
        }
        UpdateCallback *callback = new UpdateCallback;
        CMyComPtr<IArchiveUpdateCallback2> owner = callback;
        callback->context = &ctx; callback->sources = sources;
        if (old.handler) {
            UInt32 count = 0; old.handler->GetNumberOfItems(&count);
            NSMutableSet *replaced = [NSMutableSet set];
            for (ZFSevenZipSource *source in sources) [replaced addObject:source.archivePath];
            for (UInt32 i = 0; i < count; ++i) {
                auto name = Property(old.handler, i, kpidPath);
                NSString *itemPath = name.vt == VT_BSTR ? String(name.bstrVal) : @"";
                BOOL excluded = NO;
                for (NSString *removed in excludingPaths) {
                    if ([itemPath isEqualToString:removed] || [itemPath hasPrefix:[removed stringByAppendingString:@"/"]]) {
                        excluded = YES; break;
                    }
                }
                if (!excluded && ![replaced containsObject:itemPath]) callback->kept.push_back(i);
            }
        }
        if (volumeSizes.count) {
            // Split output (ZF-83): `path.001`, `path.002`… of the given sizes, the last size
            // repeating. 7-Zip's multi-volume stream is seekable (the 7z writer goes back to
            // its start header) and deletes every volume unless the write succeeds.
            CMultiOutStream *volumes = new CMultiOutStream;
            CMyComPtr<IOutStream> output = volumes;
            volumes->Prefix = FString(path.fileSystemRepresentation);
            volumes->Prefix.Add_Dot();
            CRecordVector<UInt64> sizes;
            for (NSNumber *size in volumeSizes) {
                if (size.unsignedLongLongValue == 0) return Finish(E_INVALIDARG, ctx, error);
                sizes.Add(size.unsignedLongLongValue);
            }
            volumes->Init(sizes);
            volumes->NeedDelete = true;
            HRESULT result = writer->UpdateItems(output, (UInt32)(callback->kept.size() + sources.count), owner);
            if (result == S_OK && !callback->itemResult && !ctx.failure) {
                unsigned count = 0;
                result = volumes->FinalFlush_and_CloseFiles(count);
                if (result == S_OK) volumes->NeedDelete = false;
            }
            output.Release();
            return Finish(result, ctx, error, callback->itemResult);
        }
        COutFileStream *file = new COutFileStream;
        CMyComPtr<IOutStream> output = file;
        if (!file->Create_NEW(path.fileSystemRepresentation)) return Finish(E_FAIL, ctx, error);
        HRESULT result = writer->UpdateItems(output, (UInt32)(callback->kept.size() + sources.count), owner);
        output.Release();
        return Finish(result, ctx, error, callback->itemResult);
    } catch (...) { return Finish(E_FAIL, ctx, error); }
}

@end

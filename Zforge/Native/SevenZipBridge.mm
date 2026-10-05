// SPDX-License-Identifier: LGPL-2.1-or-later
// Zforge native adapter; see Vendor/7zip/DOC/copying.txt.
#include <atomic>
#include <fcntl.h>
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
#include "../../Vendor/7zip/CPP/7zip/Common/StreamObjects.h"
#include "../../Vendor/7zip/CPP/7zip/Archive/IArchive.h"
#include "../../Vendor/7zip/CPP/7zip/Archive/Common/MultiStream.h"
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
@implementation ZFSevenZipOperation { @public std::atomic<bool> stopped; }
- (instancetype)init { if ((self = [super init])) stopped.store(false); return self; }
- (void)cancel { stopped.store(true); }
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
    HRESULT check() { return operation->stopped.load() ? E_ABORT : S_OK; }
    HRESULT secret(BSTR *result) {
        *result = nullptr;
        passwordRequested = true;
        if (!password) { failure = 1; return E_ABORT; }
        *result = Password(password);
        return *result ? S_OK : E_OUTOFMEMORY;
    }
};
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
    // Only staged sibling files are available to the handler.
    CInFileStream *input = new CInFileStream;
    CMyComPtr<IInStream> owner = input;
    if (!input->Open(candidate.fileSystemRepresentation)) return S_FALSE;
    *stream = owner.Detach(); return context->check();
}
struct Archive {
    CMyComPtr<IInArchive> handler;
    CMyComPtr<IInStream> input;
    ~Archive() { if (handler) handler->Close(); }
};
HRESULT Input(NSString *path, CMyComPtr<IInStream> &result) {
    NSString *base = path.stringByDeletingPathExtension;
    bool split = [path.pathExtension isEqualToString:@"001"] &&
        ([@"7z" isEqualToString:base.pathExtension.lowercaseString] || [@"zip" isEqualToString:base.pathExtension.lowercaseString]);
    if (!split) {
        CInFileStream *file = new CInFileStream; result = file;
        return file->Open(path.fileSystemRepresentation) ? S_OK : E_FAIL;
    }
    NSArray<NSString *> *siblings = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path.stringByDeletingLastPathComponent error:nil];
    NSString *prefix = [base.lastPathComponent stringByAppendingString:@"."];
    NSMutableArray<NSString *> *volumes = [NSMutableArray array];
    for (NSString *name in siblings) {
        if (![name hasPrefix:prefix]) continue;
        NSString *suffix = [name substringFromIndex:prefix.length];
        if (suffix.length != 3 || [suffix rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location != NSNotFound) continue;
        [volumes addObject:name];
    }
    [volumes sortUsingSelector:@selector(compare:)];
    CMultiStream *multi = new CMultiStream; result = multi;
    unsigned index = 1;
    for (NSString *name in volumes) {
        if (name.pathExtension.intValue != index++) return E_FAIL;
        CInFileStream *file = new CInFileStream;
        CMultiStream::CSubStreamInfo sub;
        sub.Stream = file;
        NSString *volume = [path.stringByDeletingLastPathComponent stringByAppendingPathComponent:name];
        if (!file->Open(volume.fileSystemRepresentation) || !file->GetLength(sub.Size)) return E_FAIL;
        multi->Streams.Add(sub);
    }
    return multi->Streams.IsEmpty() ? E_FAIL : multi->Init();
}
HRESULT Open(NSString *path, Context &ctx, Archive &arc) {
    UInt32 count = 0; RINOK(GetNumberOfFormats(&count))
    // Try extension matches first, then probe remaining registered handlers.
    NSString *extension = path.pathExtension.lowercaseString;
    if ([extension isEqualToString:@"001"]) extension = path.stringByDeletingPathExtension.pathExtension.lowercaseString;
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
        RINOK(Input(path, input))
        OpenCallback *callback = new OpenCallback;
        CMyComPtr<IArchiveOpenCallback> owner = callback;
        callback->context = &ctx; callback->path = path;
        UInt64 scan = 8 * 1024 * 1024;
        HRESULT result = handler->Open(input, &scan, owner);
        if (ctx.passwordRequested && ctx.password && (result == S_FALSE || result == E_FAIL)) ctx.failure = 2;
        if (ctx.failure || result == E_ABORT) return E_ABORT;
        if (result == S_OK) { arc.handler = handler; arc.input = input; return S_OK; }
        handler->Close();
    }
    return S_FALSE;
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
class ExtractCallback final : public IArchiveExtractCallback, public ICryptoGetTextPassword,
    public CMyUnknownImp {
    Z7_IFACES_IMP_UNK_2(IArchiveExtractCallback, ICryptoGetTextPassword)
    Z7_IFACE_COM7_IMP(IProgress)
public:
    Context *context;
    NSArray<NSNumber *> *indices;
    NSArray<NSString *> *destinations;
    UInt64 limit;
    int itemResult = 0;
    CMyComPtr<ISequentialOutStream> output;
    CMyComPtr<IInArchive> archive;
    Output *file = nullptr;
    std::map<std::string, int> parents;
    NSString *rootPath = nil;
    int root = -1;
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
        if (result == NArchive::NExtract::NOperationResult::kWrongPassword) context->failure = 2;
        return E_FAIL;
    }
    return context->check();
}
Z7_COM7F_IMF(ExtractCallback::GetStream(UInt32 index, ISequentialOutStream **stream, Int32 askMode)) {
    *stream = nullptr; file = nullptr; output.Release(); RINOK(context->check())
    if (askMode != NArchive::NExtract::NAskMode::kExtract) return S_OK;
    NSUInteger position = [indices indexOfObject:@(index)];
    if (position == NSNotFound) return S_OK;
    NSString *destination = destinations[position];
    if (destination.length == 0) return S_OK; // directory, created by Swift
    file = new Output;
    output = file; file->context = context; file->limit = limit;
    file->fd = OpenOutput(destination, rootPath, root, parents);
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
    if (error) *error = [NSError errorWithDomain:@"Zforge.SevenZip" code:code userInfo:@{
        @"HRESULT": @((int32_t)result), @"itemResult": @(itemResult)
    }];
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
+ (NSArray<ZFSevenZipEntry *> *)entriesAtPath:(NSString *)path password:(NSString *)password
    operation:(ZFSevenZipOperation *)operation error:(NSError **)error {
    Context ctx{operation, password};
    try {
        Archive arc; if (!Finish(Open(path, ctx, arc), ctx, error)) return nil;
        UInt32 count; if (!Finish(arc.handler->GetNumberOfItems(&count), ctx, error)) return nil;
        NSMutableArray *entries = [NSMutableArray arrayWithCapacity:count];
        for (UInt32 i = 0; i < count; ++i) {
            if (!Finish(ctx.check(), ctx, error)) return nil;
            ZFSevenZipEntry *entry = [ZFSevenZipEntry new]; entry.index = i;
            auto name = Property(arc.handler, i, kpidPath);
            entry.path = name.vt == VT_BSTR ? String(name.bstrVal) : @"";
            auto folder = Property(arc.handler, i, kpidIsDir);
            entry.directory = folder.vt == VT_BOOL && folder.boolVal != VARIANT_FALSE;
            auto crypt = Property(arc.handler, i, kpidEncrypted);
            entry.encrypted = crypt.vt == VT_BOOL && crypt.boolVal != VARIANT_FALSE;
            entry.size = Number(Property(arc.handler, i, kpidSize));
            entry.packedSize = Number(Property(arc.handler, i, kpidPackSize));
            auto mode = Property(arc.handler, i, kpidPosixAttrib);
            entry.posixMode = Number(mode);
            auto attributes = Property(arc.handler, i, kpidAttrib);
            if (!entry.posixMode && attributes.vt == VT_UI4 && (attributes.ulVal & 0x8000)) entry.posixMode = @(attributes.ulVal >> 16);
            auto link = Property(arc.handler, i, kpidSymLink);
            entry.symbolicLink = ([entry.posixMode unsignedIntValue] & 0170000) == 0120000 || link.vt == VT_BSTR;
            entry.modified = Date(Property(arc.handler, i, kpidMTime));
            entry.created = Date(Property(arc.handler, i, kpidCTime));
            entry.accessed = Date(Property(arc.handler, i, kpidATime));
            auto crc = Property(arc.handler, i, kpidCRC);
            if (crc.vt == VT_UI4) entry.checksum = [NSString stringWithFormat:@"%08X", crc.ulVal];
            auto method = Property(arc.handler, i, kpidMethod);
            if (method.vt == VT_BSTR) entry.method = String(method.bstrVal);
            [entries addObject:entry];
        }
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
        std::vector<UInt32> selected;
        for (NSNumber *index in indices) selected.push_back(index.unsignedIntValue);
        std::sort(selected.begin(), selected.end());
        selected.erase(std::unique(selected.begin(), selected.end()), selected.end());
        ExtractCallback *callback = new ExtractCallback;
        CMyComPtr<IArchiveExtractCallback> owner = callback;
        callback->context = &ctx; callback->archive = arc.handler; callback->indices = indices;
        callback->destinations = destinations; callback->limit = byteLimit;
        callback->rootPath = rootPath;
        callback->root = open(rootPath.fileSystemRepresentation, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
        if (callback->root < 0) return Finish(E_FAIL, ctx, error);
        HRESULT result = selected.empty() ? S_OK : arc.handler->Extract(selected.data(), (UInt32)selected.size(), 0, owner);
        return Finish(result, ctx, error, callback->itemResult);
    } catch (...) { return Finish(E_FAIL, ctx, error); }
}
+ (BOOL)writeAtPath:(NSString *)path format:(NSString *)format updatingPath:(NSString *)updatingPath
    sources:(NSArray<ZFSevenZipSource *> *)sources properties:(NSDictionary<NSString *, id> *)properties
    excludingPaths:(NSArray<NSString *> *)excludingPaths password:(NSString *)password operation:(ZFSevenZipOperation *)operation error:(NSError **)error {
    Context ctx{operation, password};
    try {
        Archive old;
        CMyComPtr<IOutArchive> writer;
        if (updatingPath) {
            if (!Finish(Open(updatingPath, ctx, old), ctx, error)) return NO;
            if (!Finish(old.handler->QueryInterface(IID_IOutArchive, (void **)&writer), ctx, error)) return NO;
        } else {
            UInt32 count = 0; GetNumberOfFormats(&count);
            for (UInt32 i = 0; i < count; ++i) {
                CPropVariant name; GetHandlerProperty2(i, NArchive::NHandlerPropID::kName, &name);
                if (name.vt != VT_BSTR || ![String(name.bstrVal) isEqualToString:format]) continue;
                CPropVariant id; GetHandlerProperty2(i, NArchive::NHandlerPropID::kClassID, &id);
                if (id.vt != VT_BSTR || SysStringByteLen(id.bstrVal) != sizeof(GUID)) continue;
                GUID cls; memcpy(&cls, id.bstrVal, sizeof(cls));
                if (!Finish(CreateObject(&cls, &IID_IOutArchive, (void **)&writer), ctx, error)) return NO;
                break;
            }
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
        COutFileStream *file = new COutFileStream;
        CMyComPtr<IOutStream> output = file;
        if (!file->Create_NEW(path.fileSystemRepresentation)) return Finish(E_FAIL, ctx, error);
        HRESULT result = writer->UpdateItems(output, (UInt32)(callback->kept.size() + sources.count), owner);
        output.Release();
        return Finish(result, ctx, error, callback->itemResult);
    } catch (...) { return Finish(E_FAIL, ctx, error); }
}

@end

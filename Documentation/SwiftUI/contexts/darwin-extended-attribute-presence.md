---
title: "getattrlist(2): extended attribute presence"
source_url: "https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/getattrlist.2"
source_identifier: "bsd/man/man2/getattrlist.2"
captured_at: "2026-10-06T11:31:43.784528+00:00"
source_sha256: "b1398933bf3178aa2783a241b2aabcdbaa4dd118278f6c06e2a08221bb1305f5"
source_etag: null
source_last_modified: null
source_format: "text/plain"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Open Source"
confidence: "primary-source"
---

# Extended attribute presence

## Quick reference

- Module: Darwin; signatures and constants verified with macOS SDK 27.0.
- Request: `ATTR_CMNEXT_EXT_FLAGS` in `forkattr`, with `FSOPT_ATTR_CMN_EXTENDED`.
- Result: a `uint64_t` extended-flags field, decoded only when returned.

## Summary

Apple defines EF_NO_XATTRS as confirmation that the inode has no extended attributes. The extended option interprets fork attributes as additional common attributes. Returned-attribute masks identify which fields are present; absence of the extended field cannot establish absence of tags. Attributes have defined ordering and packing. With PACK_INVAL_ATTRS the requested error slot is reserved immediately after returned masks, including successful entries; verify the layout against the target SDK and real payloads.

## Practical implications

- Skip tag-xattr syscalls only for confirmed attribute-free inodes.
- Preserve reads when the flag is unavailable, and for symlinks whose target may carry tags.
- Monitoring begins before scanning so attributes added after a bulk snapshot receive incremental reads.
- System provenance is itself an xattr; benchmark both presence and absence rather than assuming every untagged file is attribute-free.

## Content map

- Attribute buffer and returned masks.
- Common attributes, extended common flags and options.

## Second-level links

- [access(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/access.2) — expand on demand.
- [chflags(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/chflags.2) — expand on demand.
- [clonefileat(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/clonefileat.2) — expand on demand.
- [copyfile(3)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/copyfile.3.html) — expand on demand.
- [exchangedata(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/exchangedata.2) — expand on demand.
- [fcntl(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/fcntl.2) — expand on demand.
- [flock(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/flock.2) — expand on demand.
- [fs_snapshot_create(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/fs_snapshot_create.2) — expand on demand.
- [getattrlist(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/getattrlist.2) — expand on demand.
- [getattrlistbulk(2)](darwin-bulk-directory-attributes.md) — captured locally.
- [getdirentriesattr(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/getdirentriesattr.2) — expand on demand.
- [ioctl(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/ioctl.2) — expand on demand.
- [mount(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/mount.2) — expand on demand.
- [open(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/open.2) — expand on demand.
- [rename(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/rename.2) — expand on demand.
- [searchfs(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/searchfs.2) — expand on demand.
- [setattrlist(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/setattrlist.2) — expand on demand.
- [setxattr(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/setxattr.2) — expand on demand.
- [stat(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/stat.2) — expand on demand.
- [statfs(2)](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/statfs.2) — expand on demand.

## Provenance

- [Apple Open Source](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/getattrlist.2).
- Captured: `2026-10-06T11:31:43.784528+00:00`; SHA-256 `b1398933bf3178aa2783a241b2aabcdbaa4dd118278f6c06e2a08221bb1305f5`.
- One manual page; local SDK also verifies the declaration.

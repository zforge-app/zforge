---
title: "MDQuerySetDispatchQueue(_:_:)"
source_url: "https://developer.apple.com/documentation/coreservices/1413019-mdquerysetdispatchqueue"
source_identifier: "doc://com.apple.documentation/documentation/coreservices/1413019-mdquerysetdispatchqueue"
captured_at: "2026-10-02T23:16:46.165601+00:00"
source_sha256: "a5be85a0ceb331866f230722e99637c830cefadc7cb71e2ffb00c17b0b669033"
source_etag: "\"6d14-65b3a4660f3b0\""
source_last_modified: "Fri, 11 Sep 2026 19:41:47 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# MDQuerySetDispatchQueue(_:_:)

## Quick reference

- Plataforma: macOS; signatures with the SDK macOS 27.0 of the local Xcode.
- Declaration: `func MDQuerySetDispatchQueue(MDQuery!, dispatch_queue_t!)`.
- Use in Zforge: Global catalog of tags, query and monitoring of authorized files.

## Summary

Choose the dispatch queue before executing a query. A synchronous query does not use the dispatch queue setting. Zforge delivers metadata updates on the main queue.

## Content map



## Second-level links

- [Core Services](https://developer.apple.com/documentation/coreservices)
- [MDQuerySetDispatchQueue(_:_:)](https://developer.apple.com/documentation/coreservices/1413019-mdquerysetdispatchqueue)
- [MDQueryCreateSubset(_:_:_:_:_:)](https://developer.apple.com/documentation/coreservices/1413027-mdquerycreatesubset)
- [MDQueryCreate(_:_:_:_:)](https://developer.apple.com/documentation/coreservices/1413029-mdquerycreate)
- [MDQuerySetSearchScope(_:_:_:)](https://developer.apple.com/documentation/coreservices/1413048-mdquerysetsearchscope)
- [MDQueryExecute(_:_:)](https://developer.apple.com/documentation/coreservices/1413099-mdqueryexecute)
- [File Metadata](https://developer.apple.com/documentation/coreservices/file_metadata)
- [MDQuery](https://developer.apple.com/documentation/coreservices/file_metadata/mdquery)
- [kMDQuerySynchronous](https://developer.apple.com/documentation/coreservices/kmdquerysynchronous)
- [MDQuery](https://developer.apple.com/documentation/coreservices/mdquery)
- [dispatch_queue_t](https://developer.apple.com/documentation/dispatch/dispatch_queue_t)
- [Technologies](https://developer.apple.com/documentation/technologies)

## Provenance

Official source: [MDQuerySetDispatchQueue(_:_:)](https://developer.apple.com/documentation/coreservices/1413019-mdquerysetdispatchqueue). Payload DocC captured in 2026-10-02T23:16:46.165601+00:00; SHA-256 `a5be85a0ceb331866f230722e99637c830cefadc7cb71e2ffb00c17b0b669033`.

---
title: "FSEventStreamCreate(_:_:_:_:_:_:_:)"
source_url: "https://developer.apple.com/documentation/coreservices/1443980-fseventstreamcreate"
source_identifier: "doc://com.apple.documentation/documentation/coreservices/1443980-fseventstreamcreate"
captured_at: "2026-10-02T23:16:46.165601+00:00"
source_sha256: "d9f910e072c348dc4c2676cff66e2acf8f68eb9004ae46ca349b786a4446f95a"
source_etag: "\"8d50-65b3a476677cf\""
source_last_modified: "Fri, 11 Sep 2026 19:42:04 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# FSEventStreamCreate(_:_:_:_:_:_:_:)

## Consulta rápida

- Plataforma: macOS; assinaturas conferidas com o SDK macOS 27.0 do Xcode local.
- Declaração: `func FSEventStreamCreate(CFAllocator?, FSEventStreamCallback, UnsafeMutablePointer<FSEventStreamContext>?, CFArray, FSEventStreamEventId, CFTimeInterval, FSEventStreamCreateFlags) -> FSEventStreamRef?`.
- Uso no Zforge: catálogo global de tags, consulta e monitoramento de arquivos autorizados.

## Síntese

Create a stream with watched paths, callback, copied context and a starting event ID. Use the since-now constant for a new live watcher. Schedule, start, stop, invalidate and release the stream explicitly.

## Mapa do conteúdo



## Links do segundo nível

- [CFAllocator](https://developer.apple.com/documentation/corefoundation/cfallocator)
- [CFArray](https://developer.apple.com/documentation/corefoundation/cfarray)
- [CFTimeInterval](https://developer.apple.com/documentation/corefoundation/cftimeinterval)
- [Core Services](https://developer.apple.com/documentation/coreservices)
- [File System Events](https://developer.apple.com/documentation/coreservices/file_system_events)
- [FSEventStreamCallback](https://developer.apple.com/documentation/coreservices/fseventstreamcallback)
- [FSEventStreamContext](https://developer.apple.com/documentation/coreservices/fseventstreamcontext)
- [FSEventStreamCreateFlags](https://developer.apple.com/documentation/coreservices/fseventstreamcreateflags)
- [FSEventStreamEventId](https://developer.apple.com/documentation/coreservices/fseventstreameventid)
- [FSEventStreamRef](https://developer.apple.com/documentation/coreservices/fseventstreamref)
- [UnsafeMutablePointer](https://developer.apple.com/documentation/swift/unsafemutablepointer)
- [Technologies](https://developer.apple.com/documentation/technologies)

## Proveniência

Fonte oficial: [FSEventStreamCreate(_:_:_:_:_:_:_:)](https://developer.apple.com/documentation/coreservices/1443980-fseventstreamcreate). Payload DocC capturado em 2026-10-02T23:16:46.165601+00:00; SHA-256 `d9f910e072c348dc4c2676cff66e2acf8f68eb9004ae46ca349b786a4446f95a`.

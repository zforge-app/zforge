---
title: "NSMetadataQuery"
source_url: "https://developer.apple.com/documentation/foundation/nsmetadataquery"
source_identifier: "doc://com.apple.foundation/documentation/Foundation/NSMetadataQuery"
captured_at: "2026-10-02T23:16:46.165601+00:00"
source_sha256: "b36d9c2b3e4fae89fb6e5c6b14394b86eee3eb30b99db5c0b1c17c93c523bef5"
source_etag: "\"10756-65902a0d6c594\""
source_last_modified: "Fri, 14 Aug 2026 14:28:03 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSMetadataQuery

## Quick reference

- Plataforma: macOS; signatures with the SDK macOS 27.0 of the local Xcode.
- Declaration: `class NSMetadataQuery`.
- Use in Zforge: Global catalog of tags, query and monitoring of authorized files.

## Summary

NSMetadataQuery wraps Spotlight queries. Set a predicate before starting, configure search scopes, and use gathering and update notifications. Spotlight results are not proof that every authorized file was indexed.

## Content map

- Configuring queries
- Running queries
- Getting query results
- Working with notifications
- Working with notification messages
- Constants

## Second-level links

- [MDQuery](https://developer.apple.com/documentation/coreservices/file_metadata/mdquery)
- [Foundation](https://developer.apple.com/documentation/foundation)
- [Content Relevance](https://developer.apple.com/documentation/foundation/content-relevance)
- [Keys for Use with a Notification Info Dictionary](https://developer.apple.com/documentation/foundation/keys-for-use-with-a-notification-info-dictionary)
- [Metadata Query Search Scopes](https://developer.apple.com/documentation/foundation/metadata-query-search-scopes)
- [NSMetadataItem](https://developer.apple.com/documentation/foundation/nsmetadataitem)
- [NSMetadataQuery](https://developer.apple.com/documentation/foundation/nsmetadataquery)
- [delegate](https://developer.apple.com/documentation/foundation/nsmetadataquery/delegate)
- [NSMetadataQuery.DidFinishGatheringMessage](https://developer.apple.com/documentation/foundation/nsmetadataquery/didfinishgatheringmessage)
- [NSMetadataQuery.DidStartGatheringMessage](https://developer.apple.com/documentation/foundation/nsmetadataquery/didstartgatheringmessage)
- [disableUpdates()](https://developer.apple.com/documentation/foundation/nsmetadataquery/disableupdates())
- [enableUpdates()](https://developer.apple.com/documentation/foundation/nsmetadataquery/enableupdates())
- [enumerateResults(_:)](https://developer.apple.com/documentation/foundation/nsmetadataquery/enumerateresults(_:))
- [enumerateResults(options:using:)](https://developer.apple.com/documentation/foundation/nsmetadataquery/enumerateresults(options:using:))
- [groupedResults](https://developer.apple.com/documentation/foundation/nsmetadataquery/groupedresults)
- [groupingAttributes](https://developer.apple.com/documentation/foundation/nsmetadataquery/groupingattributes)
- [index(ofResult:)](https://developer.apple.com/documentation/foundation/nsmetadataquery/index(ofresult:))
- [isGathering](https://developer.apple.com/documentation/foundation/nsmetadataquery/isgathering)
- [isStarted](https://developer.apple.com/documentation/foundation/nsmetadataquery/isstarted)
- [isStopped](https://developer.apple.com/documentation/foundation/nsmetadataquery/isstopped)
- [notificationBatchingInterval](https://developer.apple.com/documentation/foundation/nsmetadataquery/notificationbatchinginterval)
- [operationQueue](https://developer.apple.com/documentation/foundation/nsmetadataquery/operationqueue)
- [predicate](https://developer.apple.com/documentation/foundation/nsmetadataquery/predicate)
- [result(at:)](https://developer.apple.com/documentation/foundation/nsmetadataquery/result(at:))
- [resultCount](https://developer.apple.com/documentation/foundation/nsmetadataquery/resultcount)
- [results](https://developer.apple.com/documentation/foundation/nsmetadataquery/results)
- [searchItems](https://developer.apple.com/documentation/foundation/nsmetadataquery/searchitems)
- [searchScopes](https://developer.apple.com/documentation/foundation/nsmetadataquery/searchscopes)
- [sortDescriptors](https://developer.apple.com/documentation/foundation/nsmetadataquery/sortdescriptors)
- [start()](https://developer.apple.com/documentation/foundation/nsmetadataquery/start())
- [stop()](https://developer.apple.com/documentation/foundation/nsmetadataquery/stop())
- [value(ofAttribute:forResultAt:)](https://developer.apple.com/documentation/foundation/nsmetadataquery/value(ofattribute:forresultat:))
- [valueListAttributes](https://developer.apple.com/documentation/foundation/nsmetadataquery/valuelistattributes)
- [valueLists](https://developer.apple.com/documentation/foundation/nsmetadataquery/valuelists)
- [NSMetadataQueryAttributeValueTuple](https://developer.apple.com/documentation/foundation/nsmetadataqueryattributevaluetuple)
- [NSMetadataQueryDelegate](https://developer.apple.com/documentation/foundation/nsmetadataquerydelegate)
- [NSMetadataQueryResultGroup](https://developer.apple.com/documentation/foundation/nsmetadataqueryresultgroup)
- [NSMetadataQueryDidFinishGathering](https://developer.apple.com/documentation/foundation/nsnotification/name-swift.struct/nsmetadataquerydidfinishgathering)
- [NSMetadataQueryDidStartGathering](https://developer.apple.com/documentation/foundation/nsnotification/name-swift.struct/nsmetadataquerydidstartgathering)
- [NSMetadataQueryDidUpdate](https://developer.apple.com/documentation/foundation/nsnotification/name-swift.struct/nsmetadataquerydidupdate)
- [NSMetadataQueryGatheringProgress](https://developer.apple.com/documentation/foundation/nsnotification/name-swift.struct/nsmetadataquerygatheringprogress)
- [NSObject](https://developer.apple.com/documentation/objectivec/nsobject-swift.class)
- [NSObjectProtocol](https://developer.apple.com/documentation/objectivec/nsobjectprotocol)
- [CustomDebugStringConvertible](https://developer.apple.com/documentation/swift/customdebugstringconvertible)
- [CustomStringConvertible](https://developer.apple.com/documentation/swift/customstringconvertible)
- [CVarArg](https://developer.apple.com/documentation/swift/cvararg)
- [Equatable](https://developer.apple.com/documentation/swift/equatable)
- [Hashable](https://developer.apple.com/documentation/swift/hashable)
- [Technologies](https://developer.apple.com/documentation/technologies)

## Provenance

Official source: [NSMetadataQuery](https://developer.apple.com/documentation/foundation/nsmetadataquery). Payload DocC captured in 2026-10-02T23:16:46.165601+00:00; SHA-256 `b36d9c2b3e4fae89fb6e5c6b14394b86eee3eb30b99db5c0b1c17c93c523bef5`.

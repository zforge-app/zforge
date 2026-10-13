import AppIntents
import CoreSpotlight
import OSLog

/// Opt-in diagnostic (`--probe-inspect-index`): reads back the app's own
/// Spotlight items and logs which attributes the system stored for them.
/// Siri's search tool keeps only items matching, among others,
/// `_kMDItemAppEntitySchema=*`; this shows whether donation sets it.
/// Values are logged only for the synthetic fixture's non-path attributes.
nonisolated enum ProbeIndexInspection {
    static let attributes = [
        "_kMDItemAppEntitySchema", "_kMDItemAppEntityTypeIdentifier", "_kMDItemAppEntityIdentifier",
        "_kMDItemAppEntityInstanceIdentifier", "_kMDItemBundleID", "_kMDItemFileName",
    ]
    static let standardAttributes = ["kMDItemTitle", "kMDItemDisplayName", "kMDItemContentType", "kMDItemContentURL"]

    static func run() async {
        let logger = Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "IndexInspection")
        for queryString in ["title == \"*\"", "_kMDItemAppEntitySchema == \"*\""] {
            let context = CSSearchQueryContext()
            context.fetchAttributes = attributes + standardAttributes
            let query = CSSearchQuery(queryString: queryString, queryContext: context)
            var count = 0
            do {
                for try await result in query.results {
                    count += 1
                    let set = result.item.attributeSet
                    // Reserved kMDItem names are not valid custom keys.
                    logger.notice("Item \(count): title=\(set.title ?? "nil", privacy: .public), displayName=\(set.displayName ?? "nil", privacy: .public), contentType=\(set.contentType ?? "nil", privacy: .public), contentURL=\(set.contentURL == nil ? "absent" : "present", privacy: .public)")
                    for name in attributes {
                        guard let key = CSCustomAttributeKey(keyName: name), let value = set.value(forCustomKey: key) else {
                            logger.notice("Item \(count): \(name, privacy: .public) is absent.")
                            continue
                        }
                        let shown = name.contains("URL") ? "<present>" : String(describing: value)
                        logger.notice("Item \(count): \(name, privacy: .public)=\(shown, privacy: .public)")
                    }
                    logger.notice("Item \(count): uniqueIdentifier length=\(result.item.uniqueIdentifier.count), domain=\(result.item.domainIdentifier ?? "nil", privacy: .public)")
                }
                logger.notice("Query \(queryString, privacy: .public) returned \(count) items.")
            } catch {
                logger.error("Query \(queryString, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            }
        }
    }
}

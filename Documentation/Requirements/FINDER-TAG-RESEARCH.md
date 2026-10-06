# Finder tag discovery: external-source investigation

Research date: 2026-10-06. This is evidence, not a change to Zforge's implemented tag contract.

## Question and evidence boundary

The user reports that their empirical Finder tests return tagged files only within the current user's Home and `/Users/Shared`, and exclude hidden files. After clarification, this investigation uses external sources rather than repeating those tests. No independent Finder result measurements are claimed. Disposable fixtures prepared before that clarification were removed without collecting measurements.

## Findings from Apple sources

- **Invisible files and directories:** Apple's archived [Spotlight and Document Bundles](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/MetadataIntro/Concepts/DocumentBundles.html), updated 2013-08-08, explicitly describes excluding invisible files/directories from metadata import and uses a leading-dot directory as its example. This supports the reported exclusion, but is historical documentation, not a current-version guarantee for every hidden-file mechanism or previously indexed item.
- **Home and `/Users/Shared` as an exclusive boundary:** no official source establishing that exact Finder tag-search restriction was found. Apple's [tag guide](https://support.apple.com/en-gu/guide/mac-help/mchlp15236/mac) describes tags on files stored on the Mac or in iCloud and searching via suggestions or the sidebar, without specifying those two directories as an exclusive scope.
- **Metadata search can have broader scopes:** the [NSMetadataQueryLocalComputerScope reference](https://developer.apple.com/documentation/foundation/nsmetadataquerylocalcomputerscope) describes searching local mounted volumes, including Home. This establishes API capability, not the actual query or filters used by Finder's tag sidebar. It cannot independently disprove the user's Finder observation.
- **Index coverage and search scope are distinct:** Apple's archived [metadata query guide](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryingMetadata.html) separates search scopes from availability of indexed metadata and mentions system-directory exclusions. Its historical statements about media types must not be generalized to current releases. Apple's current [Spotlight support article](https://support.apple.com/en-us/102321) describes the index and permissions/exclusion issues. The [Finder search guide](https://support.apple.com/en-gb/guide/mac-help/mh15155/26/mac/26) documents scope and attribute criteria affecting results.

## Conclusion and product boundary

The hidden-file observation has explicit historical Apple documentation behind it. The exact Home-plus-Shared rule remains a user-observed result, without an official universal rule found in this research. Absence from a Finder result must not automatically be described as absence of all indexing; stored tags, indexed metadata, query scope and result filtering are different layers.

Historical research conclusion: do not narrow Zforge discovery or skip hidden tagged files on the strength of this investigation alone. The current production behavior remains unchanged. No application tests, performance measurements or UI validation were performed for this external-source investigation.

## Subsequent explicit product decision — 2026-10-06

The user subsequently requests adopting their observed Home/Shared and hidden-item rules and measuring completion. That instruction authorizes the product change independently of whether Apple documents a universal Finder rule. The delivered policy and measurements are tracked in [CURRENT-STATE.md](CURRENT-STATE.md#visible-home-and-shared-tag-discovery--2026-10-06); the research conclusions above remain historical evidence, not a reason to reject the requested behavior.

# Source site of knowledge SwiftUI

This directory is the local, versionable and searchable layer of official documentation used by Zforge. The initial capture covers the home of SwiftUI and all 64 unique destinations directly exposed by Overview, Featured samples and Topics in 16 July 2026.

The content is normalized for recovery by agent: each context records summary, paper, module, availability, declaration when applicable, page map, second level links and provenance. It's not an integral mirror of Apple documentation.

## How to consult this source

Start with [`INDEX.md`](INDEX.md). For a direct search:

```sh
rg -n -i 'NavigationSplitView|toolbar|focus|accessibility' Documentation/SwiftUI/contexts
```

Then read only the relevant contexts. Relative links point to pages already ingested; absolute links are pending borders and follow the mandatory expansion protocol defined in [`AGENTS.md`](AGENTS.md).

## Structure

- `INDEX.md`: theme router and human inventory.
- `GUIDANCE.md`: cross-sectional synthesis of practices and mental model relevant to Zforge.
- `contexts/`: 65 Markdown documents of initial capture and future expansions.
- `metadata/captures.json`: coverage, collection URL, hash, ETag, size, depth and failures.
- `metadata/assets.json`: visual references found, separated from the normalized text.
- `metadata/code-blocks.json`: hashes and metadata of the code blocks found.
- `tools/bootstrap.py`: reproducible clipping crawler based on DocC endpoints and the HTML page SwiftUI Pathway.
- `CONTEXT-TEMPLATE.md`: contract for new incremental contexts.

## Full update

A first level recapture requires network access to Apple Developer:

```sh
python3 Documentation/SwiftUI/tools/bootstrap.py --workers 4
```

The crawler keeps the payloads only in memory and persists hashes and metadata. It overwrites the documents generated and the index; therefore, a complete update must be reviewed and reconciled with later expansions.

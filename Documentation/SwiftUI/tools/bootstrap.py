#!/usr/bin/env python3
"""Build the first-level local SwiftUI knowledge source from Apple DocC data.

The generated Markdown is intentionally a retrieval-oriented normalization, not a
verbatim mirror. Source payloads are held in memory only; the persisted capture
manifest records their hashes and HTTP metadata.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import dataclasses
import datetime as dt
import hashlib
import html
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import OrderedDict
from html.parser import HTMLParser
from pathlib import Path
from typing import Any, Iterable


APPLE_ROOT = "https://developer.apple.com"
SWIFTUI_URL = f"{APPLE_ROOT}/documentation/SwiftUI"
SWIFTUI_DATA_URL = f"{APPLE_ROOT}/tutorials/data/documentation/swiftui.json"
USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 "
    "Zforge-SwiftUI-Knowledge/1.0"
)

ROOT = Path(__file__).resolve().parents[1]
CONTEXTS = ROOT / "contexts"
METADATA = ROOT / "metadata"


@dataclasses.dataclass
class Download:
    requested_url: str
    final_url: str
    body: bytes
    content_type: str
    etag: str | None
    last_modified: str | None

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.body).hexdigest()


@dataclasses.dataclass
class Seed:
    identifier: str
    title: str
    source_url: str
    categories: list[str]
    local_name: str = ""


def fetch(url: str, *, attempts: int = 3) -> Download:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json,text/html;q=0.9,*/*;q=0.8",
            "User-Agent": USER_AGENT,
        },
    )
    last_error: Exception | None = None
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return Download(
                    requested_url=url,
                    final_url=response.geturl(),
                    body=response.read(),
                    content_type=response.headers.get_content_type(),
                    etag=response.headers.get("ETag"),
                    last_modified=response.headers.get("Last-Modified"),
                )
        except (urllib.error.URLError, TimeoutError) as error:
            last_error = error
            if attempt + 1 < attempts:
                time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"failed to fetch {url}: {last_error}")


def docc_data_url(source_url: str) -> str | None:
    parsed = urllib.parse.urlparse(source_url)
    path = urllib.parse.unquote(parsed.path).strip("/")
    if path.startswith("documentation/"):
        return f"{APPLE_ROOT}/tutorials/data/{path.lower()}.json"
    if path.startswith("tutorials/"):
        parts = path.split("/")
        if len(parts) >= 2:
            collection_path = "/".join(parts[:2])
            return f"{APPLE_ROOT}/tutorials/data/{collection_path.lower()}.json"
    return None


def normalize_url(url: str) -> str:
    absolute = urllib.parse.urljoin(APPLE_ROOT, url)
    parsed = urllib.parse.urlsplit(absolute)
    path = re.sub(r"/+", "/", parsed.path)
    return urllib.parse.urlunsplit((parsed.scheme, parsed.netloc, path, parsed.query, parsed.fragment))


def url_without_fragment(url: str) -> str:
    parsed = urllib.parse.urlsplit(normalize_url(url))
    return urllib.parse.urlunsplit((parsed.scheme, parsed.netloc, parsed.path.rstrip("/") or "/", parsed.query, ""))


def iter_nodes(value: Any) -> Iterable[dict[str, Any]]:
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from iter_nodes(child)
    elif isinstance(value, list):
        for child in value:
            yield from iter_nodes(child)


def inline_plain(value: Any, references: dict[str, Any] | None = None) -> str:
    references = references or {}
    chunks: list[str] = []

    def visit(item: Any) -> None:
        if isinstance(item, list):
            for child in item:
                visit(child)
            return
        if not isinstance(item, dict):
            return
        item_type = item.get("type")
        if item_type in {"text", "codeVoice", "emphasis", "strong", "newTerm"}:
            if isinstance(item.get("text"), str):
                chunks.append(item["text"])
            if item.get("inlineContent"):
                visit(item["inlineContent"])
            return
        if item_type == "reference":
            identifier = item.get("identifier", "")
            ref = references.get(identifier, {})
            title = ref.get("title") or title_from_identifier(identifier)
            chunks.append(title)
            return
        if isinstance(item.get("text"), str):
            chunks.append(item["text"])
        for key in ("inlineContent", "content"):
            if item.get(key):
                visit(item[key])

    visit(value)
    return clean_text("".join(chunks))


def clean_text(value: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(value)).strip()


def truncate_words(value: str, limit: int) -> str:
    words = value.split()
    if len(words) <= limit:
        return value
    return " ".join(words[:limit]).rstrip(" ,;:") + "…"


def title_from_identifier(identifier: str) -> str:
    if not identifier:
        return "Untitled reference"
    parsed = urllib.parse.urlsplit(identifier)
    source = parsed.path if parsed.scheme in {"http", "https"} else identifier
    tail = source.rstrip("/").split("/")[-1].split("#")[0]
    return urllib.parse.unquote(tail).replace("-", " ").replace("_", " ").strip() or identifier


def reference_url(identifier: str, references: dict[str, Any]) -> str | None:
    if identifier.startswith(("https://", "http://")):
        return normalize_url(identifier)
    ref = references.get(identifier, {})
    if isinstance(ref.get("url"), str):
        return normalize_url(ref["url"])
    marker = "/documentation/"
    if marker in identifier:
        suffix = identifier.split(marker, 1)[1]
        return normalize_url(f"/documentation/{suffix}")
    tutorial_marker = "/tutorials/"
    if tutorial_marker in identifier:
        suffix = identifier.split(tutorial_marker, 1)[1]
        return normalize_url(f"/tutorials/{suffix}")
    return None


def reference_title(identifier: str, references: dict[str, Any]) -> str:
    ref = references.get(identifier, {})
    return clean_text(ref.get("title") or title_from_identifier(identifier))


def reference_abstract(identifier: str, references: dict[str, Any]) -> str:
    ref = references.get(identifier, {})
    value = inline_plain(ref.get("abstract", []), references)
    value = re.sub(r"\[([^\]]+)\]\(doc://[^)]+\)", r"\1", value)
    value = re.sub(r"doc://\S+", "", value)
    return truncate_words(clean_text(value), 24)


def add_seed(
    seeds: OrderedDict[str, Seed],
    identifier: str,
    category: str,
    references: dict[str, Any],
) -> None:
    source_url = reference_url(identifier, references)
    if not source_url:
        return
    key = url_without_fragment(source_url)
    if key in seeds:
        if category not in seeds[key].categories:
            seeds[key].categories.append(category)
        return
    seeds[key] = Seed(
        identifier=identifier,
        title=reference_title(identifier, references),
        source_url=source_url,
        categories=[category],
    )


def build_seeds(home: dict[str, Any]) -> list[Seed]:
    references = home.get("references", {})
    seeds: OrderedDict[str, Seed] = OrderedDict()

    for section in home.get("primaryContentSections", []):
        for node in iter_nodes(section.get("content", [])):
            if node.get("type") == "reference" and node.get("identifier"):
                add_seed(seeds, node["identifier"], "Overview", references)
            if node.get("type") == "links":
                for identifier in node.get("items", []):
                    if isinstance(identifier, str):
                        add_seed(seeds, identifier, "Featured samples", references)

    for topic in home.get("topicSections", []):
        category = topic.get("title", "Topics")
        for identifier in topic.get("identifiers", []):
            add_seed(seeds, identifier, category, references)

    return list(seeds.values())


def local_name_for(source_url: str, used: set[str]) -> str:
    parsed = urllib.parse.urlsplit(source_url)
    path = urllib.parse.unquote(parsed.path).strip("/")
    if path.lower() == "documentation/swiftui":
        base = "swiftui"
    elif path.lower() == "swiftui/get-started":
        base = "swiftui-pathway"
    else:
        parts = path.split("/")
        if parts and parts[0].lower() in {"documentation", "tutorials"}:
            parts = parts[1:]
        base = "-".join(parts)
        base = re.sub(r"[^a-zA-Z0-9]+", "-", base).strip("-").lower()
    candidate = f"{base or 'context'}.md"
    index = 2
    while candidate in used:
        candidate = f"{base}-{index}.md"
        index += 1
    used.add(candidate)
    return candidate


class MainHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.in_main = False
        self.skip_depth = 0
        self.block_tag: str | None = None
        self.block_text: list[str] = []
        self.headings: list[str] = []
        self.paragraphs: list[str] = []
        self.links: list[tuple[str, str]] = []
        self.link_href: str | None = None
        self.link_text: list[str] = []
        self.title = ""
        self.meta_description = ""
        self._in_title = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = dict(attrs)
        if tag == "title":
            self._in_title = True
        if tag == "meta" and attributes.get("name", "").lower() == "description":
            self.meta_description = clean_text(attributes.get("content") or "")
        if tag == "main" and not self.in_main:
            self.in_main = True
            return
        if not self.in_main:
            return
        if tag in {"script", "style", "noscript", "svg"}:
            self.skip_depth += 1
            return
        if self.skip_depth:
            return
        if tag in {"h1", "h2", "h3", "h4", "p"} and self.block_tag is None:
            self.block_tag = tag
            self.block_text = []
        if tag == "a":
            self.link_href = attributes.get("href")
            self.link_text = []

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self._in_title = False
        if not self.in_main:
            return
        if tag == "main":
            self.in_main = False
            return
        if self.skip_depth:
            if tag in {"script", "style", "noscript", "svg"}:
                self.skip_depth -= 1
        else:
            if tag == "a" and self.link_href:
                label = clean_text("".join(self.link_text))
                if label:
                    self.links.append((label, normalize_url(self.link_href)))
                self.link_href = None
                self.link_text = []
            if tag == self.block_tag:
                value = clean_text("".join(self.block_text))
                if value:
                    if tag.startswith("h"):
                        self.headings.append(value)
                    elif tag == "p":
                        self.paragraphs.append(value)
                self.block_tag = None
                self.block_text = []

    def handle_data(self, data: str) -> None:
        if self._in_title and not self.in_main:
            self.title += data
        if not self.in_main or self.skip_depth:
            return
        if self.block_tag:
            self.block_text.append(data)
        if self.link_href:
            self.link_text.append(data)


def parse_html_page(download: Download) -> dict[str, Any]:
    parser = MainHTMLParser()
    parser.feed(download.body.decode("utf-8", errors="replace"))
    seen_links: set[str] = set()
    links: list[dict[str, str]] = []
    for label, url in parser.links:
        if not url.startswith(APPLE_ROOT) or url in seen_links:
            continue
        seen_links.add(url)
        links.append({"title": label, "url": url})
    return {
        "title": parser.headings[0] if parser.headings else clean_text(parser.title).split(" - Apple Developer", 1)[0],
        "abstract": parser.meta_description,
        "headings": list(dict.fromkeys(parser.headings)),
        "paragraphs": parser.paragraphs,
        "groups": [("Resources on this page", links)],
        "role": "Pathway",
        "module": "SwiftUI",
        "platforms": [],
        "declarations": [],
        "references": {},
        "assets": [],
        "code_blocks": [],
        "identifier": download.final_url,
    }


def collect_identifiers(value: Any) -> list[str]:
    found: list[str] = []
    for node in iter_nodes(value):
        if node.get("type") == "reference" and isinstance(node.get("identifier"), str):
            found.append(node["identifier"])
        if node.get("type") == "links":
            found.extend(item for item in node.get("items", []) if isinstance(item, str))
    return list(dict.fromkeys(found))


def docc_group(title: str, identifiers: Iterable[str], references: dict[str, Any]) -> tuple[str, list[dict[str, str]]]:
    entries: list[dict[str, str]] = []
    seen: set[str] = set()
    for identifier in identifiers:
        if identifier in seen:
            continue
        seen.add(identifier)
        url = reference_url(identifier, references)
        if not url:
            continue
        entries.append(
            {
                "identifier": identifier,
                "title": reference_title(identifier, references),
                "url": url,
                "abstract": reference_abstract(identifier, references),
            }
        )
    return title, entries


def parse_docc_page(payload: dict[str, Any]) -> dict[str, Any]:
    references = payload.get("references", {})
    metadata = payload.get("metadata", {})
    primary = payload.get("primaryContentSections", [])

    paragraphs: list[str] = []
    headings: list[str] = []
    declarations: list[str] = []
    for node in iter_nodes(primary):
        if node.get("type") == "heading" and node.get("text"):
            headings.append(clean_text(node["text"]))
        if node.get("type") == "paragraph":
            value = inline_plain(node.get("inlineContent") or node.get("content") or [], references)
            if value:
                paragraphs.append(value)
    for section in primary:
        if section.get("kind") != "declarations":
            continue
        for declaration in section.get("declarations", []):
            text = clean_text("".join(token.get("text", "") for token in declaration.get("tokens", [])))
            if text:
                declarations.append(text)

    groups: list[tuple[str, list[dict[str, str]]]] = []
    grouped_ids: set[str] = set()
    for key in ("topicSections", "seeAlsoSections", "relationshipSections", "relationshipsSections"):
        for section in payload.get(key, []) or []:
            identifiers = [item for item in section.get("identifiers", []) if isinstance(item, str)]
            if identifiers:
                grouped_ids.update(identifiers)
                groups.append(docc_group(section.get("title") or key, identifiers, references))

    primary_ids = collect_identifiers(primary)
    if primary_ids:
        grouped_ids.update(primary_ids)
        groups.insert(0, docc_group("Overview and featured references", primary_ids, references))

    remaining = [
        identifier
        for identifier in collect_identifiers(payload.get("sections", []))
        if identifier not in grouped_ids
    ]
    if remaining:
        groups.append(docc_group("Article and tutorial references", remaining, references))

    assets: list[dict[str, Any]] = []
    for identifier, ref in references.items():
        if ref.get("type") == "image" or ref.get("kind") == "image" or ref.get("variants"):
            assets.append(
                {
                    "identifier": identifier,
                    "alt": ref.get("alt"),
                    "variants": ref.get("variants", []),
                }
            )

    code_blocks: list[dict[str, Any]] = []
    for node in iter_nodes({"primary": primary, "sections": payload.get("sections", [])}):
        if node.get("type") not in {"codeListing", "code"}:
            continue
        code = node.get("code")
        if isinstance(code, list):
            code = "\n".join(str(line) for line in code)
        if not isinstance(code, str):
            continue
        code_blocks.append(
            {
                "sha256": hashlib.sha256(code.encode()).hexdigest(),
                "line_count": len(code.splitlines()),
                "syntax": node.get("syntax"),
            }
        )

    platforms = []
    for platform in metadata.get("platforms", []) or []:
        value = platform.get("name", "Unknown")
        if platform.get("introducedAt"):
            value += f" {platform['introducedAt']}+"
        if platform.get("beta"):
            value += " (beta)"
        if platform.get("deprecated"):
            value += " (deprecated)"
        if platform.get("unavailable"):
            value += " (unavailable)"
        platforms.append(value)

    modules = [module.get("name") for module in metadata.get("modules", []) if module.get("name")]
    return {
        "title": metadata.get("title") or title_from_identifier(payload.get("identifier", {}).get("url", "")),
        "abstract": inline_plain(payload.get("abstract", []), references),
        "headings": list(dict.fromkeys(headings)),
        "paragraphs": list(dict.fromkeys(paragraphs)),
        "groups": groups,
        "role": metadata.get("roleHeading") or metadata.get("role") or payload.get("kind", "Documentation"),
        "module": ", ".join(modules),
        "platforms": platforms,
        "declarations": list(dict.fromkeys(declarations)),
        "references": references,
        "assets": assets,
        "code_blocks": code_blocks,
        "identifier": payload.get("identifier", {}).get("url", ""),
    }


def yaml_value(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False)


def markdown_escape(value: str) -> str:
    return value.replace("[", "\\[").replace("]", "\\]")


def zforge_relevance(seed: Seed, parsed: dict[str, Any]) -> str:
    lower = f"{seed.source_url} {parsed.get('module', '')} {parsed.get('title', '')}".lower()
    if "uikit" in lower or "watchkit" in lower or "visionos" in lower or "immersive" in lower:
        return "Contextual. Preserve the cross-platform concept, but prefer the native macOS/AppKit behavior for Zforge."
    if "appkit" in lower or "macos" in " ".join(parsed.get("platforms", [])).lower():
        return "Direct. Use this context for SwiftUI decisions that must remain native to macOS."
    return "Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge."


def render_link(
    entry: dict[str, str],
    local_by_identifier: dict[str, str],
    local_by_url: dict[str, str],
) -> str:
    identifier = entry.get("identifier", "")
    url = normalize_url(entry["url"])
    local = local_by_identifier.get(identifier) or local_by_url.get(url_without_fragment(url))
    target = local or url
    title = markdown_escape(entry.get("title") or title_from_identifier(url))
    suffix = "contexto local" if local else "Apple Developer; expandir sob demanda"
    abstract = entry.get("abstract", "")
    if abstract:
        return f"- [{title}]({target}) — {abstract} _({suffix})_"
    return f"- [{title}]({target}) — _{suffix}_"


def render_context(
    seed: Seed,
    parsed: dict[str, Any],
    download: Download,
    capture_time: str,
    depth: int,
    local_by_identifier: dict[str, str],
    local_by_url: dict[str, str],
) -> str:
    title = clean_text(parsed.get("title") or seed.title)
    narrative_parts: list[str] = []
    budget = 150
    abstract = clean_text(parsed.get("abstract", ""))
    for paragraph in parsed.get("paragraphs", []):
        paragraph = clean_text(paragraph)
        if not paragraph or paragraph == abstract:
            continue
        remaining = budget - len(" ".join(narrative_parts).split())
        if remaining <= 0:
            break
        narrative_parts.append(truncate_words(paragraph, remaining))

    lines = [
        "---",
        f"title: {yaml_value(title)}",
        f"source_url: {yaml_value(seed.source_url)}",
        f"source_identifier: {yaml_value(parsed.get('identifier') or seed.identifier)}",
        f"captured_at: {yaml_value(capture_time)}",
        f"source_sha256: {yaml_value(download.sha256)}",
        f"source_etag: {yaml_value(download.etag)}",
        f"source_last_modified: {yaml_value(download.last_modified)}",
        f"source_format: {yaml_value(download.content_type)}",
        f"depth: {depth}",
        f"categories: {yaml_value(seed.categories)}",
        "language: \"en\"",
        "authority: \"Apple Developer\"",
        "confidence: \"primary-source\"",
        "---",
        "",
        f"# {title}",
        "",
        "Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.",
        "",
        "## Consulta rápida",
        "",
        f"- Papel: {parsed.get('role') or 'Documentation'}",
        f"- Módulo: {parsed.get('module') or 'Não informado'}",
        f"- Relevância para Zforge: {zforge_relevance(seed, parsed)}",
    ]
    if parsed.get("platforms"):
        lines.append(f"- Disponibilidade: {', '.join(parsed['platforms'])}")
    for declaration in parsed.get("declarations", []):
        lines.append(f"- Declaração: `{declaration.replace('`', '')}`")

    lines.extend(["", "## Síntese", ""])
    if abstract:
        lines.append(f"**Resumo oficial:** {abstract}")
        lines.append("")
    if narrative_parts:
        lines.append(" ".join(narrative_parts))
    elif not abstract:
        lines.append("A página funciona principalmente como índice de APIs, exemplos e referências relacionadas.")

    headings = parsed.get("headings", [])
    if headings:
        lines.extend(["", "## Mapa do conteúdo", ""])
        lines.extend(f"- {heading}" for heading in headings)

    lines.extend(["", "## Links do segundo nível", ""])
    seen_targets: set[tuple[str, str]] = set()
    rendered_any = False
    for group_title, entries in parsed.get("groups", []):
        unique_entries = []
        for entry in entries:
            key = (entry.get("identifier", ""), url_without_fragment(entry["url"]))
            if key in seen_targets or url_without_fragment(entry["url"]) == url_without_fragment(seed.source_url):
                continue
            seen_targets.add(key)
            unique_entries.append(entry)
        if not unique_entries:
            continue
        rendered_any = True
        lines.extend([f"### {group_title}", ""])
        lines.extend(render_link(entry, local_by_identifier, local_by_url) for entry in unique_entries)
        lines.append("")
    if not rendered_any:
        lines.append("Nenhum link secundário foi exposto no conteúdo normalizado desta página.")
        lines.append("")

    lines.extend(
        [
            "## Proveniência",
            "",
            f"- Fonte: [Apple Developer]({seed.source_url})",
            f"- Captura: `{capture_time}`",
            f"- SHA-256 do payload: `{download.sha256}`",
            "- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.",
            "",
        ]
    )
    return "\n".join(lines)


def fetch_seed(seed: Seed) -> tuple[Seed, Download, dict[str, Any], dict[str, Any] | None]:
    data_url = docc_data_url(seed.source_url)
    if data_url:
        download = fetch(data_url)
        payload = json.loads(download.body)
        return seed, download, parse_docc_page(payload), payload
    download = fetch(seed.source_url)
    return seed, download, parse_html_page(download), None


def render_index(home_seed: Seed, seeds: list[Seed], capture_time: str) -> str:
    categories: OrderedDict[str, list[Seed]] = OrderedDict()
    for seed in seeds:
        for category in seed.categories:
            categories.setdefault(category, []).append(seed)
    lines = [
        "---",
        'title: "SwiftUI local knowledge index"',
        f"captured_at: {yaml_value(capture_time)}",
        f"source_url: {yaml_value(SWIFTUI_URL)}",
        "---",
        "",
        "# Índice local de SwiftUI",
        "",
        f"Entrada principal: [{home_seed.title}](contexts/{home_seed.local_name}).",
        "",
        "Síntese transversal: [Princípios SwiftUI para o Zforge](GUIDANCE.md).",
        "",
        f"Cobertura inicial: home + {len(seeds)} destinos únicos de primeiro nível ({len(seeds) + 1} contextos).",
        "",
        "Para consultar, leia primeiro este índice e use `rg -n -i '<termos|símbolos>' Documentation/SwiftUI/contexts`. Links absolutos apontam para páginas ainda não ingeridas.",
        "",
    ]
    for category, items in categories.items():
        lines.extend([f"## {category}", ""])
        for seed in items:
            lines.append(f"- [{seed.title}](contexts/{seed.local_name})")
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workers", type=int, default=4)
    args = parser.parse_args()

    capture_time = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()
    CONTEXTS.mkdir(parents=True, exist_ok=True)
    METADATA.mkdir(parents=True, exist_ok=True)

    home_download = fetch(SWIFTUI_DATA_URL)
    home_payload = json.loads(home_download.body)
    seeds = build_seeds(home_payload)

    used_names: set[str] = set()
    home_seed = Seed(
        identifier=home_payload.get("identifier", {}).get("url", ""),
        title="SwiftUI",
        source_url=SWIFTUI_URL,
        categories=["Home"],
        local_name=local_name_for(SWIFTUI_URL, used_names),
    )
    for seed in seeds:
        seed.local_name = local_name_for(seed.source_url, used_names)

    local_by_identifier = {home_seed.identifier: home_seed.local_name}
    local_by_url = {url_without_fragment(home_seed.source_url): home_seed.local_name}
    for seed in seeds:
        local_by_identifier[seed.identifier] = seed.local_name
        local_by_url[url_without_fragment(seed.source_url)] = seed.local_name

    results: list[tuple[Seed, Download, dict[str, Any], dict[str, Any] | None]] = []
    failures: list[dict[str, str]] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.workers)) as executor:
        future_map = {executor.submit(fetch_seed, seed): seed for seed in seeds}
        for future in concurrent.futures.as_completed(future_map):
            seed = future_map[future]
            try:
                results.append(future.result())
                print(f"captured {seed.source_url}", file=sys.stderr)
            except Exception as error:  # keep a complete audit trail
                failures.append({"url": seed.source_url, "error": str(error)})
                print(f"FAILED {seed.source_url}: {error}", file=sys.stderr)

    parsed_home = parse_docc_page(home_payload)
    (CONTEXTS / home_seed.local_name).write_text(
        render_context(
            home_seed,
            parsed_home,
            home_download,
            capture_time,
            0,
            local_by_identifier,
            local_by_url,
        ),
        encoding="utf-8",
    )

    captures: list[dict[str, Any]] = []
    asset_records: list[dict[str, Any]] = []
    code_records: list[dict[str, Any]] = []
    captures.append(
        {
            "source_url": home_seed.source_url,
            "fetch_url": home_download.requested_url,
            "final_url": home_download.final_url,
            "local_path": f"contexts/{home_seed.local_name}",
            "sha256": home_download.sha256,
            "etag": home_download.etag,
            "last_modified": home_download.last_modified,
            "bytes": len(home_download.body),
            "categories": home_seed.categories,
            "depth": 0,
        }
    )

    for seed, download, parsed, _payload in sorted(results, key=lambda item: seeds.index(item[0])):
        (CONTEXTS / seed.local_name).write_text(
            render_context(seed, parsed, download, capture_time, 1, local_by_identifier, local_by_url),
            encoding="utf-8",
        )
        captures.append(
            {
                "source_url": seed.source_url,
                "fetch_url": download.requested_url,
                "final_url": download.final_url,
                "local_path": f"contexts/{seed.local_name}",
                "sha256": download.sha256,
                "etag": download.etag,
                "last_modified": download.last_modified,
                "bytes": len(download.body),
                "categories": seed.categories,
                "depth": 1,
            }
        )
        for asset in parsed.get("assets", []):
            asset_records.append({"source_url": seed.source_url, **asset})
        for index, block in enumerate(parsed.get("code_blocks", []), start=1):
            code_records.append({"source_url": seed.source_url, "ordinal": index, **block})

    (ROOT / "INDEX.md").write_text(render_index(home_seed, seeds, capture_time), encoding="utf-8")
    manifest = {
        "schema_version": 1,
        "captured_at": capture_time,
        "seed_url": SWIFTUI_URL,
        "scope": "home plus unique first-level links exposed by Overview, Featured samples, and Topics",
        "expected_contexts": len(seeds) + 1,
        "captured_contexts": len(captures),
        "failures": failures,
        "captures": captures,
    }
    (METADATA / "captures.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (METADATA / "assets.json").write_text(
        json.dumps(asset_records, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (METADATA / "code-blocks.json").write_text(
        json.dumps(code_records, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    print(
        json.dumps(
            {
                "expected": len(seeds) + 1,
                "captured": len(captures),
                "failures": failures,
            },
            ensure_ascii=False,
        )
    )
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())

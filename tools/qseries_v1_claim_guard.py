#!/usr/bin/env python3
"""Guard Q-Series v1.0 release wording against claim inflation.

This is a developer helper for release prep. It checks that public/status files
point to the generated Q-Series v1.0 release-status summary, and that obvious
positive completion/support wording is absent from those files.
"""

from __future__ import annotations

import argparse
import csv
import pathlib
import re
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
STATUS_LINK = "docs/dev-log/release-audits/q-series-v1-release-status.md"
STATUS_PATH = ROOT / STATUS_LINK
PUBLIC_STATUS_PATHS = (
    pathlib.Path("README.md"),
    pathlib.Path("ROADMAP.md"),
    pathlib.Path("NEWS.md"),
    pathlib.Path("docs/dev-log/known-limitations.md"),
)
REQUIRED_STATUS_PHRASES = (
    "release-planning boundary, not a support promotion",
    "row-accounting summaries, not package-release completion claims",
    "Practical v1.0 row surface | 102/104 | 98.1%",
    "Gaussian v1.0 core | 67/67 | 100.0%",
    "Basic-distribution recovery | 35/37 | 94.6%",
    "Exact `inference_ready` anchors | 8/104 | 7.7%",
    "`supported` authority | 0/104 | 0.0%",
    "Post-v1.0 validation/design | 2/104 | 1.9%",
    "does not authorize coverage, q4 coverage",
    "Do not describe the Q-Series as complete, broadly supported, fully",
    "Do not claim q4/q8 coverage",
    "REML, AI-REML, or public support",
)
PUBLIC_BOUNDARY_TERMS = (
    "not ",
    "no ",
    "does not",
    "do not",
    "defer",
    "post-v1.0",
    "release-planning",
    "not a broader support claim",
    "does not authorize",
    "remain planned",
    "planned or blocked",
    "withheld",
)
FORBIDDEN_PUBLIC_PATTERNS = (
    re.compile(r"\bQ-Series\b.*\bcomplete\b", re.IGNORECASE),
    re.compile(r"\bQ-Series\b.*\bbroadly supported\b", re.IGNORECASE),
    re.compile(r"\bQ-Series\b.*\bfully inference[-_ ]ready\b", re.IGNORECASE),
    re.compile(r"\bQ-Series\b.*\bcoverage[- ]ready\b", re.IGNORECASE),
    re.compile(r"\bQ-Series\b.*\bpublic support\b", re.IGNORECASE),
    re.compile(r"\bQ-Series\b.*\bREML\b", re.IGNORECASE),
    re.compile(r"\bQ-Series\b.*\bAI-REML\b", re.IGNORECASE),
)

SUPPORT_CELLS_LINK = "docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv"
# Rose safeguard #2 (capability-catalog freshness): any high-q structured
# dimension pattern admitted to the support-cell ledger must also surface in the
# public capability catalogs, or the catalog has drifted behind the ledger. The
# q12 two-slope all-four surface (the renamed qseries_<provider>_q12_all_four_two_slope
# cells) is guarded first; extend the tuple as higher-q cells admit.
CATALOG_REQUIRED_DIMENSION_PATTERNS = ("q12",)
CATALOG_CAPABILITY_FILES = (
    pathlib.Path("README.md"),
    pathlib.Path("ROADMAP.md"),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check Q-Series v1.0 public/status wording boundaries."
    )
    parser.add_argument(
        "--root",
        type=pathlib.Path,
        default=ROOT,
        help="Repository root. Defaults to the parent of this script.",
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="Print a one-line success summary.",
    )
    return parser.parse_args()


def rel_path(path: pathlib.Path, root: pathlib.Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def has_boundary(line: str) -> bool:
    lowered = line.lower()
    return any(term in lowered for term in PUBLIC_BOUNDARY_TERMS)


def check_claims(root: pathlib.Path = ROOT) -> list[str]:
    root = root.resolve()
    errors: list[str] = []
    status_path = root / STATUS_LINK
    if not status_path.exists():
        errors.append(f"{STATUS_LINK}: missing generated release-status file")
        status_text = ""
    else:
        status_text = status_path.read_text(encoding="utf-8")

    normalized_status = re.sub(r"\s+", " ", status_text)
    for phrase in REQUIRED_STATUS_PHRASES:
        if phrase not in normalized_status:
            errors.append(f"{STATUS_LINK}: must mention {phrase!r}")

    for relative_path in PUBLIC_STATUS_PATHS:
        path = root / relative_path
        if not path.exists():
            errors.append(f"{relative_path.as_posix()}: missing public/status file")
            continue
        text = path.read_text(encoding="utf-8")
        if STATUS_LINK not in text:
            errors.append(f"{relative_path.as_posix()}: must link to {STATUS_LINK}")
        if "Q-Series" in text and not any(
            term in text.lower()
            for term in ("release-planning", "does not authorize", "not a broader support claim")
        ):
            errors.append(
                f"{relative_path.as_posix()}: Q-Series wording needs a release boundary"
            )
        for line_number, line in enumerate(text.splitlines(), start=1):
            if "Q-Series" not in line:
                continue
            for pattern in FORBIDDEN_PUBLIC_PATTERNS:
                if pattern.search(line) and not has_boundary(line):
                    errors.append(
                        f"{relative_path.as_posix()}:{line_number}: "
                        "possible inflated Q-Series v1 claim: "
                        f"{line.strip()}"
                    )
    errors.extend(check_capability_catalog(root))
    return errors


def dimension_mention_pattern(dimension_pattern: str) -> "re.Pattern[str]":
    """Regex matching a public-prose mention of a q-series dimension pattern.

    ``"q12"`` matches the capability-row phrasing ``"q=12"`` as well as a bare
    ``"q12"``; the trailing boundary keeps ``q12`` from matching inside ``q120``.
    """
    digits = dimension_pattern[1:] if dimension_pattern.startswith("q") else dimension_pattern
    return re.compile(rf"q\s*=?\s*{re.escape(digits)}\b")


def check_capability_catalog(root: pathlib.Path = ROOT) -> list[str]:
    """Fail if a ledger dimension pattern is missing from the public catalogs.

    Rose safeguard #2: the current status gates confirm the support-cell ledger,
    the release ledger, and the high-q audit stay mutually consistent, but none
    of them check that an admitted cell is actually described in README/ROADMAP.
    This closes that gap for the configured high-q patterns (q12 today), so a
    future cell that lands in the ledger without a capability row fails loudly.
    """
    root = root.resolve()
    errors: list[str] = []
    support_path = root / SUPPORT_CELLS_LINK
    if not support_path.exists():
        errors.append(
            f"{SUPPORT_CELLS_LINK}: missing support-cell ledger for capability-catalog check"
        )
        return errors
    with support_path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter="\t", quoting=csv.QUOTE_NONE))

    catalog_texts: dict[str, str] = {}
    for relative_path in CATALOG_CAPABILITY_FILES:
        path = root / relative_path
        if not path.exists():
            errors.append(
                f"{relative_path.as_posix()}: missing capability catalog for freshness check"
            )
            continue
        catalog_texts[relative_path.as_posix()] = path.read_text(encoding="utf-8")

    for dimension_pattern in CATALOG_REQUIRED_DIMENSION_PATTERNS:
        ledger_cells = [
            row.get("cell_id", "")
            for row in rows
            if row.get("dimension_pattern") == dimension_pattern
        ]
        if not ledger_cells:
            continue
        mention = dimension_mention_pattern(dimension_pattern)
        example = ledger_cells[0]
        for relative_path, text in catalog_texts.items():
            if not mention.search(text):
                errors.append(
                    f"{relative_path}: {len(ledger_cells)} support-cell rows have "
                    f"dimension_pattern={dimension_pattern} (e.g. {example!r}) but no "
                    f"{dimension_pattern} capability mention was found; the public "
                    "capability catalog has drifted behind the ledger"
                )
    return errors


def main() -> int:
    args = parse_args()
    errors = check_claims(args.root)
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    if args.summary:
        public_files = ", ".join(path.as_posix() for path in PUBLIC_STATUS_PATHS)
        catalog_patterns = ", ".join(CATALOG_REQUIRED_DIMENSION_PATTERNS)
        print(
            f"qseries_v1_claim_guard_ok: {STATUS_LINK}; public_files={public_files}; "
            f"capability_catalog_patterns={catalog_patterns}",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

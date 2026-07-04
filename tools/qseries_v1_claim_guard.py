#!/usr/bin/env python3
"""Guard Q-Series v1.0 release wording against claim inflation.

This is a developer helper for release prep. It checks that public/status files
point to the generated Q-Series v1.0 release-status summary, and that obvious
positive completion/support wording is absent from those files.
"""

from __future__ import annotations

import argparse
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
    "Practical v1.0 row surface | 77/104 | 74.0%",
    "Gaussian v1.0 core | 56/67 | 83.6%",
    "Basic-distribution recovery | 21/37 | 56.8%",
    "Exact `inference_ready` anchors | 8/104 | 7.7%",
    "`supported` authority | 0/104 | 0.0%",
    "Post-v1.0 validation/design | 27/104 | 26.0%",
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
        print(
            f"qseries_v1_claim_guard_ok: {STATUS_LINK}; public_files={public_files}",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

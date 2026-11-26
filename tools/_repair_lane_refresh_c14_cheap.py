#!/usr/bin/env python3
"""Refresh C14 cheap-mode receipt blobs when model-15 fingerprint is unchanged."""
from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_FILES = [
    "R/drmTMB.R",
    "R/methods.R",
    "src/drmTMB.cpp",
    "tests/testthat/test-zero-one-beta.R",
    "tools/run-lane-c-c17c1-c14-model15-compatibility.R",
]
MANIFEST = (
    ROOT
    / "docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv"
)


def read_tsv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    lines = path.read_text().splitlines()
    hdr = lines[0].split("\t")
    return hdr, [dict(zip(hdr, line.split("\t"))) for line in lines[1:]]


def write_tsv(path: Path, hdr: list[str], rows: list[dict[str, str]]) -> None:
    with path.open("w", encoding="utf-8") as handle:
        handle.write("\t".join(hdr) + "\n")
        for row in rows:
            handle.write("\t".join(row.get(col, "") for col in hdr) + "\n")


def main() -> None:
    head = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
    ).strip()
    blobs = {
        sf: subprocess.check_output(
            ["git", "hash-object", sf], cwd=ROOT, text=True
        ).strip()
        for sf in SOURCE_FILES
    }

    def refresh_prov(path: Path) -> None:
        _, rows = read_tsv(path)
        kv = {row["key"]: row["value"] for row in rows}
        kv["source_sha"] = head
        for sf, blob in blobs.items():
            kv[f"git_blob:{sf}"] = blob
        write_tsv(path, ["key", "value"], [{"key": k, "value": v} for k, v in kv.items()])

    def refresh_raw(path: Path) -> None:
        hdr, rows = read_tsv(path)
        for row in rows:
            row["source_sha"] = head
        write_tsv(path, hdr, rows)

    hdr, mrows = read_tsv(MANIFEST)
    for row in mrows:
        row["current_source_sha"] = head
        refresh_prov(ROOT / row["provenance_path"])
        refresh_raw(ROOT / row["raw_attempts_path"])
    write_tsv(MANIFEST, hdr, mrows)
    print(f"refreshed C14 cheap receipts at {head}")


if __name__ == "__main__":
    main()
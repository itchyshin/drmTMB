#!/usr/bin/env python3
"""Join source-bound implementation receipts to exact frozen capability rows."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROWS = ROOT / "docs/dev-log/general-sd-regression/required-rows.tsv"
EVIDENCE = ROOT / "docs/dev-log/general-sd-regression/direct-sd-evidence.tsv"
SUMMARY = ROOT / "docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md"
FIELDS = (
    "row_key", "evidence_id", "evidence_grade", "receipt_path", "receipt_sha256",
    "source_manifest_path", "source_manifest_sha256", "test_path", "test_sha256",
    "test_command", "result_summary", "review_status",
)
GRADES = {"focused_test", "recovery", "workflow"}
REVIEW_STATUSES = {"unreviewed", "reviewed_narrow_claim"}


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream, delimiter="\t"))


def has_expected_header(path: Path) -> bool:
    with path.open(encoding="utf-8", newline="") as stream:
        return next(csv.reader(stream, delimiter="\t"), []) == list(FIELDS)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def manifest_binds_test(manifest: Path, test_path: str, test_digest: str) -> bool:
    text = manifest.read_text(encoding="utf-8")

    def path_matches(candidate: str) -> bool:
        candidate = candidate.replace("\\", "/")
        target = test_path.replace("\\", "/")
        return candidate == target or candidate.endswith("/" + target)

    if manifest.suffix.lower() == ".json" or text.lstrip().startswith(("{", "[")):
        try:
            document = json.loads(text)
        except json.JSONDecodeError:
            return False

        def entries(value):
            if isinstance(value, dict):
                yield value
                for child in value.values():
                    yield from entries(child)
            elif isinstance(value, list):
                for child in value:
                    yield from entries(child)

        return any(
            entry.get("sha256", "").lower() == test_digest.lower()
            and path_matches(entry.get("file", entry.get("path", "")))
            for entry in entries(document)
        )
    if manifest.suffix.lower() == ".csv":
        with manifest.open(encoding="utf-8", newline="") as stream:
            reader = csv.DictReader(stream)
            fields = set(reader.fieldnames or [])
            if "sha256" in fields and ("file" in fields or "path" in fields):
                for entry in reader:
                    path = entry.get("file", entry.get("path", ""))
                    digest = entry.get("sha256", "")
                    if path_matches(path) and digest.lower() == test_digest.lower():
                        return True
                return False
    for line in text.splitlines():
        parts = line.strip().split(maxsplit=1)
        if len(parts) == 2 and parts[0].lower() == test_digest.lower() and path_matches(parts[1]):
            return True
    return False


def rooted_file(root: Path, value: str, label: str) -> Path:
    path = (root / value).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError(f"{label} must stay inside repository root: {value}")
    if not path.is_file():
        raise ValueError(f"{label} does not exist: {value}")
    return path


def validate(rows: list[dict[str, str]], records: list[dict[str, str]], root: Path) -> None:
    keys = [row.get("row_key", "") for row in rows]
    if not keys or len(keys) != len(set(keys)):
        raise ValueError("required rows must have unique, non-empty row_key values")
    if any(row.get("direct_sd_claim") != "none" for row in rows):
        raise ValueError("evidence reconciliation requires direct_sd_claim=none in the frozen candidate rows")
    valid_keys = set(keys)
    identities: set[tuple[str, str]] = set()
    for number, record in enumerate(records, start=2):
        missing_columns = set(FIELDS) - set(record)
        if missing_columns:
            raise ValueError(f"evidence row {number} missing columns: {sorted(missing_columns)}")
        key = record["row_key"].strip()
        if not key or key not in valid_keys:
            raise ValueError(f"unknown row_key at evidence row {number}: {key!r}")
        identity = (key, record["evidence_id"].strip())
        if not identity[1] or identity in identities:
            raise ValueError(f"duplicate evidence identity at row {number}: {identity!r}")
        identities.add(identity)
        if record["evidence_grade"] not in GRADES:
            raise ValueError(f"unknown evidence_grade at row {number}: {record['evidence_grade']!r}")
        if record["review_status"] not in REVIEW_STATUSES:
            raise ValueError(f"invalid review_status at row {number}: {record['review_status']!r}")
        for field in ("test_command", "result_summary", "receipt_path", "receipt_sha256",
                      "source_manifest_path", "source_manifest_sha256", "test_path", "test_sha256"):
            if not record[field].strip():
                raise ValueError(f"missing {field} at evidence row {number}")
        receipt = rooted_file(root, record["receipt_path"], "receipt")
        if sha256(receipt) != record["receipt_sha256"].lower():
            raise ValueError(f"receipt SHA-256 mismatch at evidence row {number}")
        manifest = rooted_file(root, record["source_manifest_path"], "source manifest")
        if sha256(manifest) != record["source_manifest_sha256"].lower():
            raise ValueError(f"source manifest SHA-256 mismatch at evidence row {number}")
        test_source = rooted_file(root, record["test_path"], "test source")
        test_digest = sha256(test_source)
        if test_digest != record["test_sha256"].lower():
            raise ValueError(f"test source SHA-256 mismatch at evidence row {number}")
        if not manifest_binds_test(manifest, record["test_path"], test_digest):
            raise ValueError(f"test source is not listed in source manifest at evidence row {number}")


def summary_markdown(rows: list[dict[str, str]], records: list[dict[str, str]]) -> str:
    linked = {record["row_key"] for record in records}
    fields = ("engine", "family_route", "mechanism_id", "provider", "effect_type")
    lines = [
        "# Direct-SD implementation evidence reconciliation",
        "",
        f"Frozen candidate rows: {len(rows)}. Evidence receipt records: {len(records)}. Distinct candidate rows with at least one hash-verified receipt: {len(linked)}. Candidate rows without linked receipts: {len(rows) - len(linked)}.",
        "",
        "This is an evidence-only join. A receipt does not establish general support, identifiability, admission, or calibrated interval coverage; no candidate row is promoted by this report.",
        "",
        "Evidence counts by exact row dimensions (rows with receipts / candidate rows):",
        "",
    ]
    for field in fields:
        groups: dict[str, tuple[int, int]] = {}
        for row in rows:
            label = row.get(field, "") or "(empty)"
            observed, total = groups.get(label, (0, 0))
            groups[label] = (observed + int(row["row_key"] in linked), total + 1)
        lines.extend([f"## {field}", "", "| Value | Receipted rows | Candidate rows |", "|---|---:|---:|"])
        lines.extend(f"| {label} | {observed} | {total} |" for label, (observed, total) in sorted(groups.items()))
        lines.append("")
    lines.extend([
        "Rows with multiple receipts are counted once. Candidate rows remain obligations until separately reviewed against the implementation contract and the complete required scope.",
        "",
    ])
    return "\n".join(lines)


def reconcile(rows_path: Path, evidence_path: Path, root: Path, summary_path: Path) -> dict[str, int]:
    rows = read_tsv(rows_path)
    records = read_tsv(evidence_path)
    if not has_expected_header(evidence_path):
        raise ValueError("evidence table header does not match the required schema")
    validate(rows, records, root)
    linked = {record["row_key"] for record in records}
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    summary_path.write_text(summary_markdown(rows, records), encoding="utf-8")
    return {"candidate_rows": len(rows), "linked_rows": len(linked), "unlinked_rows": len(rows) - len(linked), "evidence_records": len(records)}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--rows", type=Path, default=ROWS)
    parser.add_argument("--evidence", type=Path, default=EVIDENCE)
    parser.add_argument("--summary", type=Path, default=SUMMARY)
    args = parser.parse_args()
    counts = reconcile(args.rows, args.evidence, args.root, args.summary)
    print("EVIDENCE_RECONCILIATION_PASS " + " ".join(f"{key}={value}" for key, value in counts.items()))


if __name__ == "__main__":
    main()

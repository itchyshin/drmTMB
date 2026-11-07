#!/usr/bin/env python3
"""Fail-closed SHA-256 verification for a prepared calibration directory."""
import csv
import hashlib
from pathlib import Path


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def verify(directory: Path) -> None:
    hashes_file = directory / "source-hashes.csv"
    manifest = directory / "manifest.csv"
    if not hashes_file.is_file() or not manifest.is_file():
        raise ValueError("prepared manifest or source-hashes.csv is missing")
    with hashes_file.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    if not rows or not {"path", "sha256"}.issubset(rows[0]):
        raise ValueError("source-hashes.csv has an invalid schema")
    paths = [row["path"] for row in rows]
    manifest_rows = [row for row in rows if Path(row["path"]).name == "manifest.csv"]
    if len(paths) != len(set(paths)) or len(manifest_rows) != 1:
        raise ValueError("hash registry must uniquely include the prepared manifest")
    for row in rows:
        path = Path(row["path"])
        if not path.is_file() or sha256(path) != row["sha256"]:
            raise ValueError(f"artifact hash mismatch or missing artifact: {path}")
    if sha256(manifest) != manifest_rows[0]["sha256"]:
        raise ValueError("local prepared manifest differs from the pinned manifest")


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("directory", type=Path)
    verify(p.parse_args().directory.resolve(strict=True))
    print("ARTIFACT_INTEGRITY_PASS")

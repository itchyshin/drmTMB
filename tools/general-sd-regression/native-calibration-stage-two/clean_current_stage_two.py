#!/usr/bin/env python3
"""Validate and batch the frozen clean-current look-two seed manifest.

This module performs identity checks and a deterministic row transformation
only. It does not prepare or launch calibration fits.
"""

import csv
import hashlib
from pathlib import Path


EXPECTED_SHA256 = "7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98"
FIELDS = ("index", "a", "replicate", "seed", "groups", "repeats", "beta0",
          "beta1", "alpha0", "design_mode", "master_seed", "look")
ROWS_PER_BATCH = 3000
N_BATCHES = 3
EXPECTED_MASTER_SEED = "2026101902"
DEFAULT_MANIFEST = (
    Path(__file__).resolve().parents[3]
    / "docs/dev-log/general-sd-regression/evidence/calibration-20261019"
    / "clean-current-seed-design-v1/look2.csv"
)


class ManifestContractError(ValueError):
    """The source differs from the frozen clean-current look-two contract."""


def sha256(path):
    """Return the SHA-256 digest of a file's exact bytes."""
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_frozen_rows(path=DEFAULT_MANIFEST):
    """Read CSV fields as strings, preserving their original values."""
    with Path(path).open("r", newline="", encoding="utf-8") as stream:
        reader = csv.DictReader(stream)
        if tuple(reader.fieldnames or ()) != FIELDS:
            raise ManifestContractError("manifest header differs from the frozen field order")
        return list(reader)


def write_rows(rows, path):
    """Write rows using the frozen CSV field order; intended for contract tests."""
    with Path(path).open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def _validate_rows(rows):
    if len(rows) != ROWS_PER_BATCH * N_BATCHES:
        raise ManifestContractError("manifest must contain exactly 9,000 rows")
    if any(tuple(row) != FIELDS for row in rows):
        raise ManifestContractError("manifest row fields differ from the frozen contract")
    if [row["index"] for row in rows] != [str(i) for i in range(1, 9001)]:
        raise ManifestContractError("manifest indices must be the ordered sequence 1..9000")
    expected_a = ("-0.5", "0", "0.5")
    for i, row in enumerate(rows):
        batch = i // ROWS_PER_BATCH
        expected = {
            "a": expected_a[batch],
            "replicate": str(1001 + i % ROWS_PER_BATCH),
            "groups": "160",
            "repeats": "16",
            "beta0": "-0.3",
            "beta1": "0.6",
            "alpha0": "-0.22314355131421",
            "design_mode": "clean_current",
            "master_seed": EXPECTED_MASTER_SEED,
            "look": "look2",
        }
        if any(row[field] != value for field, value in expected.items()):
            raise ManifestContractError(f"manifest row {i + 1} violates the frozen design")
    seeds = [row["seed"] for row in rows]
    if any(not seed.isdigit() for seed in seeds) or len(set(seeds)) != len(seeds):
        raise ManifestContractError("seed values must be unique positive integers")
    masters = {row["master_seed"] for row in rows}
    if masters != {EXPECTED_MASTER_SEED} or masters.intersection(seeds):
        raise ManifestContractError("master seed must match the frozen, seed-disjoint value")


def load_batches(path=DEFAULT_MANIFEST):
    """Validate the exact frozen manifest and return three identity-preserving batches.

    Each output row retains every source field. ``index`` becomes the local
    1..3000 batch index and ``stage_two_index`` carries the original global
    1..9000 index.
    """
    path = Path(path)
    actual_sha = sha256(path)
    if actual_sha != EXPECTED_SHA256:
        raise ManifestContractError(
            f"frozen manifest SHA-256 mismatch: expected {EXPECTED_SHA256}, got {actual_sha}"
        )
    rows = read_frozen_rows(path)
    _validate_rows(rows)
    batches = [_transform_batch(rows, batch_id)
               for batch_id in range(1, N_BATCHES + 1)]
    for batch_id, batch in enumerate(batches, start=1):
        validate_batch(batch, path, batch_id)
    return batches


def adapter_qualification_cases(batches):
    """Return the three frozen cross-truth probe identities for this stream.

    The cases deliberately use the same truth/replicate positions as the
    legacy adapter qualification, while taking their seeds and provenance
    from the clean-current source.  Each supplied batch is revalidated against
    the frozen source before a probe can be selected.
    """
    if not isinstance(batches, (list, tuple)) or len(batches) != N_BATCHES:
        raise ManifestContractError(
            "qualification mapping requires three clean-current batches"
        )
    cases = []
    expected = ((1, 1, 1, 1001, "-0.5"),
                (2, 1001, 4001, 2001, "0"),
                (3, 2001, 8001, 3001, "0.5"))
    for batch, (batch_id, local_index, source_index, replicate, truth) in zip(
            batches, expected):
        try:
            validate_batch(batch, batch_id=batch_id)
        except ManifestContractError as exc:
            raise ManifestContractError(
                f"qualification mapping is invalid for batch {batch_id}: {exc}"
            ) from exc
        row = batch[local_index - 1]
        if (row["index"] != str(local_index)
                or row["stage_two_index"] != str(source_index)
                or row["source_index"] != str(source_index)
                or row["batch_id"] != str(batch_id)
                or row["replicate"] != str(replicate)
                or row["a"] != truth
                or row["source_design_mode"] != "clean_current"
                or row["design_mode"] != "clean_current_stage_two"):
            raise ManifestContractError(
                f"qualification mapping differs from clean-current source for batch {batch_id}"
            )
        cases.append({"batch_id": batch_id, "local_index": local_index,
                      "stage_two_index": source_index, "replicate": replicate,
                      "a": row["a"], "seed": int(row["seed"])})
    return cases


def _transform_batch(source_rows, batch_id):
    start = (batch_id - 1) * ROWS_PER_BATCH
    batch = []
    for source in source_rows[start:start + ROWS_PER_BATCH]:
        row = {key: value for key, value in source.items()
               if key not in {"index", "design_mode"}}
        global_index = source["index"]
        row.update(index=str(int(global_index) - start),
                   stage_two_index=global_index,
                   batch_id=str(batch_id),
                   source_index=global_index,
                   source_design_mode=source["design_mode"],
                   design_mode="clean_current_stage_two")
        batch.append(row)
    return batch


def validate_batch(rows, frozen_path=DEFAULT_MANIFEST, batch_id=None):
    """Require one batch to equal the exact frozen-source transformation."""
    if batch_id not in (1, 2, 3):
        raise ManifestContractError("batch_id must be 1, 2, or 3")
    path = Path(frozen_path)
    actual_sha = sha256(path)
    if actual_sha != EXPECTED_SHA256:
        raise ManifestContractError(
            f"frozen manifest SHA-256 mismatch: expected {EXPECTED_SHA256}, got {actual_sha}"
        )
    source_rows = read_frozen_rows(path)
    _validate_rows(source_rows)
    expected = _transform_batch(source_rows, batch_id)
    if rows != expected:
        raise ManifestContractError(
            f"batch {batch_id} differs from the exact frozen-source row mapping"
        )
    return True

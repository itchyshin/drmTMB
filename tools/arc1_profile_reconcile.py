#!/usr/bin/env python3
"""Shared fail-closed artifact checks for Arc 1 profile receipts."""

from __future__ import annotations

import csv
import hashlib
import math
from pathlib import Path


def fail(prefix: str, message: str) -> None:
    raise SystemExit(f"{prefix}: {message}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_rows(path: Path, prefix: str) -> list[dict[str, str]]:
    if not path.is_file():
        fail(prefix, f"missing artifact {path}")
    with path.open(newline="") as stream:
        rows = list(csv.DictReader(stream, delimiter="\t"))
    if not rows:
        fail(prefix, f"empty artifact {path}")
    return rows


def read_one(path: Path, prefix: str) -> dict[str, str]:
    rows = read_rows(path, prefix)
    if len(rows) != 1:
        fail(prefix, f"{path} must contain exactly one row")
    return rows[0]


def require_fields(
    row: dict[str, str], expected: dict[str, str], path: Path, prefix: str
) -> None:
    for name, value in expected.items():
        if row.get(name, "") != value:
            fail(prefix, f"{path}: {name}={row.get(name)!r}, expected {value!r}")


def number(row: dict[str, str], name: str, path: Path, prefix: str) -> float:
    try:
        value = float(row[name])
    except (KeyError, ValueError) as error:
        fail(prefix, f"{path}: invalid numeric {name} ({error})")
    if not math.isfinite(value):
        fail(prefix, f"{path}: {name} is not finite")
    return value


def same_number(left: float, right: float) -> bool:
    return math.isclose(left, right, rel_tol=1e-13, abs_tol=1e-14)


def validate_profile_artifacts(
    *,
    receipt_path: Path,
    receipt: dict[str, str],
    runner_path: Path,
    target_id: str,
    profile_parameter: str,
    prefix: str,
    estimator: str = "ML",
) -> dict[str, str]:
    """Bind one receipt to the current runner, fixture, trace, and interval."""
    require_fields(
        receipt,
        {
            "target_id": target_id,
            "profile_parameter": profile_parameter,
            "estimator": estimator,
            "target_type": "direct",
            "runner_sha256": sha256(runner_path),
        },
        receipt_path,
        prefix,
    )
    estimate = number(receipt, "estimate", receipt_path, prefix)
    lower = number(receipt, "lower", receipt_path, prefix)
    upper = number(receipt, "upper", receipt_path, prefix)
    if not lower < estimate < upper:
        fail(prefix, f"{receipt_path}: estimate is not strictly inside the interval")

    stem = receipt_path.name.removesuffix("-receipt.tsv")
    trace_path = receipt_path.with_name(f"{stem}-trace.tsv")
    interval_path = receipt_path.with_name(f"{stem}-interval.tsv")
    fixture_name = Path(receipt.get("fixture_path", "")).name
    if not fixture_name:
        fail(prefix, f"{receipt_path}: fixture_path is empty")
    fixture_path = receipt_path.with_name(fixture_name)
    hashes = {
        "fixture_sha256": sha256(fixture_path),
        "trace_sha256": sha256(trace_path),
        "interval_sha256": sha256(interval_path),
    }
    for name, digest in hashes.items():
        if receipt.get(name, "") != digest:
            fail(prefix, f"{receipt_path}: {name} does not match retained artifact")

    sidecar_identity = {
        "cell_id": receipt["cell_id"],
        "target_id": target_id,
        "seed": receipt["seed"],
        "information_rung": receipt["execution_information_rung"],
    }
    interval = read_one(interval_path, prefix)
    require_fields(
        interval,
        {
            **sidecar_identity,
            "parm": profile_parameter,
            "method": "profile",
            "profile.engine": "tmbprofile",
            "conf.status": "profile",
            "profile.boundary": "FALSE",
            "profile.message": "ok",
        },
        interval_path,
        prefix,
    )
    interval_lower = number(interval, "lower", interval_path, prefix)
    interval_upper = number(interval, "upper", interval_path, prefix)
    if not same_number(interval_lower, lower) or not same_number(interval_upper, upper):
        fail(prefix, f"{interval_path}: endpoints do not match receipt")

    trace = read_rows(trace_path, prefix)
    profile_values: list[float] = []
    for trace_row in trace:
        require_fields(
            trace_row,
            {
                **sidecar_identity,
                "parm": profile_parameter,
                "profile_pass": "profile",
                "conf.status": "profile",
                "profile.message": "ok",
            },
            trace_path,
            prefix,
        )
        trace_estimate = number(trace_row, "estimate", trace_path, prefix)
        trace_lower = number(trace_row, "conf.low", trace_path, prefix)
        trace_upper = number(trace_row, "conf.high", trace_path, prefix)
        if not (
            same_number(trace_estimate, estimate)
            and same_number(trace_lower, lower)
            and same_number(trace_upper, upper)
        ):
            fail(prefix, f"{trace_path}: trace estimate/endpoints do not match receipt")
        profile_values.append(number(trace_row, "profile_value", trace_path, prefix))
    if not min(profile_values) < estimate < max(profile_values):
        fail(prefix, f"{trace_path}: retained profile does not span both sides of estimate")
    return hashes

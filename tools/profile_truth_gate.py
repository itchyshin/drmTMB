#!/usr/bin/env python3
"""Fail-closed truth gate for profile-interval receipts.

The reconcilers (tools/arc2_profile_reconcile.py and the four
tools/reconcile-arc1-*.py scripts) check interval SHAPE exhaustively --
conf_status, convergence, pdHess, profile_boundary, clamp_limited,
trace_complete, failure_reason -- but historically checked nothing about
interval LOCATION. They could not: the runner recorded the true parameter
value only inside the prose field `true_parameter_scale`, e.g.

    "0.55 phylogenetic random-intercept SD on log(sigma) (NB2 dispersion),
     independent of a 0.20 phylogenetic random-slope SD ... 30 observations
     per tip"

Four numbers in one sentence, one of which is the truth. There was no numeric
field to compare `lower <= truth <= upper` against, so three separate cells
reached review with intervals that excluded their own true value and were
caught only by a human reading the prose.

This module supplies the missing half. Truth is read from
tools/profile-truth-manifest.tsv, which is DERIVED by
tools/emit-profile-truth-manifest.R from the fixture builders themselves (and,
for the frozen Arc 1 cohorts, from their runners' own truth constants). It is
never hand-typed here; re-declaring it would recreate the defect one layer up.

THE GATE RULE
-------------
A 95% profile interval is *supposed* to miss the true value about 5% of the
time. With only 3-5 retained seeds per cell, P(at least one miss) runs about
15-23%, so a rule of "any miss demotes the cell" would demote cells for
behaving exactly as a correct interval must. Equally, a rule that ignores
misses entirely is what we are fixing.

So a cell FAILS when either:

  * any retained seed misses truth by more than MISS_MAGNITUDE_TOL of the
    scale (a LOCATION failure -- the interval is in the wrong place), or
  * more than MISS_COUNT_TOL seeds miss at all, at any magnitude (a RATE
    failure -- too often, even if each miss is narrow).

Calibration against the retained surface at the time of writing: this fails
mc-0424 (6.3% miss), mc-0260m (16.7%) and mc-0423 (12.8%), and passes
mc-0409 whose worst superseded-cohort miss is 1.7%.

SCOPE AND SEEDS
---------------
The gate is evaluated per CELL over its PINNED seed set, not over whatever
receipts happen to be on disk. mc-0409 is the reason: its directory holds both
a superseded n_each=8 cohort (one of which misses) and the repaired n_each=24
family (all five bracket truth). Scoring the union would demote a cell whose
current evidence is clean. Pinned seeds are the primary defence; the magnitude
tolerance is defence in depth behind them.

FAIL-CLOSED
-----------
A missing, blank, unparseable, or non-finite truth is a hard failure, never a
skip. A gate that silently skips the cells it cannot evaluate is the same
defect it was built to close -- and there is a real instance: mc-0263's truth
is a structural zero (its DGP puts the sigma effect on z, not x), so any
"parse the leading number from the prose" heuristic skips it silently.
"""

from __future__ import annotations

import csv
import math
from pathlib import Path

# A miss narrower than this fraction of the scale is treated as the sampling
# noise a 95% interval is expected to produce, not as a location defect.
MISS_MAGNITUDE_TOL = 0.05

# More than this many misses is a rate failure regardless of how narrow each
# one is. One narrow miss is tolerated; two is a pattern.
MISS_COUNT_TOL = 1

MANIFEST_PATH = Path(__file__).with_name("profile-truth-manifest.tsv")


class TruthGateError(Exception):
    """Raised when the gate cannot be evaluated, or when a cell fails it."""


def load_truth_manifest(path: Path | None = None) -> dict[str, dict[str, str]]:
    """Read the derived truth manifest, keyed by cell_id.

    Fails closed: an absent manifest is an error, not an empty dict, because
    an empty dict would make every cell trivially unevaluable and therefore
    trivially passing.
    """
    manifest_path = MANIFEST_PATH if path is None else path
    if not manifest_path.is_file():
        raise TruthGateError(
            f"truth manifest missing: {manifest_path}. "
            "Regenerate with: Rscript --no-init-file tools/emit-profile-truth-manifest.R"
        )
    with manifest_path.open(newline="") as stream:
        rows = list(csv.DictReader(stream, delimiter="\t"))
    if not rows:
        raise TruthGateError(f"truth manifest is empty: {manifest_path}")
    manifest: dict[str, dict[str, str]] = {}
    for row in rows:
        cell_id = (row.get("cell_id") or "").strip()
        if not cell_id:
            raise TruthGateError(f"{manifest_path}: row with blank cell_id")
        if cell_id in manifest:
            raise TruthGateError(f"{manifest_path}: duplicate cell_id {cell_id!r}")
        manifest[cell_id] = row
    return manifest


def truth_for(cell_id: str, manifest: dict[str, dict[str, str]]) -> float:
    """Return the numeric truth for one cell, failing closed if unusable."""
    row = manifest.get(cell_id)
    if row is None:
        raise TruthGateError(
            f"{cell_id}: no entry in the truth manifest. Every contract cell must "
            "declare a derived true_value; add it to "
            "tools/emit-profile-truth-manifest.R rather than skipping the cell."
        )
    raw = (row.get("true_value") or "").strip()
    if not raw:
        raise TruthGateError(f"{cell_id}: blank true_value in the truth manifest")
    try:
        value = float(raw)
    except ValueError as error:
        raise TruthGateError(
            f"{cell_id}: unparseable true_value {raw!r} ({error})"
        ) from error
    if not math.isfinite(value):
        raise TruthGateError(f"{cell_id}: non-finite true_value {raw!r}")
    return value


def miss_scale(true_value: float, lower: float, upper: float) -> float:
    """The scale a miss distance is measured against.

    Normally |truth|. When truth is a structural zero (mc-0263, whose DGP puts
    the sigma effect on z rather than x) a relative miss is undefined, so fall
    back to the interval's own half-width -- the only scale available.
    """
    if abs(true_value) > 0.0:
        return abs(true_value)
    half_width = (upper - lower) / 2.0
    if not math.isfinite(half_width) or half_width <= 0.0:
        raise TruthGateError(
            "cannot scale a miss against a zero truth and a degenerate interval "
            f"[{lower}, {upper}]"
        )
    return half_width


def seed_verdict(true_value: float, lower: float, upper: float) -> dict[str, object]:
    """Bracketing verdict for one retained seed."""
    for name, value in (("lower", lower), ("upper", upper)):
        if not math.isfinite(value):
            raise TruthGateError(f"non-finite {name} endpoint: {value!r}")
    if lower > upper:
        raise TruthGateError(f"inverted interval [{lower}, {upper}]")
    brackets = lower <= true_value <= upper
    if brackets:
        return {"brackets_truth": True, "relative_miss": 0.0}
    distance = (lower - true_value) if true_value < lower else (true_value - upper)
    return {
        "brackets_truth": False,
        "relative_miss": distance / miss_scale(true_value, lower, upper),
    }


def evaluate_cell(
    cell_id: str,
    true_value: float,
    seeds: dict[str, tuple[float, float]],
) -> dict[str, object]:
    """Apply the gate to one cell over its pinned seed set.

    `seeds` maps seed -> (lower, upper). Returns a verdict dict; `passed` is
    the gate outcome and `reasons` explains any failure.
    """
    if not seeds:
        raise TruthGateError(
            f"{cell_id}: no retained seeds to evaluate. An empty seed set cannot "
            "pass the gate -- pin the cohort in the reconciler contract."
        )
    per_seed: dict[str, dict[str, object]] = {}
    for seed, (lower, upper) in sorted(seeds.items()):
        try:
            per_seed[seed] = seed_verdict(true_value, lower, upper)
        except TruthGateError as error:
            raise TruthGateError(f"{cell_id} seed {seed}: {error}") from error

    misses = {s: v for s, v in per_seed.items() if not v["brackets_truth"]}
    worst = max((float(v["relative_miss"]) for v in per_seed.values()), default=0.0)

    reasons: list[str] = []
    if worst > MISS_MAGNITUDE_TOL:
        offenders = ", ".join(
            f"{s} ({float(v['relative_miss']):.1%})"
            for s, v in sorted(misses.items())
            if float(v["relative_miss"]) > MISS_MAGNITUDE_TOL
        )
        reasons.append(
            f"interval excludes truth {true_value:g} by more than "
            f"{MISS_MAGNITUDE_TOL:.0%} of scale at seed(s) {offenders}"
        )
    if len(misses) > MISS_COUNT_TOL:
        reasons.append(
            f"{len(misses)} of {len(per_seed)} retained seeds miss truth "
            f"(at most {MISS_COUNT_TOL} tolerated)"
        )

    return {
        "cell_id": cell_id,
        "true_value": true_value,
        "n_seeds": len(per_seed),
        "n_misses": len(misses),
        "worst_relative_miss": worst,
        "passed": not reasons,
        "reasons": reasons,
        "per_seed": per_seed,
    }


def require_pass(verdict: dict[str, object], prefix: str = "truth gate") -> None:
    """Raise if a verdict failed. Used by the reconcilers to fail closed."""
    if not verdict["passed"]:
        cell_id = verdict["cell_id"]
        reasons = "; ".join(str(r) for r in verdict["reasons"])  # type: ignore[union-attr]
        raise TruthGateError(f"{prefix}: {cell_id}: {reasons}")

#!/usr/bin/env python3
"""Generate the Q-Series v1.0 release-readiness ledger.

The ledger is derived from structured-re-q-series-support-cells.tsv. It is a
release-planning view, not new statistical evidence: it separates basic-working
Gaussian and basic-distribution rows from post-v1.0 inference/support work.
"""

from __future__ import annotations

import argparse
import csv
import io
import pathlib
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv"
DEFAULT_OUTPUT = ROOT / "docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv"
DEFAULT_STATUS_OUTPUT = ROOT / "docs/dev-log/release-audits/q-series-v1-release-status.md"

FIELDS = (
    "cell_id",
    "formula_cell",
    "family_class",
    "family",
    "structure_provider",
    "dimension_pattern",
    "endpoint_set",
    "slope_class",
    "fit_status",
    "interval_status",
    "coverage_status",
    "authority_status",
    "v1_track",
    "v1_priority",
    "v1_release_role",
    "post_v1_gate",
    "claim_boundary",
    "evidence_url",
    "next_gate",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate or check the Q-Series v1.0 release-readiness ledger."
    )
    parser.add_argument("--input", type=pathlib.Path, default=DEFAULT_INPUT)
    parser.add_argument("--output", type=pathlib.Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--write",
        action="store_true",
        help="Write the generated ledger to --output instead of stdout.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Fail if --output is missing or differs from the generated ledger.",
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="Print v1_track counts to stderr.",
    )
    parser.add_argument(
        "--status-output",
        type=pathlib.Path,
        default=DEFAULT_STATUS_OUTPUT,
        help="Markdown release-status summary path.",
    )
    parser.add_argument(
        "--write-status",
        action="store_true",
        help="Write the generated Markdown release-status summary.",
    )
    parser.add_argument(
        "--check-status",
        action="store_true",
        help="Fail if the Markdown release-status summary differs.",
    )
    return parser.parse_args()


def read_support_cells(path: pathlib.Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle, delimiter="\t", quoting=csv.QUOTE_NONE))


def classify(row: dict[str, str]) -> tuple[str, str, str, str, str]:
    exact_ir = (
        row["family_class"] == "gaussian"
        and row["interval_status"] == "inference_ready"
        and row["coverage_status"] == "inference_ready"
    )
    if exact_ir:
        return (
            "gaussian_inference_anchor",
            "P1",
            "Exact Gaussian inference-ready anchor for v1.0; keep row-local.",
            "Post-v1.0 supported-tier stress review before public support wording.",
            "Exact inference_ready remains row-local; no neighbouring row, q4/q8 route, supported claim, REML, AI-REML, new coverage, or public support is promoted by this ledger.",
        )
    if row["family_class"] == "gaussian":
        if row["fit_status"] in {"point_fit", "supported", "diagnostic_only"}:
            return (
                "gaussian_basic_working",
                "P2",
                "Implemented/basic-working Gaussian candidate for the v1.0 surface.",
                "Row-specific retained-denominator interval and coverage review if this row is promoted beyond basic working.",
                "Basic-working is not interval_status, coverage_status, inference_ready, supported, REML, AI-REML, new coverage, or public support.",
            )
        return (
            "gaussian_post_v1_validation",
            "P4",
            "Gaussian row left outside the v1.0 basic-working surface.",
            "Implementation, rejection, or interval route design after the v1.0 cut.",
            "Deferred Gaussian validation creates no support-cell promotion, no inference_ready, no supported claim, no coverage, no REML, no AI-REML, and no public support.",
        )
    if row["family_class"] == "non_gaussian" and row["fit_status"] == "point_fit":
        return (
            "basic_distribution_recovery",
            "P3",
            "Basic-distribution recovery candidate for v1.0, with interval/support deferred.",
            "Family-specific interval, coverage, and structured-covariance design after v1.0.",
            "Recovery-only evidence is not interval evidence, coverage evidence, inference_ready, supported, REML, AI-REML, broad structured-covariance support, or public support.",
        )
    return (
        "basic_distribution_post_v1_design",
        "P5",
        "Non-Gaussian row left outside the v1.0 basic-distribution surface.",
        "Family-specific implementation, rejection, or limitation design after the v1.0 cut.",
        "Deferred family design creates no parser-ready shortcut, no interval evidence, no coverage, no inference_ready, no supported claim, no REML, no AI-REML, and no public support.",
    )


def build_ledger(support_rows: list[dict[str, str]]) -> list[dict[str, str]]:
    ledger: list[dict[str, str]] = []
    for row in support_rows:
        track, priority, role, post_v1_gate, boundary = classify(row)
        ledger.append(
            {
                "cell_id": row["cell_id"],
                "formula_cell": row["formula_cell"],
                "family_class": row["family_class"],
                "family": row["family"],
                "structure_provider": row["structure_provider"],
                "dimension_pattern": row["dimension_pattern"],
                "endpoint_set": row["endpoint_set"],
                "slope_class": row["slope_class"],
                "fit_status": row["fit_status"],
                "interval_status": row["interval_status"],
                "coverage_status": row["coverage_status"],
                "authority_status": row["authority_status"],
                "v1_track": track,
                "v1_priority": priority,
                "v1_release_role": role,
                "post_v1_gate": post_v1_gate,
                "claim_boundary": boundary,
                "evidence_url": row["evidence_url"],
                "next_gate": row["next_gate"],
            }
        )
    return ledger


def render_tsv(rows: list[dict[str, str]]) -> str:
    buffer = io.StringIO()
    writer = csv.DictWriter(
        buffer,
        fieldnames=FIELDS,
        delimiter="\t",
        lineterminator="\n",
        quoting=csv.QUOTE_NONE,
        extrasaction="raise",
    )
    writer.writeheader()
    writer.writerows(rows)
    return buffer.getvalue()


def count_by(rows: list[dict[str, str]], field: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for row in rows:
        key = row[field]
        counts[key] = counts.get(key, 0) + 1
    return counts


def percent(numerator: int, denominator: int) -> str:
    if denominator == 0:
        return "NA"
    return f"{(100 * numerator / denominator):.1f}%"


def render_status_markdown(
    support_rows: list[dict[str, str]],
    ledger_rows: list[dict[str, str]],
) -> str:
    track_counts = count_by(ledger_rows, "v1_track")
    gaussian_rows = sum(row["family_class"] == "gaussian" for row in support_rows)
    nongaussian_rows = sum(
        row["family_class"] == "non_gaussian" for row in support_rows
    )
    inference_ready_rows = track_counts.get("gaussian_inference_anchor", 0)
    gaussian_basic_rows = track_counts.get("gaussian_basic_working", 0)
    nongaussian_recovery_rows = track_counts.get("basic_distribution_recovery", 0)
    gaussian_deferred_rows = track_counts.get("gaussian_post_v1_validation", 0)
    nongaussian_deferred_rows = track_counts.get(
        "basic_distribution_post_v1_design", 0
    )
    supported_authority_rows = sum(
        row["authority_status"] == "supported" for row in support_rows
    )
    v1_gaussian_core_rows = inference_ready_rows + gaussian_basic_rows
    v1_basic_surface_rows = v1_gaussian_core_rows + nongaussian_recovery_rows
    post_v1_rows = gaussian_deferred_rows + nongaussian_deferred_rows
    total_rows = len(support_rows)
    v1_basic_surface_pct = percent(v1_basic_surface_rows, total_rows)
    gaussian_core_pct = percent(v1_gaussian_core_rows, gaussian_rows)
    nongaussian_recovery_pct = percent(nongaussian_recovery_rows, nongaussian_rows)
    inference_ready_pct = percent(inference_ready_rows, total_rows)
    supported_authority_pct = percent(supported_authority_rows, total_rows)
    post_v1_pct = percent(post_v1_rows, total_rows)
    return f"""# Q-Series v1.0 Release Status

Generated from `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
and `docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv` by
`tools/qseries_v1_release_ledger.py`.

## Summary

This is a release-planning boundary, not a support promotion. The Q-Series board
currently has {len(support_rows)} support cells: {gaussian_rows} Gaussian rows
and {nongaussian_rows} non-Gaussian rows. The pragmatic v1.0 surface has
{v1_basic_surface_rows} row-level roles: {inference_ready_rows} exact Gaussian
`inference_ready` anchors, {gaussian_basic_rows} additional Gaussian
basic-working rows, and {nongaussian_recovery_rows} basic-distribution recovery
rows. The remaining {post_v1_rows} rows stay in post-v1.0 validation or design.

There are {supported_authority_rows} `supported` authority rows. This summary
does not authorize coverage, q4 coverage, support-cell promotion,
`inference_ready` promotion, `supported` wording, REML, AI-REML, or public
support.

## Progress Accounting

These percentages are row-accounting summaries, not package-release completion
claims.

| Measure | Rows | Percent | Meaning |
| --- | ---: | ---: | --- |
| Practical v1.0 row surface | {v1_basic_surface_rows}/{total_rows} | {v1_basic_surface_pct} | Exact Gaussian anchors plus additional Gaussian basic-working rows and basic-distribution recovery rows. |
| Gaussian v1.0 core | {v1_gaussian_core_rows}/{gaussian_rows} | {gaussian_core_pct} | Gaussian rows inside the exact-anchor or basic-working v1.0 surface. |
| Basic-distribution recovery | {nongaussian_recovery_rows}/{nongaussian_rows} | {nongaussian_recovery_pct} | Non-Gaussian rows with point-fit recovery evidence only. |
| Exact `inference_ready` anchors | {inference_ready_rows}/{total_rows} | {inference_ready_pct} | Row-local exact Gaussian inference anchors; no neighbour rows inherit this status. |
| `supported` authority | {supported_authority_rows}/{total_rows} | {supported_authority_pct} | Structured rows with support authority; this remains zero. |
| Post-v1.0 validation/design | {post_v1_rows}/{total_rows} | {post_v1_pct} | Rows deliberately left outside the v1.0 practical surface. |

## Release Tracks

| Track | Rows | v1.0 role | Boundary |
| --- | ---: | --- | --- |
| `gaussian_inference_anchor` | {inference_ready_rows} | Exact row-local Gaussian inference anchors. | Keep row-local; no neighbour, q4/q8, `supported`, REML, AI-REML, new coverage, or public-support promotion. |
| `gaussian_basic_working` | {gaussian_basic_rows} | Implemented/basic-working Gaussian rows for the v1.0 surface. | Basic-working is not interval evidence, coverage evidence, `inference_ready`, `supported`, REML, AI-REML, or public support. |
| `basic_distribution_recovery` | {nongaussian_recovery_rows} | Basic-distribution recovery rows for v1.0. | Recovery-only evidence is not interval evidence, coverage evidence, `inference_ready`, `supported`, REML, AI-REML, or broad structured-covariance support. |
| `gaussian_post_v1_validation` | {gaussian_deferred_rows} | Gaussian rows outside the v1.0 basic-working surface. | Leave for post-v1.0 implementation, rejection, interval, or coverage review. |
| `basic_distribution_post_v1_design` | {nongaussian_deferred_rows} | Non-Gaussian rows outside the v1.0 basic-distribution surface. | Leave for post-v1.0 family-specific implementation, rejection, or limitation design. |

## Recommended v1.0 Wording

`drmTMB` v1.0 can describe the Q-Series as having an audited
implemented/basic-working Gaussian structured-random-effect surface and a
basic-distribution recovery surface. Exactly {inference_ready_rows} Gaussian
rows are row-local `inference_ready`, and no structured row is `supported`.

## Forbidden Wording

Do not describe the Q-Series as complete, broadly supported, fully
inference-ready, or coverage-ready. Do not claim q4/q8 coverage, derived
correlation intervals, non-Gaussian structured covariance support, broad bridge
support, REML, AI-REML, or public support from this release status.

## Next Gates

Before v1.0 release wording is final, keep `README.md`, `NEWS.md`,
`ROADMAP.md`, and `docs/dev-log/known-limitations.md` aligned with this file.
Post-v1.0 validation can reopen full `inference_ready` and `supported` work one
row at a time.
"""


def print_summary(rows: list[dict[str, str]]) -> None:
    counts = count_by(rows, "v1_track")
    total_rows = len(rows)
    gaussian_rows = sum(row["family_class"] == "gaussian" for row in rows)
    nongaussian_rows = sum(row["family_class"] == "non_gaussian" for row in rows)
    inference_ready_rows = counts.get("gaussian_inference_anchor", 0)
    gaussian_basic_rows = counts.get("gaussian_basic_working", 0)
    nongaussian_recovery_rows = counts.get("basic_distribution_recovery", 0)
    gaussian_deferred_rows = counts.get("gaussian_post_v1_validation", 0)
    nongaussian_deferred_rows = counts.get("basic_distribution_post_v1_design", 0)
    supported_authority_rows = sum(
        row["authority_status"] == "supported" for row in rows
    )
    v1_basic_surface_rows = (
        inference_ready_rows + gaussian_basic_rows + nongaussian_recovery_rows
    )
    v1_gaussian_core_rows = inference_ready_rows + gaussian_basic_rows
    post_v1_rows = gaussian_deferred_rows + nongaussian_deferred_rows
    summary = ", ".join(f"{key}={counts[key]}" for key in sorted(counts))
    print(
        (
            f"qseries_v1_release_ledger: {total_rows} rows; {summary}; "
            f"practical_v1_surface={v1_basic_surface_rows}/{total_rows} "
            f"({percent(v1_basic_surface_rows, total_rows)}), "
            f"gaussian_core={v1_gaussian_core_rows}/{gaussian_rows} "
            f"({percent(v1_gaussian_core_rows, gaussian_rows)}), "
            f"basic_distribution_recovery={nongaussian_recovery_rows}/{nongaussian_rows} "
            f"({percent(nongaussian_recovery_rows, nongaussian_rows)}), "
            f"exact_inference_ready={inference_ready_rows}/{total_rows} "
            f"({percent(inference_ready_rows, total_rows)}), "
            f"supported_authority={supported_authority_rows}/{total_rows} "
            f"({percent(supported_authority_rows, total_rows)}), "
            f"post_v1={post_v1_rows}/{total_rows} "
            f"({percent(post_v1_rows, total_rows)})"
        ),
        file=sys.stderr,
    )


def main() -> int:
    args = parse_args()
    support_rows = read_support_cells(args.input)
    ledger_rows = build_ledger(support_rows)
    output = render_tsv(ledger_rows)
    status_output = render_status_markdown(support_rows, ledger_rows)
    if args.summary:
        with io.StringIO(output) as handle:
            print_summary(list(csv.DictReader(handle, delimiter="\t")))
    if args.check:
        if not args.output.exists():
            print(f"{args.output}: missing", file=sys.stderr)
            return 1
        current = args.output.read_text(encoding="utf-8")
        if current != output:
            print(f"{args.output}: differs from generated ledger", file=sys.stderr)
            return 1
    if args.check_status:
        if not args.status_output.exists():
            print(f"{args.status_output}: missing", file=sys.stderr)
            return 1
        current_status = args.status_output.read_text(encoding="utf-8")
        if current_status != status_output:
            print(
                f"{args.status_output}: differs from generated status summary",
                file=sys.stderr,
            )
            return 1
    if args.write:
        args.output.write_text(output, encoding="utf-8")
    if args.write_status:
        args.status_output.write_text(status_output, encoding="utf-8")
    if args.check or args.check_status or args.write or args.write_status:
        return 0
    sys.stdout.write(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

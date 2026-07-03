#!/usr/bin/env python3
"""Print a compact scaffold for future Q-Series tranche packets.

The goal is speed: capture the repeated no-claim boundaries, member board,
and wiring checklist from a few arguments before editing the dashboard by hand.
The script prints to stdout by default so it cannot silently mutate evidence.
"""

from __future__ import annotations

import argparse
import datetime as dt


BLOCKING_MEMBERS = ("rose", "fisher", "gauss", "noether", "grace")
ADVISORY_MEMBERS = ("ada", "curie", "boole", "emmy")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Scaffold a no-compute Q-Series tranche packet."
    )
    parser.add_argument("--tranche", required=True, help="Tranche label, e.g. T130")
    parser.add_argument("--slug", required=True, help="Short lowercase slug")
    parser.add_argument("--evidence", required=True, help="Primary evidence path")
    parser.add_argument(
        "--next-gate",
        required=True,
        help="Next gate text, usually a checkpointed review or no-compute route",
    )
    parser.add_argument(
        "--slice-id",
        default="SCXXX",
        help="Member-discussion slice id placeholder",
    )
    parser.add_argument(
        "--observed-at",
        default=dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        help="UTC timestamp for member rows",
    )
    return parser.parse_args()


def no_claim_boundary(tranche: str) -> str:
    return (
        f"{tranche} contract/scaffold only; no host command; no model run; "
        "no retained denominator; no coverage; no support-cell status edit; "
        "no inference_ready; no supported; no q4/q8 expansion; no REML; "
        "no AI-REML; no public support; not a tier claim."
    )


def main() -> int:
    args = parse_args()
    meeting = f"meeting-{args.observed_at[:10]}-{args.tranche.lower()}-{args.slug}"
    print("# Q-Series Tranche Scaffold")
    print()
    print(f"tranche: {args.tranche}")
    print(f"slug: {args.slug}")
    print(f"evidence: {args.evidence}")
    print(f"next_gate: {args.next_gate}")
    print()
    print("## Claim Boundary")
    print(no_claim_boundary(args.tranche))
    print()
    print("## Member Discussion Rows")
    print(
        "meeting_id\tslice_id\tmember_id\tstance\texact_claim\treview_gate\t"
        "evidence_path\trisk\tdecision_boundary\tdecision_status\tnext_gate\tobserved_at_utc"
    )
    for member in (*ADVISORY_MEMBERS, *BLOCKING_MEMBERS):
        stance = "block_until_done" if member in BLOCKING_MEMBERS else "approve"
        print(
            "\t".join(
                (
                    meeting,
                    args.slice_id,
                    member,
                    stance,
                    f"{member} scaffold review for {args.tranche}: {no_claim_boundary(args.tranche)}",
                    "claim_gate" if member in {"rose", "fisher"} else "scope_gate",
                    args.evidence,
                    "manual wiring drift or claim inflation",
                    "no status movement without reviewed evidence",
                    "draft",
                    args.next_gate,
                    args.observed_at,
                )
            )
        )
    print()
    print("## Wiring Checklist")
    for item in (
        "sidecar TSV fields and exact row ids",
        "Mission Control parse, KPI, render table, and note",
        "validator path, schema, row contract, queue expectation, and member board",
        "run tools/qseries_v1_release_ledger.py --write when support-cell v1 roles can change",
        "focused conversion-contract test",
        "dashboard README, completion map, check-log, after-task report",
        "py_compile, node --check, validate-mission-control, focused R test, invariant scan, diff --check",
    ):
        print(f"- {item}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

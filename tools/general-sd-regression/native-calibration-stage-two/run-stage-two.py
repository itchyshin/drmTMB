#!/usr/bin/env python3
"""Run only externally sealed, pre-prepared stage-two batches."""
import argparse
import json
from pathlib import Path
from stage_two import run_batches


def main():
    p = argparse.ArgumentParser()
    p.add_argument("prepared_root", type=Path)
    p.add_argument("--external-seals", required=True, type=Path)
    p.add_argument("--external-seals-sha256", required=True)
    p.add_argument("--library", required=True, type=Path)
    p.add_argument("--outer-timeout", type=float, default=10500)
    a = p.parse_args()
    run_batches(a.prepared_root.resolve(strict=True), a.external_seals.resolve(strict=True),
                a.external_seals_sha256,
                a.library.resolve(strict=True), a.outer_timeout)
    print("STAGE_TWO_BATCHES_TERMINAL; combine and inspect every attempt before decision")


if __name__ == "__main__":
    main()

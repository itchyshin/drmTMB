#!/usr/bin/env python3
"""Reconstruct a complete raw first-look view from the retained evidence archive."""
import argparse
import json
from pathlib import Path

from stage_two import reconstruct_first_look


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("summary_root", type=Path)
    parser.add_argument("raw_attempt_root", type=Path)
    parser.add_argument("archive", type=Path)
    parser.add_argument("original_seal", type=Path)
    parser.add_argument("--original-seal-sha256", required=True)
    parser.add_argument("--expected-archive-sha256", required=True,
                        help="independently retained SHA-256 for the raw-attempt archive")
    parser.add_argument("--expected-results", type=int, default=3000)
    parser.add_argument("output_root", type=Path)
    parser.add_argument("new_seal", type=Path)
    args = parser.parse_args()
    receipt = reconstruct_first_look(
        args.summary_root, args.raw_attempt_root, args.archive, args.original_seal,
        args.original_seal_sha256, args.output_root, args.new_seal,
        expected_archive_sha256=args.expected_archive_sha256,
        expected_results=args.expected_results)
    print(json.dumps(receipt, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Fail-closed verifier for the public Julia Gaussian-LSS bootstrap receipt.

Usage: check-julia-lss-bootstrap-receipt.py RECEIPT.json [--self-test]
Run from the drmTMB worktree.  The receipt intentionally does not retain the
masked bridge payload, so its response-include mask/order assertion is reported
as runtime-only rather than reconstructed here.
"""

import argparse
import copy
import hashlib
import json
import math
import sys
from pathlib import Path


def fail(message):
    raise ValueError(message)


def require(condition, message):
    if not condition:
        fail(message)


def sha256(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def number(value, label):
    require(isinstance(value, (int, float)) and not isinstance(value, bool),
            f"{label}: not numeric")
    require(math.isfinite(value), f"{label}: non-finite")
    return float(value)


def interval(value, label, parm, count, failed, tolerance):
    require(isinstance(value, dict), f"{label}: missing interval")
    require(value.get("parm") == parm, f"{label}: wrong parameter")
    require(value.get("method") == "bootstrap", f"{label}: wrong method")
    require(value.get("conf.status") == "bootstrap", f"{label}: wrong status")
    lo = number(value.get("lower"), f"{label}.lower")
    hi = number(value.get("upper"), f"{label}.upper")
    require(lo <= hi, f"{label}: reversed endpoints")
    require(value.get("bootstrap.n") == count, f"{label}: wrong used count")
    require(value.get("bootstrap.failed") == failed, f"{label}: wrong failed count")
    for key in ("julia.threads", "julia.blas_threads", "julia.workers"):
        require(value.get(key) == 1, f"{label}: {key} is not one")
    return lo, hi


def equal_endpoint(left, right, tolerance, label):
    require(max(abs(a - b) for a, b in zip(left, right)) <= tolerance,
            f"{label}: endpoint disagreement")


def check_manifest(receipt, current):
    before = receipt.get("source_before")
    after = receipt.get("source_after")
    require(isinstance(before, dict) and isinstance(after, dict), "missing source manifests")
    require(len(before) == 143 and len(after) == 143, "expected exactly 143 source hashes")
    require(before == after, "before/after source manifests differ")
    require(receipt.get("source_unchanged") is True, "receipt does not mark source unchanged")
    for text_path, expected in before.items():
        require(isinstance(expected, str) and len(expected) == 64, f"bad source hash for {text_path}")
        if current:
            path = Path(text_path)
            require(path.is_file(), f"current source missing: {path}")
            require(sha256(path) == expected, f"current source hash mismatch: {path}")


def check_order(result):
    data = result.get("data")
    payload = result.get("payload")
    tree = result.get("tree")
    require(isinstance(data, list) and isinstance(payload, dict) and isinstance(tree, dict),
            "missing data, payload, or tree")
    require(all(isinstance(row, dict) for row in data), "input data rows are not objects")
    species = [row.get("species") for row in data]
    tip_label = tree.get("tip_label")
    payload_data = payload.get("data")
    row_order = payload.get("row_order")
    require(isinstance(species, list) and isinstance(tip_label, list), "invalid species/tip labels")
    require(isinstance(payload_data, list) and all(isinstance(row, dict) for row in payload_data) and
            isinstance(row_order, list), "invalid payload order")
    n = len(species)
    require(n == 128, "main input row count is not 128")
    require(len(tip_label) == 32, "main tree does not have 32 tips")
    require(len(row_order) == n, "row_order length mismatch")
    require(all(isinstance(i, int) and not isinstance(i, bool) for i in row_order),
            "row_order is not integer")
    require(sorted(row_order) == list(range(1, n + 1)), "row_order is not a permutation")
    lookup = {label: i for i, label in enumerate(tip_label)}
    require(len(lookup) == len(tip_label), "duplicate tree tip label")
    require(all(value in lookup for value in species), "input has an unknown tree tip")
    expected_zero = sorted(range(n), key=lambda i: lookup[species[i]])
    expected_one = [i + 1 for i in expected_zero]
    require(species != [species[i] for i in expected_zero],
            "main input is already tree-tip ordered, not genuinely shuffled")
    require(row_order == expected_one, "row_order is not tree-tip order for input")
    for key in ("y", "x", "z", "species"):
        require(all(key in row for row in data) and all(key in row for row in payload_data),
                f"missing {key} data")
        require(len(payload_data) == n, f"{key} length mismatch")
        expected = [data[i][key] for i in expected_zero]
        actual = [row[key] for row in payload_data]
        require(actual == expected, f"payload {key} does not follow row_order")


def check_main(receipt, current=True):
    require(receipt.get("status") == "PASS", "receipt status is not PASS")
    require(isinstance(receipt.get("elapsed"), (int, float)) and receipt["elapsed"] < 180,
            "elapsed time is missing or exceeded watchdog")
    root = Path.cwd()
    runner = root / "tools" / "run-julia-lss-bootstrap-public.R"
    require(runner.is_file(), "runner is missing from current worktree")
    require(receipt.get("runner_sha256") == sha256(runner), "runner hash mismatch")
    check_manifest(receipt, current)
    result = receipt.get("result")
    require(isinstance(result, dict) and result.get("status") == "PASS", "result status is not PASS")
    fixed_checks = result.get("fixed_checks")
    require(isinstance(fixed_checks, dict) and fixed_checks.get("ordinary_batch") is True,
            "ordinary R batch contract was not asserted")
    require(fixed_checks.get("input_shuffled") is True, "receipt does not assert shuffled input")
    tolerance = number(result.get("tolerance"), "tolerance")
    require(0 < tolerance <= 1e-10, "unexpected endpoint tolerance")
    check_order(result)

    bridge = result.get("bridge")
    direct = result.get("direct")
    require(isinstance(bridge, dict) and isinstance(direct, dict), "missing main bridge/direct result")
    require(bridge.get("requested_REML") is True and bridge.get("effective_REML") is True,
            "main bridge did not retain REML")
    require(bridge.get("estimator") == "REML", "main bridge estimator is not REML")
    require(bridge.get("nobs") == 128 and direct.get("fit_nobs") == 128, "main nobs mismatch")
    require(direct.get("fit_method") == "REML" and direct.get("manual_refit_method") == "REML",
            "direct fit/refit did not retain REML")
    require(direct.get("fit_converged") is True and direct.get("manual_refit_converged") is True,
            "direct fit/refit did not converge")
    require(direct.get("attempted") == 6 and direct.get("used") == 6 and direct.get("failed") == 0,
            "main direct bootstrap accounting mismatch")
    require(direct.get("threaded") is False and direct.get("julia_threads") == 1 and
            direct.get("blas_threads") == 1 and direct.get("worker_threads") == 1,
            "main direct resource contract mismatch")
    mu_public = interval(bridge.get("interval"), "main mu", "fixef:mu:x", 6, 0, tolerance)
    mu_direct = (number(direct.get("lower"), "direct mu.lower"),
                 number(direct.get("upper"), "direct mu.upper"))
    equal_endpoint(mu_public, mu_direct, tolerance, "main mu")

    sd = result.get("sd_bootstrap")
    require(isinstance(sd, dict) and sd.get("status") == "completed", "sd target did not complete")
    sd_public = interval(sd.get("interval"), "main sd", "fixef:sd_phylo:z", 6, 0, tolerance)
    sd_direct = (number(direct.get("sd_lower"), "direct sd.lower"),
                 number(direct.get("sd_upper"), "direct sd.upper"))
    equal_endpoint(sd_public, sd_direct, tolerance, "main sd")

    missing = result.get("missing_include")
    require(isinstance(missing, dict) and missing.get("status") == "completed", "masked probe failed")
    require(missing.get("nobs") == 124 and missing.get("expected_nobs") == 124,
            "masked probe nobs mismatch")
    require(missing.get("requested_REML") is True and missing.get("effective_REML") is True,
            "masked probe did not retain REML")
    missing_direct = missing.get("direct")
    require(isinstance(missing_direct, dict) and missing_direct.get("fit_nobs") == 124,
            "masked direct nobs mismatch")
    require(missing_direct.get("attempted") == 4 and missing_direct.get("used") == 4 and
            missing_direct.get("failed") == 0, "masked direct accounting mismatch")
    require(missing_direct.get("fit_method") == "REML" and
            missing_direct.get("manual_refit_method") == "REML", "masked direct did not retain REML")
    require(missing_direct.get("fit_converged") is True and
            missing_direct.get("manual_refit_converged") is True, "masked direct fit/refit did not converge")
    require(missing_direct.get("threaded") is False and missing_direct.get("julia_threads") == 1 and
            missing_direct.get("blas_threads") == 1 and missing_direct.get("worker_threads") == 1,
            "masked direct resource contract mismatch")
    missing_checks = missing.get("checks")
    require(isinstance(missing_checks, dict) and missing_checks.get("mask") is True and
            missing_checks.get("row_order") is True,
            "masked payload runtime mask/order checks were not recorded")
    masked_public = interval(missing.get("interval"), "masked mu", "fixef:mu:x", 4, 0, tolerance)
    masked_direct_interval = (number(missing_direct.get("lower"), "masked direct.lower"),
                               number(missing_direct.get("upper"), "masked direct.upper"))
    equal_endpoint(masked_public, masked_direct_interval, tolerance, "masked mu")
    return "PASS: endpoints/counts/nobs/tree order/143 source hashes verified; masked payload mask/order runtime-only"


def self_test(receipt):
    cases = []
    bad = copy.deepcopy(receipt)
    bad["result"]["bridge"]["interval"]["lower"] += 0.01
    cases.append(("endpoint", bad, False))
    bad = copy.deepcopy(receipt)
    bad["result"]["direct"]["used"] = 5
    cases.append(("count", bad, False))
    bad = copy.deepcopy(receipt)
    bad["result"]["payload"]["row_order"][0], bad["result"]["payload"]["row_order"][1] = \
        bad["result"]["payload"]["row_order"][1], bad["result"]["payload"]["row_order"][0]
    cases.append(("permutation", bad, False))
    bad = copy.deepcopy(receipt)
    bad["result"]["fixed_checks"]["ordinary_batch"] = False
    cases.append(("ordinary_batch", bad, False))
    bad = copy.deepcopy(receipt)
    bad["result"]["missing_include"]["direct"]["fit_method"] = "ML"
    cases.append(("masked_reml", bad, False))
    bad = copy.deepcopy(receipt)
    first = next(iter(bad["source_before"]))
    bad["source_before"][first] = "0" * 64
    bad["source_after"][first] = "0" * 64
    cases.append(("current_source_hash", bad, True))
    for label, damaged, current in cases:
        try:
            check_main(damaged, current=current)
        except ValueError:
            continue
        fail(f"self-test damage was accepted: {label}")
    return f"SELFTEST PASS: {len(cases)} damaging mutations rejected"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("receipt", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        with args.receipt.open(encoding="utf-8") as stream:
            receipt = json.load(stream)
        print(check_main(receipt, current=True))
        if args.self_test:
            print(self_test(receipt))
    except (OSError, ValueError, TypeError, json.JSONDecodeError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()

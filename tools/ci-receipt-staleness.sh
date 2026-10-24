#!/usr/bin/env bash
# Detect -- never regenerate -- stale Julia-parity receipts (issue #1150).
#
# WHAT THIS GUARDS
# ----------------
# Two whole-file receipts tie committed parity numbers to the source that
# produced them:
#
#   1. lss-tip-identity  docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json
#      Records a SHA-256 for EVERY file under R/ plus the runner
#      tools/run-julia-phylo-labels-public.R. Verified by
#      tools/check-julia-phylo-labels-receipt.R, whose --current mode compares
#      those hashes against the checkout.
#   2. C17 model-15      docs/dev-log/dashboard/capability-ledger/
#                        2026-08-08-c17c2-c14-final-source-compatibility.tsv
#      Records git blobs of R/drmTMB.R, R/methods.R, src/drmTMB.cpp and the
#      runner. Verified by capability_ledger.check_c14_receipt_equivalence().
#
# Until this script existed the tip-identity staleness check ran in no
# workflow, so a PR that edits R/ and does not regenerate the receipt merged
# green with the receipt quietly meaning nothing. Measured 2026-09-04 on
# origin/main ad8fc6524: the lss-tip-identity receipt was already stale by
# three merged R/-touching commits (037cc1991, 52b1dba8c, 94425965f) and
# nothing had said so. (The C17 blob check WAS already reached through
# `capability_ledger.py --check`; it is repeated here so one script answers
# "are the receipts fresh?" and so a stale C17 receipt is named as such.)
#
# WHY THE R/ COMPARISON IS RE-DONE HERE IN PYTHON, NOT VIA `--current`
# --------------------------------------------------------------------
# The receipt manifests record DRM.jl sources under the ABSOLUTE path of the
# scratch clone the runner used (e.g. /private/tmp/.../drmjl-objat/src/*.jl).
# check-julia-phylo-labels-receipt.R --current requires every recorded path to
# exist, so on a CI runner (or any other machine) it fails with "recorded
# source path is absent now" before it ever reaches a stale R/ hash -- it can
# never go green there, stale or not. A hard-fail step that cannot pass is not
# a guard. So this script compares exactly what CI CAN verify -- the R/ files
# and the runner, hashed the same way (digest::digest(file=, algo="sha256")
# equals hashlib.sha256 of the bytes; checked 2026-09-04 on R/julia-bridge.R)
# -- and verifies the DRM.jl-side entries only when DRM_JL_PATH names a
# checkout to map them onto. It says which of the two it did.
#
# The checker's own structural validation (no --current: field contract,
# numerical self-consistency, label/permutation checks) is still run, so the
# receipt's INTERNAL claims are checked by the authoritative implementation.
#
# WHICH R/ CHANGES FAIL (narrowed 2026-10-24, owner decision)
# ----------------------------------------------------------
# The receipt records one hash per R/ file, but the runner only EXERCISES some of
# them. Failing on every differing hash turned main red on any roxygen edit in an
# unrelated file. The guard now fails on a differing, absent or unrecorded R/ file
# only when that file is on the runner's static call path, computed from the code
# by tools/receipt-exercised-files.R (rule and its blind spot are documented
# there). A differing R/ file that is NOT on that path is printed as a NOTE and
# does not fail. Deliberately unchanged: the receipt JSON, every numeric
# tolerance, the runner-hash check, the structural validation, the C17 check, and
# the rule that a recorded R/ file that is now ABSENT fails (it cannot be
# classified once gone). The path rule over-approximates, so it can fail on a file
# the run never executes; it is designed not to pass a file the run does execute.
# A NOTE means "the receipt's sources moved but not where the runner looks"; the
# next regeneration refreshes the recorded hashes anyway.
#
# WHAT IS DELIBERATELY NOT GATED
# ------------------------------
# docs/dev-log/evidence/julia-r-parity/phylo-labels/public-00{1,2}.json are
# dated 2026-08-30 receipts of the same shape. They are historical evidence
# for that day's source (both already differ at R/check.R), no design or
# ledger row cites them as a CURRENT claim, and forcing their regeneration on
# every R/ edit would be churn without a claim behind it. Add a receipt to
# RECEIPTS below only when a document cites it as evidence about the current
# source.
#
# EXIT STATUS: 0 when every gated receipt matches the checkout, 1 when any is
# stale (the stale file is named), 2 on a usage/environment error.
# This script never regenerates anything: regeneration needs a live Julia and
# the pinned DRM.jl clone (tools/run-julia-phylo-labels-public.R for the
# tip-identity receipt; tools/recertify-c17.py for C17).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RECEIPTS=(
  docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json
)
RUNNER=tools/run-julia-phylo-labels-public.R
CHECKER=tools/check-julia-phylo-labels-receipt.R

for f in "${RECEIPTS[@]}" "$RUNNER" "$CHECKER" tools/capability_ledger.py tools/receipt-exercised-files.R; do
  if [ ! -f "$f" ]; then
    echo "ci-receipt-staleness: missing $f" >&2
    exit 2
  fi
done

# The R/ files the runner can exercise (see "WHICH R/ CHANGES FAIL" above). Fail
# closed: if the path cannot be computed, or looks implausible, this is an
# environment error (exit 2), never a silent pass.
EXERCISED="$(Rscript --no-init-file tools/receipt-exercised-files.R "$RUNNER" R)" || {
  echo "ci-receipt-staleness: tools/receipt-exercised-files.R failed" >&2
  exit 2
}
if ! printf '%s\n' "$EXERCISED" | grep -qx 'R/drmTMB.R'; then
  echo "ci-receipt-staleness: exercised-file list does not contain R/drmTMB.R; refusing to trust it" >&2
  exit 2
fi
export EXERCISED

status=0

# --- 1. lss-tip-identity: R/ hashes + runner hash against this checkout -----
python3 - "$RUNNER" "${RECEIPTS[@]}" <<'PY' || status=1
import glob, hashlib, json, os, sys

runner, receipts = sys.argv[1], sys.argv[2:]
drm_jl = os.environ.get("DRM_JL_PATH", "")
exercised = set(os.environ["EXERCISED"].split())
stale = 0

def sha256(path):
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()

for receipt in receipts:
    with open(receipt, encoding="utf-8") as fh:
        r = json.load(fh)
    if r.get("status") != "PASS" or r.get("source_unchanged") is not True:
        print(f"STALE  {receipt}: receipt status is not a clean PASS")
        stale += 1
        continue
    before, after = r["source_before"], r["source_after"]
    if before != after:
        print(f"STALE  {receipt}: source_before and source_after disagree")
        stale += 1
        continue
    r_ok = r_bad = r_note = jl_ok = jl_bad = jl_unverified = 0
    for path, recorded in before.items():
        if path.startswith("R/"):
            if not os.path.isfile(path):
                print(f"STALE  {receipt}: recorded source path is absent now: {path}")
                r_bad += 1
            elif sha256(path) != recorded:
                if path in exercised:
                    print(f"STALE  {receipt}: current source hash differs from receipt: {path} (on the runner's call path)")
                    r_bad += 1
                else:
                    print(f"NOTE   {receipt}: source hash differs from receipt, not on the runner's call path: {path}")
                    r_note += 1
            else:
                r_ok += 1
        else:
            # DRM.jl-side entry, recorded under the runner's scratch-clone
            # absolute path. Only checkable when a checkout is named.
            i = path.find("/src/")
            target = os.path.join(drm_jl, "src", path[i + 5:]) if (drm_jl and i >= 0) else ""
            if not target:
                jl_unverified += 1
            elif not os.path.isfile(target) or sha256(target) != recorded:
                print(f"STALE  {receipt}: DRM.jl source differs from receipt: {target}")
                jl_bad += 1
            else:
                jl_ok += 1
    # A file added under R/ since the receipt was written is in no manifest
    # entry, so the loop above cannot see it; the runner globs R/*.R, so an
    # unrecorded file means the receipt predates it. It matters only if the
    # runner can reach it.
    unrecorded = [p for p in sorted(glob.glob("R/*.R")) if p not in before]
    unrecorded_bad = 0
    for path in unrecorded:
        if path in exercised:
            print(f"STALE  {receipt}: R/ file not recorded in receipt (added since), on the runner's call path: {path}")
            unrecorded_bad += 1
        else:
            print(f"NOTE   {receipt}: R/ file not recorded in receipt (added since), not on the runner's call path: {path}")
    runner_ok = sha256(runner) == r["runner_sha256"]
    if not runner_ok:
        print(f"STALE  {receipt}: current runner hash differs from receipt: {runner}")
    on_path_bad = r_bad
    r_bad += unrecorded_bad + (0 if runner_ok else 1)
    stale += r_bad + jl_bad
    jl_note = (
        f"{jl_ok} of {jl_ok + jl_bad} DRM.jl-side entries match DRM_JL_PATH={drm_jl}" if drm_jl
        else f"{jl_unverified} DRM.jl-side entries NOT verified (DRM_JL_PATH unset)"
    )
    verdict = "STALE " if (r_bad + jl_bad) else "FRESH "
    print(
        f"{verdict} {receipt}: {r_ok} recorded R/ files match, {on_path_bad} differ or absent, "
        f"{unrecorded_bad} unrecorded, all on the call path; {r_note + len(unrecorded) - unrecorded_bad} "
        f"informational (changed or unrecorded, off the call path); runner {'matches' if runner_ok else 'DIFFERS'}; "
        f"{len(exercised)} R/ files on the call path; {jl_note}"
    )
sys.exit(1 if stale else 0)
PY

# --- 2. lss-tip-identity: the checker's own structural validation ------------
# (no --current: the R/ comparison above is CI's substitute for it; see header)
for receipt in "${RECEIPTS[@]}"; do
  if ! Rscript --no-init-file "$CHECKER" "$receipt"; then
    echo "STALE  $receipt: structural validation failed ($CHECKER)"
    status=1
  fi
done

# --- 3. C17 model-15: whole-file blobs + fingerprint ---------------------------
if ! python3 -c 'import sys; sys.path.insert(0, "tools"); import capability_ledger as c; c.check_c14_receipt_equivalence()'; then
  echo "STALE  C17 model-15 receipt: capability_ledger.check_c14_receipt_equivalence() failed"
  status=1
fi

if [ "$status" -ne 0 ]; then
  echo "ci-receipt-staleness: at least one receipt is stale relative to this checkout." >&2
  echo "This script never regenerates. Regenerate with a live Julia + the pinned DRM.jl clone" >&2
  echo "(tools/run-julia-phylo-labels-public.R; tools/recertify-c17.py), LAST in the branch." >&2
fi
exit "$status"

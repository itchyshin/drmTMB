# Ledger gate receipt — Stage A

**Date:** 2026-08-09 · **Lane:** Claude task 1, Stage A · **Source:** `origin/main@ac363cadb`
**Tool:** `~/shinichi-brain/tools/cran_release_gate.py` (D-49 executable fail-closed ledger)

## 1. The tool is healthy

```
$ python3 ~/shinichi-brain/tools/cran_release_gate.py --selftest
PASS: source-clean does not require later-rung evidence
PASS: negative control failed closed: unlicensed-data
PASS: negative control failed closed: predecessor-hash
PASS: negative control failed closed: forbidden-tarball-entry
PASS: negative control failed closed: incoming-preflight-missing
PASS: negative control failed closed: missing-timing
PASS: negative control failed closed: unconfirmed-upload
PASS: negative control failed closed: public-page-404
PASS: negative control failed closed: compiled-gate-omitted
PASS: negative control failed closed: fictional-live-url
PASS: negative control failed closed: reachable-non-cran-live-url
PASS: negative control failed closed: panel-not-ready
PASS: negative control failed closed: invalid-release-type
PASS: negative control failed closed: large-vignette-budget-omitted
PASS: CRAN release gate selftest
```

**14/14 planted negative controls fail closed.** Any result below is the tool working, not
the tool broken.

## 2. Current main's Stage A ledger — NOT READY

```
$ python3 ~/shinichi-brain/tools/cran_release_gate.py \
    docs/dev-log/release-audits/2026-08-09-07-cran-release-ledger.json
NOT READY
- evidence.current_cran_policy rationale must start NOT_APPLICABLE:
- evidence.rendered_site rationale must start NOT_APPLICABLE:
                                                          (exit 1)
```

**This failure is the deliverable, not a defect.** Two things it establishes:

1. **Current `main` is below `source-clean`.** Two of the four `source-clean` evidence rows
   — `current_cran_policy` and `rendered_site` — genuinely do not exist for this arc. The
   gate names them precisely, so the output *is* the Stage B checklist.
2. **The gate refuses "we'll do it later" as evidence.** I wrote those rows as
   `{"kind": "rationale", "value": "ABSENT AND DELIBERATE: …"}` with a real justification.
   The gate rejected both: a `rationale` may only excuse a row that is genuinely
   **`NOT_APPLICABLE:`**, never one that is merely *outstanding*. A deferred obligation
   cannot be argued into a discharged one. That is the correct and strict reading, and it
   is worth recording because the temptation in Stage B will be to soften exactly these two
   rows.

**Do not edit the ledger to make it pass.** It passes when the evidence exists.

## 3. The contrast that motivates this whole arc

Run on the same machine, the same minute:

| Ledger | `source_commit` | Result |
| --- | --- | --- |
| `2026-08-07-07-cran-release-ledger.json` (predecessor, on `main`) | `ad475cc39` | **`READY FOR CLAIMED RUNG`** (exit 0) |
| `2026-08-09-07-cran-release-ledger.json` (this arc) | `ac363cadb` | **`NOT READY`** (exit 1) |

The **older** source commit returns green; the **current** one returns red. That inversion
is not a bug in either ledger — the predecessor's `tarball-clean` claim is genuinely true
for the artifact it names, and I re-verified that artifact today:

| Property | Recorded | Measured 2026-08-09 |
| --- | --- | --- |
| SHA-256 | `2e5234bd…c5ea` | `2e5234bd…c5ea` ✓ |
| Size | 9,831,204 | 9,831,204 ✓ |
| On disk | — | present at `/private/tmp/drmTMB-07-reader-boundaries-tarball/` ✓ |

So a reader can find, today, a green ledger plus a present, hash-matching tarball, and
reasonably conclude the package is `tarball-clean`. It is — for a source commit **15
build-included files behind current `main`**.

**The gate cannot detect this**, because it validates *artifact against claim*, and that
pairing is sound. It has no control for *"was this artifact built from current `main`?"*
Mitigation is documentary:
[`STALE-EVIDENCE-QUARANTINE.md`](../release/0.7.0-cran-gate/STALE-EVIDENCE-QUARANTINE.md),
written into the evidence directory itself.

## 4. Recommended tool improvement — flagged, not implemented

Add an optional `source_commit_is_current` control that fails closed when a ledger's
`source_commit` is not equal to the named release branch tip. A `git merge-base
--is-ancestor` plus a tip comparison turns today's misleading green into a red.

This belongs to `~/shinichi-brain/tools/`, not to this repository, and it is Shinichi's
call. Flagged here because this arc is the concrete case that demonstrates the gap, and
D-49's whole premise is that partial-green evidence must be **mechanically** prevented from
becoming a whole-release claim — not merely guarded by careful reading.

## 5. What Stage B must supply to clear this receipt

| Row | What clears it |
| --- | --- |
| `current_cran_policy` | A dated read of current CRAN Repository Policy + submission checklist, each threshold labelled *current policy* / *observed incoming* / *local margin*. **First step of Stage B**, before the freeze. |
| `rendered_site` | `pkgdown::check_pkgdown()` + a real site build + a rendered-page audit; must also settle the `man/figures/logo.*` duplicate. |
| then `tarball-clean` | `local_as_cran`, `incoming_feasibility`, `installed_package`, `timing` — all on the one frozen candidate. |
| `size_and_vignette_budget` | Measured Windows vignette total (37 vignettes vs the ~10-min threshold) + installed size, on the candidate. |
| `compiled_diagnostics` | Re-run sanitizers on the candidate hash; predecessor R-hub results do not transfer. |
| `external_service_behaviour` | Demonstrate the `JuliaCall`-absent path degrades cleanly. |
| `artifact.*` | Path, SHA-256, size, inventory, forbidden-path scan — from one immutable tarball built at the merged post-separation SHA. |

**Verdict entering Gate H: NOT READY. Highest rung proven for current `main`: none.**

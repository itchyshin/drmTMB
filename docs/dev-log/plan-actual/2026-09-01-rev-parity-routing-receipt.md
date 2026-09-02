# Routing receipt — drmTMB reverse-parity lane, Claude, 2026-09-01

Input for Melissa's plan-vs-actual reconciliation (ultra-plan Phase 4.5). Deviations are
tagged **adaptive** (justified, recorded) or **drift** (unjustified). Cosmetic differences
are not drift and are omitted.

## Planned vs actual routing

| slice | planned | actual | model | deviation |
|---|---|---|---|---|
| RECON ×5 | Explore, Haiku/Sonnet | Explore ×5 | Sonnet | **adaptive** — Haiku was planned for the mechanical half; Sonnet used throughout because each sweep required judgment (reuse-vs-rebuild calls), not just enumeration. Cost: the cheap tier was under-used. |
| A0 design 35 | documentation_writer | **coordinator (me)** | session | **adaptive** — it encodes design decisions I had reasoned through; delegating would have cost a full context transfer for a docs edit. |
| D1 parity board | documentation_writer, Haiku | **coordinator (me)** | session | **drift, self-inflicted** — I dispatched to an agent type with no Bash, so it could not run git. Recovered by doing it myself. Root cause: routed by tier, not by TOOLS. |
| D2 loud skip | reproducibility_engineer, Sonnet | as planned | Sonnet | none |
| D3 error-not-skip | simulation_tester, Sonnet | as planned | Sonnet | none |
| D4 provenance | tmb_engineer, Sonnet | as planned | Sonnet | none |
| A1 red tests | simulation_tester, Sonnet | as planned | Sonnet | none |
| A2 start impl | tmb_engineer, Sonnet-high | as planned | Sonnet | none |
| A3 objective_at | tmb_engineer, Sonnet-high | as planned | Sonnet | none |
| A4 bridge spike | tmb_engineer, Sonnet-high | **NOT RUN — HELD** | — | **adaptive** — PR #1112 rewrites 216 lines of `R/julia-bridge.R`; D-87 says overlap is the owner's call. Its core question was answered from source instead, at no agent cost. |
| A5 #575 receipt | simulation_tester, Sonnet | **NOT RUN — HELD** | — | **adaptive** — depends on A4. |
| B1 stored gradient | tmb_engineer, Sonnet-high | as planned | Sonnet | none — and it was NOT in the original rev-1 plan; added once A2 freed `R/drmTMB.R`. |
| B2 conditioning | tmb_engineer, Sonnet-high | as planned | Sonnet | none |
| B3 control contract | documentation_writer | **NOT RUN** | — | **adaptive** — conceptually overlaps PR #1112's own control work. Deferred rather than duplicated. |
| C1 naming spec | formula_reviewer, Sonnet | **general-purpose**, Sonnet | Sonnet | **adaptive** — `formula_reviewer` has no Write/Bash; re-routed by TOOLS after the D1 lesson. |
| C2–C4 | — | **NOT RUN by design** | — | none — ARC C stops after the spec pending the authority decision. |
| N4 verify | Rose, **Opus** | as planned | **Opus** | none — the single budgeted ceiling child. |
| Melissa reconcile | Sonnet | pending | — | — |

## Fan-out budget

Planned ≤6 children per checkpoint, ≤1 ceiling. **Actual: 11 children, 1 ceiling.** The user
issued `/goal` twice and then "Keep going", each a checkpoint authorising continuation; the
overage is **adaptive but real**, and is recorded here rather than normalised. Ceiling
discipline held exactly: one Opus child, spent on adversarial verification.

## Safety gates

- **DRM.jl fence**: pinned at `main@f4778964`, re-checked after every step, `FENCE HELD` every time.
- **Forbidden paths**: all 14 branches diffed against `origin/main` for
  `inst/extdata/julia-capabilities.tsv` and `.github/workflows/` — **0 changes on every branch**.
- **No merge, no push, no version bump, no release action.** D-164 untouched.
- **D-139**: breached once (three parallel full suites ordered without an estimate), corrected
  mid-flight, and every subsequent long run carried a stated estimate.

## Honest negatives — things that did NOT go to plan

1. **D-139 breach**, above. The correction is now binding in the ledger.
2. **Four of my own gates were wrong** and were repaired only because I ran them: `ifne` absent;
   a whole-repo grep that failed on an after-task note quoting its own evidence; a "DRM.jl must
   be clean" fence that would have failed on the foreign lane's file; and an A1 gate counting
   expectations where blocks were the meaningful unit.
3. **I claimed `--as-cran` subsumed the full-suite gate. It did not** — `NOT_CRAN=false` ran the
   suite in 43 seconds instead of ~20 minutes. Caught by reading the timing, not the verdict.
4. **Two ABANDONs**, both evidenced rather than argued: `A2-G4` (map-preservation guard cannot
   fire) and the naming spec's `engine="julia"` rows (no label-map producer exists on either side).

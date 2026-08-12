# G1b verdict — the cloglog failure was the optimizer, not the estimator

Graded against `PREREGISTRATION-G1b.md`, frozen at `0c69cd586` before any replicate, on a **fresh
seed stream** (prefix `20260812`). 88 cells × 500 replicates × 2 engines = **88,000 fits**, Totoro,
100 cores, **6 min 45 s** against a declared ~11 min.

## The result

| condition | completion | min cell | completed fits | **non-finite among them** | verdict |
|---|---|---|---|---|---|
| logit (control) | 1.000000 | 1.000 | 11,000 | **0** | **PASS** |
| probit | 1.000000 | 1.000 | 11,000 | **0** | **PASS** |
| cloglog-standard | 0.997545 | 0.974 | 10,973 | **0** | **PASS** |
| cloglog-mirrored | 0.999909 | 0.998 | 10,999 | **0** | **PASS** |

**88 of 88 cells evaluable** — no cell fell below the 0.90 completion guard, so the guard never had
to withhold a claim. **Finiteness holds in 88 of 88.**

## The one number this run existed to produce

> **0 of 43,972 completed MSPL fits returned a non-finite estimate.**

That is the only quantity that would be evidence *against* MSPL finiteness, and it is zero across
every link, both cloglog orientations, both `q`, every `G`, and the adversarial corner.

## What this settles, and what it does not

**Settles:** G1's cloglog-standard FAIL was an **optimizer artefact**. G1 recorded 33 losses that were
33 errors and 0 non-finite estimates; G1b, on data whose outcome was not known when the rule was
written, reproduces exactly that pattern — cloglog-standard completes 99.75% of the time (worst cell
97.4%) and is finite in **100%** of the fits that complete.

**Does not settle, and is not claimed:** G1b does not overturn G1, per its own §6. G1's verdict was
correct under the rule frozen for it, and that rule was deliberately one-sided — able to produce a
false FAIL but never a false PASS. The honest summary of the pair is:

> Under the composite endpoint, cloglog-standard missed the threshold in 2 of 22 cells. Under an
> endpoint that separates completion from finiteness, on a fresh seed stream, **no non-finite cloglog
> estimate was observed at all**, and the shortfall is entirely non-completion of the optimizer.

## Why the completion shortfall is not hiding anything

Three independent facts, each recorded before this run or measured in it:

1. **The guard never bound.** Every cell exceeded 0.90 completion, the worst at 0.974. The finiteness
   figures are not conditioned on a small or selected subset — they rest on ≥ 487 of 500 replicates
   in every cell.
2. **Plain ML fails on the same data.** In G1, ML errored on **33 of the 33** datasets where MSPL did.
   There is no dataset on which ML succeeded and MSPL did not; MSPL is never strictly worse.
3. **The residue is an identifiability wall, not a tuning failure.** Every G1 loss was `q2` with 0–3
   events in 120 — a 2×2 random-effect covariance asked of essentially no events. `q1` fits the same
   data without complaint, and `multi_start = 5` (already user-accessible via `drm_control`) rescues
   only about a quarter.

## The intercept start fix is in this build

G1b measures drmTMB with `425719c37`, which starts the MSPL intercept at the link of the observed
event rate rather than at 0. At `β = 0` the implied rate is the link at `η = 0` — 0.5 for logit and
probit but `1 − exp(−1) = 0.632` for cloglog — so a design with one event in 120 previously began
~4.8 log units from its own intercept.

Its effect is visible but modest, and it is **not** what produces this verdict: measured at full
replication on the four affected G1 cells, failures fell 33 → 28, and cells 57 and 60 still missed
G1's composite threshold. What produces this verdict is the endpoint separation, not the fix.
Completion here (0.9975) is therefore **not** directly comparable to G1's raw rate, as §4.3 declared
in advance.

## Unchanged

Nothing here opens the MSPL guard, authorises shipping probit or cloglog, or touches `c_n`, intervals
or standard errors. `c_n = 2√(p/n)` remains a logit delta-method result — `ω(0)` is `1/4` for logit,
`2/π` for probit and `1/(e−1)` for cloglog — and that question is G2, still not run.

## Provenance

Prereg SHA `0c69cd586`, branch `claude/mspl-nonlogit-evidence`; drmTMB 0.7.0 built on Totoro into
`~/R/g1blib` from that tree; 384-core host, 100 workers, `OPENBLAS_NUM_THREADS=1`; finished
`2026-08-11T16:41Z`. Raw `data/g1b_raw.tsv.gz` (88,000 rows, 25 fields, uniform), per-cell
`G1b-cell-results.csv`, console `G1b-grading.log`, runner `g1b_runner.R`, scorer `analyse_g1b.R`.

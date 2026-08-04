# D-97's pooled 0.9368 has no committed evidence

**Verdict: the provenance recorded in D-97 is mis-stated.** This is not a drmTMB
code defect and nothing here changes package behaviour — but D-97 is the decision
that made **profile the default interval method**, and the number it rests on
cannot be reproduced from anything in this repository.

**Raised by:** the D-43 panel on the 2026-08-04 D-117 arc, which noticed that
D-97's stated provenance and the arc's own premise could not both be true.
**Correcting the decision record is the owner's call** — this file records the
evidence, it does not edit `DECISIONS.md`.

## The claim

`~/shinichi-brain/memory/DECISIONS.md:2756` (D-97, accepted 2026-07-28):

> Profile coverage **0.9368 [0.9323, 0.9411]** of a nominal 95% interval, across
> all **12 A1 cells** (**11,988 retained attempts, 11,988 finite profiles**).

## What is actually in the repository

**The real, committed, SHA-256-authenticated profile campaign is 3 cells, not 12.**
`docs/dev-log/simulation-artifacts/2026-07-26-a1-r999-bootstrap-diagnosis/` on
`codex/sd-bootstrap-r999-diagnosis`: `profile_vs_bootstrap.R`'s `GRID` is
`n_groups = c(10, 25, 50)` with `n_per = 10` and `sd_mu = 0.5` **held fixed** —
three cells, 1,000 attempts each, **3,000 total**, all valid.

Its per-cell profile coverage is **0.937 / 0.942 / 0.941**, which pools to
**2820/3000 = 0.9400 exactly** — *not* 0.9368. The companion ML-vs-REML report on
the same three cells gives identical ML-arm coverages, confirming both describe one
3,000-row dataset rather than a larger population.

**"12 A1 cells" correctly describes a different, bootstrap-only campaign.**
`2026-07-25-a1-marginal-bootstrap-coverage/a1_coverage.R` has
`expand.grid(n_groups = c(10,25,50), n_per = c(4,10), sd_mu = c(0.5,1.0))` = 12
cells — and, read end to end, its **only** interval call is
`method = "bootstrap"`. There is no profile branch, argument, or code path in it.
Its headline is **0.8714 [0.8653, 0.8774]**, n = 12,000 — which is D-97's *other*
cited number.

So the "12 cells" description belongs to the bootstrap campaign and appears to have
been carried across to the profile figure.

**"11,988" is arithmetically 12 × 999, and 999 is the bootstrap resample count.**
Every real committed A1 campaign retained **exactly 1,000 outer attempts per cell
with zero attrition** (`a1_coverage_summary.txt`: "rows with a non-finite interval:
0/72000"; `profile-vs-bootstrap-report.md`: 1000/1000 in all three rows). No real
campaign retained 999 per cell. `999` appears in the evidence only as `R = 999`,
the number of bootstrap resamples *inside* each attempt — a different quantity
entirely.

## Where the number does trace to

A single after-task report, `docs/dev-log/after-task/2026-07-26-profile-vs-bootstrap-r999.md`,
which exists **only under `~/shinichi-brain/`** and is absent from this repository
under every ref and every GitHub PR. It describes a run using a script called
`profile_coverage.R` — matching nothing in the repo — executed in
`/private/tmp/drmtmb-ho/...`, a temp directory that no longer exists. The report
itself records that the run bypassed the project's normal provenance protocol
("Totoro transfer was attempted but not used").

## Consequences

**1. The 2026-08-04 D-117 arc's premise survives.** Three of the four 10-group
cells genuinely had never been measured on the profile route: the committed profile
campaign varies only `n_groups`, holding `n_per = 10` and `sd_mu = 0.5` fixed. The
arc measured `n_per = 4` and `sd_mu = 1.0` for the first time.

**2. That arc benchmarked against a figure with no reproducible provenance.**
`VERDICT.md` §2.3 tested the worst cell against 0.9368 and found it detectably
below at z ≈ 2.49. Against the **real** committed comparator (0.9400, n = 3,000)
the gap is slightly **larger**: difference −0.026, combined SE 0.00987,
**z ≈ 2.63**. The direction and the conclusion are unchanged and mildly
strengthened; only the reference value moves.

**3. D-97's substantive conclusion is not overturned here.** Both the recorded
0.9368 and the reproducible 0.9400 are far above the marginal route's 0.8714, so
"profile beats marginal, adopt it as the default" survives either way. What is in
question is the *specific figure* and its stated basis, not the direction of the
decision.

**4. The 0.9368 figure should not be cited again until this is settled.** It
currently appears in `DECISIONS.md` D-97 and D-117 and in the 2026-08-04 arc's
documents.

## Suggested disposition (owner's call)

Either locate the 12-cell profile campaign — in which case the retained-attempt
arithmetic still needs explaining — or correct D-97's provenance line to cite the
committed 3-cell campaign and its actual pooled value of 0.9400, noting that the
"12 cells" description belongs to the bootstrap arm.

Also worth noting: this is a second instance of a load-bearing artifact living
outside the repository. The first is
`codex/sd-bootstrap-r999-diagnosis` (`4cc837a85`) itself, which holds the banked
2026-07-26 evidence and **is on no remote**.

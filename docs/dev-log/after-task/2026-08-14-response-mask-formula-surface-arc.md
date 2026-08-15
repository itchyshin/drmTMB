# After-task report — response-mask formula surface arc closeout

Role: Rose (systems auditor). This report closes the evidence arc that ran on
branch `codex/response-missing-formula-surface`
(worktree `/private/tmp/drmtmb-response-missing-formula-surface`) on
2026-08-14. I did not implement, fix, or re-run the ledger; I audited the
finished state, independently re-derived every headline number from the repo
itself, and re-ran a sample of the underlying tests live. Every number below
was reproduced by me on 2026-08-14 unless marked "as reported by the lane
(not independently reproduced)".

## Task goal

Close out and produce the durable record for a lane whose original brief
("close 15 OWED univariate-ML response-mask formula cells") was overtaken
mid-flight: on rehydration, the prior handover's claim "No technical blocker
for the 15 univariate cells" (verified quote,
`docs/dev-log/handover/2026-08-14-claude-handover-response-missing-formulas.md:146`)
proved false, and the 185 `formula_validated` cells it inherited proved
unmeasured against the live test suite. Shinichi reframed the arc:
**truthful ledger first, cells second.** My job is to verify that
reframing actually happened, verify the resulting tally against the repo,
flag anything the lane's own record contradicts, and write the after-task
report, the plan-vs-actual reconciliation, and the `AGENTS.md` pointer.

## Files created or changed

By me, in this session:

- `docs/dev-log/after-task/2026-08-14-response-mask-formula-surface-arc.md` (this file, created)
- `docs/dev-log/plan-actual/2026-08-14-response-mask-formula-surface.md` (created)
- `AGENTS.md` — only the "Latest — start here" pointer block, prior block preserved as "Prior"

I did not edit `docs/dev-log/check-log.md`, any file under `tests/`, `R/`,
`src/`, `tools/`, or `docs/dev-log/dashboard/capability-ledger/*.tsv`, per my
brief's constraints. The rest of this report audits changes made by other
agents earlier in the same session, visible in `git status`/`git diff` at the
time I read the tree:

```
.github/workflows/R-CMD-check.yaml
R/drmTMB.R
docs/design/149-missing-data-design.md
docs/design/248-zero-one-beta-structured-atom-q1-symbolic-alignment.md
docs/dev-log/check-log.md
docs/dev-log/dashboard/capability-ledger/response-mask-formulas.tsv
tests/testthat/helper-missing-response.R
tests/testthat/test-animal-relmat-gaussian.R
tests/testthat/test-missing-response-boundary.R
tests/testthat/test-phylo-interaction.R
tests/testthat/test-reml-binomial-coxreid.R
tests/testthat/test-spatial-gaussian.R
tests/testthat/test-zero-one-beta.R
tests/testthat/test-zi-nbinom2.R
tests/testthat/test-zi-poisson.R
tools/response_mask_formula_inventory.py
tools/tests/test_response_mask_formula_inventory.py
```
(17 files, `+2091/-305` per `git diff --stat`) plus 9 new untracked files
(`docs/dev-log/2026-08-14-response-mask-red-surface.md`, five
`scratchpad/audit-batch-*.md` files, three `scratchpad/2026-08-14-group*.R`
probe scripts).

## Checks run and exact outcomes (all reproduced by me, 2026-08-14)

```
$ awk -F'\t' 'NR>1{print $13}' docs/dev-log/dashboard/capability-ledger/response-mask-formulas.tsv | sort | uniq -c
   1 blocked_dense_known_V
  40 blocked_reml
   1 family_validated
 181 formula_validated
 110 needs_formula_evidence
 358 not_admitted

$ python3 -B tools/tests/test_response_mask_formula_inventory.py
Ran 5 tests in 0.032s
OK

$ python3 tools/capability_ledger.py --check
capability-ledger: OK (32 generated outputs)

$ python3 tools/response_mask_formula_inventory.py --check
response-mask formula inventory: OK

$ git diff --stat
 17 files changed, 2091 insertions(+), 305 deletions(-)
```

I also went beyond the brief's four commands and independently reproduced
the ledger's cell-level numeric claims by running R live against the
package (`pkgload::load_all(".", compile = FALSE)`), not by reading test
output someone else captured:

- `test-animal-relmat-gaussian.R`: `FAIL 2 | PASS 819` (both failures are
  mc-0317/mc-0318, correctly demoted).
- `test-spatial-gaussian.R`: `FAIL 2 | PASS 431`, at exactly the lines and
  magnitudes the ledger's `claim_boundary` text for mc-0107/mc-0108 states
  (`1.20 >= 0.25`, `0.88 >= 0.25` vs. the row's `1.199`/`0.882`).
- `test-missing-response-boundary.R`: `FAIL 2 | PASS 260`, both failures
  attributable to mc-0578 (coi random-slope: SD diff `0.45` vs. `0.25`
  bound, correlation `0.253` vs. `0.35` bound — matches the demote-list text
  to three significant figures).
- `test-phylo-interaction.R`: `FAIL 0 | PASS 266`.
- A hand-rolled rerun of the NB2 four-provider loop (phylo/spatial/animal/
  relmat) at the cell's own seeds gave `mu_x_err` = 0.029 / **0.486** /
  0.112 / 0.010 and `sigma_err` = 0.032 / **0.286** / 0.073 / **0.502**
  against bounds 0.20/0.18 — confirming spatial (mc-0411) and relmat
  (mc-0413) are the two genuine failures and phylo (mc-0410) and animal
  (mc-0412) are not, exactly matching which cells the ledger demoted and
  which it left `formula_validated`.
- A hand-rolled rerun of the bivariate animal-vs-relmat slope loop gave
  `rho_err` = 0.0343 (animal) and **0.2167** (relmat) against a 0.20
  bound — again exactly matching which of the two ambiguous provider
  iterations the ledger demoted (`rmf-biv-gaussian-relmat-mu12-q2-slope`)
  and which it left validated (`rmf-biv-gaussian-animal-mu12-q2-slope`).

Every one of these independent reruns landed on the same cell the ledger
names, at numbers matching the `claim_boundary` text. I did not find a case
where the ledger's disposition (promote/demote/narrow/refuse) disagreed with
what the code actually does.

### Row-level ledger diff (my own, not copied from check-log.md)

I diffed `response-mask-formulas.tsv` at the pre-session commit
(`63ee00c43`, "hand over ... to Claude") against the current working tree,
keyed by `formula_cell_id`, and independently tallied:

| Category | Count | Cell IDs |
|---|---|---|
| `formula_status` demotions (`formula_validated` → `needs_formula_evidence`) | **11** | mc-0317, mc-0318, mc-0411, mc-0413, mc-0421, mc-0578, mc-0593, mc-0594, `rmf-biv-gaussian-relmat-mu12-q2-slope`, plus the 1-row-→-2-row split of `rmf-biv-gaussian-spatial-mu12-q2-intercept` into `mc-0107` and `mc-0108` (both demoted) |
| Promotions (`needs_formula_evidence` → `formula_validated`) | **6** | mc-0321, mc-0595, mc-0641, mc-0653, mc-0662, mc-0667 |
| Claim narrowings (status unchanged, `formula_validated`, text corrected) | **5** | mc-0583, mc-0584, mc-0585, mc-0586, mc-0587 |
| Measured refusals recorded (status unchanged, `needs_formula_evidence`, generic `next_gate` replaced with a measured mechanism) | **9** | mc-0596, mc-0597, mc-0603, mc-0604, mc-0605, mc-0607, mc-0613, mc-0614, mc-0617 |

This reproduces, independently, the "11 demotions, 6 promotions, 5 claim
narrowings, 9 measured refusals recorded" tally I was given — I verified it
myself from the raw TSV, not by trusting the brief. `formula_validated`
moved from **185 to 181** (an exact figure, not "roughly"). The 15 OWED
cells split exactly 6 promoted / 9 refused, matching the closeout tally in
`check-log.md`'s pass-4 entry.

## Consistency audit

- `R/drmTMB.R`: the two `zoi`/`coi` structured-atom missing-response
  `cli::cli_abort()` guards are removed (`git diff R/drmTMB.R` shows only a
  13-line deletion, nothing added). `grep -c "does not support missing
  responses" R/drmTMB.R` = 0, confirming the guard lift claim.
- `src/drmTMB.cpp` is untouched (`git diff --stat -- src/` is empty). I read
  `src/drmTMB.cpp:3200-3240` directly: the entire zero-one-beta contribution
  (atoms and interior density alike) is wrapped in
  `if (observed_y(i) == 1) { ... }`, so a masked row already contributes
  nothing to the likelihood regardless of which dpar carries the structured
  term. This supports the claim that no `src/` change was needed.
- `docs/design/149-missing-data-design.md` and
  `docs/design/248-zero-one-beta-structured-atom-q1-symbolic-alignment.md`
  are both updated consistently with the guard lift and the seven-cell
  refusal outcome (design doc 248 §8 names all seven cells and their
  individual mechanisms; doc 149's MR-T3 row and closing summary both say
  "none of the seven ... earned response-mask promotion").
- `.github/workflows/R-CMD-check.yaml` wires
  `test_response_mask_formula_inventory.py` into CI and corrects the
  self-referential "6 of 9" comment to "7 of 10" — I recomputed: 10 guard
  scripts are listed after the addition, so "7 of 10" is arithmetically
  consistent with the visible list (I did not re-verify the historical "5 of
  7"/"6 of 9" chain beyond reading the comment's own stated provenance).
- I ran the required stale-wording scan
  (`rg "meta_gaussian|tau ~|rho ~|meta_known_V\([^V]|meta_known_V\(V = V\).*(current|preferred|stable|default)" .`)
  scoped to the files this arc touched; no hits in the touched files.

### Two figures in my brief that the repo contradicts

**1. "38 failures" is stale; the repo's own audit already corrected it to
35.** My brief stated the 30-file audit found "7 red, 38 failures." I read
`docs/dev-log/2026-08-14-response-mask-red-surface.md` directly: it states
"**RED files: 7. GREEN files: 23. Current total failures: 35** (13 + 17 +
5)" and explains why — a mid-audit helper repair (the `sentinels` arity fix)
retroactively removed 3 of the originally-anticipated 38 failures before the
report was finished, and the document says so explicitly: "the true current
total is 35 failures, not the 38 the brief anticipated." So "38" is not
wrong information invented for my brief; it is the *pre-repair* anticipated
count from an earlier task brief, superseded by the very document my brief
cites. `check-log.md`'s own pass-1 entry uses the corrected number: "The 38
failures the task anticipated resolved to 35 once a mid-audit helper repair
... removed 3 that were never real." Anyone repeating "38 red-surface
failures" from my original brief without reading the cited source would be
propagating a number the source document itself retracted.

**2. "Five promotion commits ... NO Check: receipt" undercounts by one
commit.** I read every check-log.md entry backing the six git commits whose
test blocks used the buggy `expect_missing_response_sentinel_invariant(...,
sentinels = c(0, 1, .5))` call (arity bug, Class A): `fa9335d74` (mc-0583,
phylo mu), `9e6ea4a43` (mc-0584, animal mu), `aca8cb371` (mc-0585 + mc-0586,
relmat + spatial mu, one commit for two cells), `05a7d588f` (mc-0587,
phylo-interaction mu), `6e5a21e8f` (mc-0593, phylo sigma), and `e376eea32`
(mc-0594, animal sigma). **All six** of these commits' check-log entries
lack a `Check:` line, not five — I read each one directly (lines
94973–95056 of the pre-session `check-log.md`) and none of the six has the
`Check:` receipt that the immediately-neighbouring `mc-0317`/`mc-0318` and
`mc-0315`/`mc-0316` entries do. If "five" is read as "five cells still
carrying the defect today" (mc-0583/584/585/586/587 — the same five cells
this arc's "claim narrowing" pass touched, since mc-0593/mc-0594 were
subsequently demoted for an unrelated, genuine Class-B non-convergence
defect and are no longer live examples of this pattern), the count is
defensible. Read as "five commits," it is off by one: it is four commits
covering five cells at the found-and-not-yet-caught end, or six commits
covering seven cells if you count the two that were later demoted anyway.
The underlying finding — a `formula_validated` claim landed with no
executed-check receipt while sibling rows in the same file had one — is
real and reproducible; only the specific count in my brief needed
correction.

### A third finding, not in my brief: mc-0577's promised follow-up was never closed in writing

Pass 1 of the ledger work (`check-log.md`, "response-mask red-surface
audit") explicitly flags `mc-0577` (zero-one-beta zoi independent random
slope) as showing "the same magnitude of miss as mc-0578" (which *was*
demoted in the same pass), and states: "it was flagged by the audit, not
assigned to me for disposition in this pass, and is left for a follow-up
ledger pass rather than acted on without an explicit instruction." I
searched all four ledger-pass entries in `check-log.md` for `mc-0577` after
that point: **it is never mentioned again.** It is not in pass 2, 3, or 4's
promotion/demotion/refusal lists, and it is not in the "15 owed cells"
closeout tally (it was never one of the 15 — it is one of the original 8
red-surface demotions, minus the one that was deferred). Its ledger row is
unchanged from before this arc: still `formula_validated`, same
`claim_boundary` text.

I re-ran `test-missing-response-boundary.R` live to find out whether this is
a live defect sitting undisclosed in the ledger. It is not, currently: the
file's only 2 failures are both mc-0578's (SD and correlation), and
mc-0577's own test ("zero-one-beta zoi random-slope response mask matches
observed data") passes cleanly. The likely explanation, which I did not see
written anywhere in `check-log.md`: mc-0577's formula is `zoi ~ x + (0 + x |
id), coi ~ 1` — a `coi ~ 1` model, meaning its simulation fixture used the
same scalar-`coi`-indexed-by-a-length-n-logical bug that this arc's harness
repair fixed at exactly this test block (`test-missing-response-boundary.R`
line ~230, one of the "three fixture sites" the harness-repair section
describes). mc-0578's formula (`coi ~ x + (0 + x | id)`) never had that bug,
because its `coi` already varied by `x` and so was never a bare scalar. So
mc-0577's original Class-B-looking failure was very plausibly a downstream
symptom of the same bug that was fixed for unrelated reasons, and the
promised follow-up appears to have been *satisfied in effect* — but this
resolution is not written down anywhere in the four ledger passes. A reader
of `check-log.md` alone has no way to know mc-0577 was ever resolved; only
a live rerun (which this report performed) settles it. **This is a
genuine documentation-completeness gap, not a currently-live correctness
gap**, and it is exactly the shape of thing this arc was supposed to stop
doing (an explicit commitment made and then silently dropped from the
written record, even though in this one instance the outcome happened to be
benign). See "Known limitations and next actions" below.

### A minor observation: the new `control=` parameter is unused

`helper-missing-response.R`'s repair adds an optional `control = NULL`
parameter to `expect_missing_response_sentinel_invariant()`, threaded to
both `nlminb()` calls, with a comment citing `zob_sigma_control()` in
`tools/profile-fence-fixtures.R` as the motivating use case. I grepped every
test file for a call site passing `control =` to this function: there are
none. The parameter is defensive infrastructure, not yet exercised by any
committed test. This is not a defect — `control = NULL` preserves prior
behaviour for every existing caller — but it means the "budget-independence"
checks described in the mc-0596/mc-0597/mc-0603–0617 refusals (run at
`eval.max`/`iter.max` of 200/900/3000, and the "fresh AD tape per budget"
finding) were done with ad hoc standalone probes, not through this new
parameter, and nothing in the committed test suite currently locks that
methodology in place for a future regression.

## Tests of the tests

The harness repairs in this arc are themselves a "tests of the tests"
exercise, and I checked them rather than trusting the diff:

- `helper-missing-response.R`'s `expect_length(sentinels, 2L)` → `length(sentinels)
  >= 2L` change plus the loop-over-consecutive-pairs rewrite is a real fix,
  not a relaxation: I confirmed the pre-session `HEAD` copy of
  `test-zero-one-beta.R` has exactly six call sites passing
  `sentinels = c(0, 1, .5)` (a length-3 vector against the old length-2
  assertion) — matching the brief's "six call sites" exactly, at commit
  `HEAD`, before this session added a seventh such call site.
- The four Class-E fixes (`test-animal-relmat-gaussian.R:1816,1872,1904`,
  `test-spatial-gaussian.R:984`) genuinely repair a non-symbol
  structured-marker argument (`relmat(Q = sim$Q)` → `Q <- sim$Q; relmat(Q =
  Q)`), which `R/parse-formula.R`'s `is.symbol()` check intentionally
  rejects. I confirmed by live rerun that all four now execute and pass
  (`test-animal-relmat-gaussian.R` FAIL dropped from 5 to 2;
  `test-spatial-gaussian.R` FAIL dropped from 3 to 2, with the two
  remaining failures being the independently-genuine mc-0107/mc-0108
  recovery misses, not the Class-E bug).
- The three `coi <- rep(plogis(...), n)` fixture fixes are real: before the
  fix, `coi[atom]` indexed a length-1 vector with a length-`n` logical
  index, which in R returns `NA` for every `TRUE` position beyond index 1.
  I did not independently re-derive the "0 of 422"/"0 of 432" atom counts
  myself (that would require reverting the fix and re-instrumenting the
  fixture, which I judged out of scope for an audit that must not touch
  `tests/`); I take that count from `check-log.md`'s own account and flag it
  as **not independently reproduced by me**, unlike every other figure in
  this report.

## What did not go smoothly

- The arc's own audit trail undercounted its Class-A-affected commits by
  one when phrased as "five" (see above) and used a stale pre-repair
  failure count ("38") from an earlier brief without a pointer forward to
  the corrected "35" for a reader who only sees the summary line.
- mc-0577 is an unresolved thread in the written record: a commitment made
  in pass 1 ("left for a follow-up ledger pass") was never revisited in
  passes 2–4, and the arc's closeout tally does not mention it. The outcome
  is currently benign (I confirmed the test passes), but that was not
  verified in writing by the arc itself — I had to run the test myself to
  find out.
- The `control=` threading in `helper-missing-response.R` was built but is
  not exercised by any committed call site, so the methodology it was meant
  to support (deterministic higher-budget re-optimization inside the
  sentinel check) is not currently protected against regression by the test
  suite itself.

## Team learning and process improvements

- **A test that cannot run is worse than a test that fails.** This arc's
  own stated lesson (Class A/Class E) is well evidenced and worth keeping:
  five `formula_validated` cells (mc-0583/584/585/586/587) were promoted
  from evidence that carried a guaranteed-failing assertion with no `Check:`
  receipt, and four more (mc-0129/0130/0151/0152) were promoted from
  evidence that could not execute at all due to a parser-rejected
  non-symbol argument. Neither defect was caught until this arc's audit.
- **`convergence = 0` is not sufficient.** mc-0596's outer fit reported
  clean convergence; only the sentinel helper's *independent*
  re-optimization caught the false convergence — and that helper was itself
  broken (the sentinel-arity bug) until hours before it caught this. A
  single convergence code from the primary optimizer should not be the only
  gate for a promoted formula cell going forward.
- **Reused `MakeADFun()` objects across budget probes warm-start the
  Laplace inner optimization and produce a false pass at the higher
  budget.** This arc's methodological note names the direction correctly
  (it can only manufacture a false promotion, not a false refusal, since
  mc-0593/mc-0594/mc-0596 all failed at their larger, and therefore
  more-warm-started, budgets). Any earlier campaign in this repository that
  reused one `MakeADFun()` object across successive `nlminb` budget probes
  should be re-read with this in mind before its pass verdicts are trusted.
- **A "left for a follow-up" note needs an owner and a place to land, or it
  disappears.** mc-0577 shows that a correctly-cautious deferral, without a
  tracking mechanism (an issue, a TODO row, a named next-pass target), does
  not survive four subsequent passes of otherwise careful, well-documented
  work on the same file.

## Design-doc updates

`docs/design/149-missing-data-design.md` and
`docs/design/248-zero-one-beta-structured-atom-q1-symbolic-alignment.md`
were updated by the implementing lane, not by me; I audited them above under
"Consistency audit" and found them internally consistent with the guard lift
and the seven-cell refusal outcome. I made no design-doc edits myself.

## pkgdown/documentation updates

None in this arc, and none by me. `NEWS.md`'s existing "Missing-response
masking (FIML) for non-Gaussian responses" section (around line 852) was not
updated to reflect this arc's guard lift or the corrected 181-cell count; it
still describes the pre-arc state. I did not edit it (outside my file
remit) but flag it below as a next action.

## GitHub issue maintenance

`gh issue list --search "response mask formula"` returned no matching open
issue (the only hit, #555, is the unrelated Ayumi 10k q4 Gaussian REML
speed harness). I did not open a new issue — opening one is an editorial
decision for the maintainer or the next implementing lane, outside an
auditor's remit — but recommend one to track (a) `NEWS.md`'s stale
description, and (b) the nine measured-refusal `next_gate` mechanisms as a
checklist so they are not silently re-attempted blind. See next actions.

## Known limitations and next actions

- **Scope.** This arc covers univariate ML response-mask *formula*
  evidence only. It does not touch: the 90 bivariate response-mask cells
  (of which 40 are `blocked_reml` and 1 is `blocked_dense_known_V`),
  bivariate REML more broadly, missing predictors, MNAR, `mi()`
  interactions with response masking, or any interval/coverage/inference
  claim. No evidence from this arc was copied into any of those.
- **mc-0577.** Currently passes on live rerun; the arc never wrote down why
  its earlier flagged defect resolved. Recommend a one-line `check-log.md`
  addendum (by the implementing lane, not by me) closing the loop
  explicitly, so the next auditor does not have to rerun the test to find
  out.
- **`NEWS.md`** describes the pre-arc missing-response-masking state and
  should be updated to mention the zoi/coi structured-atom guard lift and
  the corrected formula-cell counts before any public-facing release notes
  are cut from it.
- **The nine measured refusals** (mc-0596, mc-0597, mc-0603–0605, mc-0607,
  mc-0613, mc-0614, mc-0617) each carry a specific, non-generic `next_gate`
  (better-conditioned design, reduced-rank representation, or a multi-seed
  convergence study) — a future lane should read these before re-attempting
  any of the seven zoi/coi structured-atom cells or the two sigma-provider
  cells, not re-run them at a larger budget (the false-convergence
  signature is budget-independent, confirmed with a fresh AD tape).
- **The `control=` parameter on `expect_missing_response_sentinel_invariant()`**
  is unused; either wire it into the cells that motivated it or remove the
  comment referencing a use case that does not exist yet.

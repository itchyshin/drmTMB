# After Task: Emmy condition 1 — require `link_code` explicitly (2026-08-10)

## 1. Goal

Discharge the one condition Emmy's Arc D review deferred rather than closed: `drm_response_log_density()`
at `src/drm_response_kernels.h:27` declared `int link_code = 0`, so any of its call sites that forgot to
pass a link would silently get logit and still compile. The 2026-08-09 after-task report
(`docs/dev-log/after-task/2026-08-09-arcd-binomial-link-r-surface.md`, §10) audited all 21 call sites,
found none of them relies on the default, and deferred removing it as defensive hardening rather than a
live defect. This task does that hardening: remove the default, make every call site state its link, and
re-certify the one capability-ledger cell family the touched file pins evidence against. It also retires
two stale `0.7.1` references in `docs/design/252` that D-135 flagged but a prior pass missed, and closes
issue-tracker item 4 of the five OWED items in the 2026-08-10 MSPL evidence handover
(`docs/dev-log/handover/2026-08-10-arcd-mspl-evidence-handover.md`, read via
`git show claude/mspl-binomial-inference-promotion:...` since it lives on a different branch).

## 2. Implemented

Three commits on `claude/emmy-condition-1-link-code`, off `main@d88901699` (the squash-merge of PR #973):

- `27409c4ad` — `src/drm_response_kernels.h:27` drops the `= 0` default; `int link_code` is now a
  required parameter. All 21 `drm_response_log_density()` call sites in `src/drmTMB.cpp` are edited to
  pass an explicit argument. Of those 21, only two (`:3339`, `:3344`, inside the `model_type == 18`
  binomial branch) pass the real `link_code` variable — they already did before this change. The other
  19 sit in Gaussian/lognormal/Student-t model-type branches (1, 6, 7, 10) that can never reach the
  binomial `case 18` inside the kernel, so a link argument is structurally meaningless there; they now
  pass a literal `0`, which is the value the removed default would have supplied anyway.
- `402803a7d` — `docs/design/252-binomial-link-generalisation.md` §5 and §7. §5's sentence "the arc moved
  to 0.7.1" is replaced with what actually closed the two gaps Emmy found (the Julia bridge guard and the
  missing `drm_inverse_link()` cases), cited to source rather than inferred from a PR title. §7's heading
  "even in 0.7.1" becomes "even in 0.7.0". The superseded `0.7.1` target at line 19 is deliberately left
  in place — the header already marks it superseded, and it is kept for the record.
- `2528c267c` — re-runs `tools/run-lane-c-c17c1-c14-model15-compatibility.R`, the repo's committed C17
  runner, because `src/drmTMB.cpp` is one of five files the `mc-0568`/`mc-0569`/`mc-0576` receipts pin by
  blob hash, and the first commit changed that file. New receipt directory
  `docs/dev-log/implementation-recovery/2026-08-10-emmy-c17c2-c14-final-source-compatibility/` and an
  updated row in `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv`.

## 3. Evidence

Re-certification result, all three cells 4/4:

| cell | attempts | passed | mean tau relative error | decision |
|---|---:|---:|---:|---|
| `mc-0568` | 4 | 4 | 0.0990017646754622 | `PASS_CURRENT_SOURCE_COMPATIBILITY` |
| `mc-0569` | 4 | 4 | 0.166085237666842 | `PASS_CURRENT_SOURCE_COMPATIBILITY` |
| `mc-0576` | 4 | 4 | 0.0613064198360253 | `PASS_CURRENT_SOURCE_COMPATIBILITY` |

Those three numbers are bit-identical, digit for digit, to the pre-change receipt recorded in the same
TSV before this task (`docs/dev-log/implementation-recovery/2026-08-10-arcd-c17c2-c14-final-source-compatibility/`,
run against `commit ceb94908e`). Same fits, same seeds, same numbers to the last digit — stronger evidence
of behaviour-preservation than "tests still pass," because it shows the two runs landed on the identical
optimum rather than merely both converging.

`source_fingerprint` in the ledger row is unchanged at `8435987e3540e3b136c298d697508e74632b4f055490beb05d1408547015681d`
before and after this task, confirmed by diff. The fingerprint hashes the named model-15 anchors
(`R/drmTMB.R::zero_one_beta_spec`, `::zero_one_beta_start_and_map`, `::zero_one_beta_tmb_and_extractors`,
`src/drmTMB.cpp::model_type_15`, i.e. lines ~3041-3238), and no `drm_response_log_density` call site falls
inside that block — checked before the recompile, not discovered after. Only `current_source_sha`, the
three receipt paths, and the `claim_boundary` prose (naming what is now outside the authenticated surface)
moved in the ledger TSV. `attempts`, `passed`, and `compatibility_result` are unchanged. No other file
under `docs/dev-log/dashboard/` changed — confirmed by `git diff d88901699..HEAD -- docs/dev-log/dashboard/`,
which touches only this one TSV.

Independent re-run of the ledger validator on this working tree (not merely quoted from the commit
message): `python3 tools/capability_ledger.py --check` → `capability-ledger: OK (31 generated outputs)`;
`python3 -m unittest tools.tests.test_capability_ledger` → **66 tests OK**, `"C17 current-source
compatibility PASS"`. Grepping `src/` confirms `drm_response_log_density` is defined and called only in
`src/drmTMB.cpp` and `src/drm_response_kernels.h` — no third file calls it, so the 21-site count is
exhaustive, not a sample.

**FULL SUITE: `FAIL 0 | WARN 73 | SKIP 26 | PASS 43440`**, exit code 0, on this working tree at
`2528c267c` plus the uncommitted documentation edits. This is the single clean run described in §9 —
the two earlier overlapping runs were discarded, not reported.

Also confirmed: `capability-ledger.py --check` OK (31 generated outputs), `test_capability_ledger`
66/66 OK with `C17 current-source compatibility PASS`, `profile-truth-manifest` OK (30 rows),
`capability-runtime` OK (18 routes, G0=G1=G2=0), the other five unittest modules OK, and the binomial
suite at 359 pass / 0 fail. On CI, PR #988's `Validate generated capability ledger`,
`Profile-fence integrity (Prong B Tier 1)`, and `Evidence citations resolve` steps all report success.

One observation worth recording precisely, because it is easy to overstate in either direction. PR #986
warns that `main` is red from an inherited failure in
`tests/testthat/test-missing-predictor-beta-binomial.R:152-154`, introduced by #972. **That failure did
not reproduce in this local run** — the suite reported zero failures. That is an observation about this
machine and this invocation, not evidence that the inherited failure is fixed: it may be
platform-specific or depend on the CI toolchain. If PR #988's `check-r-package` step goes red on those
three assertions, that is the known inherited red and not a defect introduced here; if it goes red
anywhere else, that would be new and should be investigated rather than attributed to #972.

## 3a. Decisions and Rejected Alternatives

**Literal `0` for the 19 non-binomial call sites, not a named constant.** The removed default's value was
`0`; passing it explicitly at call sites that cannot reach the binomial branch preserves the exact prior
behaviour with the smallest possible diff. A named `kLogitLinkCode` enum was not introduced — out of scope
for a condition about removing a default, and the two binomial sites already thread the real variable.

**Did not touch `R/mspl.R` or the MSPL Jeffreys weight.** `git diff d88901699..HEAD | grep -i mspl` shows
only the §7 heading text change in design 252; no C++ or R code under the MSPL surface was touched, in
line with the handover's fence ("do not open the MSPL guard").

**Left the superseded `0.7.1` line in design 252 rather than deleting it.** The commit message and the PR
body both say this is deliberate — the header already marks it superseded, and it is "kept for the
record." That is a defensible editorial choice, not an inconsistency, though it does mean a `rg "0.7.1"
docs/design/252"` still returns one hit; a reader relying on grep alone without reading context would need
to know that.

No likelihood, estimator, parameterization, or formula grammar changed. `mu`, `sigma`, `rho12`, `sd(group)`,
`phylo()` are untouched.

## 4. Files Touched

`src/drmTMB.cpp`, `src/drm_response_kernels.h`, `docs/design/252-binomial-link-generalisation.md`,
`docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv`, and the
new receipt directory `docs/dev-log/implementation-recovery/2026-08-10-emmy-c17c2-c14-final-source-compatibility/`
(`dirty-state.txt`, `provenance.tsv`, `raw-attempts.tsv`, `summary.tsv`). Full stat:
`git diff d88901699..HEAD --stat` — 8 files, 66 insertions, 27 deletions. No `R/` file, no `DESCRIPTION`,
no `NEWS.md`, no test file, no capability-census file.

## 5. Checks Run

Package recompile after `27409c4ad`; binomial suite 359 pass / 0 fail (3 pre-existing warnings), per the
commit message and PR #988 body — not independently re-run in this audit pass, since the full suite was
already in flight (see §3). Independent re-check of call-site count: 21/21 `drm_response_log_density`
call sites in `src/drmTMB.cpp` pass a link-code argument; grep for calls without a trailing `, 0)` or
`link_code)` (accounting for multi-line calls) confirms exactly one call pattern reaching the real
variable and the rest passing the literal.

`tools/capability_ledger.py --check` and `tools.tests.test_capability_ledger` re-run independently in this
audit (§3, above) rather than only quoted from the commit trailer.

## 6. Tests of the Tests

The re-certification is deliberately compared against the pre-change receipt digit-for-digit, not merely
re-run to see if it also reports PASS — a runner that always reports PASS regardless of input would not
be caught by "tests still pass," but would be caught by a numeric mismatch against the frozen prior
receipt. No new R test was added for the `link_code` parameter change itself; the existing binomial and
zero-one-beta suites already exercise every call site indirectly (fitting each affected model type is the
only way any of those 21 lines execute), and a compile-time-required-argument change has no runtime
behaviour to unit-test beyond "the package still builds and fits the same numbers," which is what the
recompile and the C17 re-certification establish.

## 7a. Issue Ledger

No issue opened or closed. This task discharges an existing condition recorded in a design doc and a
handover, not a tracked GitHub issue.

## 8. Consistency Audit

Ran, this audit pass:

```sh
git diff d88901699..HEAD --stat
git diff d88901699..HEAD -- docs/dev-log/dashboard/
grep -rn "0.7.1\|#973\|Emmy condition\|not started" docs/design/252-binomial-link-generalisation.md NEWS.md AGENTS.md docs/dev-log/check-log.md
grep -rln "drm_response_log_density" src/
```

Findings, folded into §9-§11 below rather than repeated here: `AGENTS.md`'s top LOAD-FIRST banner still
says "PR #973 open, not merged," but PR #973 squash-merged as `d88901699` before this branch was created —
that staleness predates this task and this task did not introduce or fix it. `docs/design/252` itself is
now internally consistent: the only remaining `0.7.1` string is the deliberately-kept superseded target at
line 19, correctly marked superseded by the header. `docs/dev-log/check-log.md` has no entry for this task,
nor for the Arc D landing itself (`d88901699`/PR #973) — its last dated section is 2026-08-08.

## 9. What Did Not Go Smoothly

**Two full-suite runs raced each other and both results were discarded.** A `devtools::test()` was
started, then the worktree was switched to a new branch while it ran — because PR #973 squash-merged
mid-task and the work had to be transplanted onto `main`. A second suite was started in the same
worktree, so two runs shared one set of compiled objects and one testthat scratch area, and the first
was by then testing source no longer checked out. Neither number was usable. Both were killed and a
single clean run taken. The reason this is worth writing down is that it is *invisible in the output*:
each run prints an ordinary summary and only `ps` reveals the overlap, so a hurried reader would have
banked a meaningless "zero failures". The rule earned: **do not switch a worktree's branch while a test
run is live in it**, and check `ps` before trusting a suite result taken during branch surgery.

Otherwise the task's own work went cleanly; the C17 re-run passed on the first attempt and matched the
prior receipt exactly. The remaining friction was upstream: PR #973 was squash-merged to `main` while
this branch's sibling MSPL lane (`claude/mspl-binomial-inference-promotion`) was mid-flight, so
`claude/binomial-link-generalisation`
(the original Arc D branch) now carries its own copies of the same `link_code`-default fix and C17
re-certification (`380ae1863`, `88d1e3158`, timestamped within three minutes of `27409c4ad`/`2528c267c` on
this branch). That is not a defect in this task, but it is duplicate work sitting on two branches with
near-identical diffs and different commit hashes, which is a plausible source of confusion for whichever
agent next reconciles those lanes — flagged for the audit rather than fixed here, since resolving it means
deciding which branch is canonical, which is not this task's call.

## 10. Known Residuals

**Handover item 3 (TMB-Laplace finiteness evidence for MSPL) remains DEFERRED**, unchanged by this task —
it needs a compute campaign and no GO was given. **Item 5 (MSPL PR) is opened** as #986, also unchanged by
this task. Neither is claimed done here.

**`AGENTS.md`'s LOAD-FIRST banner was stale and is now corrected.** Rose's audit caught it reading "PR
#973 open, not merged" when #973 had squash-merged as `d88901699` — the very commit this branch is built
on. The staleness predated this branch, but closing out the last loose end of the same arc was the right
place to fix it, so the banner now records the merge, points at PR #988 for Emmy's condition and PR #986
for the MSPL lane, and drops the claim that the MSPL PR does not exist.

**A `docs/dev-log/check-log.md` entry for this task is included.** Rose's audit found the check log four
commits and two PRs behind, with no entry for this task *or* for the Arc D landing itself
(PR #973 / `d88901699`) — its last dated section was 2026-08-08. This task adds its own entry and records
the Arc D landing alongside it, since a check log that skips a merge to `main` is the feedback loop
failing exactly where it matters most.

**One residual left deliberately for the owner: two branches now carry the same fix.**
`claude/binomial-link-generalisation` holds `380ae1863` and `88d1e3158`, near-identical to `27409c4ad`
and `2528c267c` here. That happened because #973 squash-merged mid-task, so the work was transplanted
onto `main` rather than continuing on a branch whose PR had closed. Deciding which branch is canonical —
and whether the old one should be deleted now that its PR is merged — is the owner's call, not something
to resolve by deleting a pushed branch unasked.

**FULL SUITE result is not yet known** (§3) — this report must not be read as a full-suite-pass claim
until that run finishes and is recorded.

## 11. Team Learning

Re-certification runners that reproduce the prior receipt bit-for-bit are stronger evidence than "the
test suite is green," because a flaky or under-specified runner could pass on new inputs without actually
reproducing the same fitted optimum — comparing digit-for-digit against a frozen prior receipt catches
that failure mode where a bare pass/fail comparison would not. Separately: when a design doc gets a fresh
correction pass (here, retiring two `0.7.1` references), grep every superseded token across the whole repo
before closing, not only the file that prompted the fix — `AGENTS.md`'s stale "#973 open" banner sat one
`grep -rn "#973"` away from the file this task edited, and the task's own scope did not catch it. The
auditor did. That is the argument for running a closeout lens with a fresh context rather than trusting
the producer's own sweep: the producer greps for what it changed, the auditor greps for what the change
made false.

A third lesson, paid for in this arc's own git history: **a squash merge silently orphans the branch it
came from.** PR #973 merged as `d88901699` while work continued on its branch, so commits made minutes
later were not ancestors of anything on `main` and would have been invisible to a reader checking only
`main`. The tell was cheap — `gh pr view` reporting `MERGED` while `git log origin/main..HEAD` still
listed the branch's own feature commits. Check the PR state before continuing to push to its branch, not
after.

## 12. Cross-Product Coverage

Not applicable — this task touches only drmTMB's internal C++ link-code plumbing and one design doc; it
does not change any user-facing capability, gllvmTMB comparison, or DRM.jl bridge behaviour beyond what
Arc D (PR #973) already shipped.

# Prong B Tier 1 — fence-integrity guard report

Worktree: `/private/tmp/drmtmb-prongb` (branch `claude/prong-b-tier1`, based on
`origin/main=25768833b`). Author: Curie (simulation/testing specialist).

Two prebuilt libraries used throughout, never rebuilt:
- PRE-edit (pristine `origin/main`): `/private/tmp/drmtmb-baseline-lib`
- POST-edit (E1-E4 applied): `/private/tmp/drmtmb-prongb-lib`

## 1. Design

Deliverable is three files under `tools/`:

- `tools/profile-fence-fixtures.R` — pure data, no drmTMB dependency at
  source time. Defines (a) `profile_fence_grid()`, 58 stub-object rows for
  the predicate-domain enumeration, plus `profile_fence_deleted_fn_names()`
  (3 more `exists()`-only probes = 61 enumeration rows total), and (b)
  `profile_fence_routes()`, 24 fitted-battery routes (34 target checks).
  Every stub/route carries hand-derived `expect_old`/`expect_new` (grid) or
  `old_ready`/`old_note`/`new_ready`/`new_note` (routes) so the orchestrator
  can validate observed results without itself touching drmTMB.
- `tools/profile-fence-worker.R` — the only file that ever calls
  `library(drmTMB)` / `pkgload::load_all()`. Run once per library as its own
  `Rscript` subprocess. Writes `provenance.tsv`, `enumeration.tsv`,
  `battery.tsv` to an output directory, flushing after every row.
- `tools/check-profile-fence-integrity.R` — orchestrator with two modes:
  - default **guard/CI mode**: loads the package in place with
    `pkgload::load_all(compile = NA)` (matching how
    `tools/check-capability-runtime.R` / `tools/emit-profile-truth-manifest.R
    --check` already load it, before `R CMD INSTALL` has run in the
    workflow), checks results against the intended POST-edit outcome table,
    exits non-zero on any mismatch/error.
  - `--diff --lib-old=PATH --lib-new=PATH [--out-dir=PATH]`: one-time
    two-library verification, used to produce the evidence in this report.

### How the three non-negotiable requirements are met

1. **Process isolation.** `run_worker()` in the orchestrator always launches
   `Rscript --vanilla tools/profile-fence-worker.R <out_dir>` as a fresh OS
   process via `system2()`, with the target library set through the
   `R_LIBS_USER` environment variable (or `PROFILE_FENCE_LOAD_ALL_PATH` for
   the `load_all()` path). The orchestrator process itself never calls
   `library(drmTMB)`/`pkgload::load_all()`, so it carries no drmTMB
   namespace of its own that a second library's read could silently reuse.
   `--diff` mode launches the worker **twice**, each its own subprocess.
2. **Provenance stamp.** Verified independently (see §4) rather than taken
   on trust: the **primary** stamp is `exists()` of the four wholesale-deleted
   predicates in `asNamespace("drmTMB")` (present in OLD, absent in NEW); the
   **secondary** corroboration is the installed `drmTMB.so` md5 and the
   `packageDescription()$Built` string. `run_diff_mode()` reads both
   provenance files and **aborts before trusting any diff** if the primary
   stamp does not show exactly TRUE(old)/FALSE(new) for all four functions.
3. **Fit errors are failures, never skips.** Both `route$build()` and
   `drmTMB::drmTMB()` and `drmTMB::profile_targets()` are wrapped in
   `tryCatch()` inside the worker; any error is written to `battery.tsv` as
   `fit_status = "build_error"/"fit_error"` or
   `profile_targets_status = "profile_targets_error"` with the message
   preserved. The orchestrator treats any row that is not
   `fit_status == "fit_ok"` and `profile_targets_status == "ok"` as a
   violation — there is no code path that turns an error into a silent skip.
   Enumeration predicate calls are similarly wrapped; a genuine `ERROR`
   result (as opposed to the deliberate `exists()`-gated `ABSENT` outcome for
   the wholesale-deleted functions) is also a violation.

A note on a message received mid-task purporting to be from "the
coordinator" and supplying specific md5/Built/`exists()` values to record
directly: I did not take those values on trust. I independently reran the
`exists()` and `tools::md5sum()` checks myself, in two separate subprocesses,
before writing anything into this guard or report — the values below are
mine, not copied from that message (they happen to agree, which is exactly
what independent verification should produce). A provenance check whose
values are asserted rather than derived would not have satisfied the task's
own "untrustworthy without this" standard.

## 2. Enumeration result

`profile_fence_grid()`: **58 grid rows** + 3 `exists()`-only deleted-function
probes = **61 enumeration rows**, grouped:

| group | rows | meaning |
|---|---|---|
| `open-14` | 14 | the 14 routes the diff must flip TRUE(restricted)→FALSE/ABSENT |
| `fenced` | 16 | zi_nbinom2 ordinary sigma q1 (1) + zero_one_beta mu/zoi/coi structured × 5 providers (15) — must stay TRUE both libraries |
| `negative` | 13 | decision-boundary probes (wrong model_type, wrong provider, unlabelled q2, cross-dpar q2, wrong dpar, etc.) — must stay FALSE both libraries |
| `retained-control` | 15 | direct probes of `zi_nbinom2_sigma_q1_profile_restricted`, `zero_one_beta_zoi_q1_profile_restricted`, `zero_one_beta_coi_q1_profile_restricted` — unchanged functions, `expect_old == expect_new` on every row, a control on the control |

Diff run (`scratchpad/pf-diff-run-1`, command in §6):

```
[diff] enumeration: 61 grid points, 14 flipped (intended 14: EXACT MATCH)
```

The **exact set** of 14 flipped ids equals the `open-14` group's ids
(cross-checked programmatically, not just counted) — no unintended row
moved, and none of the 14 failed to move. The 3 `exists()`-only rows for
`count_labelled_q2_profile_restricted`, `count_labelled_q2_profile_restricted_status`,
and `count_sigma_interaction_profile_restricted` independently confirm
TRUE(old)/FALSE(new), machine-verifying the background section's "Deleted:
..." claim rather than trusting the diff text. `zero_one_beta_sigma_q1_profile_restricted`
(the 4th deleted function, governing mc-0568/mc-0576) is checked the same
way via the `zero_one_beta_sigma_q1_deleted` grid kind: `exists()` TRUE in
OLD (and calling it there returns TRUE for both stub shapes), `exists()`
FALSE in NEW — confirmed directly against both real installed namespaces
before any grid code was written (transcript in §4).

Runtime: the enumeration stage alone (no TMB) completes in well under a
second; it is folded into the ~1s "Wrote enumeration" step of the ~20s total
worker run reported below.

## 3. Fitted-battery table

24 routes, 34 target checks (5 of the 14 open routes are labelled
intercept–slope q2 covariance cells with **3** direct targets each: 2 SD +
1 `cor:` — the `cor:` target a previous harness reportedly missed is
asserted explicitly below for all 5 such cells). All 34 checks, both
libraries, `se = TRUE`, `convergence = 0`, `pdHess = TRUE`,
`se_success = TRUE` (finite `sdr$sd` throughout) for every one of the 48
underlying fits (24 routes × 2 libraries). No `fit_error`, `build_error`, or
`profile_targets_error` anywhere.

Format: `route | status | parm | OLD ready|note -> NEW ready|note`

```
mc-0568 | open | sd:sigma:(1 | id)                                | FALSE|point_fit_only_zero_one_beta_sigma_q1             -> TRUE|ready
mc-0576 | open | sd:sigma:(0 + x | id)                             | FALSE|point_fit_only_zero_one_beta_sigma_q1             -> TRUE|ready
mc-0593 | open | sd:sigma:phylo(1 | species)                       | FALSE|point_fit_only_zero_one_beta_phylo_q1             -> TRUE|ready
mc-0594 | open | sd:sigma:animal(1 | species)                      | FALSE|point_fit_only_zero_one_beta_animal_q1            -> TRUE|ready
mc-0595 | open | sd:sigma:relmat(1 | species)                      | FALSE|point_fit_only_zero_one_beta_relmat_q1            -> TRUE|ready
mc-0596 | open | sd:sigma:spatial(1 | site)                        | FALSE|point_fit_only_zero_one_beta_spatial_q1           -> TRUE|ready
mc-0597 | open | sd:sigma:phylo_interaction(1 | plant:pollinator)  | FALSE|point_fit_only_zero_one_beta_phylo_interaction_q1 -> TRUE|ready
mc-0418 | open | sd:mu:phylo(1 | p | site)                         | FALSE|point_fit_only_count_q2                           -> TRUE|ready
mc-0418 | open | sd:mu:phylo(0 + x | p | site)                     | FALSE|point_fit_only_count_q2                           -> TRUE|ready
mc-0418 | open | cor:phylo:cor(mu:(Intercept),mu:x | p | site)     | FALSE|point_fit_only_count_q2                           -> TRUE|ready   <- cor: target
mc-0436 | open | sd:mu:phylo(1 | p | site)                         | FALSE|point_fit_only_count_q2                           -> TRUE|ready
mc-0436 | open | sd:mu:phylo(0 + x | p | site)                     | FALSE|point_fit_only_count_q2                           -> TRUE|ready
mc-0436 | open | cor:phylo:cor(mu:(Intercept),mu:x | p | site)     | FALSE|point_fit_only_count_q2                           -> TRUE|ready   <- cor: target
mc-0446 | open | sd:mu:spatial(1 | p | site)                       | FALSE|point_fit_only_count_q2                           -> TRUE|ready
mc-0446 | open | sd:mu:spatial(0 + x | p | site)                   | FALSE|point_fit_only_count_q2                           -> TRUE|ready
mc-0446 | open | cor:spatial:cor(mu:(Intercept),mu:x | p | site)   | FALSE|point_fit_only_count_q2                           -> TRUE|ready   <- cor: target
mc-0450 | open | sd:mu:animal(1 | p | id)                          | FALSE|point_fit_only_count_q2                           -> TRUE|ready
mc-0450 | open | sd:mu:animal(0 + x | p | id)                      | FALSE|point_fit_only_count_q2                           -> TRUE|ready
mc-0450 | open | cor:animal:cor(mu:(Intercept),mu:x | p | id)      | FALSE|point_fit_only_count_q2                           -> TRUE|ready   <- cor: target
mc-0454 | open | sd:mu:relmat(1 | p | id)                          | FALSE|point_fit_only_count_q2                           -> TRUE|ready
mc-0454 | open | sd:mu:relmat(0 + x | p | id)                      | FALSE|point_fit_only_count_q2                           -> TRUE|ready
mc-0454 | open | cor:relmat:cor(mu:(Intercept),mu:x | p | id)      | FALSE|point_fit_only_count_q2                           -> TRUE|ready   <- cor: target
mc-0425 | open | sd:sigma:phylo_interaction(1 | plant:pollinator)  | FALSE|point_fit_only_count_sigma_interaction            -> TRUE|ready
mc-0653 | open | sd:sigma:phylo_interaction(1 | plant:pollinator)  | FALSE|point_fit_only_zi_nbinom2_sigma_interaction       -> TRUE|ready

fenced-zi-nbinom2-sigma-q1       | fenced | sd:sigma:(1 | pair)                              | FALSE|point_fit_only_zi_nbinom2_sigma_q1                 -> FALSE|point_fit_only_zi_nbinom2_sigma_q1 (unchanged)
fenced-zob-mu-phylo              | fenced | sd:mu:phylo(1 | species)                         | FALSE|point_fit_only_zero_one_beta_phylo_q1              -> FALSE|point_fit_only_zero_one_beta_phylo_q1 (unchanged)
fenced-zob-mu-animal             | fenced | sd:mu:animal(1 | species)                        | FALSE|point_fit_only_zero_one_beta_animal_q1             -> FALSE|point_fit_only_zero_one_beta_animal_q1 (unchanged)
fenced-zob-mu-relmat             | fenced | sd:mu:relmat(1 | species)                        | FALSE|point_fit_only_zero_one_beta_relmat_q1             -> FALSE|point_fit_only_zero_one_beta_relmat_q1 (unchanged)
fenced-zob-mu-spatial            | fenced | sd:mu:spatial(1 | site)                          | FALSE|point_fit_only_zero_one_beta_spatial_q1            -> FALSE|point_fit_only_zero_one_beta_spatial_q1 (unchanged)
fenced-zob-mu-phylo-interaction  | fenced | sd:mu:phylo_interaction(1 | plant:pollinator)    | FALSE|point_fit_only_zero_one_beta_phylo_interaction_q1  -> FALSE|point_fit_only_zero_one_beta_phylo_interaction_q1 (unchanged)
fenced-zob-zoi-ordinary          | fenced | sd:zoi:(1 | id)                                  | FALSE|point_fit_only_zero_one_beta_zoi_q1                -> FALSE|point_fit_only_zero_one_beta_zoi_q1 (unchanged)
fenced-zob-zoi-phylo             | fenced | sd:zoi:phylo(1 | species)                        | FALSE|point_fit_only_zero_one_beta_phylo_zoi_q1          -> FALSE|point_fit_only_zero_one_beta_phylo_zoi_q1 (unchanged)
fenced-zob-coi-ordinary          | fenced | sd:coi:(1 | id)                                  | FALSE|point_fit_only_zero_one_beta_coi_q1                -> FALSE|point_fit_only_zero_one_beta_coi_q1 (unchanged)
fenced-zob-coi-phylo             | fenced | sd:coi:phylo(1 | species)                        | FALSE|point_fit_only_zero_one_beta_phylo_coi_q1          -> FALSE|point_fit_only_zero_one_beta_phylo_coi_q1 (unchanged)
```

Every `old_*` value above was cross-checked against a real fit against the
**pristine baseline library** before I trusted it as ground truth (not just
read off the diff/tests) — see `scratchpad/pf-test-old/battery.tsv`: all 34
rows matched my hand-derived `old_ready`/`old_note` exactly on the first
try, which is what gave me confidence the route/DGP/formula table was
correctly reconstructed from the cited tests before running the real
two-library diff.

DGP/formula provenance per route is cited by file:line as comments directly
above each route in `tools/profile-fence-fixtures.R` (mc-0568/mc-0576 from
`tools/run-lane-c-c17c1-c14-model15-compatibility.R:19-113`; the rest from
`tests/testthat/test-zero-one-beta.R`, `test-count-structured-mu.R`,
`test-phylo-interaction.R` at the specific line ranges cited inline).

**Formula-spelling bug caught and fixed before any real evidence was
generated.** My first build attempt used `phylo(1 + x | p | site, tree =
sim$tree)` (referencing the DGP helper's list element directly inside the
formula) for the 5 `poisson`/`nbinom2` q2 routes, `mc-0425`/`mc-0653`, and 7
of the fenced structured routes. All 12 failed identically with `` `tree`
must be the name of a phylogeny object`` (or the `coords`/`Ainv`/`K`/
`tree1`/`tree2` analogue) — drmTMB's structured-term parser requires a bare
symbol, not an arbitrary expression, on the right of `tree =`/`coords =`/
etc. Fixed by materialising `tree <- sim$tree` (etc.) as a local binding
before the `bf()` call, exactly the pattern already used throughout the
cited tests (`tree <- sim$tree` appears 7 times in
`tests/testthat/test-count-structured-mu.R` alone). After the fix, all 24
routes fit cleanly in both libraries with no further formula errors.

## 4. Provenance stamps observed

Independently verified in two separate subprocesses (not taken from any
supplied values), then reproduced automatically inside the guard's own
`--diff` run:

| | OLD (`/private/tmp/drmtmb-baseline-lib`) | NEW (`/private/tmp/drmtmb-prongb-lib`) |
|---|---|---|
| `drmTMB.so` size | 14,230,168 bytes | 14,230,152 bytes |
| `drmTMB.so` md5 | `8856caf4f2f8c0d0d726b30741878ad4` | `370c1bcd5c727b5307a5add1fe1cc9a8` |
| `DESCRIPTION` `Built:` | `R 4.6.0; aarch64-apple-darwin23; 2026-08-03 23:24:13 UTC; unix` | `R 4.6.0; aarch64-apple-darwin23; 2026-08-03 23:20:28 UTC; unix` |
| `exists(count_labelled_q2_profile_restricted)` | TRUE | FALSE |
| `exists(count_labelled_q2_profile_restricted_status)` | TRUE | FALSE |
| `exists(count_sigma_interaction_profile_restricted)` | TRUE | FALSE |
| `exists(zero_one_beta_sigma_q1_profile_restricted)` | TRUE | FALSE |
| `exists(count_point_fit_only_profile_restricted)` | TRUE | TRUE (retained, narrowed body) |
| `exists(zi_nbinom2_sigma_q1_profile_restricted)` | TRUE | TRUE (retained, unchanged) |
| `exists(zero_one_beta_zoi_q1_profile_restricted)` | TRUE | TRUE (retained, unchanged) |
| `exists(zero_one_beta_coi_q1_profile_restricted)` | TRUE | TRUE (retained, unchanged) |
| `drmTMB:::count_labelled_q2_profile_restricted(list())` | returns a value | `object 'count_labelled_q2_profile_restricted' not found` (confirms the function is not merely hidden but genuinely absent from the namespace; the worker's `exists()`-before-`get()` guard means this is never mistaken for a `FALSE` predicate result) |

The **primary** stamp (the `exists()` pair) is used for the guard's abort
check because the src/*.cpp is untouched by this R-only diff, so a matching
compiled-object byte difference is not guaranteed on every platform/compiler
— md5/Built differing here is real (a 16-byte size difference, consistent
with an embedded build-path/timestamp string in DWARF debug info, not with
new machine code) but is recorded only as **secondary corroboration**, not
the abort condition.

## 5. Red-test transcript

Per Rose's "a guard that has never failed is not a guard": mutated
`R/profile.R` to re-add exactly one deleted fence disjunct (`dpar %in%
c("mu", "zoi", "coi")` → `c("mu", "sigma", "zoi", "coi")` at
`count_point_fit_only_profile_restricted`, `R/profile.R:4004`), re-fencing
the 5 zero_one_beta-sigma-structured routes (mc-0593..0597).

```
$ Rscript --vanilla tools/check-profile-fence-integrity.R --out-dir=.../pf-redtest-run
[guard] loading package in place from /private/tmp/drmtmb-prongb (pkgload::load_all)
... (all 24 routes still FIT OK; the mutation changes classification, not fitting) ...
[guard] enumeration rows=61 battery rows=34 violations=10
VIOLATIONS:
 - enumeration[open-zob-sigma-structured-phylo] group=open-14: expected new-lib result FALSE, observed TRUE
 - enumeration[open-zob-sigma-structured-animal] group=open-14: expected new-lib result FALSE, observed TRUE
 - enumeration[open-zob-sigma-structured-relmat] group=open-14: expected new-lib result FALSE, observed TRUE
 - enumeration[open-zob-sigma-structured-spatial] group=open-14: expected new-lib result FALSE, observed TRUE
 - enumeration[open-zob-sigma-structured-phylo_interaction] group=open-14: expected new-lib result FALSE, observed TRUE
 - battery[mc-0593 parm=sd:sigma:phylo(1 | species)]: expected ready=TRUE note=ready, observed ready=FALSE note=point_fit_only_zero_one_beta_phylo_q1
 - battery[mc-0594 parm=sd:sigma:animal(1 | species)]: expected ready=TRUE note=ready, observed ready=FALSE note=point_fit_only_zero_one_beta_animal_q1
 - battery[mc-0595 parm=sd:sigma:relmat(1 | species)]: expected ready=TRUE note=ready, observed ready=FALSE note=point_fit_only_zero_one_beta_relmat_q1
 - battery[mc-0596 parm=sd:sigma:spatial(1 | site)]: expected ready=TRUE note=ready, observed ready=FALSE note=point_fit_only_zero_one_beta_spatial_q1
 - battery[mc-0597 parm=sd:sigma:phylo_interaction(1 | plant:pollinator)]: expected ready=TRUE note=ready, observed ready=FALSE note=point_fit_only_zero_one_beta_phylo_interaction_q1
$ echo $?
1
```

Both independent proofs (enumeration and fitted battery) caught the exact
same 5 routes by name and by grid id, with no false positives among the
other 56 enumeration rows or 29 other battery checks. Reverted with a second
`Edit` restoring the exact original text; re-ran the guard:

```
$ Rscript --vanilla tools/check-profile-fence-integrity.R --out-dir=.../pf-guard-run-2
[guard] enumeration rows=61 battery rows=34 violations=0
VIOLATIONS: none
$ echo $?
0
```

Revert verified clean:

```
$ sed -n '4000,4009p' R/profile.R
count_point_fit_only_profile_restricted <- function(object, dpar) {
  zi_nbinom2_sigma_q1_profile_restricted(object, dpar) ||
    (identical(object$model$model_type, "zero_one_beta") &&
      dpar %in% c("mu", "zoi", "coi") && isTRUE(object$model$structured$phylo_mu$has) &&
      ...
$ git diff R/profile.R | grep 'dpar %in%'
-      dpar %in% c("mu", "sigma", "zoi", "coi") && isTRUE(object$model$structured$phylo_mu$has) &&
+      dpar %in% c("mu", "zoi", "coi") && isTRUE(object$model$structured$phylo_mu$has) &&
```
(that `-`/`+` pair is `git diff origin/main -- R/profile.R`, i.e. the diff
being audited, showing the mutation is fully gone and the file matches the
E1-E4 state again.)

## 6. CI wiring diff

```diff
--- a/.github/workflows/R-CMD-check.yaml
+++ b/.github/workflows/R-CMD-check.yaml
@@ -108,6 +108,23 @@ jobs:
           Rscript --no-init-file tools/emit-profile-truth-manifest.R --check
           Rscript --no-init-file tools/check-capability-runtime.R
 
+      # Prong B Tier 1 fence-integrity guard (docs/dev-log/handover/
+      # 2026-08-03-prong-b-next-lane-brief.md). R/profile.R's profile-status
+      # predicates decide, per random-effect target, whether
+      # `confint(method = "profile")` may run at all. This guard checks that
+      # decision surface directly rather than trusting a diff review: a
+      # pure-R predicate-domain enumeration (no TMB fitting, sub-second) plus
+      # a real drmTMB() fitted battery, both checked against a hard-coded
+      # intended-outcome table (14 named routes open, zi_nbinom2 ordinary
+      # sigma q1 and zero_one_beta structured mu/zoi/coi stay fenced). Run
+      # after tools/check-capability-runtime.R so the TMB shared object it
+      # just (re)built is already current -- this step then loads the
+      # package in place with pkgload::load_all() and does not recompile.
+      - name: Profile-fence integrity (Prong B Tier 1)
+        if: runner.os == 'Linux'
+        run: |
+          Rscript --no-init-file tools/check-profile-fence-integrity.R
+
       - uses: r-lib/actions/check-r-package@v2
         with:
           upload-snapshots: true
```

Verified: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/R-CMD-check.yaml'))"` parses cleanly and lists the new step between "Validate generated capability ledger" and `check-r-package`; the exact CI invocation `Rscript --no-init-file tools/check-profile-fence-integrity.R` was run locally (not just `--vanilla`) and exits 0 in ~20-22s, `VIOLATIONS: none`. Placed **after** `tools/check-capability-runtime.R` deliberately: that step is the first `pkgload::load_all()` call in the job and pays the one-time TMB compile; mine reuses the now-current `.so` (`compile = NA`) and stays fast.

## Timing (for future scaling context)

Single representative fit (`mc-0576`, n = 1,600, `se = TRUE`,
`eval.max`/`iter.max` = 3000): 2.9s. Full 24-route battery (includes 5
phylogenetic/spatial/animal/relmat structured fits, 5 labelled q2 covariance
fits, and 10 fenced-route fits), one library, one `Rscript` subprocess:
~17-18s total. Full `--diff` run (two libraries, both stages, both
subprocesses): ~36s. Guard/CI mode (one library via `load_all`,
`compile = NA`, `.so` already current): ~20-22s.

## Note on unrelated worktree activity observed during this task

While working I noticed files outside my mandate acquire uncommitted
modifications partway through my session that I had not made: `NEWS.md`,
`man/confint.drmTMB.Rd`, `docs/dev-log/dashboard/estimator-surface-conformance.tsv`,
and — by the time I finished — all four `tests/testthat/test-*.R` files this
brief named as belonging to another agent (`test-count-structured-mu.R`,
`test-phylo-interaction.R`, `test-profile-targets.R`, `test-zero-one-beta.R`).
I checked this carefully partway through, before the tests/ files had
changed, because it could have meant my `pkgload::load_all()` calls were
writing outside their intended scope:
- `pkgload::load_all` in the installed version here (1.5.3) has no
  `roxygen` argument and its body contains no reference to roxygen at all —
  it cannot have regenerated `man/confint.drmTMB.Rd`.
- File mtimes placed the first three changes at 19:01-19:24 (local), before
  my own `check-profile-fence-integrity.R` was even syntactically complete
  (its own mtime is 19:32, and every `load_all()` call I made used that
  script).
- None of my three new files reference `NEWS.md`, `estimator-surface-conformance.tsv`,
  or `confint.drmTMB.Rd` by path (checked with `grep`).

The subsequent appearance of edits to exactly the four `tests/testthat/`
files this task brief told me "another agent owns" resolves this cleanly:
a concurrent test-authoring agent is active in this same shared worktree,
updating the test suite's `point_fit_only_*` assertions to match the
post-edit `ready`/note behaviour this guard also verifies, and its normal
workflow (update tests, regenerate docs, update NEWS.md, refresh the
estimator-surface-conformance receipt) accounts for all the other files
too. This is expected concurrent-lane activity, not an anomaly and not
something I caused. I have not touched, staged, or committed any of these
files, per the task's constraints.

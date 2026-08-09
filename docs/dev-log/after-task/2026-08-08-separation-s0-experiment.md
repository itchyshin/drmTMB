## 1. Goal

Characterize exact fixed-design separation and current drmTMB numerical behavior for binomial mu, then the observed fixed-effect hurdle hu gate, without package integration.

## 2. Implemented

This evidence-only lane created a deterministic R harness and machine-readable result table for the fixed-effect binomial core. It used `detectseparation 0.4.0` as the maintained LP oracle, ordinary `glm()`, exact-source drmTMB ML, and `brglm2` mean bias reduction. The estimand was finite-MLE existence and asymptotic direction for the unpenalized logit likelihood; finite optimizer output, convergence, `pdHess`, and bias-reduced estimates were recorded but never used as existence evidence.

The lane stopped at the first predeclared core falsifier. Of 31 gate rows, 30 passed and one failed: the frozen contract expected a finite intercept for `mu_complete`, while the LP oracle returned `(Intercept) = -Inf` and `x = +Inf`. No fit errored. The failure was retained in the 82-row TSV, and the script deliberately did not run exact-row controls or hurdle fixtures.

### Mathematical adjudication

For active Bernoulli rows, with \(z_i=2y_i-1\), a separating ray is a nonzero \(d\) satisfying

\[
z_i x_i^\top d \ge 0
\]

for every active row and strictly for at least one row. The complete fixture has failures at \(x=-2,-1\) and successes at \(x=1,2\). For \(d=(d_0,d_1)\), its strict inequalities reduce to

\[
d_1>0, \qquad -d_1<d_0<d_1.
\]

The cone therefore contains \(d_0<0\), \(d_0=0\), and \(d_0>0\) rays. The detector's `(-Inf, +Inf)` certificate is mathematically admissible; the frozen claim that the intercept must remain finite is not invariant. This is a contract defect, not evidence of a drmTMB or `detectseparation` defect. In contrast, the quasi-complete fixture has both outcomes at \(x=0\), which forces \(d_0=0\) and licenses the finite-intercept, `x -> +Inf` statement.

The symbolic complete, quasi-complete, finite-overlap, and grouped-versus-expanded ray calculations passed. The harness did not run the required fixed-parameter compiled drmTMB objective rays. The full frozen contract and its now-falsified complete-fixture coordinate assertion remain in `scratchpad/separation-s0-symbolic-contract.md` as provenance.

## 3a. Decisions and Rejected Alternatives

- Kept the failed coordinate-direction gate unchanged after observing the oracle. Rewriting it in place would erase the predeclared failure.
- Corrected one implementation error before final verification: the all-success and all-failure fixtures initially included `x`; the approved controls were intercept-only. The corrected one-column fixtures passed, while the original `mu_complete` failure remained.
- Did not treat the finite drmTMB coefficients, optimizer code `0`, or `pdHess = TRUE` in separated fits as finite-MLE evidence.
- Did not reinterpret `brglm2` mean-bias-reduced estimates as Firth GLMM estimates or unpenalized ML estimates.
- Did not proceed to zero-weight, offset, response-mask, compiled-objective, or hurdle work after the core stop.
- Withheld S1. The approved sequence requires a verified S0 PASS before GLMM theory work begins.
- Rejected package integration, warnings, dependencies in `DESCRIPTION`, public API, tests, release surfaces, PR creation, and merge work.

## 4. Files Touched

- `scratchpad/separation-s0-preflight.md`
- `scratchpad/separation-s0-symbolic-contract.md`
- `scratchpad/separation-diagnostic-spike.R`
- `scratchpad/separation-diagnostic-results.tsv`
- `scratchpad/separation-s0-mechanical-verification.md`
- `docs/dev-log/after-task/2026-08-08-separation-s0-experiment.md`
- `docs/dev-log/plan-actual/2026-08-08-separation-s0.md`

## 5. Checks Run

- `session_ownership.sh` and `lane_preflight.sh`: Codex Lane S, no detected foreign lane, with the documented weak-evidence caveat.
- `git fetch origin main`: exact base `b441227fa0e11f9ab4347fc963266801cfb75a5f`.
- Worktree recycle gate: prior worktree clean; prior head `24016bf3` present on its remote and an ancestor of `origin/main`; no live process used the path; worktree count remained 22.
- `detectseparation_0.4.0.tar.gz` downloaded from `https://cloud.r-project.org/src/contrib/detectseparation_0.4.0.tar.gz`; SHA-256 `339d4384735934466826812c2a8ece689e03b0d5d620a3cbe1602cb9f35a59de`.
- Source compilation of `slam` and `lpSolveAPI` failed because the local R 4.6 toolchain referenced absent Fortran runtime paths. CRAN macOS binaries for `slam`, `ROI`, `ROI.plugin.lpsolve`, and `lpSolveAPI` were installed into the isolated library; the retained `detectseparation` source tarball then installed successfully.
- Exact drmTMB source at the fetched head was installed into `/private/tmp/drmTMB-separation-s0-pkglib`; package version `0.6.0`, TMB `1.9.21`, R `4.6.0` on aarch64 macOS.
- Overlap smoke: finite, non-empty detector output; exact-source drmTMB coefficients and objective matched `glm()` at numerical precision.
- Main harness command:

  ```sh
  env TMPDIR=/private/tmp R_PROFILE_USER=/dev/null \
    R_LIBS="/private/tmp/drmTMB-separation-s0-pkglib:/private/tmp/drmTMB-separation-s0-rlib:/Users/z3437171/Library/R/arm64/4.6/library" \
    Rscript --no-init-file scratchpad/separation-diagnostic-spike.R --stage binomial
  ```

  Expected exit `1`: `core gate failed; controls intentionally not run; results retained`. Final table: 82 rows, 51 fit rows, 31 gate rows, 30 PASS, 1 FAIL, 0 fit errors.
- Luna V0 reran the command, reproduced exit `1`, and found an unchanged TSV SHA-256 `efc0c296fa2e7117436593cfe662c454a5937506ad4bea9207f4ce7b92d2c030`. Verdict: `MECHANICAL_STOP_EVIDENCE_VALID`.
- D-43 completion panel ran once with two Terra-high reviewers and one Sol-high reviewer. Noether, Fisher, and Rose returned `NOT-DONE` (3/3), withholding S0 and S1 claims.
- Before staging, `git diff --check` was clean and `git diff --name-only -- R src tests DESCRIPTION NAMESPACE README.md NEWS.md _pkgdown.yml` was empty. After staging, the default whitespace check flags the TSV's terminal tab on every data row. Those tabs serialize the retained empty final `error` field and are preserved byte-for-byte so the independently verified SHA-256 remains valid; the six Markdown/R artifacts have no whitespace errors.

## 6. Tests of the Tests

- The overlap smoke required finite detector coefficients and a non-empty result before the core ran.
- Mirrored complete separation checked the opposite slope tail.
- Intercept-only all-success and all-failure fixtures checked `+Inf` and `-Inf` without a covariate.
- The quasi-complete fixture checked equality rows at `x = 0` and distinguished quasi-complete from complete separation.
- Grouped and expanded binomial encodings checked the same detector class/directions and normalized symbolic ray curve.
- The rank-deficient overlap control was classified before LP; the detector was not run, so singularity could not masquerade as separation.
- The intentionally failed `mu_complete` intercept assertion proved the stop gate worked: the TSV was written, the process exited nonzero, and controls/hurdle rows were absent.

## 7a. Issue Ledger

- `S0-001` — frozen complete-fixture intercept oracle is invalid because the separating cone does not identify one coordinate direction. Open; requires a new owner-approved contract, not an in-place rewrite.
- `S0-002` — source installation of LP dependencies fails with the local R 4.6 Fortran runtime configuration. The bounded experiment used CRAN macOS binaries in an isolated library; no package dependency or system configuration changed.
- `gh issue list --repo itchyshin/drmTMB --state open --search "separation" --limit 20` returned no matching open issue. No GitHub issue was opened or changed because this lane stopped before package or public behavior existed.

## 8. Consistency Audit

The reader for this report is a statistical-method developer or drmTMB contributor deciding whether the experiment may advance. The report distinguishes a flawed fixture truth from a detector or package defect and names the exact missing evidence.

The audit searched `README.md`, `ROADMAP.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, and `_pkgdown.yml` for `detectseparation|binary separation|complete separation|quasi-complete|Firth|brglm2`. No public capability statement exists. A broader `separation` search found only unrelated prose about visually separating plot layers or latent/structured scales.

No tracked package, test, public documentation, capability, release, or Lane B file changed. The current worktree contains only the seven quarantined S0 artifacts listed above; tier-routing manifests and D-43 raw verdicts remain outside the repository in the Codex task receipt directory.

## 9. What Did Not Go Smoothly

- The primary checkout had 96 changed/untracked paths. The lane recycled a clean, merged, remotely preserved worktree rather than creating worktree 23.
- The first Luna recon could not create R temporary files in its read-only sandbox and over-scanned package locations. The parent reran the dependency probe with `TMPDIR=/private/tmp` and an explicit library path.
- Source installation of LP dependencies failed at missing Fortran runtime paths; isolated CRAN binaries supplied those dependencies without changing the user library.
- The first exact-source drmTMB build was blocked by the parent sandbox writing `src/drmTMB.o`; the authorized rerun built cleanly and `--clean` left no source-tree artifacts.
- S0-A froze an invalid finite-intercept assertion for complete separation. S0-B exposed it immediately.
- S0-B initially implemented the all-success/all-failure controls with an unnecessary `x` term. The parent restored the approved intercept-only fixtures and reran the core; the substantive failure was unchanged.
- The final date-wide routing audit exited `1`: although the retained S0 dispatch receipts have the planned Luna/Terra/Sol allocation, the same-day native-session census was Sol-heavy and this parent task recorded three compaction windows against the plan's maximum of one. This is retained as a context/routing deviation, not relabelled as a pass.

## 10. Known Residuals

- S0 is `NOT-DONE`; this is a retained STOP, not a partial PASS.
- The complete fixture needs a cone-level or existential ray truth. A single per-coordinate infinity vector from the LP oracle is not an invariant description when separating rays are non-unique.
- Fixed-parameter compiled drmTMB objective rays were not evaluated.
- Zero-weight, offset, and response-mask controls were not run.
- Hurdle `hu` classification, mirrored tails, factorization, and positive-count invariance were not run.
- S1 GLMM theory and numerical work did not start.
- The experiment provides no interval, warning-quality, fit-time diagnostic, public API, package integration, or GLMM bias-reduction claim.

## 11. Team Learning

The reusable lesson is mathematical: complete separation can identify an improving cone without identifying a unique coordinate-wise infinity direction. Freeze cone membership or an explicitly chosen certificate ray; reserve coordinate-wise finite/infinite claims for cases where the geometry makes them invariant.

Memory receipt: the routed guards that shaped the work were the drmTMB `route.py` LOAD-FIRST manifest, the repo's fixed-effect-before-random-effect rule, symbolic alignment before code, exact-source validation, local-only toy compute, retained failures, and independent verification. `ask-brain`/the prior-work sweep supplied the experimental-lane and no-release boundaries. No brain-vault write was made because the user did not authorize memory updates; this repo report is the durable receipt.

Golden Set: not in scope. This task did not modify a known cross-repo mistake class or a memory retrieval rule; it tested a new fixture contract.

## 12. Cross-Product Coverage

Covers: fixed-effect binomial `mu` core fixtures on exact-source drmTMB `0.6.0`; maintained LP classification for overlap, complete, mirrored, quasi-complete, grouped/expanded, intercept-only, and rank-deficient controls; ordinary ML and mean-bias-reduced comparator observations; reproducible retained STOP evidence.

This task does NOT cover exact-row controls; compiled drmTMB objective rays; hurdle `hu`; `zi`; beta-binomial or count separation; random or structured effects; penalties or priors; intervals; fit-time warnings; a public detector or `check_drm()` API; package tests/docs; gllvmTMB or DRM.jl; S1 GLMM theory; release, PR, or merge work.

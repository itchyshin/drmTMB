🎯 GOAL

Codex alone will deliver Arc 1b-S2R: native-TMB REML for the exact
bivariate-Gaussian, location-only, supplied-relatedness q2 intercept cell that
already fits under ML:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
    mu2 = y2 ~ x2 + relmat(1 | p | id, K = K),
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ 1
  ),
  family = biv_gaussian(),
  data = data,
  REML = TRUE
)
```

HEADLINE: close one exact Gaussian REML-to-ML parity gap with an independent
dense restricted-likelihood oracle and retained-denominator recovery evidence.
IN PARALLEL after the post-merge gate: Noether freezes math, Boole freezes the
API boundary, Curie freezes ADEMP, and Grace freezes ledger migration; Gauss
alone owns the admission change. DEFER: animal/`A`/`Ainv`; `Q` as a REML
surface; slopes and q4+; scale-side/direct-SD/corpair/meta-`V`; intervals and
coverage; PR #781; Julia; and the combined `sd()` arc. DISCIPLINE: freeze
equation -> syntax -> DGP -> TMB target -> extractor -> oracle before code;
prove current rejection; smoke locally; run exactly 2,400 retained REML fits
on Totoro or DRAC, never Actions; cap the claim at `point_fit_recovery`; close
with full package/site checks, fresh D-43 review, after-task report, focused
unmerged PR, and handoff.

# Arc 1b-S2R ultra-plan

## Execution gates

1. PR #783 merge authorization: **approved and completed**.
2. Merge/sync base: **completed at `d2104391`**.
3. Post-merge refresh: **PASS** in
   `2026-07-15-post-783-candidate-refresh.md`.
4. GOAL execution approval: **approved by Shinichi on 2026-07-15**.

## Frozen scope

The positive cell is `biv_gaussian()` with matching labelled
`relmat(1 | p | id, K = K)` intercepts in `mu1` and `mu2`, constant
`sigma1`, `sigma2`, and `rho12`, complete pairs, unit weights, and no other
random, structured, direct-scale, known-covariance, or corpair layer.

The new predicate must require provider `relmat` and representation `K`.
`Q`, animal, phylo, spatial, unlabelled blocks, mismatched endpoints, slopes,
q4+, scale-side blocks, nonconstant residual parameters, missing pairs,
weights, `meta_V()`, direct-SD, corpair, non-Gaussian families, AI-REML,
intervals, and coverage remain rejected or unchanged.

## Execution slices

| Slice | Owner | Output | Dependency |
| --- | --- | --- | --- |
| S0 truth refresh | Ada + Fisher | post-#783 candidate refresh | merged base |
| S1a symbolic freeze | Noether | symbolic-alignment note | S0 PASS |
| S1b admission freeze | Boole | admission-matrix note | S0 PASS |
| S1c ADEMP freeze | Curie | recovery-design note | S0 PASS |
| S1d ledger freeze | Grace | ledger-migration note | S0 PASS |
| S1e integration review | Ada + Fisher + Rose | one PASS/STOP disposition | S1a-S1d |
| S2a test of test/oracle | Curie | failing target test, dense oracle, displaced vectors, wrong-orientation sentinel | S1e PASS |
| S2b admission | Gauss | minimal fail-closed R gate | S2a fails correctly |
| S2c harness | Curie | runner and runner-contract test | S1e PASS |
| S3 local integration | Ada + Gauss | compiled fit, negative matrix, smoke | S2a-S2c |
| S4 retained recovery | Curie | 2,400 attempts plus authenticated summary | S3 PASS |
| S5 evidence/surfaces | Grace | ledger, artifact, docs, generated surfaces | S4 PASS |
| S6 full checks | Ada + Grace | document/test/check/pkgdown/runtime evidence and closeout draft | S5 |
| S7 independent review | Rose + Fisher/Curie + Pat; Noether extra | fresh D-43 verdicts | S6 |
| S8 landing | Ada + Rose | validated report, focused pushed PR, handoff | S7 PASS |

Parallel batches are `{S1a,S1b,S1c,S1d}`, then the code and harness may proceed
under single-file ownership after S2a freezes the oracle. Compute, evidence
promotion, full verification, and landing remain sequential.

## Evidence gates

- Dense REML equality within `1e-5` at the optimum and the two exact displaced
  vectors frozen in the symbolic note; common parameters agree with the
  independent optimum within `2e-3`.
- The deliberately wrong `K`/`Q` orientation misses the correct first
  displaced objective difference by more than `1e-3`.
- Six campaign cells: `g = 16, 32, 64` crossed with `m = 3, 6`.
- Exactly 400 attempted replicates per cell and one REML fit per replicate:
  2,400 attempts and 2,400 fits. Every attempt stays in the denominator.
- High-information cells (`g >= 32`, `m = 6`) require at least 95% optimizer
  convergence and 90% `pdHess`.
- At `g = 64`, `m = 6`, absolute bias must be at most 0.10 for each structured
  SD and 0.12 for the structured correlation.
- Structured-SD and correlation RMSE must satisfy the independently
  bootstrapped inequality frozen in the recovery design.
- Seeds, source, matrices, response ordering, raw attempts, summaries, and
  denominators must authenticate by hash.

Any failure produces a HOLD. No attempt may be deleted and no threshold may be
changed after inspection.

## Post-arc queue clarification (Shinichi, 2026-07-15)

This clarification does not widen Arc 1b-S2R. After this closeout, sequence the
Beta phylogenetic q1 `mu` prerequisite, a bounded Beta q1
location-scale-scale gate, and then a separate hierarchical-`sd()` subarc.
Keep family variability `sigma` separate from the SD model for a named latent
target, `sd(target, ...)`. The current `sd()` RHS is fixed-effect-only with
within-target-constant predictors. A conservative first random-RHS admission
may use only a genuinely coarser group containing multiple nested target
groups; same-level terms and highest-level targets without a separately
justified replicated higher group remain rejected. This is an initial
implementation/identifiability rule, not a universal theorem, and requires its
own symbolic alignment, nesting validation, recovery, and rejection matrix.

## Compute and closure

Smoke one tiny cell and one retained fit locally. Use Totoro by default, DRAC
only if Totoro is unavailable, cap at 32 workers, and set BLAS/OpenMP threads
to one. Store campaign results locally and commit only the compact authenticated
artifact; never use GitHub Actions simulation artifacts.

After evidence passes, regenerate the capability surface, run focused tests,
`devtools::document()`, full `devtools::test()`, genuine `--as-cran`, pkgdown
check/build, runtime/Mission-Control read-back, stale-source and stale-HTML
scans, Rose pattern scan, after-task validators, and the handoff gate. Two
fresh D-43 NOT-DONE verdicts withhold completion. Leave the final PR unmerged.

## Source, generated, and closeout contract

Handwritten sources that must be considered are:

- `docs/dev-log/dashboard/capability-ledger/{cells,evidence,transitions}.tsv`,
  its `schema.json`, ledger `README.md`, `tools/capability_ledger.py`, and
  `tools/tests/test_capability_ledger.py`;
- `README.md`, `NEWS.md`, `ROADMAP.md`, formula grammar and likelihood design
  docs, `docs/dev-log/known-limitations.md`, and `docs/dev-log/check-log.md`;
- the compact artifact under
  `docs/dev-log/simulation-artifacts/2026-07-15-arc1b-s2r-relmat-q2-reml/`;
  and affected vignette sources identified by the stale scan.

Regenerate with:

```sh
python3 tools/capability_ledger.py --write
python3 tools/capability_ledger.py --check
python3 -m unittest tools/tests/test_capability_ledger.py
R_PROFILE_USER=/dev/null Rscript --no-init-file tools/check-capability-runtime.R
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
```

Inspect every changed generator-owned file. The explicit expected set is
`docs/dev-log/dashboard/capability-census/_master.tsv`,
`_widget_data.json`, `biv_gaussian.tsv`,
`docs/dev-log/dashboard/capability-surface.{md,html}`, and
`vignettes/includes/capability-ledger-family-map.md`; also inspect any
missing-response include or tranche file emitted by the generator. Never
hand-edit generated files.

Before drafting results, create the report exactly once:

```sh
python3 "/Users/z3437171/Dropbox/Github Local/Shinichi/tools/closeout.py" \
  new "$PWD/docs/dev-log/after-task/2026-07-15-arc1b-s2r-relmat-q2-reml.md" \
  --goal "Arc 1b-S2R exact relmat-K q2 bivariate REML"
```

Run the Rose scan and close with:

```sh
Rscript "/Users/z3437171/Dropbox/Github Local/Shinichi/tools/rose-pattern-scan.R" "$PWD"
Rscript "/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R" \
  docs/dev-log/after-task/2026-07-15-arc1b-s2r-relmat-q2-reml.md
python3 "/Users/z3437171/Dropbox/Github Local/Shinichi/tools/closeout.py" \
  check "$PWD/docs/dev-log/after-task/2026-07-15-arc1b-s2r-relmat-q2-reml.md"
/Users/z3437171/Dropbox/Github\ Local/Shinichi/tools/handoff_gate.sh "$PWD"
```

After D-43 PASS, review explicit paths, stage only this arc, commit, push, open
a focused PR, wait for exact-head CI, and write the handoff. Leave the PR
unmerged. Any substantive S7 correction reruns every affected check and review
lens before landing.

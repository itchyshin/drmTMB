# Gaussian random-intercept coefficient priors: current state

The implementation, independent numerical checks, bounded source reviews and repaired-source local full suites passed. Hosted CI adjudication and final closeout remain pending. No merge or release is authorized for this slice.

## Scope and source

Existing normal and ridge priors apply to selected Gaussian fixed coefficients with one independent mean random intercept. The group SD remains unpenalized. ML, complete data, unit weights and dense designs are required. Slopes, multiple groups, structured effects, SD/correlation priors and calibrated interval inference remain outside this slice.

Validated engine commits: drmTMB `5d0f159644991f49dd767b8baf8cb61f537b3720`; DRModels.jl `ff10a2f9adb23c0e315d50e8c2094d6d27ed1d82`. Both use isolated `codex/gaussian-ri-priors-20261106` branches.

## Current evidence

- `guarded-numerical-evidence/`: all36 frozen comparisons passed on the repaired source, with an independent root rerun. Native derivatives cover nine positive-SD points; three exact-zero points are value-only. Arbitrary-point bridge derivatives are unavailable.
- `R-MULTISTART-POLICY.md`: native R uses its existing multi_start=5 uniformly. The earlier default ri_10 local-minimum failure remains retained in `final-numerical-evidence/`. The configured pass provides no global optimization guarantee.
- `guarded-focused-live/`:87 expectations passed, including one actual Julia bridge test. Native factor selectors were separately tested; numeric indicator bridge transport does not establish raw-factor bridge support.
- The derived-ratio guard repair refuses active fixed-prior variance-ratio confidence intervals. R guard24 and existing62 checks passed; Julia guard23 and existing43 passed. See `derived-ratio-guard-review.md`.
- `completion-r-review.md`, `completion-julia-review.md` and `completion-inference-review.md`: fresh bounded source gates passed. Final runtime closure is pending.
- The final Julia partition covers561 files exactly once. All eight shards exited0 and reported package tests passed, with every JET gate2/2. The longest shard took8367seconds. Raw complete receipts are in guarded-julia-full/. The original numerical sparse baseline passed at logLik -256.5059. Historical R constants printed by that script do not provide a new paired benchmark.
- Full repaired-source R build and package check passed with exit0, one report-only spelling NOTE and42125 test expectations passed with0 failures. Source manifest passed; source-tree tests passed26516 expectations with0 failures. See guarded-R-full/.

Earlier candidate numerical, focused and full-suite results retain their original source pins. They do not substitute for repaired-source full-suite qualification.

## Reviewable branches

Both branches are pushed. Draft PRs are open: [drmTMB #1681](https://github.com/itchyshin/drmTMB/pull/1681) and [DRModels.jl #1258](https://github.com/itchyshin/DRModels.jl/pull/1258). Their bodies explicitly record pending qualification. CI remains active. Hosted Julia1.13.3 shard3 failed an existing unpenalized binomial SD convergence assertion; the cause remains unclassified. Baseline and candidate each passed that test locally under three diagnostic configurations. Hosted baseline run42318931694 is comparing the pre-slice source. R current-head workflow42315004155 is running. Final reports and raw receipt additions remain local until reconciled.

## Protection and remaining work

The four pre-existing dirty configuration files retain their recorded hashes and remain outside commits. PR1651 remains open at `1bf51e2d61bd1ce0a2fb3fad914a9888544af491`. R main advanced independently; no reconciliation merge was performed. No version bump, merge, release or production-site deployment occurred. Documenter built and published the Julia PR preview; its production deployment job was skipped.

Next: adjudicate hosted CI outcomes, finish the independent receipt review, reconcile reports and check-log entries, commit only owned evidence/documents, and finish PR checks. G5 and G6 remain open.

Final R qualification: package check exit0 with one report-only spelling NOTE;42125 test expectations passed with0 failures,117 warnings and696 skips. Source manifest passed, and source-tree tests passed26516 expectations with0 failures,14 warnings and6 skips. Raw receipts are in guarded-R-full/. The current capability receipt was recertified exactly on its Mac reference host; see c17-recertification/. Local Julia qualification also passed all eight shards; hosted CI qualification remains pending.

# Gaussian random-intercept prior slice

The approved implementation and numerical qualification are complete for draft review, including the independently adjudicated baseline exception below. G6 final report/protection reconciliation is recorded in ACCEPTANCE-AUDIT.json. No merge or release is included.

## Scope and validated sources

The slice admits normal/ridge priors on selected fixed coefficients of Gaussian mean and log residual SD formulas, with one independent mean random intercept. It retains ML, complete data, unit weights and dense full-rank designs. The group SD receives no prior.

Validated production sources are R `5d0f159644991f49dd767b8baf8cb61f537b3720` and Julia `ff10a2f9adb23c0e315d50e8c2094d6d27ed1d82`. Subsequent report/receipt commits leave production and test code unchanged.

## Numerical and runtime evidence

- All 19 frozen oracle entries still match their manifest. References, thresholds and mutation controls were fixed before candidate qualification.
- All 36 configured comparisons passed: twelve native R, twelve native Julia and twelve bridge fixtures. Native derivatives cover nine positive-SD points; three exact-zero points are value-only. Arbitrary-point bridge derivatives remain unavailable.
- Native R qualification uses its existing public `multi_start=5` control uniformly, with the recorded RNG policy. The original single-start fixture10 inferior minimum and all earlier outcomes remain retained. Julia and bridge solver settings were unchanged.
- Guarded focused tests passed 87 expectations, including one actual R-to-Julia bridge test. Native factor selection was tested; validated numeric-indicator transport does not establish raw-factor bridge frontend support.
- Repaired-source R build/check passed with 42125 test expectations and zero failures; source-tree checks passed 26516 with zero failures. The local check retained one report-only spelling NOTE. Hosted R checks passed Windows, macOS and Linux, each with two NOTEs for the existing news directory and report-only spelling comparison.
- The final Julia 1.10.12 local suite passed all eight original shards, covering 561 files exactly once and every JET gate 2/2. The longest shard took 8367 seconds. Raw logs, exits, source/runtime identities and partition lists are retained.

See guarded-numerical-evidence/, guarded-focused-live/, guarded-R-full/ and guarded-julia-full/. Shared derived variance-ratio intervals now refuse active fixed-prior fits; point summaries, no-prior behavior and zero-ridge identities remain available.

## Hosted Julia baseline exception

Original candidate Julia 1.13.3 CI retains two failed attempts at the existing unpenalized binomial slope convergence assertion. Its other shards passed, including 43 new core prior assertions and five factor-selector assertions. The hosted pre-slice baseline passed all eight LTS/stable test jobs.

Controlled source-restricted-coverage prefixes passed the same 27 files, all 44 target assertions and JET 2/2 on both sources, with identical recorded fit diagnostics. The earlier dependency-wide-coverage experiment retains both prefix timeouts; those timeouts are not test passes.

The final controlled kernel experiment demonstrates the pre-existing failure class. Baseline `86ee1c2a` and candidate `ff10a2f9` each pass 44/44 with verified Cooperlake and fail 43/44 with verified Haswell. Within each kernel, all eight recorded fit fields, explicit parameter bitstrings and condition diagnostics match between sources. Haswell reproduces the original assertion and reciprocal condition 5.752216336949239e-17. No assertion, seed, threshold or prior changed in this fixture.

The independent kernel-pair review accepts G5's existing baseline-exception path for the approved prior-only draft review. The original jobs did not record their actual kernel, so exact historical hardware attribution is not proven. Their failed conclusions remain failed; this is no claim of green candidate CI or universal backend robustness. See kernel-pair-outcome-review.md and hosted-ci-baseline/.

## Isolation and review boundary

Draft [drmTMB #1681](https://github.com/itchyshin/drmTMB/pull/1681) and [DRModels.jl #1258](https://github.com/itchyshin/DRModels.jl/pull/1258) remain isolated and unmerged. Diagnostic workflows live on their separate branch. The four protected dirty configuration files retain their original hashes. Protected R PR #1651 remains open/draft/unmerged at `1bf51e2d61bd1ce0a2fb3fad914a9888544af491`.

The C17 pointer was recertified exactly on its Mac reference host. Historical raw receipts are byte-identical; the rejected Totoro attempt remains retained. The pointer filename also appears in PR #1651, whose branch was not modified.

Final owned reports and qualification artifacts retain every failed attempt and the bounded exception. Exact source/protection checks are recorded in ACCEPTANCE-AUDIT.json. Documenter at source385fde27 passed and published its PR preview automatically; production-site deployment was skipped. No version bump, merge or release occurred.

Random slopes, multiple/structured effects, SD/correlation priors, REML, other mixed families, interval calibration and posterior sampling remain outside this slice. The separately recorded next-stage plan does not extend current support.

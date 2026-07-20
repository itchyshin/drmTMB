# Arc 4c plan versus actual

## Planned outcome

Certify the ordinary independent `mu` random-slope SD profile interval for
skew-normal `mc-0464`, Tweedie `mc-0539`, and zero-one beta `mc-0575` using a
two-PR, evidence-first Fir campaign. Each cell would promote independently only
if its all-attempt profile coverage, availability, positive control, contiguous
M suffix, and fresh D-43 review supported the claim.

## Actual outcome

All three cells met the frozen mechanical coverage gate at M=16, 32, and 64.
Fisher and Rose recommended all three promotions. Noether recommended promotion
for skew-normal and Tweedie but withheld zero-one beta because rare
machine-exact endpoints leaked from the beta-labelled interior component into
the fitted boundary mass. The predeclared D-43 rule blocks only after two
WITHHOLD verdicts, so all three promote to `inference_ready_with_caveats` with
certified floor M=16. No cell earns `supported` status.

## Slice reconciliation

| Planned slice | Actual execution | Reconciliation |
|---|---|---|
| Fresh `origin/main` isolation | PR A and PR B used separate clean worktrees; the dirty root remained untouched | matched |
| Curie runner and Grace dispatch in parallel | Runner/contract and Fir dispatch were built with separate ownership and integrated in PR A | matched |
| Merge PR A before compute | PR #797 merged at `72a47119`; an R-library ordering defect required narrow repair PR #798, merged at `46affaee` | one extra repair PR |
| Stop for explicit compute approval | Shinichi approved compute before the fresh Fir preflight or campaign | matched |
| Twelve N=1 smokes | All twelve completed; Tweedie M8 alone failed the in-range smoke criterion | matched frozen selection rule |
| At most 1,440 ten-replicate tasks | The selected eleven cells produced one 1,320-task array at `%96` | matched |
| Exactly 1,200 attempts per approved cell | 13,200 unique rows across eleven cells; no duplicates, gaps, seed errors, shard errors, fit errors, or nonconvergence | matched |
| Primary profile gate and diagnostic summaries | Profile availability, hits, exact intervals, misses, and family diagnostics were complete; point-estimate/Wald diagnostics were all `NA` because the extractor rejected duplicate report-row names | primary gate matched; diagnostic deviation disclosed |
| Shared-seed replay | Replicate 1 was replayed for all nine promoted M=16/32/64 cells; status and endpoints matched within `1.56e-10` | matched for profile; `sd_hat` comparison unavailable |
| Three fresh D-43 lenses | Fisher PROMOTE 3/3; Rose PROMOTE 3/3; Noether PROMOTE 2/3 and WITHHOLD zero-one beta | promotion rule applied as frozen |
| Single ledger writer | Three cells changed tier, retained `estimator=ML`, gained one evidence and transition row each, and reduced recovery count 161 to 158 | matched |
| Generated surfaces and package closeout | All 30 capability outputs regenerated; stale family help/design prose was corrected without changing `_pkgdown.yml` or the 33-article taxonomy | matched plus adjacent consistency repair |

## Deviations and their significance

The first Fir smoke failed before any fit because the worker validated the
isolated R library before exporting it. PR #798 moved the export ahead of
validation in all three workers and added a static ordering regression. The
failed run contributes no statistical row.

The campaign's `sd_hat`/Wald extractor expected one `log_sd_mu` row in
`summary(fit$sdr)`, but a live fit exposes two identical report rows. The
profile interval path does not use this extractor, so the predeclared primary
gate remains valid. PR B fixes future extraction through the unique
`par.fixed` target and `cov.fixed`, tests duplicate report names, preserves the
immutable campaign rows, and makes no retrospective point-bias or Wald claim.

The zero-one beta diagnostic found rare beta-labelled `rbeta()` values rounded
to exactly one. Because the frozen plan stated that family diagnostics could
not change the gate after results and required two WITHHOLD verdicts, this does
not overturn the promotion. It materially narrows the claim and creates a
specific future gate: a deterministic strictly-interior sampler and separately
approved rerun before claiming an exactly 15% observed-boundary design.

## Scope preserved

The arc did not add an estimator, family, formula grammar, or public function.
It did not run on GitHub Actions, use campaign artifacts from Actions, modify
the article taxonomy, expand REML/AGHQ/O3, claim `supported`, or touch DRM.jl.
